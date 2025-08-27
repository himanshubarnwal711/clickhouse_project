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
  source             = "./modules/ecs_ec2"
  name_prefix        = local.resource_prefix
  cluster_name       = aws_ecs_cluster.clickhouse_ecs.name
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  ecs_instance_sg_id = module.networking.ecs_task_sg_id
  instance_type      = "t2.medium"
  ami_id             = var.ami_id
  min_size           = 2
  max_size           = 4
  desired_capacity   = 2
  key_name           = "" # set if you want to attach an EC2 keypair
  tags = {
    Environment = var.env
    Project     = var.app_code
    AssetID     = var.asset_id
  }
  depends_on = [aws_ecs_cluster.clickhouse_ecs]
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

  service_name      = "a552762-clickhouse"
  cluster_name      = aws_ecs_cluster.clickhouse_ecs.name
  capacity_provider = module.ecs_ec2.capacity_provider_name
  desired_count     = 2

  private_subnet_ids = module.networking.private_subnet_ids
  public_subnet_ids  = module.networking.public_subnet_ids
  vpc_id             = module.networking.vpc_id

  alb_sg      = module.networking.alb_sg_id
  ecs_task_sg = module.networking.ecs_task_sg_id

  docker_image_uri = data.external.image_uri.result.image_uri
  container_name   = "clickhouse"
  container_port   = 8123
  task_cpu         = 512
  task_memory      = 1024

  depends_on = [
    module.networking,
    module.ecs_ec2
  ]

}
