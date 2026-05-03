
resource "aws_security_group" "vpce_ssm_sg" {
  name        = "remed-dev-vpce-ssm-sg" # match the existing SG's group name
  description = "Allow HTTPS from bastion to SSM interface endpoints"
  vpc_id      = module.networking.vpc_id

  # allow HTTPS from bastion SG
  ingress {
    description     = "HTTPS from bastion"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id] # sg-09666c36a48533433 in your plan
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    prevent_destroy = true # keep it; we’re preventing accidental deletes
  }

  tags = {
    Name = "remed-dev-vpce-ssm-sg"
  }
}

