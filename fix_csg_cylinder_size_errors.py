#!/usr/bin/env python3
"""
Fix all invalid .size property access on CSGCylinder3D nodes
CSGCylinder3D uses .height and .radius, not .size
"""

import os
import re

# Known CSGCylinder3D indicator/control nodes from scene files
cylinder_indicators = {
    'IterationControl': [
        'algorithms/RecursiveEmergence/mandelbrot_set/MandelbrotSet.gd',
        'algorithms/patterngeneration/penrose_tilings/PenroseTilings.gd',
        'algorithms/RecursiveEmergence/koch_curve/KochCurve.gd'
    ],
    'BiasIndicator': ['algorithms/CriticalAlgorithms/algorithmic_bias/AlgorithmicBias.gd'],
    'ForceIndicator': ['algorithms/GraphTheory/force_directed_layout/ForceDirectedLayout.gd'],
    'DistanceIndicator': ['algorithms/searchpathfinding/dijkstra_algorithm/DijkstraAlgorithm.gd'],
    'EntropyIndicator': ['algorithms/ProceduralGeneration/wave_function_collapse/WaveFunctionCollapse.gd'],
    'GenerationControl': ['algorithms/RecursiveEmergence/cellular_automata_3d/CellularAutomata3D.gd'],
    'GenerationIndicator': ['algorithms/RecursiveEmergence/cellular_automata_1d/CellularAutomata1D.gd'],
    'ProbabilityControl': ['algorithms/randomness/ten_print/TenPrint.gd'],
    'FrequencyControl': ['algorithms/wavefunctions/sine_space/SineSpace.gd'],
    'AmplitudeControl': ['algorithms/wavefunctions/sine_space/SineSpace.gd'],
    'PhaseControl': ['algorithms/wavefunctions/sine_space/SineSpace.gd'],
    'UnionOperationIndicator': ['algorithms/datastructures/union_find/UnionFind.gd'],
    'PrefixIndicator': ['algorithms/datastructures/trie_operations/TrieOperations.gd'],
    'OperationIndicator': ['algorithms/datastructures/heap_operations/HeapOperations.gd'],
    'HeightIndicator': ['algorithms/datastructures/binary_trees/BinaryTrees.gd'],
    'LoadFactorIndicator': ['algorithms/datastructures/hash_maps/HashMaps.gd'],
    'ListSizeIndicator': ['algorithms/datastructures/linked_lists/LinkedLists.gd'],
    'GridModeIndicator': ['algorithms/primitives/tron_grid/TronGrid.gd'],
    'RotationIndicator': ['algorithms/primitives/geometric_transformations/GeometricTransformations.gd']
}

def fix_cylinder_size_access(file_path):
    """Fix .size access on CSGCylinder3D nodes"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Pattern 1: $NodeName.size.y = value (direct access)
        pattern1 = r'\$([A-Za-z]+(?:Control|Indicator))\.size\.y\s*=\s*([^#\n]+)'
        matches = re.finditer(pattern1, content)
        for match in matches:
            node_name = match.group(1)
            value = match.group(2).strip()
            
            # Check if this node is a known CSGCylinder3D
            if node_name in cylinder_indicators:
                old_line = f'${node_name}.size.y = {value}'
                new_line = f'${node_name}.height = {value}'
                content = content.replace(old_line, new_line)
                changes_made.append(f'${node_name}.size.y -> .height')
        
        # Pattern 2: Safe node access patterns we've already created
        pattern2 = r'(\w+)\.size\.y\s*=\s*([^#\n]+)'
        matches2 = re.finditer(pattern2, content)
        for match in matches2:
            var_name = match.group(1)
            value = match.group(2).strip()
            
            # Check if this variable might be referencing a CSGCylinder3D
            # Look for the corresponding node name in the same file
            for node_name in cylinder_indicators:
                node_name_lower = node_name.lower()
                if node_name_lower in var_name.lower():
                    old_line = f'{var_name}.size.y = {value}'
                    new_line = f'{var_name}.height = {value}'
                    content = content.replace(old_line, new_line)
                    changes_made.append(f'{var_name}.size.y -> .height')
                    break
        
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
    """Process all files that might have CSGCylinder3D size issues"""
    files_to_check = []
    
    # Add all files that have known CSGCylinder3D indicators
    for node_name, file_list in cylinder_indicators.items():
        files_to_check.extend(file_list)
    
    # Remove duplicates
    files_to_check = list(set(files_to_check))
    
    print("Fixing CSGCylinder3D .size access errors...")
    print("=" * 60)
    
    fixed_count = 0
    for file_path in files_to_check:
        if os.path.exists(file_path):
            if fix_cylinder_size_access(file_path):
                fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} files with CSGCylinder3D size issues")

if __name__ == "__main__":
    main()
