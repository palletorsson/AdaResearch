import os
import re
import uuid

def generate_uid():
    """Generate a proper Godot 4 UID format"""
    return f"uid://{uuid.uuid4().hex[:16]}"

def fix_tscn_file(file_path):
    """Fix UIDs in a single .tscn file"""
    print(f"Fixing: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Generate new UIDs
    new_scene_uid = generate_uid()
    script_uids = {}
    
    # Find all script references and assign new UIDs
    script_pattern = r'\[ext_resource type="Script" path="([^"]+)" uid="([^"]+)"\]'
    script_matches = re.findall(script_pattern, content)
    
    for script_path, old_uid in script_matches:
        new_uid = generate_uid()
        script_uids[old_uid] = new_uid
        
        # Replace the ext_resource line
        old_line = f'[ext_resource type="Script" path="{script_path}" uid="{old_uid}"]'
        new_line = f'[ext_resource type="Script" path="{script_path}" uid="{new_uid}"]'
        content = content.replace(old_line, new_line)
    
    # Replace scene UID
    scene_uid_pattern = r'uid="uid://[^"]+"'
    content = re.sub(scene_uid_pattern, f'uid="{new_scene_uid}"', content)
    
    # Replace all script references in nodes
    for old_uid, new_uid in script_uids.items():
        content = content.replace(f'ExtResource("{old_uid}")', f'ExtResource("{new_uid}")')
    
    # Write the fixed content back
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"Fixed: {file_path}")

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
            fix_tscn_file(tscn_path)
        else:
            print(f"File not found: {tscn_path}")
    
    print("UID fixing complete!")

if __name__ == "__main__":
    main()
