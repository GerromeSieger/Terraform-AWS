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

resource "aws_elastic_beanstalk_application" "gerrome-app" {
  name        = "gerrome-app"
  description = "Example Elastic Beanstalk application"
}

resource "aws_elastic_beanstalk_environment" "gerromeapp-dev" {
  name                = "gerromeapp-dev"
  application         = aws_elastic_beanstalk_application.gerrome-app.name
  solution_stack_name = "64bit Amazon Linux 2 v3.5.0 running Python 3.8"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }
}