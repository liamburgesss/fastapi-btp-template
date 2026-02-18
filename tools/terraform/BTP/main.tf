data "btp_directories" "all" {
}

data "btp_subaccounts" "all" {
}

locals {
  sub_dir = [
    for s in data.btp_subaccounts.all.values : s
    if s["name"] == var.subaccount_name
  ][0] # [0] takes the first result
}

data "btp_subaccount" "dev" {
  id = local.sub_dir.id
}

data "btp_subaccount_service_instances" "all" {
  subaccount_id = data.btp_subaccount.dev.id
}

data "btp_subaccount_environment_instances" "all" {
  subaccount_id = data.btp_subaccount.dev.id
}

locals {
  cf = [
    for s in data.btp_subaccount_environment_instances.all.values : s
    if s["environment_type"] == "cloudfoundry"
  ][0] # [0] takes the first result
}

data "btp_subaccount_environment_instance" "cloudfoundry" {
  id = local.cf.id
  subaccount_id = data.btp_subaccount.dev.id
}

output "api_endpoint" {
  value = jsondecode(data.btp_subaccount_environment_instance.cloudfoundry.labels)["API Endpoint"]
}

output "org_id" {
  value = jsondecode(data.btp_subaccount_environment_instance.cloudfoundry.labels)["Org ID"]
}

output "org_name" {
  value = jsondecode(data.btp_subaccount_environment_instance.cloudfoundry.labels)["Org Name"]
}
