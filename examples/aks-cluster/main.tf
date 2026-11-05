###############################################################################
# Production AKS Cluster Example
# Deploys: VNet + AKS (system + user pools) + Key Vault with workload identity
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

provider "azurerm" {
  features {}
}

variable "project" {
  default = "platform"
}

variable "environment" {
  default = "prod"
}

variable "location" {
  default = "eastus"
}

locals {
  prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.common_tags
}

###############################################################################
# Networking — dedicated subnets for system and workload pools
###############################################################################

module "network" {
  source = "../../modules/vnet"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vnet_name           = "vnet-${local.prefix}"
  address_space       = ["10.10.0.0/16"]

  subnets = {
    aks-system = {
      address_prefixes  = ["10.10.1.0/24"]
      service_endpoints = ["Microsoft.KeyVault", "Microsoft.ContainerRegistry"]
    }
    aks-workload = {
      address_prefixes  = ["10.10.2.0/23"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.Storage"]
    }
    aks-ingress = {
      address_prefixes = ["10.10.4.0/24"]
      nsg_rules = [
        {
          name                       = "allow-http"
          priority                   = 100
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "80"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        },
        {
          name                       = "allow-https"
          priority                   = 110
          direction                  = "Inbound"
          access                     = "Allow"
          protocol                   = "Tcp"
          source_port_range          = "*"
          destination_port_range     = "443"
          source_address_prefix      = "*"
          destination_address_prefix = "*"
        }
      ]
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# AKS Cluster
###############################################################################

module "aks" {
  source = "../../modules/aks"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  cluster_name        = "aks-${local.prefix}"
  dns_prefix          = local.prefix
  kubernetes_version  = "1.28"
  sku_tier            = "Standard"

  default_node_pool = {
    name                = "system"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    vnet_subnet_id      = module.network.subnet_ids["aks-system"]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
    os_disk_size_gb     = 128
    zones               = ["1", "2", "3"]
  }

  additional_node_pools = {
    workload = {
      vm_size             = "Standard_D8s_v3"
      node_count          = 3
      vnet_subnet_id      = module.network.subnet_ids["aks-workload"]
      enable_auto_scaling = true
      min_count           = 2
      max_count           = 20
      os_disk_size_gb     = 256
      node_labels = {
        "workload-type" = "application"
      }
    }
    spot = {
      vm_size             = "Standard_D4s_v3"
      node_count          = 0
      vnet_subnet_id      = module.network.subnet_ids["aks-workload"]
      enable_auto_scaling = true
      min_count           = 0
      max_count           = 10
      priority            = "Spot"
      eviction_policy     = "Delete"
      spot_max_price      = -1
      node_labels = {
        "kubernetes.azure.com/scalesetpriority" = "spot"
      }
      node_taints = ["kubernetes.azure.com/scalesetpriority=spot:NoSchedule"]
    }
  }

  network_plugin = "azure"
  network_policy = "azure"
  service_cidr   = "172.16.0.0/16"
  dns_service_ip = "172.16.0.10"

  enable_azure_rbac    = true
  enable_log_analytics = true
  log_retention_days   = 30
  enable_azure_policy  = true

  auto_scaler_profile = {
    balance_similar_node_groups      = "true"
    scale_down_delay_after_add       = "10m"
    scale_down_unneeded              = "10m"
    scale_down_utilization_threshold = "0.5"
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# Key Vault for workload secrets
###############################################################################

module "keyvault" {
  source = "../../modules/key-vault"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  key_vault_name      = "kv-${local.prefix}"

  network_acls = {
    bypass                     = "AzureServices"
    default_action             = "Deny"
    ip_rules                   = []
    virtual_network_subnet_ids = [
      module.network.subnet_ids["aks-system"],
      module.network.subnet_ids["aks-workload"]
    ]
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# Outputs
###############################################################################

output "cluster_name" {
  value = module.aks.cluster_name
}

output "cluster_fqdn" {
  value = module.aks.cluster_fqdn
}

output "kube_config_command" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.this.name} --name ${module.aks.cluster_name}"
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}
