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

resource "aws_s3_bucket" "bucket-gerrome-web" {
  bucket_prefix = "gerrome-web-data"
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "bucket-versioning" {
  bucket = aws_s3_bucket.bucket-gerrome-web.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bucket-crypto-conf" {
  bucket = aws_s3_bucket.bucket-gerrome-web.bucket
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}