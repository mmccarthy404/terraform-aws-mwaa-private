resource "aws_s3_bucket" "mwaa_s3" {
  bucket        = var.s3_name
  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "mwaa_s3_public_access_block" {
  bucket                  = aws_s3_bucket.mwaa_s3.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "mwaa_s3_versioning" {
  bucket = aws_s3_bucket.mwaa_s3.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_object" "requirements" {
  bucket  = aws_s3_bucket.mwaa_s3.id
  key     = var.s3_requirements_path
  content = "-r /usr/local/airflow/dags/codeartifact.txt"
}