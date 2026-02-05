variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "audio-processing-rg"
}

variable "storage_account_name" {
  description = "Name of the storage account"
  type        = string
  default     = "audioprocessingstorage"
}

variable "function_app_name" {
  description = "Name of the Azure Function App"
  type        = string
  default     = "audio-processing-func"
}

variable "app_service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
  default     = "audio-processing-plan"
}
