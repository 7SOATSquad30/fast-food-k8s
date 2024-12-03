provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket = "aws-fastfood-fiap-terraform-tfstate"
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

# default roles for aws academy
data "aws_iam_role" "eks_cluster_role" {
  name = "LabRole"
}
data "aws_iam_role" "eks_node_group_role" {
  name = "LabRole"
}
#

# resource "aws_iam_role" "eks_cluster_role" {
#   name = "eks-cluster-role"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "eks.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
#   role       = aws_iam_role.eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_policy" {
#   role       = aws_iam_role.eks_cluster_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
# }

# resource "aws_iam_role" "eks_node_group_role" {
#   name = "eks-node-group-role"
  
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [
#       {
#         Effect = "Allow",
#         Principal = {
#           Service = "ec2.amazonaws.com"
#         },
#         Action = "sts:AssumeRole"
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
#   role       = aws_iam_role.eks_node_group_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
# }

# resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
#   role       = aws_iam_role.eks_node_group_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
# }

# resource "aws_iam_role_policy_attachment" "eks_ec2_container_registry_readonly_policy" {
#   role       = aws_iam_role.eks_node_group_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
# }

resource "aws_eks_cluster" "eks_cluster" {
  name     = "basic-eks-cluster"
  role_arn = data.aws_iam_role.eks_cluster_role.arn
  version  = "1.25"

  vpc_config {
    subnet_ids = [data.aws_ssm_parameter.subnet_1.value, data.aws_ssm_parameter.subnet_2.value, data.aws_ssm_parameter.subnet_3.value]
  }
}

resource "aws_eks_node_group" "eks_node_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "eks-node-group"
  node_role_arn   = data.aws_iam_role.eks_node_group_role.arn
  subnet_ids      = [data.aws_ssm_parameter.subnet_1.value, data.aws_ssm_parameter.subnet_2.value, data.aws_ssm_parameter.subnet_3.value]

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  update_config {
    max_unavailable_percentage = 50
  }

  instance_types = ["t2.micro"]
  capacity_type = "SPOT"

  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}
