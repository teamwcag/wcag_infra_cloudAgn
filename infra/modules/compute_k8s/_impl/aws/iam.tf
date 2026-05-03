# IAM role assumed by the EKS control plane
resource "aws_iam_role" "cluster" {
  name = "${var.name_prefix}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
  tags = { Name = "${var.name_prefix}-eks-cluster-role" }
}

# Required AWS-managed policies for the EKS control plane
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSVPCResourceController" {
  role       = aws_iam_role.cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}

data "aws_iam_policy_document" "doc_service_s3" {
  statement {
    sid = "DocsBucketObjects"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]

    resources = [
      "${var.docs_bucket_arn}/*"
    ]
  }


  statement {
    sid = "DocsBucketList"
    actions = [
      "s3:ListBucket"
    ]

    resources = [
      var.docs_bucket_arn
    ]
  }
}

# Trust policy for IRSA: allow the EKS OIDC provider to assume this role
data "aws_iam_policy_document" "eks_irsa_assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [module.eks.oidc_provider_arn]
    }

    # Adjust the namespace/service account to match the one you'll use
    condition {
      test     = "StringEquals"
      variable = "${replace(module.eks.cluster_oidc_issuer_url, "https://", "")}:sub"
      values = [
        "system:serviceaccount:wcag-docs:doc-service", # namespace: wcag-docs, sa: doc-service
      ]
    }
  }
}



resource "aws_iam_policy" "doc_service_s3" {
  name   = "${var.name_prefix}-doc-service-s3"
  policy = data.aws_iam_policy_document.doc_service_s3.json

}

resource "aws_iam_role" "doc_service" {
  name = "${var.name_prefix}-doc-service"

  assume_role_policy = data.aws_iam_policy_document.eks_irsa_assume_role.json
}

resource "aws_iam_role_policy_attachment" "doc_service_s3" {
  role       = aws_iam_role.doc_service.name
  policy_arn = aws_iam_policy.doc_service_s3.arn
}
