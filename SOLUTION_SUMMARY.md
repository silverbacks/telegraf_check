# Azure VM Linux Monitoring Solution Summary

This document provides an overview of the comprehensive monitoring solution for RHEL 7 and RHEL 8 servers running on Azure VMs, with integration to Prometheus, Grafana Cloud, and Alertmanager using Mimir.

## Solution Components

### 1. Telegraf Configuration
- **File**: `configs/telegraf.conf`
- **Purpose**: Collects system metrics from RHEL servers
- **Metrics Collected**:
  - CPU usage (per-core and total)
  - Memory usage
  - Disk usage and I/O statistics
  - Network interface statistics
  - System information
  - Process information
  - Swap usage
  - Kernel metrics
  - **Telegraf internal metrics** - For monitoring Telegraf itself

### 2. Azure VM Maintenance Event Monitoring
- **Script**: `scripts/azure_vm_freeze_monitor.sh`
- **Systemd Service**: `scripts/azure-vm-freeze-monitor.service`
- **Systemd Timer**: `scripts/azure-vm-freeze-monitor.timer`
- **Configuration**: `configs/azure_monitoring.conf`
- **Purpose**: Detects Azure VM maintenance events through the Azure Instance Metadata Service
- **Functionality**:
  - Periodically checks for scheduled events (Freeze, Reboot, Redeploy, Preempt, Terminate)
  - Reports all event types to Grafana Cloud
  - Logs event details for troubleshooting

### 3. Alert Rules
- **File**: `alerts/azure-vm-alerts.yaml`
- **Purpose**: Defines alert conditions for Mimir/Alertmanager
- **Alerts Included**:
  - Azure VM freeze events
  - Azure VM reboot events
  - Azure VM redeploy events
  - High CPU load (>85%)
  - High memory usage (>85%)
  - Low disk space (>90%)
  - High disk I/O
  - Network interface down
  - Systemd service failures
  - **Telegraf agent status** - Alerts when Telegraf stops sending metrics

### 4. Deployment Automation
- **Script**: `scripts/deploy_monitoring.sh`
- **Purpose**: Automates the installation and configuration of the monitoring solution
- **Functionality**:
  - Detects RHEL version (7 or 8)
  - Installs Telegraf
  - Configures Telegraf with provided settings
  - Sets up Azure VM maintenance event monitoring
  - Starts and enables all services

### 5. Grafana Dashboard
- **File**: `configs/grafana_dashboard.json`
- **Purpose**: Provides visualization of collected metrics
- **Panels Included**:
  - CPU usage graphs
  - Memory usage graphs
  - Disk I/O statistics
  - Network traffic visualization
  - Disk space usage
  - Azure VM maintenance events

### 6. Documentation
- **File**: `docs/grafana_cloud_setup.md`
- **Purpose**: Detailed instructions for setting up Grafana Cloud and Mimir
- **Content**:
  - Grafana Cloud account setup
  - Prometheus configuration
  - Alertmanager configuration
  - Deployment instructions
  - Dashboard setup
  - Alert configuration
  - Troubleshooting guide

## Architecture Overview

```
┌─────────────────┐    ┌──────────────┐    ┌──────────────────┐
│   Azure VM      │    │              │    │   Grafana Cloud  │
│  (RHEL 7/8)     │    │              │    │                  │
│                 │    │              │    │  ┌────────────┐  │
│ ┌─────────────┐ │    │              │    │  │ Prometheus │  │
│ │  Telegraf   │─┼────┤  Internet    ├────┼─▶│   (Mimir)  │  │
│ └─────────────┘ │    │              │    │  └────────────┘  │
│                 │    │              │    │                  │
│ ┌─────────────┐ │    │              │    │  ┌────────────┐  │
│ │Azure Events │ │    │              │    │  │Alertmanager│  │
│ │  Monitor    │─┼────┤              ├────┼─▶│   (Mimir)  │  │
│ └─────────────┘ │    │              │    │  └────────────┘  │
│                 │    │              │    │                  │
│ ┌─────────────┐ │    │              │    │  ┌────────────┐  │
│ │Systemd Timer│ │    │              │    │  │ Dashboards │  │
│ └─────────────┘ │    │              │    │  └────────────┘  │
└─────────────────┘    └──────────────┘    └──────────────────┘
```

