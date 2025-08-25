#!/usr/bin/env python3
"""
Script to properly update PhysicsSimulation_ teleporter definitions while preserving formatting
"""

import json
import os
import glob
import re

def fix_teleporters_properly():
    """Update teleporter definitions while preserving compact formatting"""
    
    # Find all PhysicsSimulation_ folders
    physics_folders = glob.glob("commons/maps/PhysicsSimulation_*")
    
    print(f"Found {len(physics_folders)} PhysicsSimulation_ folders")
    
    updated_count = 0
    errors = []
    
    for folder in physics_folders:
        map_file = os.path.join(folder, "map_data.json")
        
        if not os.path.exists(map_file):
            print(f"⚠️  No map_data.json found in {folder}")
            continue
            
        try:
            # Read the file as text to preserve formatting
            with open(map_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Use regex to find and replace only the teleporter definition
            # Look for the old format with destination: "next"
            old_pattern = r'("t":\s*\{[^}]*"destination":\s*"next"[^}]*\})'
            
            if re.search(old_pattern, content):
                # Replace with new compact format
                new_teleporter = '''"t": {
			"type": "teleporter",
			"name": "Next Lesson",
			"description": "Continue to the next algorithm demonstration",
			"properties": {
				"action": "next_in_sequence"
			}
		}'''
                
                # Replace the old teleporter definition
                content = re.sub(old_pattern, new_teleporter, content)
                
                # Write back with preserved formatting
                with open(map_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                print(f"✅ Updated teleporter: {folder}")
                updated_count += 1
            else:
                print(f"⏭️  Already updated: {folder}")
                
        except Exception as e:
            error_msg = f"❌ Error updating {folder}: {str(e)}"
            print(error_msg)
            errors.append(error_msg)
    
    print(f"\n📊 Summary:")
    print(f"✅ Successfully updated: {updated_count} files")
    print(f"❌ Errors: {len(errors)}")
    
    if errors:
        print(f"\n❌ Error details:")
        for error in errors:
            print(f"  {error}")
    
    return updated_count, errors

if __name__ == "__main__":
    print("🔄 Properly updating PhysicsSimulation_ teleporter definitions...")
    updated, errors = fix_teleporters_properly()
    
    if errors:
        print(f"\n⚠️  Some files had errors. Check the output above.")
    else:
        print(f"\n🎉 All PhysicsSimulation_ teleporters updated successfully!")
