#!/bin/bash
# heartbeat.sh - Simple heartbeat script for Telegraf

# Create the heartbeat file with current timestamp
echo "telegraf_status,host=$(hostname) status=1i,timestamp=$(date +%s)$(date +%N | cut -b1-6)"