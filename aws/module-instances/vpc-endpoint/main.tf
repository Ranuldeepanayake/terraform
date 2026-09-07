module "secrets_manager_endpoint" {
  source = "./modules/vpc-endpoint"

  name = "secrets-manager"

  vpc_id       = module.vpc.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.secretsmanager"

  subnet_ids = module.vpc.private_subnet_ids

  create_security_group = true

  security_group_ingress_rules = [
    {
      description                  = "HTTPS from Lambda"
      from_port                    = 443
      to_port                      = 443
      protocol                     = "tcp"
      referenced_security_group_id = aws_security_group.lambda.id
    }
  ]

  security_group_egress_rules = [
    {
      description = "Allow outbound traffic"
      protocol    = "-1"
      cidr_ipv4   = "0.0.0.0/0"
    }
  ]

  tags = {
    Environment = "production"
  }
}