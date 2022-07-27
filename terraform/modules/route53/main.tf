#--------------------------------------------------
# route53
#--------------------------------------------------

# ドメイン取得時に自動的にホストゾーンが登録されるので、ここでは参照のみ
data "aws_route53_zone" "parent" {
  name = var.domain
}

# サブドメインの管理を委譲する
resource "aws_route53_zone" "child" {
  # 本番環境の場合は作成しない
  count = var.environment == "prod" ? 0 : 1

  name    = var.sub_domain
  comment = "${var.domain}の${var.environment}環境"

  tags = {
    Name        = "${var.project}-${var.environment}-acm"
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_route53_record" "delegate" {
  # 本番環境の場合は作成しない
  count = var.environment == "prod" ? 0 : 1

  zone_id = data.aws_route53_zone.parent.zone_id
  name    = var.sub_domain
  ttl     = 300
  type    = "NS"

  records = [
    aws_route53_zone.child[0].name_servers[0],
    aws_route53_zone.child[0].name_servers[1],
    aws_route53_zone.child[0].name_servers[2],
    aws_route53_zone.child[0].name_servers[3],
  ]
}

resource "aws_acm_certificate" "this" {
  domain_name = var.environment == "prod" ? var.domain : var.sub_domain

  validation_method = "DNS"

  tags = {
    Name        = "${var.project}-${var.environment}-acm"
    Project     = var.project
    Environment = var.environment
  }

  lifecycle {
    # 再作成時は新リソース作成後に元のリソースを削除する
    create_before_destroy = true
  }
}

# DNS検証用レコード追加
resource "aws_route53_record" "certificate" {
  for_each = {
    for dvo in aws_acm_certificate.this.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  ttl     = 60
  type    = each.value.type
  zone_id = var.environment == "prod" ? data.aws_route53_zone.parent.id : aws_route53_zone.child[0].id
}

# DNS検証完了まで待機するリソース
resource "aws_acm_certificate_validation" "this" {
  certificate_arn         = aws_acm_certificate.this.arn
  validation_record_fqdns = [for record in aws_route53_record.certificate : record.fqdn]
}
