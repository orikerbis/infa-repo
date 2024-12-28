resource "helm_release" "argocd" {
  name       = "argocd"
  chart      = "argo-cd"
  namespace  = "argocd"
  create_namespace = true


  repository = "https://argoproj.github.io/argo-helm"
  version    = "7.7.7" 
}