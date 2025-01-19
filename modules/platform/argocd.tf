module "argocd" {
  source  = "aigisuk/argocd/kubernetes"
  version = "0.2.7"
  insecure = true
  depends_on = [ helm_release.karpenter, kubectl_manifest.karpenter_node_class, kubectl_manifest.karpenter_node_pool ] 
}