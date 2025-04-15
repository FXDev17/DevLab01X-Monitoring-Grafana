##################################################################################################################
# 00X_monitoring_pipeline Variables
##################################################################################################################

variable "key_pair_name" {
  description = "Pipeline KeyPair Name"
  type        = string
  default     = "00X_monitoring_pipeline"
}

variable "ssh_public_key" {
  description = "Pipeline KeyPair Key"
  type        = string
  default = file("~/.ssh/jenkins_dev_pipeline_keys.pub")
}

variable "ami_id" {
  description = "Pipeline AMI ID"
  type        = string
  default     = "ami-0e56583ebfdfc098f"
}

variable "monitoring" {
  description = "High Resolution Monitoring"
  type        = bool
  default     = false
}

variable "instance_type" {
  description = "Pipeline Instance Type"
  type        = string
  default     = "t2.large"
}

variable "iam_instance_profile_name" {
  description = "IAM instance profile name"
  type        = string
  default     = "DevLab01X_Monitoring_Instance_Profile"
}

variable "ebs_optimized" {
  description = "Ensures that the Instance has Dedicated Bandwidth "
  type        = bool
  default     = true
}

variable "jenkins_user_data_path" {
  description = "Path to the Jenkins pipeline bootstrap script"
  type        = string
  default     = "/Users/fx/WorkSpace/DevLab01X-Monitoring-Grafana/env/dev/infra/EC2/scripts/jenkins-pipeline.bootstrap.sh"
}


variable "security_groups_ingress" {
  description = "Pipeline SG Ingress"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string


  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "SSH access"
    },
    {
      from_port   = 8080
      to_port     = 8080
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP access" 
    }
  ]
}

variable "security_groups_egress" {
  description = "Pipeline SG Egress"
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      description = "All All outbound traffic"
    }
  ]
}

variable "http_endpoint" {
  description = "Enable or disable the Instance Metadata Service"
  type        = string
  default     = "enabled"
}

variable "http_tokens" {
  description = "Enforce IMDSv2 (blocks v1)"
  type        = string
  default     = "required"
}

variable "root_block_device_encryption" {
  description = "Encrypts EBS"
  type        = bool
  default     = true
}


variable "tags" {
  description = "Tag For The Jenkins Instance"
  type        = map(string)
  default = {
    "name"        = "00x_monitoring_pipeline"
    "environment" = "Dev"
    "ManagedBy"   = "jenkins"
  }
}

variable "vpc_id" {
  description = "ID of the VPC for EC2 resources"
  type        = string
}

