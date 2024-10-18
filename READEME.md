# Desafio: Automação com Terraform para Ambiente AWS

## 1. Análise Técnica do Código Terraform

### Arquivo `main.tf`

- **Provider**: O provedor AWS é configurado para a região `us-east-1`.

- **Variáveis**:
  - **`projeto`**: Nome do projeto, padrão "VExpenses".
  - **`candidato`**: Nome do candidato, padrão "Daniel_Guimarães_Silva".
  - **`admin_ip`**: IP do administrador para acesso SSH.

- **Recursos Criados**:
  - **`tls_private_key`**: Gera uma chave privada RSA de 2048 bits.
  - **`aws_key_pair`**: Cria um par de chaves na AWS.
  - **`aws_vpc`**: Configura uma VPC com CIDR `10.0.0.0/16`.
  - **`aws_subnet`**: Cria uma subnet pública com CIDR `10.0.1.0/24`.
  - **`aws_internet_gateway`**: Cria um internet gateway.
  - **`aws_route_table`**: Define uma tabela de rotas para a internet.
  - **`aws_route_table_association`**: Associa a tabela de rotas à subnet.
  - **`aws_security_group`**: Configura um grupo de segurança com regras de entrada e saída.
  - **`aws_cloudwatch_metric_alarm`**: Configura um alarme para monitorar a utilização de CPU.
  - **`aws_instance`**: Cria uma instância EC2 do tipo `t2.micro` com Nginx instalado.

## 2. Modificações e Melhorias do Código Terraform

### Melhorias de Segurança
1. **Criptografia do Disco**: O volume raiz da instância EC2 é criptografado.
2. **Restrição de Acesso SSH**: O acesso SSH é restrito ao IP específico.
3. **Desativação do Login de Usuário Root**: (Nova medida a considerar)

### Automação da Instalação do Nginx
A instância EC2 é configurada para instalar e iniciar o Nginx automaticamente através do `user_data`.

### Outras Melhorias
1. **Alarme de Utilização de CPU**: Monitora a CPU e envia alertas conforme necessário.
2. **Tagging**: As tags são aplicadas para facilitar o gerenciamento.

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