# Azure VM Linux Monitoring with Telegraf, Prometheus, and Grafana Cloud

This repository contains configuration files for comprehensive monitoring of RHEL 7 and RHEL 8 servers running on Azure VMs. The setup includes:

1. Telegraf for collecting system metrics
2. Custom monitoring for Azure VM maintenance events (Freeze, Reboot, Redeploy)
3. Integration with Prometheus and Grafana Cloud
4. Alerting through Alertmanager using Mimir

## Directory Structure

- `configs/` - Telegraf configuration files
- `scripts/` - Scripts for monitoring Azure VM events
- `alerts/` - Alert rules for Mimir/Alertmanager
- `docs/` - Documentation for setting up the solution

## Components

### Telegraf Configuration
- Main configuration: `configs/telegraf.conf`
- Azure-specific configuration: `configs/azure_monitoring.conf`

### Azure VM Maintenance Event Monitoring
- Monitoring script: `scripts/azure_vm_freeze_monitor.sh`
- Systemd service: `scripts/azure-vm-freeze-monitor.service`
- Systemd timer: `scripts/azure-vm-freeze-monitor.timer`

### Alert Rules
- Alert definitions: `alerts/azure-vm-alerts.yaml`

### Deployment Automation
- Deployment script: `scripts/deploy_monitoring.sh`
- Validation script: `scripts/validate_setup.sh`

### Visualization
- Grafana dashboard: `configs/grafana_dashboard.json`
- Sample Azure dashboard: `configs/sample_azure_dashboard.json`

### Documentation
- Setup guide: `docs/grafana_cloud_setup.md`
- Solution summary: `SOLUTION_SUMMARY.md`
- Customization guide: `CUSTOMIZATION_GUIDE.md`
- Deployment checklist: `DEPLOYMENT_CHECKLIST.md`

## Setup Instructions

### 1. Install Telegraf on RHEL 7/8

For RHEL 7:
```bash
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL 7
baseurl = https://repos.influxdata.com/rhel/7/x86_64/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo yum update
sudo yum install telegraf
```

For RHEL 8:
```bash
cat <<EOF | sudo tee /etc/yum.repos.d/influxdb.repo
[influxdb]
name = InfluxDB Repository - RHEL 8
baseurl = https://repos.influxdata.com/rhel/8/x86_64/stable
enabled = 1
gpgcheck = 1
gpgkey = https://repos.influxdata.com/influxdb.key
EOF

sudo dnf update
sudo dnf install telegraf
```

### 2. Configure Telegraf

Copy the configuration files to the Telegraf directory:
```bash
sudo cp configs/telegraf.conf /etc/telegraf/telegraf.conf
sudo cp configs/azure_monitoring.conf /etc/telegraf/telegraf.d/
```

Update the configurations with your Grafana Cloud credentials:
- Replace `your-prometheus-username` with your Grafana Cloud Prometheus username
- Replace `your-prometheus-api-key` with your Grafana Cloud API key

Update the Azure VM maintenance events monitor script:
- Replace `your-prometheus-username` with your Grafana Cloud Prometheus username
- Replace `your-prometheus-api-key` with your Grafana Cloud API key

### 3. Set up Azure VM Maintenance Event Monitoring

1. Copy the monitoring script to a system directory:
   ```bash
   sudo cp scripts/azure_vm_freeze_monitor.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/azure_vm_freeze_monitor.sh
   ```

2. Install the systemd service and timer:
   ```bash
   sudo cp scripts/azure-vm-freeze-monitor.service /etc/systemd/system/
   sudo cp scripts/azure-vm-freeze-monitor.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable azure-vm-freeze-monitor.timer
   sudo systemctl start azure-vm-freeze-monitor.timer
   ```

### 4. Configure Alerting

Copy the alert rules to your Mimir/Alertmanager configuration:
```bash
# This depends on your specific setup
# You may need to copy the file to a specific directory or
# import it through the Grafana UI
```

The alert rules include:
- Azure VM freeze events
- Azure VM reboot events
- Azure VM redeploy events
- Azure VM preempt events
- Azure VM terminate events
- High CPU load
- High memory usage
- Low disk space
- High disk I/O
- Network interface down
- Systemd service failures
- **Telegraf agent status** - Alerts when Telegraf stops sending metrics

### 5. Start Services

Start and enable Telegraf:
```bash
sudo systemctl start telegraf
sudo systemctl enable telegraf
```

## Validation

Use the validation script to check your setup:
```bash
sudo ./scripts/validate_setup.sh
```

This script will check:
- OS version compatibility
- Required packages installation
- Telegraf configuration validity
- Service status
- Network connectivity
- Log file presence
- Common configuration issues

## Configuration Details

### Telegraf Configuration

The Telegraf configuration collects the following metrics:

- CPU usage (per-core and total)
- Memory usage
- Disk usage and I/O
- Network statistics
- System information
- Process information
- Swap usage
- Kernel metrics
- **Telegraf internal metrics** - For monitoring Telegraf itself

### Azure VM Maintenance Event Monitoring

The Azure monitoring configuration collects several types of metrics:

1. **Azure VM Metadata** - Static information about the VM:
   - Location (region)
   - Name
   - OS Type
   - VM Size
   - These appear in Grafana as `azure_vm_metadata` with tags for each field

2. **Azure Scheduled Events** - Information about upcoming maintenance:
   - Event Type (Freeze, Reboot, Redeploy, Preempt, Terminate)
   - Resource Type
   - Resources (affected VM names)
   - Event ID
   - Status
   - NotBefore timestamp
   - Description
   - Event Source (Platform or User)
   - Duration in seconds
   - These appear in Grafana as `azure_scheduled_events` with tags for event details

3. **Custom Maintenance Events** - Detected by our script:
   - Freeze events (`azure_vm_freeze_event`)
   - Reboot events (`azure_vm_reboot_event`)
   - Redeploy events (`azure_vm_redeploy_event`)
   - Preempt events (`azure_vm_preempt_event`)
   - Terminate events (`azure_vm_terminate_event`)
   - These appear in Grafana as gauge metrics with values of 0 or 1

### Alert Rules

The alert rules cover:

- Azure VM freeze events
- Azure VM reboot events
- Azure VM redeploy events
- Azure VM preempt events
- Azure VM terminate events
- High CPU load
- High memory usage
- Low disk space
- High disk I/O
- Network interface down
- Systemd service failures
- **Telegraf agent status** - Uses `internal_agent_metrics_written` metric to detect when Telegraf stops sending metrics

## Troubleshooting

Check Telegraf status:
```bash
sudo systemctl status telegraf
```

Check Telegraf logs:
```bash
sudo journalctl -u telegraf -f
```

Check Azure VM maintenance monitor status:
```bash
sudo systemctl status azure-vm-freeze-monitor.timer
```

Check Azure VM maintenance monitor logs:
```bash
sudo journalctl -u azure-vm-freeze-monitor.service
```

View the maintenance monitor log file:
```bash
tail -f /var/log/azure_vm_freeze_monitor.log
```