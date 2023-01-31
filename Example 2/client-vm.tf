
# create subnet
resource "azurerm_subnet" "client" {
  name                 = "sn-client"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.3.0/24"]
}

# create nsg and allow rdp from 59.102.23.57
resource "azurerm_network_security_group" "client-nsg" {
  name                = "nsg-client"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  security_rule {
    name                       = "rdp"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "20.167.41.16"
    destination_address_prefix = "*"
    }
}

# associate nsg to client subnet
resource "azurerm_subnet_network_security_group_association" "client-nsg" {
  subnet_id                 = azurerm_subnet.client.id
  network_security_group_id = azurerm_network_security_group.client-nsg.id
}

# create a public IP
resource "azurerm_public_ip" "client-ip" {
  name                = "pip-client"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# create a new network interface
resource "azurerm_network_interface" "client-interface" {
  name                = "ni-admin-host"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.client.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.client-ip.id
  }
}


# create ubuntu vm in client subnet
resource "azurerm_linux_virtual_machine" "ubuntu" {
  name                = "ubuntu-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B4ms"
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.client-interface.id
  ]
  admin_password      = "Passw0rd.0"
  disable_password_authentication = false
  custom_data = base64encode(file("./clientscript.sh"))
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-focal"
    sku       = "20_04-lts-gen2"
    version   = "latest"
  }
  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
}