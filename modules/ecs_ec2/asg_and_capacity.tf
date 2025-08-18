terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

# Auto Scaling Group for ECS
resource "aws_autoscaling_group" "ecs_asg" {
  name     = "${var.name_prefix}-ecs-asg"
  min_size = var.min_size
  max_size = var.max_size

  # vpc_zone_identifier is now correctly set
  vpc_zone_identifier = var.private_subnet_ids

  launch_template {
    id = aws_launch_template.ecs_lt.id
    # Use the 'latest_version' attribute for a more robust reference
    version = aws_launch_template.ecs_lt.latest_version
  }

  health_check_type         = "EC2"
  health_check_grace_period = 300
  wait_for_capacity_timeout = "10m"
  force_delete              = false
  protect_from_scale_in     = true

  # Enable Instance Refresh for zero-downtime updates
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 90
      instance_warmup        = 300
    }
    triggers = ["launch_template"]
  }

  tag {
    key                 = "Name"
    value               = "${var.name_prefix}-ecs"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# ECS Capacity Provider
resource "aws_ecs_capacity_provider" "cp" {
  name = "${var.name_prefix}-cp"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs_asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status                    = "ENABLED"
      target_capacity           = 75
      minimum_scaling_step_size = 1
      maximum_scaling_step_size = 1000
      instance_warmup_period    = 300
    }
  }

  depends_on = [aws_autoscaling_group.ecs_asg]
}

# Attach Capacity Provider to ECS Cluster
resource "aws_ecs_cluster_capacity_providers" "attach" {
  cluster_name       = var.cluster_name
  capacity_providers = [aws_ecs_capacity_provider.cp.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.cp.name
    weight            = 1
    base              = 1
  }

  depends_on = [aws_ecs_capacity_provider.cp]
}
