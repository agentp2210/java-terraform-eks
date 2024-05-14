variable "region" {
  default = "us-east-1"
}

variable "project_name" {
  description = "The name of the project"
  default     = "TEST"
  type        = string
}

variable "instance_type" {
  description = "The EC2 Instance type"
  default     = "t2.micro"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The main CIDR for the VPC"
  default     = "10.0.0.0/16"
  type        = string
}

variable "public_subnets_count" {
  description = "Number of public subnets"
  default     = 3
  type        = number
  validation {
    condition     = var.public_subnets_count >= 2
    error_message = "Number of public subnets needs to be greater or equal than 2"
  }
}

variable "private_subnets_count" {
  description = "Number of private subnets"
  default     = 3
  type        = number
  validation {
    condition     = var.private_subnets_count >= 2
    error_message = "Number of private subnets needs to be greater or equal than 2"
  }
}

variable "ssh_public_key" {
  default = "./sshkey/id_rsa.pub"
}

variable "cluster_name" {
  default = "app-signals-demo"
}

variable "cloudwatch_observability_addon_version" {
  default = "v1.6.0-eksbuild.1"
}