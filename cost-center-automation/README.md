# Copilot Metrics

This repository contains tools and automation scripts for GitHub Copilot metrics and cost center management.

## Repository Structure

```
Copilot-metrics/
                         # This file
├── cost-center-automation/             # Cost center management tools
│   ├── .env                           # Common environment configuration
│   ├── .env.example                   # Example environment configuration
|   ├── README.md
│   ├── assign-users-cost-center/      # Add users to cost centers
│   │   ├── assign-users-cost-center.sh
│   │   ├── users.csv
│   │   ├── users.csv.example
│   │   └── README.md
│   ├── remove-users-cost-center/      # Remove users from cost centers
│   │   ├── remove-users-cost-center.sh
│   │   ├── remove-users.csv
│   │   ├── remove-users.csv.example
│   │   └── README.md
│   └── fetch-cost-centers/            # List and display cost centers
│   |    ├── fetch-cost-centers.sh
│   |    ├── cost-centers.csv
│   |    └── README.md  
```

## Cost Center Automation

The cost center automation tools provide complete management capabilities for GitHub Enterprise cost centers using the GitHub REST API.

### Features

- 🎯 **Add Users**: Assign users to cost centers from CSV files
- 🗑️ **Remove Users**: Remove users from cost centers
- 📊 **Fetch Cost Centers**: List and display cost centers with multiple output formats
- 🔐 **Secure Authentication**: Uses GitHub Personal Access Tokens
- 📝 **CSV Support**: Easy bulk operations with CSV file input
- 🎨 **Rich Output**: Color-coded terminal output with multiple display formats
- ⚡ **curl-based**: No GitHub CLI dependency required

### Quick Start

1. **Setup Configuration**:
   ```bash
   cd cost-center-automation
   cp .env.example .env
   # Edit .env with your values
   ```

2. **Add Users to Cost Center**:
   ```bash
   cd assign-users-cost-center
   # Edit users.csv with usernames
   ./assign-users-cost-center.sh
   ```

3. **List Cost Centers**:
   ```bash
   cd fetch-cost-centers
   ./fetch-cost-centers.sh
   ```

4. **Remove Users from Cost Center**:
   ```bash
   cd remove-users-cost-center
   # Edit remove-users.csv with usernames
   ./remove-users-cost-center.sh
   ```

### Environment Configuration

The `.env` file in the `cost-center-automation` directory contains shared configuration:

```bash
# GitHub Enterprise Configuration
GITHUB_ENTERPRISE=your-enterprise-name

# Cost Center ID (get from fetch-cost-centers.sh)
COST_CENTER_ID=your-cost-center-id

# CSV file paths
USERS_CSV_FILE=users.csv
REMOVE_USERS_CSV_FILE=remove-users.csv

# GitHub Personal Access Token
GITHUB_TOKEN=your_github_token_here
```

### Prerequisites

All scripts require:
- **curl**: For HTTP requests
- **jq**: For JSON processing  
- **GitHub Enterprise Admin Access**: Required for cost center management
- **Personal Access Token**: With `admin:enterprise` scope

#### Installing Dependencies

**macOS:**
```bash
brew install curl jq
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install curl jq
```

**Windows (via Chocolatey):**
```bash
choco install curl jq
```

## Detailed Documentation

Each tool has its own detailed README with specific usage instructions:

- **[Assign Users to Cost Center](cost-center-automation/assign-users-cost-center/README.md)**: Add users from CSV to cost centers
- **[Remove Users from Cost Center](cost-center-automation/remove-users-cost-center/README.md)**: Remove users from cost centers with confirmation
- **[Fetch Cost Centers](cost-center-automation/fetch-cost-centers/README.md)**: List and export cost centers in multiple formats

### Running Scripts

All scripts can be run from either the parent directory or their individual directories:

```bash
# From parent directory
./assign-users-cost-center/assign-users-cost-center.sh
./remove-users-cost-center/remove-users-cost-center.sh
./fetch-cost-centers/fetch-cost-centers.sh

# Or from individual directories
cd assign-users-cost-center && ./assign-users-cost-center.sh
cd remove-users-cost-center && ./remove-users-cost-center.sh
cd fetch-cost-centers && ./fetch-cost-centers.sh
```

### Getting Your Cost Center ID

Use the fetch script to list all cost centers and find your target ID:

```bash
cd cost-center-automation/fetch-cost-centers
./fetch-cost-centers.sh --format json | jq '.costCenters[] | {id: .id, name: .name}'
```

### API Endpoints Used

The scripts interact with these GitHub REST API endpoints:

- **GET** `/enterprises/{enterprise}/settings/billing/cost-centers` - List cost centers
- **POST** `/enterprises/{enterprise}/settings/billing/cost-centers/{id}/resource` - Add resources
- **DELETE** `/enterprises/{enterprise}/settings/billing/cost-centers/{id}/resource` - Remove resources

### Security Notes

- Store your `.env` file securely and never commit it to version control
- Use Personal Access Tokens with minimal required scopes (`admin:enterprise`)
- Regularly rotate your access tokens
- Consider using separate tokens for different environments

### Troubleshooting

#### Common Issues

**"Command not found: curl"**
- Install curl using your system's package manager

**"Command not found: jq"** 
- Install jq using your system's package manager

**"GitHub authentication failed"**
- Verify your `GITHUB_TOKEN` in the `.env` file
- Ensure your token has `admin:enterprise` scope
- Check that you have enterprise admin permissions

**"403 Forbidden"**
- Ensure you have enterprise admin permissions
- Verify your token scopes include `admin:enterprise`

**"Cost Center ID not found"**
- Use `fetch-cost-centers.sh` to list available cost centers
- Verify the `COST_CENTER_ID` in your `.env` file

### Support

For issues related to:
- **GitHub API**: Check [GitHub REST API documentation](https://docs.github.com/en/rest)
- **Cost Centers**: See [GitHub Cost Centers documentation](https://docs.github.com/en/enterprise-cloud@latest/rest/billing/cost-centers)
- **Scripts**: Create an issue in this repository with detailed error information

---

**Note**: These tools are designed for GitHub Enterprise Cloud customers with cost center functionality enabled. Enterprise admin permissions are required for all cost center operations.
