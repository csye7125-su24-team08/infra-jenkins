terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
  # shared_config_files = ["$HOME/.aws/config"]
  # shared_credentials_files = ["$HOME/.aws/credentials"]
  profile = var.profile
}

resource "aws_vpc" "infra_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "infra_vpc"
  }
}

resource "aws_internet_gateway" "infra_gw" {
  vpc_id = aws_vpc.infra_vpc.id
  
  tags = {
    Name = "infra_gw"
  }
}

resource "aws_subnet" "infra_subnet" {
  vpc_id            = aws_vpc.infra_vpc.id
  cidr_block        = var.subnet_cidr
  availability_zone = var.availability_zone
  

  tags = {
    Name = "infra_subnet"
  }
}

resource "aws_route_table" "infra_rt" {
  vpc_id = aws_vpc.infra_vpc.id

  route {
    cidr_block = var.default_cidr
    gateway_id = aws_internet_gateway.infra_gw.id
  }

  route {
    cidr_block = aws_vpc.infra_vpc.cidr_block
    gateway_id = "local"
  }

  tags = {
    Name = "tf_route_table"
  }
}

resource "aws_route_table_association" "infra_rta" {
  subnet_id      = aws_subnet.infra_subnet.id
  route_table_id = aws_route_table.infra_rt.id
}

resource "aws_main_route_table_association" "infra_vpc_rta" {
  vpc_id         = aws_vpc.infra_vpc.id
  route_table_id = aws_route_table.infra_rt.id
}

# resource "aws_network_interface" "infra_ni" {
#   subnet_id   = aws_subnet.infra_subnet.id
#   private_ips = ["10.0.0.10"]

#   attachment {
#     instance = 
#   }

#   # tags = {
#   #   Name = "tf_primary_network_interface"
#   # }
# }

resource "aws_iam_role" "tf_jenkins_role" {
  name = "tf_jenkins_role"

  assume_role_policy = var.jenkins_role
}

resource "aws_iam_instance_profile" "tf_jenkins_profile" {
  name = "tf_jenkins_profile"
  role = aws_iam_role.tf_jenkins_role.name
}

resource "aws_iam_role_policy" "tf_jenkins_policy" {
  name = "tf_jenkins_policy"
  role = aws_iam_role.tf_jenkins_role.id

  policy = var.jenkins_policy
}

resource "aws_default_security_group" "infra_dsg" {
  vpc_id = aws_vpc.infra_vpc.id

  ingress {
    protocol  = var.protocol
    self      = true
    from_port = var.https_port
    to_port   = var.https_port
    # cidr_blocks = [aws_subnet.infra_subnet.cidr_block]
    cidr_blocks = [var.default_cidr]
  }

  ingress {
    protocol  = var.protocol
    self      = true
    from_port = var.http_port
    to_port   = var.http_port
    # cidr_blocks = [aws_subnet.infra_subnet.cidr_block]
    cidr_blocks = [var.default_cidr]
  }

  # ingress {
  #   protocol  = "tcp"
  #   self      = true
  #   from_port = 0
  #   to_port   = 22
  #   # cidr_blocks = [aws_subnet.infra_subnet.cidr_block]
  #   cidr_blocks = ["0.0.0.0/0"]
  # }


  egress {
    from_port   = var.jenkins_egress_from_port
    to_port     = var.jenkins_egress_to_port
    protocol    = var.jenkins_egress_protocol
    cidr_blocks = [var.default_cidr]
  }
}

resource "aws_instance" "tf_jenkins" {
  ami               = var.jenkins_ami
  availability_zone = var.availability_zone
  instance_type     = var.instance_type
  subnet_id     = aws_subnet.infra_subnet.id
  iam_instance_profile = aws_iam_instance_profile.tf_jenkins_profile.name

  user_data = var.startup_script

  tags = {
    Name = "tf-jenkins"
  }
}

data "aws_eip" "infra_eip" {
  id = var.infra_eip
}

data "aws_route53_zone" "infra_zone" {
  zone_id = var.infra_zone
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.tf_jenkins.id
  allocation_id = data.aws_eip.infra_eip.id
}

resource "aws_route53_record" "jenkins_dns_rec" {
  zone_id = data.aws_route53_zone.infra_zone.zone_id
  name    = data.aws_route53_zone.infra_zone.name
  type    = "A"
  ttl     = var.jenkins_dns_ttl
  records = [data.aws_eip.infra_eip.public_ip]
}
