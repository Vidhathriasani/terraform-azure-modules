variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "cluster_name" {
  description = "Name of the AKS cluster"
  type        = string
}

variable "dns_prefix" {
  description = "DNS prefix for the AKS cluster"
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster"
  type        = string
  default     = "1.28"
}

variable "sku_tier" {
  description = "SKU tier for the AKS cluster (Free or Standard)"
  type        = string
  default     = "Free"

  validation {
    condition     = contains(["Free", "Standard"], var.sku_tier)
    error_message = "SKU tier must be either 'Free' or 'Standard'."
  }
}

variable "default_node_pool" {
  description = "Configuration for the default (system) node pool"
  type        = map(any)
}

variable "additional_node_pools" {
  description = "Map of additional (user) node pool configurations"
  type        = map(any)
  default     = {}
}

variable "network_plugin" {
  description = "Network plugin: azure (CNI) or kubenet"
  type        = string
  default     = "azure"
}

variable "network_policy" {
  description = "Network policy provider: azure, calico, or null"
  type        = string
  default     = "azure"
}

variable "outbound_type" {
  description = "Outbound routing method: loadBalancer or userDefinedRouting"
  type        = string
  default     = "loadBalancer"
}

variable "service_cidr" {
  description = "CIDR range for Kubernetes services"
  type        = string
  default     = "172.16.0.0/16"
}

variable "dns_service_ip" {
  description = "IP address for the Kubernetes DNS service"
  type        = string
  default     = "172.16.0.10"
}

variable "enable_azure_rbac" {
  description = "Enable Azure AD RBAC integration"
  type        = bool
  default     = true
}

variable "admin_group_object_ids" {
  description = "List of Azure AD group object IDs for cluster admin access"
  type        = list(string)
  default     = []
}

variable "enable_log_analytics" {
  description = "Enable Container Insights with Log Analytics"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 30
}

variable "enable_azure_policy" {
  description = "Enable Azure Policy add-on for AKS"
  type        = bool
  default     = false
}

variable "auto_scaler_profile" {
  description = "Cluster auto-scaler profile configuration"
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
