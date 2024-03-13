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
