###############################################################################
# Azure Key Vault Module
# Deploys Key Vault with RBAC, network ACLs, and soft delete protection
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

data "azurerm_client_config" "current" {}

###############################################################################
# Key Vault
###############################################################################

resource "azurerm_key_vault" "this" {
  name                          = var.key_vault_name
  location                      = var.location
  resource_group_name           = data.azurerm_resource_group.this.name
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.sku_name
  enabled_for_deployment        = var.enabled_for_deployment
  enabled_for_disk_encryption   = var.enabled_for_disk_encryption
  enabled_for_template_deployment = var.enabled_for_template_deployment
  enable_rbac_authorization     = var.enable_rbac_authorization
  purge_protection_enabled      = var.purge_protection_enabled
  soft_delete_retention_days    = var.soft_delete_retention_days
  public_network_access_enabled = var.public_network_access_enabled

  network_acls {
    bypass                     = var.network_acls.bypass
    default_action             = var.network_acls.default_action
    ip_rules                   = var.network_acls.ip_rules
    virtual_network_subnet_ids = var.network_acls.virtual_network_subnet_ids
  }

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/key-vault"
  })
}

###############################################################################
# Access Policies (when not using RBAC)
###############################################################################

resource "azurerm_key_vault_access_policy" "this" {
  for_each = var.enable_rbac_authorization ? {} : var.access_policies

  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions         = lookup(each.value, "key_permissions", [])
  secret_permissions      = lookup(each.value, "secret_permissions", [])
  certificate_permissions = lookup(each.value, "certificate_permissions", [])
  storage_permissions     = lookup(each.value, "storage_permissions", [])
}

###############################################################################
# Diagnostic Settings
###############################################################################

resource "azurerm_monitor_diagnostic_setting" "this" {
  count = var.log_analytics_workspace_id != null ? 1 : 0

  name                       = "diag-${var.key_vault_name}"
  target_resource_id         = azurerm_key_vault.this.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  metric {
    category = "AllMetrics"
  }
}
