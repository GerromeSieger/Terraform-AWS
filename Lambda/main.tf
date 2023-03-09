terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "lambdabucketvicifah" {
  bucket = "lambdabucketvicifah"
}

resource "aws_lambda_function" "test-function" {
  filename         = "lambda_function_payload.zip"
  function_name    = "test-function"
  role             = aws_iam_role.lambda-role.arn
  handler          = "index.handler"
  #source_code_hash = filebase64sha256("lambda_function_payload.zip")
  runtime          = "nodejs14.x"

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.lambdabucketvicifah.bucket
    }
  }
}

resource "aws_iam_role" "lambda-role" {
  name = "lambda-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = ["lambda.amazonaws.com"]
        }
      }
    ]
  })
}