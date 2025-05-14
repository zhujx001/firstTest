#!/bin/bash
set -e

echo "Starting system optimization..."

# Calculate the amount of RAM in bytes and 4 KB pages
RAM_BYTES=$(free -b | awk '/Mem:/ {print $2}')
RAM_PAGES=$(($RAM_BYTES / 4096))

# Dynamically calculate buffer sizes based on available RAM
# Use 25% of RAM for max TCP buffers as a rule of thumb
TCP_BUFFER_MAX=$((RAM_BYTES / 4))
TCP_BUFFER_DEFAULT=$((TCP_BUFFER_MAX / 2))
TCP_BUFFER_MIN=8192  # Minimum buffer size remains fixed

# Ensure buffer values do not exceed reasonable limits
if [ "$TCP_BUFFER_MAX" -gt 268435456 ]; then
    TCP_BUFFER_MAX=268435456  # Cap at 256 MB
fi

if [ "$TCP_BUFFER_DEFAULT" -gt 134217728 ]; then
    TCP_BUFFER_DEFAULT=134217728  # Cap at 128 MB
fi

# Prepare sysctl configuration content
CONFIG_CONTENT="""
fs.file-max = 2097152

# Reduce TIME_WAIT socket reuse timeout
net.ipv4.tcp_tw_reuse = 1

# Increase TCP buffer sizes
net.core.rmem_max = $TCP_BUFFER_MAX
net.core.wmem_max = $TCP_BUFFER_MAX
net.core.rmem_default = $TCP_BUFFER_DEFAULT
net.core.wmem_default = $TCP_BUFFER_DEFAULT
net.ipv4.tcp_rmem = $TCP_BUFFER_MIN 87380 $TCP_BUFFER_MAX
net.ipv4.tcp_wmem = $TCP_BUFFER_MIN 87380 $TCP_BUFFER_MAX

# Disable TCP slow start on idle connections
net.ipv4.tcp_slow_start_after_idle = 0

# Optimize backlog and connection queue
net.core.somaxconn = 65535
net.core.netdev_max_backlog = 65535
net.ipv4.tcp_max_syn_backlog = 65535
net.ipv4.tcp_fin_timeout = 10
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_max_tw_buckets = 1440000

# Expand local port range
net.ipv4.ip_local_port_range = 1024 65535

# Enable TCP Fast Open
net.ipv4.tcp_fastopen = 3

# Use BBR congestion control for better throughput
net.ipv4.tcp_congestion_control = bbr

# Kernel scheduling and shared memory tuning
kernel.sched_rt_runtime_us = 950000
kernel.sched_autogroup_enabled = 1
kernel.shmmax=$RAM_BYTES
kernel.shmall=$RAM_PAGES
"""

# Append configuration to /etc/sysctl.conf
echo "Appending configuration to /etc/sysctl.conf..."
echo "$CONFIG_CONTENT" | sudo tee -a /etc/sysctl.conf > /dev/null

# Apply sysctl changes
echo "Applying sysctl settings..."
sudo sysctl -p || { echo "Failed to apply sysctl settings."; exit 1; }
echo "Sysctl settings applied."

# Set all CPU cores to performance mode (for AMD systems)
echo "Setting all CPU cores to performance mode..."
for cpu in /sys/devices/system/cpu/cpu[0-9]*; do
    if [ -f "$cpu/cpufreq/scaling_governor" ]; then
        echo performance | sudo tee "$cpu/cpufreq/scaling_governor" > /dev/null
        echo "$(basename $cpu): $(cat $cpu/cpufreq/scaling_governor)"
    fi
done
echo "All CPU cores set to performance mode."

# Check if 'tuned' is installed; if not, install it
echo "Checking for 'tuned' package..."
if ! command -v tuned > /dev/null 2>&1; then
    echo "'tuned' is not installed. Installing it now..."
    sudo apt update && sudo apt install -y tuned
else
    echo "'tuned' is already installed."
fi

# Start and enable the tuned service
echo "Enabling and starting the tuned service..."
sudo systemctl enable tuned
sudo systemctl start tuned

# Apply the latency-performance tuning profile
echo "Applying the 'latency-performance' profile..."
sudo tuned-adm profile latency-performance

# Confirm applied profile
CURRENT_PROFILE=$(tuned-adm active | grep "Current active profile" || true)
echo "Tuned profile applied: $CURRENT_PROFILE"

echo "✅ System optimization completed."
