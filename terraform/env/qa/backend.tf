terraform {
  backend "s3" {
    bucket = "prologue-terraform-qa"
    key    = "terraform.tfstate"
    region = "ap-northeast-1"
  }
}
