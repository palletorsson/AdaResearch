# Wavefunction Shared Resources

This folder contains shared resources and utilities for wavefunction visualizations.

## WavefunctionResources

A static class providing shared meshes, materials, and audio utilities. **No autoload required** — uses static pattern for lazy initialization.

### Why?

Before optimization, each wavefunction scene created its own resources:
- `SphericalHarmonics` created 128 trail spheres (128 meshes, 128 materials)
- `OscillatingWave` created its own meshes
- Every scene duplicated common resources

Now, resources are created **once** and shared:

```gdscript
# Before: 128 allocations
for i in range(128):
    var sphere = SphereMesh.new()      # New mesh every time
    var material = StandardMaterial3D.new()  # New material every time

# After: 1 allocation, shared
var shared_mesh = WavefunctionResources.get_trail_sphere()  # Created once
for i in range(128):
    point.mesh = shared_mesh  # Same mesh, 128 references
```

### Usage

```gdscript
# Get shared meshes
var trail = WavefunctionResources.get_trail_sphere()  # radius 0.02
var unit = WavefunctionResources.get_unit_sphere()    # radius 1.0
var point = WavefunctionResources.get_point_sphere()  # radius 0.01

# Get cached materials (created once per color+alpha combo)
var mat = WavefunctionResources.get_emissive_material(Color.ORANGE, 0.8)
var glass = WavefunctionResources.get_glass_material(Color.BLUE, 0.3)

# Create MultiMesh for trails (replaces 128 nodes with 1)
var mmi = WavefunctionResources.create_trail_multimesh_instance(128, Color.ORANGE)

# Fast audio waveforms (lookup tables)
var sample = WavefunctionResources.fast_sine(phase)   # phase 0.0-1.0
var sample = WavefunctionResources.fast_square(phase)
```

### Performance Impact

| Metric | Before | After |
|--------|--------|-------|
| Trail nodes | 128 MeshInstance3D | 1 MultiMeshInstance3D |
| Mesh allocations | 128 | 1 (shared) |
| Material allocations | 128 | ~5 (cached) |
| Draw calls | 128 | 1 |
| Memory | High | ~75% reduction |

### Files

- `wavefunction_resources.gd` — The shared resource singleton (static class)

### Scenes Using This

| Scene | Before | After | Status |
|-------|--------|-------|--------|
| `spherical_harmonics/` | 128 MeshInstance3D | 1 MultiMesh | ✅ Done |
| `oscillating_wave/` | 300 MeshInstance3D | 2 MultiMesh | ✅ Done |
| `beat_frequencies/` | 224 MeshInstance3D | 4 MultiMesh | ✅ Done |
| `wave_propagation_3d/` | Already MultiMesh | — | ✅ OK |
| `lissajous_curves/` | 1 ImmediateMesh | — | ✅ OK |
| `doublehelix/` | Already MultiMesh | — | ✅ OK |

**Total nodes eliminated:** ~650 → ~10 (65x reduction)

See `WAVEFUNCTION_OPTIMIZATION_ANALYSIS.md` for the full optimization roadmap.
