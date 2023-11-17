# Install Red Hat 3scale API Management v2.13

1. Adapt the following files according to your environment:
    
    1. Edit the 3scale APIManager CR ([`./2.13_manifests/rhsi-hackfest-apimanager_cr.yaml`](./2.13_manifests/rhsi-hackfest-apimanager_cr.yaml)) to replace the OpenShift domain placeholder with that of your cluster:
    
        ```script shell
        sed 's/apps.*com/<Replace with your cluster domain URl>/g' ./2.13_manifests/rhsi-hackfest-apimanager_cr.yaml > temp.yml && mv temp.yml ./2.13_manifests/rhsi-hackfest-apimanager_cr.yaml
        ```

        Example:

        ```script shell
        sed 's/apps.*com/apps.cluster-8bcs7.8bcs7.sandbox2056.opentlc.com/g' ./2.13_manifests/rhsi-hackfest-apimanager_cr.yaml > temp.yaml && mv temp.yaml ./2.13_manifests/rhsi-hackfest-apimanager_cr.yaml
        ```

    2. Edit the ([`./2.13_manifests/threescale-aws-s3-auth-secret`](./2.13_manifests/threescale-aws-s3-auth-secret)) according to your AWS cloud environment. Replace the `AWS_ACCESS_KEY_ID`, `AWS_REGION` and `AWS_SECRET_ACCESS_KEY` properties :

        > NOTE: The AWS S3 bucket is used to store static contents of the 3scale CMS.
    
        ```script shell
        apiVersion: v1
        kind: Secret
        metadata:
        name: threescale-aws-s3-auth-secret
        stringData:
        AWS_ACCESS_KEY_ID: <change_me>
        AWS_BUCKET: threescale-bucket
        AWS_REGION: <change_me>
        AWS_SECRET_ACCESS_KEY: <change_me>
        type: Opaque
        ```



2. Run the [`setup_rhsi-hackfest_api-manager.sh`](./setup_rhsi-hackfest_api-manager.sh) script to install the Red Hat 3scale API Management platform in the `rhsi-hackfest-3scale-amp` namespace:

    > NOTE: the 3scale operator is installed with an _all namespaces_ scope.

    ```script shell
    ./setup_rhsi-hackfest_api-manager.sh
    ```
