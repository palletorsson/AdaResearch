#!/usr/bin/env python3
"""
Comprehensive fix for all CSGCylinder3D .size property access errors
"""

import os
import re

# All CSGCylinder3D nodes found in scene files that might be accessed via .size
cylinder_nodes = [
    'ParticleCount', 'StructureSize', 'InertiaWeight', 'SwarmConvergence', 
    'PheromoneStrength', 'AntCount', 'MinDistance', 'IterationCount',
    'SampleCount', 'Parameter1', 'Parameter2', 'CarrierFreq', 'ModulatorFreq', 
    'ModulationIndex', 'FMRatio', 'FundamentalFreq', 'HarmonicCount',
    'FilterFrequency', 'FilterResonance', 'FilterType', 'ParameterU', 'ParameterV',
    'IterationControl', 'BiasIndicator', 'ForceIndicator', 'DistanceIndicator',
    'EntropyIndicator', 'GenerationControl', 'GenerationIndicator',
    'ProbabilityControl', 'FrequencyControl', 'AmplitudeControl', 'PhaseControl',
    'UnionOperationIndicator', 'PrefixIndicator', 'OperationIndicator',
    'HeightIndicator', 'LoadFactorIndicator', 'ListSizeIndicator',
    'GridModeIndicator', 'RotationIndicator', 'FieldResolution', 'LearningRate'
]

def fix_cylinder_size_comprehensive(file_path):
    """Fix all .size access on CSGCylinder3D nodes"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Pattern 1: $NodeName.size.y = value
        for node_name in cylinder_nodes:
            pattern = f'\\${re.escape(node_name)}\\.size\\.y\\s*=\\s*([^#\\n]+)'
            matches = list(re.finditer(pattern, content))
            for match in matches:
                value = match.group(1).strip()
                old_line = f'${node_name}.size.y = {value}'
                new_line = f'${node_name}.height = {value}'
                content = content.replace(old_line, new_line)
                changes_made.append(f'${node_name}.size.y -> .height')
        
        # Pattern 2: Safe access patterns we might have created
        # Look for variable.size.y where variable name contains a cylinder node name
        for node_name in cylinder_nodes:
            node_lower = node_name.lower()
            # Match patterns like: variable_name.size.y where variable_name contains node name
            pattern = f'([a-zA-Z_]*{re.escape(node_lower)}[a-zA-Z_]*)\\.size\\.y\\s*=\\s*([^#\\n]+)'
            matches = list(re.finditer(pattern, content, re.IGNORECASE))
            for match in matches:
                var_name = match.group(1)
                value = match.group(2).strip()
                old_line = f'{var_name}.size.y = {value}'
                new_line = f'{var_name}.height = {value}'
                content = content.replace(old_line, new_line)
                changes_made.append(f'{var_name}.size.y -> .height')
        
        if content != original_content:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            if changes_made:
                print(f"Fixed {file_path}: {', '.join(set(changes_made))}")
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
    
    print("Comprehensive fix for all CSGCylinder3D .size access errors...")
    print("=" * 60)
    
    for root, dirs, files in os.walk(algorithms_dir):
        for file in files:
            if file.endswith('.gd'):
                file_path = os.path.join(root, file)
                if fix_cylinder_size_comprehensive(file_path):
                    fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} files with CSGCylinder3D size issues")

if __name__ == "__main__":
    main()
