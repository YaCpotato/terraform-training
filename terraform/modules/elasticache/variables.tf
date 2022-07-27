variable "subnet_ids" {
  type        = list(string)
  description = "サブネットグループ作成時に指定するサブネットのID"
}
variable "security_group_ids" {
  type        = list(string)
  description = "ElastiCacheに適用するセキュリティグループのid"
}
variable "node_type" {
  type        = string
  description = "ElastiCacheのノードの種類"
}
variable "engine_version" {
  type        = string
  description = "ElastiCache for Redis のバージョン"
}
variable "automatic_failover_enabled" {
  type        = bool
  description = "自動フェイルオーバーの有効化"
}
variable "num_cache_clusters" {
  type        = number
  description = "クラスターの数"
}
variable "node_count" {
  type        = number
  description = "ノードの数"
}
variable "param_group_family" {
  type        = string
  description = "新しく作成するパラメーターグループの基となるパラメーターグループ名"
}
variable "project" {
  type        = string
  description = "プロジェクト名"
}
variable "environment" {
  type        = string
  description = "環境名"
}

