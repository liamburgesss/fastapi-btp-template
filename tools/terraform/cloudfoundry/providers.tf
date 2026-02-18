terraform {
  required_version = ">= 1.10.4"
  required_providers {
    cloudfoundry = {
      source  = "cloudfoundry/cloudfoundry"
      version = "1.3.0"
    }
  }
}