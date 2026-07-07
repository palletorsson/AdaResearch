# Force Props Sandbox

Before the word *vector*, the push. Play first; name later.

Push something and watch what the engine remembers.

```gdscript
func _on_force_cube_pushed(cube: RigidBody3D) -> void:
    print(cube.linear_velocity)  # e.g. (2.4, 0.0, -0.7)
```

Three numbers per push. Every shove you give this room is already a vector — a direction and an amount, packed together.

Mow a line through the dots.

```gdscript
func mower_step(mower: Node3D, delta: float) -> void:
    mower.position += mower.heading * mower.speed * delta
```

The mower moves by adding a small vector every frame. Where it ends up is the sum of everywhere it was pushed.

Blow a bubble against gravity.

```gdscript
func bubble_force(bubble: RigidBody3D) -> void:
    bubble.apply_central_force(Vector3.UP * buoyancy)
```

Two forces argue inside the bubble: gravity down, buoyancy up. The bubble's drift is their disagreement.

Keep clear of the pylon.

```gdscript
func pylon_check(player_pos: Vector3, pylon_pos: Vector3) -> bool:
    return (player_pos - pylon_pos).length() > danger_radius
```

Subtracting two positions gives the vector between them. Its length is your distance — your safety, measured.

> Try: push the force cube twice in different directions before it stops. The path it takes is the addition you'll write as code in the next room.

Everything in this sandbox ran on three ideas: add a push, scale by time, measure a length. The next rooms give those ideas their names — vector addition, scalar multiplication, magnitude.
