resource "aws_iam_policy" "ca_sts_policy" {
  name = "mwaa-ca-sts-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "sts",
        "Effect" : "Allow",
        "Action" : "sts:GetServiceBearerToken",
        "Resource" : "*",
        "Condition" : {
          "StringEquals" : { "sts:AWSServiceName" : "codeartifact.amazonaws.com" }
        }
      }
    ]
  })
}

resource "aws_iam_policy" "ca_token_policy" {
  name = "mwaa-ca-token-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "codeartifact:GetAuthorizationToken",
          "codeartifact:ReadFromRepository",
          "codeartifact:GetRepositoryEndpoint"
        ]
        "Resource" : "*"
      }
    ]
  })
}

resource "aws_iam_policy" "ca_s3_read_write_policy" {
  name = "mwaa-ca-read-write-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "ListObjectsInBucket",
        "Effect" : "Allow",
        "Action" : ["s3:ListBucket"],
        "Resource" : ["arn:aws:s3:::${aws_s3_bucket.mwaa_s3.id}"]
      },
      {
        "Sid" : "AllObjectActions",
        "Effect" : "Allow",
        "Action" : "s3:*Object",
        "Resource" : ["arn:aws:s3:::${aws_s3_bucket.mwaa_s3.id}/*"]
      }
    ]
  })
}

resource "aws_iam_role" "mwaa_update_ca_index_url_role" {
  name = "MWAA-UpdateCodeArtifactIndexURLRole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : [
          "sts:AssumeRole"
        ],
        "Principal" : {
          "Service" : [
            "lambda.amazonaws.com"
          ]
        }
      }
    ]
  })

  managed_policy_arns = [
    aws_iam_policy.ca_sts_policy.arn,
    aws_iam_policy.ca_token_policy.arn,
    aws_iam_policy.ca_s3_read_write_policy.arn
  ]
}

resource "aws_lambda_function" "mwaa_update_ca_index_url" {
  filename      = "lambda_function.zip"
  function_name = "MWAA-UpdateCodeArtifactIndexURL"
  role          = aws_iam_role.mwaa_update_ca_index_url_role.arn
  handler       = "lambda_function.lambda_handler"
  timeout       = 300
  runtime       = "python3.7"

  source_code_hash = filebase64sha256("lambda_function.zip")

  environment {
    variables = {
      CA_DOMAIN          = aws_codeartifact_domain.mwaa_ca_domain.domain
      CA_DOMAIN_OWNER    = aws_codeartifact_domain.mwaa_ca_domain.owner
      CA_REPOSITORY_NAME = aws_codeartifact_repository.mwaa_ca_repo.id
      BUCKET_NAME        = aws_s3_bucket.mwaa_s3.id
    }
  }
}

resource "aws_cloudwatch_event_rule" "mwaa_update_ca_index_url_rule" {
  name        = "mwaa-update-ca-index-url-rule"
  description = "Update the CodeArtifact URL present in MWAA's dags/cloudartifact.txt file"

  schedule_expression = "rate(10 hours)"
}

resource "aws_cloudwatch_event_target" "mwaa_update_ca_index_url_target" {
  rule      = aws_cloudwatch_event_rule.mwaa_update_ca_index_url_rule.name
  target_id = "UpdateCodeArtifactIndexURL"
  arn       = aws_lambda_function.mwaa_update_ca_index_url.arn
}

data "aws_lambda_invocation" "mwaa_update_ca_index_url_invoke" {
  function_name = aws_lambda_function.mwaa_update_ca_index_url.id
  input = ""

  depends_on = [
    aws_codeartifact_repository.mwaa_ca_repo,
    aws_s3_bucket_public_access_block.mwaa_s3_public_access_block,
    aws_s3_bucket_versioning.mwaa_s3_versioning
  ]
}