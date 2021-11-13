provider "aws" {
    region = "us-east-1"
    access_key = "AKIATZ6PZPLQUY7UGJPV"
    secret_key = "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"
}

resource "aws_directory_service_directory" "newad" {
  name     = "death.deathranger.com"
  password = "root@123"
  size     = "Small"

  vpc_settings {
    vpc_id     = aws_vpc.main.id
    subnet_ids = [aws_subnet.foo.id, aws_subnet.bar.id]
  }

  tags = {
    Project = "foo"
  }
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "foo" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1a"
  cidr_block        = "10.0.1.0/24"
}

resource "aws_subnet" "bar" {
  vpc_id            = aws_vpc.main.id
  availability_zone = "us-east-1b"
  cidr_block        = "10.0.2.0/24"
}