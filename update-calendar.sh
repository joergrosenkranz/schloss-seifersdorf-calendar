#!/usr/bin/env bash

# Update Calendar Script
# Fetches calendar events from Google Calendar API and commits changes to git

set -e  # Exit on error
set -o pipefail  # Catch errors in pipes

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Default values
DRY_RUN=false
VERBOSE=false
OUTPUT_FILE="calendar.json"

# Git configuration (matching workflow)
GIT_USER_NAME="Automat"
GIT_USER_EMAIL="automat@example.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print verbose messages
verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${GREEN}[VERBOSE]${NC} $1"
    fi
}

# Function to print error messages to stderr
error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Function to print info messages
info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Function to print success messages
success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# URL encode function (from workflow)
urlencode() {
    # urlencode <string>
    
    old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:$i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf '%s' "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    
    LC_COLLATE=$old_lc_collate
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Fetch calendar events from Google Calendar API and commit changes to git."
            echo ""
            echo "Options:"
            echo "  --dry-run       Fetch calendar and show changes without committing/pushing"
            echo "  --verbose, -v   Show detailed output of operations"
            echo "  --help, -h      Show this help message"
            echo ""
            echo "Environment variables (from .env file):"
            echo "  CALENDAR_ID     Google Calendar ID (without @group.calendar.google.com)"
            echo "  API_KEY         Google API Key for Calendar API access"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

verbose "Starting calendar update script..."
verbose "Dry run mode: $DRY_RUN"

# Check if .env file exists
if [ ! -f ".env" ]; then
    error ".env file not found. Please create one from .env.example"
    echo "  cp .env.example .env" >&2
    echo "  # Then edit .env and add your CALENDAR_ID and API_KEY" >&2
    exit 1
fi

verbose "Loading environment variables from .env file..."

# Load .env file
set -a  # Export all variables
source .env
set +a

verbose "Validating required environment variables..."

# Validate required environment variables
if [ -z "$CALENDAR_ID" ]; then
    error "CALENDAR_ID not set in .env file"
    exit 1
fi

if [ -z "$API_KEY" ]; then
    error "API_KEY not set in .env file"
    exit 1
fi

verbose "CALENDAR_ID: $CALENDAR_ID"
verbose "API_KEY: ${API_KEY:0:10}..." # Show only first 10 chars for security

# Set timezone to Europe/Berlin (matching workflow)
export TZ=Europe/Berlin

verbose "Timezone set to: $TZ"

# Get current date in ISO 8601 format
CURRENT_DATE=$(date '+%FT%T%:z')
info "Current date: $CURRENT_DATE"

# URL encode the date
ENCODED_DATE=$(urlencode "$CURRENT_DATE")
verbose "Encoded date: $ENCODED_DATE"

# Build API URL
API_URL="https://www.googleapis.com/calendar/v3/calendars/${CALENDAR_ID}%40group.calendar.google.com/events"
API_URL="${API_URL}?maxResults=3&orderBy=startTime&singleEvents=true&timeMin=${ENCODED_DATE}"
API_URL="${API_URL}&fields=items(description%2Cend%2ChtmlLink%2Cstart%2Csummary)&key=${API_KEY}"

verbose "API URL: ${API_URL:0:100}..." # Show only first 100 chars

# Fetch calendar data
info "Fetching calendar data from Google Calendar API..."
HTTP_CODE=$(curl -s -w "%{http_code}" -o "${OUTPUT_FILE}.tmp" "$API_URL")

verbose "HTTP response code: $HTTP_CODE"

# Check HTTP response code
if [ "$HTTP_CODE" -ne 200 ]; then
    error "Failed to fetch calendar data (HTTP $HTTP_CODE)"
    if [ -f "${OUTPUT_FILE}.tmp" ]; then
        error "Response body:"
        cat "${OUTPUT_FILE}.tmp" >&2
        rm -f "${OUTPUT_FILE}.tmp"
    fi
    exit 1
fi

# Validate JSON response
if ! python3 -m json.tool "${OUTPUT_FILE}.tmp" > /dev/null 2>&1; then
    error "Invalid JSON response from API"
    if [ -f "${OUTPUT_FILE}.tmp" ]; then
        error "Response body:"
        cat "${OUTPUT_FILE}.tmp" >&2
        rm -f "${OUTPUT_FILE}.tmp"
    fi
    exit 1
fi

verbose "Calendar data fetched successfully and validated as JSON"

# Move temp file to actual output file
mv "${OUTPUT_FILE}.tmp" "$OUTPUT_FILE"

success "Calendar data saved to $OUTPUT_FILE"

# Check if there are changes
verbose "Checking for git changes..."

if git diff --exit-code "$OUTPUT_FILE" > /dev/null 2>&1; then
    info "No changes detected in calendar data"
    exit 0
fi

info "Changes detected in calendar data"

# Show diff if verbose
if [ "$VERBOSE" = true ]; then
    echo ""
    echo "Diff:"
    git diff "$OUTPUT_FILE"
    echo ""
fi

# If dry-run, show what would be committed
if [ "$DRY_RUN" = true ]; then
    info "DRY RUN MODE - Would commit the following changes:"
    echo ""
    git diff "$OUTPUT_FILE"
    echo ""
    info "DRY RUN MODE - No changes committed or pushed"
    exit 0
fi

# Configure git
verbose "Configuring git user..."
git config user.name "$GIT_USER_NAME"
git config user.email "$GIT_USER_EMAIL"

verbose "Git user: $GIT_USER_NAME <$GIT_USER_EMAIL>"

# Commit changes
info "Committing changes..."
git add "$OUTPUT_FILE"
git commit -m "Calendar changed"

verbose "Changes committed"

# Push changes
info "Pushing changes to remote repository..."
if git push; then
    success "Changes pushed successfully!"
else
    error "Failed to push changes to remote repository"
    exit 1
fi

success "Calendar update completed successfully!"
