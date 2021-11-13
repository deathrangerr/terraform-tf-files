provider "aws" {
  region = "us-east-2"
  access_key = "AKIATZ6PZPLQVNYI377A"
  secret_key = "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"
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_id
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  cluster_version = "1.21"
  cluster_name    = "my-cluster"
  vpc_id          = "vpc-28cd2e43"
  subnets         = ["subnet-6bce8f11", "subnet-4bcd6507", "subnet-69dcd701"]

  worker_groups = [
    {
      instance_type = "t2.micro"
      asg_max_size  = 1
    }
  ]
}
resource "kubernetes_namespace" "example" {
  metadata {
    name = "my-first-namespace"
  }
}