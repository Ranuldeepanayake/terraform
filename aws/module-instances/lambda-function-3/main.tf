# Locals for common variables.
locals {
  project_name  = "student-application"
  function_name = "user-info"

  tags = {
    Environment      = "dev"
    ProjectName      = local.project_name
    ResourceCategory = "lambda"
    ManagedBy        = "terraform"
  }
}

# Create a secret.
module "secret" {
  source = "../../modules/secrets-manager"

  name          = "${local.project_name}/database-credentials"
  description   = "Database credentials for ${local.project_name}"
  secret_string = jsonencode(var.secret_values)
  kms_key_id    = null
  tags          = local.tags
}

module "lambda" {
  source = "../../modules/lambda"

  vpc_subnet_ids = [] # ["subnet-089b9610c4dee02f4", "subnet-0776c6b9deb42264e"]

  function_name          = "${local.project_name}_${local.function_name}"
  description            = "Lambda function which returns information after being authenticated."
  runtime                = "nodejs24.x"
  handler                = "index.handler"
  memory_size            = 128
  timeout                = 30
  ephemeral_storage_size = 512

  # Asynchronous settings.
  create_function_event_invoke_config = false
  maximum_event_age_in_seconds        = 3600
  maximum_retry_attempts              = 1

  # IAM role settings.
  lambda_role_arn  = null
  create_role      = true
  lambda_role_name = "${local.project_name}_${local.function_name}"

  environment_variables = {
    SECRET_ID = module.secret.arn
  }

  # Endpoint access settings.
  create_function_url = true
  cors = {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "PUT", "PATCH", "DELETE"]
    allow_headers = ["*"]
  }
  # Authorization type NONE means the URL can be invoked without AWS authentication.
  authorization_type = "NONE"

  # Cloudwatch logging.
  log_retention_days = 7

  # Security group settings.
  create_security_group      = false # true
  vpc_security_group_ids     = []
  security_group_name        = null # "${local.project_name}_${local.function_name}"
  security_group_description = null #"Security group for the test lambda function"

  # Security group ingress for the Lambda function. Lambda normally does not need inbound rules, 
  # but this demonstrates that the module supports them.

  security_group_ingress_rules = {
    example_internal_https = {
      description = "Example HTTPS ingress from internal network"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_ipv4   = "10.0.0.0/8"
    }
  }

  # Security group egress rule for both normal CIDR-based and a security-group referenced.
  #security_group_egress_rules = {
  #  https = {
  #    description = "Allow HTTPS outbound"
  #    from_port = 443
  #    to_port   = 443
  #    protocol  = "tcp"
  #    cidr_ipv4 = "0.0.0.0/0"
  #  }

  #  postgres = {
  #    description = "Allow PostgreSQL to RDS"
  #    from_port = 5432
  #    to_port   = 5432
  #    protocol  = "tcp"
  #    referenced_security_group_id = "sg-0123456789abcdef0"
  #  }
  #}

  # Inline custom policy. Grants the lambda function access to the created secret.
  custom_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "secretsmanager:GetSecretValue"
        ]

        Resource = [
          module.secret.arn
        ]
      }
    ]
  })

  # List of existing IAM policies to be attached if the module creates a new role. Can be left null if not required.
  custom_policy_arns = []

  # Inline code settings.
  use_inline_code = true
  # If using an existing zip.
  source_path = null

  inline_code = <<-EOF
    const os = require("os");

    exports.handler = async (event) => {
      const response = {
        hostname: os.hostname(),
        timestamp: new Date().toISOString(),
        runtime: process.version
      };

      console.log(JSON.stringify(response));

      return {
        statusCode: 200,
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify(response)
      };
    };
  EOF

  tags = local.tags
}
