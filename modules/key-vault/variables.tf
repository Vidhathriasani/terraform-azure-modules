variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "key_vault_name" {
  description = "Name of the Key Vault (must be globally unique)"
  type        = string
}

variable "sku_name" {
  description = "SKU name: standard or premium"
  type        = string
  default     = "standard"
}

variable "enabled_for_deployment" {
  description = "Allow Azure VMs to retrieve certificates"
  type        = bool
  default     = false
}

variable "enabled_for_disk_encryption" {
  description = "Allow Azure Disk Encryption to retrieve secrets"
  type        = bool
  default     = false
}

variable "enabled_for_template_deployment" {
  description = "Allow ARM templates to retrieve secrets"
  type        = bool
  default     = false
}

variable "enable_rbac_authorization" {
  description = "Use Azure RBAC instead of access policies"
  type        = bool
  default     = true
}

variable "purge_protection_enabled" {
  description = "Enable purge protection (recommended for production)"
  type        = bool
  default     = true
}

variable "soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted vaults"
  type        = number
  default     = 90
}

variable "public_network_access_enabled" {
  description = "Allow public network access"
  type        = bool
  default     = true
}

variable "network_acls" {
  description = "Network ACL configuration"
  type = object({
    bypass                     = string
    default_action             = string
    ip_rules                   = list(string)
    virtual_network_subnet_ids = list(string)
  })
  default = {
    bypass                     = "AzureServices"
    default_action             = "Allow"
    ip_rules                   = []
    virtual_network_subnet_ids = []
  }
}

variable "access_policies" {
  description = "Map of access policy configurations (used when RBAC is disabled)"
  type        = map(any)
  default     = {}
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID for diagnostic settings"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
