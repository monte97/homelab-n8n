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
│   │   ├── hosts.yml
│   │   └── group_vars/
│   │       └── all.yml
│   ├── playbooks/
│   │   ├── site.yml
│   │   ├── n8n-setup.yml
│   │   └── post-install.yml
│   ├── roles/
│   │   ├── common/
│   │   ├── docker/
│   │   └── n8n/
│   └── ansible.cfg
├── scripts/                      # Utility scripts
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
git clone https://github.com/yourusername/homelab-n8n-proxmox-automation.git
cd homelab-n8n-proxmox-automation
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

#### Ansible Configuration

Configure Ansible variables:

```bash
mkdir -p ansible/inventory/group_vars
nano ansible/inventory/group_vars/all.yml
```

**Ansible Variables:**

```yaml
# n8n Configuration
n8n_version: "1.15.1"
n8n_port: 5678
n8n_domain: "n8n.homelab.local"

# Database Configuration
n8n_database_type: "sqlite"  # or "postgres"
n8n_database_sqlite_file: "/opt/n8n/data/database.sqlite"

# Security
n8n_encryption_key: "{{ vault_n8n_encryption_key | default('change-me-to-secure-random-string') }}"

# SSL Configuration (optional)
enable_ssl: false
ssl_cert_path: "/opt/n8n/ssl/cert.pem"
ssl_key_path: "/opt/n8n/ssl/key.pem"

# Backup Configuration
backup_enabled: true
backup_path: "/opt/n8n/backups"
backup_retention_days: 7

# Docker Configuration
docker_compose_version: "2.21.0"
docker_data_root: "/opt/docker"
```

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

## ⚙️ Advanced Configuration

### Database Configuration

#### SQLite (Default)
```yaml
n8n_database_type: "sqlite"
n8n_database_sqlite_file: "/opt/n8n/data/database.sqlite"
```

#### PostgreSQL
```yaml
n8n_database_type: "postgres"
n8n_database_postgres_host: "192.168.1.10"
n8n_database_postgres_port: 5432
n8n_database_postgres_database: "n8n"
n8n_database_postgres_username: "n8n_user"
n8n_database_postgres_password: "{{ vault_postgres_password }}"
```

### SSL/TLS Configuration

#### Self-signed Certificate
```yaml
enable_ssl: true
ssl_type: "self-signed"
ssl_country: "US"
ssl_state: "California"
ssl_city: "San Francisco"
ssl_org: "Homelab"
ssl_cn: "{{ n8n_domain }}"
```

#### Let's Encrypt
```yaml
enable_ssl: true
ssl_type: "letsencrypt"
letsencrypt_email: "admin@yourdomain.com"
letsencrypt_staging: false
```

### Firewall Configuration

```yaml
firewall_rules:
  - port: 22
    protocol: tcp
    comment: "SSH"
  - port: 5678
    protocol: tcp
    comment: "n8n Web Interface"
  - port: 443
    protocol: tcp
    comment: "HTTPS"
```

### Backup Configuration

```yaml
backup_enabled: true
backup_schedule: "0 2 * * *"  # Daily at 2 AM
backup_retention_days: 30
backup_encrypt: true
backup_encryption_key: "{{ vault_backup_key }}"
backup_remote_enabled: false
backup_remote_type: "s3"  # s3, sftp, rsync
```

## 🔧 Features

### Infrastructure (OpenTofu/Terraform)
- ✅ Automated LXC container creation
- ✅ Static network configuration
- ✅ Resource allocation (CPU, RAM, Storage)
- ✅ Persistent volume mounting
- ✅ Firewall rule configuration
- ✅ SSH key injection

### Configuration (Ansible)
- ✅ Docker and Docker Compose installation
- ✅ Optimized n8n setup with persistent data
- ✅ SSL/TLS configuration (self-signed or Let's Encrypt)
- ✅ Automated backup setup
- ✅ Firewall configuration
- ✅ Health monitoring
- ✅ Update automation

### Utility Scripts
- ✅ One-command bootstrap
- ✅ Automated deployment
- ✅ Backup and restore functionality
- ✅ n8n version updates
- ✅ Infrastructure cleanup

## 🌐 Access

After deployment, n8n will be accessible at:

- **HTTP**: `http://192.168.1.50:5678`
- **HTTPS**: `https://n8n.homelab.local` (if SSL configured)
- **SSH**: `ssh root@192.168.1.50`

Default credentials will be displayed after first setup or can be found in `/opt/n8n/data/credentials.txt`.

## 🔒 Security Features

- Container isolation with minimal privileges
- Firewall rules for required ports only
- SSL/TLS encryption support
- Encrypted backups with retention policies
- SSH key-based authentication
- Optional reverse proxy integration (Traefik/Nginx)
- Ansible Vault for sensitive data

## 📋 Management Commands

```bash
# Check deployment status
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags status

# Create manual backup
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags backup

# Update n8n version
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags update

# Restart services
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags restart

# View logs
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags logs

# Restore from backup
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags restore -e backup_file=backup-2024-01-01.tar.gz
```

## 🚨 Troubleshooting

### Common Issues

**Container won't start:**
```bash
# Check Proxmox logs
tail -f /var/log/pve/tasks/active

# Check container status
pct status 200
pct start 200
```

**Network connectivity issues:**
```bash
# Test from Proxmox host
ping 192.168.1.50

# Check container network config
pct exec 200 -- ip addr show
```

**n8n service issues:**
```bash
# Check service status
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags status

# View service logs
docker logs n8n
```

### Updating Configuration

To update configuration after initial deployment:

```bash
# Update infrastructure
cd terraform
tofu plan
tofu apply

# Update application configuration
cd ../ansible
ansible-playbook -i inventory/hosts.yml playbooks/site.yml --tags config
```

## 📦 Backup and Restore

### Automated Backups

Backups run automatically based on the configured schedule and include:
- n8n database and configuration
- Docker volumes and data
- SSL certificates
- Application logs

### Manual Backup

```bash
# Create immediate backup
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags backup
```

### Restore Process

```bash
# List available backups
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags list-backups

# Restore from specific backup
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags restore \
  -e backup_file="n8n-backup-2024-01-15-02-00.tar.gz"
```

## 🔄 Updates and Maintenance

### Updating n8n

```bash
# Update to latest version
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags update

# Update to specific version
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags update \
  -e n8n_version="1.16.0"
```

### System Maintenance

```bash
# Update system packages
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags system-update

# Clean up old Docker images
ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags cleanup
```

## 🤝 Contributing

This is a personal homelab project, but suggestions and improvements are welcome! Please feel free to:

- Report issues
- Suggest enhancements
- Submit pull requests
- Share your configurations

## 📝 License

MIT License - see [LICENSE](LICENSE) for details.

## ⚠️ Disclaimer

This project is designed for homelab/personal use. For production environments, consider additional security hardening, monitoring, and high-availability configurations.

---

**Happy Automating! 🚀**