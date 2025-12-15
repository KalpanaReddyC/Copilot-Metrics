#!/bin/bash

# Script to fetch and display cost centers for a GitHub Enterprise
# Uses .env file for configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Function to print colored output
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if required commands are available
check_dependencies() {
    local missing_deps=()
    
    command -v curl >/dev/null 2>&1 || missing_deps+=("curl")
    command -v jq >/dev/null 2>&1 || missing_deps+=("jq")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_info "Please install:"
        for dep in "${missing_deps[@]}"; do
            case $dep in
                curl)
                    echo "  - curl: https://curl.se/"
                    ;;
                jq)
                    echo "  - jq: https://stedolan.github.io/jq/"
                    ;;
            esac
        done
        exit 1
    fi
}

# Function to load environment variables from .env file
load_env() {
    local env_file="${1:-}"
    
    # If no env file specified, try to find it intelligently
    if [[ -z "$env_file" ]]; then
        # Check common locations for .env file
        if [[ -f "../.env" ]]; then
            env_file="../.env"  # Running from subdirectory
        elif [[ -f "./.env" ]]; then
            env_file="./.env"   # Running from cost-center-automation directory
        elif [[ -f ".env" ]]; then
            env_file=".env"     # Running from cost-center-automation directory
        else
            log_error "Environment file not found in expected locations (../.env, ./.env, .env)"
            log_info "Please create a .env file with the following variables:"
            echo "  GITHUB_ENTERPRISE=your-enterprise-name"
            echo "  GITHUB_TOKEN=your-github-token (required)"
            exit 1
        fi
    fi
    
    if [[ ! -f "$env_file" ]]; then
        log_error "Environment file '$env_file' not found"
        log_info "Please create a .env file with the following variables:"
        echo "  GITHUB_ENTERPRISE=your-enterprise-name"
        echo "  GITHUB_TOKEN=your-github-token (required)"
        exit 1
    fi
    
    # Source the .env file
    set -a
    source "$env_file"
    set +a
    
    # Validate required variables
    local required_vars=("GITHUB_ENTERPRISE" "GITHUB_TOKEN")
    local missing_vars=()
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            missing_vars+=("$var")
        fi
    done
    
    if [ ${#missing_vars[@]} -ne 0 ]; then
        log_error "Missing required environment variables: ${missing_vars[*]}"
        exit 1
    fi
    
    log_success "Environment variables loaded successfully"
}

# Function to authenticate with GitHub
authenticate_github() {
    # Verify GitHub token is set
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_error "GITHUB_TOKEN is required"
        log_info "Please set GITHUB_TOKEN in .env file"
        exit 1
    fi
    
    log_info "Using GitHub token from environment"
    
    # Verify authentication by getting user info
    local user_response
    
    user_response=$(curl -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/user" 2>/dev/null)
    
    if [[ -z "$user_response" ]] || ! echo "$user_response" | jq -e .login >/dev/null 2>&1; then
        log_error "GitHub authentication failed"
        log_info "Please check your GITHUB_TOKEN in .env file"
        if [[ -n "$user_response" ]]; then
            echo "API Response: $user_response"
        fi
        exit 1
    fi
    
    local user=$(echo "$user_response" | jq -r '.login')
    log_success "Authenticated as: $user"
}

# Function to fetch cost centers
fetch_cost_centers() {
    local enterprise="$1"
    local state_filter="${2:-}"
    
    log_info "Fetching cost centers for enterprise '$enterprise'" >&2
    
    # Construct URL with optional state parameter
    local url="https://api.github.com/enterprises/$enterprise/settings/billing/cost-centers"
    if [[ -n "$state_filter" ]]; then
        url="${url}?state=${state_filter}"
        log_info "Filtering by state: $state_filter" >&2
    fi
    
    # Make API request
    local response
    
    response=$(curl -s \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "$url" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        log_error "Failed to fetch cost centers - no response received" >&2
        return 1
    fi
    
    # Check if response contains an error
    if echo "$response" | jq -e .message >/dev/null 2>&1; then
        local message=$(echo "$response" | jq -r .message)
        log_error "API Error: $message" >&2
        echo "$response" >&2
        return 1
    fi
    
    # Check if response contains cost centers
    if ! echo "$response" | jq -e .costCenters >/dev/null 2>&1; then
        log_error "Unexpected API response format" >&2
        echo "$response" >&2
        return 1
    fi
    
    echo "$response"
}

# Function to display cost centers in a formatted way
display_cost_centers() {
    local response="$1"
    local format="${2:-table}"
    
    local cost_center_count=$(echo "$response" | jq '.costCenters | length')
    
    if [[ "$cost_center_count" -eq 0 ]]; then
        log_warning "No cost centers found"
        return
    fi
    
    log_success "Found $cost_center_count cost center(s)"
    echo
    
    case "$format" in
        "table")
            display_table_format "$response"
            ;;
        "detailed")
            display_detailed_format "$response"
            ;;
        "json")
            echo "$response" | jq .
            ;;
        "csv")
            display_csv_format "$response"
            ;;
        *)
            log_error "Unknown format: $format"
            return 1
            ;;
    esac
}

