#!/bin/bash

# Title:
# Bootstrap script for Ubuntu 20.04 server

# Description:
# This script is intended to be run on a fresh Ubuntu 20.04 server to perform the following tasks:
# 1. Update and upgrade apt
# 2. Install gh (GitHub CLI)
# 3. Install Docker (and Docker Compose)
# 4. Install utilities (ufw, nano, bat, logwatch, fail2ban, git, bpytop)
# 5. Enable PasswordAuthentication and PubkeyAuthentication in sshd_config
# 6. Add SSH key to authorized_keys

# Usage:
# bash bootstrap.sh

# COLORS
RED='\033[0;31m'
GREEN='\033[0;32m'
INFO='\033[0;33m' # Yellow
NC='\033[0m' # No Color

# function to echo success messages
echo_success() {
  echo -e "${GREEN}$1${NC}"
}

# function to echo info messages
echo_info() {
  echo -e "${INFO}$1${NC}"
}

# function to echo error messages
echo_error() {
  echo -e "${RED}$1${NC}"
}

# function to handle errors gracefully (and continue the script)
handle_error() {
  echo_error "Error: $1"
  return 1
}

# Function to check if a command is available
command_exists() {
  echo_info "Checking if $1 is available..."
  type "$1" &> /dev/null
}

# Function to check if the script is run with sudo privileges
check_sudo() {
  if [ "$EUID" -ne 0 ]; then
    echo_error "Please run this script with sudo or as root."
    exit 1
  fi
}

# Function to update and upgrade apt
update_and_upgrade_apt() {
  echo_info "Updating and upgrading apt..."
  sudo apt update && sudo apt upgrade -y
  echo_success "Apt updated and upgraded successfully."
}

# Function to install gh
install_gh() {
  echo_info "Installing gh..."
  if ! command_exists gh; then
    echo_info "gh not found. Installing gh..."
    type -p curl > /dev/null || (sudo apt update && sudo apt install curl -y)
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
    sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
      && sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
      && echo "deb [arch=$(dpkg --print-architecture) \
      signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
      sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
      && sudo apt update \
      && sudo apt install gh -y

    # Check if gh was installed successfully
    if ! command_exists gh; then
      echo_error "Error: gh not installed."
      return 1
    fi

    echo_success "gh installed successfully."
  fi
}

# Function to install Docker
install_docker() {
  echo_info "Installing Docker..."
  if ! command_exists docker; then
    echo_info "Docker not found. Installing Docker..."
    sudo apt-get update
    sudo apt-get install ca-certificates curl -y
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install docker-ce docker-ce-cli containerd.io -y

    # Check if Docker was installed successfully
    if ! command_exists docker; then
      echo_error "Error: Docker not installed."
      return 1
    fi

    echo_success "Docker installed successfully."
  fi
}

# Function to install ufw, nano, bat, logwatch, fail2ban
install_utilities() {
  echo_info "Installing utilities..."
  sudo apt install ufw nano bat logwatch fail2ban git bpytop -y

  # Check if utilities were installed successfully
  for util in ufw nano bat logwatch fail2ban git bpytop; do
    if ! command_exists "$util"; then
      echo_error "Error: $util not installed."
      return 1
    fi
  done
  echo_success "Utilities installed successfully."
}

# Function to enable PasswordAuthentication and PubkeyAuthentication in sshd_config
enable_ssh_authentication() {
  echo_info "Enabling PasswordAuthentication and PubkeyAuthentication in sshd_config..."
  sshd_config="/etc/ssh/sshd_config"

  # Check if the file exists
  if [ -f "$sshd_config" ]; then
    echo_info "sshd_config found. Updating PasswordAuthentication and PubkeyAuthentication settings..."
    # Ensure PasswordAuthentication is set to yes
    if grep -qE '^#?PasswordAuthentication' "$sshd_config"; then
      echo_info "PasswordAuthentication setting found. Updating..."
      sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' "$sshd_config"
    else
      echo_info "PasswordAuthentication setting not found. Adding..."
      echo "PasswordAuthentication yes" | sudo tee -a "$sshd_config" > /dev/null
    fi

    # Ensure PubkeyAuthentication is set to yes
    echo_info "PubkeyAuthentication setting found. Updating..."
    if grep -qE '^#?PubkeyAuthentication' "$sshd_config"; then
      echo_info "PubkeyAuthentication setting found. Updating..."
      sudo sed -i 's/^#PubkeyAuthentication.*/PubkeyAuthentication yes/' "$sshd_config"
    else
      echo_info "PubkeyAuthentication setting not found. Adding..."
      echo "PubkeyAuthentication yes" | sudo tee -a "$sshd_config" > /dev/null
    fi

    # Restart SSH service
    echo_info "Restarting SSH service..."
    sudo systemctl restart ssh
    echo_success "PasswordAuthentication and PubkeyAuthentication settings updated in sshd_config. SSH service restarted."
  else
    echo_error "Error: $sshd_config not found."
  fi
}
# Function to prompt for SSH key and add it to authorized_keys
add_ssh_key() {
  echo_info "Adding SSH key to authorized_keys..."

  # Ensure the ~/.ssh directory exists
  echo_info "Ensuring the ~/.ssh directory exists..."
  mkdir -p ~/.ssh

  # Check if authorized_keys file exists; create if not
  echo_info "Ensuring the ~/.ssh/authorized_keys file exists..."
  touch ~/.ssh/authorized_keys

  # Prompt user for SSH key
  echo_info "Enter the SSH key to add to authorized_keys..."
  read -r -p "Enter the SSH key to add: " ssh_key

  # Check if the key is already in authorized_keys
  if grep -qF "$ssh_key" ~/.ssh/authorized_keys; then
    echo_success "SSH key already exists in authorized_keys."
  else
    # Add the key to authorized_keys
    echo_info "Adding SSH key to authorized_keys..."
    echo "$ssh_key" >> ~/.ssh/authorized_keys
    echo_success "SSH key added to authorized_keys."
  fi
}

# Main function
main() {
  echo_info "Running bootstrap script..."

  # Check if the script is run with sudo privileges
  check_sudo || handle_error "Please run this script with sudo or as root."

  # Update and upgrade apt
  update_and_upgrade_apt || handle_error "Failed to update and upgrade apt."

  # Install gh
  install_gh || handle_error "Failed to install gh."

  # Install Docker
  install_docker || handle_error "Failed to install Docker."

  # Install utilities
  install_utilities || handle_error "Failed to install utilities."

  # Add SSH key to authorized_keys
  add_ssh_key || handle_error "Failed to add SSH key to authorized_keys."

  # Enable PasswordAuthentication and PubkeyAuthentication in sshd_config
  enable_ssh_authentication || handle_error "Failed to enable PasswordAuthentication and PubkeyAuthentication in sshd_config."

  echo_success "Bootstrap script completed successfully."
}

# Run the main function
main