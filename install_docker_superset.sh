#!/bin/bash

# Update package list and install dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Add Docker GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Update package list again
sudo apt-get update

# Install Docker CE
sudo apt-get install -y docker-ce

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add the user to the Docker group
sudo usermod -aG docker ${USER}

# Refresh group membership
newgrp docker

# Run Superset container
sudo docker run -d -p 8088:8088 --name superset apache/superset:latest
