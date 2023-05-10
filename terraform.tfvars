
name                      = "demo-asg"
region                    = "us-east-1"
ami_id                    = "ami-013a451d6c08ef928"
instance_type             = "t2.micro"
vpc_cidr                  = "10.0.0.0/16"
# public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
min_size                  = 1
max_size                  = 3


desired_capacity = 2
health_check_type = "ELB"
health_check_grace_period = 300
termination_policies = ["OldestInstance", "Default"]
# environment = "production"




