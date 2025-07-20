# Homelab n8n Proxmox Automation

Automated deployment of n8n workflow automation platform on Proxmox LXC containers using OpenTofu/Terraform and Ansible for homelab environments.

## 🏗️ Architecture

- **Infrastructure as Code**: OpenTofu/Terraform for Proxmox infrastructure management
- **Configuration Management**: Ansible for container configuration and n8n deployment
- **Target Platform**: LXC Container on Proxmox VE
- **Network**: Direct access on local network with optional SSL/reverse proxy

## 📁 Project Structure

```
homelab-n8n-proxmox-automation/
├── README.md
├── .gitignore
├── terraform/                    # OpenTofu/Terraform configuration
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── terraform.tfvars.example
│   └── versions.tf
├── ansible/                      # Ansible playbooks and configuration
│   ├── inventory/
│   │   └── hosts.yml
│   └── playbooks/
│       └── n8n-setup.yml
└── scripts/                      # Utility scripts
    ├── deploy.sh
    └── destroy.sh

```

## 🚀 Quick Start

### Prerequisites

- Proxmox VE 7.x/8.x with API access configured
- OpenTofu 1.6+ or Terraform 1.5+
- Ansible 2.9+
- SSH access to Proxmox node
- Ubuntu 22.04 LXC template available on Proxmox

### 1. Clone Repository

```bash
git clone https://github.com/monte97/homelab-n8n.git
cd homelab-n8n
```

### 2. Configure Variables

#### Terraform Configuration

Copy the example variables file and customize it:

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
nano terraform/terraform.tfvars
```

**Required Variables:**

```hcl
# Proxmox API Configuration
proxmox_api_url          = "https://192.168.1.100:8006/api2/json"
proxmox_api_token_id     = "root@pam!terraform"
proxmox_api_token_secret = "your-secret-token-here"
proxmox_node             = "pve"

# Container Configuration
vm_id           = 200
vm_name         = "n8n-prod"
vm_memory       = 2048
vm_cores        = 2
vm_storage      = "local-lvm"
vm_disk_size    = "20G"

# Network Configuration
vm_ip_address   = "192.168.1.50/24"
vm_gateway      = "192.168.1.1"
vm_nameserver   = "192.168.1.1"

# Template
template_name   = "ubuntu-22.04-standard_22.04-1_amd64.tar.zst"

# SSH Configuration (optional, but recommended)
ssh_public_keys = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAAB... your-key-here"
ssh_private_key = "~/.ssh/id_rsa"
```

**Variable Descriptions:**

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `proxmox_api_url` | Proxmox API endpoint URL | - | Yes |
| `proxmox_api_token_id` | API token identifier | - | Yes |
| `proxmox_api_token_secret` | API token secret | - | Yes |
| `proxmox_node` | Target Proxmox node name | `"pve"` | Yes |
| `vm_id` | Container ID (100-999999) | `200` | No |
| `vm_name` | Container hostname | `"n8n-prod"` | No |
| `vm_cores` | CPU cores (1-16) | `2` | No |
| `vm_memory` | RAM in MB (512-16384) | `2048` | No |
| `vm_storage` | Storage pool name | `"local-lvm"` | No |
| `vm_disk_size` | Root filesystem size | `"20G"` | No |
| `vm_data_disk_size` | Data volume size | `"10G"` | No |
| `vm_ip_address` | Static IP with CIDR | `"192.168.1.50/24"` | Yes |
| `vm_gateway` | Default gateway | `"192.168.1.1"` | Yes |
| `vm_nameserver` | DNS server | `"192.168.1.1"` | No |
| `template_name` | LXC template filename | ubuntu-22.04 template | Yes |
| `ssh_public_keys` | SSH public keys for root | `""` | No |
| `enable_firewall` | Enable Proxmox firewall | `true` | No |

### 3. Setup Proxmox API Token

Create an API token in Proxmox:

1. Login to Proxmox web interface
2. Go to **Datacenter** > **Permissions** > **API Tokens**
3. Click **Add** and create a token with:
   - **Token ID**: `terraform`
   - **User**: `root@pam`
   - **Privilege Separation**: Unchecked
4. Copy the generated token secret

### 4. Prepare SSH Keys

Generate SSH key pair if you don't have one:

```bash
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N ""
```

Add your public key to the terraform configuration:

```bash
echo "ssh_public_keys = \"$(cat ~/.ssh/id_rsa.pub)\"" >> terraform/terraform.tfvars
```

### 5. Bootstrap Deployment

Run the automated bootstrap script:

```bash
chmod +x scripts/bootstrap.sh
./scripts/bootstrap.sh
```

Or deploy manually:

```bash
# 1. Initialize and apply infrastructure
cd terraform
tofu init
tofu plan
tofu apply

# 2. Configure and deploy n8n
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/site.yml
```