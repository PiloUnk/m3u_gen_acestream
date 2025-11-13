#!/bin/sh

echo "Starting M3U generator service with cron"
echo "=========================================="
echo "Configuration:"
echo "  - Ace Stream Engine: ${ACESTREAM_ENGINE_ADDR}"
echo "  - HTTPAceProxy: ${HTTPACEPROXY_ADDR}"

# Set default refresh interval if not provided (in minutes)
REFRESH_INTERVAL_MINUTES=${REFRESH_INTERVAL_MINUTES:-720}

echo "Refresh interval: ${REFRESH_INTERVAL_MINUTES} minutes"

# Convert minutes to cron format
if [ $REFRESH_INTERVAL_MINUTES -lt 60 ]; then
    # Less than 60 minutes: */N * * * *
    CRON_SCHEDULE="*/${REFRESH_INTERVAL_MINUTES} * * * *"
elif [ $REFRESH_INTERVAL_MINUTES -eq 60 ]; then
    # Exactly 1 hour: 0 * * * *
    CRON_SCHEDULE="0 * * * *"
else
    # Multiple hours: 0 */N * * *
    HOURS=$((REFRESH_INTERVAL_MINUTES / 60))
    CRON_SCHEDULE="0 */${HOURS} * * *"
fi

echo "Cron schedule: ${CRON_SCHEDULE}"
echo "=========================================="

# Create crontab file to execute at specified interval
# Format: minute hour day month day_of_week command
echo "${CRON_SCHEDULE} /app/generate.sh >> /var/log/m3u_gen.log 2>&1" > /etc/crontabs/root

# Create log file
touch /var/log/m3u_gen.log

# Run once at startup
echo "Running initial generation..."
echo "=========================================="
/app/generate.sh 2>&1 | tee -a /var/log/m3u_gen.log

echo "=========================================="
# Start crond in foreground
echo "Starting cron daemon..."
crond -f -l 2
