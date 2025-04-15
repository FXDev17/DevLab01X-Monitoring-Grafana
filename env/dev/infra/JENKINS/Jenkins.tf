# Creating KeyPair
resource "aws_key_pair" "monitoring_pipeline_KeyPair" {
  key_name   = var.key_pair_name
  public_key = var.ssh_public_key
  }

# Creating Jenkins Pipeline
resource "aws_instance" "monitoring_pipeline" {
  # checkov:skip=CKV_AWS_126:Detailed monitoring NOT required for personal project
  # checkov:skip=CKV2_AWS_41:Using EC2 user credentials instead of IAM role (pipeline instance)
  ami                    = var.ami_id
  instance_type          = var.instance_type
  ebs_optimized          = var.ebs_optimized
  key_name               = aws_key_pair.monitoring_pipeline_KeyPair.key_name
  vpc_security_group_ids = [aws_security_group.monitoring_pipeline_SG_In.id, aws_security_group.monitoring_pipeline_SG_Out.id]
  user_data              = var.jenkins_user_data_path
  monitoring             = var.monitoring
  tags                   = var.tags

  root_block_device {
    encrypted = var.root_block_device_encryption
  }

  metadata_options {
    http_endpoint = var.http_endpoint
    http_tokens   = var.http_tokens
  }

  security_groups = [ 
    aws_security_group.monitoring_pipeline_SG_In.name,
    aws_security_group.monitoring_pipeline_SG_Out.name
    
   ]
}

# Creating Security Groups
resource "aws_security_group" "monitoring_pipeline_SG_In" {
  name_prefix = "monitoring_pipeline_SG_In"
  description = "Ingress rules for Monitoring Pipeline"


  dynamic "ingress" {
    for_each = var.security_groups_ingress

    content {
      # checkov:skip=CKV_AWS_24:Dev Projects No Need To Restrict
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }
}

# Creating Security Groups
resource "aws_security_group" "monitoring_pipeline_SG_Out" {
  name_prefix = "monitoring_pipeline_SG_Out"
  description = "Egress rules for Monitoring Pipeline"

  dynamic "egress" {
    for_each = var.security_groups_egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
}
