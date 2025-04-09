
variable "dB_name" {
  description = "DynamoDB Name"
  type        = string
  default     = "RequestMetricsDb"
}

variable "dB_billing_mode" {
  description = "DynamoDB Billing Mode"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "dB_hash_key" {
  description = "DynamoDB Hash Key"
  type        = string
  default     = "request_id"
}

variable "dB_range_key" {
  description = "DynamoDB Range Key"
  type        = string
  default     = "timestamp"
}



variable "dB_attribute_string" {
  description = "DB Attribut String"
  type        = map(string)
  default = {
    name = "request_id"
    type = "S" # String
  }
}

variable "dB_attribute_number" {
  description = "dB Attribute Number"
  type = object({
    name = string
    type = string
  })
  default = {
    name = "timestamp"
    type = "N" # Number
  }
}

variable "dB_global_index_name" {
  description = "dB Global Secondary Index name"
  type        = string
  default     = "PathIndex"
}

variable "dB_global_index_hash_key" {
  description = "dB Global Secondary Index hash key"
  type        = string
  default     = "path"
}

variable "dB_global_index_range_key" {
  description = "dB Global Secondary index range key"
  type        = string
  default     = "timestamp"
}

variable "dB_global_index_projection_type" {
  description = "db Global Secondary index projection type"
  type        = string
  default     = "ALL"
}

variable "dB_global_index_read_capacity" {
  description = "db Global Secondary index read capacity "
  type        = number
  default     = 1
}

variable "dB_global_index_write_capacity" {
  description = "db Global Secondary index write capacity "
  type        = number
  default     = 1
}

