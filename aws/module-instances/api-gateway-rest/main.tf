locals {
  aws_region       = "ap-southeast-1"
  project_name     = "student-application"
  api_gateway_name = "api"
  custom_domain    = "api.ranul.click"

  tags = {
    Environement     = "dev"
    ProjectName      = local.project_name
    ResourceCategory = "api-gateway"
    ManagedBy        = "terraform"
  }
}

module "api_gateway" {
  source = "../../modules/api-gateway-rest"

  api_gateway_name   = "${local.project_name}_${local.api_gateway_name}"
  deployment_trigger = "v1"

  cors_configuration = {
    allow_headers = [
      "authorization",
      "content-type",
      "x-api-key"
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

  integration_method               = "POST"
  integration_timeout_milliseconds = 10000

  stages = {
    dev = {
      description               = "Development stage"
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
        burst_limit = 300
      }

      route_settings = {
        "health-check" = {
          throttling_rate_limit  = 50
          throttling_burst_limit = 150
        }
      }
    }
    prod = {
      description               = "Production stage"
      custom_domain_mapping_key = ""
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
        burst_limit = 150
      }
    }
  }

  lambda_functions = {
    student-application_health-check = {
      arn = "arn:aws:lambda:ap-southeast-1:104322896078:function:student-application_health-check"
    }
    student-application_auth-module = {
      arn = "arn:aws:lambda:ap-southeast-1:104322896078:function:student-application_auth-module"
    }
    #student-application_user-info = {
    #  arn = "arn:aws:lambda:ap-southeast-1:104322896078:function:student-application_user-info"
    #}
  }

  routes = {
    health-check = {
      method           = "GET"
      path             = "/health-check"
      lambda           = "student-application_health-check"
      authorization    = "NONE"
      api_key_required = false
    }
    auth-module = {
      method           = "POST"
      path             = "/auth-module"
      lambda           = "student-application_auth-module"
      authorization    = "NONE"
      api_key_required = true
    }
    #user-info = {
    #  method           = "POST"
    #  path             = "/user-info"
    #  lambda           = "student-application_user-info"
    #  authorization    = "NONE"
    #  api_key_required = false
    #}
  }

  usage_plans = {
    standard = {
      description = "Standard usage plan"
      stages      = ["dev", "prod"]
      throttle = {
        rate_limit  = 25
        burst_limit = 100
      }
      quota = {
        limit  = 1000
        period = "MONTH"
      }
    },
    pro = {
      description = "Enhanced usage plan"
      stages      = ["dev", "prod"]
      throttle = {
        rate_limit  = 75
        burst_limit = 200
      }
      quota = {
        limit  = 5000
        period = "MONTH"
      }
    }
  }

  custom_domain               = local.custom_domain
  endpoint_type_custom_domain = "REGIONAL"
  security_policy             = "TLS_1_2"

  certificate_validation_method = "DNS"
  certificate_subject_alternative_names = [
    "www.${local.custom_domain}"
  ]

  route53_hosted_zone_name = "ranul.click"
  route53_private_zone     = false

  tags = local.tags
}
