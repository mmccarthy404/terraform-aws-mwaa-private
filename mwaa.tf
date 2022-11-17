resource "aws_iam_policy" "mwaa_policy" {
  name = "mwaa-policy"
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "airflow:PublishMetrics",
        "Resource" : "arn:aws:airflow:${var.region}:${data.aws_caller_identity.current.account_id}:environment/${var.environment_name}"
      },
      {
        "Effect" : "Deny",
        "Action" : "s3:ListAllMyBuckets",
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.mwaa_s3.id}",
          "arn:aws:s3:::${aws_s3_bucket.mwaa_s3.id}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "s3:GetObject*",
          "s3:GetBucket*",
          "s3:List*"
        ]
        "Resource" : [
          "arn:aws:s3:::${aws_s3_bucket.mwaa_s3.id}",
          "arn:aws:s3:::${aws_s3_bucket.mwaa_s3.id}/*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:CreateLogStream",
          "logs:CreateLogGroup",
          "logs:PutLogEvents",
          "logs:GetLogEvents",
          "logs:GetLogRecord",
          "logs:GetLogGroupFields",
          "logs:GetQueryResults"
        ],
        "Resource" : [
          "arn:aws:logs:${var.region}:${data.aws_caller_identity.current.account_id}:log-group:airflow-${var.environment_name}-*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "logs:DescribeLogGroups"
        ],
        "Resource" : [
          "*"
        ]
      },
      {
        "Effect" : "Allow",
        "Action" : "cloudwatch:PutMetricData",
        "Resource" : "*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "sqs:ChangeMessageVisibility",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl",
          "sqs:ReceiveMessage",
          "sqs:SendMessage"
        ],
        "Resource" : "arn:aws:sqs:${var.region}:*:airflow-celery-*"
      },
      {
        "Effect" : "Allow",
        "Action" : [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey*",
          "kms:Encrypt"
        ],
        "NotResource" : "arn:aws:kms:*:${data.aws_caller_identity.current.account_id}:key/*",
        "Condition" : {
          "StringLike" : {
            "kms:ViaService" : [
              "sqs.${var.region}.amazonaws.com"
            ]
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "mwaa_role" {
  name = "MWAARole"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : [
            "airflow.amazonaws.com",
            "airflow-env.amazonaws.com"
          ]
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
  managed_policy_arns = [aws_iam_policy.mwaa_policy.arn]
}

resource "aws_mwaa_environment" "mwaa_env" {
  name                          = var.environment_name
  environment_class             = var.environment_class
  airflow_version               = var.airflow_version
  execution_role_arn            = aws_iam_role.mwaa_role.arn
  source_bucket_arn             = aws_s3_bucket.mwaa_s3.arn
  dag_s3_path                   = var.s3_dags_path
  requirements_s3_path          = var.s3_requirements_path
  webserver_access_mode         = "PUBLIC_ONLY"
  airflow_configuration_options = var.airflow_configuration_options
  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = data.aws_subnets.selected.ids
  }
  logging_configuration {
    scheduler_logs {
      enabled   = true
      log_level = "INFO"
    }
    webserver_logs {
      enabled   = true
      log_level = "INFO"
    }
    dag_processing_logs {
      enabled   = true
      log_level = "INFO"
    }
  }

  depends_on = [
    aws_s3_bucket_public_access_block.mwaa_s3_public_access_block,
    aws_s3_bucket_versioning.mwaa_s3_versioning
  ]
}