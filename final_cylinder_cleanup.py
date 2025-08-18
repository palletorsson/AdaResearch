#!/usr/bin/env python3
"""
Final cleanup for remaining CSGCylinder3D property issues:
Handle cases where top_radius and bottom_radius are set to variables
"""

import os
import re

def final_cylinder_cleanup(file_path):
    """Fix remaining variable-based cylinder property assignments"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Pattern: object.top_radius = variable followed by object.bottom_radius = same_variable
        pattern = r'(\w+)\.top_radius\s*=\s*(\w+[\w.]*)\s*\n\s*\1\.bottom_radius\s*=\s*\2'
        matches = list(re.finditer(pattern, content))
        
        for match in matches:
            object_name = match.group(1)
            variable_name = match.group(2)
            replacement = f'{object_name}.radius = {variable_name}'
            content = content.replace(match.group(0), replacement)
            changes_made.append(f"variable assignment {object_name}")
        
        # Pattern: object.top_radius = variable followed by object.bottom_radius = different_variable
        # Use the bottom_radius value (usually the main radius for cones converted to cylinders)
        pattern2 = r'(\w+)\.top_radius\s*=\s*(\w+[\w.]*)\s*\n\s*\1\.bottom_radius\s*=\s*(\w+[\w.]*)'
        matches2 = list(re.finditer(pattern2, content))
        
        for match in matches2:
            if match.group(2) != match.group(3):  # Different variables
                object_name = match.group(1)
                bottom_variable = match.group(3)
                replacement = f'{object_name}.radius = {bottom_variable}'
                content = content.replace(match.group(0), replacement)
                changes_made.append(f"different variables {object_name}")
        
        # Clean up any remaining single assignments
        content = re.sub(r'(\w+)\.top_radius\s*=\s*(\w+[\w.]*)', r'\1.radius = \2', content)
        content = re.sub(r'\s*\w+\.bottom_radius\s*=\s*\w+[\w.]*\s*\n?', '', content)
        
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
    """Process remaining files with cylinder property issues"""
    remaining_files = [
        "algorithms/wavefunctions/wave_propagation_3d/WavePropagation3D.gd",
        "algorithms/wavefunctions/wave_interference/WaveInterference.gd", 
        "algorithms/randomness/random_transformations/RandomTransformations.gd",
        "algorithms/randomness/digital_materiality_glitch/DigitalMaterialityGlitch.gd",
        "algorithms/proceduralaudio/generative_music/GenerativeMusic.gd",
        "algorithms/physicssimulation/softbodies/playground_of_joy/PlaygroundOfJoy.gd",
        "algorithms/physicssimulation/softbodies/affect_theory_visualization/AffectTheoryVisualization.gd",
        "algorithms/lsystems/tree_generation/TreeGeneration.gd"
    ]
    
    print("Final cleanup for remaining CSGCylinder3D property issues...")
    print("=" * 60)
    
    fixed_count = 0
    for file_path in remaining_files:
        if os.path.exists(file_path):
            if final_cylinder_cleanup(file_path):
                fixed_count += 1
    
    print("=" * 60)
    print(f"Final cleanup fixed {fixed_count} files")

if __name__ == "__main__":
    main()
