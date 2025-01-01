module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0" #ensure to update this to the latest/desired version

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  eks_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
  }

  enable_aws_load_balancer_controller = true
  enable_external_secrets             = true

}

resource "helm_release" "external_nginx" {
  name             = "external"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  version          = "4.12.0-beta.0"
  set {
    name  = "controller.service.type"
    value = "NodePort"
  }

  depends_on = [module.eks_blueprints_addons]
}

resource "kubernetes_ingress_v1" "nginx_test_ingress" {
  metadata {
    name      = "nginx-test-ingress"
    namespace = "ingress"
    annotations = {
      "alb.ingress.kubernetes.io/ssl-redirect"    = 443
      "alb.ingress.kubernetes.io/scheme"          = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"     = "ip" 
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\": 80}, {\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn" = module.acm.acm_certificate_arn

    }
  }

  spec {
    ingress_class_name = "alb" 
    rule {
      http {
        path {
          path = "/*"
          backend {
            service {
              name = "external-ingress-nginx-controller" # Replace with your service name
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    module.eks_blueprints_addons,
    helm_release.external_nginx
  ]
}

resource "kubernetes_ingress_v1" "argocd_ingress" {
  metadata {
    name      = "argocd-ingress"
    namespace = "argocd"
  }

  spec {
    ingress_class_name = "nginx"
    rule {
      host = var.argocd_domain
      http {
        path {
          path = "/"
          backend {
            service {
              name = "argocd-server"
              port {
                number = 80
              }
            }
          }
        }
      }
    }
  }

  depends_on = [
    helm_release.external_nginx
  ]
}



