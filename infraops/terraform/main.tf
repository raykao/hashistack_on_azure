terraform {
  required_version = ">= 0.11.11"
  backend "azurerm" {
  }
}

provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.21.0"
}

resource "azurerm_resource_group" "default" {
  name     = "${var.AZURE_RESOURCE_GROUP_NAME}"
  location = "${var.AZURE_DC_LOCATION}"
}

resource "azurerm_container_registry" "default" {
  name                     = "${azurerm_resource_group.default.name}cr"
  resource_group_name      = "${azurerm_resource_group.default.name}"
  location                 = "${azurerm_resource_group.default.location}"
  sku                      = "Premium"
  admin_enabled            = true
  georeplication_locations = ["Canada East"]
}

resource "azurerm_app_service_plan" "default" {
  name                = "${azurerm_resource_group.default.name}-appserviceplan"
  location            = "${azurerm_resource_group.default.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  kind                = "${var.AZURE_APP_SERVICE_PLAN_KIND}"

  reserved = "${var.AZURE_APP_SERVICE_PLAN_RESERVED}"

  sku {
    tier = "${var.AZURE_APP_SERVICE_PLAN_TIER}"
    size = "${var.AZURE_APP_SERVICE_PLAN_SIZE}"
  }
}

# Create an Azure Web App for Containers in that App Service Plan
resource "azurerm_app_service" "webapp" {
  name                = "${azurerm_resource_group.default.name}wafcweb"
  location            = "${azurerm_resource_group.default.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  app_service_plan_id = "${azurerm_app_service_plan.default.id}"

  # Do not attach Storage by default
  app_settings {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false

    # Settings for private Container Registires  
    DOCKER_REGISTRY_SERVER_URL      = "https://${azurerm_container_registry.default.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = "${azurerm_container_registry.default.admin_username}"
    DOCKER_REGISTRY_SERVER_PASSWORD = "${azurerm_container_registry.default.admin_password}"
  }

  # Configure Docker Image to load on start
  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.default.login_server}/${var.WEBAPP_CONTAINER_IMAGE_NAME}:${var.WEBAPP_CONTAINER_IMAGE_TAG}"
    always_on        = "true"
  }

  identity {
    type = "SystemAssigned"
  }
}


# Create an Azure Web App for Containers in that App Service Plan
resource "azurerm_app_service" "apiapp" {
  name                = "${azurerm_resource_group.default.name}wafcapi"
  location            = "${azurerm_resource_group.default.location}"
  resource_group_name = "${azurerm_resource_group.default.name}"
  app_service_plan_id = "${azurerm_app_service_plan.default.id}"

  # Do not attach Storage by default
  app_settings {
    WEBSITES_ENABLE_APP_SERVICE_STORAGE = false

    # Settings for private Container Registires  
    DOCKER_REGISTRY_SERVER_URL      = "https://${azurerm_container_registry.default.login_server}"
    DOCKER_REGISTRY_SERVER_USERNAME = "${azurerm_container_registry.default.admin_username}"
    DOCKER_REGISTRY_SERVER_PASSWORD = "${azurerm_container_registry.default.admin_password}"
    MONGODB_CONNECTION_STRING = "${var.MONGODB_CONNECTION_STRING}"
  }

  # Configure Docker Image to load on start
  site_config {
    linux_fx_version = "DOCKER|${azurerm_container_registry.default.login_server}/${var.APIAPP_CONTAINER_IMAGE_NAME}:${var.APIAPP_CONTAINER_IMAGE_TAG}"
    always_on        = "true"
  }

  identity {
    type = "SystemAssigned"
  }
}