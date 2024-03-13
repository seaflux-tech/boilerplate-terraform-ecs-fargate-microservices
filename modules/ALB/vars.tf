variable "alb_name" {
  type    = string
}
variable "subnets_ids" {
  type = list(string)
}
variable "security_groups" {
  type = list(string)
}

variable "environment" {
  type = string
}
variable "root_domain_name" {
  type    = string
}

variable "vpc_id" {
  type = string
}

variable "host_header" {
  type = list(string)
}