variable "btp_username" {
  description = ""
  type        = string
}

variable "btp_password" {
  description = ""
  type        = string
  sensitive   = true  # Suppresses the value in CLI output
}

variable "target-directory" {
  default = ""
  description = ""
  type        = string
}

variable subaccount_name {
  default = ""
  type = string
}