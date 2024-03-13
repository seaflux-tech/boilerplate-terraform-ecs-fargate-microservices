variable "ecs_name" {
  type = string
}
variable "environment" {
  type = string
}
variable "ecs_task_definition" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_desired_instances" {
  type = string
}

variable "public_subnets_ids" {
  type = list(string)
}

variable "private_subnets_ids" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "ecs_container_name" {
  type = string
}

variable "vpc_id" {
  type = string
}
variable "ecs_container_port" {
  type = number
}

variable "root_domain_name" {
  type = string
}
# variable "host_header" {
#   type = list(string)
# }
variable "host_header_example_4_qa" {
  type = list(string)
}
variable "host_header_example_5_qa" {
  type = list(string)
}
variable "host_header_example_1_qa" {
  type = list(string)
}
variable "host_header_example_3_qa" {
  type = list(string)
}
variable "host_header_example_2_qa" {
  type = list(string)
}
variable "php_image" {
  type = string
}
variable "example_varnish_image" {
  type = string
}
variable "nginx_varnish_image" {
  type = string
}
variable "example_qa_image_4" {
  type = string
}
variable "example_qa_image_1" {
  type = string
}
variable "example_qa_image_5" {
  type = string
}
variable "example_qa_image_3" {
  type = string
}
variable "example_qa_image_2" {
  type = string
}
variable "nginx_image" {
  type = string
}
variable "target_type" {
  type = string
}
variable "instance_type" {
  type = string
}
variable "key_name" {
  type = string
}
variable "asg_min_size" {
  type = number
}
variable "asg_max_size" {
  type = number
}
variable "lt_volume_size" {
  type = number
}