# Soft Bodies Obstacles

Soft body collides with a rigid obstacle. Response is elastic.

Detect penetration.

```gdscript
func penetration_at(mass: Vector3, obstacle: Node3D) -> Vector3:
    var obstacle_local: Vector3 = obstacle.to_local(mass)
    var shape: CollisionShape3D = obstacle.get_node("CollisionShape3D")
    if shape.shape is SphereShape3D:
        var radius: float = shape.shape.radius
        if obstacle_local.length() < radius:
            return obstacle_local.normalized() * (radius - obstacle_local.length())
    return Vector3.ZERO
```

Returns the correction vector needed to push the mass outside the obstacle. Zero if no penetration.

Apply collision response.

```gdscript
func apply_collision(cube: MassSpringCube, obstacle: Node3D) -> void:
    for i in cube.masses.size():
        var mass_world: Vector3 = cube.to_global(cube.masses[i])
        var correction: Vector3 = penetration_at(mass_world, obstacle)
        if correction.length() > 0.01:
            cube.masses[i] += cube.to_local(correction)
            var normal: Vector3 = correction.normalized()
            var velocity_component: float = cube.velocities[i].dot(normal)
            if velocity_component < 0:
                cube.velocities[i] -= normal * velocity_component * 1.8  # elastic rebound
```

Push the mass out of the obstacle; reflect the inward velocity component. Coefficient 1.8 produces slightly elastic rebound.

Spawn a sphere obstacle.

```gdscript
func spawn_sphere_obstacle(position: Vector3, radius: float) -> StaticBody3D:
    var obstacle := StaticBody3D.new()
    var mesh := MeshInstance3D.new()
    mesh.mesh = SphereMesh.new()
    mesh.mesh.radius = radius
    obstacle.add_child(mesh)
    var shape := CollisionShape3D.new()
    var s := SphereShape3D.new()
    s.radius = radius
    shape.shape = s
    obstacle.add_child(shape)
    obstacle.global_position = position
    add_child(obstacle)
    return obstacle
```

Standard static body with a sphere collision shape. The obstacle cannot move.

Spawn a plane obstacle.

```gdscript
func spawn_plane_obstacle(y: float) -> StaticBody3D:
    var obstacle := StaticBody3D.new()
    var shape := CollisionShape3D.new()
    shape.shape = WorldBoundaryShape3D.new()  # infinite plane
    obstacle.add_child(shape)
    obstacle.global_position = Vector3(0, y, 0)
    add_child(obstacle)
    return obstacle
```

Infinite floor. Any mass below y is pushed up.

Detect plane penetration.

```gdscript
func plane_penetration(mass: Vector3, plane_y: float) -> Vector3:
    if mass.y < plane_y:
        return Vector3(0, plane_y - mass.y, 0)
    return Vector3.ZERO
```

Single axis comparison. Correction is purely vertical.

Apply friction on sliding contacts.

```gdscript
func apply_friction(cube: MassSpringCube, friction: float = 0.3) -> void:
    for i in cube.masses.size():
        if cube.masses[i].y < 0.01:  # touching floor
            var horizontal := Vector3(cube.velocities[i].x, 0, cube.velocities[i].z)
            cube.velocities[i] -= horizontal * friction
```

Reduce horizontal velocity for masses in contact. Produces slowing as the cube slides.

You can now detect penetration, apply elastic rebound, spawn sphere and plane obstacles, and apply friction on ground contact. SoftBodies_Obsticals_Part2 extends with moving obstacles.

Emergency stop the simulation.

```gdscript
var paused: bool = false

func toggle_pause() -> void:
    paused = not paused

func _physics_process(delta: float) -> void:
    if paused: return
    super(delta)
```

Lets the learner freeze the scene to examine a moment. Useful for studying specific deformation states.
