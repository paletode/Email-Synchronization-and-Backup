#!/bin/bash

# Check if .env file exists
cd /usr/local/bin || exit 1
ENV_FILE=".env"

# Load environment variables from .env file
if [ -f "$ENV_FILE" ]; then
    set -o allexport
    source .env
    set +o allexport
else
    echo ".env file not found. Ensure a .env file is present."
    exit 1
fi

# Function to send notifications with Apprise
send_notification() {
    local message="$1"
    if [ -n "$APPRISE_URL" ]; then
        apprise -b "$message" "$APPRISE_URL"
    else
        echo "APPRISE_URL is not set. No notification would be sent."
    fi
}

# Function for email synchronization with imapsync
sync_emails() {
    echo "Starting synchronization between $SOURCE_HOST and $TARGET_HOST"

    # Build the imapsync command based on .env settings
    command=(
        "imapsync"
        "--host1" "$SOURCE_HOST" "--user1" "$SOURCE_USER" "--password1" "$SOURCE_PASSWORD"
        "--host2" "$TARGET_HOST" "--user2" "$TARGET_USER" "--password2" "$TARGET_PASSWORD"
    )

    # Connection options
    [[ "$SSL1" == "true" ]] && command+=("--ssl1")
    [[ "$SSL2" == "true" ]] && command+=("--ssl2")
    [[ "$TLS1" == "true" ]] && command+=("--tls1")
    [[ "$TLS2" == "true" ]] && command+=("--tls2")
    [[ -n "$TIMEOUT1" ]] && command+=("--timeout1" "$TIMEOUT1")
    [[ -n "$TIMEOUT2" ]] && command+=("--timeout2" "$TIMEOUT2")
    [[ -n "$AUTH_MECH1" ]] && command+=("--authmech1" "$AUTH_MECH1")
    [[ -n "$AUTH_MECH2" ]] && command+=("--authmech2" "$AUTH_MECH2")
    [[ -n "$DEBUG_SSL" ]] && command+=("--debugssl" "$DEBUG_SSL")
    [[ "$SHOW_PASSWORDS" == "true" ]] && command+=("--showpasswords")

    # Synchronization behavior
    [[ "$DRY_RUN" == "true" ]] && command+=("--dry")
    [[ "$DELETE1" == "true" ]] && command+=("--delete1")
    [[ "$DELETE2" == "true" ]] && command+=("--delete2")
    [[ "$DELETE2FOLDERS" == "true" ]] && command+=("--delete2folders")
    [[ "$SYNC_INTERNAL_DATES" == "true" ]] && command+=("--syncinternaldates")

    # Folder options
    [[ -n "$FOLDER" ]] && command+=("--folder" "$FOLDER")
    [[ -n "$FOLDER_REC" ]] && command+=("--folderrec" "$FOLDER_REC")
    [[ -n "$EXCLUDE" ]] && command+=("--exclude" "$EXCLUDE")
    [[ -n "$SUBFOLDER2" ]] && command+=("--subfolder2" "$SUBFOLDER2")
    [[ -n "$INCLUDE" ]] && command+=("--include" "$INCLUDE")
    [[ -n "$FOLDERFIRST" ]] && command+=("--folderfirst" "$FOLDERFIRST")
    [[ -n "$FOLDERLAST" ]] && command+=("--folderlast" "$FOLDERLAST")

    # Message filters
    [[ -n "$MAXAGE" ]] && command+=("--maxage" "$MAXAGE")
    [[ -n "$MINAGE" ]] && command+=("--minage" "$MINAGE")
    [[ -n "$MAXSIZE" ]] && command+=("--maxsize" "$MAXSIZE")
    [[ -n "$MINSIZE" ]] && command+=("--minsize" "$MINSIZE")

    # Debugging
    [[ "$DEBUG" == "true" ]] && command+=("--debug")
    [[ "$DEBUG_IMAP" == "true" ]] && command+=("--debugimap")

    # Logging control
    [[ "$LOGGING" == "false" ]] && command+=("--nolog")

    # Execute the imapsync command and capture the output
    sync_output=$("${command[@]}" 2>&1)
    exit_status=$?

    if [ $exit_status -eq 0 ]; then
        echo "$sync_output"

        # Extract the number of synchronized emails from the output
        emails_synced=$(echo "$sync_output" | awk '/Messages transferred/ {print $NF}')

        send_notification "✅ Synchronization completed successfully!
📂 Source: $SOURCE_USER@$SOURCE_HOST
📤 Target: $TARGET_USER@$TARGET_HOST
📨 Emails synced: ${emails_synced:-unknown}"

    else
        # Capture any specific error messages in the output
        error_message=$(echo "$sync_output" | awk '/Err [0-9]+:/ {print}')

        send_notification "❌ Synchronization failed!
📂 Source: $SOURCE_USER@$SOURCE_HOST
📤 Target: $TARGET_USER@$TARGET_HOST
🚨 Error message: ${error_message:-'Unknown error occurred.'}"
    fi
}

sync_emails