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
  cluster_name       = var.cluster_name
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
  ebs_csi_policy_arn    = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}



#################################################

data "aws_caller_identity" "current" {}

data "aws_eks_cluster" "eks" {
  name       = module.eks.cluster_name
  depends_on = [module.eks]
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

resource "aws_iam_role" "jenkins_irsa" {
  name = var.jenkins_irsa_role_name

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
          "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:${var.jenkins_namespace}:${var.jenkins_service_account_name}"
        }
      }
    }]
  })
}

resource "aws_iam_role" "ebs_csi_irsa" {
  name = "ebs-csi-irsa-role"

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
          "${replace(data.aws_eks_cluster.eks.identity[0].oidc[0].issuer, "https://", "")}:sub" = "system:serviceaccount:kube-system:ebs-csi-controller-sa"
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
  role       = aws_iam_role.alb_controller.name
  policy_arn = data.aws_iam_policy.alb_controller.arn
}

resource "aws_iam_role_policy_attachment" "jenkins_irsa_ecr_poweruser" {
  role       = data.aws_iam_role.jenkins_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

resource "aws_iam_role_policy_attachment" "jenkins_irsa_s3_full" {
  role       = data.aws_iam_role.jenkins_irsa_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ebs_policy" {
  role       = aws_iam_role.ebs_csi_irsa.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
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

resource "kubernetes_namespace" "jenkins" {
  metadata {
    name = var.jenkins_namespace
  }
}


# resource "aws_iam_role_policy_attachment" "jenkins_irsa_s3" {
#   role       = data.aws_iam_role.jenkins_irsa_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
# }



# ##############################################

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

# Cluster Autoscaler Helm 설치
resource "helm_release" "cluster_autoscaler" {
  name             = "cluster-autoscaler"
  namespace        = "kube-system"
  repository       = "https://kubernetes.github.io/autoscaler"
  chart            = "cluster-autoscaler"
  version          = "9.29.0"
  create_namespace = false

  set {
    name  = "autoDiscovery.clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.create"
    value = "true"
  }

  set {
    name  = "extraArgs.balance-similar-node-groups"
    value = "true"
  }

  set {
    name  = "extraArgs.skip-nodes-with-system-pods"
    value = "false"
  }

  set {
    name  = "extraArgs.skip-nodes-with-local-storage"
    value = "false"
  }

  set {
    name  = "nodeSelector.kubernetes\\.io/os"
    value = "linux"
  }

  set {
    name  = "tolerations[0].operator"
    value = "Exists"
  }

  depends_on = [module.eks]
}


# AWS Load Balancer Controller Helm 설치
resource "helm_release" "aws_load_balancer_controller" {
  name             = "aws-load-balancer-controller"
  namespace        = "kube-system"
  repository       = "https://aws.github.io/eks-charts"
  chart            = "aws-load-balancer-controller"
  version          = "1.7.1"
  create_namespace = false

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }

  set {
    name  = "region"
    value = var.region
  }

  set {
    name  = "vpcId"
    value = module.network.vpc_id
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = kubernetes_service_account.alb_controller_sa.metadata[0].name
  }

  depends_on = [kubernetes_service_account.alb_controller_sa]
}

