# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "chavo-group" {
  name     = "chavoResourceGroup"
  location = "eastus"

  tags = {
    environment = "Terraform chavo"
  }
}

# Create virtual network
resource "azurerm_virtual_network" "chavo-network" {
  name                = "chavonet"
  address_space       = ["10.0.0.0/16"]
  location            = "eastus"
  resource_group_name = azurerm_resource_group.chavo-group.name

  tags = {
    environment = "Terraform chavo"
  }
}

# Create subnet
resource "azurerm_subnet" "chavo-subnet" {
  name                 = "chavoSubnet"
  resource_group_name  = azurerm_resource_group.chavo-group.name
  virtual_network_name = azurerm_virtual_network.chavo-network.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Create public IPs
resource "azurerm_public_ip" "chavo-public-ip" {
  count               = var.server_count
  name                = "chavoPublicIP-${count.index}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.chavo-group.name
  allocation_method   = "Dynamic"

  tags = {
    environment = "Terraform chavo"
  }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "chavo-sg" {
  name                = "chavoNetworkSecurityGroup"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.chavo-group.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = var.destination_port_ranges
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    environment = "Terraform chavo"
  }
}

# Create network interface
resource "azurerm_network_interface" "chavo-nic" {
  count               = var.server_count
  name                = "chavoNIC-${count.index}"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.chavo-group.name

  ip_configuration {
    name                          = "chavoNicConfiguration"
    subnet_id                     = azurerm_subnet.chavo-subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.chavo-public-ip.*.id, count.index)
  }

  tags = {
    environment = "Terraform chavo"
  }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
  keepers = {
    # Generate a new ID only when a new resource group is defined
    resource_group = azurerm_resource_group.chavo-group.name
  }

  byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "chavostorageaccount" {
  name                     = "diag${random_id.randomId.hex}"
  resource_group_name      = azurerm_resource_group.chavo-group.name
  location                 = "eastus"
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "Terraform chavo"
  }
}

# Create virtual machine
resource "azurerm_virtual_machine" "chavo-vm" {
  count                 = var.server_count
  name                  = "chavoVM-${count.index}"
  location              = "eastus"
  resource_group_name   = azurerm_resource_group.chavo-group.name
  network_interface_ids = ["${element(azurerm_network_interface.chavo-nic.*.id, count.index)}"]
  vm_size               = "Standard_DS1_v2"

  storage_os_disk {
    name              = "chavoOsDisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04.0-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "chavovm-${count.index}"
    admin_username = "azureuser"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/azureuser/.ssh/authorized_keys"
      key_data = var.public_key
    }
  }

  tags = {
    environment = "Terraform chavo"
  }
}
