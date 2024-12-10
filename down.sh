#!/bin/bash

# 确保脚本以root权限运行
if [[ $EUID -ne 0 ]]; then
   echo "此脚本需要以root权限运行。请使用 sudo 或以root用户运行。" 
   exit 1
fi

# 更新包列表
update_system() {
    echo "=============================="
    echo "正在更新包列表..."
    echo "=============================="
    apt update -y
    if [ $? -eq 0 ]; then
        echo "包列表更新成功。"
    else
        echo "包列表更新失败。请检查网络连接或APT配置。"
    fi
    read -p "按任意键继续..."
}

# 安装基础工具
install_basic_tools() {
    echo "=============================="
    echo "正在安装 screen, vim, curl, wget, git..."
    echo "=============================="
    apt install -y screen vim curl wget git
    if [ $? -eq 0 ]; then
        echo "基础工具安装成功。"
    else
        echo "基础工具安装失败。"
    fi
    read -p "按任意键继续..."
}

# 安装 Docker 和 Docker Compose
install_docker() {
    echo "=============================="
    echo "正在安装 Docker 和 Docker Compose..."
    echo "=============================="

    # 安装必要的包
    apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    if [ $? -ne 0 ]; then
        echo "安装必要的包失败。"
        read -p "按任意键继续..."
        return
    fi

    # 添加 Docker 的官方 GPG 密钥
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    if [ $? -ne 0 ]; then
        echo "添加 Docker GPG 密钥失败。"
        read -p "按任意键继续..."
        return
    fi

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    if [ $? -ne 0 ]; then
        echo "设置 Docker 仓库失败。"
        read -p "按任意键继续..."
        return
    fi

    # 更新包列表
    apt update -y
    if [ $? -ne 0 ]; then
        echo "包列表更新失败。"
        read -p "按任意键继续..."
        return
    fi

    # 安装 Docker Engine
    apt install -y docker-ce docker-ce-cli containerd.io
    if [ $? -ne 0 ]; then
        echo "安装 Docker Engine 失败。"
        read -p "按任意键继续..."
        return
    fi

    # 启动并设置 Docker 开机自启
    systemctl start docker
    systemctl enable docker

    # 验证 Docker 安装
    if docker --version >/dev/null 2>&1; then
        echo "Docker 安装成功。"
    else
        echo "Docker 安装失败。"
        read -p "按任意键继续..."
        return
    fi

    # 安装 Docker Compose
    DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep tag_name | cut -d '"' -f 4)
    if [ -z "$DOCKER_COMPOSE_VERSION" ]; then
        echo "获取 Docker Compose 版本失败。"
        read -p "按任意键继续..."
        return
    fi

    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    if [ $? -ne 0 ]; then
        echo "下载 Docker Compose 失败。"
        read -p "按任意键继续..."
        return
    fi

    chmod +x /usr/local/bin/docker-compose

    # 创建软链接
    ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

    # 验证 Docker Compose 安装
    if docker-compose --version >/dev/null 2>&1; then
        echo "Docker Compose 安装成功。"
    else
        echo "Docker Compose 安装失败。"
    fi
    read -p "按任意键继续..."
}

# 安装 Go 1.23
install_go() {
    echo "=============================="
    echo "正在安装 Go 1.23..."
    echo "=============================="

    # 定义 Go 版本
    GO_VERSION="1.23.0"

    # 下载 Go 二进制包
    wget https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz -O /tmp/go${GO_VERSION}.linux-amd64.tar.gz
    if [ $? -ne 0 ]; then
        echo "下载 Go 二进制包失败。"
        read -p "按任意键继续..."
        return
    fi

    # 删除现有的 Go 安装（如果有）
    rm -rf /usr/local/go

    # 解压并安装 Go
    tar -C /usr/local -xzf /tmp/go${GO_VERSION}.linux-amd64.tar.gz
    if [ $? -ne 0 ]; then
        echo "解压 Go 二进制包失败。"
        read -p "按任意键继续..."
        return
    fi

    # 设置环境变量
    if ! grep -q "export PATH=\$PATH:/usr/local/go/bin" /etc/profile; then
        echo "export PATH=\$PATH:/usr/local/go/bin" >> /etc/profile
    fi

    # 重新加载环境变量
    source /etc/profile

    # 验证 Go 安装
    if go version | grep "go${GO_VERSION}" >/dev/null 2>&1; then
        echo "Go ${GO_VERSION} 安装成功。"
    else
        echo "Go ${GO_VERSION} 安装失败。"
    fi

    # 清理下载文件
    rm /tmp/go${GO_VERSION}.linux-amd64.tar.gz
    read -p "按任意键继续..."
}

# 安装 NVM 并使用 NVM 安装 Node.js 和 npm
install_nvm_node() {
    echo "=============================="
    echo "正在安装 NVM 和 Node.js/npm..."
    echo "=============================="
    read -p "请输入要安装 Node.js 和 npm 的用户名: " username

    if id "$username" &>/dev/null; then
        echo "正在为用户 $username 安装 NVM 和 Node.js..."

        sudo -u "$username" bash -c ' 
            # 下载并安装 NVM
            curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash

            # 加载 NVM 环境变量
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

            # 安装最新的 LTS 版本 Node.js
            nvm install --lts

            # 设置默认 Node.js 版本
            nvm alias default node
        '
        if [ $? -ne 0 ]; then
            echo "NVM 或 Node.js 安装过程中出错。"
            read -p "按任意键继续..."
            return
        fi

        # 验证安装
        sudo -u "$username" bash -c ' 
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

            if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then 
                echo "Node.js 和 npm 安装成功。"; 
            else 
                echo "Node.js 和 npm 安装失败。"; 
            fi
        '
    else
        echo "用户 $username 不存在。"
    fi
    read -p "按任意键继续..."
}

# 显示菜单
show_menu() {
    clear
    echo "=============================="
    echo "        一键安装服务脚本      "
    echo "=============================="
    echo "1. 安装 screen, vim, curl, wget, git"
    echo "2. 安装 Docker 和 Docker Compose"
    echo "3. 安装 Go 1.23"
    echo "4. 使用 NVM 安装 Node.js 和 npm"
    echo "5. 退出"
    echo "=============================="
}

# 主执行
show_menu
read -p "请输入选项 [1-5]: " choice

case $choice in
    1)
        update_system
        install_basic_tools
        ;;
    2)
        update_system
        install_docker
        ;;
    3)
        update_system
        install_go
        ;;
    4)
        update_system
        install_nvm_node
        ;;
    5)
        echo "退出脚本。"
        exit 0
        ;;
    *)
        echo "无效选项，请重新输入。"
        read -p "按任意键退出..."
        exit 1
        ;;
esac
