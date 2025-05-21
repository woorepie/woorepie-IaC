variable "bucket_name" {
  type = string
}

variable "team_user_arns" {
  type = list(string)
}

variable "cloudfront_arn" {
  type = string
}
