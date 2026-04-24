# Vector Applied

Vectors aim turrets. Vectors drive weather. Vectors fill space with instructions.

Point a turret at a target.

```gdscript
func aim_at_target(turret: Node3D, target_position: Vector3) -> void:
    var to_target: Vector3 = target_position - turret.global_position
    turret.look_at(target_position, Vector3.UP)
    turret.rotate_object_local(Vector3.UP, PI)  # compensate for -Z forward
```

`look_at` handles the rotation. The compensation accounts for Godot's convention that forward is -Z.

Test whether the turret can fire.

```gdscript
func can_fire(turret: Node3D, target: Vector3, cone_degrees: float = 5.0) -> bool:
    var forward: Vector3 = -turret.global_transform.basis.z
    var to_target: Vector3 = (target - turret.global_position).normalized()
    var cos_cone: float = cos(deg_to_rad(cone_degrees))
    return forward.dot(to_target) > cos_cone
```

Fire when the forward direction is within the cone angle of the target. 5 degrees is a reasonable tolerance.

Sample a weather vector field.

```gdscript
func weather_at(p: Vector3) -> Vector3:
    var gravity := Vector3.DOWN * 2.0
    var wind := Vector3(1, 0, 0) * sin(Time.get_ticks_msec() / 1000.0)
    var turbulence := random_noise_vector(p) * 0.5
    return gravity + wind + turbulence
```

Three fields superposed. Particles released into the field ride the summed flow.

Release a particle.

```gdscript
func spawn_particle_at(p: Vector3) -> RigidBody3D:
    var particle := RigidBody3D.new()
    particle.mass = 0.1
    particle.global_position = p
    add_child(particle)
    return particle
```

Low-mass body so environmental forces dominate. Godot's physics integrator handles the rest.

Apply the field force.

```gdscript
func _physics_process(_delta: float) -> void:
    for particle in get_tree().get_nodes_in_group("weather_particles"):
        particle.apply_central_force(weather_at(particle.global_position))
```

Every frame, each particle samples the field at its current position and applies the resulting force. Motion emerges from the field.

Populate a field visualiser grid.

```gdscript
func populate_arrow_grid(resolution: int = 8) -> void:
    for ix in resolution:
        for iy in resolution:
            for iz in resolution:
                var p := Vector3(ix, iy, iz) - Vector3.ONE * resolution / 2
                spawn_arrow_at(p, weather_at(p))
```

A 3D grid of arrows shows the field at discrete samples. Each arrow's direction is the local field direction.

Switch between field types.

```gdscript
enum FieldType { GRAVITATIONAL, ELECTRIC, MAGNETIC }

func sample(p: Vector3, field_type: FieldType) -> Vector3:
    match field_type:
        FieldType.GRAVITATIONAL: return Vector3.DOWN * 9.81
        FieldType.ELECTRIC: return (p - source_charge_position).normalized() / p.distance_squared_to(source_charge_position)
        FieldType.MAGNETIC: return p.cross(Vector3.UP)
    return Vector3.ZERO
```

Each field type has a different spatial signature. Gravitational is uniform; electric falls off with distance squared; magnetic rotates around an axis.

You can now aim a turret, simulate weather as a superposed field, and render any field as a grid of arrows. VectorAdvanced will next turn vectors into embodied action.