# Function to display cost centers in table format
display_table_format() {
    local response="$1"
    
    echo -e "${BOLD}┌─────────────────────────────────────────┬──────────────────────────────┬─────────────┬───────────────┐${NC}"
    echo -e "${BOLD}│ Cost Center ID                          │ Name                         │ State       │ Resources     │${NC}"
    echo -e "${BOLD}├─────────────────────────────────────────┼──────────────────────────────┼─────────────┼───────────────┤${NC}"
    
    echo "$response" | jq -r '.costCenters[] | 
        [
            .id,
            (.name // "N/A"),
            (.state // "unknown"),
            ((.resources // []) | length | tostring)
        ] | @tsv' | while IFS=$'\t' read -r id name state resource_count; do
        
        # Truncate long names and IDs for table display
        local short_id=$(echo "$id" | cut -c1-39)
        local short_name=$(echo "$name" | cut -c1-28)
        
        # Color code by state
        local state_color=""
        case "$state" in
            "active") state_color="${GREEN}" ;;
            "deleted") state_color="${RED}" ;;
            *) state_color="${YELLOW}" ;;
        esac
        
        printf "│ %-39s │ %-28s │ ${state_color}%-11s${NC} │ %13s │\n" \
            "$short_id" "$short_name" "$state" "$resource_count"
    done
    
    echo -e "${BOLD}└─────────────────────────────────────────┴──────────────────────────────┴─────────────┴───────────────┘${NC}"
}

# Function to display cost centers in detailed format
display_detailed_format() {
    local response="$1"
    
    echo "$response" | jq -r '.costCenters[] | 
        "=== Cost Center: " + (.name // "Unnamed") + " ===\n" +
        "ID: " + .id + "\n" +
        "State: " + (.state // "unknown") + "\n" +
        "Azure Subscription: " + (.azure_subscription // "N/A") + "\n" +
        "Resources (" + ((.resources // []) | length | tostring) + "):" +
        (if (.resources // []) | length > 0 then
            "\n" + ((.resources // []) | map("  - " + .type + ": " + .name) | join("\n"))
        else
            "\n  (No resources assigned)"
        end) +
        "\n"'
}

# Function to display cost centers in CSV format
display_csv_format() {
    local response="$1"
    
    echo "ID,Name,State,Azure Subscription,Resource Count,Resource Types"
    echo "$response" | jq -r '.costCenters[] | 
        [
            .id,
            (.name // ""),
            (.state // "unknown"),
            (.azure_subscription // ""),
            ((.resources // []) | length | tostring),
            ((.resources // []) | map(.type) | unique | join(";"))
        ] | @csv'
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Fetch and display cost centers for a GitHub Enterprise.

OPTIONS:
    -e, --env FILE         Environment file to load (default: auto-detect)
    -s, --state STATE      Filter by state (active, deleted)
    -f, --format FORMAT    Output format (table, detailed, json, csv)
    -h, --help             Show this help message
    -v, --verbose          Enable verbose output

ENVIRONMENT VARIABLES (in .env file):
    GITHUB_ENTERPRISE     GitHub enterprise name (required)
    GITHUB_TOKEN          GitHub personal access token (required)

OUTPUT FORMATS:
    table      Default table format with summary information
    detailed   Detailed view showing all resources
    json       Raw JSON response from API
    csv        CSV format suitable for import into spreadsheets

EXAMPLES:
    $0                                    # Show all cost centers in table format
    $0 --state active                     # Show only active cost centers
    $0 --format detailed                  # Show detailed information
    $0 --format csv > cost-centers.csv    # Export to CSV file
    $0 --format json | jq '.costCenters[0]'  # Get first cost center as JSON

EOF
}

# Main function
main() {
    local env_file=""
    local state_filter=""
    local output_format="table"
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                env_file="$2"
                shift 2
                ;;
            -s|--state)
                state_filter="$2"
                if [[ ! "$state_filter" =~ ^(active|deleted)$ ]]; then
                    log_error "Invalid state: $state_filter. Must be 'active' or 'deleted'"
                    exit 1
                fi
                shift 2
                ;;
            -f|--format)
                output_format="$2"
                if [[ ! "$output_format" =~ ^(table|detailed|json|csv)$ ]]; then
                    log_error "Invalid format: $output_format. Must be 'table', 'detailed', 'json', or 'csv'"
                    exit 1
                fi
                shift 2
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Enable verbose output if requested
    if [[ "$verbose" == true ]]; then
        set -x
    fi
    
    log_info "Starting GitHub Enterprise Cost Center Fetch Script"
    
    # Check dependencies
    check_dependencies
    
    # Load environment variables
    load_env "$env_file"
    
    # Authenticate with GitHub
    authenticate_github
    
    # Fetch cost centers
    local response
    response=$(fetch_cost_centers "$GITHUB_ENTERPRISE" "$state_filter")
    
    if [[ $? -ne 0 ]]; then
        exit 1
    fi
    
    # Display results
    display_cost_centers "$response" "$output_format"
    
    log_success "Script completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
