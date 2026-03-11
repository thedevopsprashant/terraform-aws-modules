variable "env" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "public_subnet" {
  type    = list(string)
  default = []
}

variable "private_subnet" {
  type    = list(string)
  default = []
}

variable "cluster_name" {
  type        = string
  description = "Cluster name to tag subnets for Karpenter/ALB discovery"
}

variable "vpc_tags" {
  type    = map(string)
  default = {}
}

variable "public_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "private_subnet_tags" {
  type    = map(string)
  default = {}
}

variable "igw_tags" {
  type    = map(string)
  default = {}
}

