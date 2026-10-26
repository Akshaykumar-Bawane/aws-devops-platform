# Latest Amazon Linux 2023 AMI, resolved by AWS so we never hardcode an ID
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# SSH only from the bastion, nothing from the internet
resource "aws_security_group" "fleet" {
  count       = var.enable ? 1 : 0
  name        = "${var.project_name}-${var.env}-fleet-sg"
  description = "Ansible fleet nodes, SSH from bastion only"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.bastion_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-${var.env}-fleet-sg" }
}

resource "aws_instance" "fleet" {
  count                  = var.enable ? var.node_count : 0
  ami                    = data.aws_ssm_parameter.al2023.value
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index % length(var.private_subnet_ids)]
  vpc_security_group_ids = [aws_security_group.fleet[0].id]
  key_name               = var.key_pair_name

  metadata_options {
    http_tokens = "required"
  }

  root_block_device {
    volume_size = 8
    encrypted   = true
  }

  tags = {
    Name = "${var.project_name}-${var.env}-fleet-${count.index + 1}"
    Role = "fleet"
  }
}