# ThreescaleAPIProducts

## Purpose of this repository

This repository contains instructions used to secure the [Library Books API](./library-books-api/) with Red Hat 3scale API Management. Some instructions involve the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper) using [Podman](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/index).
 

The [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper) is then used to secure the [Library Books API](./library-books-api/) with a Red Hat 3scale API Management tenant. Some instructions involve the _3scale Admin Portal_ UI.

[Red Hat 3scale API Management v2.13](https://access.redhat.com/products/red-hat-3scale/) and [Red Hat 3scale Toolbox CLI v2.13](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper) are used in these instructions.

## Prerequisites

- [Red Hat OpenShift v4.12+](https://access.redhat.com/products/openshift/) with [Red Hat 3scale v2.13+](https://access.redhat.com/products/red-hat-3scale/) installed
- [Podman v4+](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/index)
    > **NOTE:** [Podman](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/index) must have the credentials to connect to the public Red Hat container registry ([registry.redhat.io](registry.redhat.io)) in order to pull the [3scale Toolbox image](https://catalog.redhat.com/software/containers/3scale-amp2/toolbox-rhel8/60ddc3173a73378722213e7e?container-tabs=gti&gti-tabs=registry-tokens).
    - The `podman login` command can generate a file with credentials (`${XDG_RUNTIME_DIR}/containers/auth.json`). Example: `podman login registry.redhat.io` and then enter the service account credentials to connect.
    - See https://docs.podman.io/en/latest/markdown/podman-login.1.html
    - See https://access.redhat.com/terms-based-registry/ to create the service account associated with your Red Hat customer account.
- Access Token with read-write permissions on all scopes of your Red Hat 3scale API Manager tenant.

    ![3scaleAPIM_access-token-creation.png](./images/3scaleAPIM_access-token-creation.png)

## Instructions 

### :bulb: Notes

The following environment variables are used in the scope of these instructions. Please, do set them according to your Red Hat 3scale environment.

- `ABSOLUTE_BASE_PATH`: absolute path to the working directory where you cloned this repository
- `OCP_DOMAIN`: the application domain of the Red Hat OpenShift cluster hosting the 3scale API Manager.
- `THREESCALE_TENANT`: name of the remote 3scale API Manager tenant
- `THREESCALE_TENANT_ACCESS_TOKEN`: access token with read-write permissions on all scopes of the remote 3scale API Manager tenant.
- `THREESCALE_TENANT_ADMIN_PORTAL_HOSTNAME`: FQDN of the remote 3scale API Manager tenant.
- `THREESCALE_TOOLBOX_DESTINATION`: name of the remote 3scale API Manager tenant registered in the 3scale Toolbox CLI

### I. Setup the 3scale-toolbox CLI

1. Set the following environment variables according to your 3scale environment. Example:
    ```script shell
    export ABSOLUTE_BASE_PATH=/home/lab-user
    export OCP_DOMAIN=apps.<change_me>
    export THREESCALE_TENANT=rhsi-hackfest
    export THREESCALE_TENANT_ACCESS_TOKEN=<change_me>
    export THREESCALE_TENANT_ADMIN_PORTAL_HOSTNAME=${THREESCALE_TENANT}-admin.${OCP_DOMAIN}
    export THREESCALE_TOOLBOX_DESTINATION=rhsi-hackfest-tenant
    ```

2. Create a named container that contains the remote 3scale tenant connection credentials.
    ```script shell
    podman run --name 3scale-toolbox-original \
    registry.redhat.io/3scale-amp2/toolbox-rhel8:3scale2.13 3scale remote \
    add ${THREESCALE_TOOLBOX_DESTINATION} https://${THREESCALE_TENANT_ACCESS_TOKEN}@${THREESCALE_TENANT_ADMIN_PORTAL_HOSTNAME}
    ```

3. Use `podman commit` to create a new image, `3scale-toolbox-demo`, from the named container. 
    > **NOTE**: Because the previous created container holds the remote information, the new image contains it too.
    ```script shell
    podman commit 3scale-toolbox-original 3scale-toolbox-demo
    ```

4. Create a bash alias to run the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper) using the `3scale-toolbox-demo` container image.

    > **NOTE**: The `library-books-api` 3scale resources are also mounted into the container at run-time

    ```script shell
    alias 3scale="podman run --rm -v ${ABSOLUTE_BASE_PATH}/3scale-rhsi-locationless-api-demo/ThreescaleAPIProducts/library-books-api:/tmp/toolbox/library-books-api:Z 3scale-toolbox-demo 3scale -k"
    ```

### II. Secure the _Library Books API_ services using Red Hat 3scale API Management

> **NOTE**: Both versions `v1` and `v2` are bundled and exposed as a single API product _Library Books API v2_

1. Login into the OpenShift cluster where [Red Hat 3scale API Management v2.13](https://access.redhat.com/products/red-hat-3scale/) is deployed
    ```script shell
    oc login...
    ```

2. Make sure the current OpenShift project is the one where the `Red Hat 3scale operator` is deployed. For instance:
    ```shell script
    oc project 3scale-amp
    ```

2. Using the 3scale Admin Portail UI, add the `Library Books API (v2) Backend` object to the `Library Books API (v1)` product object with the following properties. Menu: _Products -> Library Books API (v1) -> Integration -> Backends -> Add backend_
    - Backend: `Library Books API (v2) Backend`
    - Path: `/v2`

    ![](./images/3scale_add_books-api-v2-backend_to_product.png)

3. Using the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper), create the API product `v2` methods.

    - `addnewbook-v2` method:
        ```script shell
        3scale method create ${THREESCALE_TOOLBOX_DESTINATION} library-books-api addNewBook-v2 \
        --system-name=addnewbook_v2 \
        --description="Adds a new \`book-v2\` entity in the inventory."
        ```

    - `getbooks-v2` method:
        ```script shell
        3scale method create ${THREESCALE_TOOLBOX_DESTINATION} library-books-api getBooks-v2 \
        --system-name=getbooks_v2 \
        --description="Gets a list of all \`book-v2\` entities."
        ```

    ![](./images/3scale_product-v2_methods.png)

4. Using the 3scale Admin Portail UI, add the following mapping rules. Menu: _Products -> Library Books API (v1) -> Integration -> Mapping Rules -> Create mapping rule_

    - `GET /v2/books$`
        - Verb: `GET`
        - Pattern: `/v2/books$`
        - Method: `getbooks-v2`

        ![](./images/3scale_getbooks-v2_mappingrule.png)

    - `POST /v2/books$`
        - Verb: `POST`
        - Pattern: `/v2/books$`
        - Method: `addnewbook-v2`

        ![](./images/3scale_addnewbook-v2_mappingrule.png)

5. Using the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper), update the `v1` application plans to disable `v2` operations.

    - Update `Basic v1` plan 
        ```script shell
        3scale application-plan import \
        --file=/tmp/toolbox/library-books-api/threescale/application_plans/basic-v1-plan_afterv2.yaml \
        ${THREESCALE_TOOLBOX_DESTINATION} library-books-api
        ```

    - Update `Premium v1` plan
        ```script shell
        3scale application-plan import \
        --file=/tmp/toolbox/library-books-api/threescale/application_plans/premium-v1-plan_afterv2.yaml \
        ${THREESCALE_TOOLBOX_DESTINATION} library-books-api
        ```

    You can drill down into the details of each application plan to verify the configurations that has been applied. For instance, the details of the `Basic v1` are shown below.

    ![](./images/3scale_product_basicplan_v1afterv2.png)

6. Using the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper), import the `v2` application plans.

    - `Basic v2` plan 
        ```script shell
        3scale application-plan import \
        --file=/tmp/toolbox/library-books-api/threescale/application_plans/basic-v2-plan.yaml \
        ${THREESCALE_TOOLBOX_DESTINATION} library-books-api
        ```

    - `Premium v2` plan
        ```script shell
        3scale application-plan import \
        --file=/tmp/toolbox/library-books-api/threescale/application_plans/premium-v2-plan.yaml \
        ${THREESCALE_TOOLBOX_DESTINATION} library-books-api
        ```

    After importing, you should find the `Basic v2` and `Premium v2` plans on the _Library Books API (v1)_ product page of the 3scale Admin Portal.

    ![](./images/3scale_product_applicationplans_v2.png)

    You can drill down into the details of each application plan to verify the configurations that has been applied. For instance, the details of the `Basic v2` are shown below.

    ![](./images/3scale_product_basicplan_v2.png)

