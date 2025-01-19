module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name                   = var.cluster_name
  cluster_version                = "1.30"
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  enable_irsa                    = true
  control_plane_subnet_ids = module.vpc.intra_subnets
  cluster_addons = {
    coredns                = {}
    eks-pod-identity-agent = {}
    kube-proxy             = {}
    vpc-cni                = {}

  }
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
 

  enable_cluster_creator_admin_permissions = true
  eks_managed_node_groups = {
    karpenter = {
      ami_type       = "AL2023_x86_64_STANDARD"
      instance_types = ["t3.medium"]
      min_size     = 2
      max_size     = 4
      desired_size = 2
      taints = {
        addons = {
          key    = "CriticalAddonsOnly"
          value  = "true"
          effect = "NO_SCHEDULE"
        },
      }
    }
  }
    
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.cluster_name
  }
}

module "eks_blueprints_addons" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "1.19.0" 

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  enable_aws_load_balancer_controller = true
  enable_external_secrets             = true
  depends_on = [ helm_release.karpenter, kubectl_manifest.karpenter_node_class, kubectl_manifest.karpenter_node_pool ] 
  aws_load_balancer_controller = {
    set = [ 
      {
      name = "vpcId"
      value = module.vpc.vpc_id 
      },
      {
      name = "region"
      value = var.aws_region
      }
    ] 
  }

}

module "karpenter" {
  source = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "20.31.6"
  cluster_name = module.eks.cluster_name

  enable_v1_permissions = true

  enable_pod_identity             = true
  create_pod_identity_association = true

  node_iam_role_additional_policies = {
  AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  
  }
}
resource "aws_iam_service_linked_role" "spot" {
  aws_service_name = "spot.amazonaws.com"
}

data "aws_ecrpublic_authorization_token" "token" {
  provider = aws.virginia
}

resource "helm_release" "karpenter" {
  namespace           = "kube-system"
  name                = "karpenter"
  repository          = "oci://public.ecr.aws/karpenter"
  repository_username = data.aws_ecrpublic_authorization_token.token.user_name
  repository_password = data.aws_ecrpublic_authorization_token.token.password
  chart               = "karpenter"
  version             = "1.0.0"
  wait                = false


  set {
    name  = "serviceAccount.name"
    value = module.karpenter.service_account
  }
  
  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }

  set {
    name  = "settings.interruptionQueue"
    value = module.karpenter.queue_name
  }
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          requirements:
            - key: kubernetes.io/arch
              operator: In
              values: ["amd64", "arm64"]
            - key: kubernetes.io/os
              operator: In
              values: ["linux"]
            - key: karpenter.sh/capacity-type
              operator: In
              values: ["spot", "on-demand"]
            - key: karpenter.k8s.aws/instance-family
              operator: In
              values: ["t3a", "m5a", "m6a", "m5", "m6i"]
            - key: karpenter.k8s.aws/instance-size
              operator: In
              values: ["medium", "large"]
          nodeClassRef:
            name: default
            kind: EC2NodeClass
            group: karpenter.k8s.aws
          expireAfter: 168h
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 30s
      YAML

  depends_on = [
    kubectl_manifest.karpenter_node_class
  ]
}

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: ${module.karpenter.node_iam_role_name}
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: ${var.cluster_name}
      amiSelectorTerms:
        - alias: al2@latest
  YAML

  depends_on = [
    helm_release.karpenter
  ]
}

resource "helm_release" "prometheus" {
  namespace = "monitoring"
  name      = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart     = "kube-prometheus-stack"
  create_namespace = true
  version   = "67.9.0"
  depends_on = [ helm_release.karpenter, kubectl_manifest.karpenter_node_class, kubectl_manifest.karpenter_node_pool, aws_iam_service_linked_role.spot ] 
}

module "loki_stack" {
  source = "terraform-iaac/loki-stack/kubernetes"

  namespace        = "monitoring"
  create_namespace = false

  provider_type          = "local"
  pvc_storage_class_name = "gp2"
  pvc_access_modes       = ["ReadWriteOnce"]
  persistent_volume_size = "10Gi"

  loki_resources = {
    request_cpu    = "100m"
    request_memory = "256Mi"
  }

  promtail_resources = {
    request_cpu    = "50m"
    request_memory = "128Mi"
  }
  depends_on = [ helm_release.karpenter, kubectl_manifest.karpenter_node_class, kubectl_manifest.karpenter_node_pool ]
}





  
