resource "azurerm_storage_account" "staging" {
  name                     = var.staging_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "datalake" {
  name                     = var.datalake_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

resource "azurerm_storage_data_lake_gen2_filesystem" "example" {
  name               = var.filesystem_name
  storage_account_id = azurerm_storage_account.datalake.id

  depends_on = [
    azurerm_storage_account.datalake,
  ]
}
