/*
    DESCRIPTION:
    Terraform cloning VMs for K8S cluster, via Kubeadm on vSphere 8
    Last update: 09/01/2024 by MAIRIEN Anthony
    Website: https://blog.tips4tech.fr
*/

// To be able to get the build time
locals {
  buildtime = formatdate("YYYY-MM-DD hh:mm ZZZ", timestamp())
}

// vSphere vCenter credentials.

provider "vsphere" {
  user           = var.vsphere_username
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  allow_unverified_ssl = true
}

// vSphere provider configuration  

variable "vsphere_username" {
  description = "Username for vSphere connection."
  type        = string
}

variable "vsphere_password" {
  description = "Password for vSphere user. This is sensitive."
  type        = string
  sensitive   = true
}

variable "vsphere_server" {
  description = "URL of the vCenter/VCSA server."
  type        = string
}

variable "clone_count" {
  description = "Number of VMs to clone"
  type        = number
}

variable "vm_names" {
  description = "List of hostnames for each VM"
  type        = list(string)
}

variable "vm_ips" {
  description = "List of IP addresses for each VM"
  type        = list(string)
}

variable "vm_gateway_ip" {
  description = "Gateway IPv4 for the VMs"
  type        = string
}

variable "template_name" {
  description = "vSphere template to clone for VM creation."
  type        = string
}

variable "datacenter" {
  description = "The name of the vSphere datacenter."
  type        = string
}

variable "datastore" {
  description = "Datastore where the VMs will be created."
  type        = string
}

variable "network" {
  description = "Network to assign to the VMs. It must be a valid vSphere network."
  type        = string
}

variable "cluster" {
  description = "The vSphere cluster where the VMs will be deployed."
  type        = string
}

variable "guest_os" {
  description = "The guest OS type for the VMs. For example, 'ubuntu64Guest' for Ubuntu."
  type        = string
}

variable "script_path" {
  description = "Path to the script that installs additional packages, like Docker and htop."
  type        = string
}

variable "ssh_user" {
  description = "SSH user for connecting to the VMs after provisioning."
  type        = string
}

variable "ssh_password" {
  description = "SSH password for the VMs. This is sensitive."
  type        = string
  sensitive   = true
}

// vSphere Resources Configuration
// These data sources retrieve information about the resources in your vSphere environment,
// such as datacenter, datastore, compute cluster, network, and template. These resources are
// later used to clone VMs.

data "vsphere_datacenter" "dc" {
  name = var.datacenter
}

data "vsphere_datastore" "datastore" {
  name          = var.datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_compute_cluster" "cluster" {
  name          = var.cluster
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_network" "network" {
  name          = var.network
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_virtual_machine" "template" {
  name          = var.template_name
  datacenter_id = data.vsphere_datacenter.dc.id
}

// VM Creation Configuration
// This block creates the virtual machines based on the clone count specified.
// It clones the template, customizes the VMs with network settings, and runs a script
// to install additional packages.

resource "vsphere_virtual_machine" "vm" {
  count             = var.clone_count
  name              = "${var.vm_names[count.index]}"
  resource_pool_id  = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id      = data.vsphere_datastore.datastore.id
  num_cpus          = 1
  memory            = 1024
  guest_id          = var.guest_os
  annotation        = "Terraform generated VM on ${local.buildtime} - tips4tech.fr"
  network_interface {
    network_id   = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = 50  
    thin_provisioned = true  
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    customize {
      linux_options {
        host_name = var.vm_names[count.index]
        domain    = "tips4tech.local"
      }
      
      network_interface {
        ipv4_address = var.vm_ips[count.index]
        ipv4_netmask = 24
      }
      ipv4_gateway = var.vm_gateway_ip
    }
  }

    provisioner "file" {
      source      = "scripts/setup.sh"
      destination = "/tmp/setup.sh"
    }

    provisioner "remote-exec" {
      inline = [
        "chmod +x /tmp/setup.sh",
        "/tmp/setup.sh",
      ]
    }

    connection {
      type     = "ssh"
      user     = var.ssh_user
      password = var.ssh_password
      host     = var.vm_ips[count.index]
      timeout  = "5m"
    }
  }