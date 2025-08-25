#!/usr/bin/env python3
"""
Script to fix array formatting in PhysicsSimulation_ files using regex
"""

import os
import glob
import re

def fix_array_formatting():
    """Fix array formatting to make them more compact"""
    
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
            # Read the file as text
            with open(map_file, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Pattern to find arrays with one element per line
            # Look for: ["1", "2", "3", ...] on multiple lines
            pattern = r'\[\s*\n\s*"([^"]*)"(?:\s*,\s*\n\s*"([^"]*)")*\s*\]'
            
            def compact_array(match):
                # Extract all the values from the array
                values = re.findall(r'"([^"]*)"', match.group(0))
                # Return compact format
                return '["' + '", "'.join(values) + '"]'
            
            # Replace all arrays
            new_content = re.sub(pattern, compact_array, content)
            
            # Write back
            with open(map_file, 'w', encoding='utf-8') as f:
                f.write(new_content)
            
            print(f"✅ Fixed arrays: {folder}")
            updated_count += 1
                
        except Exception as e:
            error_msg = f"❌ Error fixing {folder}: {str(e)}"
            print(error_msg)
            errors.append(error_msg)
    
    print(f"\n📊 Summary:")
    print(f"✅ Successfully fixed: {updated_count} files")
    print(f"❌ Errors: {len(errors)}")
    
    if errors:
        print(f"\n❌ Error details:")
        for error in errors:
            print(f"  {error}")
    
    return updated_count, errors

if __name__ == "__main__":
    print("🔄 Fixing array formatting in PhysicsSimulation_ files...")
    updated, errors = fix_array_formatting()
    
    if errors:
        print(f"\n⚠️  Some files had errors. Check the output above.")
    else:
        print(f"\n🎉 All PhysicsSimulation_ arrays fixed successfully!")
