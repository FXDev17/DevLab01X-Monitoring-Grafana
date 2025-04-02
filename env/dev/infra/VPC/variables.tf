# VPC Variables 

variable "cidr_block" {
  description = "VPC CIDR Block"
  type        = string
  default     = "10.0.0.0/16"
}

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

# Public Subnet Variables 
variable "cidr_block_public_subnet" {
  description = "Public Subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "public_availability_zone" {
  description = "Public Subnet AZ"
  type        = string
  default     = "eu-west-2"
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


# Private Subnet Variables 
variable "cidr_block_private_subnet" {
  description = "Private Subnet"
  type        = string
  default     = "10.0.2.0/24"
}

variable "private_availability_zone" {
  description = "Private Subnet AZ"
  type        = string
  default     = "eu-west-2"
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

# Routes Variables
variable "public_destination_cidr_block" {
  description = "Public Subnet CIDR Block"
  type        = string
  default     = "10.0.0.0/24"
}

# Routes Variables
variable "private_destination_cidr_block" {
  description = "Private Subnet CIDR Block"
  type        = string
  default     = "10.0.0.0/24"
}