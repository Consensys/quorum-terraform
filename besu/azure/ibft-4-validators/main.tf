
provider "azurerm" {
  version = "~> 1.44"
  subscription_id = "${var.subscription_id}"
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.vnet}-${var.location}-rg"
  location = "${var.location}"
  tags = {
    terraform = "true"
    vpc = "${var.vnet}"
  }
}

resource "azurerm_storage_account" "storageaccount" {
  depends_on          = [azurerm_resource_group.rg]
  # name can only consist of lowercase letters and numbers, and must be between 3 and 24 characters long
  name                = "${var.vnet}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  location            = "${var.location}"
  account_tier        = "Standard"
  account_replication_type    = "LRS"
  tags = {
    terraform = "true"
    vpc = "${var.vnet}"
  }
}

resource "azurerm_network_security_group" "monitoring_nsg" {
  name                = "${var.vnet}_monitoring_nsg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"
  security_rule {
    name                       = "ssh"
    priority                   = 2001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "prometheus"
    priority                   = 2002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9090"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "grafana"
    priority                   = 2003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3000"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_public_ip" "monitoring_public_ip" {
  name                        = "monitoring_public_ip"
  location                    = "${var.location}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  allocation_method           = "Dynamic"
  domain_name_label           = "${var.vnet}-monitoring"
}

resource "azurerm_network_interface" "monitoring_nic" {
  depends_on                = [azurerm_private_dns_zone_virtual_network_link.idns_vnet_assoc]
  name                      = "monitoring_nic"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.monitoring_nsg.id}"

  ip_configuration {
    name                          = "monitoring_nic_config"
    subnet_id                     = "${module.network.vnet_subnets[0]}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.monitoring_public_ip.id}"
  }
}

resource "azurerm_virtual_machine" "monitoring" {
  depends_on            = [azurerm_private_dns_zone_virtual_network_link.idns_vnet_assoc]
  name                  = "${var.vnet}-monitoring"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = [azurerm_network_interface.monitoring_nic.id]
  vm_size               = "${var.light_instance_type}"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  identity {
    type = "SystemAssigned"
  }

  storage_os_disk {
    name              = "monitoring-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "40"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "monitoring"
    admin_username = "${var.login_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.login_user}/.ssh/authorized_keys"
      key_data = "${var.login_ssh_public_key}"
    }
  }

  connection {
    type = "ssh"
    port = 22
    agent = false
    user = "${var.login_user}"
    host = "${azurerm_public_ip.monitoring_public_ip.fqdn}"
    private_key = "${file(var.login_ssh_private_key_path)}"
  }

  provisioner "file" {
    source = "../files/monitoring"
    destination = "$HOME"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add - ",
      "sudo sh -c 'echo \"deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable\" > /etc/apt/sources.list.d/docker.list'",
      "sudo apt-get update && sudo apt-get -y install docker-ce",
      "sudo usermod -aG docker $USER",
      "sudo curl -L https://github.com/docker/compose/releases/download/1.24.1/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose",
      "sudo chmod +x /usr/local/bin/docker-compose",
      "sudo sh $HOME/monitoring/setup.sh ${var.location} ${var.login_user} ${var.subscription_id} ",
      "sleep 30",
    ]
  }
}

resource "azurerm_role_assignment" "monitoring_vm_managed_identity" {
  scope              = "${azurerm_resource_group.rg.id}"
  role_definition_name = "Monitoring Reader"
  principal_id       = "${lookup(azurerm_virtual_machine.monitoring.identity[0], "principal_id")}"
}


resource "azurerm_network_security_group" "eth_nsg" {
  name                = "${var.vnet}_eth_nsg"
  location            = "${var.location}"
  resource_group_name = "${azurerm_resource_group.rg.name}"

  security_rule {
    name                       = "ssh"
    priority                   = 2001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "rpc"
    priority                   = 2002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8545"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ws"
    priority                   = 2003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8546"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "gql"
    priority                   = 2004
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8547"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "p2p-tcp"
    priority                   = 2005
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "30303"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "p2p-udp"
    priority                   = 2006
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "30303"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "metrics"
    priority                   = 2007
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "9545"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "metrics-node-exporter"
    priority                   = 2008
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Udp"
    source_port_range          = "*"
    destination_port_range     = "9100"
    source_address_prefix      = "${var.vnet_cidr}"
    destination_address_prefix = "*"
  }
}

