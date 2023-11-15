#!/usr/bin/env bash

#Environment variables
## Namespace for the observability tools
OBSERVABILITY_NS="rhsi-hackfest-observability"

# Create the`observability` _OpenShift namespace_
oc new-project $OBSERVABILITY_NS \
  --display-name="RHSI Hackfest - Observability Tools" \
  --description=$OBSERVABILITY_NS

# /!\ INSTALL the Jaeger Operator through the OpenShift OLM
## The `Jaeger` operator subscription (AllNamespaces install mode)
oc apply -f ./manifests/jaeger-product-operator-subscription.yaml

## Check the operators are successfully installed
watch oc get csv

# Deploy the all-in-one-memory Jaeger
oc apply \
  -f ./manifests/rhsi-hackfest-jaeger-all-in-one-memory_cr.yaml \
  -n $OBSERVABILITY_NS

watch oc get po