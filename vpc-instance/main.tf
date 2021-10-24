provider "aws" {
    region = "us-east-1"
    access_key = ""
    secret_key = ""
}

resource "aws_vpc" "prod" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "production"
  }
}

resource "aws_internet_gateway" "prod-gw" {
  vpc_id = aws_vpc.prod.id

}

resource "aws_route_table" "prod-rt" {
  vpc_id = aws_vpc.prod.id

  route = [
    {
      cidr_block = "0.0.0.0/0",
      gateway_id = aws_internet_gateway.prod-gw.id
      egress_only_gateway_id: "",
      ipv6_cidr_block: "",
      instance_id: "",
      local_gateway_id: "",
      nat_gateway_id: "",
      network_interface_id: "",
      transit_gateway_id: "",
      vpc_peering_connection_id: "",
      vpc_endpoint_id: "",
      carrier_gateway_id = "",
      destination_prefix_list_id = ""
    }
#    {
#      ipv6_cidr_block        = "::/0"
#      gateway_id = aws_internet_gateway.prod-gw
#    }
  ]

  tags = {
    Name = "prod-web-rt"
  }
}

variable "subnet_prefix" {
  type        = list
  #default     = "10.0.66.0/24"  //if user doesnt enter any value for the variable
  description = "subnet cidr block"
}


resource "aws_subnet" "prod-subnet" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnet_prefix[0].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[0].name
  }
}

resource "aws_subnet" "dev-subnet" {
  vpc_id     = aws_vpc.prod.id
  cidr_block = var.subnet_prefix[1].cidr_block
  availability_zone = "us-east-1a"

  tags = {
    Name = var.subnet_prefix[1].name
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prod-subnet.id
  route_table_id = aws_route_table.prod-rt.id
}

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow WEB inbound traffic"
  vpc_id      = aws_vpc.prod.id

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
    Name = "allow_web"
  }
}
resource "aws_network_interface" "web" {
  subnet_id       = aws_subnet.prod-subnet.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.allow_web.id]

}

resource "aws_eip" "one-ip" {
  vpc = true
  network_interface = aws_network_interface.web.id
  depends_on  = [aws_internet_gateway.prod-gw]
}

output "server_public_eip" {
    value = aws_eip.one-ip.public_ip
}

resource "aws_instance" "web-server1" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a"
  key_name  = "virginia"

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo your very first web server > /var/www/html/index.html'
              EOF

  network_interface {
      device_index = 0
      network_interface_id = aws_network_interface.web.id
  }


  tags = {
    Name = "web-server"
  }
}

output web_server_key{
    value = aws_instance.web-server1.key_name
}

output web_server_id{
    value = aws_instance.web-server1.id
}

output web_server_region{
    value = aws_instance.web-server1.availability_zone
}

output web_server_public_ipS{
    value = aws_instance.web-server1.public_ip
}