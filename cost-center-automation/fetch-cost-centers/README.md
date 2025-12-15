# Fetch Cost Centers

This script fetches and displays cost centers for a GitHub Enterprise using the GitHub REST API with curl.

## Prerequisites

- **curl**: For making HTTP requests
- **jq**: For JSON processing
- **GitHub Enterprise Admin Access**: Required for cost center management
- **Personal Access Token**: With `admin:enterprise` scope

## Setup

The script uses the shared `.env` file located in the parent directory (`../.env`) for configuration.

## Usage

The script can be run from either the parent directory or this directory:

### From this directory:

### List all cost centers (default table format):
```bash
./fetch-cost-centers.sh
```

### From parent directory:
```bash
./fetch-cost-centers/fetch-cost-centers.sh
```

### Show only active cost centers:
```bash
./fetch-cost-centers.sh --state active
```

### Show only deleted cost centers:
```bash
./fetch-cost-centers.sh --state deleted
```

### Different output formats:
```bash
# Detailed view with all resources
./fetch-cost-centers.sh --format detailed

# Raw JSON for scripting
./fetch-cost-centers.sh --format json

# CSV format for spreadsheets
./fetch-cost-centers.sh --format csv
```

### Export to file:
```bash
# Export to CSV file
./fetch-cost-centers.sh --format csv > cost-centers.csv

# Get specific cost center ID
./fetch-cost-centers.sh --format json | jq '.costCenters[0].id'
```

### With options:
```bash
# With custom environment file
./fetch-cost-centers.sh --env /path/to/custom.env

# With verbose output
./fetch-cost-centers.sh --verbose

# Show help
./fetch-cost-centers.sh --help
```

## Output Formats

### Table (Default)
Clean table format with:
- Cost Center ID
- Name
- State (color-coded: green=active, red=deleted)
- Resource count

### Detailed
Shows complete information:
- Full cost center details
- All assigned resources with types
- Azure subscription information

### JSON
Raw API response for programmatic use

### CSV
Export-friendly format with headers:
- ID, Name, State, Azure Subscription, Resource Count, Resource Types

## API Endpoint

Uses: `GET /enterprises/{enterprise}/settings/billing/cost-centers`

Optional query parameter: `?state=active` or `?state=deleted`

## Features

- ✅ **Multiple output formats**: table, detailed, json, csv
- ✅ **State filtering**: Filter by active/deleted cost centers
- ✅ **Color-coded output**: Easy-to-read table format
- ✅ **Export capability**: Direct CSV export for analysis
- ✅ **Error handling**: Comprehensive error checking
- ✅ **Flexible usage**: Suitable for both interactive and scripted use
- ✅ **Smart file detection**: Automatically finds .env file
- ✅ **Flexible execution**: Can be run from parent or current directory

## Example Output

### Table Format
```
┌─────────────────────────────────────────┬──────────────────────────────┬─────────────┬───────────────┐
│ Cost Center ID                          │ Name                         │ State       │ Resources     │
├─────────────────────────────────────────┼──────────────────────────────┼─────────────┼───────────────┤
│ f707dcde-22a7-4796-bd23-6ec8d70f0655    │ Engineering Team             │ active      │            3  │
│ a123bcde-45f6-789a-bcde-1234567890ab    │ Marketing Team               │ active      │            5  │
└─────────────────────────────────────────┴──────────────────────────────┴─────────────┴───────────────┘
```

### Detailed Format
```
=== Cost Center: Engineering Team ===
ID: f707dcde-22a7-4796-bd23-6ec8d70f0655
State: active
Azure Subscription: N/A
Resources (3):
  - User: alice-smith
  - User: bob-jones
  - User: charlie-brown
```
