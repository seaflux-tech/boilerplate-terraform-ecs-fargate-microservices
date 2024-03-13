resource "aws_s3_bucket" "s3-bucket" {
  bucket        = var.s3_buckets
  tags          = var.s3_tags
}

resource "aws_s3_bucket_versioning" "bucket_versioning" {
  bucket = aws_s3_bucket.s3-bucket.id
  versioning_configuration {
    status = var.s3_versioning
  }
}
