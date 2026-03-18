# Mesh Morpher

Topology-aware creature that morphs between 4 shapes, each with a distinct attack pattern.

## Behavior

Extends `HazardCreatureBase`. Meshes sequence hazard teaching topology.

4 forms with distinct attacks:
1. **SPHERE** (blue) — Rolls fast
2. **CUBE** (orange) — Slams down
3. **TORUS** (purple) — Spins like a buzzsaw
4. **CYLINDER** (green) — Extends and sweeps

- Morphs every 5.0 seconds via scale shrink/grow transition
- Each form displays topology info (genus, Euler characteristic)

## Files

| File | Purpose |
|------|---------|
| `mesh_morpher.gd` | Main script — morphing, per-form attack logic |
| `mesh_morpher.tscn` | Scene |
