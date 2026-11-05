###############################################################################
# Azure Storage Account Module
# Deploys Storage Account with containers, lifecycle, and security hardening
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

data "azurerm_resource_group" "this" {
  name = var.resource_group_name
}

###############################################################################
# Storage Account
###############################################################################

resource "azurerm_storage_account" "this" {
  name                          = var.storage_account_name
  resource_group_name           = data.azurerm_resource_group.this.name
  location                      = var.location
  account_tier                  = var.account_tier
  account_replication_type      = var.replication_type
  account_kind                  = var.account_kind
  access_tier                   = var.access_tier
  min_tls_version               = "TLS1_2"
  enable_https_traffic_only     = true
  public_network_access_enabled = var.public_network_access_enabled
  shared_access_key_enabled     = var.shared_access_key_enabled

  # Blob properties
  blob_properties {
    versioning_enabled       = var.enable_versioning
    change_feed_enabled      = var.enable_change_feed
    last_access_time_enabled = var.enable_last_access_time

    dynamic "container_delete_retention_policy" {
      for_each = var.container_soft_delete_days > 0 ? [1] : []

      content {
        days = var.container_soft_delete_days
      }
    }

    dynamic "delete_retention_policy" {
      for_each = var.blob_soft_delete_days > 0 ? [1] : []

      content {
        days = var.blob_soft_delete_days
      }
    }

    dynamic "cors_rule" {
      for_each = var.cors_rules

      content {
        allowed_headers    = cors_rule.value.allowed_headers
        allowed_methods    = cors_rule.value.allowed_methods
        allowed_origins    = cors_rule.value.allowed_origins
        exposed_headers    = cors_rule.value.exposed_headers
        max_age_in_seconds = cors_rule.value.max_age_in_seconds
      }
    }
  }

  # Network rules
  dynamic "network_rules" {
    for_each = var.network_rules != null ? [var.network_rules] : []

    content {
      default_action             = network_rules.value.default_action
      bypass                     = lookup(network_rules.value, "bypass", ["AzureServices"])
      ip_rules                   = lookup(network_rules.value, "ip_rules", [])
      virtual_network_subnet_ids = lookup(network_rules.value, "virtual_network_subnet_ids", [])
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/storage-account"
  })
}

###############################################################################
# Containers
###############################################################################

resource "azurerm_storage_container" "this" {
  for_each = var.containers

  name                  = each.key
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = lookup(each.value, "access_type", "private")
}

###############################################################################
# Lifecycle Management
###############################################################################

resource "azurerm_storage_management_policy" "this" {
  count = length(var.lifecycle_rules) > 0 ? 1 : 0

  storage_account_id = azurerm_storage_account.this.id

  dynamic "rule" {
    for_each = var.lifecycle_rules

    content {
      name    = rule.value.name
      enabled = lookup(rule.value, "enabled", true)

      filters {
        blob_types   = lookup(rule.value, "blob_types", ["blockBlob"])
        prefix_match = lookup(rule.value, "prefix_match", [])
      }

      actions {
        base_blob {
          tier_to_cool_after_days_since_modification_greater_than    = lookup(rule.value, "tier_to_cool_days", null)
          tier_to_archive_after_days_since_modification_greater_than = lookup(rule.value, "tier_to_archive_days", null)
          delete_after_days_since_modification_greater_than          = lookup(rule.value, "delete_after_days", null)
        }

        dynamic "snapshot" {
          for_each = lookup(rule.value, "snapshot_delete_days", null) != null ? [1] : []

          content {
            delete_after_days_since_creation_greater_than = rule.value.snapshot_delete_days
          }
        }
      }
    }
  }
}

###############################################################################
# Private Endpoint
###############################################################################

resource "azurerm_private_endpoint" "blob" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${var.storage_account_name}-blob"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.storage_account_name}-blob"
    private_connection_resource_id = azurerm_storage_account.this.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  tags = var.tags
}
