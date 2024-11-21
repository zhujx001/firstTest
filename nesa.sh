#!/bin/bash

# 更新系统包
echo "Updating system packages..."
sudo apt-get update -y
sudo apt-get upgrade -y

# 安装必要的依赖项
echo "Installing required packages..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

# 添加官方 Docker GPG 密钥
echo "Adding Docker GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# 添加 Docker 存储库
echo "Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 更新系统包并安装 Docker
echo "Installing Docker..."
sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 启动 Docker
echo "Starting Docker..."
sudo systemctl start docker
sudo systemctl enable docker

# 安装 CURL
echo "Installing CURL..."
sudo apt-get install -y curl

# 下载并运行矿工安装向导
echo "Running miner installation wizard..."
bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)

echo "Installation completed!"
