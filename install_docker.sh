#!/bin/bash
###
##
#

sudo apt update -y

echo "INFO : Installing required packages ..."
# Install the required packages
sudo apt install apt-transport-https ca-certificates curl software-properties-common &> /dev/null

# Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg &> /dev/null

# Set up the stable repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list &> /dev/null 

# Update the package database with Docker packages from the newly added repo
sudo apt update &> /dev/null


echo "INFO : Installing Docker Engine ..."
# Install Docker Engine
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &> /dev/null
# Verify Docker is installed correctly
echo "Docker Version :" $(sudo docker --version | awk 'NR==1 {print $1,$2,$3,$4}')


## Install Docker Compose
echo "INFO : Installing Docker Compose ..."

# Download the current stable release of Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep -Po '"tag_name": "\K.*?(?=")')/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose &> /dev/null

# Apply executable permissions to the binary
sudo chmod +x /usr/local/bin/docker-compose

# Verify the installation
echo "Docker Version :" $(docker-compose --version | awk 'NR==1 {print $1,$2,$3,$4}')


## Manage Docker as a Non-Root User
echo "INFO : Manage Docker as a Non-Root User ..."

# Create the docker group
sudo groupadd docker &> /dev/null

# Add your user to the docker group
sudo usermod -aG docker $USER &> /dev/null

# Activate the changes to groups
newgrp docker &> /dev/null

# Verify that you can run docker commands without sudo
echo "Docker Version :" $( docker --version | awk 'NR==1 {print $1,$2,$3,$4}')