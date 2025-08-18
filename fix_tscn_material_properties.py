#!/usr/bin/env python3
"""
Fix material property issues in .tscn files for Godot 4 compatibility:
1. material = SubResource -> material_override = SubResource
2. emission = Color(...) * value -> emission = Color(...) + emission_energy = value
3. transparency = BaseMaterial3D.ENUM -> transparency = integer
"""

import os
import re

def fix_tscn_material_properties(file_path):
    """Fix material property issues in .tscn files"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Fix 1: material = SubResource -> material_override = SubResource
        pattern1 = r'^material = (SubResource\([^)]+\))$'
        matches1 = re.finditer(pattern1, content, re.MULTILINE)
        for match in matches1:
            subresource = match.group(1)
            old_line = f'material = {subresource}'
            new_line = f'material_override = {subresource}'
            content = content.replace(old_line, new_line)
            changes_made.append('material -> material_override')
        
        # Fix 2: emission = Color(...) * value -> emission = Color(...) + emission_energy = value
        pattern2 = r'emission = (Color\([^)]+\)) \* ([0-9.]+)'
        matches2 = list(re.finditer(pattern2, content))
        for match in reversed(matches2):  # Process in reverse to maintain positions
            color_part = match.group(1)
            energy_value = match.group(2)
            old_line = f'emission = {color_part} * {energy_value}'
            new_line = f'emission = {color_part}\nemission_energy = {energy_value}'
            content = content.replace(old_line, new_line)
            changes_made.append(f'emission syntax (* {energy_value})')
        
        # Fix 3: transparency = BaseMaterial3D.ENUM -> transparency = integer
        transparency_enums = {
            'BaseMaterial3D.TRANSPARENCY_DISABLED': '0',
            'BaseMaterial3D.TRANSPARENCY_ALPHA': '1',
            'BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR': '2',
            'BaseMaterial3D.TRANSPARENCY_ALPHA_HASH': '3',
            'BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS': '4',
            'StandardMaterial3D.TRANSPARENCY_DISABLED': '0',
            'StandardMaterial3D.TRANSPARENCY_ALPHA': '1',
            'StandardMaterial3D.TRANSPARENCY_ALPHA_SCISSOR': '2',
            'StandardMaterial3D.TRANSPARENCY_ALPHA_HASH': '3',
            'StandardMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS': '4'
        }
        
        for enum_name, int_value in transparency_enums.items():
            pattern = f'transparency = {re.escape(enum_name)}'
            if pattern.replace('\\', '') in content:
                content = content.replace(f'transparency = {enum_name}', f'transparency = {int_value}')
                changes_made.append(f'transparency enum -> {int_value}')
        
        # Fix similar issues with other material properties that might use enums
        blend_mode_enums = {
            'BaseMaterial3D.BLEND_MIX': '0',
            'BaseMaterial3D.BLEND_ADD': '1',
            'BaseMaterial3D.BLEND_SUB': '2',
            'BaseMaterial3D.BLEND_MUL': '3',
            'StandardMaterial3D.BLEND_MIX': '0',
            'StandardMaterial3D.BLEND_ADD': '1',
            'StandardMaterial3D.BLEND_SUB': '2',
            'StandardMaterial3D.BLEND_MUL': '3'
        }
        
        for enum_name, int_value in blend_mode_enums.items():
            if f'blend_mode = {enum_name}' in content:
                content = content.replace(f'blend_mode = {enum_name}', f'blend_mode = {int_value}')
                changes_made.append(f'blend_mode enum -> {int_value}')
        
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
    """Process all .tscn files in algorithms directory"""
    algorithms_dir = "algorithms"
    fixed_count = 0
    
    print("Fixing material property issues in .tscn files for Godot 4...")
    print("=" * 60)
    
    for root, dirs, files in os.walk(algorithms_dir):
        for file in files:
            if file.endswith('.tscn'):
                file_path = os.path.join(root, file)
                if fix_tscn_material_properties(file_path):
                    fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} .tscn files with material property issues")

if __name__ == "__main__":
    main()
