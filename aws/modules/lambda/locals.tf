# Derived variables to reduce statement duplication.
locals {
  using_inline = var.use_inline_code && var.inline_code != null
  create_lambda_security_group = (length(var.vpc_subnet_ids) > 0 && var.create_security_group)
  lambda_security_group_ids = concat(var.vpc_security_group_ids, local.create_lambda_security_group ? [aws_security_group.lambda[0].id] : [])
}