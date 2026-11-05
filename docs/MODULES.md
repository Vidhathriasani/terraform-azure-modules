# Module Reference

## VNet Module

Creates an Azure Virtual Network with subnets, NSGs, and optional peering.

### Key Features
- Dynamic subnet creation with service endpoints
- Per-subnet NSG with custom rules
- Subnet delegation support (App Service, Container Instances, etc.)
- VNet peering for hub-spoke topologies

### When to Use
- Any deployment needing network isolation
- Hub-spoke network architectures
- Multi-tier applications with distinct network segments

---

## AKS Module

Deploys a production-ready Azure Kubernetes Service cluster.

### Key Features
- System and user node pool separation
- Azure CNI with network policies
- Spot instance node pools for cost optimization
- Container Insights integration
- Azure AD RBAC with admin groups
- Cluster auto-scaler configuration

### When to Use
- Microservices deployments
- Container orchestration at scale
- Multi-tenant workload isolation

---

## App Service Module

Deploys Azure App Service with deployment slots and auto-scaling.

### Key Features
- Linux web app with multiple runtime stacks
- Deployment slots for blue-green deployments
- VNet integration for private backend access
- Auto-scale rules based on CPU metrics
- Managed identity for secure service access

### When to Use
- Web applications and APIs
- Background processing services
- Containerized web workloads

---

## Key Vault Module

Deploys Azure Key Vault with access control and diagnostics.

### Key Features
- RBAC or access policy authorization
- Network ACLs with VNet integration
- Diagnostic logging to Log Analytics
- Purge protection and soft delete
- Audit event monitoring

### When to Use
- Centralized secret management
- Certificate storage and rotation
- Application configuration encryption

---

## Storage Account Module

Deploys Azure Storage with containers, lifecycle management, and security.

### Key Features
- Blob versioning and soft delete
- Lifecycle management policies (hot/cool/archive)
- Private endpoints for secure access
- CORS rules for web applications
- Network rules and firewall configuration

### When to Use
- Application file storage
- Log archival with tiered storage
- Static website hosting
- Backup and disaster recovery

---

## SQL Database Module

Deploys Azure SQL Server and databases with enterprise security.

### Key Features
- Azure AD authentication
- Server auditing and threat detection
- Short-term and long-term backup retention
- Serverless compute tier support
- Private endpoints and VNet rules
- Firewall rules management

### When to Use
- Relational database workloads
- Applications requiring geo-replication
- Regulatory compliance scenarios
