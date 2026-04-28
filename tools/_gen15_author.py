import json
p = "commons/mesh_grammar/research_configs.json"
with open(p) as f:
    data = json.load(f)

new_configs = []

# 1. Butterfly with billboard wings
butterfly_nodes = [
    [0, 0.18, -0.5], [0, 0.18, -0.2], [0, 0.18, 0.0],
    [0, 0.18, 0.25], [0, 0.18, 0.6],
    [-0.6, 0.18, -0.05], [-0.55, 0.18, 0.2],
    [0.6, 0.18, -0.05], [0.55, 0.18, 0.2],
]
butterfly_radii = [0.10, 0.13, 0.15, 0.10, 0.06, 0.04, 0.04, 0.04, 0.04]
butterfly_edges = [[0,1],[1,2],[2,3],[3,4],[2,5],[2,6],[2,7],[2,8]]
butterfly_tags = [["head"],["thorax"],["thorax"],["abdomen"],["abdomen"],
                  ["wing"],["wing"],["wing"],["wing"]]
new_configs.append({
    "id": "gen15_butterfly_billboard_wings",
    "notes": "Mixed-mode creature: body solid, wings as billboard alpha-quads.",
    "seed": {"graph": {"nodes": butterfly_nodes, "radii": butterfly_radii,
                       "edges": butterfly_edges, "node_tags": butterfly_tags,
                       "segments": 8, "skin_mode": "shared_rings_capped"}},
    "generations": 1,
    "camera_angle": "iso", "camera_pitch": 0.45,
    "rules": [
        {"op": "smooth_subdivide", "selector": "all", "params": {"passes": 1}},
        {"op": "mark_billboard_anchors", "selector": "tag:wing", "params": {
            "remove_original": True,
            "one_per_role": True,
            "snap_radial": False,
            "role_params": {
                "wing": {
                    "size": [0.7, 0.5],
                    "color": [0.9, 0.45, 0.65],
                    "align_radial": False
                }
            }
        }},
        {"op": "paint_by_tag", "selector": "all", "params": {"palette": {
            "head": [0.2, 0.15, 0.3], "thorax": [0.45, 0.35, 0.6],
            "abdomen": [0.6, 0.4, 0.7], "joint": [0.45, 0.35, 0.6]
        }}}
    ]
})

# 2. Tree with billboard leaves at every leaf node
new_configs.append({
    "id": "gen15_tree_billboard_leaves",
    "notes": "Graph-grammar tree skinned, every leaf-node gets a billboard. Tag-driven scatter.",
    "seed": {"graph_grammar": {
        "seed_node": {"pos": [0, 0, 0], "radius": 0.18, "tags": ["trunk"]},
        "generations": 3,
        "skin_segments": 6,
        "skin_mode": "shared_rings_capped",
        "rules": [
            {"op": "spawn_branch", "selector": "leaves", "params": {
                "count": 3, "length": 0.5, "spread_deg": 32, "radius_decay": 0.65,
                "jitter": 0.25, "seed": 13, "tag_children": "leaf"
            }}
        ]
    }},
    "generations": 1,
    "camera_angle": "iso", "camera_pitch": 0.35,
    "rules": [
        {"op": "mark_billboard_anchors", "selector": "tag:leaf", "params": {
            "remove_original": False,
            "one_per_role": False,
            "role_params": {
                "leaf": {
                    "size": [0.35, 0.45],
                    "color": [0.55, 0.75, 0.4],
                    "align_radial": False
                }
            }
        }},
        {"op": "paint_by_tag", "selector": "all", "params": {"palette": {
            "trunk": [0.4, 0.28, 0.18], "leaf": [0.55, 0.75, 0.4]
        }}}
    ]
})

# 3. Dense meadow - cube + split + billboard scatter
new_configs.append({
    "id": "gen15_grass_meadow",
    "notes": "Cube subdivided + every face becomes a grass-blade billboard. Stress-test for MultiMesh batching.",
    "seed": "cube",
    "seed_scale": 0.8,
    "generations": 1,
    "camera_angle": "iso", "camera_pitch": 0.25,
    "rules": [
        {"op": "split", "selector": "up", "params": {"subdivisions": 4}},
        {"op": "mark_billboard_anchors", "selector": "up", "params": {
            "remove_original": False,
            "one_per_role": False,
            "role_params": {},
            "default": {
                "size": [0.08, 0.18],
                "color": [0.35, 0.65, 0.3],
                "align_radial": False
            }
        }},
        {"op": "paint_by_tag", "selector": "all", "params": {"palette": {
            "default": [0.2, 0.4, 0.2]
        }}}
    ]
})

# 4. Full billboard flower - petals + stamens + pistil as billboards
petal_params = {f"flower_petal_{i}": {"size": [0.3, 0.55], "color": [0.95, 0.4, 0.65], "align_radial": True, "radial_tilt": 0.45} for i in range(12)}
stamen_params = {f"flower_stamen_{i}": {"size": [0.06, 0.25], "color": [0.95, 0.85, 0.3], "align_radial": True, "radial_tilt": 0.85} for i in range(8)}
all_role_params = dict(petal_params)
all_role_params.update(stamen_params)
all_role_params["flower_pistil"] = {"size": [0.18, 0.18], "color": [1.0, 0.85, 0.2], "align_radial": False, "y_offset": 0.05}

new_configs.append({
    "id": "gen15_flower_full_billboard",
    "notes": "Full billboard flower: 12 petals + 8 stamens + 1 pistil = single MultiMesh batch.",
    "seed": "flower_disk",
    "seed_scale": 1.0,
    "generations": 1,
    "camera_angle": "iso", "camera_pitch": 0.5,
    "rules": [
        {"op": "tag_by_grammar", "selector": "all", "params": {"grammar": "flower"}},
        {"op": "cluster_by_role", "selector": "all", "params": {
            "role_params": {
                "flower_petal": {"k": 12, "method": "angular"},
                "flower_stamen": {"k": 8, "method": "angular"}
            }
        }},
        {"op": "mark_billboard_anchors", "selector": "all", "params": {
            "remove_original": False,
            "one_per_role": True,
            "snap_radial": True,
            "role_params": all_role_params
        }},
        {"op": "paint_by_tag", "selector": "all", "params": {"palette": {
            "flower_sepal": [0.4, 0.6, 0.35]
        }}}
    ]
})

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
