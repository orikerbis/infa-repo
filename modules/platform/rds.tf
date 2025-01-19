module "rds" {
  source  = "terraform-aws-modules/rds/aws"
  version = "6.10.0"

  identifier = "employee-db"

  engine                              = "mysql"
  engine_version                      = "5.7"
  instance_class                      = "db.t3.small"
  allocated_storage                   = 5
  iam_database_authentication_enabled = true
  username                            = "admin"

  vpc_security_group_ids = [module.vpc.default_security_group_id, aws_security_group.rds_sg.id]

  maintenance_window = "Mon:00:00-Mon:03:00"
  backup_window      = "03:00-06:00"
  family                      = "mysql5.7"
  manage_master_user_password = false
  password                    = random_password.db_password.result

  create_db_subnet_group = true
  subnet_ids             = [aws_subnet.db-1.id, aws_subnet.db-2.id]

  major_engine_version = "5.7"

  deletion_protection = false

}

resource "random_password" "db_password" {
  length  = 16
  special = true
  override_special = "!#$%&*()_-+="
}

resource "aws_secretsmanager_secret" "db_credentials" {
  name        = var.secret_name
  description = "RDS database credentials"
}

resource "aws_secretsmanager_secret_version" "db_credentials_version" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    MYSQL_USER = module.rds.db_instance_username
    MYSQL_PASSWORD = random_password.db_password.result
    MYSQL_HOST      = module.rds.db_instance_endpoint
  })
  depends_on = [ module.rds ]
}

resource "aws_subnet" "db-1" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = "10.0.6.0/24"
  availability_zone = "us-east-2a"
  tags = {
    Name = "db"
  }
}

resource "aws_subnet" "db-2" {
  vpc_id            = module.vpc.vpc_id
  cidr_block        = "10.0.7.0/24"
  availability_zone = "us-east-2b"
  tags = {
    Name = "db"
  }
}



resource "aws_security_group" "rds_sg" {
  name        = "rds-sg"
  description = "Security group for RDS instance"
  vpc_id      = module.vpc.vpc_id
  tags = {
    Name = "rds-sg"
  }
}

resource "aws_security_group_rule" "allow_eks_to_rds_mysql" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = module.eks.node_security_group_id
  description = "Allow EKS nodes to access RDS MySQL"
}

