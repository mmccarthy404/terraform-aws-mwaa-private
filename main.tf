terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

data "aws_caller_identity" "current" {}

provider "aws" {
  region = var.region
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_subnets" "all" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}

data "aws_subnets" "selected" {
  filter {
    name   = "subnet-id"
    values = slice(data.aws_subnets.all.ids, 0, 2)
  }
}

data "aws_route_table" "selected" {
  subnet_id = data.aws_subnets.selected.ids[0]
}