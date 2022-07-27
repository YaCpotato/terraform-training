variable "vpc_cidr_block" {
  type        = string
  description = "VPCのCIDRブロック"
}
variable "public_subnets" {
  description = "パブリックサブネットのCIDRブロック"
}
variable "private_subnets" {
  description = "プライベートサブネットのCIDRブロック"
}
variable "project" {
  type        = string
  description = "プロジェクト名"
}
variable "environment" {
  type        = string
  description = "環境名"
}
