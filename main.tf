terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
  shared_config_files = ["$HOME/.aws/config"]
  shared_credentials_files = ["$HOME/.aws/credentials"]
  profile = "infra"
}

resource "aws_vpc" "infra_vpc" {
  cidr_block = "10.0.0.0/16"

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
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  

  # tags = {
  #   Name = "tf-example"
  # }
}

resource "aws_route_table" "infra_rt" {
  vpc_id = aws_vpc.infra_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.infra_gw.id
  }

  route {
    cidr_block = "10.0.0.0/16"
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
#   #   Name = "primary_network_interface"
#   # }
# }

resource "aws_iam_role" "tf_jenkins_role" {
  name = "tf_jenkins_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "tf_jenkins_profile" {
  name = "tf_jenkins_profile"
  role = aws_iam_role.tf_jenkins_role.name
}

resource "aws_iam_role_policy" "tf_jenkins_policy" {
  name = "tf_jenkins_policy"
  role = aws_iam_role.tf_jenkins_role.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "route53:GetChange",
                "route53:ChangeResourceRecordSets",
                "route53:ListResourceRecordSets",
                "route53:ListHostedZonesByName"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_default_security_group" "infra_dsg" {
  vpc_id = aws_vpc.infra_vpc.id

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 80
    to_port   = 443
    # cidr_blocks = [aws_subnet.infra_subnet.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol  = "tcp"
    self      = true
    from_port = 0
    to_port   = 22
    # cidr_blocks = [aws_subnet.infra_subnet.cidr_block]
    cidr_blocks = ["0.0.0.0/0"]
    # source = "18.206.107.24/29"
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# resource "aws_security_group" "infra_sg" {
#   name        = "infra_sg"
#   description = "Allow TLS inbound traffic and all outbound traffic"
#   vpc_id      = aws_vpc.infra_vpc.id

#   tags = {
#     Name = "infra_sg"
#   }
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
#   security_group_id = aws_security_group.infra_sg.id
#   cidr_ipv4         = aws_vpc.infra_vpc.cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
#   security_group_id = aws_security_group.infra_sg.id
#   cidr_ipv6         = aws_vpc.infra_vpc.ipv6_cidr_block
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
#   security_group_id = aws_security_group.infra_sg.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
#   security_group_id = aws_security_group.infra_sg.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

resource "aws_instance" "tf_jenkins" {
  ami               = "ami-0824b7052bb75fb6d"
  availability_zone = "us-east-1a"
  instance_type     = "t2.micro"
  subnet_id     = aws_subnet.infra_subnet.id
  iam_instance_profile = aws_iam_instance_profile.tf_jenkins_profile.name

  user_data = <<-EOL
#!/bin/bash -xe
cd /home/ubuntu
touch file.txt
caddy stop
caddy fmt --overwrite
sudo ./caddy run
EOL

  tags = {
    Name = "tf-jenkins"
  }
}


resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.tf_jenkins.id
  allocation_id = "eipalloc-00d408691ab4dcba1"
}
