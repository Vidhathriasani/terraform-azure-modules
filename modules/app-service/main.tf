###############################################################################
# Azure App Service Module
# Deploys App Service with deployment slots, managed identity, and monitoring
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
# App Service Plan
###############################################################################

resource "azurerm_service_plan" "this" {
  name                = var.service_plan_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  os_type             = var.os_type
  sku_name            = var.sku_name
  worker_count        = var.worker_count
  zone_balancing_enabled = var.zone_redundant

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/app-service"
  })
}

###############################################################################
# Linux Web App
###############################################################################

resource "azurerm_linux_web_app" "this" {
  count = var.os_type == "Linux" ? 1 : 0

  name                      = var.app_name
  location                  = var.location
  resource_group_name       = data.azurerm_resource_group.this.name
  service_plan_id           = azurerm_service_plan.this.id
  https_only                = true
  virtual_network_subnet_id = var.vnet_integration_subnet_id

  identity {
    type         = var.identity_type
    identity_ids = var.identity_ids
  }

  site_config {
    always_on                = var.always_on
    ftps_state               = "Disabled"
    http2_enabled            = true
    minimum_tls_version      = "1.2"
    vnet_route_all_enabled   = var.vnet_integration_subnet_id != null

    dynamic "application_stack" {
      for_each = var.application_stack != null ? [var.application_stack] : []

      content {
        docker_image_name   = lookup(application_stack.value, "docker_image_name", null)
        docker_registry_url = lookup(application_stack.value, "docker_registry_url", null)
        dotnet_version      = lookup(application_stack.value, "dotnet_version", null)
        java_version        = lookup(application_stack.value, "java_version", null)
        node_version        = lookup(application_stack.value, "node_version", null)
        python_version      = lookup(application_stack.value, "python_version", null)
      }
    }

    dynamic "ip_restriction" {
      for_each = var.ip_restrictions

      content {
        name                      = ip_restriction.value.name
        ip_address                = lookup(ip_restriction.value, "ip_address", null)
        virtual_network_subnet_id = lookup(ip_restriction.value, "virtual_network_subnet_id", null)
        priority                  = ip_restriction.value.priority
        action                    = lookup(ip_restriction.value, "action", "Allow")
      }
    }
  }

  app_settings = var.app_settings

  dynamic "connection_string" {
    for_each = var.connection_strings

    content {
      name  = connection_string.value.name
      type  = connection_string.value.type
      value = connection_string.value.value
    }
  }

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/app-service"
  })
}

###############################################################################
# Deployment Slots
###############################################################################

resource "azurerm_linux_web_app_slot" "this" {
  for_each = var.os_type == "Linux" ? var.deployment_slots : {}

  name           = each.key
  app_service_id = azurerm_linux_web_app.this[0].id
  https_only     = true

  identity {
    type         = var.identity_type
    identity_ids = var.identity_ids
  }

  site_config {
    always_on           = var.always_on
    ftps_state          = "Disabled"
    http2_enabled       = true
    minimum_tls_version = "1.2"
  }

  app_settings = merge(var.app_settings, lookup(each.value, "app_settings", {}))

  tags = merge(var.tags, {
    Slot = each.key
  })
}

###############################################################################
# Auto-scale Settings
###############################################################################

resource "azurerm_monitor_autoscale_setting" "this" {
  count = var.autoscale_settings != null ? 1 : 0

  name                = "autoscale-${var.app_name}"
  resource_group_name = data.azurerm_resource_group.this.name
  location            = var.location
  target_resource_id  = azurerm_service_plan.this.id

  profile {
    name = "default"

    capacity {
      default = var.autoscale_settings.default_capacity
      minimum = var.autoscale_settings.minimum
      maximum = var.autoscale_settings.maximum
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = lookup(var.autoscale_settings, "scale_out_cpu_threshold", 75)
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "CpuPercentage"
        metric_resource_id = azurerm_service_plan.this.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = lookup(var.autoscale_settings, "scale_in_cpu_threshold", 25)
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT5M"
      }
    }
  }

  tags = var.tags
}