## Bootnode

resource "azurerm_public_ip" "bootnode_public_ip" {
  name                        = "bootnode_public_ip"
  location                    = "${var.location}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  allocation_method           = "Dynamic"
  domain_name_label           = "${var.vnet}-bootnode"
}

resource "azurerm_network_interface" "bootnode_nic" {
  depends_on                = [azurerm_private_dns_zone_virtual_network_link.idns_vnet_assoc]
  name                      = "bootnode_nic"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.eth_nsg.id}"

  ip_configuration {
    name                          = "bootnode_nic_config"
    subnet_id                     = "${module.network.vnet_subnets[0]}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.bootnode_public_ip.id}"
  }
}

resource "azurerm_virtual_machine" "bootnode" {
  depends_on            = [azurerm_private_dns_zone_virtual_network_link.idns_vnet_assoc]
  name                  = "${var.vnet}-bootnode"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = [azurerm_network_interface.bootnode_nic.id]
  vm_size               = "${var.node_instance_type}"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "bootnode-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "40"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "bootnode"
    admin_username = "${var.login_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.login_user}/.ssh/authorized_keys"
      key_data = "${var.login_ssh_public_key}"
    }
  }

  connection {
    type = "ssh"
    port = 22
    agent = false
    user = "${var.login_user}"
    host = "${azurerm_public_ip.bootnode_public_ip.fqdn}"
    private_key = "${file(var.login_ssh_private_key_path)}"
  }

  provisioner "file" {
    source = "../files/besu"
    destination = "$HOME"
  }

  provisioner "file" {
    source = "files/besu_ibft/besu.yml"
    destination = "$HOME/besu/besu.yml"
  }

  provisioner "file" {
    source = "files/besu_ibft/ibft.json"
    destination = "$HOME/besu/ibft.json"
  }

  provisioner "file" {
    source = "files/besu_ibft/bootnode"
    destination = "$HOME/besu/node_db/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.besu_download_url}' '${azurerm_network_interface.bootnode_nic.private_ip_address}'",
      "sleep 30",
    ]
  }

}

## Nodes

resource "azurerm_public_ip" "node_public_ip" {
  count                = "${var.node_count}"
  name                 = "node${count.index}_public_ip"
  location             = "${var.location}"
  resource_group_name  = "${azurerm_resource_group.rg.name}"
  allocation_method    = "Dynamic"
  domain_name_label    = "${var.vnet}-node${count.index}"
}

resource "azurerm_network_interface" "node_nic" {
  depends_on                = [azurerm_public_ip.node_public_ip]
  count                     = "${var.node_count}"
  name                      = "node${count.index}_nic"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.eth_nsg.id}"
  ip_configuration {
    name                          = "node${count.index}_nic_config"
    subnet_id                     = "${module.network.vnet_subnets[0]}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${element(azurerm_public_ip.node_public_ip.*.id, count.index )}"
  }
}

