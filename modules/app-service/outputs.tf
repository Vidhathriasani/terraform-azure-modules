output "app_service_id" {
  description = "ID of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].id : null
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].name : null
}

output "default_hostname" {
  description = "Default hostname of the App Service"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].default_hostname : null
}

output "principal_id" {
  description = "Principal ID of the managed identity"
  value       = var.os_type == "Linux" ? azurerm_linux_web_app.this[0].identity[0].principal_id : null
}

output "service_plan_id" {
  description = "ID of the App Service Plan"
  value       = azurerm_service_plan.this.id
}

output "slot_hostnames" {
  description = "Map of slot names to their hostnames"
  value = var.os_type == "Linux" ? {
    for k, v in azurerm_linux_web_app_slot.this : k => v.default_hostname
  } : {}
}