7. Using the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper), promote the APIcast configuration to the Staging Environment.
    ```script shell
    3scale proxy deploy ${THREESCALE_TOOLBOX_DESTINATION} library-books-api
    ```

    ![](./images/3scale_promote-staging_v2.png)

8. Using the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper), create an application with the default Developer account subscribing to the service `Basic v2` plan in order to test the configuration.
    ```script shell
    3scale application create \
    --description="Developer's Application to the Library Books API (V2 testing purposes)" \
    ${THREESCALE_TOOLBOX_DESTINATION} john library-books-api basic-plan-v2 "Developer's App (v2)"
    ```

    - `Developer's App (v2)` application credentials in 3scale:

        ![](./images/3scale_application_credentials_v2.png)

    - `Developer's App (v2)` application credentials are dynamically synchronized in Red Hat Single Sign-On:

        ![](./images/rh-sso_3scale_application_credentials_v2.png)

9. Perform some testing of your configuration in the 3scale staging environment.

    1. Test the forbidden `/v1/books` path 

        > **NOTE**: Adjust the 3scale _Staging Public Base URL_ according to your environment.

        - `GET` method:
            ```script shell
            http https://library-books-api-${THREESCALE_TENANT}-apicast-staging.${OCP_DOMAIN}/v1/books "Authorization: Bearer ${TOKEN}"
            ```

            The 3scale API gateway should reject the request.
            ```console
            HTTP/1.1 403 Forbidden
            [...]

            Authentication failed
            ```

        - `POST` method:
            ```script shell
            echo '{                                   
                "authorName": "Test Author",
                "copies": 100,
                "title": "Test Book",
                "year": 2023
            }' | http https://library-books-api-${THREESCALE_TENANT}-apicast-production.${OCP_DOMAIN}/v1/books "Authorization: Bearer ${TOKEN}" "Content-type: application/json"
            ```

            The 3scale API gateway should reject the request.
            ```console
            HTTP/1.1 403 Forbidden
            [...]

            Authentication failed
            ```

    3. Test the authorized `/v2/books` path

        > **NOTE**: Adjust the 3scale _Staging Public Base URL_ according to your environment.

        - `GET` method:
            ```script shell
            http https://library-books-api-${THREESCALE_TENANT}-apicast-staging.${OCP_DOMAIN}/v2/books "Authorization: Bearer ${TOKEN}"
            ```

            The 3scale API gateway should authorize the request.
            ```console
            HTTP/1.1 200 OK
            [...]

            [
                {
                    "author": {
                        "birthDate": "1797-08-30T00:00:00.000Z",
                        "name": "Mary Shelley"
                    },
                    "copies": 10,
                    "title": "Frankenstein",
                    "year": 1818
                },
                {
                    "author": {
                        "birthDate": "1812-02-07T00:00:00.000Z",
                        "name": "Charles Dickens"
                    },
                    "copies": 5,
                    "title": "A Christmas Carol",
                    "year": 1843
                },
                {
                    "author": {
                        "birthDate": "1775-12-16T00:00:00.000Z",
                        "name": "Charles Dickens"
                    },
                    "copies": 3,
                    "title": "Pride and Prejudice",
                    "year": 1813
                }
            ]
            ```

        - `POST` method:
            ```script shell
            echo '{
                "author": {
                    "birthDate": "1980-01-01T00:00:00.000Z",
                    "name": "Test Author"
                },
                "copies": 31,
                "title": "Test Book",
                "year": 2023
            }' | http https://library-books-api-${THREESCALE_TENANT}-apicast-staging.${OCP_DOMAIN}/v2/books "Authorization: Bearer ${TOKEN}" "Content-type: application/json"
            ```

            The 3scale API gateway should authorize the request.
            ```console
            HTTP/1.1 200 OK
            [...]

            [
                {
                    "author": {
                        "birthDate": "1797-08-30T00:00:00.000Z",
                        "name": "Mary Shelley"
                    },
                    "copies": 10,
                    "title": "Frankenstein",
                    "year": 1818
                },
                {
                    "author": {
                        "birthDate": "1812-02-07T00:00:00.000Z",
                        "name": "Charles Dickens"
                    },
                    "copies": 5,
                    "title": "A Christmas Carol",
                    "year": 1843
                },
                {
                    "author": {
                        "birthDate": "1775-12-16T00:00:00.000Z",
                        "name": "Jane Austen"
                    },
                    "copies": 3,
                    "title": "Pride and Prejudice",
                    "year": 1813
                },
                {
                    "author": {
                        "birthDate": "1980-01-01T00:00:00.000Z",
                        "name": "Test Author"
                    },
                    "copies": 31,
                    "title": "Test Book",
                    "year": 2023
                }
            ]
            ```

    4. Test rate limit (5 calls/mn). After 5 consecutive requests, the 3scale API gateway should reject your call.

        > **NOTE**: Adjust the 3scale _Staging Public Base URL_ according to your environment.
        ```script shell
        http https://library-books-api-${THREESCALE_TENANT}-apicast-staging.${OCP_DOMAIN}/v2/books "Authorization: Bearer ${TOKEN}"
        ```

        The 3scale API gateway should reject the request.
        ```console
        HTTP/1.1 429 Too Many Requests
        [...]

        Usage limit exceeded
        ```

