#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户,然后再次运行此脚本。"
    exit 1
fi

# 安装必要的工具和依赖
echo "更新系统软件包..."
sudo apt update && sudo apt upgrade -y
echo "安装必要的工具和依赖..."
sudo apt install -y curl build-essential jq git libssl-dev pkg-config screen

# 安装 Rust 和 Cargo
echo "正在安装 Rust 和 Cargo..."
curl https://sh.rustup.rs -sSf | sh -s -- -y
source $HOME/.cargo/env

# 克隆 Ore 项目
echo "正在从 GitHub 克隆 Ore 项目..."
git clone https://github.com/okeyzero/ore-cli.git
cd ore-cli

# 构建 Ore CLI
echo "正在构建 Ore CLI..."
cargo build --release

# 将 Ore CLI 二进制文件复制到 /usr/local/bin
echo "将 Ore CLI 二进制文件复制到 /usr/local/bin..."
sudo cp target/release/ore /usr/local/bin/

# 获取用户输入的 RPC 地址或使用默认地址
read -p "请输入自定义的 RPC 地址,建议使用免费的Quicknode或者alchemy SOL rpc(默认设置使用 https://api.mainnet-beta.solana.com): " custom_rpc
RPC_URL=${custom_rpc:-https://api.mainnet-beta.solana.com}

# 获取用户输入的发送交易RPC地址,如果未提供则默认与RPC地址相同
read -p "请输入自定义的发送交易RPC地址(默认设置与RPC地址相同): " custom_send_tx_rpc
SEND_TX_RPC=${custom_send_tx_rpc:-$RPC_URL}

# 获取用户输入的线程数或使用默认值
read -p "请输入挖矿时要使用的线程数(默认设置4): " custom_threads
THREADS=${custom_threads:-4}

# 获取用户输入的优先费用或使用默认值  
read -p "请输入交易的优先费用(默认设置1): " custom_priority_fee
PRIORITY_FEE=${custom_priority_fee:-1}

# 获取用户输入的钱包数量
read -p "请输入要运行的钱包数量: " wallet_count

# 循环wallet_count次,每次提示用户输入私钥并启动挖矿
for ((i=1; i<=wallet_count; i++)); do
    # 提示用户输入Solana钱包私钥
    read -p "请输入第 $i 个Solana钱包私钥(例如[11,22,33,44,...]): " keypair
    KEYPAIR_FILE=~/.config/solana/id_$i.json
    mkdir -p ~/.config/solana
    echo $keypair > $KEYPAIR_FILE

    # 使用screen和Ore CLI开始挖矿
    session_name="ore_mining_$i"
    echo "开始第 $i 个钱包的挖矿,会话名称为 $session_name ..."

    start="while true; do ore --rpc $RPC_URL --send-tx-rpc $SEND_TX_RPC --keypair $KEYPAIR_FILE --priority-fee $PRIORITY_FEE mine --threads $THREADS; echo '进程异常退出,等待重启' >&2; sleep 1; done" 
    screen -dmS "$session_name" bash -c "$start"

    echo "第 $i 个钱包的挖矿进程已在名为$session_name的screen会话中后台启动。"
    echo "使用'screen -r $session_name'命令重新连接到此会话。"
done

# 显示查询命令
echo "要查询未领取代币,请运行以下命令,将X替换为钱包编号(1到$wallet_count):"
echo "ore --rpc $RPC_URL --keypair ~/.config/solana/id_X.json rewards"

echo "要查询代币余额,请运行以下命令,将X替换为钱包编号(1到$wallet_count):"  
echo "ore --rpc $RPC_URL --keypair ~/.config/solana/id_X.json balance"

echo "要领取代币,请运行以下命令,将X替换为钱包编号(1到$wallet_count):"
echo "ore --rpc $RPC_URL --keypair ~/.config/solana/id_X.json --priority-fee $PRIORITY_FEE claim"
