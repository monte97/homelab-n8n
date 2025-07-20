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

# Check prerequisites for destroy script
check_destroy_prerequisites() {
    print_status "Checking prerequisites for destroy script..."
    
    # Verify Terraform/OpenTofu
    if ! command -v tofu &> /dev/null && ! command -v terraform &> /dev/null; then
        print_error "OpenTofu or Terraform not found. Please install one of them to destroy resources:"
        echo "  - OpenTofu: https://opentofu.org/docs/intro/install/"
        echo "  - Terraform: https://www.terraform.io/downloads"
        exit 1
    fi
    
    print_success "Prerequisites for destroy script are met"
}

# Destroy infrastructure
destroy_infrastructure() {
    print_status "Destroying Proxmox infrastructure..."
    
    cd terraform || { print_error "Could not change to terraform directory. Aborting."; exit 1; }
    
    # Determine which command to use (tofu or terraform)
    if command -v tofu &> /dev/null; then
        TERRAFORM_CMD="tofu"
    else
        TERRAFORM_CMD="terraform"
    fi
    
    echo -e "\n${YELLOW}=== TERRAFORM DESTROY PLAN ===${NC}"
    $TERRAFORM_CMD plan -destroy
    
    echo -e "\n${RED}WARNING: This will PERMANENTLY delete all deployed infrastructure.${NC}"
    echo -e "${BLUE}Do you want to proceed with infrastructure destruction? (y/N)${NC}"
    read -r response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        $TERRAFORM_CMD destroy -auto-approve
        print_success "Infrastructure destroyed successfully"
    else
        print_warning "Infrastructure destruction cancelled"
        exit 0
    fi
    
    cd ..
}

# Main function for destroy script
main_destroy() {
    echo -e "${BLUE}=== HOMELAB N8N PROXMOX INFRASTRUCTURE DESTROY ===${NC}\n"
    
    check_destroy_prerequisites
    destroy_infrastructure
    
    print_success "Infrastructure cleanup completed!"
    echo -e "\n${BLUE}Remember to manually remove any generated configuration files (e.g., terraform/terraform.tfvars, ansible/inventory/hosts.yml) if no longer needed.${NC}"
}

# Execute the main destroy function
main_destroy
