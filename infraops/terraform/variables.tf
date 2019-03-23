variable "CLUSTER_ENVIRONMENT" {
  default = "test"
}


variable "AZURE_RESOURCE_GROUP_NAME" {
  default = "rkdevopsdemo"
}

variable "AZURE_DC_LOCATION" {
  default = "Canada Central"
}

variable "AZURE_APP_SERVICE_PLAN_TIER" {
  default = "Standard"
}

variable "AZURE_APP_SERVICE_PLAN_SIZE" {
  default = "S1"
}

variable "AZURE_APP_SERVICE_PLAN_KIND" {
  default = "Linux"
}

variable "AZURE_APP_SERVICE_PLAN_RESERVED" {
  default = "true"
}

variable "WEBAPP_CONTAINER_IMAGE_NAME" {
  default = "nginx"
}

variable "WEBAPP_CONTAINER_IMAGE_TAG" {
  default = "latest"
}

variable "APIAPP_CONTAINER_IMAGE_NAME" {
  default = "nginx"
}

variable "APIAPP_CONTAINER_IMAGE_TAG" {
  default = "latest"
}

variable "MONGODB_CONNECTION_STRING" {
  default = "mongodb://127.0.0.1:27017"
}



