resource "azurerm_network_interface" "vmnic" {
  name                = "jumpserver-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "my_nic_configuration"
    subnet_id                     = azurerm_subnet.jumpserver.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_security_group" "net_sg" {
  name                = "network_sg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  #   Allow SSH traffic from Bastion Host
  security_rule {
    name                       = "Allow_Bastion"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.0.0/27"
    destination_address_prefix = "*"
  }

}

resource "azurerm_network_interface_security_group_association" "sg_assoc" {
  network_interface_id      = azurerm_network_interface.vmnic.id
  network_security_group_id = azurerm_network_security_group.net_sg.id
}

# Identity

data "azurerm_subscription" "current" {}

resource "azurerm_user_assigned_identity" "identity-vm" {
  name                = "identity-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

resource "azurerm_role_assignment" "vm-contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.identity-vm.principal_id
}

resource "azurerm_linux_virtual_machine" "main" {
  name                = "jumpserver-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "adminuser"
  network_interface_ids = [azurerm_network_interface.vmnic.id]

  custom_data = filebase64("postdeploy.sh")

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/myazurekey.pub")
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.identity-vm.id]
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "ubuntu-24_04-lts"
    sku       = "server"
    version   = "latest"
  }
}
