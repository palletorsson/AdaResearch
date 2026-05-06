import os
import json

# Define the base directory for maps
maps_dir = "commons/maps"

# Define the new maps to create
new_maps = {
    "LSystems_CityGenerator": {
        "name": "The City Generator",
        "description": "Procedural architecture using 3D L-Systems.",
        "category": "algorithms/l_systems",
        "scene_key": "LSystems_CityGenerator"
    },
    "LSystems_Hilbert3D": {
        "name": "3D Hilbert Curve",
        "description": "A space-filling curve visualization.",
        "category": "algorithms/l_systems",
        "scene_key": "LSystems_Hilbert3D"
    },
    "LSystems_AnimatedTree": {
        "name": "Animated Growth",
        "description": "Visualizing the growth process over time.",
        "category": "algorithms/l_systems",
        "scene_key": "LSystems_AnimatedTree"
    },
    "LSystems_ForestCompetition": {
        "name": "Ecosystem Simulation",
        "description": "Multiple L-Systems competing for resources.",
        "category": "algorithms/l_systems",
        "scene_key": "LSystems_ForestCompetition"
    },
    "LSystems_ContextSensitiveTree": {
        "name": "Context Sensitive Growth",
        "description": "L-Systems that react to their environment.",
        "category": "algorithms/l_systems",
        "scene_key": "LSystems_ContextSensitiveTree"
    }
}

def create_map_folders():
    for map_key, map_info in new_maps.items():
        # Create directory
        dir_path = os.path.join(maps_dir, map_key)
        os.makedirs(dir_path, exist_ok=True)
        
        # Create map_data.json
        data = {
            "id": map_key,
            "name": map_info["name"],
            "description": map_info["description"],
            "category": map_info["category"],
            "scene_path": "", # Loaded from registry
            "registry_key": map_info["scene_key"],
            "thumbnail_path": "",
            "order": 100
        }
        
        file_path = os.path.join(dir_path, "map_data.json")
        with open(file_path, 'w') as f:
            json.dump(data, f, indent=4)
            
        print(f"Created map: {map_key}")

if __name__ == "__main__":
    create_map_folders()
