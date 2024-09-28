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

resource "aws_iam_role" "eks_cluster_role" {
  name = "eks-cluster-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

resource "aws_iam_role" "eks_node_group_role" {
  name = "eks-node-group-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_ec2_container_registry_readonly_policy" {
  role       = aws_iam_role.eks_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = "basic-eks-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.25"

  vpc_config {
    subnet_ids = [data.aws_ssm_parameter.subnet_1.value, data.aws_ssm_parameter.subnet_2.value, data.aws_ssm_parameter.subnet_3.value]
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = aws_iam_role.eks_node_group_role.arn
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
