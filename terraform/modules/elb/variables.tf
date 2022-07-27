variable "vpc_id" {
  type        = string
  description = "VPCのID"
}
variable "subnet_ids" {
  type        = list(string)
  description = "ELBが配置されるサブネットのID"
}
variable "target_id" {
  type        = string
  description = "ターゲットとなるEC2のID"
}
variable "security_group_ids" {
  type        = list(string)
  description = "ELBに適用するセキュリティグループのid"
}
variable "route53_zone_id" {
  type        = string
  description = "ホストゾーンのID"
}
variable "route53_name" {
  type        = string
  description = "ホストゾーン名"
}
variable "certificate_arn" {
  type        = string
  description = "ACMで発行した証明書のarn"
}
variable "deletion_protection" {
  type        = bool
  description = "削除保護"
}
variable "project" {
  type        = string
  description = "プロジェクト名"
}
variable "environment" {
  type        = string
  description = "環境名"
}
