variable "subnet_ids" {
  type        = list(string)
  description = "RDSが配置されるサブネットのID"
}
variable "engine" {
  type        = string
  default     = "aurora-mysql"
  description = "RDSのエンジン"
}
variable "engine_version" {
  type        = string
  description = "RDSのエンジンバージョン"
}
variable "backup_retention_period" {
  type        = number
  default     = 7
  description = "バックアップ保持期間"
}
variable "security_group_ids" {
  type        = list(string)
  description = "RDSに適用するセキュリティグループのid"
}
variable "parameter_group_family" {
  type        = string
  description = "新しく作成するパラメーターグループの基となるパラメーターグループ名"
}
variable "instance_class" {
  type        = string
  description = "RDSのインスタンスクラス"
}
variable "db_password" {
  type        = string
  description = "RDS接続用のパスワード"
}
variable "deletion_protection" {
  type        = bool
  description = "削除保護"
}
variable "skip_final_snapshot" {
  type        = bool
  description = "インスタンス終了時のスナップショット無効化"
}
variable "project" {
  type        = string
  description = "プロジェクト名"
}
variable "environment" {
  type        = string
  description = "環境名"
}
