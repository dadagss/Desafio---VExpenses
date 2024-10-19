# Variáveis para configuração geral

# Nome do projeto
variable "projeto" {
  description = "Desafio-VExpenses"
  type        = string
  default     = "VExpenses"
}

# Nome do candidato
variable "candidato" {
  description = "Nome do candidato"
  type        = string
  default     = "Daniel_Guimarães_Silva"
}

# IP do administrador para acesso SSH
variable "admin_ip" {
  description = "IP do administrador para acesso SSH"
  type        = string
}

# Região AWS para criação dos recursos
variable "aws_region" {
  description = "A região AWS para criar os recursos"
  type        = string
  default     = "us-east-1"
}

# CIDR block da VPC
variable "vpc_cidr" {
  description = "CIDR block da VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# CIDR block da Sub-rede
variable "subnet_cidr" {
  description = "CIDR block da Sub-rede"
  type        = string
  default     = "10.0.1.0/24"
}

# Tipo da instância EC2
variable "instance_type" {
  description = "Tipo da instância EC2"
  type        = string
  default     = "t2.micro"
}
