variable "ami_id" {
  type        = string
  description = "EC2作成時の基となるAMIのID"
}
variable "subnet_id" {
  type        = string
  description = "EC2が配置されるサブネットのID"
}
variable "security_group_ids" {
  type        = list(string)
  description = "EC2に適用するセキュリティグループのid"
}
variable "instance_type" {
  type        = string
  description = "EC2のインスタンスタイプ"
}
variable "iam_role_policy_arns" {
  type        = list(string)
  description = "EC2にアタッチするインスタンスプロファイルに紐付けるIAMポリシーのarn"
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
