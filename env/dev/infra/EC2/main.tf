# Creating KeyPair
resource "aws_key_pair" "opentelemetry_instance_keypair" {
  key_name   = var.ot_key_pair_name
  public_key = file("${path.module}/pipeline-pub-key/jenkins-dev-pipeline-keys.pub")
  }

# Creating Jenkins Pipeline
resource "aws_instance" "opentelemetry_instance" {
  # checkov:skip=CKV_AWS_126:Detailed monitoring NOT required for personal project
  # checkov:skip=CKV2_AWS_41:Using EC2 user credentials instead of IAM role (pipeline instance)
  ami                    = var.ot_ami_id
  instance_type          = var.ot_instance_type
  ebs_optimized          = var.ot_ebs_optimized
  key_name               = aws_key_pair.opentelemetry_instance_keypair.key_name
  vpc_security_group_ids = [aws_security_group.opentelemetry_instance_SG_In.id, aws_security_group.opentelemetry_instance_SG_Out.id] #
  monitoring             = var.ot_monitoring
  iam_instance_profile = aws_iam_instance_profile.opentelemetry_instance_profile.name
  tags                   = var.ot_tags
  user_data = <<-EOF
    #!/bin/bash
    # Install OpenTelemetry Collector
    curl -LO https://github.com/open-telemetry/opentelemetry-collector-releases/releases/download/v0.88.0/otelcol-contrib_0.88.0_linux_amd64.tar.gz
    tar -zxvf otelcol-contrib_0.88.0_linux_amd64.tar.gz
    mv otelcol-contrib /usr/local/bin/

    # Create otel-config.yaml
    cat <<EOT > /etc/otel-config.yaml
    receivers:
      awsxray:
        endpoint: 0.0.0.0:2000
    exporters:
      otlp:
        endpoint: tempo-us-central1.grafana.net:4317
        headers:
          Authorization: "Bearer ${var.api_key}"
        tls:
          insecure: false
    service:
      pipelines:
        traces:
          receivers: [awsxray]
          exporters: [otlp]
    EOT

    # Run OpenTelemetry Collector
    nohup /usr/local/bin/otelcol-contrib --config=/etc/otel-config.yaml &
  EOF


  root_block_device {
    encrypted = var.ot_root_block_device_encryption
  }

  metadata_options {
    http_endpoint = var.ot_http_endpoint
    http_tokens   = var.ot_http_tokens
  }

  security_groups = [ 
    aws_security_group.opentelemetry_instance_SG_In.name,
    aws_security_group.opentelemetry_instance_SG_Out.name
    
   ]
}

# Creating Security Groups
resource "aws_security_group" "opentelemetry_instance_SG_In" {
  name_prefix = "opentelemetry_instance_SG_In"
  description = "Ingress rules for OpenTelemetry"


  dynamic "ingress" {
    for_each = var.ot_security_groups_ingress

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
resource "aws_security_group" "opentelemetry_instance_SG_Out" {
  name_prefix = "opentelemetry_instance_SG_Out"
  description = "Ingress rules for OpenTelemetry"

  dynamic "egress" {
    for_each = var.ot_security_groups_egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
      description = egress.value.description
    }
  }
}
