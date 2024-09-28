resource "aws_ssm_parameter" "cluster_endpoint" {
  name  = "/eks/cluster_endpoint"
  type  = "String"
  value = aws_eks_cluster.eks_cluster.endpoint
}

resource "aws_ssm_parameter" "cluster_security_group_id" {
  name  = "/eks/cluster_security_group_id"
  type  = "String"
  value = aws_eks_cluster.eks_cluster.vpc_config[0].cluster_security_group_id
}

resource "aws_ssm_parameter" "cluster_node_group_arn" {
  name  = "/eks/cluster_node_group_arn"
  type  = "String"
  value = aws_eks_node_group.eks_node_group.arn
}