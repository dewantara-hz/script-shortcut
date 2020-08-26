#!/bin/sh

#parameter
_opt=$1

# shift param to remove 1st parameter (options)
shift

#var
ORANGE='\033[0;33m'
NC='\033[0m' # No Color
namespace=$(kubectl config view --minify | grep namespace: | cut -f2 -d ":")
context=$(kubectl config view --minify | grep context: | cut -f2 -d ":")
allNamespaces=""
params=$@

# interactive options
# Loop until all parameters are used up
while [ "$1" != "" ]; do
        case $1 in
        -n | --namespace )           shift
                                namespace=$1
                                ;;
        --context )           shift
                                context=$1
                                ;;
        --all-namespaces )           shift
                                allNamespaces=true
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

# Determine status column
if [ "$allNamespaces" = true ]; then
    statusColumn="\$4"
else
    statusColumn="\$3"
fi

# Functions
function kubeinfo () {
    # Context
    echo "${ORANGE}Context${NC}"
    echo $context
    echo ''

    # Namespace
    echo "${ORANGE}Namespace${NC}"
    echo $namespace
    echo ''

    # Deployments
    echo "${ORANGE}Deployments${NC}"
    command="kubectl get deployments -o wide $params"
    eval $command
    echo ''

    # Ingress
    echo "${ORANGE}Ingresses${NC}"
    command="kubectl get ingress -o wide $params"
    eval $command
    echo ''
    command="kubectl get ing $params -o custom-columns=\"NAME:.metadata.name,CANARY CLASS:.metadata.annotations.kubernetes\.io/ingress\.class,CANARY WEIGHT:.metadata.annotations.nginx\.ingress\.kubernetes\.io/canary-weight,HOSTS:.spec.rules[*].host,BACKENDS:.spec.rules[*].http.paths[*].backend.serviceName,SERVICE PORTS:.spec.rules[*].http.paths[*].backend.servicePort,PATHS:.spec.rules[*].http.paths[*].path\""
    eval $command
    echo ''

    # Services
    echo "${ORANGE}Services${NC}"
    command="kubectl get services -o wide $params"
    eval $command
    echo ''
    command="kubectl get services $params -o custom-columns=\"NAME:.metadata.name,NEG:.metadata.annotations.cloud\.google\.com/neg,NEG STATUS:.metadata.annotations.cloud\.google\.com/neg-status\""
    eval $command
    echo ''

    # Endpoints
    echo "${ORANGE}Endpoints${NC}"
    command="kubectl get endpoints -o wide $params"
    eval $command
    echo ''

    # Configmaps
    echo "${ORANGE}Configmaps${NC}"
    command="kubectl get configmap -o wide $params"
    eval $command
    echo ''

    # Secrets
    echo "${ORANGE}Secrets${NC}"
    command="kubectl get secret -o wide $params"
    eval $command
    echo ''

    # HPA
    echo "${ORANGE}HPA${NC}"
    command="kubectl get hpa -o wide $params"
    eval $command
    echo ''

    # ResourceQuota
    echo "${ORANGE}ResourceQuota${NC}"
    command="kubectl get resourcequota -o wide $params"
    eval $command
    echo ''

    # Cronjobs
    echo "${ORANGE}Cronjobs${NC}"
    command="kubectl get cronjob -o wide $params"
    eval $command
    echo ''

    # Statefulsets
    echo "${ORANGE}Statefulsets${NC}"
    command="kubectl get statefulset -o wide $params"
    eval $command
    echo ''

    # PersistentVolumeClaims
    echo "${ORANGE}PesistentVolumeClaims${NC}"
    command="kubectl get persistentvolumeclaim -o wide $params"
    eval $command
    echo ''

    # Jobs
    echo "${ORANGE}Jobs${NC}"
    command="kubectl get jobs -o wide $params"
    eval $command
    echo ''

    # Replica sets
    echo "${ORANGE}Replica sets${NC}"
    command="kubectl get rs -o wide $params"
    eval $command
    echo ''

    # Pods
    echo "${ORANGE}Pods${NC}"
    command="kubectl get pods -o wide $params"
    eval $command
    echo ''
}

function kuberestart () {
    kubectl get deployments $params
    echo ''

    deploymentName=$(kubectl get deploy $params | awk 'FNR == 2 {print $1}')
    read -p "Do you want to restart $deploymentName (yes/no/<deployment_name>)? " confirmation
    if [ "$confirmation" == "yes" ]; then
        kubectl patch deployment $deploymentName $params -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"restart\":\"$(date)\"}}}}}"

        kubectl get deployment $params -w
    elif [ "$confirmation" == "no" ]; then
        echo "skipped"
    else
        kubectl patch deployment $confirmation $params -p "{\"spec\":{\"template\":{\"metadata\":{\"annotations\":{\"restart\":\"$(date)\"}}}}}"

        kubectl get deployment -w
    fi
}

function kubeexec () {
    kubectl get pods $params
    echo ''

    podName=$(kubectl get pods $params | awk 'FNR == 2 {print $1}')
    read -p "Do you want to exec $podName (yes/no/<deployment_name>)? " confirmation
    if [ "$confirmation" == "yes" ]; then
        kubectl exec -it $podName $params sh
    elif [ "$confirmation" == "no" ]; then
        echo "skipped"
    else
        kubectl exec -it $confirmation $params sh
    fi
}

# Options
if [ "$_opt" = "restart" ]; then
    kuberestart
elif [ "$_opt" = "info" ]; then
    kubeinfo
elif [ "$_opt" = "exec" ]; then
    kubeexec
fi