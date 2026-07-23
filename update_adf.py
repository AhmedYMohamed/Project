# update_adf.py
import json
import subprocess
import sys

FACTORY_NAME = "moi-data-factory-v2"
RESOURCE_GROUP = "rg-moi-reporting-prod"

def run_command(args):
    print(f"Executing: {' '.join(args)}")
    res = subprocess.run(args, capture_output=True, text=True)
    if res.returncode != 0:
        print(f"Error executing command: {res.stderr}")
        return False
    print(res.stdout)
    return True

def update_pipeline():
    print("\n--- Updating PL_Sync_Operations_To_Analytics Pipeline on Azure ---")
    pipeline_file = "pipeline/PL_Sync_Operations_To_Analytics.json"
    temp_file = "temp_pipeline_properties.json"
    
    try:
        with open(pipeline_file, 'r') as f:
            data = json.load(f)
        
        # Extract properties
        properties = data.get('properties', data)
        
        with open(temp_file, 'w') as f:
            json.dump(properties, f, indent=2)
            
        args = [
            "az", "datafactory", "pipeline", "create",
            "--factory-name", FACTORY_NAME,
            "--resource-group", RESOURCE_GROUP,
            "--name", "PL_Sync_Operations_To_Analytics",
            "--pipeline", f"@{temp_file}",
            "--if-match", "*"
        ]
        
        success = run_command(args)
        if success:
            print("✓ Pipeline updated successfully on Azure.")
        return success
    except Exception as e:
        print(f"✗ Failed to prepare/update pipeline: {e}")
        return False

def update_trigger():
    print("\n--- Updating and Starting TRIGGER_EVERY_15_MINUTES Trigger on Azure ---")
    trigger_file = "trigger/TRIGGER_EVERY_15_MINUTES.json"
    temp_file = "temp_trigger_properties.json"
    
    try:
        with open(trigger_file, 'r') as f:
            data = json.load(f)
            
        properties = data.get('properties', data)
        
        # Explicitly make sure recurrence interval is 1 hour
        properties["typeProperties"]["recurrence"]["interval"] = 1
        properties["typeProperties"]["recurrence"]["frequency"] = "Hour"
        
        with open(temp_file, 'w') as f:
            json.dump(properties, f, indent=2)
            
        # 1. Stop the trigger first (mandatory in ADF before updating)
        print("Stopping trigger...")
        stop_args = [
            "az", "datafactory", "trigger", "stop",
            "--factory-name", FACTORY_NAME,
            "--resource-group", RESOURCE_GROUP,
            "--name", "TRIGGER_EVERY_15_MINUTES"
        ]
        run_command(stop_args)
        
        # 2. Update trigger definition
        print("Deploying trigger updates...")
        create_args = [
            "az", "datafactory", "trigger", "create",
            "--factory-name", FACTORY_NAME,
            "--resource-group", RESOURCE_GROUP,
            "--name", "TRIGGER_EVERY_15_MINUTES",
            "--properties", f"@{temp_file}",
            "--if-match", "*"
        ]
        success = run_command(create_args)
        
        # 3. Start the trigger back up
        print("Starting trigger...")
        start_args = [
            "az", "datafactory", "trigger", "start",
            "--factory-name", FACTORY_NAME,
            "--resource-group", RESOURCE_GROUP,
            "--name", "TRIGGER_EVERY_15_MINUTES"
        ]
        run_command(start_args)
        
        if success:
            print("✓ Trigger updated and started successfully on Azure.")
        return success
    except Exception as e:
        print(f"✗ Failed to prepare/update trigger: {e}")
        return False

def main():
    pipeline_ok = update_pipeline()
    trigger_ok = update_trigger()
    
    # Cleanup temp files
    import os
    for temp in ["temp_pipeline_properties.json", "temp_trigger_properties.json"]:
        if os.path.exists(temp):
            os.remove(temp)
            
    if pipeline_ok and trigger_ok:
        print("\n🎉 Data Factory service successfully configured and activated on Azure!")
    else:
        print("\n⚠ Some updates failed. Review log above.")

if __name__ == "__main__":
    main()
