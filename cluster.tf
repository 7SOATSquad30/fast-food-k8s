provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "aws-fastfood-terraform-tfstate"
    key    = "fast-food-eks/terraform.tfstate"
    region = "us-east-1"
  }
}

data "aws_ssm_parameter" "vpc_id" {
  name = "/rds/vpc"
}

data "aws_ssm_parameter" "subnet_1" {
  name = "/rds/subnet_1"
}

data "aws_ssm_parameter" "subnet_2" {
  name = "/rds/subnet_2"
}

data "aws_ssm_parameter" "subnet_3" {
  name = "/rds/subnet_3"
}

resource "aws_internet_gateway" "eks_igw" {
  vpc_id = data.aws_ssm_parameter.vpc_id.value
  tags = {
    Name = "eks-igw"
  }
}

resource "aws_route_table" "eks_public_rt" {
  vpc_id = data.aws_ssm_parameter.vpc_id.value

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_igw.id
  }

  tags = {
    Name = "eks-public-rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc_1" {
  subnet_id      = data.aws_ssm_parameter.subnet_1.value
  route_table_id = aws_route_table.eks_public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_2" {
  subnet_id      = data.aws_ssm_parameter.subnet_2.value
  route_table_id = aws_route_table.eks_public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_3" {
  subnet_id      = data.aws_ssm_parameter.subnet_3.value
  route_table_id = aws_route_table.eks_public_rt.id
}

locals {
  eks_cluster_role_arn = "arn:aws:iam::691714441051:role/AWSServiceRoleForAmazonEKS"
  eks_node_group_role_arn = "arn:aws:iam::691714441051:role/AWSServiceRoleForAmazonEKSNodegroup"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "basic-eks-cluster"
  role_arn = local.eks_cluster_role_arn
  version  = "1.25"

  vpc_config {
    subnet_ids = [data.aws_ssm_parameter.subnet_1.value, data.aws_ssm_parameter.subnet_2.value, data.aws_ssm_parameter.subnet_3.value]
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = local.eks_node_group_role_arn
  subnet_ids      = [data.aws_ssm_parameter.subnet_1.value, data.aws_ssm_parameter.subnet_2.value, data.aws_ssm_parameter.subnet_3.value]

  scaling_config {
    desired_size = 1
    max_size     = 1
    min_size     = 1
  }

  instance_types = ["t3.small"]

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}
