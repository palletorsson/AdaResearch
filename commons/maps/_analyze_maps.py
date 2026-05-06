import glob
import json
import os

repo_root = r"c:\Users\palle\Documents\GitHub\AdaResearch"
maps_dir = os.path.join(repo_root, "commons", "maps")
artifacts_path = os.path.join(repo_root, "commons", "artifacts", "grid_artifacts.json")

# Load artifacts
try:
    with open(artifacts_path, 'r') as f:
        artifacts_data = json.load(f)
    artifacts = artifacts_data.get("artifacts", {})
except Exception as e:
    print(f"Error loading artifacts: {e}")
    artifacts = {}

# Find map files
map_files = glob.glob(os.path.join(maps_dir, "ProceduralGeneration*", "map_data.json"))

# Write output to file
output_path = os.path.join(maps_dir, "_map_analysis.txt")
with open(output_path, 'w') as f_out:
    print(f"Found {len(map_files)} maps.")

    for map_file in sorted(map_files):
        try:
            with open(map_file, 'r') as f:
                data = json.load(f)
            
            folder_name = os.path.basename(os.path.dirname(map_file))
            interactables = data.get("layers", {}).get("interactables", [])
            
            found_keys = set()
            for row in interactables:
                for cell in row:
                    if cell and isinstance(cell, str) and cell.strip():
                        key = cell.split('#')[0] 
                        key = key.split(':')[0]
                        found_keys.add(key)
            
            if not found_keys:
                continue
                
            f_out.write(f"FOLDER: {folder_name}\n")
            for key in sorted(found_keys):
                artifact = artifacts.get(key)
                if artifact:
                    scene = artifact.get("scene", "Unknown")
                    desc = artifact.get("description", "No description")
                    f_out.write(f"  KEY: {key}\n")
                    f_out.write(f"  SCENE: {scene}\n")
                    f_out.write(f"  DESC: {desc}\n")
                else:
                    f_out.write(f"  KEY: {key} (Not found in artifacts)\n")
            f_out.write("-" * 40 + "\n")
                
        except Exception as e:
            f_out.write(f"Error processing {map_file}: {e}\n")

