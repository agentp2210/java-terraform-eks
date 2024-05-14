# EKS demo

1. Create the infra
``` shell
aws configure
./scripts/create-infra.sh
```

2. Build and push docker images
``` shell
./scripts/push-ecr.sh
```