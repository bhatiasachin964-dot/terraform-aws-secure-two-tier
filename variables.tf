variable "region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "ap-south-1"
}

variable "project" {
  description = "Name prefix used for resources and tags"
  type        = string
  default     = "secure-two-tier"
}

variable "admin_cidr" {
  description = "Your public IP in CIDR form (for example 203.0.113.10/32). Only this range can SSH to the web server."
  type        = string

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "admin_cidr must be a valid CIDR block and must not be 0.0.0.0/0."
  }
}

variable "key_name" {
  description = "Name of an existing EC2 key pair for SSH access (null disables SSH key login)"
  type        = string
  default     = null
}

variable "instance_type" {
  description = "EC2 instance type for both tiers"
  type        = string
  default     = "t3.micro"
}

variable "vpc_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type    = string
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  type    = string
  default = "10.0.2.0/24"
}

variable "force_destroy_bucket" {
  description = "Allow terraform destroy to delete the bucket even if it contains objects"
  type        = bool
  default     = false
}
