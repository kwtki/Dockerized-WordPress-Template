sudo yum install -y docker
# Add user to user group
groups $USER
sudo usermod -aG docker $USER

# Install `docker compose` V2
sudo mkdir -p /usr/local/lib/docker/cli-plugins
sudo yum install -y jq
DOCKER_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | jq -r .tag_name)
sudo curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)" -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod +x /usr/local/lib/docker/cli-plugins/docker-compose
docker compose version

# Run docker service
sudo systemctl start docker
sudo systemctl enable docker

# Change docker permission
sudo chown root:docker /var/run/docker.sock
sudo chmod 666 /var/run/docker.sock
sudo systemctl restart docker

