###############################################################################
# Azure Kubernetes Service Module
# Deploys a production-ready AKS cluster with RBAC, CNI, and auto-scaling
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
# Log Analytics Workspace (for Container Insights)
###############################################################################

resource "azurerm_log_analytics_workspace" "this" {
  count = var.enable_log_analytics ? 1 : 0

  name                = "law-${var.cluster_name}"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days

  tags = var.tags
}

###############################################################################
# AKS Cluster
###############################################################################

resource "azurerm_kubernetes_cluster" "this" {
  name                = var.cluster_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.this.name
  dns_prefix          = var.dns_prefix
  kubernetes_version  = var.kubernetes_version
  sku_tier            = var.sku_tier

  # Default (system) node pool
  default_node_pool {
    name                 = var.default_node_pool.name
    node_count           = lookup(var.default_node_pool, "enable_auto_scaling", false) ? null : var.default_node_pool.node_count
    vm_size              = var.default_node_pool.vm_size
    vnet_subnet_id       = lookup(var.default_node_pool, "vnet_subnet_id", null)
    zones                = lookup(var.default_node_pool, "zones", ["1", "2", "3"])
    enable_auto_scaling  = lookup(var.default_node_pool, "enable_auto_scaling", false)
    min_count            = lookup(var.default_node_pool, "enable_auto_scaling", false) ? lookup(var.default_node_pool, "min_count", 1) : null
    max_count            = lookup(var.default_node_pool, "enable_auto_scaling", false) ? lookup(var.default_node_pool, "max_count", 5) : null
    max_pods             = lookup(var.default_node_pool, "max_pods", 110)
    os_disk_size_gb      = lookup(var.default_node_pool, "os_disk_size_gb", 128)
    os_disk_type         = lookup(var.default_node_pool, "os_disk_type", "Managed")
    temporary_name_for_rotation = "tmppool"

    tags = var.tags
  }

  # Identity
  identity {
    type = "SystemAssigned"
  }

  # Network profile
  network_profile {
    network_plugin    = var.network_plugin
    network_policy    = var.network_policy
    load_balancer_sku = "standard"
    outbound_type     = var.outbound_type
    service_cidr      = var.service_cidr
    dns_service_ip    = var.dns_service_ip
  }

  # Azure AD RBAC
  dynamic "azure_active_directory_role_based_access_control" {
    for_each = var.enable_azure_rbac ? [1] : []

    content {
      azure_rbac_enabled = true
      managed            = true
      admin_group_object_ids = var.admin_group_object_ids
    }
  }

  # Container Insights
  dynamic "oms_agent" {
    for_each = var.enable_log_analytics ? [1] : []

    content {
      log_analytics_workspace_id = azurerm_log_analytics_workspace.this[0].id
    }
  }

  # Azure Policy
  azure_policy_enabled = var.enable_azure_policy

  # Auto-scaler profile
  dynamic "auto_scaler_profile" {
    for_each = var.auto_scaler_profile != null ? [var.auto_scaler_profile] : []

    content {
      balance_similar_node_groups      = lookup(auto_scaler_profile.value, "balance_similar_node_groups", false)
      max_graceful_termination_sec     = lookup(auto_scaler_profile.value, "max_graceful_termination_sec", "600")
      scale_down_delay_after_add       = lookup(auto_scaler_profile.value, "scale_down_delay_after_add", "10m")
      scale_down_delay_after_delete    = lookup(auto_scaler_profile.value, "scale_down_delay_after_delete", "10s")
      scale_down_unneeded              = lookup(auto_scaler_profile.value, "scale_down_unneeded", "10m")
      scale_down_utilization_threshold = lookup(auto_scaler_profile.value, "scale_down_utilization_threshold", "0.5")
    }
  }

  tags = merge(var.tags, {
    Module = "terraform-azure-modules/aks"
  })

  lifecycle {
    ignore_changes = [
      default_node_pool[0].node_count, # Ignore changes from auto-scaler
    ]
  }
}

###############################################################################
# Additional Node Pools
###############################################################################

resource "azurerm_kubernetes_cluster_node_pool" "this" {
  for_each = var.additional_node_pools

  name                  = each.key
  kubernetes_cluster_id = azurerm_kubernetes_cluster.this.id
  vm_size               = each.value.vm_size
  node_count            = lookup(each.value, "enable_auto_scaling", false) ? null : each.value.node_count
  zones                 = lookup(each.value, "zones", ["1", "2", "3"])
  enable_auto_scaling   = lookup(each.value, "enable_auto_scaling", false)
  min_count             = lookup(each.value, "enable_auto_scaling", false) ? lookup(each.value, "min_count", 1) : null
  max_count             = lookup(each.value, "enable_auto_scaling", false) ? lookup(each.value, "max_count", 10) : null
  max_pods              = lookup(each.value, "max_pods", 110)
  os_disk_size_gb       = lookup(each.value, "os_disk_size_gb", 128)
  os_type               = lookup(each.value, "os_type", "Linux")
  vnet_subnet_id        = lookup(each.value, "vnet_subnet_id", null)
  node_labels           = lookup(each.value, "node_labels", {})
  node_taints           = lookup(each.value, "node_taints", [])
  priority              = lookup(each.value, "priority", "Regular")
  eviction_policy       = lookup(each.value, "priority", "Regular") == "Spot" ? lookup(each.value, "eviction_policy", "Delete") : null
  spot_max_price        = lookup(each.value, "priority", "Regular") == "Spot" ? lookup(each.value, "spot_max_price", -1) : null

  tags = merge(var.tags, {
    NodePool = each.key
  })

  lifecycle {
    ignore_changes = [
      node_count,
    ]
  }
}
