provider "aws" {
  region = "us-east-2" 
  assume_role {
    role_arn = "arn:aws:iam::825765414083:role/eks-admin-role"
  }
}
 terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
 }

 data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
  depends_on = [module.eks]
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", "my-eks", "--role-arn", "arn:aws:iam::825765414083:role/eks-admin-role"]
    command     = "aws"
  }
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    args        = ["eks", "get-token", "--cluster-name", "my-eks", "--role-arn", "arn:aws:iam::825765414083:role/eks-admin-role"]
    command     = "aws"
  }
}
