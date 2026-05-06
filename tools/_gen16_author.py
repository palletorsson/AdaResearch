import json
p = "commons/mesh_grammar/research_configs.json"
with open(p) as f:
    data = json.load(f)

DNA_SHADER = "res://commons/foliage/critter_dna_billboard.gdshader"

new_configs = []

def petals_with_dna(k, primary, secondary, pattern_type, pattern_density=0.6, pattern_intensity=0.7, iridescence=0.0):
    """Build role params for k petals with shared DNA shader settings."""
    rp = {}
    for i in range(k):
        rp[f"flower_petal_{i}"] = {
            "size": [0.32, 0.6],
            "color": primary,  # vertex color (used as v_instance_color tint)
            "align_radial": True, "radial_tilt": 0.45,
            "shader": DNA_SHADER,
            "dna_params": {
                "primary_color": primary,
                "secondary_color": secondary,
                "pattern_type": pattern_type,
                "pattern_density": pattern_density,
                "pattern_intensity": pattern_intensity,
                "iridescence": iridescence,
                "roughness": 0.6
            }
        }
    return rp

def make_dna_flower(slug, notes, primary, secondary, pattern_type, density=0.6, intensity=0.7, iridescence=0.0):
    return {
        "id": f"gen16_dna_petals_{slug}",
        "notes": notes,
        "seed": "flower_disk", "seed_scale": 1.0, "generations": 1,
        "camera_angle": "iso", "camera_pitch": 0.45,
        "rules": [
            {"op": "tag_by_grammar", "selector": "all", "params": {"grammar": "flower"}},
            {"op": "cluster_by_role", "selector": "all", "params": {
                "role_params": {"flower_petal": {"k": 12, "method": "angular"}}
            }},
            {"op": "mark_billboard_anchors", "selector": "all", "params": {
                "remove_original": False, "one_per_role": True, "snap_radial": True,
                "role_params": petals_with_dna(12, primary, secondary, pattern_type, density, intensity, iridescence)
            }},
            {"op": "paint_by_tag", "selector": "all", "params": {"palette": {
                "flower_pistil": [1.0, 0.85, 0.2],
                "flower_sepal":  [0.4, 0.6, 0.35]
            }}}
        ]
    }

# Five DNA variants on the same flower geometry. Same petal silhouette,
# same alpha mask, same MultiMesh — different DNA = different look.

new_configs.append(make_dna_flower(
    "dots",
    "DNA pattern 0.0 = dots. Two-tone fill on the petal silhouette: pink + dark dots.",
    primary=[0.95, 0.4, 0.65], secondary=[0.4, 0.15, 0.3],
    pattern_type=0.0, density=0.7
))

new_configs.append(make_dna_flower(
    "stripes",
    "DNA pattern 0.25 = stripes. Tiger-like vertical bands on each petal.",
    primary=[0.95, 0.55, 0.2], secondary=[0.25, 0.1, 0.05],
    pattern_type=0.25, density=0.5, intensity=0.85
))

new_configs.append(make_dna_flower(
    "veins",
    "DNA pattern 0.75 = veins (sinusoidal). Leaf-vein style on petals.",
    primary=[0.85, 0.3, 0.5], secondary=[0.3, 0.05, 0.15],
    pattern_type=0.75, density=0.45, intensity=0.6
))

new_configs.append(make_dna_flower(
    "iridescent",
    "DNA pattern 0.5 + iridescence 0.6. View-dependent hue shift on the petals.",
    primary=[0.7, 0.3, 0.85], secondary=[0.3, 0.6, 0.85],
    pattern_type=0.5, density=0.4, intensity=0.5, iridescence=0.7
))

new_configs.append(make_dna_flower(
    "scales",
    "DNA pattern 0.5 = grid (scales). Reptilian / butterfly-wing-tile look.",
    primary=[0.4, 0.7, 0.5], secondary=[0.15, 0.3, 0.25],
    pattern_type=0.5, density=0.7, intensity=0.85
))

existing = {c["id"] for c in data["configs"]}
added = 0
for c in new_configs:
    if c["id"] not in existing:
        data["configs"].append(c)
        added += 1
with open(p, "w") as f:
    json.dump(data, f, indent=2)
print(f"added {added}")
print("ids:", [c["id"] for c in new_configs])
