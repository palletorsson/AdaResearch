import json
p = "commons/mesh_grammar/research_configs.json"
with open(p) as f:
    data = json.load(f)

DNA_SHADER = "res://commons/foliage/critter_dna_billboard.gdshader"
DNA_TRES   = "res://commons/foliage/dna_samples/gen08_flower.tres"

# gen17_loop_closer — render a flower whose petal billboards are coloured
# by loading the gen08_flower.tres CritterDNA Resource that the
# MeshGrammarExporter previously emitted from gen08_stamped_flower.
# This closes the round-trip: design → export → re-render via DNA.

def petals_from_dna(k):
    rp = {}
    for i in range(k):
        rp[f"flower_petal_{i}"] = {
            "size": [0.32, 0.6],
            "color": [1.0, 1.0, 1.0],  # vertex color = white so the shader's primary_color shows pure
            "align_radial": True, "radial_tilt": 0.45,
            "shader": DNA_SHADER,
            "dna_resource": DNA_TRES,
            # Explicit overrides for fields the exported .tres doesn't carry.
            "dna_params": {
                "pattern_type": 0.0,        # dots — fill primary with secondary
                "pattern_density": 0.7,
                "pattern_intensity": 0.7,
                "roughness": 0.55
            }
        }
    return rp

new_configs = [{
    "id": "gen17_loop_closer_dna",
    "notes": ("Round-trip test: load commons/foliage/dna_samples/gen08_flower.tres "
              "(written earlier by MeshGrammarExporter from gen08_stamped_flower) "
              "and render petals coloured by its primary/secondary genes. Yellow "
              "primary + pink secondary + dots pattern."),
    "seed": "flower_disk", "seed_scale": 1.0, "generations": 1,
    "camera_angle": "iso", "camera_pitch": 0.5,
    "rules": [
        {"op": "tag_by_grammar", "selector": "all", "params": {"grammar": "flower"}},
        {"op": "cluster_by_role", "selector": "all", "params": {
            "role_params": {"flower_petal": {"k": 12, "method": "angular"}}
        }},
        {"op": "mark_billboard_anchors", "selector": "all", "params": {
            "remove_original": False, "one_per_role": True, "snap_radial": True,
            "role_params": petals_from_dna(12)
        }},
        {"op": "paint_by_tag", "selector": "all", "params": {"palette": {
            "flower_pistil": [1.0, 0.85, 0.2],
            "flower_sepal":  [0.4, 0.6, 0.35]
        }}}
    ]
}]

existing = {c["id"] for c in data["configs"]}
added = 0
for c in new_configs:
    if c["id"] not in existing:
        data["configs"].append(c)
        added += 1
with open(p, "w") as f:
    json.dump(data, f, indent=2)
print(f"added {added}")
