output "firehose_arn" {
  value = aws_kinesis_firehose_delivery_stream.waf_log.arn
}