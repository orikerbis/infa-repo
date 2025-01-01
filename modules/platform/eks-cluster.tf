module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.31.6"

  cluster_name                   = var.cluster_name
  cluster_version                = "1.31"
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  
  
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets
  

  eks_managed_node_group_defaults = {
    create_iam_role = true
    iam_role_attach_cni_policy = true
  }

  enable_cluster_creator_admin_permissions = true
  eks_managed_node_groups = {
    general = {
      desired_size = 1
      min_size     = 1
      max_size     = 10
      instance_types = ["t3.large"]
      capacity_type  = "ON_DEMAND"
    }
  }
  create_node_security_group = false
  cluster_security_group_additional_rules = {
    hybrid-all = {
      cidr_blocks = [var.vpc_cidr]
      description = "Allow all traffic from remote node/pod network"
      from_port   = 3306
      to_port     = 3306
      protocol    = "tcp"
      type        = "ingress"
    }
  }


  
  
}

