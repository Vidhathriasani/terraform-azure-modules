output "cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.id
}

output "cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.name
}

output "cluster_fqdn" {
  description = "FQDN of the AKS cluster"
  value       = azurerm_kubernetes_cluster.this.fqdn
}

output "kube_config_raw" {
  description = "Raw kubeconfig for the cluster"
  value       = azurerm_kubernetes_cluster.this.kube_config_raw
  sensitive   = true
}

output "kubelet_identity" {
  description = "Kubelet managed identity"
  value       = azurerm_kubernetes_cluster.this.kubelet_identity
}

output "node_resource_group" {
  description = "Auto-generated resource group for AKS nodes"
  value       = azurerm_kubernetes_cluster.this.node_resource_group
}

output "oidc_issuer_url" {
  description = "OIDC issuer URL for workload identity"
  value       = azurerm_kubernetes_cluster.this.oidc_issuer_url
}

output "principal_id" {
  description = "Principal ID of the cluster's managed identity"
  value       = azurerm_kubernetes_cluster.this.identity[0].principal_id
}
