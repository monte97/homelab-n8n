#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print informational status messages
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to print success messages
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Function to print warning messages
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to print error messages
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    print_status "Checking prerequisites..."
    
    # Check for Terraform/OpenTofu
    if ! command -v tofu &> /dev/null && ! command -v terraform &> /dev/null; then
        print_error "OpenTofu or Terraform not found. Please install one of them:"
        echo "  - OpenTofu: https://opentofu.org/docs/intro/install/"
        echo "  - Terraform: https://www.terraform.io/downloads"
        exit 1
    fi
    
    # Check for Ansible
    if ! command -v ansible &> /dev/null; then
        print_error "Ansible not found. Install it with:"
        echo "  Ubuntu/Debian: sudo apt install ansible"
        echo "  RHEL/CentOS: sudo yum install ansible"
        echo "  macOS: brew install ansible"
        exit 1
    fi
    
    print_success "All prerequisites are met"
}

# Setup initial configuration
setup_config() {
    print_status "Setting up initial configuration..."
    
    # Create terraform.tfvars if it doesn't exist
    if [ ! -f "terraform/terraform.tfvars" ]; then
        if [ -f "terraform/terraform.tfvars.example" ]; then
            cp terraform/terraform.tfvars.example terraform/terraform.tfvars
            print_warning "Created terraform/terraform.tfvars from example. MODIFY THE VALUES!"
        else
            print_error "File terraform.tfvars.example not found"
            exit 1
        fi
    fi
    
    # Create inventory file if it doesn't exist
    if [ ! -f "ansible/inventory/hosts.yml" ]; then
        mkdir -p ansible/inventory
        cat > ansible/inventory/hosts.yml << 'EOF'
all:
  children:
    n8n:
      hosts:
        n8n-prod:
          ansible_host: 192.168.0.8 # CHANGE THIS TO YOUR VM IP
          ansible_user: root
          ansible_ssh_private_key_file: ~/.ssh/id_ed25519_n88-homelab # ENSURE THIS PATH IS CORRECT
EOF
        print_warning "Created ansible/inventory/hosts.yml with default values. VERIFY THE VALUES!"
    fi
    
    print_success "Base configuration created"
}

# Initialize Terraform/OpenTofu
init_terraform() {
    print_status "Initializing Terraform/OpenTofu..."
    
    cd terraform
    
    # Determine which command to use (tofu or terraform)
    if command -v tofu &> /dev/null; then
        TERRAFORM_CMD="tofu"
    else
        TERRAFORM_CMD="terraform"
    fi
    
    $TERRAFORM_CMD init
    print_success "Terraform/OpenTofu initialized"
    
    cd ..
}

# Deploy infrastructure
deploy_infrastructure() {
    print_status "Deploying Proxmox infrastructure..."
    
    cd terraform
    
    # Determine which command to use (tofu or terraform)
    if command -v tofu &> /dev/null; then
        TERRAFORM_CMD="tofu"
    else
        TERRAFORM_CMD="terraform"
    fi
    
    echo -e "\n${YELLOW}=== TERRAFORM PLAN ===${NC}"
    $TERRAFORM_CMD plan
    
    echo -e "\n${BLUE}Do you want to proceed with the infrastructure deployment? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        $TERRAFORM_CMD apply -auto-approve
        print_success "Infrastructure deployed successfully"
    else
        print_warning "Infrastructure deployment cancelled"
        exit 0
    fi
    
    cd ..
}

# Wait for container to be ready
wait_container_ready() {
    print_status "Waiting for the container to be ready..."
    
    # Extract IP from terraform output
    cd terraform
    # Determine which command to use (tofu or terraform)
    if command -v tofu &> /dev/null; then
        TERRAFORM_CMD="tofu"
    else
        TERRAFORM_CMD="terraform"
    fi
    
    CONTAINER_IP=$($TERRAFORM_CMD output -raw container_ip | cut -d'/' -f1)
    cd ..
    
    print_status "Checking connectivity to $CONTAINER_IP..."
    
    for i in {1..30}; do # Loop 30 times with 2-second sleep = 60 seconds total
        if ping -c 1 -W 2 "$CONTAINER_IP" &> /dev/null; then
            print_success "Container reachable"
            break
        fi
        
        if [ $i -eq 30 ]; then
            print_error "Container not reachable after 60 seconds"
            exit 1
        fi
        
        sleep 2
    done
    
    # Wait for SSH service
    print_status "Waiting for SSH service..."
    for i in {1..30}; do # Loop 30 times with 2-second sleep = 60 seconds total
        if nc -z "$CONTAINER_IP" 22 &> /dev/null; then
            print_success "SSH ready"
            break
        fi
        
        if [ $i -eq 30 ]; then
            print_error "SSH not available after 60 seconds"
            exit 1
        fi
        
        sleep 2
    done
}

# Deploy application with Ansible
deploy_application() {
    print_status "Deploying n8n with Ansible..."
    
    cd ansible
    
    echo -e "\n${BLUE}Do you want to proceed with n8n deployment? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        ansible-playbook -i inventory/hosts.yml playbooks/n8n_setup.yml
        print_success "n8n deployed successfully"
    else
        print_warning "Application deployment cancelled"
        exit 0
    fi
    
    cd ..
}

# Show final information
show_final_info() {
    cd terraform
    # Determine which command to use (tofu or terraform)
    if command -v tofu &> /dev/null; then
        TERRAFORM_CMD="tofu"
    else
        TERRAFORM_CMD="terraform"
    fi
    
    CONTAINER_IP=$($TERRAFORM_CMD output -raw container_ip | cut -d'/' -f1)
    cd ..
    
    echo -e "\n${GREEN}🎉 DEPLOYMENT COMPLETED! 🎉${NC}"
    echo -e "\n${BLUE}=== ACCESS INFORMATION ===${NC}"
    echo -e "n8n URL: ${GREEN}http://$CONTAINER_IP:5678${NC}"
    echo -e "SSH Container: ${GREEN}ssh root@$CONTAINER_IP${NC}"
    echo -e "\n${BLUE}=== USEFUL COMMANDS ===${NC}"
    echo -e "Status: ${YELLOW}ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags status${NC}"
    echo -e "Backup: ${YELLOW}ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags backup${NC}"
    echo -e "Update: ${YELLOW}ansible-playbook -i ansible/inventory/hosts.yml ansible/playbooks/site.yml --tags update${NC}"
}

# Main function
main() {
    echo -e "${BLUE}=== HOMELAB N8N PROXMOX AUTOMATION BOOTSTRAP ===${NC}\n"
    
    check_prerequisites
    setup_config
    init_terraform
    deploy_infrastructure
    wait_container_ready
    deploy_application
    show_final_info
    
    print_success "Bootstrap completed!"
}

# Argument handling
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [options]"
        echo "Options:"
        echo "  --help, -h     Show this message"
        echo "  --skip-infra   Skip infrastructure deployment"
        echo "  --skip-app     Skip application deployment"
        exit 0
        ;;
    --skip-infra)
        check_prerequisites
        wait_container_ready
        deploy_application
        show_final_info
        ;;
    --skip-app)
        check_prerequisites
        setup_config
        init_terraform
        deploy_infrastructure
        wait_container_ready
        ;;
    *)
        main
        ;;
esac
