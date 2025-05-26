module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.8.5"

  cluster_name    = "woorepie-eks"
  cluster_version = "1.32"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  enable_irsa                              = true
  cluster_endpoint_public_access           = true
  enable_cluster_creator_admin_permissions = true

  iam_role_name = var.eks_cluster_role_name

  cluster_addons = {
    vpc-cni = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    # ebs-csi = {
    #   addon_version     = "v1.43.0-eksbuild.1"
    #   resolve_conflicts = "OVERWRITE"
    # }
  }

  eks_managed_node_groups = {
    default = {
      desired_capacity = 1
      max_capacity     = 3
      min_capacity     = 1

      instance_types = ["m6i.xlarge"]
      iam_role_name  = var.eks_node_role_name

      subnet_ids = var.private_subnet_ids

      iam_role_additional_policies = {
        ebs_csi = var.ebs_csi_policy_arn
      }
    }
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}
