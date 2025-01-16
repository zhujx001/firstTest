#!/bin/bash

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# 系统更新函数
system_update() {
    echo "正在更新系统..."
    sudo apt update && sudo apt upgrade -y
    if [ $? -eq 0 ]; then
        echo "系统更新完成!"
    else
        echo "系统更新失败，请检查网络连接或尝试手动更新。"
        return 1
    fi
}

# 安装基础依赖
install_basic_dependencies() {
    echo "正在安装基础依赖..."
    sudo apt install -y wget curl git build-essential software-properties-common
    if [ $? -eq 0 ]; then
        echo "基础依赖安装完成!"
    else
        echo "基础依赖安装失败。"
        return 1
    fi
}

# 安装功能函数
install_base_utilities() {
    echo "正在安装基础工具: make, screen, git..."
    if ! sudo apt install -y make screen git; then
        echo "基础工具安装失败"
        return 1
    fi
    
    echo "基础工具安装成功。"
    echo "按回车键返回主菜单..."
    read
    main_menu
}

install_docker() {
    echo "正在安装 Docker 和 Docker-Compose..."
    # 添加 Docker 官方 GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    
    # 添加 Docker 仓库
    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
    
    # 更新包列表并安装
    sudo apt update
    if ! sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose; then
        echo "Docker 安装失败"
        return 1
    fi
    
    # 启动 Docker 并设置开机自启
    sudo systemctl enable --now docker
    sudo usermod -aG docker "$USER"
    echo "Docker 和 Docker-Compose 安装成功。"
    echo "请注意：需要重新登录以使 Docker 权限生效。"
    echo "按回车键返回主菜单..."
    read
    main_menu
}

install_node() {
    echo "正在安装 Node.js, npm, 和 PM2..."
    # 安装 curl（如果尚未安装）
    sudo apt install -y curl
    
    # 安装 NVM
    if ! curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash; then
        echo "NVM 安装失败"
        return 1
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    if ! nvm install --lts; then
        echo "Node.js LTS 版本安装失败"
        return 1
    fi

    nvm use --lts
    
    if ! npm install -g pm2; then
        echo "PM2 安装失败"
        return 1
    fi

    echo "Node.js, npm, 和 PM2 安装成功。"
    echo "按回车键返回主菜单..."
    read
    main_menu
}

install_go() {
    echo "正在安装 Go 1.23..."
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

    echo "Go ${GO_VERSION} 安装成功。"
    echo "按回车键返回主菜单..."
    read
    main_menu
}

install_python() {
    echo "正在安装 Python 3.12..."
    
    # 添加 deadsnakes PPA 仓库
    sudo add-apt-repository -y ppa:deadsnakes/ppa
    sudo apt update

    # 安装 Python 3.12 及相关工具
    if ! sudo apt install -y python3.12 python3.12-venv python3.12-dev python3-pip; then
        echo "Python 3.12 安装失败"
        return 1
    fi
    
    # 创建 Python 3.12 的软链接
    sudo update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
    
    # 升级 pip
    python3.12 -m pip install --upgrade pip
    
    # 验证安装
    echo "验证安装:"
    python3.12 --version
    pip3 --version
    
    echo "Python 3.12 和相关工具安装成功。"
    echo "创建虚拟环境的命令: python3.12 -m venv <env_name>"
    echo "按回车键返回主菜单..."
    read
    main_menu
}

# 主菜单函数
main_menu() {
    clear
    echo "================================================================"
    echo "                     开发环境配置安装脚本"
    echo "================================================================"
    echo "初次使用请先选择选项 0 进行系统更新和安装基础依赖"
    echo "----------------------------------------------------------------"
    echo "请选择要安装的软件:"
    echo "0. 系统更新和安装基础依赖"
    echo "1. 安装基础工具 (make, screen, git)"
    echo "2. 安装 Docker 和 Docker-Compose"
    echo "3. 安装 Node.js, npm 和 PM2"
    echo "4. 安装 Go 1.23"
    echo "5. 安装 Python 3.12 和相关工具"
    echo "6. 退出"
    echo "================================================================"
    read -p "请输入选项 (0-6): " choice

    case $choice in
        0)  system_update && install_basic_dependencies && main_menu ;;
        1)  install_base_utilities ;;
        2)  install_docker ;;
        3)  install_node ;;
        4)  install_go ;;
        5)  install_python ;;
        6)  echo "退出脚本." ; exit 0 ;;
        *) 
            echo "无效选项，请重新选择..."
            echo "按回车键继续..."
            read
            main_menu 
            ;;
    esac
}

# 检查是否为 root 用户
if [ "$EUID" -eq 0 ]; then
    echo "请不要使用 root 用户运行此脚本"
    exit 1
fi

# 运行主菜单
main_menu
