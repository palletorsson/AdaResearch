# Cellular spaces

Two optional walkable studies inspired by the nearest-feature-point construction in [The Book of Shaders, chapter 12](https://thebookofshaders.com/12/) and Palle's cream/olive cellular reference.

## Walk

From the repository root, run:

```powershell
./tools/open_cellular_spaces.ps1 -Form womb
./tools/open_cellular_spaces.ps1 -Form commons
```

The scene is `commons/artifacts/cellular_spaces/museum.tscn`. The launcher uses the current museum renderer, player and hall construction with its own two-hall plan and `user://cellular-spaces/` resume/output files. Click to capture the mouse, WASD to walk, Escape to release the pointer. The museum passage leads from enclosure to commons. `--no-bridges` prevents another live command session from replacing this preview.

The two maps are registered in the optional `cellular_spaces` sequence. They are candidates for Noise; the main curriculum plan is not changed by this addition. Launching in an exported Quest build and physical headset performance are still unverified.

## What the geometry does

**Noise_Cellular_Womb:** three overlapping ellipsoidal cavities are smoothly joined, then gently moulded by distances to seeded points in 3D. The boundary is baked using marching cubes. Two rounded throats open onto the museum floor. The enclosing geometry has height and depth; it is not a ray-marched picture. Its floor is intentionally level.

**Noise_Cellular_Commons:** sixteen lower feature points and four upper feature points define a true Euclidean 3D Voronoi partition. Upper cells cut the sloping roof faces. Lower cells become rooms, with 12 cm walls and 1.9 m wide, 2.55 m high archways. Six shared faces between four central cells are omitted. There are 22 openings including entry and exit, and all sixteen floor centres are connected. Floor dots retain the original sites, including the four whose boundaries no longer divide the middle.

Both use the exact rendered triangles for static wall collision. The wall shader samples a separate static 3D cellular field: nearest and second-nearest distances provide broad colour regions and luminous seams. This finer pattern is a surface treatment, not a map of the architectural cell boundaries. It does not change the collision or animate the viewer's ground.

## Rebuild

```powershell
python tools/build_cellular_spaces.py
```

Requires Python with numpy, scipy and scikit-image. Godot only reads the resulting JSON meshes; Python is not needed at runtime. Seed 731 is fixed for reproducible geometry. Womb: 41,094 triangles. Commons: 4,452 triangles. A future headset pass should profile both fragment cost and collision; current captures use desktop GL compatibility.

## Verification

```powershell
python tools/run_encounter_probe.py Noise_Cellular_Womb --sequence noise --render --no-bridges --probe doc/book/iterations/2026-10-13-cellular-spaces/museum_probe.gd --output-tag cellular-womb
python tools/run_encounter_probe.py Noise_Cellular_Commons --sequence noise --render --no-bridges --probe doc/book/iterations/2026-10-13-cellular-spaces/museum_probe.gd --output-tag cellular-commons
```

44/44 checks passed in the actual isolated museum: geometry/collision equality, standing-capsule clearance, floor support, passage sweeps, centre overlaps, expected omitted walls and retained capture cameras. These are desktop checks with a 1.7 m tall / 0.46 m wide capsule, not a headset comfort test. The separate launcher probe also passed for both start rooms and verified that the museum player and artifact load with isolated control files.

Screenshots, reports and the review page are in `doc/book/iterations/2026-10-13-cellular-spaces/`.
