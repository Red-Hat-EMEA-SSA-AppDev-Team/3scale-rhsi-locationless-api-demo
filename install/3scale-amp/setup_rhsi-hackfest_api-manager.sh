#!/usr/bin/env bash

#Environment variables
## Namespace for the Red Hat 3Scale API Management Platform
API_MANAGER_NS="rhsi-hackfest-3scale-amp"
## Password for the master admin account (master)
API_MASTER_PASSWORD="P!ssw0rd"
## OpenShift domain suffix
OCP_DOMAIN="cluster-8bcs7.8bcs7.sandbox2056.opentlc.com"
## OpenShift routes domain suffix
OCP_WILDCARD_DOMAIN="apps.${OCP_DOMAIN}"
## Master API access token
API_MASTER_ACCESS_TOKEN="2075e314a378c9f01232d92f113f359d671620ce1de00255c55cf19ce6f46d74"
## Tenant API access token
API_TENANT_ACCESS_TOKEN="88fb895da81b95270d3bc196b86edc211fa570fdec3d8f80581fa7fce4015512"
## Name of the initial tenant
TENANT_NAME="rhsi-hackfest"
## Password for the initial tenant admin account (admin)
TENANT_ADMIN_PASSWD="P!ssw0rd"

# Create the`rhsi-hackfest-3scale-amp` _OpenShift namespace_
oc new-project $API_MANAGER_NS \
  --display-name="RHSI Hackfest - 3scale API Manager" \
  --description=$API_MANAGER_NS

# Install Operators using the OLM
## Create the namespace OperatorGroup
oc apply -f ./2.13_manifests/rhsi-hackfest-3scale-amp-operatorgroup.yaml

## The _Red Hat Integration - 3scale operator_ (Single Namespace scope)
oc apply -f ./2.13_manifests/rhsi-hackfest-3scale-operator-subscription.yaml

## The _Grafana Operator (Community)_ (single namespace scope)
oc apply -f ./Observability/manifests/rhsi-hackfest-3scale-apim-grafana-operator-subscription.yaml

# Wait for Operators to be installed
watch oc get sub,csv,installPlan

# Create the 3scale AMP Grafana instance
oc apply -f ./Observability/manifests/rhsi-hackfest-grafana_cr.yaml

# Create the 'system-seed' secret to customize the indicated parameters for the Red Hat 3scale API Management Platform
oc create secret generic system-seed \
  --from-literal=MASTER_USER=master \
  --from-literal=MASTER_PASSWORD="${API_MASTER_PASSWORD}" \
  --from-literal=MASTER_ACCESS_TOKEN="${API_MASTER_ACCESS_TOKEN}" \
  --from-literal=MASTER_DOMAIN=master \
  --from-literal=ADMIN_USER=admin \
  --from-literal=ADMIN_PASSWORD="${TENANT_ADMIN_PASSWD}" \
  --from-literal=ADMIN_EMAIL="admin-hackfest@example.com" \
  --from-literal=ADMIN_ACCESS_TOKEN="${API_TENANT_ACCESS_TOKEN}" \
  --from-literal=TENANT_NAME="${TENANT_NAME}" \
  -n $API_MANAGER_NS

# Jaeger configuration secrets fot the managed APIcast
# Reference: https://github.com/3scale/3scale-operator/blob/3scale-2.13.0-GA/doc/apimanager-reference.md#APIcastTracingConfigSecret
oc create secret generic threescale-prod-jaeger-conf-secret \
  --from-file=config=./2.13_manifests/threescale-apicast-production_jaeger_config.json \
  -n $API_MANAGER_NS
oc create secret generic threescale-staging-jaeger-conf-secret \
  --from-file=config=./2.13_manifests/threescale-apicast-staging_jaeger_config.json \
  -n $API_MANAGER_NS

# Create the 'threescale-aws-s3-auth-secret' secret
# References: 
# - https://github.com/3scale/3scale-operator/blob/3scale-2.13.0-GA/doc/apimanager-reference.md#fileStorage-S3-credentials-secret
# - https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.10/html/installing_3scale/install-threescale-on-openshift-guide#amazon_simple_storage_service_3scale_emphasis_filestorage_emphasis_installation
oc apply \
  -f ./2.13_manifests/threescale-aws-s3-auth-secret \
  -n $API_MANAGER_NS

# Deploy the Red Hat 3scale API Management Platform
oc apply \
  -f ./2.13_manifests/rhsi-hackfest-apimanager_cr.yaml \
  -n $API_MANAGER_NS

# Watch the pods being created
watch oc get po -n $API_MANAGER_NS

# Setup Service Discovery
# Cf. https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.11/html/admin_portal_guide/service_discovery_from_openshift_to_3scale
# Configuring without RH SSO
# To configure the 3scale Service Discovery without SSO, you can use 3scale Single Service Account 
# to authenticate to OpenShift API service. 3scale Single Service Account provides a seamless 
# authentication to the cluster for the Service Discovery without an authorization layer at the user level. 
# All 3scale tenant administration users have the same access level to the cluster while discovering API 
# services through 3scale.
# ===> Grant the 3scale deployment amp service account with view cluster level permission.
oc adm policy add-cluster-role-to-user view system:serviceaccount:${API_MANAGER_NS}:amp

# Enable audit logging
# Cf. https://access.redhat.com/documentation/en-us/red_hat_3scale_api_management/2.13/html-single/operating_3scale/index
## Enable audit logging to stdout
oc patch configmap system -p '{"data": {"features.yml": "features: &default\n  logging:\n    audits_to_stdout: true\n\nproduction:\n  <<: *default\n"}}'

## Patch the deployment configuration for the system-app and system-sidekiq pods
PATCH_SYSTEM_VOLUMES='{"spec":{"template":{"spec":{"volumes":[{"emptyDir":{"medium":"Memory"},"name":"system-tmp"},{"configMap":{"items":[{"key":"zync.yml","path":"zync.yml"},{"key":"rolling_updates.yml","path":"rolling_updates.yml"},{"key":"service_discovery.yml","path":"service_discovery.yml"},{"key":"features.yml","path":"features.yml"}],"name":"system"},"name":"system-config"}]}}}}'
oc patch dc system-app -p $PATCH_SYSTEM_VOLUMES
oc patch dc system-sidekiq -p $PATCH_SYSTEM_VOLUMES