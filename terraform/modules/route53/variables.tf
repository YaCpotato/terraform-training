variable "domain" {
  type        = string
  description = "ドメイン名"
}
variable "sub_domain" {
  type        = string
  description = "サブドメイン名(本番環境では値を渡さない)"
  default     = ""
}
variable "project" {
  type        = string
  description = "プロジェクト名"
}
variable "environment" {
  type        = string
  description = "環境名"
}
