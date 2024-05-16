./scripts/create-infra.sh
./scripts/push-ecr.sh
./scripts/deploy-k8s-res.sh

endpoint="http://$(kubectl get ingress -o json  --output jsonpath='{.items[0].status.loadBalancer.ingress[0].hostname}')"

echo "Visit the following URL to see the sample app running: $endpoint"