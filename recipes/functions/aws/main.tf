variable "context" {
  description = "Radius-provided object containing information about the resource calling the Recipe."
  type        = any
}

variable "region" {
  description = "AWS region to deploy into."
  type        = string
  default     = "us-west-2"
}

variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
  default     = "rad-lambda-container-example"
}

variable "architectures" {
  description = "CPU architecture for the Lambda function (x86_64 or arm64)."
  type        = list(string)
  default     = ["x86_64"]

  validation {
    condition     = alltrue([for arch in var.architectures : arch == "x86_64" || arch == "arm64"])
    error_message = "architectures must be x86_64 or arm64."
  }
}

variable "memory_size" {
  description = "Memory size for the Lambda function in MB."
  type        = number
  default     = 256
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 15
}

variable "environment" {
  description = "Environment variables for the Lambda function."
  type        = map(string)
  default     = {}
}

variable "image_command" {
  description = "Override the container CMD to point to the Lambda handler (e.g., [\"app.handler\"])."
  type        = list(string)
  default     = []
}

variable "image_entry_point" {
  description = "Override the container ENTRYPOINT if needed."
  type        = list(string)
  default     = []
}

variable "image_working_directory" {
  description = "Working directory inside the container when invoking the handler."
  type        = string
  default     = null
}

variable "enable_function_url" {
  description = "Whether to create a public Function URL for quick testing."
  type        = bool
  default     = true
}

variable "function_url_authorization_type" {
  description = "Authorization type for the Function URL (NONE or AWS_IAM)."
  type        = string
  default     = "NONE"

  validation {
    condition     = var.function_url_authorization_type == "NONE" || var.function_url_authorization_type == "AWS_IAM"
    error_message = "function_url_authorization_type must be NONE or AWS_IAM."
  }
}

variable "log_retention_in_days" {
  description = "CloudWatch log retention for the function."
  type        = number
  default     = 14
}

variable "tags" {
  description = "Tags to apply to created resources."
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  access_key = var.context.resource.properties.access_key
  secret_key = var.context.resource.properties.secret_key
}

# IAM role for the Lambda function with basic execution permissions.
resource "aws_iam_role" "lambda_exec" {
  name = "${var.function_name}-exec"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_in_days
  tags              = var.tags
}

locals {
  use_image_config = length(var.image_command) > 0 || length(var.image_entry_point) > 0 || var.image_working_directory != null
}

resource "aws_lambda_function" "container" {
  function_name = var.function_name
  role          = aws_iam_role.lambda_exec.arn
  package_type  = "Image"
  image_uri     = var.context.resource.properties.image

  architectures = var.architectures
  timeout       = var.timeout
  memory_size   = var.memory_size

  dynamic "environment" {
    for_each = length(var.environment) > 0 ? [1] : []
    content {
      variables = var.environment
    }
  }

  dynamic "image_config" {
    for_each = local.use_image_config ? [1] : []
    content {
      command           = var.image_command
      entry_point       = var.image_entry_point
      working_directory = var.image_working_directory
    }
  }

  # Ensure logging policy is attached before create/update for cleaner deploys.
  depends_on = [
    aws_iam_role_policy_attachment.lambda_basic_execution,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = var.tags
}

resource "aws_lambda_function_url" "default" {
  count = var.enable_function_url ? 1 : 0

  function_name      = aws_lambda_function.container.function_name
  authorization_type = var.function_url_authorization_type

  cors {
    allow_credentials = false
    allow_origins     = ["*"]
    allow_methods     = ["*"]
    allow_headers     = ["*"]
  }

  depends_on = [aws_lambda_function.container]
}

output "result" {
  value = {
    values = {
      function_name = aws_lambda_function.container.function_name
      function_url  = length(aws_lambda_function_url.default) > 0 ? aws_lambda_function_url.default[0].function_url : null
    }
  }
}
