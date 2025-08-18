output "ecs_service_name" {
  value = aws_ecs_service.service.name
}

output "ecs_service_arn" {
  value = aws_ecs_service.service.arn
}

output "alb_dns_name" {
  value = aws_lb.ecs_alb.dns_name
}

output "target_group_arn" {
  value = aws_lb_target_group.ecs_tg.arn
}
