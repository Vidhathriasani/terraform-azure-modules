variable "resource_group_name" {
  description = "Name of the resource group where the VNet will be created"
  type        = string
}

variable "location" {
  description = "Azure region for the VNet"
  type        = string
}

variable "vnet_name" {
  description = "Name of the Virtual Network"
  type        = string
}

variable "address_space" {
  description = "Address space for the VNet (list of CIDR blocks)"
  type        = list(string)
}

variable "dns_servers" {
  description = "Custom DNS servers for the VNet (empty list uses Azure default)"
  type        = list(string)
  default     = []
}

variable "subnets" {
  description = <<-EOT
    Map of subnet configurations. Each subnet supports:
    - address_prefixes: list of CIDR blocks
    - service_endpoints: list of service endpoint types
    - create_nsg: whether to create an NSG (default: true)
    - nsg_rules: list of NSG rule objects
    - delegation: optional subnet delegation config
    - private_endpoint_network_policies: "Enabled" or "Disabled"
    - private_link_service_network_policies_enabled: bool
  EOT
  type        = map(any)
  default     = {}
}

variable "peerings" {
  description = <<-EOT
    Map of VNet peering configurations. Each peering supports:
    - remote_vnet_id: ID of the remote VNet
    - allow_vnet_access: allow access to remote VNet (default: true)
    - allow_forwarded_traffic: allow forwarded traffic (default: false)
    - allow_gateway_transit: allow gateway transit (default: false)
    - use_remote_gateways: use remote gateways (default: false)
  EOT
  type        = map(any)
  default     = {}
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
