terraform {
  required_providers {
    btp = {
      source = "SAP/btp"
      version = "1.18.1"
    }
  }
}

provider "btp" {
  globalaccount = ""
  username = var.btp_username
  password = var.btp_password
}