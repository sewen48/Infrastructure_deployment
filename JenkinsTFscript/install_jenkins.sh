#!/bin/bash

# Exit on any error
set -e

# Function to log messages
log() {
    echo "[$(date +'%Y-%m-%dT%H:%M:%S')]: $1"
}

log "Starting Jenkins installation..."

# Wait for apt to be available
while sudo fuser /var/lib/dpkg/lock >/dev/null 2>&1 ; do
    log "Waiting for other package manager to finish..."
    sleep 1
done

# Update package list
log "Updating package list..."
sudo apt-get update

# Install required packages
log "Installing required packages..."
sudo apt-get install -y software-properties-common apt-transport-https wget

# Add Jenkins repository key
log "Adding Jenkins repository key..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null

# Add Jenkins repository
log "Adding Jenkins repository..."
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# Update package list again
log "Updating package list with new repositories..."
sudo apt-get update

# Install Java
log "Installing Java..."
sudo apt-get install -y openjdk-17-jre-headless

# Install Jenkins
log "Installing Jenkins..."
sudo apt-get install -y jenkins

# Start Jenkins
log "Starting Jenkins service..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install Maven
log "Installing Maven..."
sudo apt-get install -y maven

# Add HashiCorp GPG key
log "Adding HashiCorp repository..."
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add HashiCorp repository
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

# Update and install Terraform
log "Installing Terraform..."
sudo apt-get update
sudo apt-get install -y terraform

# Wait for Jenkins to start and create initial admin password
log "Waiting for Jenkins to start and generate the initial admin password..."
while [ ! -f /var/lib/jenkins/secrets/initialAdminPassword ]; do
    log "Waiting for Jenkins password file..."
    sleep 2
done

# Get Jenkins password
JENKINS_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
echo "Jenkins initial admin password: $JENKINS_PASSWORD"
echo "$JENKINS_PASSWORD" | sudo tee /home/ubuntu/jenkins_password.txt > /dev/null
sudo chown ubuntu:ubuntu /home/ubuntu/jenkins_password.txt
sudo chmod 600 /home/ubuntu/jenkins_password.txt

log "Installation completed successfully!"

