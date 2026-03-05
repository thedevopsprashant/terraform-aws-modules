output "cluster_endpoint" {
  value = var.is_eks_cluster_enabled ? aws_eks_cluster.eks[0].endpoint : null
}

output "cluster_name" {
  value = var.is_eks_cluster_enabled ? aws_eks_cluster.eks[0].name : null
}

output "oidc_provider_url" {
  value = aws_iam_openid_connect_provider.eks-oidc.url
}

output "oidc_provider_arn" {
  value = aws_iam_openid_connect_provider.eks-oidc.arn
}

output "cluster_certificate_authority_data" {
  value = var.is_eks_cluster_enabled ? aws_eks_cluster.eks[0].certificate_authority[0].data : null
}


########### Security Group Outputs ###########
output "eks_cluster_sg_id" {
  value = aws_security_group.eks-cluster-sg.id
}

# output "bastion_sg_id" {
#   value = aws_security_group.bastion-sg.id
# }



######### IAM Outputs ###########
output "eks_cluster_role_arn" {
  value = var.is_eks_role_enabled ? aws_iam_role.eks-cluster-role[0].arn : null
}

output "eks_nodegroup_role_arn" {
  value = var.is_eks_nodegroup_role_enabled ? aws_iam_role.eks-nodegroup-role[0].arn : null
}

# output "bastion_iam_instance_profile_name" {
#   value = aws_iam_instance_profile.bastion_profile.name
# }

# output "bastion_role_arn" {
#   value = aws_iam_role.bastion_role.arn
# }

output "alb_controller_role_arn" {
  value = var.is_alb_controller_enabled ? aws_iam_role.alb_controller_role[0].arn : null
}