# --- IAM role for the SSM-managed bastion ---

data "aws_iam_policy_document" "bastion_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "bastion_role" {
  name               = "${var.name_prefix}-eks-bastion-role"
  assume_role_policy = data.aws_iam_policy_document.bastion_assume_role.json
}

# SSM core permissions for Session Manager
resource "aws_iam_role_policy_attachment" "bastion_ssm_core" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Allow building kubeconfig (aws eks update-kubeconfig calls DescribeCluster)
data "aws_iam_policy_document" "bastion_eks_describe" {
  statement {
    actions   = ["eks:DescribeCluster"]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "bastion_eks_describe" {
  name   = "${var.name_prefix}-eks-describe"
  policy = data.aws_iam_policy_document.bastion_eks_describe.json
}
resource "aws_iam_role_policy_attachment" "bastion_eks_describe" {
  role       = aws_iam_role.bastion_role.name
  policy_arn = aws_iam_policy.bastion_eks_describe.arn
}

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${var.name_prefix}-eks-bastion-profile"
  role = aws_iam_role.bastion_role.name
}

# --- Security group (egress only) ---
resource "aws_security_group" "bastion_sg" {
  name        = "${var.name_prefix}-eks-bastion-sg"
  description = "SSM bastion egress only"
  vpc_id      = module.networking.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Outbound via NAT already in your VPC
  }

  tags = { Name = "${var.name_prefix}-eks-bastion-sg" }
}

# --- Private EC2 instance (no keypair needed) ---
data "aws_ami" "amazon_linux_2023" {
  most_recent = true
  owners      = ["137112412989"] # Amazon
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.amazon_linux_2023.id
  instance_type               = "t3.micro"
  subnet_id                   = module.networking.private_subnets[0]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.bastion_profile.name
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]

  # SSM agent is preinstalled on Amazon Linux 2/AL2023
  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${var.name_prefix}-eks-bastion" }
}

output "bastion_instance_id" {
  value = aws_instance.bastion.id
}

