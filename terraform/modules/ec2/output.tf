output "ec2_id" {
  description = "id of ec2 instance"
  value       = aws_instance.this.id
}
