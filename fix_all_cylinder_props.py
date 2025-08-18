#!/usr/bin/env python3
"""
Comprehensive fix for all CSGCylinder3D property issues in Godot 4:
- .top_radius -> .radius (use first value)
- .bottom_radius -> remove (CSGCylinder3D only needs one radius)
"""

import os
import re

def fix_cylinder_properties_comprehensive(file_path):
    """Fix all CSGCylinder3D property issues"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Strategy: Find patterns where both top_radius and bottom_radius are set
        # and replace with just radius using the bottom_radius value (usually the main radius)
        
        # Pattern 1: object.top_radius = 0.0 followed by object.bottom_radius = X
        pattern1 = r'(\w+)\.top_radius\s*=\s*0\.0?\s*\n\s*\1\.bottom_radius\s*=\s*([0-9.]+)'
        matches = re.finditer(pattern1, content)
        for match in matches:
            object_name = match.group(1)
            radius_value = match.group(2)
            replacement = f'{object_name}.radius = {radius_value}'
            content = content.replace(match.group(0), replacement)
            changes_made.append(f"cone pattern {object_name}")
        
        # Pattern 2: Any remaining .top_radius = X (use this value for radius)
        remaining_top = re.finditer(r'(\w+)\.top_radius\s*=\s*([0-9.]+)', content)
        for match in remaining_top:
            object_name = match.group(1)
            radius_value = match.group(2)
            replacement = f'{object_name}.radius = {radius_value}'
            content = content.replace(match.group(0), replacement)
            changes_made.append(f"top_radius {object_name}")
        
        # Pattern 3: Any remaining .bottom_radius = X (use this value for radius if no top_radius was found)
        remaining_bottom = re.finditer(r'(\w+)\.bottom_radius\s*=\s*([0-9.]+)', content)
        for match in remaining_bottom:
            object_name = match.group(1)
            radius_value = match.group(2)
            # Check if we already set radius for this object
            if f'{object_name}.radius =' not in content:
                replacement = f'{object_name}.radius = {radius_value}'
                content = content.replace(match.group(0), replacement)
                changes_made.append(f"bottom_radius {object_name}")
            else:
                # Just remove the bottom_radius line
                content = content.replace(match.group(0), '')
                changes_made.append(f"removed extra bottom_radius {object_name}")
        
        # Clean up any remaining orphaned bottom_radius assignments
        content = re.sub(r'\s*\w+\.bottom_radius\s*=\s*[0-9.]+\s*\n?', '', content)
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            if changes_made:
                print(f"Fixed {file_path}: {', '.join(changes_made)}")
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
    
    print("Fixing all CSGCylinder3D property issues for Godot 4...")
    print("=" * 60)
    
    for root, dirs, files in os.walk(algorithms_dir):
        for file in files:
            if file.endswith('.gd'):
                file_path = os.path.join(root, file)
                if fix_cylinder_properties_comprehensive(file_path):
                    fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} files total")

if __name__ == "__main__":
    main()
