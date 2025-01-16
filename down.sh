#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install base utilities
install_base_utilities() {
    echo "Installing base utilities: make, screen, git..."
    if ! sudo apt update; then
        echo "Failed to update package lists"
        return 1
    fi
    
    if ! sudo apt install -y make screen git; then
        echo "Failed to install base utilities"
        return 1
    fi
    
    echo "Base utilities installed successfully."
    main
}

# Function to install Docker and Docker-Compose
install_docker() {
    if command_exists docker; then
        echo "Docker is already installed. Skipping..."
        return 0
    fi

    echo "Installing Docker and Docker-Compose..."
    if ! sudo apt update; then
        echo "Failed to update package lists"
        return 1
    fi
    
    if ! sudo apt install -y docker.io docker-compose; then
        echo "Failed to install Docker"
        return 1
    fi
    
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "Docker and Docker-Compose installed successfully. Please log out and log back in for Docker permissions to take effect."
    main
}

# Function to install Node.js, npm, and PM2 using NVM
install_node() {
    if command_exists nvm; then
        echo "NVM is already installed. Skipping..."
        return 0
    fi

    echo "Installing Node.js, npm, and PM2..."
    
    # Install NVM
    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash; then
        echo "Failed to install NVM"
        return 1
    fi

    # Source NVM scripts
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    # Install latest LTS Node.js
    if ! nvm install --lts; then
        echo "Failed to install Node.js LTS"
        return 1
    fi

    nvm use --lts
    
    # Install PM2
    if ! npm install -g pm2; then
        echo "Failed to install PM2"
        return 1
    fi

    echo "Node.js, npm, and PM2 installed successfully."
    main
}

# Function to install Go
install_go() {
    if command_exists go; then
        echo "Go is already installed. Skipping..."
        return 0
    fi

    echo "Installing Go 1.23..."
    
    # Download Go
    GO_VERSION="1.23.4"
    GO_DOWNLOAD_URL="https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    
    if ! wget "$GO_DOWNLOAD_URL"; then
        echo "Failed to download Go"
        return 1
    fi

    # Remove existing Go installation if exists
    if [ -d "/usr/local/go" ]; then
        sudo rm -rf /usr/local/go
    fi

    # Install Go
    if ! sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz"; then
        echo "Failed to extract Go"
        return 1
    fi

    # Add to PATH if not already present
    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
    fi

    # Clean up downloaded tarball
    rm "go${GO_VERSION}.linux-amd64.tar.gz"

    echo "Go ${GO_VERSION} installed successfully."
    main
}

# Function to install Python and venv
install_python() {
    echo "Installing Python and venv..."
    
    if ! sudo apt update; then
        echo "Failed to update package lists"
        return 1
    fi
    
    # Install Python 3 and venv
    if ! sudo apt install -y python3 python3-pip python3-venv; then
        echo "Failed to install Python and venv"
        return 1
    fi
    
    # Verify installations
    python3 --version
    pip3 --version
    
    echo "Python and venv installed successfully."
    echo "To create a new virtual environment, use: python3 -m venv <env_name>"
    main
}

# Main menu function
main() {
    clear
    echo "Select the software to install:"
    echo "0. Install base utilities (make, screen, git)"
    echo "1. Install Docker and Docker-Compose"
    echo "2. Install Node.js, npm, and PM2 using NVM"
    echo "3. Install Go 1.23"
    echo "4. Install Python and venv"
    echo "5. Exit"
    read -p "Enter your choice (0-5): " choice

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
        4)
            install_python
            ;;
        5)
            echo "Exiting script."
            exit 0
            ;;
        *)
            echo "Invalid choice. Please select a valid option."
            main
            ;;
    esac
}

# Run the main function
main
