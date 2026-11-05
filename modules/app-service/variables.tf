variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "app_name" {
  description = "Name of the App Service (must be globally unique)"
  type        = string
}

variable "service_plan_name" {
  description = "Name of the App Service Plan"
  type        = string
}

variable "os_type" {
  description = "OS type: Linux or Windows"
  type        = string
  default     = "Linux"
}

variable "sku_name" {
  description = "App Service Plan SKU (B1, S1, P1v3, etc.)"
  type        = string
  default     = "P1v3"
}

variable "worker_count" {
  description = "Number of workers (instances)"
  type        = number
  default     = 1
}

variable "zone_redundant" {
  description = "Enable zone redundancy"
  type        = bool
  default     = false
}

variable "always_on" {
  description = "Keep the app always loaded"
  type        = bool
  default     = true
}

variable "identity_type" {
  description = "Managed identity type: SystemAssigned, UserAssigned, or both"
  type        = string
  default     = "SystemAssigned"
}

variable "identity_ids" {
  description = "List of user-assigned identity IDs"
  type        = list(string)
  default     = []
}

variable "application_stack" {
  description = "Application runtime stack configuration"
  type        = map(string)
  default     = null
}

variable "app_settings" {
  description = "App settings (environment variables)"
  type        = map(string)
  default     = {}
}

variable "connection_strings" {
  description = "Connection string configurations"
  type = list(object({
    name  = string
    type  = string
    value = string
  }))
  default = []
}

variable "ip_restrictions" {
  description = "IP restriction rules"
  type        = list(any)
  default     = []
}

variable "vnet_integration_subnet_id" {
  description = "Subnet ID for VNet integration"
  type        = string
  default     = null
}

variable "deployment_slots" {
  description = "Map of deployment slot configurations"
  type        = map(any)
  default     = {}
}

variable "autoscale_settings" {
  description = "Auto-scale configuration"
  type        = map(any)
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
