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

variable "bucket_name" {
  type        = string
  description = "S3 bucket name for static web hosting"
}

variable "team_user_arns" {
  type        = list(string)
  description = "IAM user ARNs who can access the S3 bucket"
}

variable "cloudfront_arn" {
  type        = string
  description = "CloudFront distribution ARN"
}

variable "cluster_id" {
  type = string
}

variable "node_type" {
  type = string
}

variable "num_cache_nodes" {
  type = number
}

variable "subnet_group_name" {
  type = string
}

