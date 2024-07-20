resource "null_resource" "execute_python" {
  provisioner "local-exec" {
    command = "python3 ../write_to_db.py"
    environment = {
      DB_SERVER   = azurerm_synapse_workspace.synapse_workspace.connectivity_endpoints["sql"]
      DB_DATABASE = azurerm_synapse_sql_pool.synapse_sql_pool.name
      DB_USERNAME = azurerm_synapse_workspace.synapse_workspace.sql_administrator_login
      DB_PASSWORD = azurerm_synapse_workspace.synapse_workspace.sql_administrator_login_password
      DB_DRIVER   = "{ODBC Driver 18 for SQL Server}"
    }
    working_dir = path.module
  }

  depends_on = [
    azurerm_synapse_sql_pool.synapse_sql_pool,
    azurerm_synapse_firewall_rule.allow_my_ip
  ]
}