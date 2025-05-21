module "network" {
  source = "./modules/network"

  vpc_cidr           = var.vpc_cidr
  azs                = var.azs
  ssh_port           = var.ssh_port
  redis_port         = var.redis_port
  https_port         = var.https_port
  private_cidr_block = var.private_cidr_block
  http_port          = var.http_port
  app_port           = var.app_port
  monitoring_port    = var.monitoring_port
}

data "aws_iam_role" "eks_cluster_role" {
  name = "EKSClusterRole"
}

data "aws_iam_role" "eks_node_role" {
  name = "EKSNodeRole"
}

module "eks" {
  source = "./modules/eks"

  vpc_id             = module.network.vpc_id
  private_subnet_ids = module.network.private_subnet_ids

  eks_cluster_role_name = data.aws_iam_role.eks_cluster_role.name
  eks_node_role_name    = data.aws_iam_role.eks_node_role.name
}
