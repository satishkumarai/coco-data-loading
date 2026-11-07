output "storage_queue_id" {
  description = "ID of the Azure Storage Queue for Snowpipe notifications"
  value       = azurerm_storage_queue.snowpipe_queue.id
}

output "storage_queue_name" {
  description = "Name of the Azure Storage Queue"
  value       = azurerm_storage_queue.snowpipe_queue.name
}
