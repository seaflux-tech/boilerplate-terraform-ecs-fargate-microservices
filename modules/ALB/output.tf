output "target_group_arn" {
    value = "${aws_lb_target_group.example-api.arn}"
}