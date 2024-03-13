resource "aws_ecr_repository" "ecr" {
  for_each             = toset(var.ecr_name)
  name                 = each.key
}
