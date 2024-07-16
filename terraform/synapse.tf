resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = var.synapse_workspace_name
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.example.id
  sql_administrator_login              = var.synapse_admin_login
  sql_administrator_login_password     = var.synapse_admin_password

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_sql_pool" "synapse_sql_pool" {
  name                 = var.sql_pool_name
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "GRS"
}

resource "azurerm_synapse_firewall_rule" "allow_my_ip" {
  name                 = "AllowMyIP"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id
  start_ip_address     = var.start_ip_address
  end_ip_address       = var.end_ip_address
}
