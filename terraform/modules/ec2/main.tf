#--------------------------------------------------
# ec2
#--------------------------------------------------

resource "aws_instance" "this" {
  ami                    = var.ami_id
  subnet_id              = var.subnet_id
  vpc_security_group_ids = var.security_group_ids
  instance_type          = var.instance_type
  iam_instance_profile   = aws_iam_instance_profile.this.name

  disable_api_termination = var.deletion_protection

  tags = {
    Name        = "${var.project}-${var.environment}-ec2"
    Environment = var.environment
    Project     = var.project
  }
}

#--------------------------------------------------
# instance profile settings
#--------------------------------------------------

resource "aws_iam_role" "this" {
  name               = "${var.project}-${var.environment}-iam-role-for-ec2"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name        = "${var.project}-${var.environment}-iam-role-for-ec2"
    Environment = var.environment
    Project     = var.project
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(var.iam_role_policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.iam_role_policy_arns[count.index]
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project}-${var.environment}-profile-for-ec2"
  role = aws_iam_role.this.name

  tags = {
    Name        = "${var.project}-${var.environment}-profile-for-ec2"
    Environment = var.environment
    Project     = var.project
  }
}
