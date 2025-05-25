variable "vpc_id" {
  type        = string
  description = "VPC ID to launch EKS cluster in"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "eks_cluster_role_name" {
  type        = string
  description = "IAM Role name for EKS control plane"
}

variable "eks_node_role_name" {
  type        = string
  description = "IAM Role name for worker nodes"
}

variable "ebs_csi_policy_arn" {
  description = "Amazon EBS CSI Driver Policy ARN"
  type        = string
}
