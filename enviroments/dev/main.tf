module "vpc" {
  source = "../../modules/vpc"
  vpc_cidr = var.vpc_cidr
  vpc_name = var.vpc_name
  vpc_tags = var.vpc_tags
  
}

module "eks" {
  source = "../../modules/eks"
    cluster_name = var.cluster_name
}

module "acm" {
  source = "../../modules/acm"
  acm_domain_name = var.acm_domain_name
  
}

module "argocd" {
  source = "../../modules/argocd"
  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_version = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  
}

module "nginx-ingress" {
  source = "../../modules/nginx-ingress"
  cluster_name = module.eks.cluster_name
  cluster_endpoint = module.eks.cluster_endpoint
  cluster_version = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn
  acm_certificate_arn = module.acm.acm_certificate_arn
}

module "db" {
    source = "../../modules/db"
    vpc_id = module.vpc.vpc_id
    db_subnet_ids = [module.vpc.vpc_private_subnet_ids[0], module.vpc.vpc_private_subnet_ids[1]]
    db_name = var.db_name
    
}




