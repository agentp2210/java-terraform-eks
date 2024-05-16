terraform {
    source = "../.."
}

inputs = {
    region = "us-east-1"
    instance_type = "t2.small"
    vpc_cidr_block = "10.0.0.0/16"
    public_subnets_count = 3
    private_subnets_count = 3
    cluster_name = "eks-demo-dev"
    cloudwatch_observability_addon_version = "v1.6.0-eksbuild.1"
}