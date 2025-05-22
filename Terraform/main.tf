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




data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}


resource "aws_iam_role" "alb_controller" {
  name = "alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}"
      },
      Action = "sts:AssumeRoleWithWebIdentity",
      Condition = {
        StringEquals = {
          "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}


data "aws_iam_policy" "alb_controller" {
  name = "AWSLoadBalancerControllerIAMPolicy"
}

# 정책 첨부
resource "aws_iam_role_policy_attachment" "attach_alb_policy" {
  role = aws_iam_role.alb_controller.name
  policy_arn = data.aws_iam_policy.alb_controller.arn
}

# Kubernetes Provider
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks.token
}

resource "null_resource" "wait_for_eks" {
  depends_on = [module.eks]
}

# ServiceAccount 연결
resource "kubernetes_service_account" "alb_controller_sa" {
  depends_on = [null_resource.wait_for_eks]

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller.arn
    }
  }
}

data "aws_iam_role" "jenkins_irsa_role" {
  name = var.jenkins_irsa_role_name
}

resource "kubernetes_service_account" "jenkins_sa" {
  metadata {
    name      = var.jenkins_service_account_name
    namespace = var.jenkins_namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = data.aws_iam_role.jenkins_irsa_role.arn
    }
  }
}

resource "aws_iam_role_policy_attachment" "jenkins_irsa_s3" {
  role       = data.aws_iam_role.jenkins_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}