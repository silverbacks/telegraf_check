#!/bin/bash

# validate_setup.sh
# Script to validate the Azure VM monitoring setup

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
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
        warn "This script should ideally be run as root for complete validation"
    fi
}

# Check OS version
check_os() {
    info "Checking OS version..."
    if [ -f /etc/redhat-release ]; then
        if grep -q "release 7" /etc/redhat-release; then
            log "Detected RHEL 7"
        elif grep -q "release 8" /etc/redhat-release; then
            log "Detected RHEL 8"
        else
            warn "Unsupported RHEL version detected"
        fi
    else
        warn "This validation script is designed for RHEL systems"
    fi
}

# Check if required packages are installed
check_packages() {
    info "Checking for required packages..."
    
    # Check for Telegraf
    if command -v telegraf &> /dev/null; then
        log "Telegraf is installed: $(telegraf --version)"
    else
        error "Telegraf is not installed"
    fi
    
    # Check for curl
    if command -v curl &> /dev/null; then
        log "curl is installed"
    else
        error "curl is not installed"
    fi
    
    # Check for jq
    if command -v jq &> /dev/null; then
        log "jq is installed"
    else
        warn "jq is not installed (recommended for Azure metadata parsing)"
    fi
}

# Check Telegraf configuration
check_telegraf_config() {
    info "Checking Telegraf configuration..."
    
    if [ -f /etc/telegraf/telegraf.conf ]; then
        log "Main Telegraf configuration found"
        
        # Check if the configuration is valid
        if telegraf --config /etc/telegraf/telegraf.conf --test &> /dev/null; then
            log "Telegraf configuration is valid"
        else
            error "Telegraf configuration is invalid"
        fi
    else
        error "Main Telegraf configuration not found"
    fi
    
    # Check for Azure monitoring configuration
    if [ -f /etc/telegraf/telegraf.d/azure_monitoring.conf ]; then
        log "Azure monitoring configuration found"
    else
        warn "Azure monitoring configuration not found"
    fi
}

# Check Telegraf service status
check_telegraf_service() {
    info "Checking Telegraf service status..."
    
    if systemctl is-active --quiet telegraf; then
        log "Telegraf service is running"
    else
        error "Telegraf service is not running"
    fi
    
    if systemctl is-enabled --quiet telegraf; then
        log "Telegraf service is enabled"
    else
        warn "Telegraf service is not enabled"
    fi
}

# Check Azure VM maintenance events monitor
check_azure_monitor() {
    info "Checking Azure VM maintenance events monitor..."
    
    # Check if the script exists
    if [ -f /usr/local/bin/azure_vm_freeze_monitor.sh ]; then
        log "Azure VM maintenance events monitor script found"
        
        # Check if it's executable
        if [ -x /usr/local/bin/azure_vm_freeze_monitor.sh ]; then
            log "Azure VM maintenance events monitor script is executable"
        else
            error "Azure VM maintenance events monitor script is not executable"
        fi
    else
        error "Azure VM maintenance events monitor script not found"
    fi
    
    # Check systemd service and timer
    if systemctl is-active --quiet azure-vm-freeze-monitor.timer; then
        log "Azure VM maintenance events monitor timer is active"
    else
        error "Azure VM maintenance events monitor timer is not active"
    fi
    
    if systemctl is-enabled --quiet azure-vm-freeze-monitor.timer; then
        log "Azure VM maintenance events monitor timer is enabled"
    else
        warn "Azure VM maintenance events monitor timer is not enabled"
    fi
}

# Check network connectivity
check_network() {
    info "Checking network connectivity..."
    
    # Check connectivity to Azure metadata service
    if curl -s --connect-timeout 5 -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" &> /dev/null; then
        log "Azure metadata service is accessible"
    else
        warn "Cannot reach Azure metadata service (this is expected if not running on Azure)"
    fi
    
    # Check connectivity to localhost Telegraf endpoint (if configured)
    if curl -s --connect-timeout 5 "http://localhost:9273/metrics" &> /dev/null; then
        log "Telegraf Prometheus endpoint is accessible"
    else
        info "Telegraf Prometheus endpoint is not accessible (this is expected if not configured)"
    fi
}

# Check log files
check_logs() {
    info "Checking log files..."
    
    if [ -f /var/log/azure_vm_freeze_monitor.log ]; then
        log "Azure VM maintenance events monitor log file found"
        
        # Check if log file has recent entries
        if [ -s /var/log/azure_vm_freeze_monitor.log ]; then
            log "Azure VM maintenance events monitor log file contains entries"
        else
            warn "Azure VM maintenance events monitor log file is empty"
        fi
    else
        warn "Azure VM maintenance events monitor log file not found"
    fi
}

# Check for common configuration issues
check_config_issues() {
    info "Checking for common configuration issues..."
    
    # Check for placeholder credentials in Telegraf config
    if [ -f /etc/telegraf/telegraf.conf ]; then
        if grep -q "your-prometheus-username" /etc/telegraf/telegraf.conf; then
            error "Placeholder username found in Telegraf configuration"
        fi
        
        if grep -q "your-prometheus-api-key" /etc/telegraf/telegraf.conf; then
            error "Placeholder API key found in Telegraf configuration"
        fi
    fi
    
    # Check for placeholder credentials in maintenance events monitor script
    if [ -f /usr/local/bin/azure_vm_freeze_monitor.sh ]; then
        if grep -q "your-prometheus-username" /usr/local/bin/azure_vm_freeze_monitor.sh; then
            error "Placeholder username found in maintenance events monitor script"
        fi
        
        if grep -q "your-prometheus-api-key" /usr/local/bin/azure_vm_freeze_monitor.sh; then
            error "Placeholder API key found in maintenance events monitor script"
        fi
    fi
}

# Check Telegraf internal metrics
check_telegraf_internal() {
    info "Checking Telegraf internal metrics configuration..."
    
    # Check if internal plugin is configured
    if [ -f /etc/telegraf/telegraf.conf ]; then
        if grep -q "\[\[inputs.internal\]\]" /etc/telegraf/telegraf.conf; then
            log "Telegraf internal plugin is configured"
        else
            warn "Telegraf internal plugin is not configured"
        fi
    fi
}

# Check Azure VM maintenance events monitoring
check_azure_maintenance_events() {
    info "Checking Azure VM maintenance events monitoring configuration..."
    
    # Check if exec plugin is configured for maintenance events in azure_monitoring.conf
    if [ -f /etc/telegraf/telegraf.d/azure_monitoring.conf ]; then
        if grep -q "azure_vm_freeze_monitor.sh --check-only" /etc/telegraf/telegraf.d/azure_monitoring.conf; then
            log "Azure VM maintenance events monitoring is configured in azure_monitoring.conf"
        else
            warn "Azure VM maintenance events monitoring is not configured in azure_monitoring.conf"
        fi
    fi
}

# Main validation function
main() {
    log "Starting Azure VM monitoring setup validation..."
    
    check_root
    check_os
    check_packages
    check_telegraf_config
    check_telegraf_service
    check_azure_monitor
    check_network
    check_logs
    check_config_issues
    check_telegraf_internal
    check_azure_maintenance_events
    
    log "Validation complete. Please review any warnings or errors above."
    log "For detailed troubleshooting, check the documentation in the repository."
    log "To verify that Telegraf is sending metrics, check for the 'internal_agent_metrics_written' metric in Grafana Cloud."
    log "To verify that Azure VM maintenance events are being detected, check the logs at /var/log/azure_vm_freeze_monitor.log"
}

# Run main function
main "$@"