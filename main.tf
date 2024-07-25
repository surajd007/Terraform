# Configure the AWS provider
provider "aws" {
        region = "us-east-1"
        access_key = "AKIA6ODU4FLMUHMV424D"
        secret_key = "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"
}

# Create a key pair for SSH access
resource "aws_key_pair" "my_keypair" {
  key_name   = "my-keypair"
  public_key = file("~/.ssh/id_ed25519.pub")  # Replace with your SSH public key path
}

# Create a security group allowing inbound SSH and HTTP traffic
resource "aws_security_group" "instance_sg" {
  name = "instance-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create an EC2 instance in the default VPC
resource "aws_instance" "example_instance" {
  ami                    = "ami-04a81a99f5ec58529"  # Replace with your desired AMI ID
  instance_type          = "t2.micro"
  key_name               = aws_key_pair.my_keypair.key_name
  #security_groups        = [aws_security_group.instance_sg.id]
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt-get update
              sudo apt-get install -y apache2
              TOKEN=$(curl -s --request PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
              echo "$(curl -s --header "X-aws-ec2-metadata-token: $TOKEN" http://169.254.169.254/latest/meta-data/public-ipv4)" > /tmp/ec2_public_ip.txt
              EOF

  tags = {
    Name = "example-instance"
  }
}

# Output the public IP address of the instance
output "instance_public_ip" {
  value = aws_instance.example_instance.public_ip
}
