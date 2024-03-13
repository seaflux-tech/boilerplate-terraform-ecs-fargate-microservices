variable "db_name" {
  type = string
}
variable "vpc_security_group_ids" {
  type = list(string)
}
variable "vpc_id" {
  type = string
}
variable "db_username" {
  type = string
}
variable "environment" {
  type = string
}
variable "db_instance_class" {
  type = string
}
variable "db_parameter_group_name" {
  type = string
}
variable "db_engine_version" {
  type = string
}
variable "db_subnet_group_name" {
  type = string
}
# variable "db_vpc_security_group_ids" {
#   type = list(string)
# }