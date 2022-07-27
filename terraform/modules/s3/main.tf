#--------------------------------------------------
# s3
#--------------------------------------------------

resource "aws_s3_bucket" "this" {
  bucket = "${var.project}-${var.environment}-s3-${var.bucket_name}"

  tags = {
    Name        = "${var.project}-${var.environment}-s3-${var.bucket_name}"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_bucket_acl" "this" {
  bucket = aws_s3_bucket.this.id
  acl    = var.acl
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  count = var.enable_delete_lifecycle ? 1 : 0

  bucket = aws_s3_bucket.this.id

  rule {
    id = "7days-lifecycle-for-delete-object"

    expiration {
      # lifecycleの仕様で10日間程度保持される
      days = 7
    }

    status = "Enabled"
  }
}
