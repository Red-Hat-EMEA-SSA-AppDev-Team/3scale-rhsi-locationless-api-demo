# RHSI Skupper Network

## Red Hat Service Interconnect Router in the AWS OCP cluster

1. Login to the AWS OCP cluster
    ```shell script
    oc login...
    ```

2. Make sure the current project is rhsi-hackfest-apibackend
    ```shell script
    oc project rhsi-hackfest-apibackend
    ```

3. Initialize the Service Interconnect Router.
    > NOTE: This should install the Service Interconnect resources in the rhsi-hackfest-apibackend namespace of the AWS OCP cluster 
    ```shell script
    skupper init --enable-console --enable-flow-collector --console-auth unsecured --site-name aws-ocp
    ```

4. See the status of the skupper network
    ```shell script
    skupper status
    ```

5. Expose the `books-api-v1` and `books-api-v2` services over the link

    ```shell script
    skupper expose deployment/books-api-v1 --address books-api-v1 --port 80 --target-port 8080 --protocol http
    skupper expose deployment/books-api-v2 --address books-api-v2 --port 80 --target-port 8080 --protocol http
    ```

6. Create a token in the AWS OCP cluster namespace that will be used to create the link with the AZURE OCP cluster namespace
    ```shell script
    skupper token create secret_aws_azure.token
    ```

7. Display the token
> NOTE: the content will be used to create a token file before creating a RHSI link from the AZURE OCP cluster
    ```shell script
    cat secret_aws_azure.token
    ```

## Red Hat Service Interconnect Router in the Azure OCP cluster

1. login to the AZURE OCP cluster
    ```shell script
    oc login...
    ```

2. Make sure the current project is rhsi-hackfest-apibackend
    ```shell script
    oc project rhsi-hackfest-apibackend
    ```

3. Initialize the Service Interconnect Router.
    > NOTE: This should install the Service Interconnect resources in the rhsi-hackfest-apibackend namespace of the AZURE OCP cluster 
    ```shell script
    skupper init --site-name azure-ocp
    ```

4. Copy and paste AWS token into a file named secret_aws_azure.token
    ```shell script
    vi secret_aws_azure.token
    ```

5. Create a link between the rhsi-hackfest-apibackend namespaces on AWS and AZURE OCP clusters
    >NOTE: /!\ Beware, the token is only usable once. Plus, it expires after 15mn if not used.
    ```shell script
    skupper link create secret_aws_azure.token --name azure-to-aws
    ```

6. Expose the books-api-v1 and books-api-v2 services over the link
    ```shell script
    skupper expose deployment/books-api-v1 --address books-api-v1 --port 80 --target-port 8080 --protocol http
    skupper expose deployment/books-api-v2 --address books-api-v2 --port 80 --target-port 8080 --protocol http
    ```