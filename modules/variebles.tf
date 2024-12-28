variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "aws_region" {
  type = string
  default = "us-east-2"
}
variable "cluster_name" {
  type = string
  default = ""
}

variable "desired_size" {
  type = any
  default = {}
}
variable "min_size" {
  type = any
  default = {}
}
variable "max_size" {
  type = any
  default = {}
}
variable "instance_types" {
  type = any
  default = {}
}
variable "capacity_type" {
  type = any
  default = {}
}







