# Define o provedor AWS e a região a ser utilizada
provider "aws" {
  region = var.aws_region  # Região AWS a ser utilizada para criar os recursos
}

# Gera uma chave privada para a instância EC2
resource "tls_private_key" "ec2_key" {
  algorithm = "RSA"  # Algoritmo de chave
  rsa_bits  = 2048   # Tamanho da chave em bits
}

# Cria um par de chaves AWS usando a chave privada gerada
resource "aws_key_pair" "ec2_key_pair" {
  key_name   = "${var.projeto}-${var.candidato}-key"  # Nome do par de chaves, formatado com projeto e candidato
  public_key = tls_private_key.ec2_key.public_key_openssh  # Chave pública gerada
}

# Cria uma VPC (Virtual Private Cloud)
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr  # CIDR para a VPC, permite o isolamento dos recursos
  enable_dns_support   = true  # Habilita o suporte a DNS na VPC
  enable_dns_hostnames = true  # Habilita nomes DNS para instâncias na VPC

  tags = {
    Name = "${var.projeto}-${var.candidato}-vpc"  # Nome da VPC formatado com o nome do projeto e do candidato
  }
}

# Cria uma sub-rede dentro da VPC
resource "aws_subnet" "main_subnet" {
  vpc_id            = aws_vpc.main_vpc.id  # ID da VPC à qual a sub-rede pertence
  cidr_block        = var.subnet_cidr  # CIDR da sub-rede
  availability_zone = "us-east-1a"  # Zona de disponibilidade para a sub-rede

  tags = {
    Name = "${var.projeto}-${var.candidato}-subnet"  # Nome da sub-rede
  }
}

# Cria um gateway de internet para a VPC
resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main_vpc.id  # ID da VPC à qual o gateway de internet está associado

  tags = {
    Name = "${var.projeto}-${var.candidato}-igw"  # Nome do gateway de internet
  }
}

# Cria uma tabela de rotas para a VPC
resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main_vpc.id  # ID da VPC à qual a tabela de rotas pertence

  route {
    cidr_block = "0.0.0.0/0"  # Rota para todo o tráfego
    gateway_id = aws_internet_gateway.main_igw.id  # Gateway de internet a ser utilizado
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table"  # Nome da tabela de rotas
  }
}

# Associa a sub-rede à tabela de rotas
resource "aws_route_table_association" "main_association" {
  subnet_id      = aws_subnet.main_subnet.id  # ID da sub-rede
  route_table_id = aws_route_table.main_route_table.id  # ID da tabela de rotas

  tags = {
    Name = "${var.projeto}-${var.candidato}-route_table_association"  # Nome da associação
  }
}

# Cria um grupo de segurança para a VPC
resource "aws_security_group" "main_sg" {
  name        = "${var.projeto}-${var.candidato}-sg"  # Nome do grupo de segurança
  description = "Permitir SSH de IP específico e todo o tráfego de saída"  # Descrição da finalidade do grupo de segurança
  vpc_id      = aws_vpc.main_vpc.id  # Associar o grupo de segurança à VPC

  # Regras de entrada
  ingress {
    description = "Allow SSH from specific IP"  # Permite SSH apenas do IP especificado
    from_port   = 22  # Porta de entrada para SSH
    to_port     = 22  # Porta de saída para SSH
    protocol    = "tcp"  # Protocolo TCP
    cidr_blocks = [var.admin_ip]  # Permitir acesso SSH apenas do IP definido na variável
  }

  ingress {
    description = "Allow HTTP traffic"  # Permite tráfego HTTP
    from_port   = 80  # Porta de entrada para HTTP
    to_port     = 80  # Porta de saída para HTTP
    protocol    = "tcp"  # Protocolo TCP
    cidr_blocks = ["0.0.0.0/0"]  # Permite acesso HTTP de qualquer IP
  }

  ingress {
    description = "Allow HTTPS traffic"  # Permite tráfego HTTPS
    from_port   = 443  # Porta de entrada para HTTPS
    to_port     = 443  # Porta de saída para HTTPS
    protocol    = "tcp"  # Protocolo TCP
    cidr_blocks = ["0.0.0.0/0"]  # Permite acesso HTTPS de qualquer IP
  }

  # Regras de saída
  egress {
    description      = "Allow all outbound traffic"  # Permite todo o tráfego de saída
    from_port        = 0  # Porta de saída para todo o tráfego
    to_port          = 0  # Porta de saída para todo o tráfego
    protocol         = "-1"  # Todos os protocolos
    cidr_blocks      = ["0.0.0.0/0"]  # Permite tráfego de saída para qualquer IP
    ipv6_cidr_blocks = ["::/0"]  # Permite tráfego de saída para qualquer IPv6
  }

  tags = {
    Name = "${var.projeto}-${var.candidato}-sg"  # Nome do grupo de segurança
  }
}

# Cria um tópico SNS para monitorar a utilização da CPU
resource "aws_sns_topic" "high_cpu_alerts" {
  name = "${var.projeto}-${var.candidato}-high-cpu-alerts"  # Nome do tópico SNS
}

# Cria uma assinatura para o tópico SNS que envia alertas para um e-mail
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.high_cpu_alerts.arn  # ARN do tópico SNS
  protocol  = "email"  # Protocolo para envio de alertas (neste caso, e-mail)
  endpoint  = "seu_email@example.com"  # Substitua pelo seu e-mail para receber alertas
}

# Cria um alarme do CloudWatch para monitorar a utilização da CPU
resource "aws_cloudwatch_metric_alarm" "high_cpu_alarm" {
  alarm_name          = "${var.projeto}-${var.candidato}-high-cpu-usage"  # Nome do alarme
  comparison_operator = "GreaterThanThreshold"  # Operador de comparação para o alarme
  evaluation_periods  = 2  # Número de períodos a serem avaliados
  metric_name         = "CPUUtilization"  # Métrica a ser monitorada
  namespace           = "AWS/EC2"  # Namespace da métrica
  period              = 300  # Período de avaliação em segundos
  statistic           = "Average"  # Estatística a ser utilizada
  threshold           = 70  # Limite para acionar o alarme (70% de utilização da CPU)
  alarm_description   = "Este alarme é acionado quando a utilização de CPU excede 70% por dois períodos consecutivos de 5 minutos."  # Descrição do alarme
  dimensions = {
    InstanceId = aws_instance.debian_ec2.id  # ID da instância a ser monitorada
  }
  alarm_actions = [
    aws_sns_topic.high_cpu_alerts.arn  # Ação a ser tomada quando o alarme é acionado
  ]
  ok_actions = [
    aws_sns_topic.high_cpu_alerts.arn  # Ação a ser tomada quando a utilização da CPU retorna ao normal
  ]
  actions_enabled = true  # Habilita ações para o alarme
}

# Obtém a imagem AMI mais recente para Debian 12
data "aws_ami" "debian12" {
  most_recent = true  # Garante que a AMI mais recente seja utilizada

  filter {
    name   = "name"  # Filtro para o nome da AMI
    values = ["debian-12-amd64-*"]  # Filtra as AMIs para Debian 12
  }

  filter {
    name   = "virtualization-type"  # Filtro para o tipo de virtualização
    values = ["hvm"]  # Filtra apenas AMIs com virtualização HVM
  }

  owners = ["679593333241"]  # ID do proprietário da AMI (Debian)
}

# Cria uma instância EC2 usando a AMI Debian 12
resource "aws_instance" "debian_ec2" {
  ami             = data.aws_ami.debian12.id  # ID da AMI a ser utilizada
  instance_type   = var.instance_type  # Tipo da instância EC2
  subnet
