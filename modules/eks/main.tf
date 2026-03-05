resource "aws_eks_cluster" "eks" {

  count    = var.is_eks_cluster_enabled == true ? 1 : 0
  name     = var.cluster_name
  role_arn = aws_iam_role.eks-cluster-role[0].arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids              = var.subnet_ids
    endpoint_private_access = var.endpoint_private_access
    endpoint_public_access  = var.endpoint_public_access
    security_group_ids      = aws_security_group.eks-cluster-sg.id
  }


  access_config {
    authentication_mode                         = var.authentication_mode
    bootstrap_cluster_creator_admin_permissions = true
  }

  tags = {
    Name = var.cluster_name
    Env  = var.env
  }
}


# NodeGroups
resource "aws_eks_node_group" "ondemand-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster_name}-on-demand-nodes"

  node_role_arn = aws_iam_role.eks-nodegroup-role[0].arn

  scaling_config {
    desired_size = var.desired_capacity_on_demand
    min_size     = var.min_capacity_on_demand
    max_size     = var.max_capacity_on_demand
  }

  subnet_ids = var.subnet_ids

  instance_types = var.ondemand_instance_types
  capacity_type  = "ON_DEMAND"
  labels = {
    type = "ondemand"
  }

  update_config {
    max_unavailable = 1
  }
  tags = {
    "Name" = "${var.cluster_name}-ondemand-nodes"
  }
  tags_all = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "Name"                                      = "${var.cluster_name}-ondemand-nodes"
  }

  depends_on = [aws_eks_cluster.eks]
}

resource "aws_eks_node_group" "spot-node" {
  cluster_name    = aws_eks_cluster.eks[0].name
  node_group_name = "${var.cluster_name}-spot-nodes"

  node_role_arn = aws_iam_role.eks-nodegroup-role[0].arn

  scaling_config {
    desired_size = var.desired_capacity_spot
    min_size     = var.min_capacity_spot
    max_size     = var.max_capacity_spot
  }

  subnet_ids = var.subnet_ids

  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"

  update_config {
    max_unavailable = 1
  }
  tags = {
    "Name" = "${var.cluster_name}-spot-nodes"
  }
  tags_all = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned" # The resource is created and managed specifically for this cluster. If the cluster is deleted, these resources should be cleaned up.
    "Name"                                      = "${var.cluster_name}-ondemand-nodes"
  }

  # "shared": The resource can be used by multiple clusters (less common for node groups, more for subnets/VPCs).

  labels = {
    type      = "spot"
    lifecycle = "spot"
  }
  disk_size = 50

  depends_on = [aws_eks_cluster.eks]
}

# AddOns for EKS Cluster
resource "aws_eks_addon" "eks-addons" {
  for_each      = { for idx, addon in var.addons : idx => addon }
  cluster_name  = aws_eks_cluster.eks[0].name
  addon_name    = each.value.name
  addon_version = each.value.version

  depends_on = [
    aws_eks_node_group.ondemand-node,
    aws_eks_node_group.spot-node
  ]
}

################### Security Groups #####################
resource "aws_security_group" "eks-cluster-sg" {
  name        = "eks-cluster-sg-${terraform.workspace}"
  # description = "Allow 443 from Jump Server only"
  description = "Allow 443 from anywhere"

  vpc_id = var.vpc_id

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    # security_groups = [aws_security_group.bastion-sg.id]
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "eks-cluster-sg-${terraform.workspace}"
  }
}

# resource "aws_security_group" "bastion-sg" {
#   name        = "bastion-sg-${terraform.workspace}"
#   description = "Allow SSH to Bastion"
#   vpc_id      = var.vpc_id

#   ingress {
#     from_port   = 22
#     to_port     = 22
#     protocol    = "tcp"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }

#   tags = {
#     Name = "bastion-sg-${terraform.workspace}"
#   }
# }





################### IAM #####################

locals {
  cluster_name = var.cluster_name
}

