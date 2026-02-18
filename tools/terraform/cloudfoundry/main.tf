provider "cloudfoundry" {
  api_url  = data.terraform_remote_state.btp.outputs.api_endpoint
  user     = var.btp_username
  password = var.btp_password
}

data "cloudfoundry_spaces" "all" {
  org = data.terraform_remote_state.btp.outputs.org_id
}

data "cloudfoundry_space" "dev" {
    name = ""
    org  = data.terraform_remote_state.btp.outputs.org_id
}

data "cloudfoundry_domain" "cfapps" {
  name = "cfapps.${trimprefix(data.terraform_remote_state.btp.outputs.api_endpoint, "https://api.cf." )}"
}

resource "cloudfoundry_route" "route" {
  space  = data.cloudfoundry_space.dev.id
  domain = data.cloudfoundry_domain.cfapps.id
  host   = "template"
}

resource "cloudfoundry_app" "server" {
  path = "../../deploy.zip"
  source_code_hash = filesha256("../../deploy.zip")
  name = "template-tf"
  space_name = data.cloudfoundry_space.dev.name
  org_name = data.terraform_remote_state.btp.outputs.org_name
  instances = 1
  routes = [{
    route = cloudfoundry_route.route.url
  }]
  environment = {
    SERVER_HOST="http://localhost",
    SERVER_PORT=8080,
  }
}

output "url" {
  value = cloudfoundry_route.route.url
}