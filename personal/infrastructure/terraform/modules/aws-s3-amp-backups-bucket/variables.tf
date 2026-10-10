variable "name" {
  description = "The name of the S3 bucket"
  type        = string
}

variable "tags" {
  description = "The tags to apply to the S3 bucket"
  type        = map(string)
  default     = {}
}

variable "namespace" {
  description = "The namespace of the S3 bucket"
  type        = string
  default     = "account-regional"
}