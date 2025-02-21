#!/bin/bash

# Exit on any error
set -e

# 1. Uninstall existing NVIDIA/CUDA drivers
echo "Uninstalling existing NVIDIA/CUDA drivers..."
sudo apt-get --purge -y remove 'cuda*' 'nvidia*'
sudo apt-get -y autoremove
sudo apt-get -y autoclean
sudo rm -rf /usr/local/cuda*

# 2. Install new NVIDIA CUDA drivers
echo "Installing new NVIDIA CUDA drivers..."
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb
sudo dpkg -i cuda-keyring_1.1-1_all.deb
sudo apt-get update
sudo apt-get install -y cuda-toolkit-12-4 cuda-drivers
echo 'export PATH=/usr/local/cuda-12.4/bin${PATH:+:${PATH}}' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=/usr/local/cuda-12.4/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}' >> ~/.bashrc

echo "CUDA installation completed. Please reboot the system manually after this script."
echo "Run 'sudo reboot' if ready, or reboot later and proceed with setup_part2.sh."
