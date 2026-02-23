# Point Line - Technical Tutorial

Point_Line teaches one implementation truth: a line is derived from endpoints.

## Endpoint Model

The line relation starts from two positions:

```gdscript
var point_a: Vector3
var point_b: Vector3
var distance: float = point_a.distance_to(point_b)
var direction: Vector3 = (point_b - point_a).normalized()
```

No independent "line state" is required beyond endpoint references.

## In-Scene Pattern

`line_demo.tscn` wires two snap points and a snap connection manager:

- `snap_point.tscn` provides grabbable endpoints.
- `snap_connection_manager.gd` manages connection lifecycle.
- `line_demo.gd` toggles instructional display visibility based on connection events.

This keeps the map logic minimal: interaction drives relation, relation drives rendering.

## Rendering the Relation

Typical line rendering uses a cylinder mesh between endpoints:

```gdscript
var midpoint: Vector3 = (point_a + point_b) / 2.0
var length: float = point_a.distance_to(point_b)

# Cylinder height matches measured length
cylinder.height = length
mesh_instance.position = midpoint
```

Orientation is solved from endpoint direction each update.

## VR Notes

- Endpoint grab affordance must be clear and stable.
- Keep line updates deterministic and lightweight.
- Prefer updating existing mesh/transforms over rebuilding scene trees.

## Key Takeaway

The map does not teach "line as thing." It teaches line as computed relation: move points, relation updates immediately.
