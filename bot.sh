#!/bin/bash

# Display menu and get user input
show_menu() {
  echo "============================================"
  echo "🚀 Performance Optimization & Setup Script 🚀"
  echo "============================================"
  echo "Select options to execute (comma-separated):"
  echo "1. Set CPU to performance mode"
  echo "2. Install required software"
  echo "3. Run performance tuning script"
  echo "4. Download and extract CC-BOT"
  echo "5. Run all options (1-4)"
  echo "0. Exit"
  echo "============================================"
  read -p "Enter your choices (e.g., 1,3,4): " choices
}

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

# Function: Set CPU to performance mode
set_cpu_performance() {
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
  
  echo "✅ CPU set to performance mode"
}

# Function: Install required software
install_software() {
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
  
  echo "✅ Software installation complete"
}

# Function: Run performance tuning script
run_performance_script() {
  echo "⚙️ Downloading and running performance tuning script..."
  wget -O /tmp/per.sh https://raw.githubusercontent.com/zhujx001/firstTest/refs/heads/master/per.sh
  chmod +x /tmp/per.sh
  bash /tmp/per.sh
  
  echo "✅ Performance tuning complete"
}

# Function: Download and extract CC-BOT
download_extract_bot() {
  echo "📥 Downloading CC-BOT package..."
  wget -O /tmp/CC-BOT.zip https://github.com/zhujx001/firstTest/releases/download/v1.0/CC-BOT.zip

  echo "📂 Extracting CC-BOT package..."

  unzip -o /tmp/CC-BOT.zip -d /root

  echo "🔐 Setting execution permissions for cc-arbitrage-bot..."
  chmod +x /root/CC-BOT/cc-arb-executable/cc-arbitrage-bot
  
  echo "✅ CC-BOT download and extraction complete"
  echo "📍 CC-BOT executable location: /root/CC-BOT/cc-arb-executable/cc-arbitrage-bot"
}

# Main execution
show_menu

# Process user choices
IFS=',' read -ra selected_options <<< "$choices"
for option in "${selected_options[@]}"; do
  option=$(echo "$option" | tr -d ' ')
  case $option in
    1)
      set_cpu_performance
      ;;
    2)
      install_software
      ;;
    3)
      run_performance_script
      ;;
    4)
      download_extract_bot
      ;;
    5)
      set_cpu_performance
      install_software
      run_performance_script
      download_extract_bot
      ;;
    0)
      echo "Exiting script."
      exit 0
      ;;
    *)
      echo "Invalid option: $option"
      ;;
  esac
done

echo "✅ Selected operations completed."
