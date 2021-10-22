locals {
  verify_ssl = length(regexall("^https://.*?\\.sysdig.com/?", var.sysdig_secure_endpoint)) != 0
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

data "azurerm_subscription" "current" {
}

module "infrastructure_eventhub" {
  source = "../../modules/infrastructure/eventhub"

  subscription_id     = data.azurerm_subscription.current.subscription_id
  location            = var.location
  name                = var.name
  tags                = var.tags
  resource_group_name = var.resource_group_name
}

module "infrastructure_container_registry" {
  source = "../../modules/infrastructure/container_registry"

  location             = var.location
  name                 = var.name
  resource_group_name  = module.infrastructure_eventhub.resource_group_name
  eventhub_endpoint_id = module.infrastructure_eventhub.azure_eventhub_id
}

module "infrastructure_enterprise_app" {
  source = "../../modules/infrastructure/enterprise_app"

  name                = var.name
  resource_group_name = module.infrastructure_eventhub.resource_group_name
  subscription_id     = data.azurerm_subscription.current.subscription_id
}

module "cloud_connector" {
  source = "../../modules/services/cloud-connector"
  name   = "${var.name}-cloudconnector"

  subscription_id                  = data.azurerm_subscription.current.subscription_id
  resource_group_name              = module.infrastructure_eventhub.resource_group_name
  azure_eventhub_connection_string = module.infrastructure_eventhub.azure_eventhub_connection_string
  tenant_id                        = module.infrastructure_enterprise_app.tenant_id
  client_id                        = module.infrastructure_enterprise_app.client_id
  client_secret                    = module.infrastructure_enterprise_app.client_secret
  location                         = var.location
  sysdig_secure_api_token          = var.sysdig_secure_api_token
  sysdig_secure_endpoint           = var.sysdig_secure_endpoint
  verify_ssl                       = local.verify_ssl
  tags                             = var.tags
}
