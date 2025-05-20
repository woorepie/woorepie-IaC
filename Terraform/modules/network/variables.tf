variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "ssh_port" {
  type    = number
}

variable "redis_port" {
  type    = number
}

variable "https_port" {
  type    = number
}

variable "private_cidr_block" {
  type    = string
}