10. After performing some tests of your configuration in the 3scale staging environment, you can now promote the latest staging Proxy Configuration to the 3scale production environment.
    ```script shell
    3scale proxy-config promote ${THREESCALE_TOOLBOX_DESTINATION} library-books-api
    ```

11. Using the 3scale Admin Portail UI, edit the name of the product to `Library Books API (v2)`. Menu: _Products -> Library Books API (v1) -> Overview -> edit_

    ![](./images/3scale_product_editname.png)

12. Using the 3scale Admin Portail UI, update the ActiveDocs with the [LibraryBooksAPI_v2.json](./library-books-api/threescale/openapi/LibraryBooksAPI_v2.json). Menu: _Products -> Library Books API (v2) -> ActiveDocs -> edit_

    > **NOTE**: Do not forget to change the name to `Library Books API (v2)`

    ![](./images/3scale_product_activedoc_v2.png)

13. Deprecate the `Basic v1` and `Premium v1` application plans so that no new applications can be created from the 3scale Developer Portal. Using the [Red Hat 3scale Toolbox CLI](https://access.redhat.com/documentation/en-us/red_hat_THREESCALE_api_management/2.13/html/operating_3scale/the-threescale-toolbox#doc-wrapper):

    - Deprecate `Basic v1` plan 
        ```script shell
        3scale application-plan apply ${THREESCALE_TOOLBOX_DESTINATION} library-books-api basic-plan-v1 --hide
        ```

    - Deprecate `Premium v1` plan
        ```script shell
        3scale application-plan apply ${THREESCALE_TOOLBOX_DESTINATION} library-books-api premium-plan-v1 --hide
        ```

    ![](./images/3scale_application-plans-v1_deprecated_.png)
