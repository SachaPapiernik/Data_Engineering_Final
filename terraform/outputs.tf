output "superset_ip" {
  value = azurerm_public_ip.superset_ip.ip_address
}

output "db_server" {
  value = azurerm_synapse_workspace.synapse_workspace.connectivity_endpoints["sql"]
}

output "db_database" {
  value = azurerm_synapse_sql_pool.synapse_sql_pool.name
}

output "db_username" {
  value = azurerm_synapse_workspace.synapse_workspace.sql_administrator_login
}

output "db_password" {
  value     = azurerm_synapse_workspace.synapse_workspace.sql_administrator_login_password
  sensitive = true
}
