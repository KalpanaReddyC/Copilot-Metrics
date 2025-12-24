# JSON to XLSX Converter

This tool converts GitHub Copilot metrics data from JSON format to Excel (XLSX) format with multiple organized sheets for analysis and reporting.

## Features

- **Multiple Organized Sheets**: Data is split into logical sheets for easy analysis
- **Flexible Input**: Supports both single JSON objects and JSONL format
- **Automatic Output Naming**: Generates timestamped output files
- **Comprehensive Metrics**: Includes all GitHub Copilot usage statistics
- **Error Handling**: Robust error handling for malformed data

## Generated Sheets

1. **Main_Metrics**: Overall user metrics summary
2. **IDE_Totals**: IDE-specific usage breakdowns
3. **Feature_Totals**: Feature usage statistics
4. **Language_Feature**: Programming language and feature combinations
5. **Language_Model**: Language and AI model usage patterns
6. **Model_Feature**: AI model and feature combinations

## Prerequisites

- Python 3.7 or higher
- Required packages: pandas, openpyxl
- JSON file containing GitHub Copilot metrics data (in JSON format) with name `json_file.json`

## Installation Steps

### 1. Install Python Dependencies

```bash
pip install -r requirements.txt
```

Or install manually:
```bash
pip install pandas>=1.5.0 openpyxl>=3.0.0
```

### 2. Verify Installation

Check if Python and required packages are installed:
```bash
python --version
python -c "import pandas, openpyxl; print('All dependencies installed successfully')"
```

## Usage Instructions

### Option 1: Using Default File (Recommended)

1. **Place your JSON data** in the same directory as the script and name it `json_file.json`

2. **Run the script**:
   ```bash
   python json_to_xlsx.py
   ```

3. **Find the output**: The script will create an Excel file with a timestamped name like:
   ```
   json_file_converted_20241224_143052.xlsx
   ```

### Option 2: Specify Input File

```bash
python json_to_xlsx.py your_data.json
```

### Option 3: Specify Both Input and Output Files

```bash
python json_to_xlsx.py your_data.json custom_output.xlsx
```

## Example Commands

```bash
# Use the default json_file.json in the current directory
python json_to_xlsx.py

# Convert a specific JSON file
python json_to_xlsx.py copilot_metrics_2024.json

# Convert with custom output name
python json_to_xlsx.py copilot_metrics_2024.json monthly_report.xlsx

# Get help if file not found
python json_to_xlsx.py non_existent_file.json
```

## Expected Output

When you run the script successfully, you'll see output like:

```
Loaded 3 records from json_file.json
Creating sheets...
Created sheet 'Main_Metrics' with 3 rows
Created sheet 'IDE_Totals' with 3 rows
Created sheet 'Feature_Totals' with 8 rows
Created sheet 'Language_Feature' with 15 rows
Created sheet 'Language_Model' with 15 rows
Created sheet 'Model_Feature' with 8 rows

Successfully converted JSON to XLSX: json_file_converted_20241224_143052.xlsx
Total records processed: 3

--- Summary Statistics ---
Unique users: 3
Date range: 2025-11-29 to 2025-12-20
Total interactions: 122
Total code generations: 144
Total LOC added: 6815
```

## File Structure

After running the script, you'll have:

```
json-to-xlsx/
├── json_to_xlsx.py          # Main conversion script
├── requirements.txt         # Python dependencies
├── json_file.json          # Your input data (JSONL format)
├── JSON_README.md          # This documentation
└── json_file_converted_YYYYMMDD_HHMMSS.xlsx  # Generated Excel file
```

## Data Format

The script supports GitHub Copilot metrics data in JSONL format (one JSON object per line). Each record should contain:

- User information (`user_id`, `user_login`)
- Date information (`day`, `report_start_day`, `report_end_day`)
- Metrics (`user_initiated_interaction_count`, `code_generation_activity_count`, etc.)
- Breakdowns by IDE, features, languages, and models

## Troubleshooting

### Common Issues

1. **ModuleNotFoundError**: Install required packages
   ```bash
   pip install pandas openpyxl
   ```

2. **File not found**: Ensure the JSON file exists and the path is correct
   ```bash
   ls -la *.json  # Check available JSON files
   ```

3. **JSON parsing error**: Check if your JSON file is properly formatted
   - Each line should be a valid JSON object
   - No trailing commas
   - Proper quotes around strings

4. **Permission error**: Ensure you have write permissions in the directory

### Getting Help

If you encounter issues:
1. Check that your JSON file is properly formatted
2. Verify Python and package installations
3. Ensure you have write permissions in the output directory
4. Check the console output for specific error messages

## Sample Command Workflow

```bash
# 1. Navigate to the script directory
cd path/to/json-to-xlsx/

# 2. Install dependencies
pip install -r requirements.txt

# 3. Place your JSON data file (or use existing json_file.json)
# Your file should be in JSONL format with GitHub Copilot metrics

# 4. Run the conversion
python json_to_xlsx.py

# 5. Open the generated Excel file
# The filename will be displayed in the console output
```

## Output File Analysis

The generated Excel file contains multiple sheets optimized for different analyses:

- **Main_Metrics**: Use for high-level user activity overview
- **IDE_Totals**: Analyze IDE adoption and usage patterns
- **Feature_Totals**: Understand which Copilot features are most used
- **Language_Feature**: See language-specific feature usage
- **Language_Model**: Analyze which AI models work best with different languages
- **Model_Feature**: Understand model performance across features

Each sheet retains user and date information for easy filtering and pivot table creation.
