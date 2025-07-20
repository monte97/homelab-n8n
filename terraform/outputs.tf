# terraform/outputs.tf

output "container_id" {
  description = "Container ID"
  value       = proxmox_lxc.n8n_container.vmid
}

output "container_hostname" {
  description = "Container hostname"
  value       = proxmox_lxc.n8n_container.hostname
}

output "container_ip" {
  description = "Container IP address"
  value       = var.vm_ip_address
}

output "container_node" {
  description = "Proxmox node"
  value       = proxmox_lxc.n8n_container.target_node
}

output "container_status" {
  description = "Container status"
  value       = "deployed"
}

output "n8n_url" {
  description = "n8n web interface URL"
  value       = "http://${split("/", var.vm_ip_address)[0]}:5678"
}

output "ssh_connection" {
  description = "SSH connection string"
  value       = "ssh root@${split("/", var.vm_ip_address)[0]}"
}

output "container_resources" {
  description = "Container resource allocation"
  value = {
    cores  = var.vm_cores
    memory = "${var.vm_memory}MB"
    swap   = "${var.vm_swap}MB"
    disk   = var.vm_disk_size
  }
}

output "network_config" {
  description = "Network configuration"
  value = {
    ip_address = var.vm_ip_address
    gateway    = var.vm_gateway
    nameserver = var.vm_nameserver
    bridge     = var.vm_network_bridge
  }
}

output "ansible_inventory_data" {
  description = "Data for Ansible inventory"
  value = {
    hostname     = proxmox_lxc.n8n_container.hostname
    ansible_host = split("/", var.vm_ip_address)[0]
    ansible_user = "root"
  }
}