variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "server_name" {
  description = "Name of the SQL Server (must be globally unique)"
  type        = string
}

variable "sql_version" {
  description = "SQL Server version"
  type        = string
  default     = "12.0"
}

variable "admin_login" {
  description = "SQL admin username"
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "SQL admin password"
  type        = string
  sensitive   = true
}

variable "public_network_access_enabled" {
  type    = bool
  default = false
}

variable "azuread_admin" {
  description = "Azure AD administrator configuration"
  type        = map(string)
  default     = null
}

variable "databases" {
  description = "Map of database configurations"
  type        = map(any)
}

variable "firewall_rules" {
  description = "Map of firewall rules"
  type        = map(any)
  default     = {}
}

variable "vnet_rules" {
  description = "Map of VNet rules for SQL Server"
  type        = map(any)
  default     = {}
}

variable "audit_storage_account_id" {
  type    = string
  default = null
}

variable "audit_storage_endpoint" {
  type    = string
  default = null
}

variable "audit_storage_access_key" {
  type      = string
  default   = null
  sensitive = true
}

variable "audit_retention_days" {
  type    = number
  default = 90
}

variable "enable_threat_detection" {
  type    = bool
  default = false
}

variable "threat_detection_email_addresses" {
  type    = list(string)
  default = []
}

variable "private_endpoint_subnet_id" {
  type    = string
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
