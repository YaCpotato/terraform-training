variable "bucket_arn" {
  type        = string
  description = "転送先のS3バケットのarn"
}
variable "project" {
  type        = string
  description = "プロジェクト名"
}
variable "environment" {
  type        = string
  description = "環境名"
}
