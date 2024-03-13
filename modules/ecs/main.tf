resource "aws_ecs_cluster" "example" {
  name = "${var.ecs_name}-${var.environment}"
  
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_acm_certificate" "example" {
  domain_name       = var.root_domain_name
  validation_method = "DNS"
  key_algorithm = "RSA_2048"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role" "ecs_node_role" {
  name_prefix        = "example-ecs-node-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_node_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_node_role_policy" {
  role       = aws_iam_role.ecs_node_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_node" {
  name_prefix = "example-ecs-node-profile"
  path        = "/ecs/instance/"
  role        = aws_iam_role.ecs_node_role.name
}

resource "aws_security_group" "ecs_node_sg" {
  name_prefix = "example-ecs-node-sg-"
  depends_on  = [ aws_security_group.lb ]
  vpc_id      = var.vpc_id
  
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.lb.id]
    # cidr_blocks = ["${aws_security_group.lb.id}"]
  }

  egress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "ecs_ec2" {
  name_prefix            = "example-ecs-ec2-"
  image_id               = data.aws_ssm_parameter.ecs_node_ami.value
  instance_type          = var.instance_type
  key_name               = var.key_name
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size = var.lt_volume_size
    }
  }
  
  vpc_security_group_ids = [aws_security_group.ecs_node_sg.id]

  iam_instance_profile { arn = aws_iam_instance_profile.ecs_node.arn }
  monitoring { enabled = true }

  user_data = base64encode(<<-EOF
      #!/bin/bash
      echo ECS_CLUSTER=${aws_ecs_cluster.example.name} >> /etc/ecs/ecs.config;
    EOF
  )
}

resource "aws_autoscaling_group" "ecs" {
  name_prefix               = "example-ecs-asg-"
  vpc_zone_identifier       = var.private_subnets_ids
  min_size                  = var.asg_min_size
  max_size                  = var.asg_max_size
  health_check_grace_period = 300
  health_check_type         = "EC2"
  protect_from_scale_in     = true
  

  launch_template {
    id      = aws_launch_template.ecs_ec2.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "example-ecs-cluster"
    propagate_at_launch = true
  }

  tag {
    key                 = "AmazonECSManaged"
    value               = ""
    propagate_at_launch = true
  }
}
resource "aws_ecs_capacity_provider" "example" {
  name = "example-ecs-ec2"

  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.ecs.arn
    managed_termination_protection = "DISABLED"

    managed_scaling {
      maximum_scaling_step_size = 5
      minimum_scaling_step_size = 1
      status                    = "ENABLED"
      target_capacity           = 100
    }
  }
}

resource "aws_ecs_cluster_capacity_providers" "example" {
  cluster_name       = aws_ecs_cluster.example.name
  capacity_providers = [aws_ecs_capacity_provider.example.name]

  default_capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
    base              = 0
    weight            = 1
  }
}

resource "aws_iam_role" "ecs_task_role" {
  name_prefix        = "example-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role" "ecs_exec_role" {
  name_prefix        = "example-ecs-exec-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_doc.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy_cloudwatch" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchFullAccess"
}

resource "aws_iam_role_policy_attachment" "ecs_exec_role_policy_efs" {
  role       = aws_iam_role.ecs_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonElasticFileSystemClientFullAccess"
}


resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/example"
  retention_in_days = 30
}

