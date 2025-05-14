#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root (use sudo)"
  exit 1
fi

# Function to check if a package is installed
is_installed() {
  dpkg -s "$1" &> /dev/null
  return $?
}

# 1. CPU Performance Mode Setup
echo "🔄 Setting CPU to performance mode..."

# Check if cpu tools are already installed
if ! is_installed "linux-tools-common"; then
  echo "Installing CPU tools..."
  apt install -y linux-tools-common linux-tools-$(uname -r)
else
  echo "CPU tools already installed."
fi

# Display CPU frequency info
echo "📊 Current CPU frequency info:"
cpupower frequency-info

# Set CPU governor to performance
echo "🚀 Setting CPU governor to performance mode..."
cpupower frequency-set --governor performance

# Display the current CPU frequency to verify changes
echo "📈 Verifying CPU frequency (press Ctrl+C to continue)..."
watch "grep 'cpu MHz' /proc/cpuinfo" &
watch_pid=$!
sleep 5
kill $watch_pid
wait $watch_pid 2>/dev/null

# 2. Software Installation Section
echo "🔧 Updating system..."
apt update && apt upgrade -y

echo "📦 Installing dependencies..."
apt install -y curl wget git unzip build-essential jq tmux net-tools ufw \
  software-properties-common glances tuned bc gawk lsof psmisc

echo "🛠️ Installing Solana CLI..."
curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash

echo "🟢 Installing Node.js (LTS) and PM2..."
if ! is_installed "nodejs"; then
  curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
  apt install -y nodejs
else
  echo "Node.js already installed."
fi

# Install PM2 globally
echo "Installing PM2..."
npm install -g pm2

echo "💾 Saving PM2 startup service..."
# Switch to user context for PM2 operations
su - $SUDO_USER -c "pm2 install pm2-logrotate && pm2 save && pm2 startup systemd -u $SUDO_USER --hp /home/$SUDO_USER"

# 3. Performance Tuning Script
echo "⚙️ Downloading and running performance tuning script..."
wget -O /tmp/per.sh https://raw.githubusercontent.com/zhujx001/firstTest/refs/heads/master/per.sh
chmod +x /tmp/per.sh
bash /tmp/per.sh

# 4. Download and Extract CC-BOT
echo "📥 Downloading CC-BOT package..."
wget -O /tmp/CC-BOT.zip https://github.com/zhujx001/firstTest/releases/download/v1.0/CC-BOT.zip

echo "📂 Extracting CC-BOT package..."
unzip -o /tmp/CC-BOT.zip -d /root

echo "🔐 Setting execution permissions for cc-arbitrage-bot..."
chmod +x /root/CC-BOT/cc-arb-executable/cc-arbitrage-bot

echo "✅ Setup complete! CC-BOT is ready to use."
echo "📍 CC-BOT executable location: /root/CC-BOT/cc-arb-executable/cc-arbitrage-bot"
