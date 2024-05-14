terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.44.0"
    }
      kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.7.1"
    }
  }
  backend "s3" {
    # bucket         = "terraform-backend-terraformbackends3bucket-cbgsm0d5zojc"
    # key            = "testing"
    # region         = "us-east-1"
    # dynamodb_table = "terraform-backend-TerraformBackendDynamoDBTable-1XFKJYQG2G0XY"
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = {
      "Environment" = "dev"
      "Project"     = "Terraform"
    }
  }
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
  debug = true
}