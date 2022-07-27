#--------------------------------------------------
# ses
#--------------------------------------------------

resource "aws_ses_domain_identity" "this" {
  domain = var.domain
}

# for domain validation
resource "aws_route53_record" "verify" {
  zone_id = var.route53_zone_id
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = [aws_ses_domain_identity.this.verification_token]
}

resource "aws_ses_domain_identity_verification" "this" {
  domain = var.domain

  depends_on = [aws_route53_record.verify]
}

# for DKIM
resource "aws_ses_domain_dkim" "this" {
  domain = var.domain
}

resource "aws_route53_record" "dkim" {
  count = 3

  zone_id = var.route53_zone_id
  name    = "${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}._domainkey.${var.domain}"
  type    = "CNAME"
  ttl     = "600"
  records = ["${element(aws_ses_domain_dkim.this.dkim_tokens, count.index)}.dkim.amazonses.com"]
}

# for DMARC
resource "aws_route53_record" "dmarc" {
  zone_id = var.route53_zone_id
  name    = "_dmarc.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["v=DMARC1;p=quarantine;rua=mailto:dmarc-reports@${var.domain}"]
}

# for SPF
resource "aws_ses_domain_mail_from" "this" {
  domain           = var.domain
  mail_from_domain = "mail.${var.domain}"

  depends_on = [
    aws_ses_domain_identity.this
  ]
}

resource "aws_route53_record" "mx_record_for_spf" {
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "MX"
  ttl     = "600"
  records = ["10 feedback-smtp.ap-northeast-1.amazonses.com"] # Ref https://docs.aws.amazon.com/ja_jp/ses/latest/DeveloperGuide/regions.html
}

resource "aws_route53_record" "txt_record_for_spf" {
  zone_id = var.route53_zone_id
  name    = aws_ses_domain_mail_from.this.mail_from_domain
  type    = "TXT"
  ttl     = "600"
  records = ["v=spf1 include:amazonses.com ~all"]
}
