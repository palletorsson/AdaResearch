#!/usr/bin/env python3
"""
Script to fix JSON formatting in PhysicsSimulation_ files - make arrays more compact
"""

import json
import os
import glob

def fix_json_formatting():
    """Fix JSON formatting to make arrays more compact"""
    
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
            # Read the file
            with open(map_file, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            # Save with compact formatting (arrays on single lines where possible)
            with open(map_file, 'w', encoding='utf-8') as f:
                json.dump(data, f, indent='\t', ensure_ascii=False, separators=(',', ': '))
            
            print(f"✅ Fixed formatting: {folder}")
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
    print("🔄 Fixing JSON formatting in PhysicsSimulation_ files...")
    updated, errors = fix_json_formatting()
    
    if errors:
        print(f"\n⚠️  Some files had errors. Check the output above.")
    else:
        print(f"\n🎉 All PhysicsSimulation_ files formatted successfully!")
