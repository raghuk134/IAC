terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "resume-auto-terraform-state"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "resume-auto"
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# S3 bucket for frontend
module "s3_frontend" {
  source = "./modules/s3"
  
  bucket_name = "resume-auto-frontend-${var.environment}"
  environment = var.environment
}

# CloudFront distribution
module "cloudfront" {
  source = "./modules/cloudfront"
  
  s3_bucket_id = module.s3_frontend.bucket_id
  s3_bucket_domain_name = module.s3_frontend.bucket_domain_name
  environment = var.environment
}

# Lambda function for backend
module "lambda" {
  source = "./modules/lambda"
  
  function_name = "resume-auto-backend-${var.environment}"
  environment = var.environment
}

# API Gateway (if needed for more complex routing)
module "api_gateway" {
  source = "./modules/api-gateway"
  
  lambda_function_arn = module.lambda.lambda_function_arn
  lambda_function_name = module.lambda.lambda_function_name
  environment = var.environment
}