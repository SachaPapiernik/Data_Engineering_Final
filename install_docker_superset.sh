#!/bin/bash

# Update package list and install dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common nginx openssl
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

# Create a self-signed SSL certificate
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=$(hostname -I | awk '{print $1}')"

# Create a strong Diffie-Hellman group
sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048

# Configure Nginx to use the self-signed certificate
cat <<EOL > /etc/nginx/snippets/self-signed.conf
ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
EOL

cat <<EOL > /etc/nginx/snippets/ssl-params.conf
ssl_protocols TLSv1.2 TLSv1.3;
ssl_prefer_server_ciphers on;
ssl_dhparam /etc/ssl/certs/dhparam.pem;
ssl_ciphers EECDH+AESGCM:EDH+AESGCM;
ssl_ecdh_curve secp384r1;
ssl_session_timeout  10m;
ssl_session_cache shared:SSL:10m;
ssl_stapling on;
ssl_stapling_verify on;
resolver 8.8.8.8 8.8.4.4 valid=300s;
resolver_timeout 5s;
add_header X-Content-Type-Options nosniff;
add_header X-Frame-Options DENY;
add_header X-XSS-Protection "1; mode=block";
EOL

# Create Nginx configuration for Superset
cat <<EOL > /etc/nginx/sites-available/superset
server {
    listen 80;
    server_name $(hostname -I | awk '{print $1}');

    location / {
        proxy_pass http://localhost:8088;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}

server {
    listen 443 ssl;
    server_name $(hostname -I | awk '{print $1}');

    include snippets/self-signed.conf;
    include snippets/ssl-params.conf;

    location / {
        proxy_pass http://localhost:8088;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
EOL

# Enable the new configuration
sudo ln -s /etc/nginx/sites-available/superset /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx