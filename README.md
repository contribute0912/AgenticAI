# AgenticAI

## KubernetesExpert Agent

### Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/<your-org>/AgenticAI.git
   cd AgenticAI
   ```

2. **Prepare your AWS EC2 instance:**
   - Launch an EC2 instance and install k3s.
   - Note the public IP address of your EC2 instance.
   - Download your PEM file for SSH access.

3. **Set your PEM file and EC2 IP as environment variables:**
    - On Windows, ensure you use double backslashes (`\\`) in the PEM file path. For example:
       ```bash
       export K8S_PEM_FILE="C:\\path\\to\\your.pem"
       export K8S_EC2_IP="your.ec2.public.ip"
       ```
    - On macOS/Linux, use forward slashes (`/`) in the PEM file path. For example:
       ```bash
       export K8S_PEM_FILE="/absolute/path/to/your.pem"
       export K8S_EC2_IP="your.ec2.public.ip"
       ```
    - The script will use these values automatically. If not set, it will prompt you to enter them.

4. **Run the connection script:**
   ```bash
   bash ./AgenticAI/connect_to_cluster.sh
   ```

5. **Verify your connection:**
   ```bash
   kubectl get pods --all-namespaces
   ```

### Troubleshooting

- If you see errors about missing PEM or kubeconfig, double-check your file paths and permissions.
- If you see certificate errors, try adding `--insecure-skip-tls-verify` to your `kubectl` commands.
- Make sure your EC2 instance is running and accessible from your local machine.


### Overview
KubernetesExpert is a custom GitHub Copilot agent designed to assist with managing Kubernetes clusters. It provides functionality to connect to a Kubernetes cluster and execute commands efficiently while ensuring safe and secure operations.

### Features
- Executes Kubernetes commands securely and efficiently.
- Avoids redundant SSH connections by enabling direct interaction with the cluster.
- Read-only operations to maintain cluster safety.
- Displays a default welcome message when launched.

### Prerequisites
- A valid `.pem` file for initial setup (if required).
- The public IP address of the EC2 instance (for initial kubeconfig retrieval).
- `kubectl` installed on the local machine.

### Usage
1. Run the connection script to automatically set up your local machine:
   ```bash
   ./AgenticAI/connect_to_cluster.sh
   ```

2. Verify the connection:
   ```bash
   kubectl cluster-info
   ```

3. Test basic functionality by listing all pods:
   ```bash
   kubectl get pods --all-namespaces
   ```

### Security Measures
- The `.pem` file is required for SSH connections and should be stored securely.
- The kubeconfig file permissions are set to ensure only the current user can access it.
- All operations are read-only to prevent accidental modifications to the cluster.

### Important Notes
- Ensure the Kubernetes cluster is properly configured before use.
- All operations are read-only to maintain cluster safety.