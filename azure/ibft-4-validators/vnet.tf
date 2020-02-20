
module "network" {
  source = "Azure/network/azurerm"
  version             = "~> 2.0"
  location = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  address_space = "${var.vnet_cidr}"
  subnet_names  = "${var.subnet_names}"
  subnet_prefixes  = "${var.subnets}"
  tags = {
    terraform = "true"
    vnet = "${var.vnet}"
  }
}

resource "azurerm_private_dns_zone" "idns" {
  name                = "${var.vnet}.${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
}

resource "azurerm_private_dns_zone_virtual_network_link" "idns_vnet_assoc" {
  name                  = "${var.vnet}.${var.location}_vnet_link"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  private_dns_zone_name = "${azurerm_private_dns_zone.idns.name}"
  virtual_network_id    = "${module.network.vnet_id}"
  registration_enabled  = "true"
}