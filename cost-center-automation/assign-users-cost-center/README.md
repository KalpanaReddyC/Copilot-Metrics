# Assign Users to Cost Center Script

This script automates the process of adding users from a CSV file to a GitHub Enterprise cost center using the GitHub REST API with curl.

## Prerequisites

1. **curl**: For making HTTP requests
2. **jq**: JSON processor. Install from [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)
3. **GitHub Enterprise Admin Access**: You need to be an enterprise admin to manage cost centers
4. **Personal Access Token**: With `admin:enterprise` scope

## Setup

The script uses the shared `.env` file located in the parent directory (`../../.env`).

1. **Configure the shared .env file** (if not already done):
   ```bash
   cd .. # Go to cost-center-automation directory
   cp .env.example .env
   # Edit .env with your actual values
   ```

2. **Prepare your users CSV file**:
   - Edit the `users.csv` file in this directory
   - First column should contain GitHub usernames
   - Header row is optional (will be auto-detected)
   - Example format:
     ```csv
     username
     alice-smith
     bob-jones
     charlie-brown
     ```

## Usage

### Basic usage:
```bash
./assign-users-cost-center.sh
```

### With custom environment file:
```bash
./assign-users-cost-center.sh --env production.env
```

### With verbose output:
```bash
./assign-users-cost-center.sh --verbose
```

### Show help:
```bash
./assign-users-cost-center.sh --help
```

## Finding Your Cost Center ID

1. **List all cost centers**:
    Refer to the [Fetch Cost Centers](../fetch-cost-centers/README.md) script to list all cost centers in your enterprise.

2. **Copy the `id` field** from the desired cost center in the response.

## Script Features

- ✅ **Robust error handling**: Validates inputs and provides clear error messages
- ✅ **CSV validation**: Automatically detects headers and validates usernames
- ✅ **Personal token authentication**: Uses GitHub Personal Access Tokens securely
- ✅ **Confirmation prompt**: Asks for confirmation before making changes
- ✅ **Detailed logging**: Color-coded output with different log levels
- ✅ **Response parsing**: Shows reassignment information when users move between cost centers
- ✅ **Dependency checking**: Verifies required tools are installed
- ✅ **Smart file detection**: Finds .env and CSV files automatically

## API Endpoint

The script uses the GitHub REST API endpoint:
```
POST /enterprises/{enterprise}/settings/billing/cost-centers/{cost_center_id}/resource
```

**Request body format**:
```json
{
  "users": ["username1", "username2", "username3"]
}
```

## Error Handling

The script handles various error scenarios:
- Missing dependencies (`curl`, `jq`)
- Invalid or missing configuration files
- CSV file validation errors
- GitHub authentication failures
- API request errors
- Invalid usernames

## Security Notes

- Store your `.env` file securely and never commit it to version control
- Use a personal access token with minimal required scopes (`admin:enterprise`)
- Regularly rotate your access tokens

## Troubleshooting

### "Command not found: curl"
Install curl using your system's package manager:
- **macOS**: `brew install curl`
- **Ubuntu/Debian**: `sudo apt-get install curl`
- **Windows**: Usually pre-installed, or install via chocolatey

### "Command not found: jq"
Install jq:
- **macOS**: `brew install jq`
- **Ubuntu/Debian**: `sudo apt-get install jq`
- **Windows**: Download from [https://stedolan.github.io/jq/](https://stedolan.github.io/jq/)

### "GitHub authentication failed"
Set a valid `GITHUB_TOKEN` in your `.env` file with `admin:enterprise` scope.

### "403 Forbidden"
Ensure you have enterprise admin permissions and your token has the correct scopes.

## Example Output

```
[INFO] Starting GitHub Cost Center User Assignment Script
[SUCCESS] Environment variables loaded successfully
[SUCCESS] Authenticated as: your-username
[INFO] Processing CSV file: users.csv
[INFO] Found 5 users in CSV file
[INFO] Users to add: alice-smith bob-jones charlie-brown diana-wilson evan-taylor
[WARNING] About to add 5 users to cost center 'abc123' in enterprise 'my-enterprise'
Do you want to continue? (y/N): y
[INFO] Adding 5 users to cost center 'abc123'
[SUCCESS] Users added successfully to cost center
[INFO] API Response: Resources successfully added to the cost center.
[SUCCESS] Script completed successfully!
```
