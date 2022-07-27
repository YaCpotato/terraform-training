#--------------------------------------------------
# kinesis data firehose
#--------------------------------------------------

resource "aws_kinesis_firehose_delivery_stream" "waf_log" {
  name        = "aws-waf-logs-${var.project}-${var.environment}"
  destination = "extended_s3"

  extended_s3_configuration {
    role_arn   = aws_iam_role.this.arn
    bucket_arn = var.bucket_arn

    prefix              = "!{timestamp:yyyy-MM-dd}/"
    error_output_prefix = "!{timestamp:yyyy-MM-dd}/error=!{firehose:error-output-type}/"
    buffer_size         = 5
    buffer_interval     = 60
  }
}

# iam
resource "aws_iam_role" "this" {
  name               = "${var.project}-${var.environment}-iam-role-for-kinesis-data-firehose"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-iam-role-for-kinesis-data-firehose"
    Environment = var.environment
    Project     = var.project
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "this" {
  name   = "firehose-to-s3-${var.project}-${var.environment}-waf-log"
  policy = data.aws_iam_policy_document.firehose_custom.json
}

data "aws_iam_policy_document" "firehose_custom" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.this.arn
}
