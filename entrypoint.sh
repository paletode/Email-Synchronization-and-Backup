#!/bin/bash

# Define the default path for the .env file, which can be overridden by setting ENV_FILE
ENV_FILE="/usr/local/bin/.env"

# Load environment variables from the specified .env file, if it exists
if [ -f "$ENV_FILE" ]; then
  set -o allexport
  # shellcheck source=/usr/local/bin/.env
  source "$ENV_FILE"
  set +o allexport
fi

# Set a default cron schedule if CRON_SCHEDULE is not defined
CRON_SCHEDULE="${CRON_SCHEDULE:-'* * * * *'}"

# Write the crontab entry with the specified or default schedule
# Note: Removing any surrounding quotes to avoid formatting issues
echo "$CRON_SCHEDULE /usr/local/bin/sync.sh >> /var/log/email_sync.log 2>&1" | sed 's/^"//;s/"$//' > /etc/crontabs/root

# Start the cron service in the foreground
exec "$@"