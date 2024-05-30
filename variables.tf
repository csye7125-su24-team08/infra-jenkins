variable "region" {
  type = string
  default = "us-east-1"
}

variable "profile" {
  type = string
  default = "infra"
}

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

variable "subnet_cidr" {
  type = string
  default = "10.0.0.0/24"
}

variable "availability_zone" {
  type = string
  default = "us-east-1a"
}

variable "default_cidr" {
  type = string
  default = "0.0.0.0/0"
}

# variable "jenkins_role" {
#   type = string
#   default = <<EOF
# {
#   "Version": "2012-10-17",
#   "Statement": [
#     {
#       "Action": "sts:AssumeRole",
#       "Principal": {
#         "Service": "ec2.amazonaws.com"
#       },
#       "Effect": "Allow",
#       "Sid": ""
#     }
#   ]
# }
# EOF
# }

# variable "jenkins_policy" {
#   type = string
#   default = <<EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "",
#             "Effect": "Allow",
#             "Action": [
#                 "route53:GetChange",
#                 "route53:ChangeResourceRecordSets",
#                 "route53:ListResourceRecordSets",
#                 "route53:ListHostedZonesByName"
#             ],
#             "Resource": "*"
#         }
#     ]
# }
# EOF
# }

variable "protocol" {
  type = string
  default = "tcp"
}

variable "http_port" {
  type = number
  default = 80
}

variable "https_port" {
  type = number
  default = 443
}

variable "jenkins_egress_protocol" {
  type = string
  default = "-1"
}

variable "jenkins_egress_from_port" {
  type = number
  default = 0
}

variable "jenkins_egress_to_port" {
  type = number
  default = 0
}

variable "jenkins_ami" {
  type = string
  default = "ami-0824b7052bb75fb6d"
}

variable "instance_type" {
  type = string
  default = "t2.micro"
}

variable "infra_eip" {
  type = string
  default = "eipalloc-00d408691ab4dcba1"
}

variable "infra_zone" {
  type = string
  default = "Z04412832AAIXSHHIZ7VG"
}

variable "jenkins_dns_ttl" {
  type = number
  default = 60
}

# variable "startup_script" {
#   type = string
#   default = <<-EOL
# #!/bin/bash -xe
# cd /home/ubuntu
# caddy stop
# caddy fmt --overwrite
# sudo ./caddy run
# EOL
# }
