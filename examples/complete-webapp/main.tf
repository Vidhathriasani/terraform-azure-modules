###############################################################################
# Complete Web App Example
# Deploys: VNet + App Service + SQL Database + Key Vault + Storage
# A full 3-tier web application stack with security best practices
###############################################################################

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }

  # Uncomment to use remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "webapp.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

###############################################################################
# Variables
###############################################################################

variable "project" {
  default = "myapp"
}

variable "environment" {
  default = "prod"
}

variable "location" {
  default = "eastus"
}

variable "sql_admin_login" {
  sensitive = true
}

variable "sql_admin_password" {
  sensitive = true
}

locals {
  prefix = "${var.project}-${var.environment}"
  common_tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "Terraform"
    Repository  = "terraform-azure-modules"
  }
}

###############################################################################
# Resource Group
###############################################################################

resource "azurerm_resource_group" "this" {
  name     = "rg-${local.prefix}"
  location = var.location
  tags     = local.common_tags
}

###############################################################################
# Networking
###############################################################################

module "network" {
  source = "../../modules/vnet"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  vnet_name           = "vnet-${local.prefix}"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    app = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault", "Microsoft.Storage"]
      delegation = {
        name                       = "appservice"
        service_delegation_name    = "Microsoft.Web/serverFarms"
        service_delegation_actions = ["Microsoft.Network/virtualNetworks/subnets/action"]
      }
    }
    db = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
    private-endpoints = {
      address_prefixes                      = ["10.0.3.0/24"]
      private_endpoint_network_policies     = "Disabled"
      create_nsg                            = false
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# Key Vault
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
    virtual_network_subnet_ids = [module.network.subnet_ids["app"]]
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# Storage Account
###############################################################################

module "storage" {
  source = "../../modules/storage-account"

  resource_group_name  = azurerm_resource_group.this.name
  location             = var.location
  storage_account_name = replace("st${local.prefix}", "-", "")

  containers = {
    uploads = { access_type = "private" }
    logs    = { access_type = "private" }
  }

  lifecycle_rules = [
    {
      name              = "archive-old-logs"
      prefix_match      = ["logs/"]
      tier_to_cool_days = 30
      delete_after_days = 365
    }
  ]

  private_endpoint_subnet_id = module.network.subnet_ids["private-endpoints"]

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# SQL Database
###############################################################################

module "database" {
  source = "../../modules/sql-database"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  server_name         = "sql-${local.prefix}"
  admin_login         = var.sql_admin_login
  admin_password      = var.sql_admin_password

  databases = {
    "db-${var.project}" = {
      sku_name                 = "S1"
      max_size_gb              = 50
      zone_redundant           = false
      short_term_retention_days = 14
      ltr_policy = {
        weekly  = "P4W"
        monthly = "P12M"
      }
    }
  }

  vnet_rules = {
    app-subnet = {
      subnet_id = module.network.subnet_ids["app"]
    }
    db-subnet = {
      subnet_id = module.network.subnet_ids["db"]
    }
  }

  private_endpoint_subnet_id = module.network.subnet_ids["private-endpoints"]

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# App Service
###############################################################################

module "webapp" {
  source = "../../modules/app-service"

  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  app_name            = "app-${local.prefix}"
  service_plan_name   = "plan-${local.prefix}"
  sku_name            = "P1v3"

  application_stack = {
    dotnet_version = "8.0"
  }

  vnet_integration_subnet_id = module.network.subnet_ids["app"]

  deployment_slots = {
    staging = {
      app_settings = {
        ASPNETCORE_ENVIRONMENT = "Staging"
      }
    }
  }

  app_settings = {
    ASPNETCORE_ENVIRONMENT               = "Production"
    APPLICATIONINSIGHTS_CONNECTION_STRING = "InstrumentationKey=placeholder"
    KeyVaultUri                          = module.keyvault.key_vault_uri
  }

  autoscale_settings = {
    default_capacity = 2
    minimum          = 1
    maximum          = 5
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.this]
}

###############################################################################
# Outputs
###############################################################################

output "app_url" {
  value = "https://${module.webapp.default_hostname}"
}

output "sql_server_fqdn" {
  value = module.database.server_fqdn
}

output "key_vault_uri" {
  value = module.keyvault.key_vault_uri
}

output "staging_url" {
  value = "https://${module.webapp.slot_hostnames["staging"]}"
}
