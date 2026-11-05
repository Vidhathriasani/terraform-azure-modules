variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "storage_account_name" {
  description = "Name of the storage account (3-24 lowercase alphanumeric)"
  type        = string
}

variable "account_tier" {
  description = "Performance tier: Standard or Premium"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Replication type: LRS, GRS, RAGRS, ZRS, GZRS, RAGZRS"
  type        = string
  default     = "GRS"
}

variable "account_kind" {
  description = "Account kind: StorageV2, BlobStorage, etc."
  type        = string
  default     = "StorageV2"
}

variable "access_tier" {
  description = "Default access tier: Hot or Cool"
  type        = string
  default     = "Hot"
}

variable "public_network_access_enabled" {
  type    = bool
  default = true
}

variable "shared_access_key_enabled" {
  description = "Allow shared key access (disable for Azure AD-only auth)"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  type    = bool
  default = true
}

variable "enable_change_feed" {
  type    = bool
  default = false
}

variable "enable_last_access_time" {
  type    = bool
  default = false
}

variable "blob_soft_delete_days" {
  type    = number
  default = 30
}

variable "container_soft_delete_days" {
  type    = number
  default = 30
}

variable "containers" {
  description = "Map of container configurations"
  type        = map(any)
  default     = {}
}

variable "lifecycle_rules" {
  description = "Lifecycle management rules"
  type        = list(any)
  default     = []
}

variable "cors_rules" {
  description = "CORS rules for blob storage"
  type        = list(any)
  default     = []
}

variable "network_rules" {
  description = "Network rules configuration"
  type        = map(any)
  default     = null
}

variable "private_endpoint_subnet_id" {
  description = "Subnet ID for private endpoint"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}
