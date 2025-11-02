#############################
# bastion_endpoints.tf
# Interface VPC Endpoints used by SSM so the bastion in private subnets
# can register/connect without public egress.
#############################

# SSM control-plane endpoint
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.private_subnets
  security_group_ids  = [aws_security_group.vpce_ssm_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-vpce-ssm"
  }
}

# EC2 messages channel for SSM agent
resource "aws_vpc_endpoint" "ec2messages" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.private_subnets
  security_group_ids  = [aws_security_group.vpce_ssm_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-vpce-ec2messages"
  }
}

# SSM messages channel for sessions/run-command
resource "aws_vpc_endpoint" "ssmmessages" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.private_subnets
  security_group_ids  = [aws_security_group.vpce_ssm_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-vpce-ssmmessages"
  }
}

# Optional: CloudWatch Logs if you want the agent to ship logs privately
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = module.networking.vpc_id
  service_name        = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = module.networking.private_subnets
  security_group_ids  = [aws_security_group.vpce_ssm_sg.id]
  private_dns_enabled = true

  tags = {
    Name = "${var.name_prefix}-vpce-logs"
  }
}

