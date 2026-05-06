import json
p = "commons/mesh_grammar/research_configs.json"
with open(p) as f:
    data = json.load(f)

DNA_SHADER = "res://commons/foliage/critter_dna_billboard.gdshader"
DNA_TRES   = "res://commons/foliage/dna_samples/gen08_flower.tres"

# gen18 mutation gallery — load the same gen08_flower DNA, vary ONE gene
# across N renders. Each variant is the same flower with the same primary
# (pink) and secondary (green) colours from the loaded DNA, but the
# pattern_* and iridescence genes are mutated per variant.

def make_petals(k, dna_overrides):
    rp = {}
    for i in range(k):
        rp[f"flower_petal_{i}"] = {
            "size": [0.32, 0.6],
            "color": [1.0, 1.0, 1.0],
            "align_radial": True, "radial_tilt": 0.45,
            "shader": DNA_SHADER,
            "dna_resource": DNA_TRES,
            "dna_params": dna_overrides
        }
    return rp

def make_config(slug, notes, dna_overrides):
    return {
        "id": f"gen18_mutation_{slug}",
        "notes": notes,
        "seed": "flower_disk", "seed_scale": 1.0, "generations": 1,
        "camera_angle": "iso", "camera_pitch": 0.5,
        "rules": [
            {"op": "tag_by_grammar", "selector": "all", "params": {"grammar": "flower"}},
            {"op": "cluster_by_role", "selector": "all", "params": {
                "role_params": {"flower_petal": {"k": 12, "method": "angular"}}
            }},
            {"op": "mark_billboard_anchors", "selector": "all", "params": {
                "remove_original": False, "one_per_role": True, "snap_radial": True,
                "role_params": make_petals(12, dna_overrides)
            }},
            {"op": "paint_by_tag", "selector": "all", "params": {"palette": {
                "flower_pistil": [1.0, 0.85, 0.2],
                "flower_sepal":  [0.4, 0.6, 0.35]
            }}}
        ]
    }

# Six variants — same DNA Resource, different mutation:
new_configs = [
    make_config("dots_low", "Pattern: dots, density 0.3 — sparse spots.",
                {"pattern_type": 0.0, "pattern_density": 0.3, "pattern_intensity": 0.7}),
    make_config("dots_high", "Pattern: dots, density 0.85 — dense spots.",
                {"pattern_type": 0.0, "pattern_density": 0.85, "pattern_intensity": 0.7}),
    make_config("stripes", "Pattern: stripes, density 0.5.",
                {"pattern_type": 0.25, "pattern_density": 0.5, "pattern_intensity": 0.85}),
    make_config("veins", "Pattern: veins (sinusoidal), density 0.5.",
                {"pattern_type": 0.75, "pattern_density": 0.5, "pattern_intensity": 0.7}),
    make_config("iridescent", "Same DNA + iridescence 0.7 — view-dependent hue shift on the pink primary.",
                {"pattern_type": 0.5, "pattern_density": 0.4, "pattern_intensity": 0.4, "iridescence": 0.7}),
    make_config("scales", "Pattern: grid (scales) — butterfly-tile look on the pink ground.",
                {"pattern_type": 0.5, "pattern_density": 0.7, "pattern_intensity": 0.85}),
]

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
