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