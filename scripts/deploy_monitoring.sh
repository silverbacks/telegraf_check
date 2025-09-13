#!/bin/bash

# deploy_monitoring.sh
# Deployment script for the Azure VM monitoring solution

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Detect OS version
detect_os() {
    if [ -f /etc/redhat-release ]; then
        if grep -q "release 7" /etc/redhat-release; then
            OS_VERSION="rhel7"
            log "Detected RHEL 7"
        elif grep -q "release 8" /etc/redhat-release; then
            OS_VERSION="rhel8"
            log "Detected RHEL 8"
        else
            error "Unsupported RHEL version"
            exit 1
        fi
    else
        error "This script is designed for RHEL systems only"
        exit 1
    fi
}

# Install Telegraf
install_telegraf() {
    log "Installing Telegraf..."
    
    if [ "$OS_VERSION" = "rhel7" ]; then
        cat <<EOF > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL 7
baseurl = https://repos.influxdata.com/rhel/7/x86_64/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF
        yum update -y
        yum install telegraf -y
    else
        cat <<EOF > /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL 8
baseurl = https://repos.influxdata.com/rhel/8/x86_64/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF
        dnf update -y
        dnf install telegraf -y
    fi
    
    log "Telegraf installed successfully"
}

# Configure Telegraf
configure_telegraf() {
    log "Configuring Telegraf..."
    
    # Backup existing config
    if [ -f /etc/telegraf/telegraf.conf ]; then
        cp /etc/telegraf/telegraf.conf /etc/telegraf/telegraf.conf.backup.$(date +%Y%m%d_%H%M%S)
        log "Backed up existing Telegraf config"
    fi
    
    # Copy new config (assuming it's in the current directory)
    if [ -f "./configs/telegraf.conf" ]; then
        cp ./configs/telegraf.conf /etc/telegraf/telegraf.conf
        log "Copied new Telegraf config"
    else
        error "Telegraf config file not found"
        exit 1
    fi
    
    # Set proper permissions
    chown telegraf:telegraf /etc/telegraf/telegraf.conf
    chmod 644 /etc/telegraf/telegraf.conf
    
    log "Telegraf configured successfully"
}

# Configure Azure VM freeze monitoring
configure_azure_monitoring() {
    log "Configuring Azure VM freeze monitoring..."
    
    # Copy the monitoring script
    cp ./scripts/azure_vm_freeze_monitor.sh /usr/local/bin/
    chmod +x /usr/local/bin/azure_vm_freeze_monitor.sh
    
    # Copy systemd files
    cp ./scripts/azure-vm-freeze-monitor.service /etc/systemd/system/
    cp ./scripts/azure-vm-freeze-monitor.timer /etc/systemd/system/
    
    # Reload systemd
    systemctl daemon-reload
    
    # Enable and start the timer
    systemctl enable azure-vm-freeze-monitor.timer
    systemctl start azure-vm-freeze-monitor.timer
    
    log "Azure VM freeze monitoring configured successfully"
}

# Start services
start_services() {
    log "Starting services..."
    
    # Start Telegraf
    systemctl enable telegraf
    systemctl restart telegraf
    
    # Check if services are running
    if systemctl is-active --quiet telegraf; then
        log "Telegraf is running"
    else
        error "Failed to start Telegraf"
        exit 1
    fi
    
    if systemctl is-active --quiet azure-vm-freeze-monitor.timer; then
        log "Azure VM freeze monitor timer is active"
    else
        error "Failed to start Azure VM freeze monitor timer"
        exit 1
    fi
    
    log "Services started successfully"
}

# Main function
main() {
    log "Starting Azure VM monitoring deployment..."
    
    check_root
    detect_os
    install_telegraf
    configure_telegraf
    configure_azure_monitoring
    start_services
    
    log "Deployment completed successfully!"
    echo
    log "Next steps:"
    log "1. Update /etc/telegraf/telegraf.conf with your Grafana Cloud credentials"
    log "2. Update /usr/local/bin/azure_vm_freeze_monitor.sh with your Grafana Cloud credentials"
    log "3. Configure alert rules in Grafana Cloud or Mimir"
    log "4. Verify that metrics are being collected and sent to Grafana Cloud"
}

# Run main function
main "$@"