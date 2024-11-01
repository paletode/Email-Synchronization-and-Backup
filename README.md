# Email Synchronization and Backup Service

This project provides an email synchronization service to back up an email account to another server or local storage. It can be run as a Docker container or as a standalone service. Based on [imapsync](https://imapsync.lamiral.info/), it securely transfers emails between accounts. Notifications can be enabled via [apprise](https://github.com/caronc/apprise) for updates and synchronization events.

## Features

- **Flexible Deployment**: Can be run as a Docker container or standalone.
- **Email Backup**: Designed to synchronize emails between accounts with a focus on backup and retention.
- **Notifications**: Optional notifications using `apprise` for real-time updates on sync status.
- **IMAP-based**: Uses `imapsync` to ensure reliable and incremental synchronization.

## Requirements

- **Docker** (for containerized setup)
- **imapsync** (for standalone setup)
- **apprise** (optional, for notifications)

## Project Structure

- **Dockerfile**: Builds the container for running the email sync service.
- **docker-compose.yml**: Defines the container configuration, environment variables, and volumes.
- **entrypoint.sh**: Entry point for initializing the service.
- **sync.sh**: Script that performs the synchronization using `imapsync`.
- **.env.example**: Example environment variable file for setup.

## Setup and Configuration

### 1. Clone the Repository
   ```bash
   git clone <repository-url>
   cd <repository-folder>
   ```

### 2. Configure Environment Variables
   Copy `.env.example` to `.env` and edit the file to add your email and notification configuration:
   ```bash
   cp .env.example .env
   ```

   Required variables may include:
   - Source and destination email server credentials.
   - Notification configuration for `apprise` if notifications are enabled.

### Running as a Docker Container

1. **Build and Run**:
   ```bash
   docker-compose up --build -d
   ```

   This will start the `email-sync-service` container, which will run the synchronization process at regular intervals. 

2. **Check Logs**:
   ```bash
   docker-compose logs -f email-sync
   ```

### Running as a Standalone Service

1. **Install imapsync** (if not already installed):
   ```bash
   # Example installation command
   sudo apt-get install imapsync
   ```

2. **Run the sync script**:
   ```bash
   ./sync.sh
   ```

   This will start the synchronization directly on your system.

## Optional Notifications with Apprise

If notifications are enabled in the `.env` file, the service will send updates using `apprise` to your chosen notification services (e.g., email, SMS, or chat platforms).

## Customization

- **Scheduling**: Adjust the synchronization frequency in the `sync.sh` script for standalone use, or configure a cron job in the Docker container for automated runs.
- **Notification Settings**: Modify `.env` to configure `apprise` notification channels as desired.
