provider "aws" {
  region = "us-east-1"
}

variable "projeto" {
  description = "Desafio-VExpenses"
  type        = string
  default     = "VExpenses"
}

variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "Daniel_Guimarães_Silva"
}

variable "admin_ip" {
  description = "IP do administrador para acesso SSH"
  type        = string
  default     = "123.123.123.123" # Altere para o IP do administrador
}

resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"
  public_key = tls_private_key.ec2_key.public_key_openssh
}

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"
  }
}

resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"
  }
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"
  }
}

resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id
  route_table_id = aws_route_table.main_route_table.id

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"
  }
}

resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"
  description = "Permitir SSH de IP específico e todo o tráfego de saída"
  vpc_id      = aws_vpc.main_vpc.id

  # Regras de entrada
  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

   ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permite acesso HTTP de qualquer IP
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Permite acesso HTTPS de qualquer IP
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"
  }
} 

# Topico SNS para monitorar a CPU
resource "aws_sns_topic" "high_cpu_alerts" {
  name = "${var.projeto}-${var.candidato}-high-cpu-alerts"
}


resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.high_cpu_alerts.arn
  protocol  = "email" # Pode ser 'email', 'sms', etc.
  endpoint  = "seu_email@example.com" # Substitua pelo seu e-mail
}

resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "${var.projeto}-${var.candidato}-high-cpu-usage"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = 70
  alarm_description   = "Este alarme é acionado quando a utilização de CPU excede 70% por dois períodos consecutivos de 5 minutos."
  dimensions = {
    InstanceId = aws_instance.debian_ec2.id
  }
  alarm_actions = [
    aws_sns_topic.high_cpu_alerts.arn 
  ]
  ok_actions = [
    aws_sns_topic.high_cpu_alerts.arn 
  ]
  actions_enabled = true
}

data "aws_ami" "debian12" {
  most_recent = true

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["679593333241"]
}

resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.main_subnet.id
  key_name        = aws_key_pair.ec2_key_pair.key_name
  security_groups = [aws_security_group.main_sg.name]

  associate_public_ip_address = true

  root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
    encrypted = true
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get upgrade -y
              apt-get install -y nginx

              # Desabilita o login do usuário root
              echo 'PermitRootLogin no' >> /etc/ssh/sshd_config 

              # reinicializa o serviço para aplicar as mudanças
              systemctl restart sshd

              # inicializa a nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = {
    Name = "${var.projeto}-${var.candidato}-ec2"
  }
}

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
