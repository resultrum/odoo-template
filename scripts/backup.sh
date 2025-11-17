#!/bin/bash
# Backup script for Odoo database and filestore
# Usage: ./scripts/backup.sh [environment] [backup_path]
# Examples:
#   ./scripts/backup.sh test /backups/odoo-mta/test/
#   ./scripts/backup.sh prod /backups/odoo-mta/prod/

set -e  # Exit on error

# ============================================================================
# CONFIGURATION
# ============================================================================

ENVIRONMENT=${1:-test}
BACKUP_PATH=${2:-/backups/odoo-mta/${ENVIRONMENT}/}
TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
BACKUP_DIR="${BACKUP_PATH}${TIMESTAMP}"

# Container names (adjust if different)
CONTAINER_NAME="odoo-mta-web"
DB_CONTAINER_NAME="odoo-mta-db"
DB_NAME="mta-${ENVIRONMENT}"
DB_USER="odoo"
DB_PASSWORD="${DB_PASSWORD:-odoo}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# FUNCTIONS
# ============================================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."

    # Check if Docker is running
    if ! docker ps > /dev/null 2>&1; then
        log_error "Docker is not running"
        exit 1
    fi

    # Check if containers exist
    if ! docker ps -a | grep -q "$CONTAINER_NAME"; then
        log_error "Container $CONTAINER_NAME not found"
        exit 1
    fi

    if ! docker ps -a | grep -q "$DB_CONTAINER_NAME"; then
        log_error "Container $DB_CONTAINER_NAME not found"
        exit 1
    fi

    log_info "Prerequisites check passed"
}

create_backup_directory() {
    log_info "Creating backup directory: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"

    if [ ! -d "$BACKUP_DIR" ]; then
        log_error "Failed to create backup directory"
        exit 1
    fi
}

backup_database() {
    log_info "Backing up database: $DB_NAME"

    BACKUP_FILE="${BACKUP_DIR}/database_${DB_NAME}.sql"

    # Create database dump
    docker exec "$DB_CONTAINER_NAME" \
        pg_dump \
        -U "$DB_USER" \
        -d "$DB_NAME" \
        --format=plain \
        --verbose \
        > "${BACKUP_FILE}.raw"

    if [ ! -f "${BACKUP_FILE}.raw" ]; then
        log_error "Failed to create database dump"
        exit 1
    fi

    # Compress the dump
    gzip -9 "${BACKUP_FILE}.raw"
    mv "${BACKUP_FILE}.raw.gz" "${BACKUP_FILE}.gz"

    BACKUP_SIZE=$(du -h "${BACKUP_FILE}.gz" | cut -f1)
    log_info "Database backup completed: ${BACKUP_FILE}.gz (${BACKUP_SIZE})"
}

backup_filestore() {
    log_info "Backing up filestore..."

    FILESTORE_BACKUP="${BACKUP_DIR}/filestore.tar.gz"

    # Backup Odoo filestore from container
    docker exec "$CONTAINER_NAME" \
        tar -czf - \
        -C /var/lib/odoo \
        .local/share/Odoo/filestore/ 2>/dev/null \
        > "$FILESTORE_BACKUP" || true

    if [ ! -f "$FILESTORE_BACKUP" ] || [ ! -s "$FILESTORE_BACKUP" ]; then
        log_warn "Filestore backup skipped or empty (may not exist yet)"
        rm -f "$FILESTORE_BACKUP"
    else
        FILESTORE_SIZE=$(du -h "$FILESTORE_BACKUP" | cut -f1)
        log_info "Filestore backup completed: ${FILESTORE_BACKUP} (${FILESTORE_SIZE})"
    fi
}

backup_addons() {
    log_info "Backing up custom addons..."

    ADDONS_BACKUP="${BACKUP_DIR}/addons.tar.gz"

    # Backup custom addons
    if [ -d "addons/custom" ]; then
        tar -czf "$ADDONS_BACKUP" -C addons custom 2>/dev/null || true

        if [ -f "$ADDONS_BACKUP" ] && [ -s "$ADDONS_BACKUP" ]; then
            ADDONS_SIZE=$(du -h "$ADDONS_BACKUP" | cut -f1)
            log_info "Custom addons backup completed: ${ADDONS_BACKUP} (${ADDONS_SIZE})"
        else
            log_warn "Custom addons backup empty, removing"
            rm -f "$ADDONS_BACKUP"
        fi
    else
        log_warn "Custom addons directory not found"
    fi
}

create_manifest() {
    log_info "Creating backup manifest..."

    MANIFEST_FILE="${BACKUP_DIR}/manifest.json"

    cat > "$MANIFEST_FILE" << EOF
{
    "timestamp": "$(date -u +'%Y-%m-%dT%H:%M:%SZ')",
    "environment": "${ENVIRONMENT}",
    "database": "${DB_NAME}",
    "container": "${CONTAINER_NAME}",
    "backup_type": "full",
    "files": {
        "database": "$(basename ${BACKUP_FILE}.gz 2>/dev/null || echo 'not-found')",
        "filestore": "$([ -f "$FILESTORE_BACKUP" ] && basename "$FILESTORE_BACKUP" || echo 'not-found')",
        "addons": "$([ -f "$ADDONS_BACKUP" ] && basename "$ADDONS_BACKUP" || echo 'not-found')"
    },
    "hostname": "$(hostname)",
    "user": "$(whoami)",
    "git_commit": "$(git rev-parse HEAD 2>/dev/null || echo 'unknown')"
}
EOF

    log_info "Manifest created: $MANIFEST_FILE"
}

cleanup_old_backups() {
    log_info "Cleaning up old backups (keeping last 10)..."

    # Count backups
    BACKUP_COUNT=$(find "$BACKUP_PATH" -maxdepth 1 -type d -name "20*" | wc -l)

    if [ "$BACKUP_COUNT" -gt 10 ]; then
        # Remove oldest backups, keeping last 10
        find "$BACKUP_PATH" -maxdepth 1 -type d -name "20*" -printf '%T+ %p\n' | \
            sort | head -n $((BACKUP_COUNT - 10)) | cut -d' ' -f2- | \
            while read -r old_backup; do
                log_info "Removing old backup: $(basename "$old_backup")"
                rm -rf "$old_backup"
            done
    fi

    log_info "Backup cleanup completed"
}

# ============================================================================
# MAIN
# ============================================================================

log_info "Starting backup for environment: $ENVIRONMENT"
log_info "Backup path: $BACKUP_PATH"

check_prerequisites
create_backup_directory
backup_database
backup_filestore
backup_addons
create_manifest
cleanup_old_backups

log_info "Backup completed successfully: $BACKUP_DIR"
echo ""
log_info "Summary:"
echo "  Environment: $ENVIRONMENT"
echo "  Database: $DB_NAME"
echo "  Backup path: $BACKUP_DIR"
echo "  Total backups: $(find "$BACKUP_PATH" -maxdepth 1 -type d -name "20*" | wc -l)"
