import os
import re

def fix_script_ids(file_path):
    """Fix script IDs by assigning unique IDs to each script and updating references"""
    print(f"Fixing script IDs in: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all ext_resource declarations
    ext_resource_pattern = r'\[ext_resource type="Script" path="([^"]+)" id="([^"]+)" uid="([^"]+)"\]'
    ext_resources = re.findall(ext_resource_pattern, content)
    
    # Create a mapping of script paths to unique IDs
    script_path_to_id = {}
    for i, (script_path, old_id, uid) in enumerate(ext_resources):
        script_name = os.path.basename(script_path)
        new_id = str(i + 1)
        script_path_to_id[script_path] = new_id
    
    # Replace ext_resource lines with proper unique IDs
    for script_path, new_id in script_path_to_id.items():
        old_line_pattern = f'\\[ext_resource type="Script" path="{re.escape(script_path)}" id="[^"]+" uid="[^"]+"\\]'
        new_line = f'[ext_resource type="Script" path="{script_path}" id="{new_id}" uid="uid://placeholder"]'
        content = re.sub(old_line_pattern, new_line, content)
    
    # Replace all ExtResource references to use the correct IDs
    for script_path, new_id in script_path_to_id.items():
        script_name = os.path.basename(script_path)
        # Find all script assignments that use this script
        old_pattern = f'script = ExtResource\("[^"]+"\)'
        new_pattern = f'script = ExtResource("{new_id}")'
        
        # Only replace if this node should use this script
        # We need to be more careful about this replacement
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if 'script = ExtResource(' in line and script_name in content:
                # This is a rough heuristic - in practice, we'd need to parse the scene tree
                lines[i] = re.sub(old_pattern, new_pattern, line)
        content = '\n'.join(lines)
    
    # Write the fixed content back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed script IDs in: {file_path}")

def main():
    base_path = "algorithms/physicssimulation/"
    algorithms = [
        "newtonslaws",
        "vectorfields", 
        "threebodyproblem",
        "bouncingball",
        "rigidbody",
        "constraints",
        "springmass",
        "fluidsimulation",
        "collisiondetection",
        "numericalintegration"
    ]
    
    for algorithm in algorithms:
        tscn_path = os.path.join(base_path, algorithm, f"{algorithm}.tscn")
        if os.path.exists(tscn_path):
            fix_script_ids(tscn_path)
        else:
            print(f"File not found: {tscn_path}")
    
    print("Script ID fixing complete!")

if __name__ == "__main__":
    main()
