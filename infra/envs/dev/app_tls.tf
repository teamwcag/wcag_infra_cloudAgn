resource "aws_acm_certificate" "app" {
  count = var.app_https_enabled && var.app_acm_certificate_create && var.app_acm_certificate_arn == "" ? 1 : 0

  domain_name       = var.app_hostname
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

locals {
  app_effective_certificate_arn = var.app_acm_certificate_arn != "" ? var.app_acm_certificate_arn : try(aws_acm_certificate.app[0].arn, "")

  app_ingress_annotations = merge(
    {
      "alb.ingress.kubernetes.io/scheme"      = "internet-facing"
      "alb.ingress.kubernetes.io/target-type" = "ip"
    },
    var.app_https_enabled ? {
      "alb.ingress.kubernetes.io/listen-ports"    = "[{\"HTTP\":80},{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/certificate-arn" = local.app_effective_certificate_arn
      "alb.ingress.kubernetes.io/ssl-redirect"    = "443"
      "alb.ingress.kubernetes.io/ssl-policy"      = var.app_acm_ssl_policy
      } : {
      "alb.ingress.kubernetes.io/listen-ports" = "[{\"HTTP\":80}]"
    }
  )
}

output "app_acm_certificate_arn" {
  value = local.app_effective_certificate_arn != "" ? local.app_effective_certificate_arn : null
}

output "app_acm_certificate_validation_records" {
  value = [
    for dvo in try(aws_acm_certificate.app[0].domain_validation_options, []) : {
      domain_name  = dvo.domain_name
      record_name  = dvo.resource_record_name
      record_type  = dvo.resource_record_type
      record_value = dvo.resource_record_value
    }
  ]
}
