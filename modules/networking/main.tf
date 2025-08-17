terraform {
  required_version = ">= 1.5"
}

data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  name = var.name_prefix
  # Pick two AZs for HA
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

# --- VPC, subnets, routing, IGW, NAT GW (managed by the module) ---
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${local.name}-vpc"
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets

  enable_dns_support   = true
  enable_dns_hostnames = true

  # NAT for private egress (e.g., yum/apt, reaching public services when no endpoint)
  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    Tier = "public"
  }

  private_subnet_tags = {
    Tier = "private"
  }

  tags = merge(var.tags, {
    Module = "networking"
  })
}

# --- Security groups you will reuse later ---

# ALB SG: HTTP from internet; egress all
resource "aws_security_group" "alb" {
  name        = "${local.name}-alb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-alb-sg" })
}

# ECS Task SG: allow ClickHouse ports from ALB; egress all
resource "aws_security_group" "ecs_task" {
  name        = "${local.name}-ecs-task-sg"
  description = "ECS task ingress from ALB; egress all"
  vpc_id      = module.vpc.vpc_id

  # ClickHouse HTTP
  ingress {
    from_port       = 8123
    to_port         = 8123
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "ClickHouse HTTP from ALB"
  }

  # ClickHouse native TCP (optional, from ALB or later from specific peers)
  ingress {
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
    description     = "ClickHouse native from ALB (optional)"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-ecs-task-sg" })
}

# EFS SG: allow NFS from ECS tasks
resource "aws_security_group" "efs" {
  name        = "${local.name}-efs-sg"
  description = "Allow NFS (2049) from ECS tasks"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ecs_task.id]
    description     = "NFS from ECS tasks"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-efs-sg" })
}

# VPC Endpoint SG: allow HTTPS from inside the VPC to interface endpoints
resource "aws_security_group" "vpce" {
  name        = "${local.name}-vpce-sg"
  description = "Allow HTTPS (443) from VPC CIDR to interface endpoints"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "HTTPS from VPC CIDR"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, { Name = "${local.name}-vpce-sg" })
}

# --- VPC Endpoints (use submodule) ---

module "vpc_endpoints" {
  source  = "terraform-aws-modules/vpc/aws//modules/vpc-endpoints"
  version = "~> 5.0"

  vpc_id = module.vpc.vpc_id

  endpoints = {
    # Gateway endpoint for S3 to keep private traffic on AWS backbone
    s3 = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = module.vpc.private_route_table_ids
      tags            = merge(var.tags, { Name = "${local.name}-vpce-s3" })
    }

    # Interface endpoints - placed in private subnets
    ecr_api = {
      service             = "ecr.api"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpce.id]
      tags                = merge(var.tags, { Name = "${local.name}-vpce-ecr-api" })
    }

    ecr_dkr = {
      service             = "ecr.dkr"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpce.id]
      tags                = merge(var.tags, { Name = "${local.name}-vpce-ecr-dkr" })
    }

    logs = {
      service             = "logs"
      private_dns_enabled = true
      subnet_ids          = module.vpc.private_subnets
      security_group_ids  = [aws_security_group.vpce.id]
      tags                = merge(var.tags, { Name = "${local.name}-vpce-logs" })
    }
  }

  tags = var.tags
}