resource "azurerm_virtual_machine" "nodes" {
  depends_on            = [azurerm_private_dns_zone_virtual_network_link.idns_vnet_assoc, azurerm_virtual_machine.bootnode]
  count                 = "${var.node_count}"
  name                  = "${var.vnet}-node${count.index}"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = ["${element(azurerm_network_interface.node_nic.*.id, count.index)}"]
  vm_size               = "${var.node_instance_type}"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "node${count.index}-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "40"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "node${count.index}"
    admin_username = "${var.login_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.login_user}/.ssh/authorized_keys"
      key_data = "${var.login_ssh_public_key}"
    }
  }

  connection {
    type = "ssh"
    port = 22
    agent = false
    user = "${var.login_user}"
    host = "${element(azurerm_public_ip.node_public_ip.*.fqdn, count.index)}"
    private_key = "${file(var.login_ssh_private_key_path)}"
  }

  provisioner "file" {
    source = "../files/besu"
    destination = "$HOME"
  }

  provisioner "file" {
    source = "files/besu_ibft/besu.yml"
    destination = "$HOME/besu/besu.yml"
  }

  provisioner "file" {
    source = "files/besu_ibft/ibft.json"
    destination = "$HOME/besu/ibft.json"
  }

  provisioner "file" {
    source = "files/besu_ibft/node-${count.index}"
    destination = "$HOME/besu/node_db/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.besu_download_url}' '${azurerm_network_interface.bootnode_nic.private_ip_address}'",
      "sleep 30",
    ]
  }

}


## Rpc node
resource "azurerm_public_ip" "rpcnode_public_ip" {
  name                        = "rpcnode_public_ip"
  location                    = "${var.location}"
  resource_group_name         = "${azurerm_resource_group.rg.name}"
  allocation_method           = "Dynamic"
  domain_name_label           = "${var.vnet}-rpcnode"
}

resource "azurerm_network_interface" "rpcnode_nic" {
  depends_on                = [azurerm_private_dns_zone_virtual_network_link.idns_vnet_assoc]
  name                      = "rpcnode_nic"
  location                  = "${var.location}"
  resource_group_name       = "${azurerm_resource_group.rg.name}"
  network_security_group_id = "${azurerm_network_security_group.eth_nsg.id}"

  ip_configuration {
    name                          = "rpcnode_nic_config"
    subnet_id                     = "${module.network.vnet_subnets[0]}"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = "${azurerm_public_ip.rpcnode_public_ip.id}"
  }
}


resource "azurerm_virtual_machine" "rpcnode" {
  depends_on            = [azurerm_private_dns_zone_virtual_network_link.idns_vnet_assoc, azurerm_virtual_machine.bootnode]
  name                  = "${var.vnet}-rpcnode"
  location              = "${var.location}"
  resource_group_name   = "${azurerm_resource_group.rg.name}"
  network_interface_ids = [azurerm_network_interface.rpcnode_nic.id]
  vm_size               = "${var.node_instance_type}"
  delete_os_disk_on_termination = true
  delete_data_disks_on_termination = true

  storage_os_disk {
    name              = "rpcnode-osdisk"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Premium_LRS"
    disk_size_gb      = "40"
  }

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  os_profile {
    computer_name  = "rpcnode"
    admin_username = "${var.login_user}"
  }

  os_profile_linux_config {
    disable_password_authentication = true
    ssh_keys {
      path     = "/home/${var.login_user}/.ssh/authorized_keys"
      key_data = "${var.login_ssh_public_key}"
    }
  }

  connection {
    type = "ssh"
    port = 22
    agent = false
    user = "${var.login_user}"
    host = "${azurerm_public_ip.rpcnode_public_ip.fqdn}"
    private_key = "${file(var.login_ssh_private_key_path)}"
  }

  provisioner "file" {
    source = "../files/besu"
    destination = "$HOME"
  }

  provisioner "file" {
    source = "files/besu_ibft/besu.yml"
    destination = "$HOME/besu/besu.yml"
  }

  provisioner "file" {
    source = "files/besu_ibft/ibft.json"
    destination = "$HOME/besu/ibft.json"
  }

  provisioner "file" {
    source = "files/besu_ibft/rpcnode"
    destination = "$HOME/besu/node_db/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update && sudo apt-get install -y apparmor apt-transport-https ca-certificates curl build-essential openjdk-11-jdk python3 python3-setuptools python3-pip python3-dev python3-virtualenv python3-venv virtualenv",
      "sudo sh $HOME/besu/setup.sh '${var.besu_version}' '${var.besu_download_url}' '${azurerm_network_interface.bootnode_nic.private_ip_address}'",
      "sleep 30",
    ]
  }

}