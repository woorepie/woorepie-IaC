output "bucket_name" {
  value = aws_s3_bucket.static.bucket
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.this.domain_name
}
