import os
import re
import uuid

def generate_uid():
    """Generate a proper Godot 4 UID format"""
    return f"uid://{uuid.uuid4().hex[:16]}"

def fix_scene_file(file_path):
    """Fix a single .tscn file with proper UIDs and IDs"""
    print(f"Fixing: {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Generate new scene UID
    new_scene_uid = generate_uid()
    
    # Find all ext_resource declarations
    ext_resource_pattern = r'\[ext_resource type="Script" path="([^"]+)" id="([^"]+)" uid="([^"]+)"\]'
    ext_resources = re.findall(ext_resource_pattern, content)
    
    # Create a mapping of script paths to unique IDs and UIDs
    script_mapping = {}
    for i, (script_path, old_id, old_uid) in enumerate(ext_resources):
        script_name = os.path.basename(script_path)
        new_id = str(i + 1)
        new_uid = generate_uid()
        script_mapping[script_path] = (new_id, new_uid)
    
    # Replace ext_resource lines with proper IDs and UIDs
    for script_path, (new_id, new_uid) in script_mapping.items():
        old_line_pattern = f'\\[ext_resource type="Script" path="{re.escape(script_path)}" id="[^"]+" uid="[^"]+"\\]'
        new_line = f'[ext_resource type="Script" path="{script_path}" id="{new_id}" uid="{new_uid}"]'
        content = re.sub(old_line_pattern, new_line, content)
    
    # Replace scene UID
    scene_uid_pattern = r'uid="uid://[^"]+"'
    content = re.sub(scene_uid_pattern, f'uid="{new_scene_uid}"', content)
    
    # Replace all ExtResource references to use the correct IDs
    for script_path, (new_id, new_uid) in script_mapping.items():
        # Find the script name to determine which nodes should use it
        script_name = os.path.basename(script_path)
        
        # If this is the main script (same name as the scene), use it for the root node
        scene_name = os.path.basename(file_path).replace('.tscn', '')
        if script_name.lower().startswith(scene_name.lower()):
            # This is the main script, find the root node and update it
            # Look for the first script assignment (which should be the root node)
            lines = content.split('\n')
            for i, line in enumerate(lines):
                if 'script = ExtResource(' in line:
                    # Replace this line with the correct ID
                    lines[i] = re.sub(r'script = ExtResource\("[^"]+"\)', f'script = ExtResource("{new_id}")', line)
                    break
            content = '\n'.join(lines)
        else:
            # This is a secondary script, find nodes that should use it
            # For now, we'll use a simple heuristic based on the script name
            if "ball" in script_name.lower():
                # This is likely for ball nodes
                ball_pattern = r'script = ExtResource\("[^"]+"\)'
                ball_replacement = f'script = ExtResource("{new_id}")'
                content = re.sub(ball_pattern, ball_replacement, content)
            elif "vector" in script_name.lower():
                # This is likely for vector field arrows
                vector_pattern = r'script = ExtResource\("[^"]+"\)'
                vector_replacement = f'script = ExtResource("{new_id}")'
                content = re.sub(vector_pattern, vector_replacement, content)
            else:
                # For other scripts, we'll need to be more specific
                # This is a limitation of the current approach
                pass
    
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
            fix_scene_file(tscn_path)
        else:
            print(f"File not found: {tscn_path}")
    
    print("All scenes fixed!")

if __name__ == "__main__":
    main()
