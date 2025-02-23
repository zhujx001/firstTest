#!/bin/bash

# Exit on any error
set -e

# 3. Install Docker using official script
echo "Installing Docker using official script..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER  # Add current user to docker group

# Install Docker Compose (latest version from GitHub)
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 4. Install NVIDIA Fabric Manager
echo "Installing NVIDIA Fabric Manager..."
sudo apt-get update
sudo apt-get install -y nvidia-fabricmanager-570
sudo systemctl start nvidia-fabricmanager

# 5. Install NVIDIA Container Toolkit and related tools
echo "Installing NVIDIA Container Toolkit..."
distribution=$(. /etc/os-release; echo $ID$VERSION_ID)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/$distribution/libnvidia-container.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker --set-as-default
sudo apt-get install -y nvidia-docker2
sudo systemctl restart docker

# 6. Install btcli
echo "Installing btcli..."
git clone https://github.com/opentensor/btcli.git
cd btcli
pip3 install .
cd ..

# 7. Clone and set up Compute-Subnet repository
echo "Setting up Compute-Subnet repository..."
git clone https://github.com/neuralinternet/Compute-Subnet.git
cd Compute-Subnet
sudo apt -y install ocl-icd-libopencl1 pocl-opencl-icd


# 8. Configure environment
echo "Configuring environment..."
cp .env.example .env
cd ~/Compute-Subnet

# 9. Install remaining software and configure firewall
echo "Installing remaining software and configuring firewall..."
sudo apt install -y npm
sudo npm install pm2 -g
sudo apt install -y at ufw
sudo systemctl start docker
sudo ufw allow 4444
sudo ufw allow 22/tcp
sudo ufw allow 10:65535/tcp
cd
cd Compute-Subnet
python3 -m pip install -r requirements.txt
python3 -m pip install --no-deps -r requirements-compute.txt
python3 -m pip install -e .
# echo "Enable UFW now? You will need to confirm interactively."
# sudo ufw enable  # Interactive step

echo "Setup part 2 completed successfully. please run sudo ufw enable"
