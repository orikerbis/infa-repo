module "acm" {
  source  = "terraform-aws-modules/acm/aws"
  version = "5.1.1"

  domain_name  = "kerbis.online"
  zone_id      = "Z08019033CJXYX9250VV4"

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