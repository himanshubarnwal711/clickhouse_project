output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnets
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnets
}

output "public_route_table_ids" {
  description = "Public route table IDs"
  value       = module.vpc.public_route_table_ids
}

output "private_route_table_ids" {
  description = "Private route table IDs"
  value       = module.vpc.private_route_table_ids
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "ecs_task_sg_id" {
  description = "ECS task security group ID"
  value       = aws_security_group.ecs_task.id
}

output "efs_sg_id" {
  description = "EFS security group ID"
  value       = aws_security_group.efs.id
}

output "vpce_sg_id" {
  description = "VPC endpoint security group ID"
  value       = aws_security_group.vpce.id
}

output "vpc_endpoint_ids" {
  description = "Map of VPC endpoint IDs"
  value       = { for k, v in module.vpc_endpoints.endpoints : k => v.id }
}
