output "domain_zone_id" {
  value = data.aws_route53_zone.parent.id
}
output "domain_name" {
  value = data.aws_route53_zone.parent.name
}
output "sub_domain_zone_id" {
  value = concat(aws_route53_zone.child.*.id, [""])[0]
}
output "sub_domain_name" {
  value = concat(aws_route53_zone.child.*.name, [""])[0]
}
output "certificate_arn" {
  value = aws_acm_certificate.this.arn
}
