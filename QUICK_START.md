# Quick Start Guide: Azure VM Linux Monitoring

This guide provides a fast path to deploying the monitoring solution on your Azure VMs running RHEL 7 or RHEL 8.

## Prerequisites

1. Azure VMs running RHEL 7 or RHEL 8
2. SSH access to the VMs
3. Grafana Cloud account with Prometheus and Alertmanager (Mimir)
4. Your Grafana Cloud Prometheus username and API key

## Step-by-Step Deployment

### 1. Clone the Repository

On your local machine or directly on the Azure VM:
```bash
git clone https://github.com/silverbacks/telegraf_check.git
cd telegraf_check
```

### 2. Gather Your Credentials

Before proceeding, have these ready:
- Grafana Cloud Prometheus username
- Grafana Cloud API key
- (Optional) Azure Event Hub connection string for maintenance events

### 3. Update Configuration Files

Update the Telegraf configuration with your Grafana Cloud credentials:
```bash
# Edit the main configuration
nano configs/telegraf.conf

# Find and replace:
#   your-prometheus-username → your actual username
#   your-prometheus-api-key → your actual API key
```

Copy and update the Azure monitoring configuration:
```bash
# Copy the Azure monitoring configuration
sudo cp configs/azure_monitoring.conf /etc/telegraf/telegraf.d/

# Update Grafana Cloud credentials in the Azure configuration if needed
```

Update the Azure VM maintenance events monitor script:
```bash
# Edit the script
nano scripts/azure_vm_freeze_monitor.sh

# Find and replace:
#   your-prometheus-username → your actual username
#   your-prometheus-api-key → your actual API key
```

### 4. Run the Deployment Script

Execute the automated deployment script:
```bash
sudo ./scripts/deploy_monitoring.sh
```

This script will:
- Detect your RHEL version
- Install Telegraf
- Configure Telegraf with your settings
- Set up Azure VM maintenance events monitoring
- Start all required services

### 5. Verify the Installation

Run the validation script:
```bash
sudo ./scripts/validate_setup.sh
```

This will check:
- OS compatibility
- Package installation
- Service status
- Configuration validity
- Network connectivity

### 6. Configure Grafana Cloud

1. Log in to your Grafana Cloud account
2. Import the dashboard:
   - Go to "Create" → "Import"
   - Upload `configs/grafana_dashboard.json`
   - Select your Prometheus data source
3. Configure alert rules:
   - Go to "Alerting" → "Alert rules"
   - Import `alerts/azure-vm-alerts.yaml`
4. Set up notification channels:
   - Go to "Alerting" → "Contact points"
   - Create channels for your preferred notification methods

## Verification Commands

After deployment, verify everything is working:

```bash
# Check Telegraf status
sudo systemctl status telegraf

# Check Azure maintenance events monitor status
sudo systemctl status azure-vm-freeze-monitor.timer

# View Telegraf metrics (if using Prometheus endpoint)
curl http://localhost:9273/metrics

# Check recent logs
sudo journalctl -u telegraf --since "5 minutes ago"

# Check for Telegraf internal metrics
# In Grafana Cloud, query for: internal_agent_metrics_written

# Check Azure VM maintenance events logs
tail -f /var/log/azure_vm_freeze_monitor.log
```

## Expected Results

After successful deployment, you should see:

1. **In Grafana Dashboards**:
   - CPU, memory, disk, and network metrics from your VMs
   - Azure VM metadata information (location, name, OS type, VM size)
   - Periodic data points (every 10 seconds by default)
   - **Telegraf internal metrics indicating Telegraf is running**
   - **Azure VM maintenance events (Freeze, Reboot, Redeploy)**

2. **In Grafana Alerts**:
   - Configured alert rules for system metrics
   - Azure VM maintenance event detection rules (Freeze, Reboot, Redeploy)
   - **Telegraf agent status alert using `internal_agent_metrics_written` metric**

3. **On Your VMs**:
   - Running Telegraf service
   - Active Azure maintenance events monitor timer
   - Log files in `/var/log/azure_vm_freeze_monitor.log`

## Metrics in Grafana

The Azure monitoring configuration generates several types of metrics:

1. **Azure VM Metadata** (`azure_vm_metadata`):
   - Tags: location, name, osType, vmSize
   - Use for inventory tracking and resource planning

2. **Azure Scheduled Events** (`azure_scheduled_events`):
   - Tags: EventType, ResourceType, Resources
   - Use for maintenance planning and impact assessment

3. **Custom Maintenance Events**:
   - `azure_vm_freeze_event` (0 or 1)
   - `azure_vm_reboot_event` (0 or 1)
   - `azure_vm_redeploy_event` (0 or 1)
   - Use for alerting and dashboard indicators

## Troubleshooting Quick Fixes

If something isn't working:

1. **Telegraf not sending metrics**:
   ```bash
   # Check configuration
   telegraf --config /etc/telegraf/telegraf.conf --test
   
   # Check service status
   sudo systemctl status telegraf
   
   # Check logs
   sudo journalctl -u telegraf --since "10 minutes ago"
   
   # Check if internal metrics are being generated
   # In Grafana, query: internal_agent_metrics_written
   ```

2. **Azure maintenance events not detected**:
   ```bash
   # Test the script manually
   sudo /usr/local/bin/azure_vm_freeze_monitor.sh
   
   # Check logs
   tail -f /var/log/azure_vm_freeze_monitor.log
   ```

3. **Metrics not appearing in Grafana**:
   - Verify Grafana Cloud credentials in Telegraf config
   - Check network connectivity to Grafana Cloud
   - Confirm firewall rules allow outbound HTTPS
   - **Check if the `internal_agent_metrics_written` metric is being generated**
   - **Check if Azure VM maintenance events are being detected**

## Next Steps

After successful deployment:

1. **Customize alert thresholds** in `alerts/azure-vm-alerts.yaml`
2. **Adjust collection intervals** in `configs/telegraf.conf`
3. **Add custom metrics** by extending the Telegraf configuration
4. **Set up additional dashboards** in Grafana
5. **Configure notification policies** in Grafana Alerting
6. **Monitor the `internal_agent_metrics_written` metric** to ensure Telegraf continues to function
7. **Monitor Azure VM maintenance events** to be notified of planned maintenance

## Support

For issues with this monitoring solution:

1. Check the detailed documentation in `docs/grafana_cloud_setup.md`
2. Review the customization guide in `CUSTOMIZATION_GUIDE.md`
3. Use the deployment checklist in `DEPLOYMENT_CHECKLIST.md`
4. Run the validation script for automated checking

For issues with Grafana Cloud:
- Refer to [Grafana Cloud Documentation](https://grafana.com/docs/grafana-cloud/)
- Contact Grafana Cloud support through your account