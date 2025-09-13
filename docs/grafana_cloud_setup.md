# Grafana Cloud and Mimir Setup for Azure VM Monitoring

This document provides instructions for setting up Grafana Cloud with Mimir for monitoring Azure VMs running RHEL 7 and RHEL 8 with Telegraf.

## Prerequisites

1. Grafana Cloud account
2. Azure VMs running RHEL 7 or RHEL 8
3. Network connectivity from VMs to Grafana Cloud

## Grafana Cloud Setup

### 1. Create a Grafana Cloud Account

If you don't already have a Grafana Cloud account, sign up at [Grafana Cloud](https://grafana.com/products/cloud/).

### 2. Configure Prometheus Metrics Endpoint

1. Log in to your Grafana Cloud account
2. Navigate to the "Stacks" section
3. Select your Prometheus stack or create a new one
4. Note the following information:
   - Prometheus metrics endpoint URL
   - Username
   - API key

### 3. Configure Alertmanager (Mimir)

1. In your Grafana Cloud stack, locate the Alertmanager configuration
2. Note the Alertmanager endpoint URL
3. You'll use this for configuring alert rules

## Configuration Updates

### Update Telegraf Configuration

Update the Telegraf configuration with your Grafana Cloud credentials:

```toml
[[outputs.http]]
  ## URL is the address to send metrics to
  url = "YOUR_PROMETHEUS_ENDPOINT_URL"
  
  ## HTTP Basic Auth credentials
  username = "YOUR_PROMETHEUS_USERNAME"
  password = "YOUR_PROMETHEUS_API_KEY"
```

### Update Azure VM Freeze Monitor Script

Update the Azure VM freeze monitor script with your Grafana Cloud credentials:

```bash
# Configuration
GRAFANA_CLOUD_URL="YOUR_PROMETHEUS_ENDPOINT_URL"
GRAFANA_USERNAME="YOUR_PROMETHEUS_USERNAME"
GRAFANA_API_KEY="YOUR_PROMETHEUS_API_KEY"
```

## Deploying to Azure VMs

### Using the Deployment Script

Run the deployment script on each Azure VM:

```bash
sudo ./scripts/deploy_monitoring.sh
```

### Manual Deployment

1. Install Telegraf on each VM
2. Copy the Telegraf configuration:
   ```bash
   sudo cp configs/telegraf.conf /etc/telegraf/telegraf.conf
   ```
3. Copy the Azure monitoring configuration:
   ```bash
   sudo cp configs/azure_monitoring.conf /etc/telegraf/telegraf.d/
   ```
4. Copy and configure the freeze monitor script:
   ```bash
   sudo cp scripts/azure_vm_freeze_monitor.sh /usr/local/bin/
   sudo chmod +x /usr/local/bin/azure_vm_freeze_monitor.sh
   ```
5. Set up the systemd service and timer:
   ```bash
   sudo cp scripts/azure-vm-freeze-monitor.service /etc/systemd/system/
   sudo cp scripts/azure-vm-freeze-monitor.timer /etc/systemd/system/
   sudo systemctl daemon-reload
   sudo systemctl enable azure-vm-freeze-monitor.timer
   sudo systemctl start azure-vm-freeze-monitor.timer
   ```
6. Start Telegraf:
   ```bash
   sudo systemctl start telegraf
   sudo systemctl enable telegraf
   ```

## Grafana Dashboard Setup

### Import the Dashboard

1. In Grafana, go to "Create" → "Import"
2. Upload the `configs/grafana_dashboard.json` file
3. Select your Prometheus data source
4. Click "Import"

### Dashboard Panels

The dashboard includes the following panels:

1. **CPU Usage** - Shows CPU utilization across all instances
2. **Memory Usage** - Displays memory usage percentage
3. **Disk I/O** - Shows disk read/write operations per second
4. **Network Traffic** - Displays network bytes transmitted and received
5. **Disk Space Usage** - Shows disk space utilization
6. **Azure VM Freeze Events** - Indicates when freeze events occur

## Alerting with Mimir

### Import Alert Rules

1. In Grafana, navigate to "Alerting" → "Alert rules"
2. Create a new rule group or import the rules from `alerts/azure-vm-alerts.yaml`
3. Configure the alert rules to match your environment

### Alert Rules Included

1. **AzureVMFreezeEvent** - Triggers when an Azure VM freeze event is detected
2. **HighCPULoad** - Triggers when CPU usage exceeds 85%
3. **HighMemoryUsage** - Triggers when memory usage exceeds 85%
4. **DiskSpaceLow** - Triggers when disk space usage exceeds 90%
5. **HighDiskIO** - Triggers when disk I/O utilization is high
6. **NetworkInterfaceDown** - Triggers when a network interface is down
7. **SystemdServiceDown** - Triggers when a systemd service is not active

### Notification Channels

Configure notification channels in Grafana to receive alerts:

1. Go to "Alerting" → "Contact points"
2. Create contact points for your preferred notification methods (email, Slack, etc.)
3. Create notification policies to route alerts to the appropriate contact points

## Verification

### Check Telegraf Metrics

Verify that Telegraf is sending metrics:

```bash
# Check Telegraf status
sudo systemctl status telegraf

# Check Telegraf logs
sudo journalctl -u telegraf -f

# Check if the Prometheus endpoint is accessible
curl http://localhost:9273/metrics
```

### Check Azure VM Freeze Monitor

Verify that the Azure VM freeze monitor is working:

```bash
# Check the timer status
sudo systemctl status azure-vm-freeze-monitor.timer

# Check the service logs
sudo journalctl -u azure-vm-freeze-monitor.service

# Check the log file
tail -f /var/log/azure_vm_freeze_monitor.log
```

### Verify Metrics in Grafana Cloud

1. In Grafana, navigate to "Explore"
2. Select your Prometheus data source
3. Run a query like `up` to see if your instances are reporting
4. Try querying specific metrics like `cpu_usage_idle` or `azure_vm_freeze_event`

## Troubleshooting

### Common Issues

1. **Telegraf not sending metrics**
   - Check Telegraf configuration for correct Grafana Cloud credentials
   - Verify network connectivity to Grafana Cloud
   - Check Telegraf logs for errors

2. **Azure VM freeze events not detected**
   - Ensure the VM is running in Azure
   - Verify the metadata service is accessible
   - Check the freeze monitor logs

3. **Alerts not firing**
   - Verify alert rules are correctly configured
   - Check that metrics are being received by Prometheus
   - Verify notification channels are properly configured

### Useful Commands

```bash
# Restart Telegraf
sudo systemctl restart telegraf

# Check Telegraf configuration
telegraf --config /etc/telegraf/telegraf.conf --test

# View Telegraf logs
sudo journalctl -u telegraf --since "1 hour ago"

# Check if metrics are being sent to Prometheus
curl -u "username:api_key" https://prometheus-endpoint/api/v1/query?query=up
```

## Security Considerations

1. Store API keys securely and limit their permissions
2. Use TLS for all communications
3. Regularly rotate credentials
4. Monitor access logs for unauthorized access