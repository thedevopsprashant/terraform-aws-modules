# How to use EKS module in your Code

This EKS module creates EKS Cluster, Node Groups - On demand & Spot, EKS Addons, Security Group for EKS Cluster, EKS Cluster Role, NodeGroup Role, Policies and Policy Attachments, Fetches OIDC URL.

## main.tf
```yaml
module "eks" {
  source = "github.com/thedevopsprashant/terraform-aws-modules//modules/eks?ref=v1.0.5"

  env          = var.env
  cluster_name = var.cluster_name
  region       = var.region

  # Input vars from other modules
  vpc_id = module.vpc.vpc_id
  subnet_ids           = module.vpc.private_subnets

  is_eks_cluster_enabled     = var.is_eks_cluster_enabled
  cluster_version            = var.cluster_version
  endpoint_private_access    = var.endpoint_private_access
  endpoint_public_access     = var.endpoint_public_access
  authentication_mode        = var.authentication_mode
  ondemand_instance_types    = var.ondemand_instance_types
  spot_instance_types        = var.spot_instance_types
  desired_capacity_on_demand = var.desired_capacity_on_demand
  min_capacity_on_demand     = var.min_capacity_on_demand
  max_capacity_on_demand     = var.max_capacity_on_demand
  desired_capacity_spot      = var.desired_capacity_spot
  min_capacity_spot          = var.min_capacity_spot
  max_capacity_spot          = var.max_capacity_spot
  addons                     = var.addons

  is_eks_role_enabled           = true
  is_eks_nodegroup_role_enabled = true
  is_alb_controller_enabled     = true

  oidc_provider_url             = module.eks.oidc_provider_url
  oidc_provider_arn             = module.eks.oidc_provider_arn

  depends_on = [module.vpc]
}
```

## variables.tf
```yaml
# EKS
variable "is_eks_cluster_enabled" {}
variable "cluster_version" {}
variable "endpoint_private_access" {}
variable "endpoint_public_access" {}
variable "authentication_mode" {}

variable "ondemand_instance_types" {}
variable "spot_instance_types" {}
variable "desired_capacity_on_demand" {}
variable "min_capacity_on_demand" {}
variable "max_capacity_on_demand" {}
variable "desired_capacity_spot" {}
variable "min_capacity_spot" {}
variable "max_capacity_spot" {}
variable "addons" {
  type = list(object({
    name    = string
    version = string
  }))
}
```


## terraform.tfvars
```yaml
# EKS
is_eks_cluster_enabled  = true
cluster_version         = "1.34"
endpoint_private_access = true
endpoint_public_access  = true
authentication_mode     = "API_AND_CONFIG_MAP"

ondemand_instance_types = ["t3a.medium"]
spot_instance_types     = ["c5a.large", "c5.large", "m5.large", "t3a.large", "t3a.medium"]

desired_capacity_on_demand = "2"
min_capacity_on_demand     = "2"
max_capacity_on_demand     = "3"

desired_capacity_spot = "2"
min_capacity_spot     = "2"
max_capacity_spot     = "3"

addons = [
  {
    name    = "vpc-cni",
    version = "v1.21.1-eksbuild.1"
  },
  {
    name    = "coredns"
    version = "v1.12.4-eksbuild.1"
  },
  {
    name    = "kube-proxy"
    version = "v1.34.1-eksbuild.2"
  },
  {
    name    = "aws-efs-csi-driver"
    version = "v2.2.0-eksbuild.1"
  },
  {
    name    = "aws-ebs-csi-driver"
    version = "v1.46.0-eksbuild.1"
  }
]
```

## outputs.tf
```yaml
# EKS Outputs
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "oidc_provider_url" {
  value = module.eks.oidc_provider_url
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}


########### Security Group Outputs ###########
output "eks_cluster_sg_id" {
  value = module.eks.eks_cluster_sg_id
}


######### IAM Outputs ###########
output "eks_cluster_role_arn" {
  value = module.eks.eks_cluster_role_arn
}

output "eks_nodegroup_role_arn" {
  value = module.eks.eks_nodegroup_role_arn
}

output "alb_controller_role_arn" {
  value = module.eks.alb_controller_role_arn
}

```

---
### Full Realtime Usage in Project 
Repository Name - deploy-eks-cluster-terraform

Link - https://github.com/thedevopsprashant/deploy-eks-cluster-terraform.git 