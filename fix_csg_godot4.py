#!/usr/bin/env python3
"""
Fix CSG node issues for Godot 4 compatibility:
1. Replace CSGCone3D.new() with CSGCylinder3D.new()
2. Replace radius_top/radius_bottom with radius (for CSGCylinder3D)
3. Update cone-specific properties
"""

import os
import re

def fix_csg_godot4(file_path):
    """Fix CSG compatibility issues in a single file"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # 1. Replace CSGCone3D.new() with CSGCylinder3D.new()
        if 'CSGCone3D.new()' in content:
            content = content.replace('CSGCone3D.new()', 'CSGCylinder3D.new()')
            changes_made.append("CSGCone3D.new() -> CSGCylinder3D.new()")
        
        # 2. Fix radius_top and radius_bottom for CSGCylinder3D
        if 'radius_top' in content or 'radius_bottom' in content:
            # Replace radius_top = X with radius = X (keep the first value)
            content = re.sub(r'\.radius_top\s*=\s*([0-9.]+)', r'.radius = \1', content)
            
            # Remove radius_bottom lines entirely (since CSGCylinder3D only needs radius)
            content = re.sub(r'\s*\.radius_bottom\s*=\s*[0-9.]+\s*\n?', '\n', content)
            
            changes_made.append("radius_top/radius_bottom -> radius")
        
        # 3. Fix cone-specific properties to cylinder properties
        # radius_top = 0.0, radius_bottom = X should become radius = X
        cone_pattern = r'(\w+)\.radius_top\s*=\s*0\.0?\s*\n\s*\1\.radius_bottom\s*=\s*([0-9.]+)'
        if re.search(cone_pattern, content):
            content = re.sub(cone_pattern, r'\1.radius = \2', content)
            changes_made.append("cone pattern -> cylinder radius")
        
        # 4. Update height assignments that might be affected
        # For cones converted to cylinders, we might need to adjust height
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
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
    
    print("Fixing CSG compatibility issues for Godot 4...")
    print("=" * 60)
    
    for root, dirs, files in os.walk(algorithms_dir):
        for file in files:
            if file.endswith('.gd'):
                file_path = os.path.join(root, file)
                if fix_csg_godot4(file_path):
                    fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} files total")

if __name__ == "__main__":
    main()
