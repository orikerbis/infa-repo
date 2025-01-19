resource "helm_release" "external_nginx" {
  name             = "external"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress"
  create_namespace = true
  version          = "4.12.0"
  values = [
    <<-EOF
    controller:
      service:
        type: NodePort
      ingressClassResource:
        name: nginx
        enabled: true
      metrics:
        enabled: true
        serviceMonitor:
          enabled: true
          additionalLabels:
            release: prometheus
      podAnnotations:
        prometheus.io/port: "10254"
        prometheus.io/scrape: "true"
      extraArgs:
        metrics-per-host: "false"
    externalTrafficPolicy: Cluster
    EOF
  ]
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
              name = "external-ingress-nginx-controller" 
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




