#!/bin/bash

# azure_vm_freeze_monitor.sh
# Script to monitor Azure VM maintenance events and send them to Grafana Cloud

# Check if running in check-only mode
CHECK_ONLY=false
if [[ "$1" == "--check-only" ]]; then
    CHECK_ONLY=true
fi

# Configuration
GRAFANA_CLOUD_URL="https://prometheus-us-central1.grafana.net/api/prom/push"
GRAFANA_USERNAME="your-prometheus-username"
GRAFANA_API_KEY="your-prometheus-api-key"

# Log file
LOG_FILE="/var/log/azure_vm_freeze_monitor.log"

# Function to log messages
log_message() {
    echo "$(date): $1" >> "$LOG_FILE"
}

# Function to send metrics to Grafana Cloud
send_metric() {
    local metric_name=$1
    local value=$2
    local timestamp=$(date +%s)
    
    # If in check-only mode, just output in InfluxDB format
    if $CHECK_ONLY; then
        echo "$metric_name value=$value $timestamp"
        return
    fi
    
    # Create a temporary file with the metric data
    TEMP_FILE=$(mktemp)
    cat > "$TEMP_FILE" <<EOF
# TYPE azure_vm_freeze_event gauge
# TYPE azure_vm_reboot_event gauge
# TYPE azure_vm_redeploy_event gauge
$metric_name $value $timestamp
EOF

    # Send to Grafana Cloud
    curl -X POST \
        -H "Content-Type: text/plain" \
        -u "$GRAFANA_USERNAME:$GRAFANA_API_KEY" \
        --data-binary "@$TEMP_FILE" \
        "$GRAFANA_CLOUD_URL/api/v1/write"
    
    # Clean up
    rm "$TEMP_FILE"
}

# Function to check for maintenance events
check_maintenance_events() {
    # Check for maintenance events in the Azure metadata service
    
    # Check if we're running on Azure
    if curl -s --connect-timeout 5 -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2021-02-01" > /dev/null; then
        log_message "Running on Azure VM"
        
        # Check for scheduled events
        scheduled_events=$(curl -s --connect-timeout 5 -H Metadata:true "http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01")
        
        # Initialize all event metrics to 0
        freeze_event=0
        reboot_event=0
        redeploy_event=0
        
        # Check for different types of events
        if echo "$scheduled_events" | jq -e '.Events[] | select(.EventType=="Freeze")' > /dev/null; then
            log_message "Freeze event detected"
            freeze_event=1
            
            # Extract freeze event details
            event_type=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Freeze") | .EventType')
            event_id=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Freeze") | .EventId')
            not_before=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Freeze") | .NotBefore')
            
            log_message "Freeze Event - Type: $event_type, Event ID: $event_id, Not Before: $not_before"
        fi
        
        if echo "$scheduled_events" | jq -e '.Events[] | select(.EventType=="Reboot")' > /dev/null; then
            log_message "Reboot event detected"
            reboot_event=1
            
            # Extract reboot event details
            event_type=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Reboot") | .EventType')
            event_id=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Reboot") | .EventId')
            not_before=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Reboot") | .NotBefore')
            
            log_message "Reboot Event - Type: $event_type, Event ID: $event_id, Not Before: $not_before"
        fi
        
        if echo "$scheduled_events" | jq -e '.Events[] | select(.EventType=="Redeploy")' > /dev/null; then
            log_message "Redeploy event detected"
            redeploy_event=1
            
            # Extract redeploy event details
            event_type=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Redeploy") | .EventType')
            event_id=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Redeploy") | .EventId')
            not_before=$(echo "$scheduled_events" | jq -r '.Events[] | select(.EventType=="Redeploy") | .NotBefore')
            
            log_message "Redeploy Event - Type: $event_type, Event ID: $event_id, Not Before: $not_before"
        fi
        
        # Send metrics for all event types
        send_metric "azure_vm_freeze_event" "$freeze_event" "$(date +%s)"
        send_metric "azure_vm_reboot_event" "$reboot_event" "$(date +%s)"
        send_metric "azure_vm_redeploy_event" "$redeploy_event" "$(date +%s)"
        
        # If no events detected, still send 0 values
        if [[ $freeze_event -eq 0 && $reboot_event -eq 0 && $redeploy_event -eq 0 ]]; then
            log_message "No maintenance events detected"
        fi
    else
        log_message "Not running on Azure VM"
        # Even if not on Azure, we still need to output metrics for Telegraf
        if $CHECK_ONLY; then
            echo "azure_vm_freeze_event value=0 $(date +%s)"
            echo "azure_vm_reboot_event value=0 $(date +%s)"
            echo "azure_vm_redeploy_event value=0 $(date +%s)"
        else
            send_metric "azure_vm_freeze_event" "0" "$(date +%s)"
            send_metric "azure_vm_reboot_event" "0" "$(date +%s)"
            send_metric "azure_vm_redeploy_event" "0" "$(date +%s)"
        fi
    fi
}

# Main execution
if ! $CHECK_ONLY; then
    log_message "Starting Azure VM maintenance monitor"
fi

check_maintenance_events

if ! $CHECK_ONLY; then
    log_message "Finished Azure VM maintenance monitor"
fi