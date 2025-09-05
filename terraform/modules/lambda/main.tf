# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "resume-auto-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy attachment for basic Lambda execution
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Additional IAM policy for Lambda (customize based on your needs)
resource "aws_iam_role_policy" "lambda_policy" {
  name = "resume-auto-lambda-policy-${var.environment}"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = "*"
      }
    ]
  })
}

# Lambda function
resource "aws_lambda_function" "backend" {
  function_name = var.function_name
  role         = aws_iam_role.lambda_role.arn
  handler      = "lambda_function.lambda_handler"
  runtime      = "python3.9"
  timeout      = 30
  memory_size  = 128

  # Placeholder code - will be updated by CI/CD
  filename         = "lambda_placeholder.zip"
  source_code_hash = data.archive_file.lambda_placeholder.output_base64sha256

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }

  depends_on = [aws_iam_role_policy_attachment.lambda_basic_execution]
}

# Create a placeholder zip file
data "archive_file" "lambda_placeholder" {
  type        = "zip"
  output_path = "lambda_placeholder.zip"
  
  source {
    content  = <<EOF
def lambda_handler(event, context):
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        },
        'body': '{"message": "Hello from Lambda placeholder!"}'
    }
EOF
    filename = "lambda_function.py"
  }
}

# Lambda function URL
resource "aws_lambda_function_url" "backend_url" {
  function_name      = aws_lambda_function.backend.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers     = ["date", "keep-alive", "content-type", "authorization"]
    expose_headers    = ["date", "keep-alive"]
    max_age          = 86400
  }
}