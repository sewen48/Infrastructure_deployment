# configured aws provider with proper credentials
provider "aws" {
  region    = "us-east-1"
  profile   = "ganiyy"
}


# create default vpc if one does not exit
resource "aws_default_vpc" "default_vpc" {

  tags    = {
    Name  = "default vpc"
  }
}


# use data source to get all avalablility zones in region
data "aws_availability_zones" "available_zones" {}


# create default subnet if one does not exit
resource "aws_default_subnet" "default_az1" {
  availability_zone = data.aws_availability_zones.available_zones.names[0]

  tags   = {
    Name = "default subnet"
  }
}


# create security group for the ec2 instance
resource "aws_security_group" "ec2_security_group" {
  name        = "ec2 security group"
  description = "allow access on ports 8080 and 22"
  vpc_id      = aws_default_vpc.default_vpc.id

  # allow access on port 8080
  ingress {
    description      = "http proxy access"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  # allow access on port 22
  ingress {
    description      = "ssh access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = -1
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags   = {
    Name = "jenkins server security group"
  }
}


# use data source to get a registered amazon linux 2 ami
data "aws_ami" "ubuntu" {

    most_recent = true

      filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
      }

      filter {
        name = "virtualization-type"
        values = ["hvm"]
      }

      owners = ["099720109477"]
}

# launch the ec2 instance
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id              = aws_default_subnet.default_az1.id
  vpc_security_group_ids = [aws_security_group.ec2_security_group.id]
  key_name               = "zeeKP"

  tags = {
    Name = "jenkins_server"
  }
}

resource "null_resource" "jenkins_install" {
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/Downloads/zeeKP.pem")
    host        = aws_instance.ec2_instance.public_ip
    timeout     = "5m"
  }
 
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y software-properties-common apt-transport-https wget",
      "sudo curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null",
      "sudo echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y openjdk-17-jre-headless",
      "sudo apt-get install -y jenkins",
      "sudo systemctl start jenkins",
      "sudo systemctl enable jenkins",
      "sudo apt-get install -y maven",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null",
      "sudo apt-get update",
      "sudo apt-get install -y terraform",
      "sleep 30",  # Wait for Jenkins to start
      "sudo cat /var/lib/jenkins/secrets/initialAdminPassword > /home/ubuntu/jenkins_password.txt",
      "sudo chown ubuntu:ubuntu /home/ubuntu/jenkins_password.txt",
      "sudo chmod 600 /home/ubuntu/jenkins_password.txt",
      "echo 'Jenkins installation completed. Password saved to /home/ubuntu/jenkins_password.txt'"
    ]
  }
 
  depends_on = [aws_instance.ec2_instance]
}

output "jenkins_password_location" {
  value = "/home/ubuntu/jenkins_password.txt"
}

output "jenkins_url" {
  value = "http://${aws_instance.ec2_instance.public_dns}:8080"
}

