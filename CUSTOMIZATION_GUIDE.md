# Customization Guide for Azure VM Monitoring Solution

This guide provides instructions for customizing the monitoring solution to fit your specific environment and requirements.

## Configuration Customization

### Telegraf Configuration

The main Telegraf configuration file (`configs/telegraf.conf`) can be customized for your environment:

1. **Global Tags**:
   ```toml
   [global_tags]
     env = "production"  # Change to your environment name
     region = "azure"   # Change to your Azure region
   ```

2. **Collection Intervals**:
   ```toml
   [agent]
     interval = "10s"        # Adjust how often metrics are collected
     flush_interval = "10s"  # Adjust how often metrics are sent
   ```

3. **Input Plugins**:
   You can add or remove input plugins based on what metrics you want to collect:
   ```toml
   # Add more specific inputs as needed
   [[inputs.logparser]]
     # Configuration for log parsing
   ```

4. **Output Configuration**:
   Update the HTTP output with your Grafana Cloud details:
   ```toml
   [[outputs.http]]
     url = "https://your-region.grafana.net/api/prom/push"
     username = "your-username"
     password = "your-api-key"
   ```

5. **Internal Plugin for Telegraf Monitoring**:
   The internal plugin is configured to monitor Telegraf itself:
   ```toml
   [[inputs.internal]]
     collect_memstats = true
   ```
   This provides the `internal_agent_metrics_written` metric used in our alerting.

### Azure Monitoring Configuration

The Azure-specific configuration (`configs/azure_monitoring.conf`) can be customized:

1. **Metadata Collection**:
   Adjust which metadata fields you want to collect:
   ```toml
   [[inputs.http]]
     # Add or remove json_string_fields as needed
     json_string_fields = ["compute/location", "compute/name", "compute/osType", "compute/vmSize", "compute/tags"]
   ```

2. **Azure VM Maintenance Events**:
   The exec input plugin runs the Azure VM maintenance events script:
   ```toml
   [[inputs.exec]]
     commands = ["/usr/local/bin/azure_vm_freeze_monitor.sh --check-only"]
     data_format = "influx"
     interval = "60s"
   ```
   You can adjust the interval to check for events more or less frequently.

3. **Scheduled Events Collection**:
   The HTTP input plugin collects Azure scheduled events:
   ```toml
   [[inputs.http]]
     urls = ["http://169.254.169.254/metadata/scheduledevents?api-version=2020-07-01"]
     method = "GET"
     headers = {"Metadata" = "true"}
     data_format = "json"
     json_query = "Events"
   ```

### Alert Rules

The alert rules file (`alerts/azure-vm-alerts.yaml`) can be customized:

1. **Thresholds**:
   Adjust alert thresholds to match your requirements:
   ```yaml
   - alert: HighCPULoad
     expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85  # Change 85 to your threshold
   ```

2. **Alert Durations**:
   Adjust how long a condition must persist before triggering an alert:
   ```yaml
   for: 5m  # Change to your preferred duration
   ```

3. **Severity Levels**:
   Adjust severity labels:
   ```yaml
   labels:
     severity: warning  # Change to critical, info, etc.
   ```

4. **Azure VM Maintenance Event Alerts**:
   Separate alerts are configured for each event type:
   ```yaml
   - alert: AzureVMFreezeEvent
     expr: azure_vm_freeze_event == 1
     
   - alert: AzureVMRebootEvent
     expr: azure_vm_reboot_event == 1
     
   - alert: AzureVMRedeployEvent
     expr: azure_vm_redeploy_event == 1
   ```
   You can adjust the expressions or add additional conditions as needed.

5. **Telegraf Agent Alert**:
   The Telegraf agent alert uses the `internal_agent_metrics_written` metric:
   ```yaml
   - alert: TelegrafAgentDown
     expr: rate(internal_agent_metrics_written[2m]) == 0
     for: 2m
   ```
   You can adjust the time window (2m) to be more or less sensitive.

## Environment-Specific Customizations

### Different Azure Regions

If your VMs are in different Azure regions, you may want to:

1. Add region-specific tags to your Telegraf configuration:
   ```toml
   [global_tags]
     region = "eastus"  # Change to your region
   ```

2. Modify the Azure metadata service URLs if needed (though the default should work for all regions).

### Multiple Environments

For multiple environments (dev, staging, production), you can:

1. Create separate Telegraf configuration files for each environment
2. Use different global tags to distinguish between environments:
   ```toml
   [global_tags]
     env = "staging"  # vs "production" or "development"
   ```

