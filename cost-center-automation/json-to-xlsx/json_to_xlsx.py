import json
import pandas as pd
from datetime import datetime
import os
import sys


def load_json_data(json_file_path):
    """
    Load JSON data from file. Handles both single JSON objects and JSONL format.
    """
    data = []
    try:
        with open(json_file_path, "r", encoding="utf-8") as file:
            content = file.read().strip()

            # Try to parse as single JSON first
            try:
                single_json = json.loads(content)
                if isinstance(single_json, list):
                    data = single_json
                else:
                    data = [single_json]
            except json.JSONDecodeError:
                # If single JSON fails, try JSONL format (one JSON per line)
                for line in content.split("\n"):
                    if line.strip():
                        try:
                            data.append(json.loads(line))
                        except json.JSONDecodeError as e:
                            print(f"Error parsing line: {line[:100]}... - {e}")
                            continue

        print(f"Loaded {len(data)} records from {json_file_path}")
        return data

    except FileNotFoundError:
        print(f"Error: File {json_file_path} not found.")
        return []
    except Exception as e:
        print(f"Error loading JSON data: {e}")
        return []


def create_main_metrics_sheet(data):
    """
    Create the main metrics summary sheet.
    """
    main_data = []

    for record in data:
        main_row = {
            "Report Start": record.get("report_start_day", ""),
            "Report End": record.get("report_end_day", ""),
            "Day": record.get("day", ""),
            "Enterprise ID": record.get("enterprise_id", ""),
            "User ID": record.get("user_id", ""),
            "User Login": record.get("user_login", ""),
            "User Initiated Interactions": record.get(
                "user_initiated_interaction_count", 0
            ),
            "Code Generation Activity": record.get("code_generation_activity_count", 0),
            "Code Acceptance Activity": record.get("code_acceptance_activity_count", 0),
            "LOC Suggested to Add": record.get("loc_suggested_to_add_sum", 0),
            "LOC Suggested to Delete": record.get("loc_suggested_to_delete_sum", 0),
            "LOC Added": record.get("loc_added_sum", 0),
            "LOC Deleted": record.get("loc_deleted_sum", 0),
            "Used Agent": record.get("used_agent", False),
            "Used Chat": record.get("used_chat", False),
        }
        main_data.append(main_row)

    return pd.DataFrame(main_data)


def create_ide_totals_sheet(data):
    """
    Create sheet for IDE-specific totals.
    """
    ide_data = []

    for record in data:
        user_info = {
            "User Login": record.get("user_login", ""),
            "Day": record.get("day", ""),
        }

        for ide_total in record.get("totals_by_ide", []):
            ide_row = user_info.copy()
            ide_row.update(
                {
                    "IDE": ide_total.get("ide", ""),
                    "User Initiated Interactions": ide_total.get(
                        "user_initiated_interaction_count", 0
                    ),
                    "Code Generation Activity": ide_total.get(
                        "code_generation_activity_count", 0
                    ),
                    "Code Acceptance Activity": ide_total.get(
                        "code_acceptance_activity_count", 0
                    ),
                    "LOC Suggested to Add": ide_total.get(
                        "loc_suggested_to_add_sum", 0
                    ),
                    "LOC Suggested to Delete": ide_total.get(
                        "loc_suggested_to_delete_sum", 0
                    ),
                    "LOC Added": ide_total.get("loc_added_sum", 0),
                    "LOC Deleted": ide_total.get("loc_deleted_sum", 0),
                    "Plugin Version": ide_total.get(
                        "last_known_plugin_version", {}
                    ).get("plugin_version", ""),
                    "IDE Version": ide_total.get("last_known_ide_version", {}).get(
                        "ide_version", ""
                    ),
                }
            )
            ide_data.append(ide_row)

    return pd.DataFrame(ide_data)


