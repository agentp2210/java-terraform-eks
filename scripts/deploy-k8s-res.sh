#!/bin/bash

CLUSTER_NAME=${1:-"python-apm-demo"}
REGION=${2:-"us-east-1"}
NAMESPACE=${3:-"default"}
OPERATION=${4:-"apply"}
ACCOUNT_ID=`aws sts get-caller-identity | jq .Account -r`

# change the directory to the script location so that the relative path can work
cd "$(dirname "$0")"

cd ../terraform/

db_endpoint=`terraform output -raw postgres_endpoint`

host=$(echo $db_endpoint | awk -F ':' '{print $1}')
port=$(echo $db_endpoint | awk -F ':' '{print $2}')

TF_VAR_cluster_name=$(terraform output -raw cluster_name)
aws eks update-kubeconfig --name $TF_VAR_cluster_name  --kubeconfig ~/.kube/config --region $REGION --alias $TF_VAR_cluster_name

for config in $(ls ../k8s/*.yaml)
do
    sed -e "s/111122223333.dkr.ecr.us-west-2/$ACCOUNT_ID.dkr.ecr.$REGION/g" -e 's#\${REGION}'"#${REGION}#g" -e 's#\${DB_SERVICE_HOST}'"#${host}#g" $config | kubectl ${OPERATION} --namespace=$NAMESPACE -f -
done

kubectl ${OPERATION} -f ../k8s/alb-ingress

# Deploy traffic generator
cd ../traffic-generator

endpoint="http://$(kubectl get ingress -o json  --output jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')"

sed -e "s/SAMPLE_APP_END_POINT/$endpoint/g" traffic-generator.yaml