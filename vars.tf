variable "region" {
  description = "Region name where resources will be created"
  type        = string
}
variable "profile" {
  description = "Profile name to deploy resources with credentials"
  type        = string
}

variable "vpc_id" {
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
variable "ecr_name" {
  description = "The name of the ECR registry"
  type        = any
  # default     = null
}
variable "s3_buckets" {
  type        = string
  description = "(required since we are not using 'bucket') Creates a unique bucket name beginning with the specified prefix. Conflicts with bucket."
}

variable "s3_tags" {
  type        = map(string)
  description = "(Optional) A mapping of tags to assign to the bucket."
  default     = {}
}

variable "s3_versioning" {
  description = "versioning config"
  type        = string
}
variable "root_domain_name" {
  type = string
}
variable "alb_name" {
  type = string
}
variable "public_subnets_ids" {
  type = list(string)
}
variable "private_subnets_ids" {
  type = list(string)
}
# variable "alb_name" {
#   type    = string
# }
# variable "subnets_ids" {
#   type = list(string)
# }
variable "security_groups" {
  type = list(string)
}
variable "db_name" {
  type = string
}
variable "vpc_security_group_ids" {
  type = list(string)
}
# variable "allocated_storage" {
#   type = number
#   # default = null
# }
variable "db_username" {
  type = string
}
# variable "kms_key_id" {
#   type = string
# }
variable "db_instance_class" {
  type = string
}
variable "db_parameter_group_name" {
  type = string
}
variable "db_engine_version" {
  type = string
}
variable "environment" {
  type = string
}
variable "ecs_desired_instances" {
  type = number
}
variable "num_cache_nodes" {
  type = number
}
variable "node_type" {
  type = string
}

variable "engine_version" {
  type    = number
  default = null
}
variable "ecs_container_port" {
  type = number
}

variable "ecs_service_name" {
  type = string
}

variable "ecs_container_name" {
  type = string
}

variable "ecs_name" {
  type = string
}

variable "ecs_task_definition" {
  type = string
}
variable "db_subnet_group_name" {
  type = string
}
# variable "db_vpc_security_group_ids" {
#   type = list(string)
# }
variable "php_image" {
  type = string
}
variable "nginx_image" {
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

variable "redis_subnet_group_name" {
  type = string
}
variable "lt_volume_size" {
  type = number
}