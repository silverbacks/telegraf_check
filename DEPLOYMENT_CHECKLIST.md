# Deployment Checklist for Azure VM Monitoring Solution

This checklist helps ensure that all components of the monitoring solution are properly deployed and configured.

## Pre-Deployment Checklist

- [ ] **Grafana Cloud Account**: Ensure you have a Grafana Cloud account with Prometheus and Alertmanager (Mimir) enabled
- [ ] **API Credentials**: Obtain your Grafana Cloud Prometheus username and API key
- [ ] **Azure VM Access**: Ensure you have SSH access to all target Azure VMs
- [ ] **Network Connectivity**: Verify that VMs can reach Grafana Cloud endpoints
- [ ] **Required Tools**: Confirm that curl and jq are installed on VMs (for the maintenance events detection script)

## Per-VM Deployment Checklist

### 1. Telegraf Installation

- [ ] Install Telegraf on the VM (using the deployment script or manual installation)
- [ ] Verify Telegraf installation:
  ```bash
  telegraf --version
  ```

### 2. Configuration Files

- [ ] Copy main Telegraf configuration:
  ```bash
  sudo cp configs/telegraf.conf /etc/telegraf/telegraf.conf
  ```
- [ ] Copy Azure monitoring configuration:
  ```bash
  sudo cp configs/azure_monitoring.conf /etc/telegraf/telegraf.d/
  ```
- [ ] Update Grafana Cloud credentials in both configuration files

### 3. Azure VM Maintenance Events Monitor

- [ ] Copy the maintenance events detection script:
  ```bash
  sudo cp scripts/azure_vm_freeze_monitor.sh /usr/local/bin/
  sudo chmod +x /usr/local/bin/azure_vm_freeze_monitor.sh
  ```
- [ ] Update Grafana Cloud credentials in the script
- [ ] Install systemd service and timer files:
  ```bash
  sudo cp scripts/azure-vm-freeze-monitor.service /etc/systemd/system/
  sudo cp scripts/azure-vm-freeze-monitor.timer /etc/systemd/system/
  ```
- [ ] Enable and start the timer:
  ```bash
  sudo systemctl daemon-reload
  sudo systemctl enable azure-vm-freeze-monitor.timer
  sudo systemctl start azure-vm-freeze-monitor.timer
  ```

### 4. Service Configuration

- [ ] Start and enable Telegraf:
  ```bash
  sudo systemctl start telegraf
  sudo systemctl enable telegraf
  ```
- [ ] Verify Telegraf is running:
  ```bash
  sudo systemctl status telegraf
  ```

### 5. Verification

- [ ] Check Telegraf logs for errors:
  ```bash
  sudo journalctl -u telegraf --since "5 minutes ago"
  ```
- [ ] Verify that the Prometheus endpoint is accessible (if using):
  ```bash
  curl http://localhost:9273/metrics
  ```
- [ ] Check that Azure maintenance events monitor is working:
  ```bash
  sudo systemctl status azure-vm-freeze-monitor.timer
  sudo journalctl -u azure-vm-freeze-monitor.service --since "5 minutes ago"
  ```
- [ ] **Verify Telegraf is sending metrics** by checking for the `internal_agent_metrics_written` metric
- [ ] **Verify Azure VM maintenance events are being detected** by checking the logs

## Post-Deployment Verification

### 1. Grafana Cloud Setup

- [ ] Import the Grafana dashboard from `configs/grafana_dashboard.json`
- [ ] Verify that metrics are appearing in the dashboard
- [ ] Configure alert rules from `alerts/azure-vm-alerts.yaml`
- [ ] Set up notification channels in Grafana

### 2. Metrics Verification

- [ ] Check that system metrics are being collected (CPU, memory, disk, network)
- [ ] Verify that Azure VM metadata is being collected
- [ ] Confirm that Azure maintenance events are being monitored
- [ ] **Validate that the `internal_agent_metrics_written` metric is being generated**
- [ ] **Confirm that all VMs are appearing in the dashboard**

### 3. Alerting Verification

- [ ] Verify that alert rules are properly configured in Mimir
- [ ] Check that metrics are being received
- [ ] Review alert thresholds
- [ ] **Test that the Telegraf agent alert can be triggered**
- [ ] **Test that Azure VM maintenance event alerts can be triggered**
- [ ] Test notification channels

## Ongoing Maintenance Checklist

### Weekly

- [ ] Check Telegraf service status on all VMs
- [ ] Review Telegraf logs for errors or warnings
- [ ] Verify that metrics are being sent to Grafana Cloud
- [ ] Check Azure maintenance events monitor logs
- [ ] **Verify that the `internal_agent_metrics_written` metric is consistently being generated**

### Monthly

- [ ] Review alert thresholds and adjust as needed
- [ ] Update Telegraf to the latest version
- [ ] Review dashboard panels for relevance
- [ ] Check disk space on VMs for log files

### Quarterly

- [ ] Review and update Grafana dashboards
- [ ] Audit alert rules for effectiveness
- [ ] Update documentation with any environment changes
- [ ] Test disaster recovery procedures

## Troubleshooting Checklist

If metrics are not appearing in Grafana:

- [ ] Check Telegraf service status
- [ ] Review Telegraf logs for errors
- [ ] Verify Grafana Cloud credentials
- [ ] Test network connectivity to Grafana Cloud
- [ ] Check firewall rules
- [ ] **Verify that the `internal_agent_metrics_written` metric is being generated**
- [ ] **Verify that Azure VM maintenance events are being detected**

If alerts are not firing:

- [ ] Verify alert rules in Grafana
- [ ] Check that metrics are being received
- [ ] Review alert thresholds
- [ ] Test notification channels

If Azure maintenance events are not detected:

- [ ] Verify the VM is running in Azure
- [ ] Check that the metadata service is accessible
- [ ] Review the maintenance events monitor logs
- [ ] Test the script manually

If Telegraf stops sending metrics:

- [ ] Check the `internal_agent_metrics_written` metric - if it stops increasing, Telegraf has stopped working
- [ ] Review Telegraf logs for errors
- [ ] Check system resources (memory, CPU, disk space)
- [ ] Restart the Telegraf service

## Security Checklist

- [ ] Rotate Grafana Cloud API keys regularly
- [ ] Restrict permissions on configuration files:
  ```bash
  sudo chmod 644 /etc/telegraf/telegraf.conf
  sudo chown telegraf:telegraf /etc/telegraf/telegraf.conf
  sudo chmod 644 /etc/telegraf/telegraf.d/azure_monitoring.conf
  sudo chown telegraf:telegraf /etc/telegraf/telegraf.d/azure_monitoring.conf
  ```
- [ ] Secure log files:
  ```bash
  sudo chmod 644 /var/log/azure_vm_freeze_monitor.log
  ```
- [ ] Regularly update Telegraf for security patches
- [ ] Monitor access to Telegraf configuration files

## Performance Checklist

- [ ] Monitor Telegraf resource usage (CPU, memory)
- [ ] Adjust collection intervals if needed
- [ ] Review which metrics are being collected
- [ ] Implement metric filtering to reduce load if necessary
- [ ] Monitor disk space usage for logs
- [ ] **Monitor the `internal_agent_metrics_written` metric for consistency**