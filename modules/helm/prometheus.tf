resource "helm_release" "prometheus-helm" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  version          = var.prometheus_stack_version #"81.0.0"
  namespace        = "prometheus"
  create_namespace = true
  cleanup_on_fail  = true
  recreate_pods    = true
  replace          = true
  
  wait = false
  #timeout = 2000

# This will also work, but it is not recommended to use "values" with "yamlencode" for complex Helm charts, as it can make the configuration less readable and harder to maintain. Instead, using "set" blocks for individual values is often more manageable and clearer.
#   values = [
#     yamlencode({
#       podSecurityPolicy = {
#         enabled = true
#       }
#       server = {
#         persistentVolume = {
#           enabled = true
#         }
#       }
#       grafana = {
#         service = {
#           type        = "LoadBalancer"
#           annotations = {
#             "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
#           }
#         }
#       }
#       prometheus = {
#         service = {
#           type        = "LoadBalancer"
#           annotations = {
#             "service.beta.kubernetes.io/aws-load-balancer-scheme" = "internet-facing"
#           }
#         }
#       }
#     })
#   ]
# }

 set {
    name  = "podSecurityPolicy.enabled"
    value = true
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = true
  }

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }

  set {
    name  = "prometheus.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "prometheus.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-scheme"
    value = "internet-facing"
  }
}

data "kubernetes_service_v1" "prometheus_server" {
  metadata {
    name      = "prometheus-kube-prometheus-prometheus"
    namespace = "prometheus"
  }
}

data "kubernetes_service_v1" "grafana_server" {
  metadata {
    name      = "prometheus-grafana"
    namespace = "prometheus"
  }
}



##### "dig" function error resolution, while calling this prometheus module from the root module.
# "dig" function error.

# The issue was resolved by:

# Installing Helm 3.20.0 (which includes the "dig" function).
# Updating the Terraform Helm provider to version 2.17.0.
# Ensuring the correct Helm binary is in the PATH during the apply.