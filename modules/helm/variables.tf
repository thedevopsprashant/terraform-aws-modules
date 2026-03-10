variable "region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "alb_controller_role_arn" {
  type = string
}

variable "alb_controller_version" {
  type = string
}

variable "argocd_version" {
  type = string
}

variable "is_prometheus-stack_enabled" {
  type = bool
}

variable "prometheus_stack_version" {
  type = string
}