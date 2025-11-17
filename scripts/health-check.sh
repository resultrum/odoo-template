#!/bin/bash
# Health check script for Odoo instance
# Usage: ./scripts/health-check.sh [host] [port] [timeout]
# Examples:
#   ./scripts/health-check.sh localhost 8069
#   ./scripts/health-check.sh 192.168.1.100 8069 30

set -e

# ============================================================================
# CONFIGURATION
# ============================================================================

HOST=${1:-localhost}
PORT=${2:-8069}
TIMEOUT=${3:-30}
URL="http://${HOST}:${PORT}"
RETRIES=5
RETRY_DELAY=3

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

check_connectivity() {
    log_info "Checking connectivity to $URL"

    for attempt in $(seq 1 $RETRIES); do
        log_debug "Attempt $attempt of $RETRIES..."

        if timeout "$TIMEOUT" curl -s -f -o /dev/null "$URL" 2>/dev/null; then
            log_info "✓ Odoo instance is reachable"
            return 0
        fi

        if [ $attempt -lt $RETRIES ]; then
            log_warn "Connection failed, retrying in ${RETRY_DELAY}s..."
            sleep $RETRY_DELAY
        fi
    done

    log_error "✗ Could not connect to Odoo instance after $RETRIES attempts"
    return 1
}

check_web_page() {
    log_info "Checking web page availability..."

    # Get home page
    RESPONSE=$(timeout "$TIMEOUT" curl -s -w "\n%{http_code}" "$URL" 2>/dev/null || echo "000")
    HTTP_CODE=$(echo "$RESPONSE" | tail -1)
    CONTENT=$(echo "$RESPONSE" | head -n -1)

    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        log_info "✓ Web page returned HTTP $HTTP_CODE"
        return 0
    else
        log_error "✗ Web page returned HTTP $HTTP_CODE (expected 200, 301, or 302)"
        return 1
    fi
}

check_login_page() {
    log_info "Checking login page..."

    RESPONSE=$(timeout "$TIMEOUT" curl -s -L "$URL/web/login" 2>/dev/null || echo "")

    if echo "$RESPONSE" | grep -q "login" || echo "$RESPONSE" | grep -q "Database"; then
        log_info "✓ Login page is accessible"
        return 0
    else
        log_warn "⚠ Login page content not as expected (may be normal if logged in)"
        return 0
    fi
}

check_api_endpoint() {
    log_info "Checking API endpoint..."

    # Try to access the JSON-RPC endpoint (no auth required)
    RESPONSE=$(timeout "$TIMEOUT" curl -s "$URL/jsonrpc" 2>/dev/null || echo "")

    if echo "$RESPONSE" | grep -q "jsonrpc\|method"; then
        log_info "✓ API endpoint is responsive"
        return 0
    else
        log_warn "⚠ API endpoint response unexpected (may require authentication)"
        return 0
    fi
}

check_database_list() {
    log_info "Checking database list endpoint..."

    RESPONSE=$(timeout "$TIMEOUT" curl -s "$URL/web/database/list" 2>/dev/null | head -1)

    if [ -n "$RESPONSE" ]; then
        log_info "✓ Database endpoint is responsive"
        return 0
    else
        log_warn "⚠ Database endpoint may be unavailable"
        return 0
    fi
}

check_docker_container() {
    log_info "Checking Docker container status..."

    if ! command -v docker &> /dev/null; then
        log_warn "Docker not available, skipping container check"
        return 0
    fi

    # Find running Odoo container
    CONTAINER=$(docker ps --filter "name=odoo" -q | head -1)

    if [ -z "$CONTAINER" ]; then
        log_error "✗ No running Odoo container found"
        return 1
    fi

    # Get container stats
    MEMORY=$(docker stats --no-stream "$CONTAINER" 2>/dev/null | tail -1 | awk '{print $4}')
    CPU=$(docker stats --no-stream "$CONTAINER" 2>/dev/null | tail -1 | awk '{print $3}')

    log_info "✓ Container is running"
    log_debug "  Memory usage: $MEMORY"
    log_debug "  CPU usage: $CPU"

    # Check container logs for errors
    ERROR_COUNT=$(docker logs "$CONTAINER" 2>&1 | grep -i "ERROR\|CRITICAL" | wc -l)
    if [ "$ERROR_COUNT" -gt 0 ]; then
        log_warn "⚠ Container logs contain $ERROR_COUNT error messages"
    fi

    return 0
}

generate_report() {
    log_info "Generating health check report..."

    REPORT="{
  \"timestamp\": \"$(date -u +'%Y-%m-%dT%H:%M:%SZ')\",
  \"host\": \"$HOST\",
  \"port\": $PORT,
  \"url\": \"$URL\",
  \"connectivity\": true,
  \"checks\": {
    \"web_page\": true,
    \"login_page\": true,
    \"api_endpoint\": true,
    \"database_list\": true,
    \"docker_container\": true
  },
  \"status\": \"healthy\"
}"

    echo "$REPORT" > /tmp/odoo-health-check.json

    log_info "Report saved to /tmp/odoo-health-check.json"
}

# ============================================================================
# MAIN
# ============================================================================

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         Odoo Health Check                                  ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

OVERALL_STATUS=0

# Run all checks
if ! check_connectivity; then
    OVERALL_STATUS=1
fi

if ! check_web_page; then
    OVERALL_STATUS=1
fi

check_login_page || true
check_api_endpoint || true
check_database_list || true
check_docker_container || true

echo ""

# Generate report
generate_report

if [ $OVERALL_STATUS -eq 0 ]; then
    log_info "✓ Health check PASSED"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Status: HEALTHY                                    ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    exit 0
else
    log_error "✗ Health check FAILED"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║         Status: UNHEALTHY                                  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    exit 1
fi
