import os
import re

def fix_ext_resource_ids(file_path):
    """Fix ext_resource declarations by adding proper id fields"""
    print(f"Fixing ext_resource IDs in: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find all ext_resource declarations
    ext_resource_pattern = r'\[ext_resource type="Script" path="([^"]+)" uid="([^"]+)"\]'
    ext_resources = re.findall(ext_resource_pattern, content)
    
    # Create a mapping of script paths to unique IDs
    script_ids = {}
    for i, (script_path, uid) in enumerate(ext_resources):
        # Use a simple ID format: 1, 2, 3, etc.
        script_ids[uid] = str(i + 1)
    
    # Replace ext_resource lines with proper id format
    for uid, new_id in script_ids.items():
        # Find the line with this uid and add the id
        old_line_pattern = f'\\[ext_resource type="Script" path="([^"]+)" uid="{uid}"\\]'
        new_line_pattern = f'[ext_resource type="Script" path="\\1" id="{new_id}" uid="{uid}"]'
        
        # Use regex to replace the line
        content = re.sub(old_line_pattern, new_line_pattern, content)
    
    # Replace all ExtResource references to use the new IDs
    for uid, new_id in script_ids.items():
        content = content.replace(f'ExtResource("{uid}")', f'ExtResource("{new_id}")')
    
    # Write the fixed content back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed ext_resource IDs in: {file_path}")

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
            fix_ext_resource_ids(tscn_path)
        else:
            print(f"File not found: {tscn_path}")
    
    print("ext_resource ID fixing complete!")

if __name__ == "__main__":
    main()
