locals {
  values_with_scanning = [
    <<EOF
rules: []
ingestors:
 - azure-event-hub:
     subscriptionID: ${data.azurerm_subscription.current.subscription_id}
 - azure-event-grid:
     subscriptionID: ${data.azurerm_subscription.current.subscription_id}
scanners:
 - azure-acr : {}
 - azure-aci :
     subscriptionID : ${data.azurerm_subscription.current.subscription_id}
     resourceGroup : ${module.infrastructure_resource_group.resource_group_name}
     containerRegistry : ${local.container_registry}
EOF
  ]
  values_without_scanning = [
    <<EOF
rules: []
ingestors:
 - azure-event-hub:
     subscriptionID: ${data.azurerm_subscription.current.subscription_id}
scanners:
EOF
  ]

  values = var.deploy_scanning ? local.values_with_scanning : local.values_without_scanning

}

resource "helm_release" "cloud_connector" {
  name = "cloud-connector"

  repository = "https://charts.sysdig.com"
  chart      = "cloud-connector"

  create_namespace = true
  namespace        = var.name
  atomic           = true
  timeout          = 60

  set_sensitive {
    name  = "sysdig.secureAPIToken"
    value = var.sysdig_secure_api_token
  }

  set {
    name  = "sysdig.url"
    value = var.sysdig_secure_endpoint
  }

  set {
    name  = "sysdig.verifySSL"
    value = local.verify_ssl
  }

  set {
    name  = "image.repository"
    value = var.cloud_connector_image
  }

  set {
    name  = "azure.eventHubConnectionString"
    value = module.infrastructure_eventhub.azure_eventhub_connection_string
  }

  set {
    name  = "azure.eventGridEventHubConnectionString"
    value = local.eventgrid_eventhub_connection_string
  }

  set {
    name  = "azure.tenantId"
    value = local.tenant_id
  }

  set {
    name  = "azure.clientId"
    value = local.client_id
  }

  set {
    name  = "azure.clientSecret"
    value = local.client_secret
  }

  set {
    name  = "azure.region"
    value = var.location
  }

  set {
    name  = "extraEnvVars[0].name"
    value = "TELEMETRY_DEPLOYMENT_METHOD"
  }

  set {
    name  = "extraEnvVars[0].value"
    value = "terraform_gcp_k8s_single"
  }

  values = local.values
}