resource "aws_ecs_task_definition" "example_4" {
  family             = "example_4-qa"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  requires_compatibilities = [ "EC2" ]
  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
  network_mode       = "bridge"
  # cpu                = 256
  # memory             = 512
  volume {
    name = "log_volumes"
    docker_volume_configuration {
      scope = "task"
      driver = "local"
    }
  }
  # container_definitions = file("task-definitions.json")
  container_definitions = jsonencode(
  [
       {
            "name": "php",
            "image": var.example_qa_image_4,
            "cpu": 0,
            "memoryReservation": 1024,
            "portMappings": [
                {
                    "name": "php-9000-tcp",
                    "containerPort": 9000,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "php-fpm",
                "-R"
            ],
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_4-php-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        },
        {
            "name": "nginx",
            "image": var.nginx_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "php:php"
            ],
            "portMappings": [
                {
                    "name": "nginx-8080-tcp",
                    "containerPort": 8080,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_4-nginx-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        },
        {
            "name": "example-varnish",
            "image": var.example_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "nginx:nginx-server"
            ],
            "portMappings": [
                {
                    "name": "varnish-80-tcp",
                    "containerPort": 80,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": false,
            "environment": [],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_4-varnish-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        }
    ]
  )
}

resource "aws_ecs_task_definition" "example_5-qa" {
  family             = "example_5-qa"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  requires_compatibilities = [ "EC2" ]
  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
  network_mode       = "bridge"
  # cpu                = 256
  # memory             = 512
  volume {
    name = "log_volumes"
    docker_volume_configuration {
      scope = "task"
      driver = "local"
    }
  }
  # container_definitions = file("task-definitions.json")
  container_definitions = jsonencode(
  [
       {
            "name": "php",
            "image": var.example_qa_image_5,
            "cpu": 0,
            "memoryReservation": 1024,
            "portMappings": [
                {
                    "name": "php-9000-tcp",
                    "containerPort": 9000,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "php-fpm",
                "-R"
            ],
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_5-php-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        },
        {
            "name": "nginx",
            "image": var.nginx_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "php:php"
            ],
            "portMappings": [
                {
                    "name": "nginx-8080-tcp",
                    "containerPort": 8080,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_5-nginx-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        },
        {
            "name": "example-varnish",
            "image": var.example_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "nginx:nginx-server"
            ],
            "portMappings": [
                {
                    "name": "varnish-80-tcp",
                    "containerPort": 80,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": false,
            "environment": [],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_5-varnish-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
  )

}
resource "aws_ecs_task_definition" "example_3-qa" {
  family             = "example_3-qa"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  requires_compatibilities = [ "EC2" ]
  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
  network_mode       = "bridge"
  # cpu                = 256
  # memory             = 512
  volume {
    name = "log_volumes"
    docker_volume_configuration {
      scope = "task"
      driver = "local"
    }
  }
  # container_definitions = file("task-definitions.json")
  container_definitions = jsonencode(
  [
       {
            "name": "php",
            "image": var.example_qa_image_3,
            "cpu": 0,
            "memoryReservation": 1024,
            "portMappings": [
                {
                    "name": "php-9000-tcp",
                    "containerPort": 9000,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "php-fpm",
                "-R"
            ],
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_3-php-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        },
        {
            "name": "nginx",
            "image": var.nginx_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "php:php"
            ],
            "portMappings": [
                {
                    "name": "nginx-8080-tcp",
                    "containerPort": 8080,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_3-nginx-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        },
        {
            "name": "example-varnish",
            "image": var.example_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "nginx:nginx-server"
            ],
            "portMappings": [
                {
                    "name": "varnish-80-tcp",
                    "containerPort": 80,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": false,
            "environment": [],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_3-varnish-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
  )

}

resource "aws_ecs_task_definition" "example_2-qa" {
  family             = "example_2-qa"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  requires_compatibilities = [ "EC2" ]
  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
  network_mode       = "bridge"
  # cpu                = 256
  # memory             = 512
  volume {
    name = "log_volumes"
    docker_volume_configuration {
      scope = "task"
      driver = "local"
    }
  }
  # container_definitions = file("task-definitions.json")
  container_definitions = jsonencode(
  [
       {
            "name": "php",
            "image": var.example_qa_image_2,
            "cpu": 0,
            "memoryReservation": 1024,
            "portMappings": [
                {
                    "name": "php-9000-tcp",
                    "containerPort": 9000,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "php-fpm",
                "-R"
            ],
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_2-php-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        },
        {
            "name": "nginx",
            "image": var.nginx_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "php:php"
            ],
            "portMappings": [
                {
                    "name": "nginx-8080-tcp",
                    "containerPort": 8080,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_2-nginx-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        },
        {
            "name": "example-varnish",
            "image": var.example_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "nginx:nginx-server"
            ],
            "portMappings": [
                {
                    "name": "varnish-80-tcp",
                    "containerPort": 80,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": false,
            "environment": [],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_2-varnish-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
  )

}

resource "aws_ecs_task_definition" "example_1-qa" {
  family             = "example_1-qa"
  task_role_arn      = aws_iam_role.ecs_task_role.arn
  execution_role_arn = aws_iam_role.ecs_exec_role.arn
  requires_compatibilities = [ "EC2" ]
  runtime_platform {
    cpu_architecture = "X86_64"
    operating_system_family = "LINUX"
  }
  network_mode       = "bridge"
  # cpu                = 256
  # memory             = 512
  volume {
    name = "log_volumes"
    docker_volume_configuration {
      scope = "task"
      driver = "local"
    }
  }
  # container_definitions = file("task-definitions.json")
  container_definitions = jsonencode(
  [
       {
            "name": "php",
            "image": var.example_qa_image_1,
            "cpu": 0,
            "memoryReservation": 1024,
            "portMappings": [
                {
                    "name": "php-9000-tcp",
                    "containerPort": 9000,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "command": [
                "php-fpm",
                "-R"
            ],
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_1-php-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        },
        {
            "name": "nginx",
            "image": var.nginx_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "php:php"
            ],
            "portMappings": [
                {
                    "name": "nginx-8080-tcp",
                    "containerPort": 8080,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": true,
            "environment": [],
            "mountPoints": [
                {
                    "sourceVolume": "log_volumes",
                    "containerPath": "/var/www/example"
                }
            ],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_1-nginx-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                },
                "secretOptions": []
            }
        },
        {
            "name": "example-varnish",
            "image": var.example_varnish_image,
            "cpu": 0,
            "memoryReservation": 102,
            "links": [
                "nginx:nginx-server"
            ],
            "portMappings": [
                {
                    "name": "varnish-80-tcp",
                    "containerPort": 80,
                    "hostPort": 0,
                    "protocol": "tcp"
                }
            ],
            "essential": false,
            "environment": [],
            "mountPoints": [],
            "volumesFrom": [],
            "logConfiguration": {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-create-group": "true",
                    "awslogs-group": "/ecs/example_1-varnish-qa",
                    "awslogs-region": "<your-region>",
                    "awslogs-stream-prefix": "ecs"
                }
            }
        }
    ]
  )

}
resource "aws_security_group" "ecs_task" {
  name_prefix = "ecs-task-sg-"
  description = "Allow all traffic within the VPC"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_ecs_service" "example_4-qa" {
  name            = "example_4-qa"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example_4.arn
  desired_count   = var.ecs_desired_instances
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
    base              = 0
    weight            = 1
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  depends_on = [aws_lb_target_group.example_4-qa]

  load_balancer {
    target_group_arn = aws_lb_target_group.example_4-qa.arn
    container_name   = "example-varnish"
    container_port   = 80
  }
}

resource "aws_ecs_service" "example_5-qa" {
  name            = "example_5-qa"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example_5-qa.arn
  desired_count   = var.ecs_desired_instances
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
    base              = 0
    weight            = 1
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  depends_on = [aws_lb_target_group.example_5-qa]

  load_balancer {
    target_group_arn = aws_lb_target_group.example_5-qa.arn
    container_name   = "example-varnish"
    container_port   = 80
  }
}

resource "aws_ecs_service" "example_1-qa" {
  name            = "example_1-qa"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example_1-qa.arn
  desired_count   = var.ecs_desired_instances
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }


  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
    base              = 0
    weight            = 1
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  depends_on = [aws_lb_target_group.example_1-qa]

  load_balancer {
    target_group_arn = aws_lb_target_group.example_1-qa.arn
    container_name   = "example-varnish"
    container_port   = 80
  }
}
resource "aws_ecs_service" "example_3-qa" {
  name            = "example_3-qa"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example_3-qa.arn
  desired_count   = var.ecs_desired_instances
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  
  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
    base              = 0
    weight            = 1
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  depends_on = [aws_lb_target_group.example_3-qa]

  load_balancer {
    target_group_arn = aws_lb_target_group.example_3-qa.arn
    container_name   = "example-varnish"
    container_port   = 80
  }
}
resource "aws_ecs_service" "example_2-qa" {
  name            = "example_2-qa"
  cluster         = aws_ecs_cluster.example.id
  task_definition = aws_ecs_task_definition.example_2-qa.arn
  desired_count   = var.ecs_desired_instances
  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  

  capacity_provider_strategy {
    capacity_provider = aws_ecs_capacity_provider.example.name
    base              = 0
    weight            = 1
  }

  lifecycle {
    ignore_changes = [desired_count]
  }
  depends_on = [aws_lb_target_group.example_2-qa]

  load_balancer {
    target_group_arn = aws_lb_target_group.example_2-qa.arn
    container_name   = "example-varnish"
    container_port   = 80
  }
}
resource "aws_security_group" "lb" {
  name_prefix = "qa-lb-sg-"
  description = "Allow all HTTP/HTTPS traffic from public"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example" {
  name               = "example-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets_ids
  security_groups    = [aws_security_group.lb.id]
}


resource "aws_lb_target_group" "example_4-qa" {
  name                 = "${var.environment}-example_4"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = 60
  health_check {
    enabled             = true
    path                = "/health_check.php"
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "example_5-qa" {
  name                 = "${var.environment}-example_5"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = 60
  health_check {
    enabled             = true
    path                = "/health_check.php"
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "example_1-qa" {
  name                 = "${var.environment}-example_1"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = 60
  health_check {
    enabled             = true
    path                = "/health_check.php"
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "example_3-qa" {
  name                 = "${var.environment}-example_3"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = 60
  health_check {
    enabled             = true
    path                = "/health_check.php"
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "example_2-qa" {
  name                 = "${var.environment}-example_2"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  target_type          = var.target_type
  deregistration_delay = 60
  health_check {
    enabled             = true
    path                = "/health_check.php"
    interval            = 30
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 2
  }
}
resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.example.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      protocol     = "HTTPS"
      port         = "443"
      status_code  = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.example.arn
  certificate_arn   = aws_acm_certificate.example.arn
  port              = 443
  protocol          = "HTTPS"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "HEALTHY"
      status_code  = "200"
    }
  }
}

resource "aws_lb_listener_rule" "redirect-http-https-example_4-qa" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 2
  

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_4-qa.arn
  }

  condition {
    host_header {
      values = var.host_header_example_4_qa
    }
  }
}

resource "aws_lb_listener_rule" "redirect_http_to_https_example_5_qa" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 3
  

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_5-qa.arn
  }

  condition {
    host_header {
      values = var.host_header_example_5_qa
    }
  }
}

resource "aws_lb_listener_rule" "redirect_http_to_https_example_1_qa" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 4
  

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_1-qa.arn
  }

  condition {
    host_header {
      values = var.host_header_example_1_qa
    }
  }
}
resource "aws_lb_listener_rule" "redirect_http_to_https_example_3_qa" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 5
  

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_3-qa.arn
  }

  condition {
    host_header {
      values = var.host_header_example_3_qa
    }
  }
}
resource "aws_lb_listener_rule" "redirect_http_to_https_example_2_qa" {
  listener_arn = aws_lb_listener.https_listener.arn
  priority     = 6
  

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.example_2-qa.arn
  }

  condition {
    host_header {
      values = var.host_header_example_2_qa
    }
  }
}