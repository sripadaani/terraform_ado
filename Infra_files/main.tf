terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.0.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  subscription_id = "${var.azure_subscription_id}"
  tenant_id       = "${var.azure_tenant_id}"
  client_id       = "${var.azure_client_id}"
  client_secret   = "${var.azure_client_secret}"
}

resource "azurerm_resource_group" "test-rg1" {
  name     = "${var.azure_rg_name}"
  location = "${var.azure_location}"
}
resource "azurerm_virtual_network" "test-Vnet" {
  name                = "${var.azure_vnet_name}"
  address_space       = ["${var.address_space}"]
  location            = "${azurerm_resource_group.test-rg1.location}"
  resource_group_name = "${azurerm_resource_group.test-rg1.name}"
}

resource "azurerm_subnet" "test-Subnet" {
  name                 = "${var.azure_subnet_name}"
  resource_group_name  = "${azurerm_resource_group.test-rg1.name}"
  virtual_network_name = "${azurerm_virtual_network.test-Vnet.name}"
  address_prefixes     = ["${var.address_prefixes}"]
}
resource "azurerm_public_ip" "pubip" {
  name                = "test-publicip"
  resource_group_name = azurerm_resource_group.test-rg1.name
  location            = azurerm_resource_group.test-rg1.location
  allocation_method   = "Dynamic"
}
resource "azurerm_network_interface" "test-Nic" {
  name                = "${var.azure_nic}"
  location            = azurerm_resource_group.test-rg1.location
  resource_group_name = azurerm_resource_group.test-rg1.name

  ip_configuration {
    name                          = "prodconfiguration1"
    subnet_id                     = azurerm_subnet.test-Subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pubip.id  
  }
}

resource "azurerm_virtual_machine" "test-Vm" {
  name                  = "${var.azure_vm}"
  location              = azurerm_resource_group.test-rg1.location
  resource_group_name   = azurerm_resource_group.test-rg1.name
  network_interface_ids = [azurerm_network_interface.test-Nic.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  # delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  # delete_data_disks_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }
  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "staging"
  }
}
