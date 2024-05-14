data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  #checkov:skip=CKV2_AWS_19:low priority, skip
  #checkov:skip=CKV2_AWS_12:low priority, skip
  #checkov:skip=CKV2_AWS_11:demo only, no flow log is required
  #checkov:skip=CKV_AWS_111:demo only, not access limit is required
  #checkov:skip=CKV_AWS_356:demo only, no resource limit is required
  #checkov:skip=CKV_AWS_23:low priority, sg descriptions skip

  source  = "terraform-aws-modules/vpc/aws"
  version = "5.8.1"

  name = var.cluster_name
  cidr = var.vpc_cidr_block

  azs             = data.aws_availability_zones.available.names
  public_subnets  = [for i in range(var.public_subnets_count) : cidrsubnet(var.vpc_cidr_block, 8, i)]
  private_subnets = [for i in range(var.private_subnets_count) : cidrsubnet(var.vpc_cidr_block, 8, i + var.public_subnets_count)]
  database_subnets = ["10.0.201.0/24", "10.0.202.0/24", "10.0.203.0/24"]
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "karpenter.sh/discovery"                    = var.cluster_name
    "kubernetes.io/role/internal-elb"           = 1
  }
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "kubernetes.io/role/elb" = 1
  }
}

resource "aws_security_group_rule" "example" {
  #checkov:skip=CKV_AWS_23:low priority, skip
  type              = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = module.vpc.default_security_group_id
}
