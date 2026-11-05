# Terraform Azure Infrastructure Modules

[![Terraform Validate](https://github.com/vidhathriasani/terraform-azure-modules/actions/workflows/validate.yml/badge.svg)](https://github.com/vidhathriasani/terraform-azure-modules/actions/workflows/validate.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)

Production-ready, reusable Terraform modules for deploying Azure infrastructure. Built with security best practices, tagging standards, and enterprise-grade configurations.

## Modules

| Module | Description | Key Features |
|--------|-------------|--------------|
| [vnet](./modules/vnet) | Virtual Network with subnets, NSGs, and peering | Multi-subnet, NSG rules, service endpoints, peering |
| [aks](./modules/aks) | Azure Kubernetes Service cluster | System/user node pools, RBAC, CNI networking, auto-scaling |
| [app-service](./modules/app-service) | App Service with deployment slots | Linux/Windows, staging slots, custom domains, managed identity |
| [key-vault](./modules/key-vault) | Azure Key Vault with access policies | RBAC, network ACLs, soft delete, purge protection |
| [storage-account](./modules/storage-account) | Storage Account with containers | Encryption, lifecycle policies, private endpoints, immutability |
| [sql-database](./modules/sql-database) | Azure SQL Database | Elastic pools, geo-replication, auditing, threat detection |

## Quick Start

```hcl
module "network" {
  source = "./modules/vnet"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  vnet_name           = "vnet-myapp-prod"
  address_space       = ["10.0.0.0/16"]

  subnets = {
    app = {
      address_prefixes  = ["10.0.1.0/24"]
      service_endpoints = ["Microsoft.Sql", "Microsoft.KeyVault"]
    }
    db = {
      address_prefixes  = ["10.0.2.0/24"]
      service_endpoints = ["Microsoft.Sql"]
    }
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

module "aks" {
  source = "./modules/aks"

  resource_group_name = "rg-myapp-prod"
  location            = "eastus"
  cluster_name        = "aks-myapp-prod"
  dns_prefix          = "myapp-prod"
  kubernetes_version  = "1.28"

  default_node_pool = {
    name                = "system"
    node_count          = 3
    vm_size             = "Standard_D4s_v3"
    vnet_subnet_id      = module.network.subnet_ids["app"]
    enable_auto_scaling = true
    min_count           = 2
    max_count           = 5
  }

  tags = {
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}
```

## Architecture

```
terraform-azure-modules/
├── modules/
│   ├── vnet/              # Virtual Network + Subnets + NSGs
│   ├── aks/               # Azure Kubernetes Service
│   ├── app-service/       # App Service + Slots
│   ├── key-vault/         # Key Vault + Access Policies
│   ├── storage-account/   # Storage + Containers + Lifecycle
│   └── sql-database/      # SQL Database + Auditing
├── examples/
│   ├── complete-webapp/   # Full web app stack example
│   └── aks-cluster/       # Production AKS cluster example
├── tests/                 # Terratest validation
└── .github/workflows/     # CI/CD pipeline
```

## Usage Patterns

### Composing Modules

These modules are designed to be composed together. See the [examples](./examples) directory for complete deployment patterns:

- **[Complete Web App](./examples/complete-webapp)** - VNet + App Service + SQL Database + Key Vault + Storage
- **[AKS Cluster](./examples/aks-cluster)** - VNet + AKS + Key Vault with workload identity

### Remote Module Source

Reference modules directly from GitHub:

```hcl
module "vnet" {
  source = "github.com/vidhathriasani/terraform-azure-modules//modules/vnet?ref=v1.0.0"
  # ... variables
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.5.0 |
| azurerm | >= 3.75.0 |

## Contributing

See [CONTRIBUTING.md](docs/CONTRIBUTING.md) for guidelines.

## License

MIT License - see [LICENSE](LICENSE) for details.
