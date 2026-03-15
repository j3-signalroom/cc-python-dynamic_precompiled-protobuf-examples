terraform {
    cloud {
      organization = "signalroom"

        workspaces {
            name = "cc-python-dynamic-precompiled-protobuf-example"
        }
    }

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "6.36.0"
        }
    }
}

resource "aws_kms_key" "csfle_kek" {
  description             = var.kms_key_description
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccountFullAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowCSFLEOperations"
        Effect = "Allow"
        Principal = {
          AWS = data.aws_caller_identity.current.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey",
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Purpose = "confluent-csfle-kek"
    ManagedBy = "terraform"
  }
}

resource "aws_kms_alias" "csfle_kek" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.csfle_kek.key_id
}
