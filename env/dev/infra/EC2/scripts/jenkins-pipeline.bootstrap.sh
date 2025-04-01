#!/bin/bash

# Configuration
ERROR_LOG_FILE="/var/log/installation_errors.log"
INSTALLATION_LOG_FILE="/var/log/installation.log"
TIMESTAMP=$(date +"%Y-%m-%d %T")
DOWNLOAD_DIR="/tmp/downloads"  # Temporary directory for downloads

# Ensure log directory exists and set permissions
sudo mkdir -p /var/log
sudo touch "$INSTALLATION_LOG_FILE" "$ERROR_LOG_FILE"
sudo chmod 644 "$INSTALLATION_LOG_FILE" "$ERROR_LOG_FILE"

# Initialize log files
echo "=== Installation Started at $TIMESTAMP ===" | tee -a "$INSTALLATION_LOG_FILE"
echo "=== Error Log - Started at $TIMESTAMP ===" | tee -a "$ERROR_LOG_FILE"
echo "" | tee -a "$INSTALLATION_LOG_FILE" "$ERROR_LOG_FILE"

# Create download directory
mkdir -p "$DOWNLOAD_DIR"

# Function to execute commands with error handling
safe_run() {
    local description=$1
    local command=$2
    local critical=${3:-true}  # Default to critical
    
    echo "[$TIMESTAMP] Starting: $description" | tee -a "$INSTALLATION_LOG_FILE"
    echo "  Command: $command" | tee -a "$INSTALLATION_LOG_FILE"
    
    if eval "$command" >> "$INSTALLATION_LOG_FILE" 2>&1; then
        echo "[$TIMESTAMP] SUCCESS: $description" | tee -a "$INSTALLATION_LOG_FILE"
        echo "" | tee -a "$INSTALLATION_LOG_FILE"
        return 0
    else
        error_msg="[$TIMESTAMP] FAILED: $description (Command: $command)"
        echo "$error_msg" | tee -a "$INSTALLATION_LOG_FILE" "$ERROR_LOG_FILE"
        echo "" | tee -a "$INSTALLATION_LOG_FILE" "$ERROR_LOG_FILE"
        
        if $critical; then
            echo "Critical failure: $description. Aborting. Check $ERROR_LOG_FILE for details." | tee -a "$INSTALLATION_LOG_FILE"
            exit 1
        fi
        return 1
    fi
}

# Function to download files with logging
safe_download() {
    local description=$1
    local url=$2
    local output_file=$3
    local critical=${4:-true}
    
    echo "[$TIMESTAMP] Downloading: $description" | tee -a "$INSTALLATION_LOG_FILE"
    echo "  URL: $url" | tee -a "$INSTALLATION_LOG_FILE"
    
    if curl -sL "$url" -o "$output_file" 2>>"$INSTALLATION_LOG_FILE"; then
        echo "[$TIMESTAMP] SUCCESS: Downloaded $description to $output_file" | tee -a "$INSTALLATION_LOG_FILE"
        echo "" | tee -a "$INSTALLATION_LOG_FILE"
        return 0
    else
        error_msg="[$TIMESTAMP] FAILED: Download of $description from $url"
        echo "$error_msg" | tee -a "$INSTALLATION_LOG_FILE" "$ERROR_LOG_FILE"
        echo "" | tee -a "$INSTALLATION_LOG_FILE" "$ERROR_LOG_FILE"
        
        if $critical; then
            echo "Critical download failure: $description. Aborting." | tee -a "$INSTALLATION_LOG_FILE"
            exit 1
        fi
        return 1
    fi
}

# Update system
safe_run "Update system packages" "sudo yum update -y"

# Install Java 17 (Amazon Corretto)
safe_run "Install Java 17" "sudo yum install java-17-amazon-corretto -y"

# Install Python 3 and pip3
safe_run "Install Python 3" "sudo yum install python3 -y"
safe_run "Install pip3" "sudo yum install python3-pip -y"

# Install virtualenv
safe_run "Install virtualenv" "sudo pip3 install virtualenv" false

# Create virtual environment
safe_run "Create security tools virtualenv" "sudo python3 -m venv /opt/security-tools-env" false

# Install Checkov in virtual environment
safe_run "Install Checkov" "source /opt/security-tools-env/bin/activate && sudo pip install checkov && deactivate" false

# Jenkins setup
safe_download "Download Jenkins repo" "https://pkg.jenkins.io/redhat-stable/jenkins.repo" "/etc/yum.repos.d/jenkins.repo"
safe_run "Import Jenkins GPG key" "sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key"
safe_run "Install Jenkins" "sudo yum install -y jenkins"
safe_run "Enable Jenkins service" "sudo systemctl enable jenkins"
safe_run "Start Jenkins service" "sudo systemctl start jenkins"

# Terraform installation
safe_run "Install yum-utils" "sudo yum install -y yum-utils"
safe_run "Add HashiCorp repo" "sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo"
safe_run "Install Terraform" "sudo yum install -y terraform"

# Security tools
safe_run "Install Trivy" "curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin" false

safe_run "Install Node.js and npm" "sudo yum install -y nodejs npm"
safe_run "Install Snyk globally" "sudo npm install -g snyk" false

safe_download "Download Gitleaks" "https://github.com/gitleaks/gitleaks/releases/download/v8.18.2/gitleaks_8.18.2_linux_x64.tar.gz" "$DOWNLOAD_DIR/gitleaks.tar.gz" false
safe_run "Extract Gitleaks" "sudo tar -xzvf $DOWNLOAD_DIR/gitleaks.tar.gz -C /usr/local/bin gitleaks" false

# Final Jenkins restart
safe_run "Restart Jenkins service" "sudo systemctl restart jenkins" false

# Cleanup download directory
rm -rf "$DOWNLOAD_DIR"

# Summary
echo "=== Installation Completed at $(date +'%Y-%m-%d %T') ===" | tee -a "$INSTALLATION_LOG_FILE"
echo "Summary:" | tee -a "$INSTALLATION_LOG_FILE"
echo " - Logs stored at: $INSTALLATION_LOG_FILE" | tee -a "$INSTALLATION_LOG_FILE"
echo " - Errors (if any) stored at: $ERROR_LOG_FILE" | tee -a "$INSTALLATION_LOG_FILE"
echo "Check logs for details of any non-critical failures." | tee -a "$INSTALLATION_LOG_FILE"