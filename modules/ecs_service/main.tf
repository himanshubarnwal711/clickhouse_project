# Application Load Balancer (public subnets)
resource "aws_lb" "ecs_alb" {
  name               = "${var.service_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.alb_sg]
  subnets            = var.public_subnet_ids

  enable_deletion_protection = false
}

# Target Group (we use target_type = "ip" because tasks use awsvpc network mode)
resource "aws_lb_target_group" "ecs_tg" {
  name        = "${var.service_name}-tg"
  port        = var.container_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "instance"

  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  #   matcher {
  #     http_code = "200-399"
  #   }
}

# Listener on port 80
resource "aws_lb_listener" "ecs_listener" {
  load_balancer_arn = aws_lb.ecs_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ecs_tg.arn
  }
}

# ECS Task Definition (EC2 launch type with awsvpc network mode)
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
          containerPort = var.container_port
          protocol      = "tcp"
        }
      ]
      # Optional: add logConfiguration here if you want logs to CloudWatch
    }
  ])
}

# ECS Service
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = var.cluster_name
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = var.desired_count
  #   launch_type     = "EC2"

  # Use capacity provider (if you have one)
  capacity_provider_strategy {
    capacity_provider = var.capacity_provider
    weight            = 1
  }

  deployment_controller {
    type = "ECS"
  }

  # manage deployment behavior
  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  enable_ecs_managed_tags           = true
  propagate_tags                    = "SERVICE"
  health_check_grace_period_seconds = 60
  scheduling_strategy               = "REPLICA"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_task_sg]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ecs_tg.arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  # Placement strategies to rebalance across AZs and then instances
  #   placement_strategy {
  #     type  = "spread"
  #     field = "attribute:ecs.availability-zone"
  #   }

  #   placement_strategy {
  #     type  = "spread"
  #     field = "instanceId"
  #   }

  # ensure ALB exists first
  depends_on = [aws_lb_listener.ecs_listener]
}
