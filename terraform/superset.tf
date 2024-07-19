resource "azurerm_virtual_machine" "superset_vm" {
  name                  = "superset-vm"
  location              = azurerm_resource_group.rg.location
  resource_group_name   = azurerm_resource_group.rg.name
  network_interface_ids = [azurerm_network_interface.superset_nic.id]
  vm_size               = "Standard_B1ms"

  depends_on = [
    azurerm_storage_account.datalake
  ]

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

# Provision Superset
resource "null_resource" "provision_superset" {
  depends_on = [
    azurerm_virtual_machine.superset_vm,
    azurerm_public_ip.superset_ip
  ]

  provisioner "file" {
    source      = "../install_docker_superset.sh"
    destination = "/tmp/install_docker_superset.sh"

    connection {
      type     = "ssh"
      user     = var.vm_admin_username
      password = var.vm_admin_password
      host     = azurerm_public_ip.superset_ip.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_docker_superset.sh",
      "sudo /tmp/install_docker_superset.sh"
    ]

    connection {
      type     = "ssh"
      user     = var.vm_admin_username
      password = var.vm_admin_password
      host     = azurerm_public_ip.superset_ip.ip_address
    }
  }
}