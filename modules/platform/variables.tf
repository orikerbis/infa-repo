variable "vpc_cidr" {
  type = string
}

variable "cluster_name" {
  type = string
}
variable "domain_name" {
  type = string
  
}

variable "argocd_domain" {
  type = string
  
}
variable "hosted_zone_id" {
  type = string
  
}

variable "aws_region" {
  type = string
}

variable "backend_bucket_region" {
  type = string
}
variable "secret_name" {
  type = string
}