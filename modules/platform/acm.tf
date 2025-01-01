module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name  = var.domain_name
  zone_id      = var.hosted_zone_id

  validation_method = "DNS"

  subject_alternative_names = [
    "*.kerbis.online",
    "app.kerbis.online",
  ]

  wait_for_validation = true

  tags = {
    Name = "kerbis.online"
  }
}