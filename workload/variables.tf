variable "project_name" {
  type        = string
  description = "Project name used for resource tags and names."
  default     = "fcaj-devsecops"
}

variable "environment" {
  type        = string
  description = "Environment name."
  default     = "dev"
}

variable "aws_region" {
  type        = string
  description = "AWS Region."
  default     = "ap-southeast-1"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR."
  default     = "10.20.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public subnet CIDR."
  default     = "10.20.10.0/24"
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type for the demo web application."
  default     = "t3.micro"
}

variable "allowed_http_cidr" {
  type        = string
  description = "CIDR allowed to reach the workshop HTTP endpoint."
  default     = "0.0.0.0/0"
}

variable "tags" {
  type        = map(string)
  description = "Additional resource tags."
  default     = {}
}
