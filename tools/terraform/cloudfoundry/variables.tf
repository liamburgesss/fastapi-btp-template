variable "btp_username" {
  type        = string
  description = "Login Username"
  sensitive   = true
}

variable "btp_password" {
  type        = string
  description = "Login Password"
  sensitive   = true
}

variable "btp_state_url" {}
variable "gitlab_username" {}
variable "gitlab_token" {}

data "terraform_remote_state" "btp" {
  backend = "http"

  config = {
    address  = var.btp_state_url
    username = var.gitlab_username
    password = var.gitlab_token
    retry_wait_min = 5
  }
}
