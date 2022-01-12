resource "aws_security_group" "allow_all" {
  name        = "allow_web"
  description = "Allow WEB inbound traffic"

  ingress = [
    {
      description      = "HTTPS from VPC"
      from_port        = 443
      to_port          = 443
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false

    },
    {
      description      = "HTTP from VPC"
      from_port        = 80
      to_port          = 80
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    },
    {
      description      = "SSH from VPC"
      from_port        = 22
      to_port          = 22
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["0.0.0.0/0"]
      prefix_list_ids  = []
      security_groups  = []
      self             = false
      
    }
  ]

  egress = [
    {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      description      = "bullhit"
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      security_groups  = []
      self             = false
    }
  ]

  tags = {
    Name = "allow_all"
  }
}


resource "aws_instance" "build" {
  count = 10     # Here we are creating identical 9 machines.
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 40
  }
  ami = var.ami
  availability_zone = "ap-southeast-1a"
  instance_type = var.instance_type[0]
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install docker.io ansible maven tree openjdk-8-jdk -y
                sudo apt install unzip zip -y
                sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
                systemctl restart sshd
                service sshd restart
                sudo adduser ubuntu --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password 
                echo "ubuntu:Govtech@4488" | sudo chpasswd
                sudo docker run -d --name sonarqube -p 9000:9000 sonarqube:8.9.1-community
                sudo docker start sonarqube
                EOF


  tags = {
    Name = "build-${count.index}"
         }
}

resource "aws_instance" "deploy" {
  count = 10     # Here we are creating identical 9 machines.
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 10
  }
  ami = var.ami
  availability_zone = "ap-southeast-1a"
  instance_type = var.instance_type[1]
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update -y
                sudo apt install openjdk-8-jdk zip unzip maven tree -y
                sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
                systemctl restart sshd
                service sshd restart
                sudo adduser ubuntu --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password 
                echo "ubuntu:Govtech@4488" | sudo chpasswd
                EOF


  tags = {
    Name = "deploy-${count.index}"
         }
}


resource "aws_instance" "bamboo-ci" {
  count = 1     # Here we are creating identical 1 machines.
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 100
    volume_type = "standard"
  }
  ami = var.ami
  availability_zone = "ap-southeast-1a"
  instance_type = var.instance_type[2]
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install docker.io ansible -y
                sudo apt install unzip zip -y
                sudo apt update
                sudo apt install openjdk-8-jdk vim wget docker.io zip unzip python maven tree -y
                sudo sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
                sudo systemctl restart sshd
                sudo service sshd restart
                sudo adduser ubuntu --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password 
                echo "ubuntu:Govtech@4488" | sudo chpasswd
                sudo docker volume create --name nexus-data 
                sudo docker run -d -p 8081:8081 --name nexus -v nexus-data:/nexus-data sonatype/nexus3
                sudo docker start nexus
                EOF


  tags = {
    Name = "bamboo-ci"
         }
}

