## Observability Demo using GKE and Dynatrace


The goal of the demo is to provision a kubernetes cluster in GCP, install and configure cluster integration with Dynatrace.

Ther following is step by step how to provision GKE cluster, install Dynatrace Operator and target application.

1. Ensure you have the following requirements:
   - [Google Cloud project](https://cloud.google.com/resource-manager/docs/creating-managing-projects#creating_a_project).
   - Shell environment with `gcloud`, `git`, and `kubectl`.

2. Cluster provisioning uses terraform. It follows closely standard deployment proposed by Terraform documentation: https://developer.hashicorp.com/terraform/tutorials/kubernetes/gke

   - Terraform configuration files in this project [terraform](#terraform) are a minor fork of publicly made available project by Hashicorp: https://github.com/hashicorp/learn-terraform-provision-gke-cluster


   - You can use official documentation to provision the cluster, however, there is bash script `dynatrace-setup.sh` to help install all necessary componets automatically (GKE cluster, Dynatrace Operator, and application). See more information below.



3. Dynatrace operator installation follows documentation from:
    - Git hub project: https://github.com/Dynatrace/dynatrace-operator

    The recommended approach is using classic fullstack injection to roll out Dynatrace to target cluster cluster
    https://www.dynatrace.com/support/help/setup-and-configuration/setup-on-k8s/installation/classic-full-stack


   - You can use official documentation to deploy Dynatrace operator, however, there is bash script `dynatrace-setup.sh` to help install all necessary componets automatically (GKE cluster, Dynatrace Operator, and application). See more information below.


4. Applicaiton deployment
    - For this demo a mustiservice architecture is used to highlight some key features in Dynatrace.
    - Online Boutique is a common open source used for demos,  project made available by Google Cloud team [Online Boutique] (https://github.com/GoogleCloudPlatform/microservices-demo)
    - This application is composed of 11 microservices written in different languages that talk to each other over gRPC.

    - You can use official documentation to deploy the application, however, there is bash script `dynatrace-setup.sh` to help install all necessary componets automatically (GKE cluster, Dynatrace Operator, and application). See more information below.

4. Utility script used for cluster provisioning, Dynatrace Operator deployment, and application deployment.

```bash
$ ./dynatrace-setup.sh  --help

Usage:

    ./dynatrace-setup.sh [--provision-cluster --gke-project-id <PROJECT_ID>] [--deploy-dynatrace-operator --api-token <TOKEN> --data-ingest-token <TOKEN> --api-url <URL>] 
                         [--deploy-application] [--delete-dynatrace-operator --api-token <TOKEN> --data-ingest-token <TOKEN> --api-url <URL>] [--delete-application]

        --provision-cluster
            Provision GKE cluster (terraform)
        --gke-project-id
            Project ID where new cluster is going to be provisioned
        --deploy-dynatrace-operator
            Deploy Dynatrace Operator
        --api-token
            Dynatrace account API Token
        --data-ingest-token
            Dynatrace account Data Ingestion Token
        --api-url
            You account API URL: i.e. https://xyz87654.live.dynatrace.com/api
        --deploy-application:
            Deploy demo application
        --delete-dynatrace-operator
            Uninstall Dynatrace operator from cluster
        --delete-application
            Uninstall appliocation 
```


    - An example of automatic provisionig and configuration in one command is:

```bash
# replace arguments with your own specific info
./dynatrace-setup.sh --provision-cluster --gke-project-id my-project-id \
                --deploy-dynatrace-operator --api-token XXXXXXXXXXXXXXXX --data-ingest-token YYYYYYYYYYYYYYYYYYY --api-url https://xyz87654.live.dynatrace.com/api \
                --deploy-application
```

    - Typically a cluster provisioning happens less ofthen, more common scenario is to install or unistall the Dynatrace operator or application:

```bash
# install application
./dynatrace-setup.shent.sh --deploy-application
namespace/dynatrace created
poddisruptionbudget.policy/dynatrace-webhook created
serviceaccount/dynatrace-activegate created
serviceaccount/dynatrace-kubernetes-monitoring created
serviceaccount/dynatrace-dynakube-oneagent-privileged created
serviceaccount/dynatrace-dynakube-oneagent-unprivileged created
serviceaccount/dynatrace-operator created
serviceaccount/dynatrace-webhook created
customresourcedefinition.apiextensions.k8s.io/dynakubes.dynatrace.com configured
clusterrole.rbac.authorization.k8s.io/dynatrace-kubernetes-monitoring unchanged
clusterrole.rbac.authorization.k8s.io/dynatrace-operator unchanged
clusterrole.rbac.authorization.k8s.io/dynatrace-webhook unchanged
clusterrolebinding.rbac.authorization.k8s.io/dynatrace-kubernetes-monitoring unchanged
clusterrolebinding.rbac.authorization.k8s.io/dynatrace-operator unchanged
clusterrolebinding.rbac.authorization.k8s.io/dynatrace-webhook unchanged
role.rbac.authorization.k8s.io/dynatrace-operator created
role.rbac.authorization.k8s.io/dynatrace-webhook created
rolebinding.rbac.authorization.k8s.io/dynatrace-operator created
rolebinding.rbac.authorization.k8s.io/dynatrace-webhook created
service/dynatrace-webhook created
deployment.apps/dynatrace-operator created
deployment.apps/dynatrace-webhook created
mutatingwebhookconfiguration.admissionregistration.k8s.io/dynatrace-webhook unchanged
validatingwebhookconfiguration.admissionregistration.k8s.io/dynatrace-webhook configured
pod/dynatrace-webhook-7569799cb-7h4rk condition met
secret/arctiq created
dynakube.dynatrace.com/arctiq created

```

```bash
$ ./dynatrace-setup.sh --delete-application
deployment.apps "emailservice" deleted
service "emailservice" deleted
deployment.apps "checkoutservice" deleted
service "checkoutservice" deleted
deployment.apps "recommendationservice" deleted
service "recommendationservice" deleted
deployment.apps "frontend" deleted
service "frontend" deleted
service "frontend-external" deleted
deployment.apps "paymentservice" deleted
service "paymentservice" deleted
deployment.apps "productcatalogservice" deleted
service "productcatalogservice" deleted
deployment.apps "cartservice" deleted
service "cartservice" deleted
deployment.apps "loadgenerator" deleted
deployment.apps "currencyservice" deleted
service "currencyservice" deleted
deployment.apps "shippingservice" deleted
service "shippingservice" deleted
deployment.apps "redis-cart" deleted
service "redis-cart" deleted
deployment.apps "adservice" deleted
service "adservice" deleted

```

5. Connect to your Dynatrace account and happy Dynatrace platform discovery.