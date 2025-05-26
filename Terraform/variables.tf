variable "region" {
  description = "AWS region"
  type        = string
  default     = "ap-northeast-2"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "List of Availability Zones"
}

variable "ssh_port" {
  type        = number
  description = "Port to allow SSH access"
}

variable "redis_port" {
  type        = number
  description = "Port to allow Redis access"
}

variable "https_port" {
  type        = number
  description = "Port to allow HTTPS access"
}

variable "private_cidr_block" {
  type        = string
  description = "CIDR block for private subnet internal traffic"
}

variable "http_port" {
  type        = number
  description = "HTTP port"
}

variable "app_port" {
  type        = number
  description = "App port (8000)"
}

variable "monitoring_port" {
  type        = number
  description = "Monitoring port (9001)"
}

variable "app_access_cidr" {
  type        = string
  description = "CIDR allowed to access app"
}

variable "jenkins_irsa_role_name" {
  description = "IAM role name for Jenkins IRSA"
  type        = string
}

variable "jenkins_namespace" {
  description = "Kubernetes namespace for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "jenkins_service_account_name" {
  description = "ServiceAccount name for Jenkins"
  type        = string
  default     = "jenkins"
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
}
