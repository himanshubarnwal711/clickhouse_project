output "clickhouse_ecr_repository_url" {
  description = "ECR repository URL for ClickHouse image"
  value       = module.ecr.repository_url
}

output "docker_image_uri" {
  value       = data.external.image_uri.result["image_uri"]
  description = "The full URI of the pushed Docker image"
}

output "vpc_id" {
  value = module.networking.vpc_id
}

output "public_subnet_ids" {
  value = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  value = module.networking.private_subnet_ids
}

output "security_groups" {
  value = {
    alb_sg      = module.networking.alb_sg_id
    ecs_task_sg = module.networking.ecs_task_sg_id
    efs_sg      = module.networking.efs_sg_id
    vpce_sg     = module.networking.vpce_sg_id
  }
}
output "vpc_endpoint_ids" {
  value = module.networking.vpc_endpoint_ids
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.clickhouse_ecs.name
}

output "ecs_capacity_provider" {
  value = module.ecs_ec2.capacity_provider_name
}

output "efs_id" {
  value = module.efs.efs_id
}

output "efs_access_point_id" {
  value = module.efs.efs_access_point_id
}
