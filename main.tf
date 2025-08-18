module "ecr" {
  source          = "./modules/ecr"
  repository_name = "${local.resource_prefix}-clickhouse"
}

resource "null_resource" "push_docker_image" {
  provisioner "local-exec" {
    command = "./push-image.sh"
  }

  triggers = {
    always_run = timestamp() # forces run every apply
  }
}

data "external" "image_uri" {
  depends_on = [null_resource.push_docker_image]

  program = ["bash", "-c", "echo \"{\\\"image_uri\\\": \\\"$(cat image_uri.txt)\\\"}\""]
}

module "networking" {
  source      = "./modules/networking"
  name_prefix = local.resource_prefix
  region      = var.region

  vpc_cidr        = "10.0.0.0/16"
  public_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnets = ["10.0.11.0/24", "10.0.12.0/24"]

  tags = {
    Environment = var.env
    Project     = var.app_code
    AssetID     = var.asset_id
  }
}

# Create ECS cluster (EC2-backed)
resource "aws_ecs_cluster" "clickhouse_ecs" {
  name = "${local.resource_prefix}-ecs-cluster"
}

# EFS module usage (if you want EFS created now)
module "efs" {
  source                = "./modules/efs"
  name_prefix           = local.resource_prefix
  vpc_id                = module.networking.vpc_id
  private_subnet_ids    = module.networking.private_subnet_ids
  efs_security_group_id = module.networking.efs_sg_id
  tags = {
    Environment = var.env
    Project     = var.app_code
    AssetID     = var.asset_id
  }
}

# ECS EC2 module usage
module "ecs_ec2" {
  source = "./modules/ecs_ec2"

  name_prefix        = local.resource_prefix
  cluster_name       = aws_ecs_cluster.clickhouse_ecs.name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  ecs_instance_sg_id = module.networking.ecs_task_sg_id
  instance_type      = "t2.medium"
  min_size           = 2
  max_size           = 4
  desired_capacity   = 2
  key_name           = "" # set if you want to attach an EC2 keypair
  tags = {
    Environment = var.env
    Project     = var.app_code
    AssetID     = var.asset_id
  }
}

module "ecs_task" {
  source         = "./modules/ecs_task"
  family         = "clickhouse-task"
  cpu            = 1024
  memory         = 3072
  container_name = "clickhouse"
  image          = "460264892221.dkr.ecr.ap-south-1.amazonaws.com/clickhouse-arm64:latest"
  region         = "ap-south-1"
  project_name   = "clickhouse-project"

  clickhouse_user                      = "test"
  clickhouse_password                  = "12345678"
  clickhouse_default_access_management = "1"
  log_group                            = "/ecs/clickhouse"
}

module "ecs_service" {
  source = "./modules/ecs_service"

  service_name       = "a552762-clickhouse"
  cluster_name       = "a552762-dev-service-layer-poc-clickhouse-ecs-cluster" # or module.ecs_ec2.ecs_cluster_name
  capacity_provider  = "a552762-dev-service-layer-poc-clickhouse-cp"          # or module.ecs_ec2.ecs_capacity_provider
  desired_count      = 2
  private_subnet_ids = ["subnet-0703bab646f373360", "subnet-04c427be942503ae0"] # from your outputs
  public_subnet_ids  = ["subnet-00c1ca1790f9ec877", "subnet-0042c54ada28e337d"] # from your outputs
  vpc_id             = "vpc-08e145f79b0abbb5b"
  alb_sg             = "sg-00ffe18a5977346e0"
  ecs_task_sg        = "sg-0a0a2a71119abd42e"
  docker_image_uri   = "460264892221.dkr.ecr.ap-south-1.amazonaws.com/a552762-dev-service-layer-poc-clickhouse-clickhouse:latest"
  container_name     = "clickhouse"
  container_port     = 8123
  task_cpu           = 512
  task_memory        = 1024
}
