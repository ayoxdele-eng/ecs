# Define variables
variable "cluster_name" {
  default = "my-ecs-cluster"
}

variable "ami_id" {
  type    = string
}

variable "instance_type" {
  type    = string
}

variable "service_name" {
  default = "my-ecs-service"
}

###############

variable "name" {
  description = "A name prefix to apply to all resources"
  type        = string
}


variable "vpc_cidr" {
  description = "The EC2 instance type to use for the launch template"
  type        = string
}



variable "min_size" {
  description = "The minimum size of the autoscaling group"
  type        = number
}

variable "max_size" {
  description = "The maximum size of the autoscaling group"
  type        = number
}

variable "region" {
  description = "Region to create the autoscaling group"
  type        = string
}

variable "desired_capacity" {
  description = "The maximum size of the autoscaling group"
  type        = number
}

variable "termination_policies" {
  description = "The maximum size of the autoscaling group"
  type        = list(string)
}

variable "health_check_grace_period" {
  description = "The maximum size of the autoscaling group"
  type        = number
}

variable "health_check_type" {
  description = "The maximum size of the autoscaling group"
  type        = string
}