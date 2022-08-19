# To run this:
# terraform fmt     [Format our files (optional)]
# terraform init    [Initialise the API]
# terraform plan    [Create a config plan]
# terraform apply   [Apply our config plan]

# Provider setup
provider "aws" {
  access_key = var.access_key
  secret_key = var.secret_key
  region     = "eu-west-1"
}

# Local variables
locals {
  version = 1.2
  # Security Vars
  key_name = "project_key"
  current_cidr_block = "52.31.14.59/32"
}

# Create new VPC
resource "aws_vpc" "main-vpc" {
  cidr_block       = "10.50.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

# Call subnet module to create Subnet Group A
module "subneta" {
  source      = "./modules/subnet"
  cidr_block  = "10.50.0.0/20"
  subnet_name = "main-net-a"
  vpc_id      = aws_vpc.main-vpc.id
}

# Call subnet module to create Subnet Group B
module "subnetb" {
  source      = "./modules/subnet"
  cidr_block  = "10.50.16.0/20"
  subnet_name = "main-net-b"
  vpc_id      = aws_vpc.main-vpc.id
}

# Call subnet module to create Subnet Group C
module "subnetc" {
  source      = "./modules/subnet"
  cidr_block  = "10.50.32.0/20"
  subnet_name = "main-net-c"
  vpc_id      = aws_vpc.main-vpc.id
}

# Security Group B. HTTP, MySQL, Jenkins and SSH from Security Group A
resource "aws_security_group" "allow-ci" {
  name        = "allow_ci_server"
  description = "Allow SSH from controller and Jenkins. Combine with Security Group C"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description = "Allow SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.current_cidr_block]
  }

  ingress {
    description = "Allow Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow_SSH_Jenkins"
  }
}

# Security Group C. HTTP, MySQL
resource "aws_security_group" "allow-http-mysql" {
  name        = "allow_http_mysql"
  description = "Allow HTTP/MySQL"
  vpc_id      = aws_vpc.main-vpc.id

  ingress {
    description = "Allow HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SQL"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow_HTTP_MySQL"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "main-igw" {
  vpc_id = aws_vpc.main-vpc.id
  tags = {
    Name = "Main-IGW"
  }
}

# Create Route Table
resource "aws_route_table" "main-route" {
  vpc_id = aws_vpc.main-vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
  tags = {
    Name = "Main-Route"
  }
}

# Create Route Table Association for Subnet A
resource "aws_route_table_association" "main-assoc-a" {
  subnet_id      = module.subneta.subnet_id
  route_table_id = aws_route_table.main-route.id
}

# Create Route Table Association for Subnet B
resource "aws_route_table_association" "main-assoc-b" {
  subnet_id      = module.subnetb.subnet_id
  route_table_id = aws_route_table.main-route.id
}


# Create Route Table Association for Subnet C
resource "aws_route_table_association" "main-assoc-c" {
  subnet_id      = module.subnetc.subnet_id
  route_table_id = aws_route_table.main-route.id
}

# Generate Private Key for SSH
resource "tls_private_key" "demokey" {
  algorithm = "RSA"
  rsa_bits  = 4096
}


# Generate AWS Key Pair
resource "aws_key_pair" "demokeypair" {
  key_name   = local.key_name
  public_key = tls_private_key.demokey.public_key_openssh
}

# Call EC2 module to create EC2 instance 1 (CI Server)
module "ci" {
  source            = "./modules/ec2"
  instance_name     = "CI Server"
  security_group_id = [aws_security_group.allow-ci.id, aws_security_group.allow-http-mysql.id]
  subnet_id         = module.subneta.subnet_id
  keypair_name      = local.key_name
}

# Call EC2 module to create EC2 instance 2 (Deployment)
module "deployment" {
  source            = "./modules/ec2"
  instance_name     = "Deployment"
  security_group_id = [aws_security_group.allow-http-mysql.id]
  subnet_id         = module.subnetb.subnet_id
  keypair_name      = local.key_name
}

# Create DB Subnet Group for MySQL RDS
resource "aws_db_subnet_group" "default" {
        name = "main-db-net"
        subnet_ids = [module.subneta.subnet_id, module.subnetb.subnet_id]
        tags = {
                Name = "Default-DB-Group"
        }
}

# Create MySQL RDS
resource "aws_db_instance" "db" {
        allocated_storage = 10
        engine = "mysql"
        instance_class = "db.t2.micro"
        db_name = "mydatabase"
        identifier = "database-1"
        username = var.db_username
        password = var.db_password
        db_subnet_group_name = aws_db_subnet_group.default.id
}