#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"

  lifecycle {
    ignore_changes = [
      # Ignore changes to tags, e.g. because azure policies enabled in my subscription
      tags,
    ]
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/virtual_network
resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/subnet
resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_security_group
resource "azurerm_network_security_group" "example" {
  name                = "ssh_rule"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges     = [22, 80, 443]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface
resource "azurerm_network_interface" "example" {

  #https://www.terraform.io/language/meta-arguments/for_each
  #https://www.terraform.io/language/functions/toset
  for_each            = toset(var.vms)
  name                = "${each.value}-example-nic"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "${each.value}-ip-config-name"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
  }
}

#https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/cloudinit_config
#https://learn.microsoft.com/en-us/azure/virtual-machines/linux/tutorial-automate-vm-deployment#create-cloud-init-config-file
data "template_cloudinit_config" "webserverconfig" {
  gzip          = true
  base64_encode = true

  part {

    content_type = "text/cloud-config"
    content      = "packages: ['nginx']"
  }
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/linux_virtual_machine
resource "azurerm_linux_virtual_machine" "example" {
  for_each            = toset(var.vms)
  name                = "${each.value}-example-machine"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location

  #https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-b-series-burstable
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  admin_password                  = var.admin_password
  disable_password_authentication = false
  network_interface_ids           = [azurerm_network_interface.example[each.value].id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }

  custom_data = data.template_cloudinit_config.webserverconfig.rendered
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/public_ip
resource "azurerm_public_ip" "example" {
  name                = "PublicIPForLB"
  sku                 = "Standard"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  allocation_method   = "Static"
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb
resource "azurerm_lb" "example" {
  name                = "TestLoadBalancer"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  sku                 = "Standard"
  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.example.id
  }
}

resource "azurerm_lb_backend_address_pool" "backend_pool" {
  loadbalancer_id = azurerm_lb.example.id
  name            = "BackEndAddressPool"
}

resource "azurerm_network_interface_backend_address_pool_association" "example" {
  for_each             = toset(var.vms)
  network_interface_id = azurerm_network_interface.example[each.value].id

  #same as azurerm_network_interface.example.ipconfiguration.name
  ip_configuration_name   = "${each.value}-ip-config-name"
  backend_address_pool_id = azurerm_lb_backend_address_pool.backend_pool.id
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/lb_nat_rule

resource "azurerm_lb_rule" "ssh" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "SSH-VM"
  protocol                       = "Tcp"
  frontend_port                  = 1020
  backend_port                   = 22
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
}

resource "azurerm_lb_rule" "http" {
  loadbalancer_id                = azurerm_lb.example.id
  name                           = "HTTP-VM"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids        = [azurerm_lb_backend_address_pool.backend_pool.id]
}

#https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/network_interface_security_group_association
resource "azurerm_network_interface_security_group_association" "example" {
  for_each            = toset(var.vms)
  network_interface_id      = azurerm_network_interface.example[each.value].id
  network_security_group_id = azurerm_network_security_group.example.id
}

resource "azurerm_subnet_network_security_group_association" "corporate-production-nsg-assoc" {
  subnet_id                 = azurerm_subnet.example.id
  network_security_group_id = azurerm_network_security_group.example.id
}