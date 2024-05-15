# EKS demo
ref: [https://github.com/aws-observability/application-signals-demo](https://github.com/aws-observability/application-signals-demo)

1. Create the infra
``` shell
aws configure
./scripts/create-infra.sh
```

2. Build and push docker images
``` shell
./scripts/push-ecr.sh
```

3. Deploy k8s resources
``` shell
./scripts/deploy-k8s-res.sh
```