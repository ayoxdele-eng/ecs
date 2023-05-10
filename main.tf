# Create a new VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
}


resource "aws_subnet" "my_subnet_a" {
  cidr_block = "10.0.1.0/24"
  vpc_id     = aws_vpc.my_vpc.id
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "my_subnet_b" {
  cidr_block = "10.0.2.0/24"
  vpc_id     = aws_vpc.my_vpc.id
  availability_zone = "us-east-1b"
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.my_vpc.id
}


resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.my_vpc.id
  

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
    # nat_gateway_id = aws_nat_gateway.nat_gateway_a.id
  }


}


# Associate the Route Table with the Subnet
resource "aws_route_table_association" "my_rta" {
#   subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.route_table.id
  subnet_id = aws_subnet.my_subnet_a.id
}

resource "aws_route_table_association" "my_rtb" {
#   subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.route_table.id
  subnet_id = aws_subnet.my_subnet_b.id 
}


resource "aws_security_group" "my_sg" {
  vpc_id = aws_vpc.my_vpc.id  
   name_prefix = "my_sg_"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    # security_groups = [aws_security_group.lb_sg.id]
    cidr_blocks      = ["0.0.0.0/0"] 
  }

  egress {

    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]

  }
  

}


resource "aws_security_group" "lb_sg" {
  vpc_id = aws_vpc.my_vpc.id  
  name_prefix = "my_lb_sg"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
     cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
    # security_groups = [aws_security_group.my_sg.id]
    
  }
}

# Create an ECS cluster
resource "aws_ecs_cluster" "ecs_cluster" {
  name = var.cluster_name
}



# Create a capacity provider
# resource "aws_ecs_capacity_provider" "capacity_provider" {
#   name  = "my-capacity-provider"
#   auto_scaling_group_provider {
#     auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
#     managed_termination_protection = "DISABLED"
#       managed_scaling {
#     maximum_scaling_step_size = 15
#     minimum_scaling_step_size = 1
#     status                    = "ENABLED"
#     target_capacity           = 50
#    }

#   }

# }

# resource "aws_ecs_cluster_capacity_providers" "example" {
#   cluster_name = aws_ecs_cluster.ecs_cluster.name

#   capacity_providers = [aws_ecs_capacity_provider.capacity_provider.name]

#   default_capacity_provider_strategy {
#     base              = 1
#     weight            = 100
#     capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
#   }
# }

resource "aws_iam_role" "ecs-instance-role" {

  name = "ecs-instance-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  inline_policy {
    name = "ecs-instance-policy"
    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Effect = "Allow"
          Action = [
            "ecs:CreateCluster",
            "ecs:DeregisterContainerInstance",
            "ecs:DiscoverPollEndpoint",
            "ecs:Poll",
            "ecs:RegisterContainerInstance",
            "ecs:StartTask",
            "ecs:StartTelemetrySession",
            "ecs:SubmitContainerStateChange",
            "ecs:SubmitTaskStateChange",
            "ecs:*"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "ecr:GetAuthorizationToken",
            "ecr:BatchCheckLayerAvailability",
            "ecr:GetDownloadUrlForLayer",
            "ecr:GetRepositoryPolicy",
            "ecr:DescribeRepositories",
            "ecr:ListImages",
            "ecr:BatchGetImage",
            "ecr:*"
          ]
          Resource = "*"
        },
        {
          Effect = "Allow"
          Action = [
            "logs:CreateLogStream",
            "logs:PutLogEvents"
          ]
          Resource = "arn:aws:logs:*:*:*"
        }
      ]
    })
  }
}



resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs-instance-role.name
}




# Create a launch template for EC2 instances
resource "aws_launch_configuration" "example" {
  name_prefix = "Launch_config_"  
  image_id = var.ami_id
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-profile.name

  instance_type = var.instance_type
  associate_public_ip_address = true
  key_name = "demo"
  security_groups         = ["${aws_security_group.my_sg.id}"]
  user_data               = "${base64encode(file("server.sh"))}"
}

# Create an autoscaling group with the launch template
resource "aws_autoscaling_group" "asg" {
  name_prefix                   = var.name
  launch_configuration          = aws_launch_configuration.example.id
  health_check_type             = var.health_check_type
  health_check_grace_period     = var.health_check_grace_period
  termination_policies          = var.termination_policies
  min_size                      = var.min_size
  max_size                      = var.max_size
  desired_capacity              = var.desired_capacity
  vpc_zone_identifier           = [aws_subnet.my_subnet_a.id, aws_subnet.my_subnet_b.id]
  tag {
    key                 = "AmazonECSManaged"
    value               = true
    propagate_at_launch = true
  }
}


# Create a task definition
resource "aws_ecs_task_definition" "task_definition" {
  family                   = "my-task-definition"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  container_definitions    = jsonencode([
    {
      "name": "nginx",
      "image": "556563769160.dkr.ecr.us-east-1.amazonaws.com/demo-nginx-repo:latest",
      "cpu": 256,
      "memory": 512,
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "protocol": "tcp"
        }
      ]
    }
  ])
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecs_task_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
  role       = aws_iam_role.ecs_task_execution_role.name
}


# Create an ECS service
resource "aws_ecs_service" "service" {
  name            = var.service_name
  cluster         = aws_ecs_cluster.ecs_cluster.arn
  task_definition = aws_ecs_task_definition.task_definition.arn
    desired_count   = 2
#   capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.capacity_provider.name
#   }
#   capacity_provider_strategy {
#     capacity_provider = aws_ecs_capacity_provider.capacity_provider.arn
#     weight            = 100
#   }
#   deployment_controller {
#     type = "ECS"
#   }
  network_configuration {
    subnets = [aws_subnet.my_subnet_a.id,aws_subnet.my_subnet_b.id]
    security_groups = [aws_security_group.my_sg.id]
  }

  # Create an Application Load Balancer listener
  load_balancer {
    # elb_name = 
    target_group_arn = aws_lb_target_group.lb_target.arn
    container_name   = "nginx"
    container_port   = 80
  }
#   execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
}

# Create a new Load Balancerss
resource "aws_lb" "my_lb" {
  name               = "my-lb"
#   internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.my_subnet_a.id, aws_subnet.my_subnet_b.id]
  security_groups    = [aws_security_group.lb_sg.id]
}

# Create a new Target Group
resource "aws_lb_target_group" "lb_target" {
  name        = "example-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.my_vpc.id
  target_type = "ip"



  health_check {
    path     = "/"
    interval = 30
    timeout  = 5
  }
}

resource "aws_lb_listener" "example" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.lb_target.arn
    type             = "forward"
  }
}






