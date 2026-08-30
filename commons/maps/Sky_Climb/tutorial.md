# Sky Climb

A tower of empty air climbed by being thrown. Before it, the player must already be a CharacterBody3D that gravity is allowed to pull down.

Give the pad a trigger, not a floor.

```gdscript
func _build_area() -> void:
    var area := Area3D.new()
    area.collision_layer = 0
    area.collision_mask = PLAYER_MASK
    var shape := CollisionShape3D.new()
    shape.shape = BoxShape3D.new()
    shape.position.y = 0.75
    area.add_child(shape)
    add_child(area)
    area.body_entered.connect(_on_body_entered)
```

Layer 0 means nothing can collide with the pad itself. It only listens, on the player-body mask, for something entering the box above it.

Build the launch out of the pad's own axes.

```gdscript
func _launch_velocity() -> Vector3:
    var fwd := global_transform.basis.z
    fwd.y = 0.0
    if fwd.length() < 0.01:
        fwd = Vector3(0, 0, 1)
    return fwd.normalized() * forward_force + Vector3.UP * up_force
```

v₀ = forward·f̂ + up·ŷ — two components summed. The pad's basis decides which way forward is, so rotating the pad in the map rotates the throw. Flattening y first stops a tilted pad aiming into the floor.

Overwrite the velocity rather than adding to it.

```gdscript
func _on_body_entered(body: Node3D) -> void:
    if _cooldown > 0.0:
        return
    if body.is_in_group("player_body") and "velocity" in body:
        body.set("velocity", _launch_velocity())
        _cooldown = cooldown_time
```

The pad does not push. It replaces what the body was doing, which is why the throw is identical whether you walk on or fall on. Everything after that assignment belongs to gravity.

Ask how high one throw reaches.

```gdscript
func apex_height(up_force: float, gravity: float = 9.8) -> float:
    return up_force * up_force / (2.0 * gravity)
```

At the shipped 7 m/s that is 2.5 metres of rise. A pad set higher than this is unreachable from the one below it, however the climber approaches.

Find where the arc crosses the next floor.

```gdscript
func reach_at_height(forward: float, up: float, rise: float, gravity: float = 9.8) -> float:
    var disc := up * up - 2.0 * gravity * rise
    if disc < 0.0:
        return -1.0
    var t := (up - sqrt(disc)) / gravity
    return forward * t
```

Solving the arc backwards gives the distance at which the climber passes a given height on the way up. That is where the next pad has to sit. A negative discriminant means the floor is above the apex, and the chain breaks there.

Run the same equation in reverse at the top.

```gdscript
func return_velocity(from: Vector3, home: Vector3, flight_time: float) -> Vector3:
    var g := Vector3(0.0, -9.8, 0.0)
    return (home - from) / flight_time - 0.5 * g * flight_time
```

Name the landing and the duration, and the velocity is forced. There is exactly one arc through two points in a given time, so the return launcher does not aim — it solves.

Hang the counterweight where the rod balances.

```gdscript
func hang_arm(arm: float, w_left: float, w_right: float) -> Vector2:
    var total := w_left + w_right
    return Vector2(arm * w_right / total, arm * w_left / total)
```

Each rod's pivot sits where w_left·d_left equals w_right·d_right, so the heavier side rides the shorter arm. Weigh both children, then cut the rod, then recurse: the whole mobile hangs from one point.

Let the weights be real.

```gdscript
func leaf_mass(radius: float, thickness: float, density: float) -> float:
    return PI * radius * radius * thickness * density
```

Sheet-metal mass computed from the disc's own geometry, not a number chosen to make the picture level. The arms balance because the metal balances.

The shaft is twelve wide, thirty-two deep and twelve high, and two-thirds of its cells are empty air. Nothing here is walked to; every floor is arrived at. A launch is a velocity you are given and gravity writes the rest — in this room the rest is the whole climb, and the mobiles overhead are the same physics with all of its velocity already spent.
