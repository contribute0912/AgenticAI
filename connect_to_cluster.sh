#!/bin/bash

# Require PEM file and EC2 IP as environment variables, or prompt interactively
EC2_USER="ubuntu"

# Normalize the PEM file path if read from the environment variable
if [ -n "$K8S_PEM_FILE" ]; then
    PEM_FILE="$K8S_PEM_FILE"
    PEM_FILE=$(echo "$PEM_FILE" | sed 's|\\|/|g')
    echo "Normalized PEM file path: $PEM_FILE"
else
    read -p "Enter the full path to your PEM file: " PEM_FILE
    export K8S_PEM_FILE="$PEM_FILE"
    echo "K8S_PEM_FILE set to $PEM_FILE"
    echo "Normalized PEM file path: $PEM_FILE"
fi

# Quote the PEM_FILE variable wherever it is used
# Check if the environment variables are already set
if [ -z "$K8S_EC2_IP" ]; then
    while [ -z "$EC2_IP" ]; do
        read -p "Enter your EC2 public IP: " EC2_IP
        if [ -z "$EC2_IP" ]; then
            echo "Error: EC2 public IP cannot be empty. Please try again."
        fi
    done
    export K8S_EC2_IP="$EC2_IP"
    echo "K8S_EC2_IP set to $EC2_IP"
else
    EC2_IP="$K8S_EC2_IP"
    echo "Using existing K8S_EC2_IP: $EC2_IP"
fi

# Check if the PEM file exists
if [ ! -f "$PEM_FILE" ]; then
    echo "Error: PEM file not found at $PEM_FILE"
    exit 1
fi

# Copy the kubeconfig file from the EC2 instance
echo "Copying kubeconfig file from EC2 instance..."
ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$PEM_FILE" $EC2_USER@$EC2_IP "sudo cp /etc/rancher/k3s/k3s.yaml /tmp/k3s.yaml && sudo chmod 644 /tmp/k3s.yaml"
scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$PEM_FILE" $EC2_USER@$EC2_IP:/tmp/k3s.yaml "./Secrets/k3s.yaml"

# Ensure the kubeconfig file is sourced for the session
if [ -f "./Secrets/k3s.yaml" ]; then
    export KUBECONFIG="$(pwd)/Secrets/k3s.yaml"
    echo "KUBECONFIG set to $(pwd)/Secrets/k3s.yaml"

    # Add the export command to the user's bash profile for persistency (always quoted)
    if ! grep -q "export KUBECONFIG=\"$(pwd)/Secrets/k3s.yaml\"" ~/.bashrc; then
        echo "export KUBECONFIG=\"$(pwd)/Secrets/k3s.yaml\"" >> ~/.bashrc
        echo "KUBECONFIG export added to ~/.bashrc for persistency."
    fi
else
    echo "Error: Kubeconfig file not found. Please rerun the script."
    exit 1
fi

# Print the export command for the terminal session
echo "To persist the connection, run the following command in your terminal:"
echo "export KUBECONFIG=\"$(pwd)/Secrets/k3s.yaml\""

# Update the server field in the kubeconfig file
sed -i "s|server: .*|server: https://$EC2_IP:6443|" "./Secrets/k3s.yaml"

# Validate the connection
if ! kubectl cluster-info >/dev/null 2>&1; then
    echo "Error: Unable to connect to the Kubernetes cluster. Please check your configuration."
    exit 1
fi

# Test the configuration
echo "Testing Kubernetes configuration..."
if ! kubectl get pods >/dev/null 2>&1; then
    echo "Certificate validation failed. Reinstalling K3s with current IP..."
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$PEM_FILE" $EC2_USER@$EC2_IP \
        "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC='--tls-san $EC2_IP' sh -"
    
    echo "Waiting for K3s to start..."
    sleep 30
    
    # Re-fetch kubeconfig after reinstallation
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$PEM_FILE" $EC2_USER@$EC2_IP "sudo cp /etc/rancher/k3s/k3s.yaml /tmp/k3s.yaml && sudo chmod 644 /tmp/k3s.yaml"
    scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i "$PEM_FILE" $EC2_USER@$EC2_IP:/tmp/k3s.yaml "./Secrets/k3s.yaml"
    sed -i "s|server: .*|server: https://$EC2_IP:6443|" "./Secrets/k3s.yaml"
    
    echo "Retesting after K3s reinstallation..."
fi

kubectl get pods
# Ready for user commands
echo "\n✅ Connection to Kubernetes cluster established!"
echo "You can now run kubectl commands, troubleshoot, or explore cluster insights."
echo "For example:"
echo "  kubectl get pods --all-namespaces"
echo "  kubectl get nodes"
echo "  kubectl cluster-info"

# Ensure the environment variables are added to the shell's configuration file
BASHRC_FILE="$HOME/.bashrc"

# Function to add a variable if it doesn't exist
add_to_bashrc() {
    local VAR_NAME="$1"
    local VAR_VALUE="$2"
    if ! grep -q "export $VAR_NAME=\"$VAR_VALUE\"" "$BASHRC_FILE"; then
        echo "export $VAR_NAME=\"$VAR_VALUE\"" >> "$BASHRC_FILE"
        echo "$VAR_NAME added to $BASHRC_FILE."
    else
        echo "$VAR_NAME already exists in $BASHRC_FILE."
    fi
}

# Add KUBECONFIG, K8S_PEM_FILE, and K8S_EC2_IP to ~/.bashrc
add_to_bashrc "KUBECONFIG" "$(pwd)/Secrets/k3s.yaml"
add_to_bashrc "K8S_PEM_FILE" "$PEM_FILE"
add_to_bashrc "K8S_EC2_IP" "$EC2_IP"

# Reload the shell configuration file
source "$BASHRC_FILE"
echo "Reloaded $BASHRC_FILE to apply changes."