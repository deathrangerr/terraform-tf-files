provider "aws" {
  region     = "ap-south-1"
  access_key = "AKIAQCUJGX5BFFOXN545"
  secret_key = "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"
}

variable "s3_bucket_names" {
  type = list
  default = ["dev-bucket.app87377438383", "uat-bucket.app78324723789487923", "prod-bucket.app8794289734873298479"]
}


resource "aws_s3_bucket" "deekshus_bucket" {
  count         = "${length(var.s3_bucket_names)}" //count will be 3
  bucket        = "${element(var.s3_bucket_names, count.index)}"
  acl           = "public-read-write"
  force_destroy = true
  tags = {
    Environment = "Dev-Env"
  }
   versioning {
    enabled = true
  }
  lifecycle_rule {
    enabled = true
    prefix = "*"

    transition {
      days          = 2
      storage_class = "GLACIER"
    }
  }
}
