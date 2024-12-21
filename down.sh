#!/bin/bash

# Function to install base utilities
install_base_utilities() {
    echo "Installing base utilities: make, screen, git..."
    sudo apt update
    sudo apt install -y make screen git
    echo "Base utilities installed successfully."
}

# Function to install Docker and Docker-Compose
install_docker() {
    echo "Installing Docker and Docker-Compose..."
    sudo apt update
    sudo apt install -y docker.io docker-compose
    sudo systemctl enable --now docker
    sudo usermod -aG docker $USER
    echo "Docker and Docker-Compose installed successfully. Please log out and log back in for Docker permissions to take effect."
}

# Function to install Node.js, npm, and PM2 using NVM
install_node() {
    echo "Installing Node.js, npm, and PM2..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \ . "$NVM_DIR/nvm.sh"  # Load nvm
    [ -s "$NVM_DIR/bash_completion" ] && \ . "$NVM_DIR/bash_completion"  # Load nvm bash_completion

    # Reload shell to ensure NVM is available
    source "$NVM_DIR/nvm.sh"
    source ~/.bashrc

    nvm install --lts
    nvm use --lts
    npm install -g pm2
    echo "Node.js, npm, and PM2 installed successfully."
}

# Function to install Go 1.23
install_go() {
    echo "Installing Go 1.23..."
    wget https://golang.org/dl/go1.23.4.linux-amd64.tar.gz
    sudo tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz
    echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
    source ~/.bashrc
    rm go1.23.4.linux-amd64.tar.gz
    echo "Go 1.23 installed successfully."
}

# Display menu and handle user input
echo "Select the software to install:"
echo "0. Install base utilities (make, screen, git)"
echo "1. Install Docker and Docker-Compose"
echo "2. Install Node.js, npm, and PM2 using NVM"
echo "3. Install Go 1.23"
read -p "Enter your choice: " choice

case $choice in
    0)
        install_base_utilities
        ;;
    1)
        install_docker
        ;;
    2)
        install_node
        ;;
    3)
        install_go
        ;;
    *)
        echo "Invalid choice. Exiting."
        ;;
esac

# Add placeholder for future extensions
echo "Installation complete or exited. You can extend this script by adding more options."