3. Use different alert thresholds for different environments

### Custom Metrics

To add custom metrics collection:

1. Add new input plugins to the Telegraf configuration:
   ```toml
   [[inputs.exec]]
     commands = ["/path/to/your/custom/script.sh"]
     data_format = "influx"
   ```

2. Create custom alert rules for your metrics in the alerts file

## Scaling Considerations

### Large Deployments

For deployments with many VMs:

1. Consider using configuration management tools (Ansible, Puppet, Chef) to deploy the solution
2. Use Telegraf's HTTP service input to collect metrics from applications
3. Implement proper tagging to organize metrics in Grafana

### Resource Constraints

For VMs with limited resources:

1. Increase collection intervals to reduce CPU usage:
   ```toml
   [agent]
     interval = "30s"  # Instead of 10s
   ```

2. Remove input plugins for metrics you don't need

3. Use Telegraf's metric filtering to reduce the number of metrics sent:
   ```toml
   [agent]
     metric_batch_size = 500  # Reduce batch size
   ```

## Security Customizations

### Credential Management

Instead of hardcoding credentials in configuration files:

1. Use environment variables:
   ```toml
   [[outputs.http]]
     username = "${GRAFANA_USERNAME}"
     password = "${GRAFANA_API_KEY}"
   ```

2. Set environment variables in the Telegraf service file

3. Use secret management solutions if available in your environment

### TLS Configuration

To enable TLS for secure communication:

1. Obtain TLS certificates for your Telegraf instances
2. Configure TLS in the Telegraf output:
   ```toml
   [[outputs.http]]
     tls_cert = "/path/to/cert.pem"
     tls_key = "/path/to/key.pem"
     tls_ca = "/path/to/ca.pem"
   ```

## Integration Customizations

### Additional Data Sources

To integrate with other data sources:

1. Add appropriate Telegraf input plugins
2. Configure authentication as needed
3. Add alert rules for any new metrics

### Notification Channels

To customize alert notifications:

1. Modify the alert rules to use different labels
2. Configure notification policies in Grafana Cloud
3. Set up contact points for your preferred notification methods

## Testing Customizations

### Testing Configuration Changes

Before deploying configuration changes:

1. Test the Telegraf configuration:
   ```bash
   telegraf --config /etc/telegraf/telegraf.conf --test
   ```

2. Verify that metrics are being collected correctly

3. Check that the output configuration is working:
   ```bash
   telegraf --config /etc/telegraf/telegraf.conf --output-filter prometheus_client
   ```

### Testing Alert Rules

Before deploying alert rule changes:

1. Review the alert expressions in the Prometheus UI
2. Use the Grafana UI to test alert rules
3. Validate that alert thresholds are appropriate for your environment

## Monitoring the Monitoring

### Health Checks

Implement health checks for your monitoring system:

1. Monitor Telegraf process status
2. Check for failed metric collections
3. Verify that metrics are being sent to Grafana Cloud
4. **Monitor the Telegraf agent itself** using the `internal_agent_metrics_written` metric
5. **Monitor Azure VM maintenance events** using the respective metrics

### Log Management

Configure proper log management:

1. Set appropriate log levels in Telegraf:
   ```toml
   [agent]
     debug = false  # Set to true for troubleshooting
   ```

2. Implement log rotation:
   ```toml
   [agent]
     logfile_rotation_interval = "1d"
     logfile_rotation_max_size = "10MB"
     logfile_rotation_max_archives = 10
   ```

## Troubleshooting Customizations

### Common Issues

1. **Metrics not appearing in Grafana**:
   - Check Telegraf logs for errors
   - Verify network connectivity to Grafana Cloud
   - Confirm credentials are correct
   - **Check if Telegraf is actually running** using the `internal_agent_metrics_written` metric
   - **Verify Azure VM maintenance events are being detected**

2. **Alerts not firing**:
   - Verify alert expressions in Prometheus
   - Check alert rule configuration
   - Review notification policies

3. **Performance issues**:
   - Review collection intervals
   - Check system resource usage
   - Optimize metric filtering

### Custom Debugging

For custom debugging needs:

1. Enable debug logging temporarily:
   ```toml
   [agent]
     debug = true
   ```

2. Use Telegraf's input filtering to test specific plugins:
   ```bash
   telegraf --config /etc/telegraf/telegraf.conf --input-filter cpu
   ```

3. Use Telegraf's output filtering to test specific outputs:
   ```bash
   telegraf --config /etc/telegraf/telegraf.conf --output-filter http
   ```