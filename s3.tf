# S3 bucket to be used as Seafile data store
resource "aws_s3_bucket" "datastore" {
  bucket = var.bucket_name
  acl    = "private"

  # Allow deletion of non-empty bucket
  force_destroy = true

  tags = {
    Name = local.project_name
  }

  # Activate encryption using SSE-S3
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

resource "aws_s3_bucket_public_access_block" "s3_access_block" {
  bucket = aws_s3_bucket.datastore.id

  # Block all public access to the bucket
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = true
  restrict_public_buckets = true
}

