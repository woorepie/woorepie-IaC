# ✅ S3 버킷 생성
resource "aws_s3_bucket" "static" {
  bucket = var.bucket_name
}

# ✅ Object Ownership 설정 (ACL 충돌 방지용)
resource "aws_s3_bucket_ownership_controls" "static" {
  bucket = aws_s3_bucket.static.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# ✅ 퍼블릭 액세스 차단 설정 해제
resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# ✅ 퍼블릭 읽기 허용 버킷 정책 (depends_on 추가!)
resource "aws_s3_bucket_policy" "allow_public_access" {
  bucket = aws_s3_bucket.static.id

  depends_on = [
    aws_s3_bucket_public_access_block.static,
    aws_s3_bucket_ownership_controls.static
  ]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.static.arn}/*"
      }
    ]
  })
}

# ✅ CloudFront 배포
resource "aws_cloudfront_distribution" "this" {
  origin {
    domain_name = aws_s3_bucket.static.bucket_regional_domain_name
    origin_id   = "s3-origin"
  }

  enabled             = true
  default_root_object = "index.html"

  default_cache_behavior {
    target_origin_id       = "s3-origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
