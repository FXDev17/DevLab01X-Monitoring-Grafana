#!/bin/bash

# Configuration
ERROR_LOG_FILE="installation_errors.log"
INSTALLATION_LOG_FILE="installation.log"
TIMESTAMP=$(date +"%Y-%m-%d %T")

# Initialize log files
echo "Installation started at $TIMESTAMP" > $INSTALLATION_LOG_FILE
echo "Error log - Installation started at $TIMESTAMP" > $ERROR_LOG_FILE

# Function to execute commands with error handling
safe_run() {
    local description=$1
    local command=$2
    local critical=${3:-true}  # Default to critical command
    
    echo "[$TIMESTAMP] Starting: $description" >> $INSTALLATION_LOG_FILE
    echo "=== Command: $command" >> $INSTALLATION_LOG_FILE
    
    if eval "$command" >> $INSTALLATION_LOG_FILE 2>&1; then
        echo "[$TIMESTAMP] Success: $description" >> $INSTALLATION_LOG_FILE
        return 0
    else
        error_msg="[$TIMESTAMP] FAILED: $description (Command: $command)"
        echo "$error_msg" >> $ERROR_LOG_FILE
        echo "$error_msg" >> $INSTALLATION_LOG_FILE
        
        if $critical; then
            echo "Critical command failed. Check $ERROR_LOG_FILE for details."
            exit 1
        fi
        return 1
    fi
}

# Update system
safe_run "System update" "sudo yum update -y"

# Install Java 17 (Amazon Corretto)
safe_run "Install Java 17" "sudo yum install java-17-amazon-corretto -y"

# Install Python 3 and pip3
safe_run "Install Python 3" "sudo yum install python3 -y"
safe_run "Install pip3" "sudo yum install python3-pip -y"

# Install virtualenv
safe_run "Install virtualenv" "sudo pip3 install virtualenv" false  # Not critical

# Create virtual environment
safe_run "Create virtual environment" "sudo python3 -m venv /opt/security-tools-env" false

# Install tools in virtual environment
safe_run "Install Checkov" "source /opt/security-tools-env/bin/activate && sudo pip install checkov && deactivate" false

# Jenkins setup
safe_run "Download Jenkins repo" "sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo"
safe_run "Import Jenkins GPG key" "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key"
safe_run "Install Jenkins" "sudo yum install -y jenkins"
safe_run "Enable Jenkins" "sudo systemctl enable jenkins"
safe_run "Start Jenkins" "sudo systemctl start jenkins"

# Terraform installation
safe_run "Install yum-utils" "sudo yum install -y yum-utils"
safe_run "Add HashiCorp repo" "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo"
safe_run "Install Terraform" "sudo yum install -y terraform"

# Security tools
safe_run "Install Trivy" "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin" false

safe_run "Install Node.js and npm" "sudo yum install -y nodejs npm"
safe_run "Install Snyk" "sudo npm install -g snyk" false

safe_run "Download Gitleaks" "curl -LO https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz" false
safe_run "Install Gitleaks" "sudo tar -xzvf gitleaks_8.18.2_linux_x64.tar.gz -C /usr/local/bin" false

# Final Jenkins restart
safe_run "Restart Jenkins" "sudo systemctl restart jenkins" false

echo "Installation completed with potential non-critical errors. Check logs:"
echo " - Full log: $INSTALLATION_LOG_FILE"
echo " - Errors only: $ERROR_LOG_FILE"