provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "my-project" {
  name     = "prod-resources"
  location = "West Europe"
}

variable "prefix" {
  default = "tfvmex"
}

resource "azurerm_virtual_network" "prod" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.my-project.location
  resource_group_name = azurerm_resource_group.my-project.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.my-project.name
  virtual_network_name = azurerm_virtual_network.prod.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "for_vm" {
  name                = "acceptancePublicIp1"
  resource_group_name = azurerm_resource_group.my-project.name
  location            = azurerm_resource_group.my-project.location
  allocation_method   = "Dynamic"
}

output "public_ip_id"{
    value = azurerm_public_ip.for_vm.id
}

output "vm-public-ip"{
    value = azurerm_public_ip.for_vm.ip_address
}
resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.my-project.location
  resource_group_name = azurerm_resource_group.my-project.name

  ip_configuration {
    name                          = "ipconfiguration1"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.for_vm.id
  }
}


resource "azurerm_virtual_machine" "main" {
  name                  = "${var.prefix}-vm"
  location              = azurerm_resource_group.my-project.location
  resource_group_name   = azurerm_resource_group.my-project.name
  network_interface_ids = [azurerm_network_interface.main.id]
  vm_size               = "Standard_DS1_v2"

  # Uncomment this line to delete the OS disk automatically when deleting the VM
  delete_os_disk_on_termination = true

  # Uncomment this line to delete the data disks automatically when deleting the VM
  delete_data_disks_on_termination = true

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
    computer_name  = "ubuntu"
    admin_username = "ubuntu"
    admin_password = "root@123"
  }
  os_profile_linux_config {
    disable_password_authentication = false
  }
  tags = {
    environment = "prod"
  }
}


