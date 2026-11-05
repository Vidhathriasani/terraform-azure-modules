###############################################################################
# Azure Virtual Network Module
# Creates a VNet with configurable subnets, NSGs, and optional peering
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
}

###############################################################################
# Resource Group (data source — expects it to already exist)
###############################################################################

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

###############################################################################
# Virtual Network
###############################################################################

resource "azurerm_virtual_network" "this" {
  name                = var.vnet_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  address_space       = var.address_space
  dns_servers         = var.dns_servers

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/vnet"
  })
}

###############################################################################
# Subnets
###############################################################################

resource "azurerm_subnet" "this" {
  for_each = var.subnets

  name                                          = each.key
  resource_group_name                           = data.azurerm_resource_group.this.name
  virtual_network_name                          = azurerm_virtual_network.this.name
  address_prefixes                              = each.value.address_prefixes
  service_endpoints                             = lookup(each.value, "service_endpoints", [])
  private_endpoint_network_policies             = lookup(each.value, "private_endpoint_network_policies", "Enabled")
  private_link_service_network_policies_enabled = lookup(each.value, "private_link_service_network_policies_enabled", true)

  dynamic "delegation" {
    for_each = lookup(each.value, "delegation", null) != null ? [each.value.delegation] : []

    content {
      name = delegation.value.name

      service_delegation {
        name    = delegation.value.service_delegation_name
        actions = delegation.value.service_delegation_actions
      }
    }
  }
}

###############################################################################
# Network Security Groups
###############################################################################

resource "azurerm_network_security_group" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_nsg", true) }

  name                = "nsg-${each.key}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/vnet"
    Subnet = each.key
  })
}

resource "azurerm_network_security_rule" "this" {
  for_each = { for rule in local.nsg_rules_flat : "${rule.subnet_key}-${rule.rule_name}" => rule }

  name                        = each.value.rule_name
  priority                    = each.value.priority
  direction                   = each.value.direction
  access                      = each.value.access
  protocol                    = each.value.protocol
  source_port_range           = each.value.source_port_range
  destination_port_range      = each.value.destination_port_range
  source_address_prefix       = each.value.source_address_prefix
  destination_address_prefix  = each.value.destination_address_prefix
  resource_group_name         = data.azurerm_resource_group.this.name
  network_security_group_name = azurerm_network_security_group.this[each.value.subnet_key].name
}

resource "azurerm_subnet_network_security_group_association" "this" {
  for_each = { for k, v in var.subnets : k => v if lookup(v, "create_nsg", true) }

  subnet_id                 = azurerm_subnet.this[each.key].id
  network_security_group_id = azurerm_network_security_group.this[each.key].id
}

###############################################################################
# VNet Peering
###############################################################################

resource "azurerm_virtual_network_peering" "this" {
  for_each = var.peerings

  name                         = each.key
  resource_group_name          = data.azurerm_resource_group.this.name
  virtual_network_name         = azurerm_virtual_network.this.name
  remote_virtual_network_id    = each.value.remote_vnet_id
  allow_virtual_network_access = lookup(each.value, "allow_vnet_access", true)
  allow_forwarded_traffic      = lookup(each.value, "allow_forwarded_traffic", false)
  allow_gateway_transit        = lookup(each.value, "allow_gateway_transit", false)
  use_remote_gateways          = lookup(each.value, "use_remote_gateways", false)
}

###############################################################################
# Locals
###############################################################################

locals {
  nsg_rules_flat = flatten([
    for subnet_key, subnet_val in var.subnets : [
      for rule in lookup(subnet_val, "nsg_rules", []) : merge(rule, {
        subnet_key = subnet_key
        rule_name  = rule.name
      })
    ] if lookup(subnet_val, "create_nsg", true)
  ])
}
