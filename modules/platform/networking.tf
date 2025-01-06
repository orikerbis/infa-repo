data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = "main"
  az_count = length(data.aws_availability_zones.available.names)
  public_subnets = [
    for i in range(local.az_count) :
    cidrsubnet(var.vpc_cidr, 8, i)
  ]
  private_subnets = [
    for i in range(local.az_count) :
    cidrsubnet(var.vpc_cidr, 8, i + local.az_count)
  ]
  azs = data.aws_availability_zones.available.names
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.17.0"

  name = local.name
  cidr = var.vpc_cidr

  azs             = local.azs
  private_subnets = local.private_subnets
  public_subnets  = local.public_subnets
  enable_nat_gateway = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "karpenter.sh/discovery" = var.cluster_name
    "kubernetes.io/role/internal-elb" = 1
  }
}