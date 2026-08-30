# Chamber Primitives

The room where the primitives stop being demonstrations and become a relationship. Before it, the point, the sphere and the cube must each already stand alone.

Unlock one mode and nothing else.

```gdscript
func configure(config_data: Dictionary) -> void:
    if config_data.has("start_mode"):
        _unlock_mode(str(config_data["start_mode"]))
```

The map writes `becoming_catalyst#start_mode:primitives`. The bracelet arrives with one verb.

Pick the cell two steps ahead of you.

```gdscript
const REACH := 2

func cardinal_offset(look: Vector3) -> Vector3i:
    var flat := Vector2(look.x, look.z)
    if absf(flat.x) > absf(flat.y):
        return Vector3i(REACH, 0, 0) if flat.x > 0 else Vector3i(-REACH, 0, 0)
    return Vector3i(0, 0, REACH) if flat.y > 0 else Vector3i(0, 0, -REACH)
```

Where you look picks one of four directions. Where you stand is the origin. You are the coordinate system now, not a point inside one.

Fire a sphere along the controller's axis.

```gdscript
static func create_projectile(pos: Vector3, dir: Vector3) -> CatalystProjectile:
    var proj := CatalystProjectile.new()
    proj.set_script(load("res://commons/hazards/becoming_catalyst/modes/primitives_projectile.gd"))
    proj.speed = 6.0
    proj.direction = dir
    return proj
```

`set_script()` runs first because it reinitialises every variable. Anything set before it is discarded.

Let the sphere survive its own collision.

```gdscript
func _apply_initial_velocity() -> void:
    var phys_mat := PhysicsMaterial.new()
    phys_mat.bounce = 0.85
    physics_material_override = phys_mat
    gravity_scale = 0.4
    contact_monitor = true
    linear_velocity = direction.normalized() * speed
```

A projectile that dies on contact touches one thing. This one bounces, so one shot can put three bodies into relation.

Shrink the mesh, never the body.

```gdscript
func _update_trajectory(_delta: float) -> void:
    var t: float = clampf(time_alive / lifetime, 0.0, 1.0)
    _mesh_instance.scale = Vector3.ONE * (1.0 - t * t)
    _collision_shape.scale = _mesh_instance.scale
```

Scaling a RigidBody3D fights the integrator and pins the body in place. The sphere shrinks toward zero radius, which is where Point One started.

Answer a hit with a state, not a deletion.

```gdscript
func hit_by_projectile(projectile_color: Color = Color.WHITE) -> void:
    _hit_count += 1
    _set_emission_boost(4.0)
    if _hit_count >= _hits_to_destroy:
        _explode()
```

Flash, explode, respawn on a timer. The target takes the projectile's colour, so you can see which mode landed. Across all four phases it is the same object.

Hold the vent's clock until the bracelet is armed.

```gdscript
func _physics_process(delta: float) -> void:
    if _emitted >= wave_size:
        return
    if not _started and not _is_catalyst_armed():
        return
    _timer += delta
    if _timer >= emit_interval_s:
        _timer = 0.0
        _emit_one()
```

`catalyst_vent#wave_size:3` emits three bodies, then goes quiet — none of them until you have taken the catalyst. The room waits for you before it acts.

Flatten the arrangement onto a wall.

```gdscript
func draw_point(p: Vector3, c: Vector2, half: float, span: float) -> void:
    var x: float = c.x - (p.x / span) * half
    var y: float = c.y - (p.y / span) * half
    draw_line(Vector2(x, y), Vector2(x, c.y), I_AXIS_X, 1.5)
    draw_line(Vector2(x, y), Vector2(c.x, y), I_AXIS_Y, 1.5)
    draw_circle(Vector2(x, y), 7.0, I_DOT)
```

`science_screen#mode:point` drops z and draws what survives: two projections and a dot dragging a trail. The screen is a primitive too — the one that says what the others are doing.

Nothing here is a new primitive. The chamber is what happens once they share a floor.
