# infra-jenkins
Infrastructure as Code using terraform to set up cloud resources on AWS

## Instructions for setting up infra using terraform
1. Install terraform 
2. Install AWS cli
3. Generate access key using AWS client
4. Authenticate AWS with iam account details using aws configure --profile
5. Use terraform variable "profile" to point to the AWS profile you're using
6. Run terraform init
7. Run terraform validate
8. Run terraform apply
