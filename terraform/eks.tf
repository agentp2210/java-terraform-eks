module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.10.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.29"

  enable_cluster_creator_admin_permissions = true #Add current user as an admin. Without this kubectl will not work
  cluster_endpoint_public_access           = true

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  enable_irsa = true

  cluster_addons = {
    # Note: https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html#fargate-gs-coredns
    aws-ebs-csi-driver = {
      service_account_role_arn = module.irsa-ebs-csi.iam_role_arn
    }
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  eks_managed_node_groups = {
    default = {
      desired_size = 3
      iam_role_additional_policies = [data.aws_iam_policy.ecr_policy.arn]
      instance_types = ["t3.small"]
      tags = {
        Owner = "default"
      }
      security_group_rules = {
        ingress_self_all = {
          description = "Node to node all ports/protocols"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          type        = "ingress"
          cidr_blocks = ["0.0.0.0/0"]
        }
        egress_all = {
          description = "Node all egress"
          protocol    = "-1"
          from_port   = 0
          to_port     = 0
          type        = "egress"
          cidr_blocks = ["0.0.0.0/0"]
        }
      }
    }
  }
  cluster_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_all = {
      description = "Node all egress"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
  depends_on = [ module.vpc ]
}

data "aws_iam_policy" "ecr_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess"
}

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

module "demo_service_account" {
  #checkov:skip=CKV_TF_1:sub-module hash key ignored
  source = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "5.39.0"

  create_role                   = true
  role_name                     = "DemoServiceRole-${var.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = ["arn:aws:iam::aws:policy/AmazonSQSFullAccess", "arn:aws:iam::aws:policy/AmazonS3FullAccess", "arn:aws:iam::aws:policy/AmazonKinesisFullAccess", "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"]
  oidc_fully_qualified_subjects = ["system:serviceaccount:default:visits-service-account"]
}

resource "kubernetes_service_account" "demo_service_account" {
  #checkov:skip=CKV_K8S_21:demo only, use default namespace
  metadata {
    name      = "visits-service-account"
    annotations = {
      "eks.amazonaws.com/role-arn" = module.demo_service_account.iam_role_arn
    }
  }
}

resource "kubernetes_secret" "demo_service_account" {
  #checkov:skip=CKV_K8S_21:demo only, use default namespace
  metadata {
    name      = "serviceaccount-token-secret"
    annotations = {
      "kubernetes.io/service-account.name"      = kubernetes_service_account.demo_service_account.metadata.0.name
    }
  }
  type                           = "kubernetes.io/service-account-token"
  wait_for_service_account_token = true
}


resource "aws_kinesis_stream" "apm_test_stream" {
  #checkov:skip=CKV_AWS_43:demo only, not encryption is needed
  #checkov:skip=CKV_AWS_185:demo only, not encryption is needed
  name             = "apm_test"
  shard_count      = 1
}

resource "aws_sqs_queue" "apm_test_queue" {
  #checkov:skip=CKV_AWS_27:demo only, not encryption is needed
  name                      = "apm_test"
}