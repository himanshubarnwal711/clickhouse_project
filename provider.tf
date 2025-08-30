terraform {
  backend "s3" {
    bucket         = "a552762-service-layer-dev-poc-clickhouse-terraform-state"
    key            = "clickhouse/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "a552762-service-layer-poc-clickhouse-terraform-state"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.3"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      Environment = var.env
      Project     = var.app_code
      data        = "restricted"
    }
  }
}
