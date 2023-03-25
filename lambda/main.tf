terraform {
  required_providers {
    aws = {
      soursource = "hashicorp/aws"
      version    = "4.20.1"
    }

    archive = {
      version = "2.2.0"
    }
  }

  backend "s3" {
    bucket  = "tankhuu-terraform"
    key     = "lambda/terraform.tfstate"
    region  = "ap-southeast-2"
    encrypt = true
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

provider "archive" {}

data "archive_file" "lambda_file" {
  type        = "zip"
  source_dir  = "lambda"
  output_path = "lambda.zip"
}

data "aws_caller_identity" "current" {}

locals {
  name = "lambda-function-name"
}

resource "aws_iam_role" "lambda_exec" {
  name = "lambda-exec-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_lambda_function" "sample-function" {
  filename         = data.archive_file.lambda_file.output_path
  source_code_hash = data.archive_file.lambda_file.output_base64sha256
  function_name    = local.name
  handler          = "index.handler"
  runtime          = "python3.8"
  role             = aws_iam_role.lambda_exec.arn
  publish          = true
  timeout          = 30
}

resource "aws_cloudwatch_log_group" "sample_function_log_group" {
  name = "/aws/lambda/${aws_lambda_function.sample-function.function_name}"
}
