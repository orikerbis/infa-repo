terraform {
  backend "s3" {
    bucket         = "terraform-backend-kerbis-system"
    key            = "terraform/state/project.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}