variable "elb_arns" {
  type = map(string)
}
variable "log_destination_arns" {
  type = list(string)
}
variable "project" {}
variable "environment" {}
