# Soft Bodies Cloth Physics

Cloth is a grid of masses connected by structural, shear, and bend constraints.

Build a cloth lattice.

```gdscript
class_name ClothPatch extends Node3D

@export var width: int = 20
@export var height: int = 20
@export var spacing: float = 0.15

var particles: Array = []
var constraints: Array = []

func build() -> void:
    for y in height:
        for x in width:
            particles.append({"position": Vector3(x * spacing, 0, y * spacing), "prev_position": Vector3(x * spacing, 0, y * spacing), "velocity": Vector3.ZERO, "pinned": false})
```

Each particle stores current and previous position. Verlet integration uses both.

Add structural constraints.

```gdscript
func add_structural_constraints() -> void:
    for y in height:
        for x in width:
            var i := y * width + x
            if x + 1 < width:
                constraints.append({"a": i, "b": i + 1, "rest_length": spacing})
            if y + 1 < height:
                constraints.append({"a": i, "b": i + width, "rest_length": spacing})
```

Direct horizontal and vertical neighbours. Keeps the cloth's weave.

Add shear constraints.

```gdscript
func add_shear_constraints() -> void:
    for y in height - 1:
        for x in width - 1:
            var i := y * width + x
            constraints.append({"a": i, "b": i + width + 1, "rest_length": spacing * sqrt(2)})
            constraints.append({"a": i + 1, "b": i + width, "rest_length": spacing * sqrt(2)})
```

Diagonal connections between adjacent rows. Prevents the cloth from shearing freely.

Add bend constraints.

```gdscript
func add_bend_constraints() -> void:
    for y in height:
        for x in width - 2:
            var i := y * width + x
            constraints.append({"a": i, "b": i + 2, "rest_length": spacing * 2})
    for y in height - 2:
        for x in width:
            var i := y * width + x
            constraints.append({"a": i, "b": i + 2 * width, "rest_length": spacing * 2})
```

Every second mass connected. Resists bending without preventing it.

Verlet step.

```gdscript
@export var gravity: Vector3 = Vector3(0, -9.81, 0)

func verlet_step(delta: float) -> void:
    var dt_sq: float = delta * delta
    for p in particles:
        if p.pinned: continue
        var acceleration := gravity
        var new_pos: Vector3 = 2.0 * p.position - p.prev_position + acceleration * dt_sq
        p.prev_position = p.position
        p.position = new_pos
```

Velocity is implicit: derived from position minus previous position. Numerically stable.

Satisfy constraints.

```gdscript
func satisfy_constraints(iterations: int = 3) -> void:
    for _i in iterations:
        for c in constraints:
            var a = particles[c.a]
            var b = particles[c.b]
            var delta: Vector3 = b.position - a.position
            var length: float = delta.length()
            var diff: float = (length - c.rest_length) / length
            var correction: Vector3 = delta * 0.5 * diff
            if not a.pinned: a.position += correction
            if not b.pinned: b.position -= correction
```

Iteratively adjust positions to match rest lengths. More iterations means stiffer cloth.

Pin the cloth at corners.

```gdscript
func pin_corners() -> void:
    particles[0].pinned = true
    particles[width - 1].pinned = true
```

Cloth hangs from two corners. Gravity pulls the rest into drape.

You can now build a cloth lattice with structural, shear, and bend constraints, step with Verlet, satisfy constraints iteratively, and pin corners. SoftBodies_Playground_of_Joy extends into interactive soft-body playground.
