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
  count = 2     # Here we are creating identical 4 machines.
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 20
  }
  ami = var.ami
  availability_zone = "ap-south-1a"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install docker.io ansible -y
                sudo apt install unzip zip -y
                sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
                systemctl restart sshd
                service sshd restart
                sudo adduser ubuntu --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password 
                echo "ubuntu:Govtech@4488" | sudo chpasswd
                sudo docker rm -f sonarqube &&  sudo docker run -d --name sonarqube -p 9000:9000 sonarqube
                EOF


  tags = {
    Name = "build-${count.index}"
         }
}

resource "aws_instance" "deploy" {
  count = 2     # Here we are creating identical 4 machines.
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 20
  }
  ami = var.ami
  availability_zone = "ap-south-1a"
  instance_type = var.instance_type
  vpc_security_group_ids = [aws_security_group.allow_all.id]
  user_data = <<-EOF
                #!/bin/bash
                sudo apt update
                sudo apt install docker.io ansible -y
                sudo apt install unzip zip -y
                sed 's/PasswordAuthentication no/PasswordAuthentication yes/' -i /etc/ssh/sshd_config
                systemctl restart sshd
                service sshd restart
                sudo adduser ubuntu --gecos "First Last,RoomNumber,WorkPhone,HomePhone" --disabled-password 
                echo "ubuntu:Govtech@4488" | sudo chpasswd
                sudo docker rm -f sonarqube &&  sudo docker run -d --name sonarqube -p 9000:9000 sonarqube
                EOF


  tags = {
    Name = "deploy-${count.index}"
         }
}

