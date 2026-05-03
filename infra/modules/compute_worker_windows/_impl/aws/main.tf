terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

locals {
  worker_subnet_id = var.subnet_id != null ? var.subnet_id : var.private_subnet_ids[0]
}

# Windows Server 2022 base AMI
data "aws_ami" "windows_2022" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }
}

resource "aws_security_group" "worker" {
  name        = "${var.name_prefix}-worker-sg"
  description = "Windows worker security group"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.name_prefix}-worker-sg" }
}

# IAM role for SSM + S3 + Secrets
resource "aws_iam_role" "worker" {
  name = "${var.name_prefix}-worker-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "worker_ssm" {
  role       = aws_iam_role.worker.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# S3 access to documents bucket
resource "aws_iam_policy" "worker_docs_s3" {
  name = "${var.name_prefix}-worker-docs-s3"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DocsBucketObjects"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
        Resource = ["${var.docs_bucket_arn}/*"]
      },
      {
        Sid      = "DocsBucketList"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"],
        Resource = [var.docs_bucket_arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "worker_docs_s3" {
  role       = aws_iam_role.worker.name
  policy_arn = aws_iam_policy.worker_docs_s3.arn
}

# Optional secrets access
data "aws_iam_policy_document" "worker_secrets" {
  count = length(var.secrets_arns) > 0 ? 1 : 0

  statement {
    actions   = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    resources = var.secrets_arns
  }
}

resource "aws_iam_policy" "worker_secrets" {
  count  = length(var.secrets_arns) > 0 ? 1 : 0
  name   = "${var.name_prefix}-worker-secrets"
  policy = data.aws_iam_policy_document.worker_secrets[0].json
}

resource "aws_iam_role_policy_attachment" "worker_secrets" {
  count      = length(var.secrets_arns) > 0 ? 1 : 0
  role       = aws_iam_role.worker.name
  policy_arn = aws_iam_policy.worker_secrets[0].arn
}

resource "aws_iam_instance_profile" "worker" {
  name = "${var.name_prefix}-worker-profile"
  role = aws_iam_role.worker.name
}

resource "aws_instance" "worker" {
  ami                         = data.aws_ami.windows_2022.id
  instance_type               = var.instance_type
  subnet_id                   = local.worker_subnet_id
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.worker.name
  vpc_security_group_ids      = concat([aws_security_group.worker.id], var.additional_security_group_ids)

  user_data = var.user_data

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${var.name_prefix}-worker" }
}
