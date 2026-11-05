###############################################################################
# Azure SQL Database Module
# Deploys SQL Server + Database with auditing, threat detection, and geo-rep
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
# SQL Server
###############################################################################

resource "azurerm_mssql_server" "this" {
  name                          = var.server_name
  resource_group_name           = data.azurerm_resource_group.this.name
  location                      = var.location
  version                       = var.sql_version
  administrator_login           = var.admin_login
  administrator_login_password  = var.admin_password
  minimum_tls_version           = "1.2"
  public_network_access_enabled = var.public_network_access_enabled

  dynamic "azuread_administrator" {
    for_each = var.azuread_admin != null ? [var.azuread_admin] : []

    content {
      login_username              = azuread_administrator.value.login_username
      object_id                   = azuread_administrator.value.object_id
      azuread_authentication_only = lookup(azuread_administrator.value, "azuread_authentication_only", false)
    }
  }

  identity {
    type = "SystemAssigned"
  }

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/sql-database"
  })
}

###############################################################################
# SQL Database
###############################################################################

resource "azurerm_mssql_database" "this" {
  for_each = var.databases

  name                        = each.key
  server_id                   = azurerm_mssql_server.this.id
  collation                   = lookup(each.value, "collation", "SQL_Latin1_General_CP1_CI_AS")
  max_size_gb                 = lookup(each.value, "max_size_gb", 32)
  sku_name                    = lookup(each.value, "sku_name", "S0")
  zone_redundant              = lookup(each.value, "zone_redundant", false)
  geo_backup_enabled          = lookup(each.value, "geo_backup_enabled", true)
  read_scale                  = lookup(each.value, "read_scale", false)
  storage_account_type        = lookup(each.value, "storage_account_type", "Geo")
  min_capacity                = lookup(each.value, "sku_name", "S0") == "GP_S_Gen5_2" ? lookup(each.value, "min_capacity", 0.5) : null
  auto_pause_delay_in_minutes = lookup(each.value, "sku_name", "S0") == "GP_S_Gen5_2" ? lookup(each.value, "auto_pause_delay", 60) : null

  dynamic "short_term_retention_policy" {
    for_each = lookup(each.value, "short_term_retention_days", null) != null ? [1] : []

    content {
      retention_days           = each.value.short_term_retention_days
      backup_interval_in_hours = lookup(each.value, "backup_interval_hours", 12)
    }
  }

  dynamic "long_term_retention_policy" {
    for_each = lookup(each.value, "ltr_policy", null) != null ? [each.value.ltr_policy] : []

    content {
      weekly_retention  = lookup(long_term_retention_policy.value, "weekly", null)
      monthly_retention = lookup(long_term_retention_policy.value, "monthly", null)
      yearly_retention  = lookup(long_term_retention_policy.value, "yearly", null)
      week_of_year      = lookup(long_term_retention_policy.value, "week_of_year", null)
    }
  }

  tags = merge(var.tags, {
    Database = each.key
  })
}

###############################################################################
# Firewall Rules
###############################################################################

resource "azurerm_mssql_firewall_rule" "this" {
  for_each = var.firewall_rules

  name             = each.key
  server_id        = azurerm_mssql_server.this.id
  start_ip_address = each.value.start_ip
  end_ip_address   = each.value.end_ip
}

resource "azurerm_mssql_virtual_network_rule" "this" {
  for_each = var.vnet_rules

  name      = each.key
  server_id = azurerm_mssql_server.this.id
  subnet_id = each.value.subnet_id
}

###############################################################################
# Auditing
###############################################################################

resource "azurerm_mssql_server_extended_auditing_policy" "this" {
  count = var.audit_storage_account_id != null ? 1 : 0

  server_id                               = azurerm_mssql_server.this.id
  storage_endpoint                        = var.audit_storage_endpoint
  storage_account_access_key              = var.audit_storage_access_key
  storage_account_access_key_is_secondary = false
  retention_in_days                       = var.audit_retention_days
  log_monitoring_enabled                  = true
}

###############################################################################
# Threat Detection
###############################################################################

resource "azurerm_mssql_server_security_alert_policy" "this" {
  count = var.enable_threat_detection ? 1 : 0

  resource_group_name = data.azurerm_resource_group.this.name
  server_name         = azurerm_mssql_server.this.name
  state               = "Enabled"
  email_addresses     = var.threat_detection_email_addresses
  retention_days      = var.audit_retention_days
}

###############################################################################
# Private Endpoint
###############################################################################

resource "azurerm_private_endpoint" "this" {
  count = var.private_endpoint_subnet_id != null ? 1 : 0

  name                = "pe-${var.server_name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  subnet_id           = var.private_endpoint_subnet_id

  private_service_connection {
    name                           = "psc-${var.server_name}"
    private_connection_resource_id = azurerm_mssql_server.this.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }

  tags = var.tags
}
