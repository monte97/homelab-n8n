# terraform/variables.tf

# Proxmox configuration
variable "proxmox_api_url" {
  description = "Proxmox API URL"
  type        = string
}

variable "proxmox_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
}

variable "proxmox_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "proxmox_node" {
  description = "Proxmox node name"
  type        = string
  default     = "pve"
}

variable "proxmox_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
  default     = true
}

variable "proxmox_debug" {
  description = "Enable debug logging"
  type        = bool
  default     = false
}

# Container configuration
variable "vm_id" {
  description = "Container ID"
  type        = number
  default     = 200
  
  validation {
    condition     = var.vm_id >= 100 && var.vm_id <= 999999
    error_message = "VM ID must be between 100 and 999999."
  }
}

variable "vm_name" {
  description = "Container hostname"
  type        = string
  default     = "n8n-prod"
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.vm_name))
    error_message = "VM name must be a valid hostname."
  }
}

variable "vm_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
  
  validation {
    condition     = var.vm_cores >= 1 && var.vm_cores <= 16
    error_message = "Cores must be between 1 and 16."
  }
}

variable "vm_memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
  
  validation {
    condition     = var.vm_memory >= 512 && var.vm_memory <= 16384
    error_message = "Memory must be between 512MB and 16GB."
  }
}

variable "vm_swap" {
  description = "Swap in MB"
  type        = number
  default     = 512
}

variable "vm_storage" {
  description = "Storage pool name"
  type        = string
  default     = "local-lvm"
}

variable "vm_disk_size" {
  description = "Root filesystem size"
  type        = string
  default     = "20G"
}

variable "vm_data_disk_size" {
  description = "Data disk size for n8n"
  type        = string
  default     = "10G"
}

variable "vm_unprivileged" {
  description = "Run as unprivileged container"
  type        = bool
  default     = true
}

variable "vm_onboot" {
  description = "Start container on boot"
  type        = bool
  default     = true
}

variable "vm_start" {
  description = "Start container after creation"
  type        = bool
  default     = true
}

variable "vm_enable_nesting" {
  description = "Enable nesting (required for Docker)"
  type        = bool
  default     = true
}

# Network configuration
variable "vm_network_bridge" {
  description = "Network bridge"
  type        = string
  default     = "vmbr0"
}

variable "vm_ip_address" {
  description = "Static IP address with CIDR notation"
  type        = string
  default     = "192.168.1.50/24"
  
  validation {
    condition     = can(cidrhost(var.vm_ip_address, 0))
    error_message = "IP address must be in CIDR notation (e.g., 192.168.1.50/24)."
  }
}

variable "vm_gateway" {
  description = "Default gateway"
  type        = string
  default     = "192.168.1.1"
}

variable "vm_nameserver" {
  description = "DNS nameserver"
  type        = string
  default     = "192.168.1.1"
}

# Template configuration
variable "template_name" {
  description = "LXC template name"
  type        = string
  default     = "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
}

# SSH configuration
variable "ssh_public_keys" {
  description = "SSH public keys for root user"
  type        = string
  default     = ""
}

variable "ssh_private_key" {
  description = "Path to SSH private key for provisioning"
  type        = string
  default     = "~/.ssh/id_rsa"
}

# Security configuration
variable "enable_firewall" {
  description = "Enable Proxmox firewall rules"
  type        = bool
  default     = true
}

variable "vm_tags" {
  description = "Tags for the container"
  type        = string
  default     = "n8n;automation;homelab"
}

# Environment configuration
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "homelab"
  
  validation {
    condition     = contains(["dev", "staging", "prod", "homelab"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod, homelab."
  }
}