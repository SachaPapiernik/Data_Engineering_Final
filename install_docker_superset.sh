#!/bin/bash

# Update package list and install dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common
sudo apt-get install msodbcsql17

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

# Generate a secure SECRET_KEY
SECRET_KEY=$(openssl rand -base64 42)

# Create superset_config.py with the generated SECRET_KEY
cat <<EOL > superset_config.py
import os

SECRET_KEY = os.environ.get('SUPERSET_SECRET_KEY', '$SECRET_KEY')
EOL

# Pull the latest Superset image
sudo docker pull apache/superset:latest

# Run Superset container with mounted configuration
sudo docker run -d -p 8088:8088 \
  --name superset \
  -v $(pwd)/superset_config.py:/app/pythonpath_dev/superset_config.py \
  -e SUPERSET_SECRET_KEY=$SECRET_KEY \
  apache/superset:latest

echo "Waiting for Superset to start..."
sleep 30

sudo docker exec -it superset superset fab create-admin \
    --username admin \
    --firstname Admin \
    --lastname User \
    --email admin@superset.com \
    --password 1234

sudo docker exec -it superset superset db upgrade
sudo docker exec -it superset superset init