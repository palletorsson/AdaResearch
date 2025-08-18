#!/usr/bin/env python3
"""
Fix CSGCylinder3D nodes that incorrectly use .size.y instead of .height
"""

import os
import re

# Known CSGCylinder3D indicator nodes that need fixing
cylinder_indicators = {
    'OperationIndicator': ['algorithms/datastructures/heap_operations/HeapOperations.gd'],
    'GenerationIndicator': ['algorithms/lsystems/tree_generation/TreeGeneration.gd'],
    'DistanceIndicator': ['algorithms/searchpathfinding/dijkstra_algorithm/DijkstraAlgorithm.gd'],
    'ComplexityIndicator': ['algorithms/RecursiveEmergence/koch_curve/KochCurve.gd'],
    'GridModeIndicator': ['algorithms/primitives/tron_grid/TronGrid.gd'],
    'ForceIndicator': ['algorithms/GraphTheory/force_directed_layout/ForceDirectedLayout.gd'],
    'ComponentIndicator': ['algorithms/datastructures/union_find/UnionFind.gd'],
    'UnionOperationIndicator': ['algorithms/datastructures/union_find/UnionFind.gd'],
    'PrefixIndicator': ['algorithms/datastructures/trie_operations/TrieOperations.gd'],
    'ListSizeIndicator': ['algorithms/datastructures/linked_lists/LinkedLists.gd'],
    'EntropyIndicator': ['algorithms/ProceduralGeneration/wave_function_collapse/WaveFunctionCollapse.gd'],
    'DensityIndicator': ['algorithms/RecursiveEmergence/cellular_automata_3d/CellularAutomata3D.gd'],
    'AlgorithmStepIndicator': ['algorithms/computationalgeometry/closest_pair/ClosestPair.gd'],
    'FrequencyIndicator': ['algorithms/wavefunctions/standing_waves/StandingWaves.gd'],
    'AmplitudeIndicator': ['algorithms/wavefunctions/standing_waves/StandingWaves.gd']
}

def fix_cylinder_size_to_height(file_path):
    """Fix .size.y to .height for CSGCylinder3D nodes"""
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original_content = content
        changes_made = []
        
        # Pattern 1: $NodeName.size.y = value
        pattern1 = r'\$([A-Za-z]+Indicator)\.size\.y\s*=\s*([^#\n]+)'
        matches = re.finditer(pattern1, content)
        for match in matches:
            node_name = match.group(1)
            value = match.group(2).strip()
            
            # Replace with safe node access and .height
            old_pattern = f'${node_name}.size.y = {value}'
            new_pattern = f'''var {node_name.lower()} = get_node_or_null("{node_name}")
\tif {node_name.lower()} and {node_name.lower()} is CSGCylinder3D:
\t\t{node_name.lower()}.height = {value}'''
            
            content = content.replace(old_pattern, new_pattern)
            changes_made.append(f"${node_name}.size.y -> .height")
        
        # Pattern 2: $NodeName.position.y = 
        # Also need to update corresponding position assignments
        pattern2 = r'\$([A-Za-z]+Indicator)\.position\.y\s*=\s*([^#\n]+)'
        matches2 = re.finditer(pattern2, content)
        for match in matches2:
            node_name = match.group(1)
            value = match.group(2).strip()
            
            # Check if we already have safe access for this node
            safe_access_exists = f'var {node_name.lower()} = get_node_or_null("{node_name}")' in content
            
            if safe_access_exists:
                old_pattern = f'${node_name}.position.y = {value}'
                new_pattern = f'\t\t{node_name.lower()}.position.y = {value}'
                content = content.replace(old_pattern, new_pattern)
                changes_made.append(f"${node_name}.position.y -> safe access")
        
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
    """Process files with CSGCylinder3D indicator issues"""
    files_to_fix = [
        'algorithms/lsystems/tree_generation/TreeGeneration.gd',
        'algorithms/searchpathfinding/dijkstra_algorithm/DijkstraAlgorithm.gd', 
        'algorithms/RecursiveEmergence/koch_curve/KochCurve.gd',
        'algorithms/RecursiveEmergence/cellular_automata_1d/CellularAutomata1D.gd',
        'algorithms/primitives/tron_grid/TronGrid.gd',
        'algorithms/GraphTheory/force_directed_layout/ForceDirectedLayout.gd',
        'algorithms/datastructures/union_find/UnionFind.gd',
        'algorithms/datastructures/trie_operations/TrieOperations.gd',
        'algorithms/datastructures/linked_lists/LinkedLists.gd',
        'algorithms/ProceduralGeneration/wave_function_collapse/WaveFunctionCollapse.gd',
        'algorithms/RecursiveEmergence/cellular_automata_3d/CellularAutomata3D.gd',
        'algorithms/computationalgeometry/closest_pair/ClosestPair.gd',
        'algorithms/wavefunctions/standing_waves/StandingWaves.gd'
    ]
    
    print("Fixing CSGCylinder3D .size.y -> .height issues...")
    print("=" * 60)
    
    fixed_count = 0
    for file_path in files_to_fix:
        if os.path.exists(file_path):
            if fix_cylinder_size_to_height(file_path):
                fixed_count += 1
    
    print("=" * 60)
    print(f"Fixed {fixed_count} files with CSGCylinder3D size issues")

if __name__ == "__main__":
    main()
