#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。/This script needs to be run with root user privileges."
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。/Please try to switch to root user with 'sudo -i' command, then run this script again."
    exit 1
fi

# 导入Socks5代理
read -p "请输入HTTP代理地址 (格式为 host:port)，如不需要代理请留空: /Please enter the HTTP proxy address (format host:port), leave blank if no proxy is needed: " proxy
if [ ! -z "$proxy" ]; then
    export http_proxy=http://$proxy
    export https_proxy=http://$proxy
    echo "已设置HTTP代理为: $proxy /HTTP proxy is set to: $proxy"
else
    echo "未设置代理 /No proxy set"
fi

# 节点安装功能
function install_node() {
    apt update
    apt install -y git python3-venv bison screen binutils gcc make bsdmainutils python3-pip build-essential

    # 安装numpy
    pip install numpy==1.24.4

    # 安装GO
    rm -rf /usr/local/go
    wget https://go.dev/dl/go1.22.1.linux-amd64.tar.gz -P /tmp/
    tar -C /usr/local -xzf /tmp/go1.22.1.linux-amd64.tar.gz
    echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    go version

    # 克隆官方仓库并安装
    mkdir -p $HOME/nimble && cd $HOME/nimble
    git clone https://github.com/nimble-technology/wallet-public.git
    cd wallet-public
    make install

    # 创建钱包
    echo "首次创建需要生成两个钱包，一个作为主钱包，一个作为挖矿钱包，需要提交官方审核。"
    read -p "请输入你想要创建的钱包数量/Enter the number of wallets you want to create: " wallet_count
    for i in $(seq 1 $wallet_count); do
        wallet_name="wallet$i"
        nimble-networkd keys add $wallet_name --keyring-backend test
        echo "钱包 $wallet_name 已创建/Wallet $wallet_name has been created."
    done

    echo "=============================备份好钱包和助记词，下方需要使用==================================="
    echo "=============================Make sure to backup your wallet and mnemonic phrase, it will be needed below==================================="

    # 确认备份
    read -p "是否已经备份好助记词? Have you backed up the mnemonic phrase? (y/n) " backup_confirmed
    if [ "$backup_confirmed" != "y" ]; then
            echo "请先备份好助记词,然后再继续执行脚本。/Please backup the mnemonic phrase first, then continue running the script."
            exit 1
    fi

    # 启动挖矿
    read -p "请输入挖矿钱包地址: Please enter your mining wallet address: " wallet_addr
    export wallet_addr
    cd $HOME/nimble
    git clone https://github.com/nimble-technology/nimble-miner-public.git
    cd nimble-miner-public
    make install
    source ./nimenv_localminers/bin/activate
    screen -dmS nim bash -c "make run addr=$wallet_addr"

    echo "安装完成，请输入命令 'screen -r nim' 查看运行状态。/Installation complete, enter 'screen -r nim' to view the running status."
}

# 查看节点日志
function lonely_start() {
    read -p "请输入挖矿钱包地址: Please enter your mining wallet address: " wallet_addr
    export wallet_addr
    cd $HOME/nimble/nimble-miner-public
    source ./nimenv_localminers/bin/activate

    # 获取显卡数量
    gpu_count=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

    for ((i=0; i<$gpu_count; i++)); do
        read -p "是否在显卡 $i 上启动挖矿? Start mining on GPU $i? (y/n) " start_mining
        if [ "$start_mining" == "y" ]; then
            screen -dmS nim_$i bash -c "make run addr=$wallet_addr gpu=$i"
            echo "显卡 $i 已启动挖矿。/Mining has started on GPU $i."
        else
            echo "跳过显卡 $i。/Skipping GPU $i."
        fi
    done

    echo "独立启动，请输入命令 'screen -r nim_<gpu_index>' 查看对应显卡的运行状态。/Independent start, enter 'screen -r nim_<gpu_index>' to view the running status of the corresponding GPU."
}

# 主菜单
function main_menu() {
    clear
    echo "请选择要执行的操作: /Please select an operation to execute:"
    echo "1. 安装常规节点 /Install a regular node"
    echo "2. 独立启动挖矿节点 /Independently start a mining node"
    read -p "请输入选项（1-2）: Please enter your choice (1-2): " OPTION

    case $OPTION in
    1) install_node ;;
    2) lonely_start ;;
    *) echo "无效选项。/Invalid option." ;;
    esac
}

main_menu
