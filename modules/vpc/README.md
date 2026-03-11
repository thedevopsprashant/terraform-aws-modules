# How to use VPC module in your Code

This VPC module creates VPC, Public Subnets, Private Subnets. IGW for Public Subnets, EIP, NAT Gateway for Private Subnets. Their Respective RT and RT associations.
Private Subnet is Optional and If Private Subnet CIDRs not provided then NAT Gateway, Private RT, Private RT Association are not created.

## main.tf
```yaml
module "vpc" {
  source = "github.com/thedevopsprashant/terraform-aws-modules//modules/vpc?ref=v1.0.5"
 
  vpc_cidr_block = var.vpc_cidr_block
  public_subnet = var.public_subnet
  private_subnet = var.private_subnet #Optional
  env = var.env
  cluster_name = var.cluster_name

} 
```

## variables.tf
```yaml
variable "vpc_cidr_block" {
  type = string
}

variable "public_subnet" {
  type = list(string)
  default     = []
}

variable "private_subnet" {
  type = list(string)
  default     = []
}

variable "cluster_name" {
  type        = string
  description = "Cluster name to tag subnets for Karpenter/ALB discovery"
}
```


## terraform.tfvars
```yaml
vpc_cidr_block = "10.0.0.0/16"
public_subnet = ["10.0.1.0/24","10.0.2.0/24","10.0.3.0/24"]
private_subnet = ["10.0.4.0/24","10.0.5.0/24","10.0.6.0/24"] #Optional
env = "production"
cluster_name = "my-eks"
region = "ap-south-1"
```

## outputs.tf
```yaml
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "alb_subnet_public" {
  value = module.vpc.public_subnets
}
```

---
### Full Realtime Usage in Project 
Repository Name - deploy-eks-cluster-terraform

Link - https://github.com/thedevopsprashant/deploy-eks-cluster-terraform.git 