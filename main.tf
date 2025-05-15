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

# Attach Policy to User

resource "aws_iam_user_policy_attachment" "attach_policy" {
  user = aws_iam_user.iam_name.name
  policy_arn = aws_iam_policy.s3_read_policy.arn
}



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

# Optional: Instance Profile (to use with EC2)
resource "aws_iam_instance_profile" "ec2_instance_profile" {
    name = "ec2_s3_profile"
    role = aws_iam_role.ec2_s3_role.name
  
}


resource "aws_instance" "ubuntu_server" {
  ami = data.aws_ssm_parameter.ubuntu_ami.value
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_ssh.id]
}


resource "aws_security_group" "allow_ssh" {
 
}





