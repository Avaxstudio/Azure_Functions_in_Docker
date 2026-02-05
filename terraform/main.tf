
# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Storage Account
resource "azurerm_storage_account" "sa" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "audioprocessingacr"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}

# Input container (WAV upload)
resource "azurerm_storage_container" "input" {
  name                  = "input"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# Output container (MP3 result)
resource "azurerm_storage_container" "output" {
  name                  = "output"
  storage_account_id    = azurerm_storage_account.sa.id
  container_access_type = "private"
}

# Event Grid Topic
resource "azurerm_eventgrid_system_topic" "blob_topic" {
  name                = "blob-upload-topic"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  source_resource_id  = azurerm_storage_account.sa.id
  topic_type          = "Microsoft.Storage.StorageAccounts"
}

# Service Plan (Consumption plan za Functions)
resource "azurerm_service_plan" "func_plan" {
  name                = var.app_service_plan_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "Y1"
}

# Function App sa Docker image-om (Linux varijanta)
resource "azurerm_linux_function_app" "audio_func" {
  name                        = var.function_app_name
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  service_plan_id             = azurerm_service_plan.func_plan.id
  storage_account_name        = azurerm_storage_account.sa.name
  storage_account_access_key  = azurerm_storage_account.sa.primary_access_key
  functions_extension_version = "~3"

  identity {
    type = "SystemAssigned"
  }

  site_config {
    # Docker image iz ACR-a
    linux_fx_version = "DOCKER|${azurerm_container_registry.acr.login_server}/audioprocessingfunc:v1"
  }

  app_settings = {
    FUNCTIONS_WORKER_RUNTIME        = "node"
    AzureWebJobsStorage             = azurerm_storage_account.sa.primary_connection_string
    DOCKER_REGISTRY_SERVER_URL      = azurerm_container_registry.acr.login_server
    DOCKER_REGISTRY_SERVER_USERNAME = azurerm_container_registry.acr.admin_username
    DOCKER_REGISTRY_SERVER_PASSWORD = azurerm_container_registry.acr.admin_password
  }
}

# Event Grid Subscription
resource "azurerm_eventgrid_event_subscription" "blob_sub" {
  name  = "blob-upload-subscription"
  scope = azurerm_eventgrid_system_topic.blob_topic.id

  webhook_endpoint {
    url = "https://${azurerm_linux_function_app.audio_func.default_hostname}/runtime/webhooks/eventgrid?functionName=ProcessAudio"
  }

  included_event_types = ["Microsoft.Storage.BlobCreated"]
}