def create_feature_totals_sheet(data):
    """
    Create sheet for feature-specific totals.
    """
    feature_data = []

    for record in data:
        user_info = {
            "User Login": record.get("user_login", ""),
            "Day": record.get("day", ""),
        }

        for feature_total in record.get("totals_by_feature", []):
            feature_row = user_info.copy()
            feature_row.update(
                {
                    "Feature": feature_total.get("feature", ""),
                    "User Initiated Interactions": feature_total.get(
                        "user_initiated_interaction_count", 0
                    ),
                    "Code Generation Activity": feature_total.get(
                        "code_generation_activity_count", 0
                    ),
                    "Code Acceptance Activity": feature_total.get(
                        "code_acceptance_activity_count", 0
                    ),
                    "LOC Suggested to Add": feature_total.get(
                        "loc_suggested_to_add_sum", 0
                    ),
                    "LOC Suggested to Delete": feature_total.get(
                        "loc_suggested_to_delete_sum", 0
                    ),
                    "LOC Added": feature_total.get("loc_added_sum", 0),
                    "LOC Deleted": feature_total.get("loc_deleted_sum", 0),
                }
            )
            feature_data.append(feature_row)

    return pd.DataFrame(feature_data)


def create_language_feature_sheet(data):
    """
    Create sheet for language and feature breakdown.
    """
    lang_feature_data = []

    for record in data:
        user_info = {
            "User Login": record.get("user_login", ""),
            "Day": record.get("day", ""),
        }

        for lang_feature in record.get("totals_by_language_feature", []):
            lang_feature_row = user_info.copy()
            lang_feature_row.update(
                {
                    "Language": lang_feature.get("language", ""),
                    "Feature": lang_feature.get("feature", ""),
                    "Code Generation Activity": lang_feature.get(
                        "code_generation_activity_count", 0
                    ),
                    "Code Acceptance Activity": lang_feature.get(
                        "code_acceptance_activity_count", 0
                    ),
                    "LOC Suggested to Add": lang_feature.get(
                        "loc_suggested_to_add_sum", 0
                    ),
                    "LOC Suggested to Delete": lang_feature.get(
                        "loc_suggested_to_delete_sum", 0
                    ),
                    "LOC Added": lang_feature.get("loc_added_sum", 0),
                    "LOC Deleted": lang_feature.get("loc_deleted_sum", 0),
                }
            )
            lang_feature_data.append(lang_feature_row)

    return pd.DataFrame(lang_feature_data)


def create_language_model_sheet(data):
    """
    Create sheet for language and model breakdown.
    """
    lang_model_data = []

    for record in data:
        user_info = {
            "User Login": record.get("user_login", ""),
            "Day": record.get("day", ""),
        }

        for lang_model in record.get("totals_by_language_model", []):
            lang_model_row = user_info.copy()
            lang_model_row.update(
                {
                    "Language": lang_model.get("language", ""),
                    "Model": lang_model.get("model", ""),
                    "Code Generation Activity": lang_model.get(
                        "code_generation_activity_count", 0
                    ),
                    "Code Acceptance Activity": lang_model.get(
                        "code_acceptance_activity_count", 0
                    ),
                    "LOC Suggested to Add": lang_model.get(
                        "loc_suggested_to_add_sum", 0
                    ),
                    "LOC Suggested to Delete": lang_model.get(
                        "loc_suggested_to_delete_sum", 0
                    ),
                    "LOC Added": lang_model.get("loc_added_sum", 0),
                    "LOC Deleted": lang_model.get("loc_deleted_sum", 0),
                }
            )
            lang_model_data.append(lang_model_row)

    return pd.DataFrame(lang_model_data)


