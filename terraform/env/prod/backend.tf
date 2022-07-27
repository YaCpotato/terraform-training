terraform {
  backend "s3" {
    bucket = "prologue-terraform-prod"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}