## Deployment Process

1. **Prepare Azure VMs**:
   - Ensure RHEL 7 or RHEL 8 is installed
   - Verify network connectivity to Grafana Cloud

2. **Configure Credentials**:
   - Update Telegraf configuration with Grafana Cloud credentials
   - Update Azure VM maintenance monitor script with Grafana Cloud credentials

3. **Deploy Solution**:
   - Run the deployment script on each VM:
     ```bash
     sudo ./scripts/deploy_monitoring.sh
     ```
   - Or follow manual deployment steps in the documentation

4. **Configure Grafana Cloud**:
   - Import the provided dashboard JSON
   - Configure alert rules in Mimir
   - Set up notification channels

5. **Verify Operation**:
   - Check that metrics are appearing in Grafana
   - Verify that alerts are configured correctly
   - Test the Azure VM maintenance event detection

## Key Features

### Comprehensive System Monitoring
- Collects detailed system metrics from all RHEL servers
- Provides real-time visibility into system performance
- Enables proactive issue detection

### Azure-Specific Monitoring
- Detects Azure VM maintenance events (Freeze, Reboot, Redeploy, Preempt, Terminate) before they impact services
- Integrates with Azure Instance Metadata Service
- Provides early warning of planned maintenance
- **Configuration separated into dedicated file** - `configs/azure_monitoring.conf`

### Metrics Visualization in Grafana

The Azure monitoring configuration generates several types of metrics that appear in Grafana:

1. **Azure VM Metadata Metrics** (`azure_vm_metadata`):
   - Tags: location, name, osType, vmSize
   - Fields: location, name, osType, vmSize (as strings)
   - Use case: Inventory tracking, resource planning

2. **Azure Scheduled Events Metrics** (`azure_scheduled_events`):
   - Tags: EventType, ResourceType, Resources, EventStatus, EventSource
   - Fields: EventId, Status, NotBefore, Description, EventSource, DurationInSeconds (timestamps and strings)
   - Use case: Maintenance planning, impact assessment

3. **Custom Maintenance Event Metrics**:
   - `azure_vm_freeze_event` (gauge: 0 or 1)
   - `azure_vm_reboot_event` (gauge: 0 or 1)
   - `azure_vm_redeploy_event` (gauge: 0 or 1)
   - `azure_vm_preempt_event` (gauge: 0 or 1)
   - `azure_vm_terminate_event` (gauge: 0 or 1)
   - Use case: Alerting, dashboard indicators

### Scalable Architecture
- Designed to work with any number of Azure VMs
- Uses industry-standard tools (Telegraf, Prometheus)
- Integrates with Grafana Cloud for enterprise-grade visualization

### Automated Alerting
- Pre-configured alert rules for common issues
- Integration with Mimir for reliable alert processing
- Configurable notification channels
- **Telegraf agent monitoring** - Alerts when Telegraf stops working
- **Azure VM maintenance event alerts** - Separate alerts for Freeze, Reboot, Redeploy, Preempt, and Terminate events

### Easy Deployment
- Automated deployment script simplifies setup
- Works with both RHEL 7 and RHEL 8
- Clear documentation for manual deployment

## Security Considerations

- All communication with Grafana Cloud uses HTTPS
- API keys should be properly secured and rotated regularly
- Systemd services run with minimal required privileges
- Log files are properly secured

## Maintenance

- Regular updates to Telegraf for security patches
- Monitoring of alert rule effectiveness
- Review of dashboard panels for relevance
- Verification of Azure VM maintenance event detection
- **Monitoring of Telegraf agent status** - Using the `internal_agent_metrics_written` metric