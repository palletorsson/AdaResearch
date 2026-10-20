# Reaction / Diffusion gallery

The 18 configurations from the encyclopedia's `/rd-gallery` now stand in the
Endless Museum's `ProceduralGeneration_Reaction_Diffusion_Systems` hall, in the
Soft Bodies sequence. The installation is anchored at map cell **(22, 29)**.
Two rows of nine off-white plinths leave a central comparison aisle and the
existing outer route to the exit.

These are **saved simulations**, not 18 live solvers. Their labels state the
feed rate F, kill rate K, iteration count, seed and rendering mode. The live
reaction desk and the other existing exhibits remain in place. The book's
current lesson and reflective text are unchanged.

## Source and rebuilding

`commons/rd_grammar/research_configs.json` matches the numerical and rendering
settings in all 18 web-gallery configs (some web notes have broken Unicode).
`tools/bake_rd_museum_gallery.gd` runs the existing Gray–Scott simulator
and gallery mesh builders in Godot, then saves compressed native scenes.
There is no numerical simulation on hall entry. Meshes are scaled uniformly
to fit 2.4 m display surfaces; relief proportions are retained.

The legacy heightmap builder's downward vertex normals are corrected in these
baked copies. Its numerical field and all other uses of that builder are unchanged.

```text
Godot --no-window --rendering-method gl_compatibility --xr-mode off --path . --script res://tools/bake_rd_museum_gallery.gd -- --rebuild --no-bridges
python tools/place_rd_museum_gallery.py
Godot --no-window --rendering-method gl_compatibility --xr-mode off --path . --script res://tests/test_rd_museum_gallery.gd -- --no-bridges
python tools/run_encounter_probe.py ProceduralGeneration_Reaction_Diffusion_Systems --sequence softbodies --render --no-bridges --output-tag rd-gallery-after --probe tools/probes/rd_gallery_room.gd
```

The first command regenerates every simulation and can take several minutes.
Without `--rebuild`, completed scenes with matching configurations are reused;
pillar buffers are checked before reuse. The headless dummy backend does
not retain MultiMesh transforms. Use a full
rebuild after changing the source, mesh builder or display design.
`manifest.json` records each configuration and its display position.
