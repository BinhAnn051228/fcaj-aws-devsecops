variable "project_name" {
  description = "Short project identifier used in AWS resource names."
  type        = string
  default     = "fcaj-devsecops"
}

variable "aws_region" {
  description = "AWS Region for the workshop."
  type        = string
  default     = "ap-southeast-1"
}

variable "tags" {
  description = "Additional tags applied to bootstrap resources."
  type        = map(string)
  default     = {}
}
