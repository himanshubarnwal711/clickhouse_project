output "cluster_name" {
  value = var.cluster_name
}

output "launch_template_id" {
  value = aws_launch_template.ecs_lt.id
}

output "asg_arn" {
  value = aws_autoscaling_group.ecs_asg.arn
}

output "capacity_provider_name" {
  value = aws_ecs_capacity_provider.cp.name
}
