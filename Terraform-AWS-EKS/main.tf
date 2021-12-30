provider "aws" {
    region = "us-east-1"
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}


data "aws_availability_zones" "azs" {
    state = "available"
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}


provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}
module "eks"{
    source = "terraform-aws-modules/eks/aws"
    version = "17.1.0"
    cluster_name = local.cluster_name
    cluster_version = "1.21"
    subnets = module.vpc.private_subnets

    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = true

    tags = {
        Name = "Demo-EKS-Cluster"
    }

    vpc_id = module.vpc.vpc_id
    workers_group_defaults = {
        root_volume_type = "gp2"
    }

    worker_groups = [
        {
            name = "Worker-Group-1"
            instance_type = "t3.micro"
            asg_desired_capacity = 2
            additional_security_group_ids = [aws_security_group.worker_group_mgmt_one.id,aws_security_group.worker_group_mgmt_two.id]
        },
        {
            name = "Worker-Group-2"
            instance_type = "t3.micro"
            asg_desired_capacity = 1
            additional_security_group_ids = [aws_security_group.worker_group_mgmt_two.id,aws_security_group.worker_group_mgmt_one.id]
        },
    ]
}

#data "aws_eks_cluster" "cluster" {
#    name = module.eks.cluster_id
#}

#data "aws_eks_cluster_auth" "cluster" {
#    name = module.eks.cluster_id
#}
resource "aws_security_group" "allow_all" {
  name        = "allow_web"
  description = "Allow WEB inbound traffic"
  vpc_id      = module.vpc.vpc_id

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
      description      = "HTTPS from VPC"
      from_port        = 0
      to_port          = 0
      protocol         = "ICMP"
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

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 email@example.com"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_subnet" "foo" {
  vpc_id            = module.vpc.vpc_id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.8.0/24"
}

resource "aws_instance" "bastion" {
  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 40
  }
  ami = data.aws_ami.ubuntu.id
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.allow_all.id,aws_security_group.worker_group_mgmt_two.id,aws_security_group.worker_group_mgmt_one.id]
  key_name = "deployer-key"
  associate_public_ip_address = true
  subnet_id = module.vpc.public_subnets[0]


  tags = {
    Name = "bastion"
         }
}


