#!/usr/bin/env python3
"""
Fix CSGCylinder3D property names across all algorithm files
Changes:
- .top_radius -> .radius_top
- .bottom_radius -> .radius_bottom
"""

import os
import re

def fix_cylinder_properties(file_path):
    """Fix CSGCylinder3D property names in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        
        # Fix property names
        content = re.sub(r'\.top_radius\s*=', '.radius_top =', content)
        content = re.sub(r'\.bottom_radius\s*=', '.radius_bottom =', content)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"Fixed: {file_path}")
            return True
        else:
            return False
            
    except Exception as e:
        print(f"Error processing {file_path}: {e}")
        return False

def main():
    """Process all .gd files in algorithms directory"""
    algorithms_dir = "algorithms"
    fixed_count = 0
    
    for root, dirs, files in os.walk(algorithms_dir):
        for file in files:
            if file.endswith('.gd'):
                file_path = os.path.join(root, file)
                if fix_cylinder_properties(file_path):
                    fixed_count += 1
    
    print(f"\nFixed {fixed_count} files total")

if __name__ == "__main__":
    main()
