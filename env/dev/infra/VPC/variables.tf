# VPC Variables 

variable "enable_dns_support" {
  description = "When Enabled Instances can Use DNS Resolution to Communicate with each other"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "When Enabled you can access instances via AWS-provided DNS names"
  type        = bool
  default     = true
}

variable "vpc_tags" {
  description = "Tag For VPC"
  type        = map(string)
  default = {
    "name"        = "DevLab01X-Monitoring-VPC"
    "environment" = "Dev"
    "ManagedBy"   = "jenkins"
  }
}

variable "public_subnet_tags" {
  description = "Tag For Public Subent"
  type        = map(string)
  default = {
    "name"        = "Public Subnet"
    "environment" = "Dev"
    "ManagedBy"   = "jenkins"
  }
}

variable "private_subnet_tags" {
  description = "Tag For Private Subent"
  type        = map(string)
  default = {
    "name"        = "Private Subnet"
    "environment" = "Dev"
    "ManagedBy"   = "jenkins"
  }
}

# Internet Gateway Tags
variable "igw_tags" {
  description = "IGW for VPC Tags"
  type        = map(string)
  default = {
    "name"        = "IGW"
    "environment" = "Dev"
    "ManagedBy"   = "jenkins"
  }
}

# CIDR
variable "cidr_block" {
  description = "CIDR"
  type        = string
  default     = "10.0.0.0/16"
}

# Public Subnet Variables 
variable "cidr_block_public_subnet" {
  description = "Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Private Subnet Variables 
variable "cidr_block_private_subnet" {
  description = "Private Subnet CIDR Block"
  type        = string
  default     = "10.0.2.0/24"
}

# Public Routes Variables
variable "public_destination_cidr_block" {
  description = "Public Subnet CIDR Block"
  type        = string
  default     = "0.0.0.0/0" # Routes To IGW
}

# Private Routes Variables
variable "private_destination_cidr_block" {
  description = "Private Subnet CIDR Block"
  type        = string
  default     = "0.0.0.0/0" # Routes To NAT
}

# Lambda Security Group Egress
variable "lambda_security_groups_egress" {
  description = "Lambda SG Egress"
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

variable "lambda_SG_Out" {
  description = "value"
  type        = string
}