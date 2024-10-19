output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"
  value       = aws_instance.debian_ec2.public_ip
}

output "private_key" {
  description = "Chave privada para acessar a instância EC2 (use-a com cuidado e armazene em local seguro)"
  value       = tls_private_key.ec2_key.private_key_pem
  sensitive   = true
}

output "instance_id" {
  description = "ID da instância EC2"
  value       = aws_instance.debian_ec2.id
}

output "ssh_command" {
  description = "Comando SSH para acessar a instância EC2"
  value       = "ssh -i ${tls_private_key.ec2_key.private_key_pem} ec2-user@${aws_instance.debian_ec2.public_ip}"
  sensitive   = true
}