def create_model_feature_sheet(data):
    """
    Create sheet for model and feature breakdown.
    """
    model_feature_data = []

    for record in data:
        user_info = {
            "User Login": record.get("user_login", ""),
            "Day": record.get("day", ""),
        }

        for model_feature in record.get("totals_by_model_feature", []):
            model_feature_row = user_info.copy()
            model_feature_row.update(
                {
                    "Model": model_feature.get("model", ""),
                    "Feature": model_feature.get("feature", ""),
                    "User Initiated Interactions": model_feature.get(
                        "user_initiated_interaction_count", 0
                    ),
                    "Code Generation Activity": model_feature.get(
                        "code_generation_activity_count", 0
                    ),
                    "Code Acceptance Activity": model_feature.get(
                        "code_acceptance_activity_count", 0
                    ),
                    "LOC Suggested to Add": model_feature.get(
                        "loc_suggested_to_add_sum", 0
                    ),
                    "LOC Suggested to Delete": model_feature.get(
                        "loc_suggested_to_delete_sum", 0
                    ),
                    "LOC Added": model_feature.get("loc_added_sum", 0),
                    "LOC Deleted": model_feature.get("loc_deleted_sum", 0),
                }
            )
            model_feature_data.append(model_feature_row)

    return pd.DataFrame(model_feature_data)


def convert_json_to_xlsx(json_file_path, output_file_path=None):
    """
    Convert JSON file to XLSX with multiple sheets.
    """
    # Load the data
    data = load_json_data(json_file_path)
    if not data:
        return

    # Generate output file path if not provided
    if output_file_path is None:
        base_name = os.path.splitext(os.path.basename(json_file_path))[0]
        output_dir = os.path.dirname(json_file_path)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file_path = os.path.join(
            output_dir, f"{base_name}_converted_{timestamp}.xlsx"
        )

    # Create all sheets
    print("Creating sheets...")

    sheets = {
        "Main_Metrics": create_main_metrics_sheet(data),
        "IDE_Totals": create_ide_totals_sheet(data),
        "Feature_Totals": create_feature_totals_sheet(data),
        "Language_Feature": create_language_feature_sheet(data),
        "Language_Model": create_language_model_sheet(data),
        "Model_Feature": create_model_feature_sheet(data),
    }

    # Write to Excel file
    try:
        with pd.ExcelWriter(output_file_path, engine="openpyxl") as writer:
            for sheet_name, df in sheets.items():
                if not df.empty:
                    df.to_excel(writer, sheet_name=sheet_name, index=False)
                    print(f"Created sheet '{sheet_name}' with {len(df)} rows")
                else:
                    print(f"Warning: Sheet '{sheet_name}' is empty")

        print(f"\nSuccessfully converted JSON to XLSX: {output_file_path}")
        print(f"Total records processed: {len(data)}")

        # Print summary statistics
        print("\n--- Summary Statistics ---")
        main_df = sheets["Main_Metrics"]
        if not main_df.empty:
            print(f"Unique users: {main_df['User Login'].nunique()}")
            print(f"Date range: {main_df['Day'].min()} to {main_df['Day'].max()}")
            print(f"Total interactions: {main_df['User Initiated Interactions'].sum()}")
            print(
                f"Total code generations: {main_df['Code Generation Activity'].sum()}"
            )
            print(f"Total LOC added: {main_df['LOC Added'].sum()}")

    except Exception as e:
        print(f"Error writing to Excel file: {e}")


def main():
    """
    Main function to handle command line arguments or use default file.
    """
    if len(sys.argv) > 1:
        json_file_path = sys.argv[1]
        output_path = sys.argv[2] if len(sys.argv) > 2 else None
    else:
        # Use the default file in the same directory
        script_dir = os.path.dirname(os.path.abspath(__file__))
        json_file_path = os.path.join(script_dir, "json_file.json")
        output_path = None

    if not os.path.exists(json_file_path):
        print(f"Error: File {json_file_path} does not exist.")
        print("\nUsage:")
        print("  python json_to_xlsx.py [input_json_file] [output_xlsx_file]")
        print("  python json_to_xlsx.py  # Uses json_file.json in current directory")
        return

    print(f"Converting {json_file_path} to XLSX...")
    convert_json_to_xlsx(json_file_path, output_path)


if __name__ == "__main__":
    main()
