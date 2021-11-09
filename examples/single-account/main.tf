locals {
  verify_ssl = length(regexall("^https://.*?\\.sysdig.com/?", var.sysdig_secure_endpoint)) != 0
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

provider "sysdig" {
  sysdig_secure_url          = var.sysdig_secure_endpoint
  sysdig_secure_api_token    = var.sysdig_secure_api_token
  sysdig_secure_insecure_tls = !local.verify_ssl
}

data "azurerm_subscription" "current" {
}

module "infrastructure_eventhub" {
  source = "../../modules/infrastructure/eventhub"

  subscription_ids    = [data.azurerm_subscription.current.subscription_id]
  location            = var.location
  name                = var.name
  tags                = var.tags
  resource_group_name = var.resource_group_name
}

module "cloud_connector" {
  source = "../../modules/services/cloud-connector"
  name   = "${var.name}-connector"

  subscription_ids                 = [data.azurerm_subscription.current.subscription_id]
  resource_group_name              = module.infrastructure_eventhub.resource_group_name
  azure_eventhub_connection_string = module.infrastructure_eventhub.azure_eventhub_connection_string
  location                         = var.location
  sysdig_secure_api_token          = var.sysdig_secure_api_token
  sysdig_secure_endpoint           = var.sysdig_secure_endpoint
  verify_ssl                       = local.verify_ssl
  tags                             = var.tags
}

module "cloud_bench" {
  count           = var.deploy_bench ? 1 : 0
  source          = "../../modules/services/cloud-bench"
  subscription_id = var.subscription_id
  region          = var.region
}
