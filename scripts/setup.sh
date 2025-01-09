#!/bin/bash

# Disable swap
echo "Disabling swap..."
sudo swapoff -a
sudo sed -i '/swap/d' /etc/fstab

# Update the system and install necessary dependencies
echo "Updating the system and installing necessary tools..."
sudo apt update -y && sudo apt upgrade -y
sudo apt install apt-transport-https ca-certificates curl software-properties-common lsb-release gnupg2 htop -y

# Install Docker
echo "Installing Docker..."
sudo curl -fsSL https://get.docker.com | bash
sudo systemctl enable docker
sudo systemctl start docker

# Add Kubernetes repository
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Update APT sources
echo "Updating APT sources..."
sudo apt update -y

# Install Kubernetes packages (kubeadm, kubelet, kubectl)
echo "Installing kubeadm, kubelet, and kubectl..."
sudo apt install -y kubeadm kubelet kubectl

# Mark the packages as "hold" to prevent automatic updates
sudo apt-mark hold kubeadm kubelet kubectl

# Enable kubelet to start on boot
sudo systemctl enable kubelet

# Configure the kernel for Kubernetes
echo "Configuring the kernel..."
sudo modprobe br_netfilter
echo "1" | sudo tee /proc/sys/net/ipv4/ip_forward
sudo sysctl -w net.ipv4.ip_forward=1
sudo sysctl net.bridge.bridge-nf-call-iptables=1
sudo sysctl net.bridge.bridge-nf-call-ip6tables=1
