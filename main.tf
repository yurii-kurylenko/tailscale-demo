terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
    }
  }
}

variable "hetzner_cloud_api_token" {  }
variable "hetzner_cloud_server_type" { default = "cx22" }
variable "hetzner_cloud_server_location" { default = "hel1" }
variable "hetzner_cloud_ssh_key_name" { }
variable "root_password" { }
  
provider "hcloud" { token = var.hetzner_cloud_api_token }

data "hcloud_ssh_key" "server_key" {
  name = var.hetzner_cloud_ssh_key_name
}

resource "hcloud_network" "network" {
  name     = "network"
  ip_range = "10.0.0.0/16"
}

resource "hcloud_network_subnet" "network-subnet" {
  type         = "cloud"
  network_id   = hcloud_network.network.id
  network_zone = "eu-central"
  ip_range     = "10.0.1.0/24"
}

resource "hcloud_firewall" "ts-firewall" {
  name = "ts-firewall"
  rule {
    direction = "in"
    protocol  = "icmp"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }

  rule {
    direction = "in"
    protocol  = "tcp"
    port      = "22"
    source_ips = [
      "0.0.0.0/0",
      "::/0"
    ]
  }
}

resource "hcloud_server" "warsaw" {
  name        = "warsaw"
  image       = "debian-12"
  server_type = var.hetzner_cloud_server_type
  location    = var.hetzner_cloud_server_location
  ssh_keys    = [var.hetzner_cloud_ssh_key_name]
  network {
    network_id = hcloud_network.network.id
    ip         = "10.0.1.4"
  }

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}

resource "hcloud_server" "kyiv" {
  name        = "kyiv"
  image       = "debian-12"
  server_type = var.hetzner_cloud_server_type
  location    = var.hetzner_cloud_server_location
  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
  network {
    network_id = hcloud_network.network.id
    ip         = "10.0.1.5"
  }
  depends_on = [
    hcloud_network_subnet.network-subnet
  ]
  user_data = <<-EOF
    #!/bin/bash
    echo "root:${var.root_password}" | chpasswd
  EOF
}


output "warsaw_server_public_ip" {
  value = hcloud_server.warsaw.ipv4_address
}

output "kyiv_server_public_ip" {
  value = hcloud_server.kyiv.ipv4_address
}
