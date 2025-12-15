#!/bin/bash

# Script to remove users from CSV file from a GitHub Enterprise cost center
# Uses .env file for configuration

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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
            echo "  COST_CENTER_ID=your-cost-center-id"
            echo "  REMOVE_USERS_CSV_FILE=path/to/remove-users.csv"
            echo "  GITHUB_TOKEN=your-github-token (required)"
            exit 1
        fi
    fi
    
    if [[ ! -f "$env_file" ]]; then
        log_error "Environment file '$env_file' not found"
        log_info "Please create a .env file with the following variables:"
        echo "  GITHUB_ENTERPRISE=your-enterprise-name"
        echo "  COST_CENTER_ID=your-cost-center-id"
        echo "  REMOVE_USERS_CSV_FILE=path/to/remove-users.csv"
        echo "  GITHUB_TOKEN=your-github-token (required)"
        exit 1
    fi
    
    # Source the .env file
    set -a
    source "$env_file"
    set +a
    
    # Validate required variables
    local required_vars=("GITHUB_ENTERPRISE" "COST_CENTER_ID" "REMOVE_USERS_CSV_FILE" "GITHUB_TOKEN")
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

# Function to validate CSV file and extract users
extract_users_from_csv() {
    local csv_file="$1"
    local original_csv_file="$csv_file"
    
    # If CSV file not found, try to find it intelligently
    if [[ ! -f "$csv_file" ]]; then
        # Get the directory where this script is located
        local script_dir="$(dirname "${BASH_SOURCE[0]}")"
        
        # Try to find the CSV file in the script's directory
        if [[ -f "$script_dir/$csv_file" ]]; then
            csv_file="$script_dir/$csv_file"
            log_info "Found CSV file at: $csv_file"
        else
            log_error "CSV file '$original_csv_file' not found in current directory or script directory"
            log_info "Searched in: $(pwd) and $script_dir"
            exit 1
        fi
    fi
    
    # Check if file is empty
    if [[ ! -s "$csv_file" ]]; then
        log_error "CSV file '$csv_file' is empty"
        exit 1
    fi
    
    # Read CSV file and extract usernames
    # Assumes first column contains usernames
    # Skip header row if it exists
    local users=()
    local line_count=0
    
    while IFS=',' read -r username rest; do
        line_count=$((line_count + 1))
        
        # Skip empty lines
        [[ -z "$username" ]] && continue
        
        # Skip header row (if it contains "username", "user", etc.)
        if [[ $line_count -eq 1 && "$username" =~ ^[Uu]ser ]]; then
            continue
        fi
        
        # Clean username (remove quotes and whitespace)
        username=$(echo "$username" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | sed 's/^"//;s/"$//')
        
        # Validate username format
        if [[ "$username" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]]; then
            users+=("$username")
        else
            log_warning "Skipping invalid username: '$username' on line $line_count"
        fi
    done < "$csv_file"
    
    if [ ${#users[@]} -eq 0 ]; then
        log_error "No valid usernames found in CSV file"
        exit 1
    fi
    
    log_info "Found ${#users[@]} users in CSV file"
    printf '%s\n' "${users[@]}"
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

# Function to remove users from cost center
remove_users_from_cost_center() {
    local enterprise="$1"
    local cost_center_id="$2"
    shift 2
    local users=("$@")
    
    log_info "Removing ${#users[@]} users from cost center '$cost_center_id'"
    
    # Create JSON payload
    local users_json=$(printf '%s\n' "${users[@]}" | jq -R . | jq -s .)
    local payload=$(jq -n --argjson users "$users_json" '{users: $users}')
    
    log_info "Payload: $payload"
    
    # Make API request
    local response
    
    response=$(curl -s \
        -X DELETE \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GITHUB_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        -H "Content-Type: application/json" \
        -d "$payload" \
        "https://api.github.com/enterprises/$enterprise/settings/billing/cost-centers/$cost_center_id/resource" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        log_error "Failed to remove users from cost center - no response received"
        return 1
    fi
    
    # Check if response contains a message
    if echo "$response" | jq -e .message >/dev/null 2>&1; then
        local message=$(echo "$response" | jq -r .message)
        if [[ "$message" == *"successfully"* ]]; then
            log_success "Users removed successfully from cost center"
        else
            # Check if it's an error response
            if echo "$response" | jq -e .errors >/dev/null 2>&1; then
                log_error "API Error: $message"
                echo "$response" | jq -r '.errors[]?' 2>/dev/null || echo "$response"
                return 1
            else
                log_info "API Response: $message"
            fi
        fi
    else
        log_error "Unexpected API response format"
        echo "$response"
        return 1
    fi
}

# Function to display usage information
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Remove users from a CSV file from a GitHub Enterprise cost center.

OPTIONS:
    -e, --env FILE         Environment file to load (default: auto-detect)
    -h, --help          Show this help message
    -v, --verbose       Enable verbose output

ENVIRONMENT VARIABLES (in .env file):
    GITHUB_ENTERPRISE      GitHub enterprise name (required)
    COST_CENTER_ID         Cost center ID to remove users from (required)
    REMOVE_USERS_CSV_FILE  Path to CSV file containing usernames to remove (required)
    GITHUB_TOKEN           GitHub personal access token (required)

CSV FILE FORMAT:
    The CSV file should contain usernames in the first column.
    Header row is optional and will be automatically detected.
    
    Example:
        username
        alice
        bob
        charlie

EXAMPLES:
    $0
    $0 --env production.env
    $0 --verbose

EOF
}

# Main function
main() {
    local env_file=""
    local verbose=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -e|--env)
                env_file="$2"
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
    
    log_info "Starting GitHub Cost Center User Removal Script"
    
    # Check dependencies
    check_dependencies
    
    # Load environment variables
    load_env "$env_file"
    
    # Authenticate with GitHub
    authenticate_github
    
    # Extract users from CSV
    log_info "Processing CSV file: $REMOVE_USERS_CSV_FILE"
    local users
    mapfile -t users < <(extract_users_from_csv "$REMOVE_USERS_CSV_FILE")
    
    if [[ ${#users[@]} -eq 0 ]]; then
        log_error "No users to process"
        exit 1
    fi
    
    log_info "Users to remove: ${users[*]}"
    
    # Confirm before proceeding
    echo
    log_warning "About to REMOVE ${#users[@]} users from cost center '$COST_CENTER_ID' in enterprise '$GITHUB_ENTERPRISE'"
    log_warning "This action will stop charging these users' usage to this cost center"
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Operation cancelled by user"
        exit 0
    fi
    
    # Remove users from cost center
    remove_users_from_cost_center "$GITHUB_ENTERPRISE" "$COST_CENTER_ID" "${users[@]}"
    
    log_success "Script completed successfully!"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
