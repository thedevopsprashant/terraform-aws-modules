# How to use HELM module in your Code

This helm module can be used to install different tools/Apps like ALB Controller, Prometheus-Grafan-Stack, ArgoCD, etc. This needs VPC, EKS cluster needs to be created first, that can be done using VPC, EKS modules present in this Repo. 
Proper versions.tf and provider.tf should also be defined in root project.

## main.tf
```yaml
module "helm" {
  source = "github.com/thedevopsprashant/terraform-aws-modules//modules/helm?ref=v1.0.6"

  cluster_name            = module.eks.cluster_name
  vpc_id                  = module.vpc.vpc_id
  region                  = var.region
  alb_controller_role_arn = module.eks.alb_controller_role_arn

  alb_controller_version = "3.0.0"
  argocd_version = "9.4.6"
  prometheus_stack_version = "81.0.0"

  depends_on = [module.eks, module.vpc]
}
```

## versions.tf
```yaml
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 6.0.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0.0"
    }
    helm = {
      source = "hashicorp/helm"
      version = "~> 2.17.0"
    }
  }
}
```

## provider.tf
```yaml
provider "aws" {
  region = var.region
}

provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    command     = "aws"
  }
}

provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
      command     = "aws"
    }
  }
}
```

---
### Full Realtime Usage in Project 
Repository Name - deploy-eks-cluster-terraform

Link - https://github.com/thedevopsprashant/deploy-eks-cluster-terraform.git 