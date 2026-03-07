# Terraform AWS Modules

A collection of reusable Terraform modules for provisioning AWS infrastructure, specifically designed for Kubernetes clusters and cloud-native deployments. This repository contains production-ready modules for VPC, EKS, and Helm chart deployments.

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Module Structure](#module-structure)
- [Modules](#modules)
  - [VPC Module](#vpc-module)
  - [EKS Module](#eks-module)
  - [Helm Module](#helm-module)
- [Usage](#usage)
- [Examples](#examples)
- [Contributing](#contributing)
- [License](#license)

## Overview

This Terraform modules repository provides a modular approach to infrastructure as code (IaC) on AWS. The modules are designed to be reusable, scalable, and production-ready. They work together to create a complete EKS-based Kubernetes infrastructure with networking, cluster management, and cloud-native applications.

### Key Features

✅ **VPC Module** - Complete networking setup with public/private subnets, NAT Gateway, and EKS-optimized configuration

✅ **EKS Module** - Fully managed Kubernetes cluster with on-demand and spot instance node groups

✅ **Helm Module** - Pre-configured Helm deployments for ALB Controller, ArgoCD, and Prometheus Stack

✅ **Reusable** - Designed for code reusability across multiple environments and projects

✅ **Production-Ready** - Includes security groups, IAM roles, and best practices

## Prerequisites

Before using these modules, ensure you have:

- **Terraform** >= 1.0
- **AWS Account** with appropriate permissions
- **AWS CLI** configured with credentials
- **Helm** >= 3.7.0 (for Helm module)
- **kubectl** (for Kubernetes cluster management)

## Module Structure

```
terraform-aws-modules/
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   ├── eks/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── README.md
│   └── helm/
│       ├── alb-controller-helm.tf
│       ├── argocd-helm.tf
│       ├── prometheus.tf
│       ├── variables.tf
│       ├── outputs.tf
│       └── README.md
├── examples/
├── README.md
└── LICENSE
```

## Modules

### VPC Module

Creates a complete VPC infrastructure with networking components optimized for Kubernetes.

**Resources Created:**
- VPC with DNS enabled
- Public Subnets (with auto-assign public IP)
- Private Subnets (no public IP)
- Internet Gateway
- NAT Gateway with Elastic IP
- Public Route Table (routes to IGW)
- Private Route Table (routes to NAT Gateway)
- Kubernetes-specific subnet tags for ALB/ELB discovery

**Module Source:**
```hcl
source = "github.com/thedevopsprashant/terraform-aws-modules//modules/vpc?ref=v1.0.5"
```

**Key Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| `vpc_cidr_block` | string | CIDR block for VPC (e.g., "10.0.0.0/16") |
| `public_subnet` | list(string) | CIDR blocks for public subnets |
| `private_subnet` | list(string) | CIDR blocks for private subnets |
| `env` | string | Environment name (e.g., "dev", "prod") |
| `cluster_name` | string | EKS cluster name for subnet tagging |

**Outputs:**
| Output | Description |
|--------|-------------|
| `vpc_id` | VPC ID |
| `public_subnets` | List of public subnet IDs |
| `private_subnets` | List of private subnet IDs |

---

### EKS Module

Provisions a fully managed Amazon EKS cluster with worker nodes and required IAM roles.

**Resources Created:**
- EKS Cluster
- EKS Node Groups (On-Demand and Spot instances)
- IAM Roles and Policies (Cluster and Node roles)
- Security Groups
- EKS Add-ons (vpc-cni, coredns, kube-proxy, ebs-csi-driver, efs-csi-driver)
- OIDC Provider for IRSA (IAM Roles for Service Accounts)
- ALB Controller IAM Role

**Module Source:**
```hcl
source = "github.com/thedevopsprashant/terraform-aws-modules//modules/eks?ref=v1.0.5"
```

**Key Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| `cluster_name` | string | Name of the EKS cluster |
| `cluster_version` | string | Kubernetes version (e.g., "1.28") |
| `endpoint_private_access` | bool | Enable private API endpoint |
| `endpoint_public_access` | bool | Enable public API endpoint |
| `authentication_mode` | string | Authentication mode ("API", "API_AND_CONFIG_MAP") |
| `ondemand_instance_types` | list(string) | EC2 instance types for on-demand nodes |
| `spot_instance_types` | list(string) | EC2 instance types for spot nodes |
| `desired_capacity_on_demand` | string | Desired number of on-demand nodes |
| `addons` | list(object) | List of EKS add-ons with versions |

**Outputs:**
| Output | Description |
|--------|-------------|
| `eks_cluster_id` | EKS cluster name |
| `eks_cluster_arn` | EKS cluster ARN |
| `oidc_provider_arn` | OIDC provider ARN for IRSA |
| `oidc_provider_url` | OIDC provider endpoint URL |

---

### Helm Module

Deploys critical Kubernetes applications using Helm charts.

**Helm Releases Deployed:**
1. **AWS Load Balancer Controller** - Manages AWS ALB/NLB creation for Kubernetes services
2. **ArgoCD** - GitOps continuous deployment platform
3. **Prometheus Stack** (kube-prometheus-stack) - Complete monitoring solution with Prometheus, Grafana, and Alert Manager

**Module Source:**
```hcl
source = "github.com/thedevopsprashant/terraform-aws-modules//modules/helm?ref=v1.0.6"
```

**Key Variables:**
| Variable | Type | Description |
|----------|------|-------------|
| `cluster_name` | string | EKS cluster name |
| `region` | string | AWS region |
| `vpc_id` | string | VPC ID for ALB Controller |
| `alb_controller_version` | string | ALB Controller Helm chart version |
| `argocd_version` | string | ArgoCD Helm chart version |
| `prometheus_stack_version` | string | Prometheus stack Helm chart version |
| `alb_controller_role_arn` | string | IAM role ARN for ALB Controller |

**Outputs:**
| Output | Description |
|--------|-------------|
| `argocd_server` | ArgoCD server URL |
| `prometheus_url` | Prometheus service LoadBalancer URL |
| `grafana_url` | Grafana service LoadBalancer URL |

---

## Usage

### Basic Usage

1. **Create a root Terraform configuration:**

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.17.0"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.main.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.main.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.main.token
  }
}
```

2. **Reference the modules:**

```hcl
module "vpc" {
  source = "github.com/thedevopsprashant/terraform-aws-modules//modules/vpc?ref=v1.0.5"
  
  vpc_cidr_block = "10.0.0.0/16"
  public_subnet  = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  env            = "dev"
  cluster_name   = "my-eks"
}

module "eks" {
  source = "github.com/thedevopsprashant/terraform-aws-modules//modules/eks?ref=v1.0.5"
  
  cluster_name = "my-eks"
  cluster_version = "1.28"
  vpc_id = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  
  # ... additional configuration
}

module "helm" {
  source = "github.com/thedevopsprashant/terraform-aws-modules//modules/helm?ref=v1.0.6"
  
  cluster_name = "my-eks"
  region = "ap-south-1"
  
  # ... additional configuration
}
```

## Examples

### Complete Infrastructure with VPC, EKS, and Helm

See the [deploy-eks-cluster-terraform](../deploy-eks-cluster-terraform) directory for a complete working example that demonstrates:

- VPC setup with proper networking configuration
- EKS cluster creation with mixed node groups (on-demand + spot instances)
- Helm deployments for ALB Controller, ArgoCD, and Prometheus
- Proper variable passing between modules
- Terraform state management best practices

### Running the Example

```bash
cd deploy-eks-cluster-terraform

# Initialize Terraform
terraform init

# Plan the infrastructure
terraform plan -out=tfplan

# Apply to create AWS resources
terraform apply tfplan

# Get outputs
terraform output
```

## Contributing

We welcome contributions! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch (`git checkout -b feature/improvement`)
3. **Make** your changes with clear commit messages
4. **Test** your changes thoroughly
5. **Submit** a pull request with description of changes

### Development Standards

- Use descriptive variable and resource names
- Include comments for complex logic
- Follow Terraform best practices
- Add/update documentation for new features
- Use consistent formatting (terraform fmt)

## License

This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.

---

## Support & Troubleshooting

For common issues and troubleshooting:

1. Check module-specific READMEs in each module directory
2. Review Terraform error messages carefully
3. Verify AWS IAM permissions
4. Ensure all prerequisites are installed and configured
5. Check the example configurations for proper usage

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest)
- [EKS Best Practices](https://aws.amazon.com/eks/best-practices/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Charts Repository](https://helm.sh/)

---

**Author:** thedevopsprashant

**Last Updated:** March 2026