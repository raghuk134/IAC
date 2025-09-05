# API Gateway REST API
resource "aws_api_gateway_rest_api" "backend_api" {
  name        = "resume-auto-api-${var.environment}"
  description = "API Gateway for resume-auto backend ${var.environment}"

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

# API Gateway Resource (proxy)
resource "aws_api_gateway_resource" "proxy" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  parent_id   = aws_api_gateway_rest_api.backend_api.root_resource_id
  path_part   = "{proxy+}"
}

# API Gateway Method (ANY)
resource "aws_api_gateway_method" "proxy" {
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Method (OPTIONS for CORS)
resource "aws_api_gateway_method" "proxy_options" {
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  resource_id   = aws_api_gateway_resource.proxy.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

# API Gateway Method for root resource
resource "aws_api_gateway_method" "root" {
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  resource_id   = aws_api_gateway_rest_api.backend_api.root_resource_id
  http_method   = "ANY"
  authorization = "NONE"
}

# API Gateway Integration
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_method.proxy.resource_id
  http_method = aws_api_gateway_method.proxy.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

# API Gateway Integration for root
resource "aws_api_gateway_integration" "lambda_integration_root" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_method.root.resource_id
  http_method = aws_api_gateway_method.root.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

# API Gateway Integration for OPTIONS
resource "aws_api_gateway_integration" "lambda_integration_options" {
  rest_api_id = aws_api_gateway_rest_api.backend_api.id
  resource_id = aws_api_gateway_method.proxy_options.resource_id
  http_method = aws_api_gateway_method.proxy_options.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:lambda:path/2015-03-31/functions/${var.lambda_function_arn}/invocations"
}

# Data source for current region
data "aws_region" "current" {}

# Lambda permission for API Gateway
resource "aws_lambda_permission" "api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.lambda_function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.backend_api.execution_arn}/*/*"
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "backend_deployment" {
  depends_on = [
    aws_api_gateway_method.proxy,
    aws_api_gateway_method.root,
    aws_api_gateway_method.proxy_options,
    aws_api_gateway_integration.lambda_integration,
    aws_api_gateway_integration.lambda_integration_root,
    aws_api_gateway_integration.lambda_integration_options,
  ]

  rest_api_id = aws_api_gateway_rest_api.backend_api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.proxy.id,
      aws_api_gateway_method.proxy.id,
      aws_api_gateway_method.root.id,
      aws_api_gateway_method.proxy_options.id,
      aws_api_gateway_integration.lambda_integration.id,
      aws_api_gateway_integration.lambda_integration_root.id,
      aws_api_gateway_integration.lambda_integration_options.id,
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "backend_stage" {
  deployment_id = aws_api_gateway_deployment.backend_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.backend_api.id
  stage_name    = var.environment
}