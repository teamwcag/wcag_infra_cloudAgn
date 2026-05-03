module "aws" {
  source = "../_impl/aws"
  count  = var.cloud == "aws" ? 1 : 0

  name_prefix                   = var.name_prefix
  vpc_id                        = var.vpc_id
  private_subnet_ids            = var.private_subnet_ids
  subnet_id                     = var.subnet_id
  instance_type                 = var.instance_type
  docs_bucket_arn               = var.docs_bucket_arn
  secrets_arns                  = var.secrets_arns
  additional_security_group_ids = var.additional_security_group_ids
  user_data                     = var.user_data
}
