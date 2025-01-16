#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 安装功能函数
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
    echo "Press Enter to return to main menu..."
    read
    main_menu
}

install_docker() {
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
    echo "Docker and Docker-Compose installed successfully."
    echo "Please log out and log back in for Docker permissions to take effect."
    echo "Press Enter to return to main menu..."
    read
    main_menu
}

install_node() {
    echo "Installing Node.js, npm, and PM2..."
    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash; then
        echo "Failed to install NVM"
        return 1
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    if ! nvm install --lts; then
        echo "Failed to install Node.js LTS"
        return 1
    fi

    nvm use --lts
    
    if ! npm install -g pm2; then
        echo "Failed to install PM2"
        return 1
    fi

    echo "Node.js, npm, and PM2 installed successfully."
    echo "Press Enter to return to main menu..."
    read
    main_menu
}

install_go() {
    echo "Installing Go 1.23..."
    GO_VERSION="1.23.4"
    GO_DOWNLOAD_URL="https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz"
    
    wget "$GO_DOWNLOAD_URL" && \
    sudo rm -rf /usr/local/go && \
    sudo tar -C /usr/local -xzf "go${GO_VERSION}.linux-amd64.tar.gz" && \
    rm "go${GO_VERSION}.linux-amd64.tar.gz"

    if ! grep -q "/usr/local/go/bin" ~/.bashrc; then
        echo "export PATH=\$PATH:/usr/local/go/bin" >> ~/.bashrc
        source ~/.bashrc
    fi

    echo "Go ${GO_VERSION} installed successfully."
    echo "Press Enter to return to main menu..."
    read
    main_menu
}

install_python() {
    echo "Installing Python and venv..."
    if ! sudo apt update && sudo apt install -y python3 python3-pip python3-venv; then
        echo "Failed to install Python and venv"
        return 1
    fi
    
    python3 --version
    pip3 --version
    
    echo "Python and venv installed successfully."
    echo "To create a new virtual environment, use: python3 -m venv <env_name>"
    echo "Press Enter to return to main menu..."
    read
    main_menu
}

# 主菜单函数
main_menu() {
    clear
    echo "================================================================"
    echo "                     开发环境配置安装脚本"
    echo "================================================================"
    echo "请选择要安装的软件:"
    echo "0. 安装基础工具 (make, screen, git)"
    echo "1. 安装 Docker 和 Docker-Compose"
    echo "2. 安装 Node.js, npm 和 PM2"
    echo "3. 安装 Go 1.23"
    echo "4. 安装 Python 和 venv"
    echo "5. 退出"
    echo "================================================================"
    read -p "请输入选项 (0-5): " choice

    case $choice in
        0) install_base_utilities ;;
        1) install_docker ;;
        2) install_node ;;
        3) install_go ;;
        4) install_python ;;
        5) echo "退出脚本." ; exit 0 ;;
        *) 
            echo "无效选项，请重新选择..."
            echo "按回车键继续..."
            read
            main_menu 
            ;;
    esac
}

# 运行主菜单
main_menu
