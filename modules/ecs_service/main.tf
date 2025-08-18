# Application Load Balancer (public subnets)
resource "aws_lb" "ecs_alb" {
  name               = "${var.service_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
}

# Target Group (pointing to EC2 instances on port 8123)
resource "aws_lb_target_group" "ecs_tg" {
  name        = "${var.service_name}-tg"
  port        = 8123 # ✅ Hardcoded to container port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id # ✅ Make sure this is correct
  target_type = "ip"       # ✅ Required for EC2-based ECS tasks

  health_check {
    path                = "/"
    protocol            = "HTTP"
    port                = "8123" # ✅ Health check uses container port
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# Listener on port 80 -> forwards to target group
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# ECS Task Definition
resource "aws_ecs_task_definition" "task" {
  family                   = var.service_name
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = tostring(var.task_cpu)
  memory                   = tostring(var.task_memory)

  container_definitions = jsonencode([
    {
      name      = var.container_name
      image     = var.docker_image_uri
      essential = true
      portMappings = [
        {
          containerPort = 8123 # ✅ Use container port here
          protocol      = "tcp"
        }
      ]
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count

  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  enable_ecs_managed_tags           = true
  propagate_tags                    = "SERVICE"
  health_check_grace_period_seconds = 60
  scheduling_strategy               = "REPLICA"

  network_configuration {
    subnets          = var.private_subnet_ids # ✅ Tasks in private subnets
    security_groups  = [var.ecs_task_sg]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = var.container_name
    container_port   = 8123
  }

  depends_on = [aws_lb_listener.ecs_listener]
}
