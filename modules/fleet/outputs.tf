output "private_ips" {
  value = aws_instance.fleet[*].private_ip
}
