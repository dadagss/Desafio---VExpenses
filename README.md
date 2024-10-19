# Projeto Terraform - VExpenses

## Descrição do Projeto
Este projeto utiliza Terraform para provisionar uma infraestrutura básica na AWS. A configuração inclui a criação de uma VPC, sub-rede, grupo de segurança, instância EC2 com Debian 12 e automação da instalação do servidor Nginx. As melhorias implementadas incluem ajustes de segurança e otimizações na automação.

## 1. Análise Técnica do Código Terraform

### Arquivo `main.tf`

- **Provider**: O provedor AWS é configurado para a região `us-east-1`.

### Variáveis
- **`projeto`**: Nome do projeto, padrão "VExpenses".
- **`candidato`**: Nome do candidato, padrão "Daniel_Guimarães_Silva".
- **`admin_ip`**: IP do administrador para acesso SSH (preencher com o IP que precisa de acesso).

### Recursos Criados
- **`tls_private_key`**: Gera uma chave privada RSA de 2048 bits.
- **`aws_key_pair`**: Cria um par de chaves na AWS.
- **`aws_vpc`**: Configura uma VPC com CIDR `10.0.0.0/16`.
- **`aws_subnet`**: Cria uma subnet pública com CIDR `10.0.1.0/24`.
- **`aws_internet_gateway`**: Cria um internet gateway.
- **`aws_route_table`**: Define uma tabela de rotas para a internet.
- **`aws_route_table_association`**: Associa a tabela de rotas à subnet.
- **`aws_security_group`**: Configura um grupo de segurança com regras de entrada (SSH restrito) e saída (todo o tráfego permitido).
- **`aws_cloudwatch_metric_alarm`**: Configura um alarme para monitorar a utilização de CPU.
- **`aws_instance`**: Cria uma instância EC2 do tipo `t2.micro` com Nginx instalado e criptografia do disco.
  - **`admin_ip`**: IP do administrador para acesso SSH.

## 2. Modificações e Melhorias do Código Terraform

### Melhorias de Segurança
1. **Restrição de Acesso SSH**: O acesso SSH é restrito ao IP específico definido em `admin_ip`.
  ```  
  # Regras de entrada
  ingress {
    description = "Allow SSH from specific IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }
  ```
2. **Criptografia do Disco**: O volume raiz da instância EC2 é criptografado.
   ```
     root_block_device {
    volume_size           = 20
    volume_type           = "gp2"
    delete_on_termination = true
    ´encrypted = true´
  
  ```
3. **Alarme de Utilização de CPU**: Monitora a CPU e envia alertas conforme necessário.
```
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
```
4. **Desativação do Login de Usuário Root**: Desativa a opção para que o usuário entre em modo administrador.
```
echo 'PermitRootLogin no' >> /etc/ssh/sshd_config 
systemctl restart sshd
```
5. **Regras de Segurança**: Apenas conexões HTTP e HTTPS são permitidas, garantindo que a instância seja acessível apenas via web.
  ```
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
  ```

### Automação da Instalação do Nginx
A instância EC2 é configurada para instalar e iniciar o Nginx automaticamente através do `user_data`.

### Outras Melhorias
1. **Tagging**: As tags são aplicadas para facilitar o gerenciamento e identificação dos recursos.

## 3. Instruções de Uso

### Pré-requisitos
- Terraform instalado.
- Acesso à sua conta AWS.

### Passos para Inicializar e Aplicar a Configuração
1. **Clone o Repositório**:
   ```bash
   git clone https://github.com/dadagss/Desafio---VExpenses.git
   cd <repositorio_onde_foi_clonado>
2. Inicialize o Terraform:
  ```bash
  terraform init
  ```
3. Visualize o plano em execução:
  ```bash
  terraform apply
  ```
Confirme digitando ```yes``` quando verificar se todos os dados estão corretos.
Apos a execução os outputs serão exibidos no terminal, incluindo o IP da instância do EC2

4. Copie o comando SSH fornecido no output ssh_command e execute no terminal para acessar a instância:
  ```bash
  ssh -i <caminho_da_chave_privada> ec2-user@<ec2_public_ip>
  ```
5. Nota:
Para evitar custos desnecessários e destrui a instância:
  ```bash
  terraform destroy
  ```
