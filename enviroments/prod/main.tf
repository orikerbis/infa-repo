module "platform" {
  source = "../../modules/platform"
  domain_name = "kerbis.online" 
  hosted_zone_id = "Z08019033CJXYX9250VV4"
  argocd_domain = "argocd.kerbis.online"
  cluster_name = "my-eks"
  vpc_cidr = "10.0.0.0/16"
  aws_region = "us-east-2"
  backend_bucket_region = "us-east-2"
}