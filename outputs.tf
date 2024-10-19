# Saída que fornece o endereço IP público da instância EC2
output "ec2_public_ip" {
  description = "Endereço IP público da instância EC2"  
  value       = aws_instance.debian_ec2.public_ip  # Valor que retorna o IP público da instância
}

# Saída que fornece a chave privada utilizada para acessar a instância EC2
output "private_key" {
  description = "Chave privada para acessar a instância EC2 (use-a com cuidado e armazene em local seguro)"   
  value       = tls_private_key.ec2_key.private_key_pem  # Valor que retorna a chave privada em formato PEM
  sensitive   = true  # Marca a saída como sensível para evitar exposição em logs
}

# Saída que fornece o ID da instância EC2
output "instance_id" {
  description = "ID da instância EC2"  
  value       = aws_instance.debian_ec2.id  # Valor que retorna o ID da instância EC2
}

# Saída que fornece o comando SSH para acessar a instância EC2
output "ssh_command" {
  description = "Comando SSH para acessar a instância EC2"  
  value       = "ssh -i ${tls_private_key.ec2_key.private_key_pem} ec2-user@${aws_instance.debian_ec2.public_ip}"  # Comando formatado para acesso via SSH
  sensitive   = true  # Marca a saída como sensível para evitar exposição em logs
}
