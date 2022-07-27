output "this" {
  value = tomap({
    "vpc_id"        = aws_vpc.this.id,
    "private_1a_id" = aws_subnet.private["ap-northeast-1a"].id,
    "private_1c_id" = aws_subnet.private["ap-northeast-1c"].id,
    "public_1a_id"  = aws_subnet.public["ap-northeast-1a"].id,
    "public_1c_id"  = aws_subnet.public["ap-northeast-1c"].id
  })
}
