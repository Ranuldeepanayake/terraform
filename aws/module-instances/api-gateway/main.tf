# Locals for common variables.
locals {
  aws_region       = "ap-southeast-1"
  project_name     = "student-application"
  api_gateway_name = "gateway-1"
  custom_domain    = "api.ranul.click"

  tags = {
    ProjectName      = local.project_name
    ResourceCategory = "lambda"
    ManagedBy        = "terraform"
  }
}

module "api_gateway" {
  source = "../../modules/api-gateway"

  api_gateway_name = "${local.project_name}_${local.api_gateway_name}"
  protocol_type    = "HTTP"
  ip_address_type  = "dualstack"

  cors_configuration = {
    allow_headers = [
      "authorization",
      "content-type"
    ]
    allow_methods = [
      "GET",
      "POST",
      "PUT",
      "PATCH",
      "DELETE",
      "OPTIONS"
    ]
    allow_origins = ["*"]
  }

  integration_type                 = "AWS_PROXY"
  integration_method               = "POST"
  payload_format_version           = "2.0"
  integration_timeout_milliseconds = 10000

  stages = {
    dev = {
      description               = "Development stage"
      auto_deploy               = true
      custom_domain_mapping_key = "dev"
      detailed_metrics_enabled  = true
      logging_level             = "INFO"
      stage_variables           = { environment = "dev" }
      tags                      = merge(local.tags, { Environment = "dev" })

      logging = {
        enabled           = true
        log_group_name    = "/aws/apigateway/${local.project_name}/${local.api_gateway_name}/dev"
        retention_in_days = 7
      }

      throttling = {
        enabled     = true
        rate_limit  = 100
        burst_limit = 500
      }

      route_settings = {
        "GET /health-check" = {
          throttling_rate_limit  = 100
          throttling_burst_limit = 500
        }
      }
    }
    "$default" = {
      description               = "Production stage"
      auto_deploy               = false
      deployment_trigger        = "prod-v2"

      detailed_metrics_enabled  = false
      logging_level             = "ERROR"
      data_trace_enabled        = false
      stage_variables           = { environment = "prod" }
      tags                      = merge(local.tags, { Environment = "prod" })

      logging = {
        enabled           = true
        log_group_name    = "/aws/apigateway/${local.project_name}/${local.api_gateway_name}/prod"
        retention_in_days = 7
      }

      throttling = {
        enabled     = true
        rate_limit  = 50
        burst_limit = 100
      }
    }
  }

  lambda_functions = {
    student-application_health-check = {
      arn = "arn:aws:lambda:ap-southeast-1:104322896078:function:student-application_health-check"
    },
    student-application_auth-module = {
      arn = "arn:aws:lambda:ap-southeast-1:104322896078:function:student-application_auth-module"
    },
    student-application_user-info = {
      arn = "arn:aws:lambda:ap-southeast-1:104322896078:function:student-application_user-info"
    }
  }

  routes = {
    health-check = {
      method        = "GET"
      path          = "/health-check"
      lambda        = "student-application_health-check"
      authorization = "NONE"
      default       = true
    },
    auth-module = {
      method        = "POST"
      path          = "/auth-module"
      lambda        = "student-application_auth-module"
      authorization = "NONE"
      default       = false
    },
    user-info = {
      method        = "POST"
      path          = "/user-info"
      lambda        = "student-application_user-info"
      authorization = "NONE"
      default       = false
    }
  }

  custom_domain   = local.custom_domain
  endpoint_type   = "REGIONAL"
  security_policy = "TLS_1_2"

  certificate_validation_method = "DNS"
  certificate_subject_alternative_names = [
    "www.${local.custom_domain}"
  ]

  route53_hosted_zone_name = "ranul.click"
  route53_private_zone     = false
}