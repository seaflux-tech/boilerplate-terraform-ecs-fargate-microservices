terraform {
  backend "s3" {
    bucket  = "example-qa-tfstate"
    key     = "terraform.tfstate"
    region  = "<your-region>"
    profile = "example"
  }
}
# module "vpc" {
#   source  = "terraform-aws-modules/vpc/aws"
#   version = "3.11.5"

#   name                 = var.vpc_name
#   cidr                 = var.cidr
#   azs                  = var.zones_names
#   public_subnets       = var.subnets_ids
#   enable_dns_hostnames = true
#   enable_dns_support   = true
# }
module "ecr-repo" {
  source   = "./modules/ecr"
  ecr_name = var.ecr_name
}

module "s3-bucket" {
  source        = "./modules/s3"
  s3_buckets    = var.s3_buckets
  s3_tags       = var.s3_tags
  s3_versioning = var.s3_versioning
}
module "database" {
  source            = "./modules/RDS"
  db_instance_class = var.db_instance_class
  db_username       = var.db_username
  db_engine_version = var.db_engine_version
  db_name           = var.db_name
  vpc_id            = var.vpc_id
  # kms_key_id        = var.kms_key_id
  vpc_security_group_ids  = var.vpc_security_group_ids
  db_parameter_group_name = var.db_parameter_group_name
  environment             = var.environment
  db_subnet_group_name    = var.db_subnet_group_name
}

module "redis" {
  source                  = "./modules/Redis"
  node_type               = var.node_type
  num_cache_nodes         = var.num_cache_nodes
  engine_version          = var.engine_version
  vpc_id                  = var.vpc_id
  redis_subnet_group_name = var.redis_subnet_group_name
}

module "ecs" {
  source                   = "./modules/ecs"
  public_subnets_ids       = var.public_subnets_ids
  private_subnets_ids      = var.private_subnets_ids
  vpc_id                   = var.vpc_id
  ecs_task_definition      = var.ecs_task_definition
  ecs_container_name       = var.ecs_container_name
  root_domain_name         = var.root_domain_name
  ecs_desired_instances    = var.ecs_desired_instances
  environment              = var.environment
  instance_type            = var.instance_type
  ecs_name                 = var.ecs_name
  key_name                 = var.key_name
  security_groups          = var.security_groups
  asg_max_size             = var.asg_max_size
  asg_min_size             = var.asg_min_size
  ecs_service_name         = var.ecs_service_name
  ecs_container_port       = var.ecs_container_port
  target_type              = var.target_type
  php_image                = var.php_image
  example_varnish_image    = var.example_varnish_image
  nginx_varnish_image      = var.nginx_varnish_image
  example_qa_image_4 = var.example_qa_image_4
  example_qa_image_1      = var.example_qa_image_1
  example_qa_image_5       = var.example_qa_image_5
  example_qa_image_3      = var.example_qa_image_3
  example_qa_image_2       = var.example_qa_image_2
  lt_volume_size           = var.lt_volume_size
  nginx_image              = var.nginx_image
  host_header_example_4_qa = var.host_header_example_4_qa
  host_header_example_1_qa = var.host_header_example_1_qa
  host_header_example_5_qa = var.host_header_example_5_qa
  host_header_example_2_qa = var.host_header_example_2_qa
  host_header_example_3_qa = var.host_header_example_3_qa

}