resource "random_integer" "random_suffix" {
  min = 1000
  max = 9999
}

resource "aws_iam_role" "eks-cluster-role" {
  count = var.is_eks_role_enabled ? 1 : 0
  name  = "${local.cluster_name}-role-${random_integer.random_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "AmazonEKSClusterPolicy" {
  count      = var.is_eks_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks-cluster-role[count.index].name
}

resource "aws_iam_role" "eks-nodegroup-role" {
  count = var.is_eks_nodegroup_role_enabled ? 1 : 0
  name  = "${local.cluster_name}-nodegroup-role-${random_integer.random_suffix.result}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "eks-AmazonWorkerNodePolicy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEKS_CNI_Policy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}
resource "aws_iam_role_policy_attachment" "eks-AmazonEC2ContainerRegistryReadOnly" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}

resource "aws_iam_role_policy_attachment" "eks-AmazonEBSCSIDriverPolicy" {
  count      = var.is_eks_nodegroup_role_enabled ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.eks-nodegroup-role[count.index].name
}



# ALB Controller Attach Policy
resource "aws_iam_role_policy_attachment" "alb-controller-policy-attach" {
  count      = var.is_alb_controller_enabled ? 1 : 0
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_role[count.index].name
}


# OIDC Provider
# Data source for TLS certificate needs to be correct.
# Usually we get the OIDC issuer URL from the cluster and then get the thumbprint.
# ServiceAccount → OIDC token → STS Security Token Service verifies identity → STS Security Token Service issues temp creds → IAM role allows alb ingress controller to create ALB
# 
data "tls_certificate" "eks_certificate" {
  url = aws_eks_cluster.eks[0].identity[0].oidc[0].issuer #fetching the OIDC issuer URL from the EKS cluster
}

resource "aws_iam_openid_connect_provider" "eks-oidc" { #Creating Identity Provider for OIDC
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks_certificate.certificates[0].sha1_fingerprint]
  url             = data.tls_certificate.eks_certificate.url
}

# to create service account for alb controller we need kubernetes provider
# resource "kubernetes_service_account" "alb_controller_sa" {
#   metadata {
#     name      = "aws-load-balancer-controller"
#     namespace = "kube-system"
#     annotations = {
#       "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
#     }
#   }
#   depends_on = [aws_eks_cluster.my_cluster, aws_eks_node_group.ondemand_nodes]
# }

# OIDC
# data "aws_iam_policy_document" "eks_oidc_assume_role_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(var.oidc_provider_url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"] # This is the service account that the ALB Ingress Controller will use. It needs to match the service account in your Kubernetes cluster.
#     }

#     principals {
#       identifiers = [var.oidc_provider_arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "eks_oidc" {
#   assume_role_policy = data.aws_iam_policy_document.eks_oidc_assume_role_policy.json
#   name               = "eks-oidc"
# }

# resource "aws_iam_policy" "eks-oidc-policy" {
#   name = "test-policy"

#   policy = jsonencode({
#     Statement = [{
#       Action = [
#         "s3:ListAllMyBuckets",
#         "s3:GetBucketLocation",
#         "*"
#       ]
#       Effect   = "Allow"
#       Resource = "*"
#     }]
#     Version = "2012-10-17"
#   })
# }




# Bastion IAM Role

# resource "aws_iam_role" "bastion_role" {
#   name = "${local.cluster_name}-bastion-role-${random_integer.random_suffix.result}"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = "sts:AssumeRole"
#         Effect = "Allow"
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         }
#       }
#     ]
#   })
# }



# resource "aws_iam_role_policy_attachment" "bastion_admin_policy" {
#   policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
#   role       = aws_iam_role.bastion_role.name
# }

# resource "aws_iam_instance_profile" "bastion_profile" {
#   name = "${local.cluster_name}-bastion-profile-${random_integer.random_suffix.result}"
#   role = aws_iam_role.bastion_role.name
# }
