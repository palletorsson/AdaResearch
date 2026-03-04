# Bracelet Zoo — Technical

## Themed Crystal System

Each catalyst determines its visual theme from the highest-order unlocked mode. The `CatalystVisual.build_crystal()` function clears the previous visual and builds a new one based on a match statement:

```gdscript
static func _get_theme(unlocked_modes: Array[String]) -> String:
    var highest_mode := "primitives"
    var highest_order := 0
    for mode_id in unlocked_modes:
        var order: int = MODE_ORDER.get(mode_id, 0)
        if order > highest_order:
            highest_order = order
            highest_mode = mode_id
    return highest_mode
```

Grid config `start_mode:chaos` unlocks that mode alongside the default primitives. Since chaos has order 7 vs primitives' order 1, the crystal takes on the chaos theme.

## Crystal Shape Mapping

| Mode | Shape | Mesh Type |
|------|-------|-----------|
| Primitives | Octahedron | SphereMesh (6 segments) |
| Transformation | Twisted double-pyramid | 2× SphereMesh, counter-rotated |
| Chromatic | Triangular prism | CylinderMesh (3 sides) |
| Forces | Smooth sphere | SphereMesh (16 segments) |
| Waveform | Double torus | 2× TorusMesh, counter-tilted |
| Chaos | Fractured shards | 2× SphereMesh (4-5 segments) |
| Cellular | Cube + grid | BoxMesh + 9× small BoxMesh |
| Fractal | Recursive crystals | 1 + 5 + 8 SphereMeshes |
| Branching | Y-tree | CylinderMesh trunk + branches |
| Swarm | Boid cluster | 8× SphereMesh via Node3D |

## Capacity Bracelet

The bracelet spawns on the controller wrist when a catalyst is picked up. It uses an `InteractableHinge` with stepped snapping — the other hand grabs the ring and rotates to switch modes. Gems on the torus correspond to unlocked modes, colored by `CatalystVisual.MODE_COLORS`.

## Practice Targets

`catalyst_target.gd` extends StaticBody3D with:
- `moving:true` — sinusoidal patrol along X axis
- `orbit:true` — circular patrol in XZ plane
- Visual hit feedback: emission flash + shake tween
