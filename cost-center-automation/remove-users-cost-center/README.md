# Remove Users from Cost Center

This script removes users from a GitHub Enterprise cost center using the GitHub REST API with curl.

## Prerequisites

- **curl**: For making HTTP requests
- **jq**: For JSON processing
- **GitHub Enterprise Admin Access**: Required for cost center management
- **Personal Access Token**: With `admin:enterprise` scope

## Setup

The script uses the shared `.env` file located in the parent directory (`../.env`).

1. **Ensure the shared .env file is configured** (if not already done):
   ```bash
   cd .. # Go to cost-center-automation directory
   cp .env.example .env
   # Edit .env with your actual values
   ```

2. **Prepare your users CSV file**: Edit `remove-users.csv` with usernames to remove

## CSV File Format

```csv
username
alice-smith
bob-jones
charlie-brown
```

## Usage

The script can be run from either the parent directory or this directory:

### From this directory:
```bash
./remove-users-cost-center.sh
```

### From parent directory:
```bash
./remove-users-cost-center/remove-users-cost-center.sh
```

### With options:
```bash
# With verbose output
./remove-users-cost-center.sh --verbose

# With custom environment file
./remove-users-cost-center.sh --env /path/to/custom.env

# Show help
./remove-users-cost-center.sh --help
```

## API Endpoint

Uses: `DELETE /enterprises/{enterprise}/settings/billing/cost-centers/{cost_center_id}/resource`

## Features

- ✅ **Confirmation prompt**: Asks before making changes
- ✅ **CSV validation**: Validates username formats
- ✅ **Error handling**: Comprehensive error checking
- ✅ **Detailed logging**: Color-coded output with different log levels
- ✅ **API response parsing**: Shows detailed response information
- ✅ **Smart file detection**: Automatically finds .env and CSV files
- ✅ **Flexible execution**: Can be run from parent or current directory

## Example Output

```
[INFO] Starting GitHub Cost Center User Removal Script
[SUCCESS] Environment variables loaded successfully
[SUCCESS] Authenticated as: your-username
[INFO] Processing CSV file: remove-users.csv
[INFO] Found 3 users in CSV file
[WARNING] About to REMOVE 3 users from cost center 'abc123' in enterprise 'my-enterprise'
[WARNING] This action will stop charging these users' usage to this cost center
Do you want to continue? (y/N): y
[INFO] Removing 3 users from cost center 'abc123'
[SUCCESS] Users removed successfully from cost center
[SUCCESS] Script completed successfully!
```
