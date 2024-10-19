# Variáveis para configuração geral
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
}