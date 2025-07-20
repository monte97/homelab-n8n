# terraform/main.tf

terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "~> 2.9"
    }
  }
  required_version = ">= 1.0"
}

# Provider configuration
provider "proxmox" {
  pm_api_url      = var.proxmox_api_url
  pm_api_token_id = var.proxmox_api_token_id
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = var.proxmox_tls_insecure
  pm_debug        = var.proxmox_debug
}

# LXC Container for n8n
resource "proxmox_lxc" "n8n_container" {
  target_node     = var.proxmox_node
  hostname        = var.vm_name
  vmid            = var.vm_id
  description     = "n8n Workflow Automation Container"
  
  # Template and OS
  ostemplate      = "local:vztmpl/${var.template_name}"
  ostype          = "ubuntu"
  arch            = "amd64"
  
  # Container configuration
  cores           = var.vm_cores
  memory          = var.vm_memory
  swap            = var.vm_swap
  
  # Enable features
  unprivileged    = var.vm_unprivileged
  onboot          = var.vm_onboot
  start           = var.vm_start
  protection      = false
  
  # SSH key configuration
  ssh_public_keys = var.ssh_public_keys != "" ? var.ssh_public_keys : null
  
  # Root filesystem
  rootfs {
    storage = var.vm_storage
    size    = var.vm_disk_size
  }
  
  # Additional storage for n8n data
  mountpoint {
    key     = "0"
    slot    = 0
    storage = var.vm_storage
    mp      = "/opt/n8n"
    size    = var.vm_data_disk_size
  }
  
  # Network configuration
  network {
    name   = "eth0"
    bridge = var.vm_network_bridge
    ip     = var.vm_ip_address
    gw     = var.vm_gateway
    type   = "veth"
  }
  
  # DNS configuration
  nameserver = var.vm_nameserver
  
  # Enable nesting for Docker
  features {
    nesting = var.vm_enable_nesting
  }
  
  # Lifecycle management
  lifecycle {
    ignore_changes = [
      # Ignora cambi di template per evitare ricreazione
      ostemplate,
    ]
  }
  
  # Wait for network to be ready
  provisioner "remote-exec" {
    inline = [
      "sleep 10",
      "apt-get update",
      "apt-get install -y curl wget gnupg lsb-release python3 python3-pip",
      "systemctl enable ssh",
      "systemctl start ssh"
    ]
    
    connection {
      type        = "ssh"
      user        = "root"
      host        = split("/", var.vm_ip_address)[0]
      private_key = var.ssh_private_key != "" ? file(var.ssh_private_key) : null
      timeout     = "5m"
    }
  }
  
  tags = var.vm_tags
}
