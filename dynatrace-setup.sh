#!/bin/bash

set -eEuo pipefail

usage() {
echo "
Usage:

    ${0} [--provision-cluster --gke-project-id <PROJECT_ID>] [--deploy-dynatrace-operator --api-token <TOKEN> --data-ingest-token <TOKEN> --api-url <URL>] 
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
        --deploy-application
            Deploy demo application
        --delete-dynatrace-operator
            Uninstall Dynatrace operator from cluster
        --delete-application
            Uninstall appliocation 
" >&2
    exit 1
}

provision_cluster() {
    pushd terraform >/dev/null
    terraform plan -var="project_id=${project_id}"
    terraform apply -var="project_id=${project_id}" # -auto-approve
    gcloud container clusters get-credentials "$(terraform output -raw kubernetes_cluster_name)" --region "$(terraform output -raw region)"
    popd >/dev/null
}

deploy_dynatrace_operator() {
    if ! kubectl get namespace dynatrace &> /dev/null; then
        kubectl create namespace dynatrace
    fi
    kubectl apply -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v0.12.1/kubernetes.yaml
    kubectl -n dynatrace wait pod --for=condition=ready --selector=app.kubernetes.io/name=dynatrace-operator,app.kubernetes.io/component=webhook --timeout=300s
    cp dynakube.yaml .dynakube.tmp.yaml
    sed -e "s,%%API_TOKEN%%,${api_token},g" -e "s,%%DATA_INGEST_TOKEN%%,${data_ingest_token},g" -e "s,%%API_URL%%,${api_url},g" -i .dynakube.tmp.yaml
    kubectl apply -f .dynakube.tmp.yaml
    rm -f .dynakube.tmp.yaml
}

deploy_app() {
    if [[ -d "microservices-demo" ]]; then
        rm -rf microservices-demo
    fi
    git clone --quiet https://github.com/GoogleCloudPlatform/microservices-demo.git
    pushd microservices-demo >/dev/null
    kubectl apply -f ./release/kubernetes-manifests.yaml
    popd >/dev/null
    rm -rf microservices-demo
}

delete_dynatrace_operator() {
    cp dynakube.yaml .dynakube.tmp.yaml
    sed -e "s,%%API_TOKEN%%,${api_token},g" -e "s,%%DATA_INGEST_TOKEN%%,${data_ingest_token},g" -e "s,%%API_URL%%,${api_url},g" -i .dynakube.tmp.yaml
    kubectl delete -f .dynakube.tmp.yaml
    rm -f .dynakube.tmp.yaml
    kubectl delete -f https://github.com/Dynatrace/dynatrace-operator/releases/download/v0.12.1/kubernetes.yaml
    kubectl delete namespace  dynatrace
}

delete_app() {
    git clone --quiet https://github.com/GoogleCloudPlatform/microservices-demo.git
    pushd microservices-demo >/dev/null
    kubectl delete -f ./release/kubernetes-manifests.yaml
    popd >/dev/null
    rm -rf microservices-demo
}

main() {
    provision_cluster=false
    deploy_dynatrace_operator=false
    deploy_application=false
    delete_dynatrace_operator=false
    delete_application=false
    project_id=""
    data_ingest_token=""
    api_token=""
    api_url=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --provision-cluster)
                provision_cluster=true
                shift 1
                ;;
           --gke-project-id)
                project_id=$2
                shift 2
                ;;
            --deploy-dynatrace-operator)
                deploy_dynatrace_operator=true
                shift 1
                ;;
            --api-token)
                api_token=$2
                shift 2
                ;;
            --data-ingest-token)
                data_ingest_token=$2
                shift 2
                ;;
            --api-url)
                api_url=$2
                shift 2
                ;;
            --deploy-application)
                deploy_application=true
                shift 1
                ;;
            --delete-application)
                delete_application=true
                shift 1
                ;;
            --delete-dynatrace-operator)
                delete_dynatrace_operator=true
                shift 1
                ;;
            --help)
                usage
                ;;
            *)
                echo "Unknown option: '$1'"
                usage
                ;;
        esac
    done

    if ${provision_cluster}; then
        if [[ -z "${project_id}" ]]; then
           echo "When provisioning a new cluster GKE project id  must be provided with '--gke-project-id'"
           usage
        fi
        provision_cluster
    fi

    if ${deploy_dynatrace_operator}; then
        if [[ -z "${api_token}" || -z "${data_ingest_token}" || -z "${api_url}" ]]; then
           echo "Operator deployment requires following arguments '--api-token', '--data-ingest-token', and '--api-url'"
           usage
        fi
        deploy_dynatrace_operator
    fi

    if ${delete_dynatrace_operator}; then
        if [[ -z "${api_token}" || -z "${data_ingest_token}" || -z "${api_url}" ]]; then
           echo "Operator unistall requires following arguments '--api-token', '--data-ingest-token', and '--api-url'"
           usage
        fi
        delete_dynatrace_operator
    fi

    if ${deploy_application}; then
        deploy_app
    fi

    if ${delete_application}; then
        delete_app
    fi
}

main "$@"
