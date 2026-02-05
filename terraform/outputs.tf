output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "function_app_url" {
  value = azurerm_linux_function_app.audio_func.default_hostname
}


output "eventgrid_topic_id" {
  value = azurerm_eventgrid_system_topic.blob_topic.id
}
