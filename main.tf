# Create IAM USer

resource "aws_iam_user" "iam_name" {
  name = "IAM_USER"
}


# Create a custome Policy
resource "aws_iam_policy" "s3_read_policy" {
  name = "PolicyForS3"
  description = "Allows read-only access to S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
        Effect = "Allow",
        Action = [
            "s3:GetObject","s3:ListBucket"
        ],
        Resource = "*"
    }]
  })
}

resource "aws_iam_policy" "route53_policy" {
  name        = "TerraformRoute53Access"
  description = "Allow Route53 management for Terraform"
  policy      = jsonencode({ 
        "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "route53:GetHostedZone",
        "route53:ChangeResourceRecordSets",
        "route53:ListHostedZones",
        "route53:ListResourceRecordSets" 
      ],
      "Resource": "*"
    }
  ]}) 
}

resource "aws_iam_user_policy_attachment" "attach_route53" {
  user       = "terraform-user"
  policy_arn = aws_iam_policy.route53_policy.arn
}


# Attach Policy to User

resource "aws_iam_user_policy_attachment" "attach_policy" {
  user = aws_iam_user.iam_name.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}

# data "aws_ssm_parameter" "ubuntu_ami" {
#   name = "/aws/service/canonical/ubuntu/server/20.04/stable/current/amd64/ami-id"
# }


# Create IAM Role for EC2
resource "aws_iam_role" "ec2_s3_role" {
  name = "ec2_s3_access_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
        Effect = "Allow",
        Principal = {
            Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
    }]
  })
}


# Attach Policy to Role

resource "aws_iam_role_policy_attachment" "attach_policy_to_role" {
  role = aws_iam_role.ec2_s3_role.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}


resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "ec2_s3_profile_v2"
    role = aws_iam_role.ec2_s3_role.name
  
}




data "aws_vpc" "default"{
  default = true
}

# data "aws_subnet_ids" "default"{
# vpc_id = data.aws_vpc.default.id 
# }

data "aws_subnets" "default"{
  filter{
    name = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_security_group" "new_sg" {
 name = "new-sg"
 description = "Allow SSH and backend access"
 vpc_id = data.aws_vpc.default.id

 ingress{
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
 }

 egress{
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
 }
}


resource "aws_instance" "ubuntu_server" {
  iam_instance_profile = aws_iam_instance_profile.ec2_instance_profile.name
  ami = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t2.micro"
  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.new_sg.id]

  tags = {
    Name = "Ubuntu EC2 with S3 Access"
  }
}

resource "aws_security_group" "mysql_ec2_sg" {
  name = "mysql-ec2-sg"
  description = "Accept traffic only from EC2 SG"
  vpc_id = data.aws_vpc.default.id

  ingress{
    from_port = 3306
    to_port = 3306
    protocol = "tcp"
    security_groups = [aws_security_group.new_sg.id]
  }

  egress{
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "default" {
  name = "default-db-subnet"
  subnet_ids = slice(data.aws_subnets.default.ids,0,2)

  tags = {
    Name = "My RDS Subnet Group"
  }
}


resource "aws_db_instance" "mysql" {
  allocated_storage = 20
  engine = "mysql"
  engine_version = "8.0"
  instance_class = "db.t3.micro"
  username = var.User_Name.value
  password = var.password.value
  db_subnet_group_name = aws_db_subnet_group.default.name
  vpc_security_group_ids = [aws_security_group.mysql_ec2_sg.id]
  skip_final_snapshot = true
  publicly_accessible = false
  deletion_protection = false 
  multi_az = false 
}

data "aws_ami" "ubuntu"{
most_recent = true 
owners = ["099720109477"]

filter {
  name = "name"
  values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
}
}

resource "aws_instance" "node_backend" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  subnet_id = data.aws_subnets.default.ids[0]
  vpc_security_group_ids = [aws_security_group.mysql_ec2_sg.id]
  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y nodejs npm mysql-client
              npm install -g pm2
              EOF

  tags = {
    Name = "ansarbro-backend"
  }
}


resource "aws_acm_certificate" "cert" {
  domain_name       = "ansarbro.com"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

data "aws_route53_zone" "main" {
  name = "ansarbro.com"
private_zone = false
}

resource "aws_route53_record" "root_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = "ansarbro.com"
  type = "A"

  alias {
    name = aws_cloudfront_distribution.cloudfront.domain_name
    zone_id = aws_cloudfront_distribution.cloudfront.hosted_zone_id
    evaluate_target_health = false
  }
}

resource "aws_route53_record" "www_record" {
  zone_id = data.aws_route53_zone.main.zone_id
  name = "www.ansarbro.com"
  type = "A"
 alias {
   name = "www.ansarbro.com.s3-website-us-east-1.amazonaws.com"
   zone_id = "Z3AQBSTGFYJSTF"
   evaluate_target_health = false
 }
}

locals {
  cert_validation = tolist(aws_acm_certificate.cert.domain_validation_options)[0]
}

resource "aws_route53_record" "cert_validation" {
name = local.cert_validation.resource_record_name
type = local.cert_validation.resource_record_type
zone_id = data.aws_route53_zone.main.zone_id
records = [local.cert_validation.resource_record_value]
ttl = 60

}

resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn = aws_acm_certificate.cert.arn
  validation_record_fqdns = [aws_route53_record.cert_validation.fqdn]  
}

resource "aws_cloudfront_distribution" "cloudfront" {
  enabled = true
  is_ipv6_enabled = true
  default_root_object = "index.html"

  origin {
    domain_name = "ansarbro.com.s3-website-us-east-1.amazonaws.com"
    origin_id = "s3Origin"

    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods = ["GET","HEAD"]
    cached_methods = ["GET","HEAD"]
    target_origin_id = "s3Origin"
    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }
  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate_validation.cert_validation.certificate_arn
    ssl_support_method = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  aliases = ["ansarbro.com"]
}

# resource "aws_route53_record" "root_redirect_bucket" {
#   zone_id = data.aws_route53_zone.main.zone_id
#   name = "ansarbro.com"
#   type = "A"
#   alias {
#     name = aws_cloudfront_distribution.cloudfront.domain_name
#     zone_id = aws_cloudfront_distribution.cloudfront.hosted_zone_id
#    evaluate_target_health = false
   
#   }
# }

output "rds_endpoint" {
  value = aws_db_instance.mysql.endpoint
}

output "ec2_public_ip" {
  value = aws_instance.node_backend.public_ip
}

output "cloudfront_url" {
  value = aws_cloudfront_distribution.cloudfront.domain_name
}

output "cloudfront_domain" {
  value = aws_cloudfront_distribution.cloudfront.domain_name
}


