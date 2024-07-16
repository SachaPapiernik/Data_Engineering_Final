resource "azurerm_virtual_machine" "superset_vm" {
  name                  = "superset-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.superset_nic.id]
  vm_size               = "Standard_B1ms"

  storage_os_disk {
    name              = "superset-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  storage_image_reference {
    publisher = "Debian"
    offer     = "debian-10"
    sku       = "10"
    version   = "latest"
  }

  os_profile {
    computer_name  = "supersetvm"
    admin_username = var.vm_admin_username
    admin_password = var.vm_admin_password
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

  tags = {
    environment = "development"
  }
}

resource "azurerm_virtual_machine_extension" "docker_superset_install" {
  name                 = "docker-superset-install"
  virtual_machine_id   = azurerm_virtual_machine.superset_vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
      "commandToExecute": "sh -c 'apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && add-apt-repository \"deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable\" && apt-get update && apt-get install -y docker-ce && systemctl start docker && systemctl enable docker && usermod -aG docker ${var.vm_admin_username} && newgrp docker && docker run -d -p 8088:8088 --name superset apache/superset:latest'"
    }
  SETTINGS
}
