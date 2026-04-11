"""Batch capture: swap wall_shader_showcase shader and capture each one."""
import subprocess, json, shutil, os, sys
os.environ["PYTHONIOENCODING"] = "utf-8"

MAP_DIR = r"C:\Users\palle\Documents\GitHub\AdaResearch_46\commons\maps\Cove_Display_Gallery"
MAP_FILE = os.path.join(MAP_DIR, "map_data.json")
GODOT = r"C:\Users\palle\Desktop\Godot_v4.6-stable_win64.exe"
PROJECT = r"C:\Users\palle\Documents\GitHub\AdaResearch_46"
SHOTS_DIR = r"C:\Users\palle\AppData\Roaming\Godot\app_userdata\Ada Research Zero One\multi_shots\Cove_Display_Gallery"
OUT_DIR = r"C:\Users\palle\Documents\GitHub\AdaResearch_46\ada_encyclopedia\public\blog\shader_showcase"

SHADERS = [
    "voronoiShader",
    "tartanshader",
    "rothko",
    "TruchetFloor",
    "reaction_diffusion",
    "coffeeswirl",
    "slime",
    "DiscoGrid",
    "pearlescent",
    "wood",
    "pinktartan",
    "sci_fi_panel",
    "ColorCheckerFloor",
    "foil_paper",
    "mushroom_dots",
    "randomgridshader",
    "wornwood",
    "pimp_shader",
    "decay_one",
    "fire",
]

os.makedirs(OUT_DIR, exist_ok=True)

for i, shader in enumerate(SHADERS):
    print(f"\n{'='*60}")
    print(f"[{i+1}/{len(SHADERS)}] Capturing shader: {shader}")
    print(f"{'='*60}")

    # Read and modify map_data.json
    with open(MAP_FILE, "r") as f:
        data = json.load(f)

    # Find and replace the wall_shader_showcase entry in interactables
    interactables = data["layers"]["interactables"]
    for r, row in enumerate(interactables):
        for c, cell in enumerate(row):
            if isinstance(cell, str) and "wall_shader_showcase" in cell:
                interactables[r][c] = f"wall_shader_showcase#shader:{shader}#emission_strength:1.0"

    with open(MAP_FILE, "w") as f:
        json.dump(data, f, indent="\t")

    # Run Godot capture
    cmd = [
        GODOT, "--path", PROJECT, "--xr-mode", "off", "--no-window",
        "--script", "res://commons/testing/capture_multi_angle.gd",
        "--", "--mode=map", "--target=Cove_Display_Gallery"
    ]
    result = subprocess.run(cmd, capture_output=True, text=True, timeout=120, encoding="utf-8", errors="replace")

    # Copy the "front" shot with shader name
    front_src = os.path.join(SHOTS_DIR, "front.png")
    above_src = os.path.join(SHOTS_DIR, "above.png")
    if os.path.exists(front_src):
        shutil.copy2(front_src, os.path.join(OUT_DIR, f"{shader}_front.png"))
        print(f"  OK Saved {shader}_front.png")
    if os.path.exists(above_src):
        shutil.copy2(above_src, os.path.join(OUT_DIR, f"{shader}_above.png"))
        print(f"  OK Saved {shader}_above.png")

    # Check for errors
    if "Applied shader" in result.stdout:
        print(f"  OK Shader applied successfully")
    elif "Failed to load shader" in result.stdout:
        print(f"  FAIL Failed to load shader!")

print(f"\n{'='*60}")
print(f"Done! {len(SHADERS)} shaders captured to {OUT_DIR}")
