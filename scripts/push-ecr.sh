#!/bin/bash
cd "$(dirname "$0")"

cd ..

# Remove old tags
old_images=$(docker images | grep amazonaws | awk '{print $1}')
if [ -n $old_images ]; then
    for i in $old_images; do
        docker rmi $i
    done
fi

# Build images if not exist
existing_images=$(docker images | grep springcommunity | awk '{print $1}')

if [ -z "$existing_images" ]; then
    ./mvnw clean install -P buildDocker
fi

# Push to ECR
cd ..

export ACCOUNT=`aws sts get-caller-identity | jq .Account -r`
export REGION=us-east-1

export REPOSITORY_PREFIX=${ACCOUNT}.dkr.ecr.${REGION}.amazonaws.com

aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin ${REPOSITORY_PREFIX}

docker tag springcommunity/spring-petclinic-api-gateway:latest ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-api-gateway:latest
docker push ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-api-gateway:latest

docker tag springcommunity/spring-petclinic-discovery-server:latest ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-discovery-server:latest
docker push ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-discovery-server:latest

docker tag springcommunity/spring-petclinic-config-server:latest ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-config-server:latest
docker push ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-config-server:latest

docker tag springcommunity/spring-petclinic-visits-service:latest ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-visits-service:latest
docker push ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-visits-service:latest

docker tag springcommunity/spring-petclinic-vets-service:latest ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-vets-service:latest
docker push ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-vets-service:latest

docker tag springcommunity/spring-petclinic-customers-service:latest ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-customers-service:latest
docker push ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-customers-service:latest

docker tag springcommunity/spring-petclinic-admin-server:latest ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-admin-server:latest
docker push ${REPOSITORY_PREFIX}/springcommunity/spring-petclinic-admin-server:latest


if [ -z "$(docker images | grep "insurance-service")" ]; then
    docker build -t insurance-service ./pet_clinic_insurance_service --no-cache
fi
docker tag insurance-service:latest ${REPOSITORY_PREFIX}/python-petclinic-insurance-service:latest
docker push ${REPOSITORY_PREFIX}/python-petclinic-insurance-service:latest


if [ -z "$(docker images | grep "billing-service")" ]; then
    docker build -t billing-service ./pet_clinic_billing_service --no-cache
fi
docker tag billing-service:latest ${REPOSITORY_PREFIX}/python-petclinic-billing-service:latest
docker push ${REPOSITORY_PREFIX}/python-petclinic-billing-service:latest

aws ecr create-repository --repository-name traffic-generator --region ${REGION} --no-cli-pager || true
if [ -z "$(docker images | grep "traffic-generator")" ]; then
    docker build -t traffic-generator ./traffic-generator --no-cache
fi
docker tag traffic-generator:latest ${REPOSITORY_PREFIX}/traffic-generator:latest
docker push ${REPOSITORY_PREFIX}/traffic-generator:latest