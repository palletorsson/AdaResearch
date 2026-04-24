<<<ADA_BUNDLE>>>
sequence: softbodies
file: tutorial.md
maps: 10
skipped_passing: 0
created: 2026-04-24T04:20:00
only_failing: true
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: SoftBodies_Soft_Body_Deformation>>>
# Soft Body Deformation

A cube made of springs. Push it; watch it deform.

Build a mass-spring lattice.

```gdscript
class_name MassSpringCube extends Node3D

var masses: Array = []      # Vector3 positions
var velocities: Array = []
var springs: Array = []     # [idx_a, idx_b, rest_length, stiffness]
@export var size: int = 3

func build() -> void:
    masses.clear()
    velocities.clear()
    for z in size:
        for y in size:
            for x in size:
                masses.append(Vector3(x, y, z) * 0.5)
                velocities.append(Vector3.ZERO)
```

A 3D grid of point masses. Each stores a position and a velocity.

Connect adjacent masses with springs.

```gdscript
func add_springs() -> void:
    springs.clear()
    for z in size:
        for y in size:
            for x in size:
                var i := index_of(x, y, z)
                if x + 1 < size: springs.append([i, index_of(x + 1, y, z), 0.5, 20.0])
                if y + 1 < size: springs.append([i, index_of(x, y + 1, z), 0.5, 20.0])
                if z + 1 < size: springs.append([i, index_of(x, y, z + 1), 0.5, 20.0])

func index_of(x: int, y: int, z: int) -> int:
    return z * size * size + y * size + x
```

Edge springs keep the cube's shape. Rest length matches the grid spacing.

Compute spring forces.

```gdscript
func compute_forces() -> Array:
    var forces: Array = []
    for _i in masses.size(): forces.append(Vector3.ZERO)
    for spring in springs:
        var a: Vector3 = masses[spring[0]]
        var b: Vector3 = masses[spring[1]]
        var direction: Vector3 = b - a
        var current_length: float = direction.length()
        var extension: float = current_length - spring[2]
        var force: Vector3 = direction.normalized() * extension * spring[3]
        forces[spring[0]] += force
        forces[spring[1]] -= force
    return forces
```

Each spring pulls its endpoints toward its rest length. Equal and opposite forces on the two ends.

Integrate.

```gdscript
@export var damping: float = 0.5

func _physics_process(delta: float) -> void:
    var forces := compute_forces()
    for i in masses.size():
        velocities[i] += forces[i] * delta
        velocities[i] *= (1.0 - damping * delta)
        masses[i] += velocities[i] * delta
```

Euler integration with velocity damping. Damping prevents unbounded oscillation.

Apply an external push.

```gdscript
func apply_push(push_position: Vector3, force: Vector3, radius: float = 0.5) -> void:
    for i in masses.size():
        var distance: float = masses[i].distance_to(push_position)
        if distance < radius:
            var falloff: float = 1.0 - distance / radius
            velocities[i] += force * falloff
```

Nearby masses take more force. The push produces a travelling wave through the lattice.

Rebuild the mesh each frame.

```gdscript
func rebuild_mesh() -> void:
    var mesh := ArrayMesh.new()
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    for face in cube_faces():
        for vi in face:
            st.add_vertex(masses[vi])
    st.generate_normals()
    mesh_instance.mesh = st.commit()
```

The visible cube follows the masses. Deformation is visible as warping of the mesh.

You can now build a mass-spring lattice, compute forces, integrate, apply pushes, and rebuild the visual mesh. SoftBodies_Carusell extends into rotating soft bodies.

<<<MAP: SoftBodies_Carusell>>>
# Soft Bodies Carousel

Rotating platform with soft cubes. Centrifugal deformation.

Build a rotating platform.

```gdscript
class_name SoftCarousel extends Node3D

@export var rotation_speed: float = 1.0

func _physics_process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

Constant angular velocity. Soft bodies on the platform experience centrifugal acceleration.

Spawn soft cubes on the platform.

```gdscript
func spawn_soft_cube_at(position: Vector3) -> Node3D:
    var cube := preload("res://commons/softbodies/mass_spring_cube.tscn").instantiate()
    cube.position = position
    add_child(cube)
    return cube
```

Each cube is an independent mass-spring lattice. Multiple cubes populate the carousel.

Apply centrifugal force.

```gdscript
func apply_centrifugal(cube: MassSpringCube, angular_velocity: float) -> void:
    for i in cube.masses.size():
        var world_pos: Vector3 = cube.to_global(cube.masses[i])
        var radial: Vector3 = world_pos - global_position
        radial.y = 0
        var centrifugal: Vector3 = radial.normalized() * radial.length() * angular_velocity * angular_velocity
        cube.velocities[i] += cube.to_local(centrifugal) * get_physics_process_delta_time()
```

Outward force proportional to radial distance and angular velocity squared. Cubes deform outward.

Vary distances.

```gdscript
func populate_rings() -> void:
    const RADII := [0.8, 1.5, 2.2]
    const COUNT_PER_RING := [4, 6, 8]
    for ring_idx in 3:
        for i in COUNT_PER_RING[ring_idx]:
            var angle: float = i * TAU / COUNT_PER_RING[ring_idx]
            var position := Vector3(cos(angle) * RADII[ring_idx], 0, sin(angle) * RADII[ring_idx])
            spawn_soft_cube_at(position)
```

Three rings. Outer cubes deform more than inner ones. Visible gradient of stretch.

Stabilise corner cubes.

```gdscript
func pin_corners() -> void:
    for cube in get_children():
        if cube is MassSpringCube:
            cube.pinned_indices = [0, cube.size - 1, cube.size * cube.size - 1]
```

Pinning prevents a mass from moving. Anchors the cube's base to the platform surface.

Skip update for pinned masses.

```gdscript
var pinned_indices: Array = []

func _physics_process(delta: float) -> void:
    super(delta)
    for i in pinned_indices:
        masses[i] = initial_masses[i]
        velocities[i] = Vector3.ZERO
```

After integration, reset pinned masses to their starting positions. Zero their velocities.

You can now build a rotating platform, apply centrifugal force to soft bodies, populate rings at different radii, and pin corner vertices. SoftBodies_Obsticals extends into collision with static obstacles.

<<<MAP: SoftBodies_Obsticals>>>
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

<<<MAP: SoftBodies_Obsticals_Part2>>>
# Soft Bodies Obstacles Part 2

Moving obstacles. The soft body absorbs the motion.

Spawn a moving piston.

```gdscript
class_name Piston extends StaticBody3D

@export var movement_range: Vector3 = Vector3(0, 0, 2)
@export var period: float = 2.0

var start_position: Vector3

func _ready() -> void:
    start_position = global_position

func _physics_process(delta: float) -> void:
    var t: float = fmod(Time.get_ticks_msec() / 1000.0, period) / period
    var phase: float = sin(t * TAU)
    global_position = start_position + movement_range * phase
```

Sinusoidal back-and-forth motion. The piston pushes the soft body on its forward stroke.

Compute piston velocity.

```gdscript
var previous_position: Vector3

func _physics_process(delta: float) -> void:
    super(delta)
    linear_velocity = (global_position - previous_position) / delta
    previous_position = global_position
```

Finite difference. The velocity is used to drive the soft body's response.

Apply piston velocity to the soft body.

```gdscript
func apply_piston(cube: MassSpringCube, piston: Piston) -> void:
    for i in cube.masses.size():
        var mass_world: Vector3 = cube.to_global(cube.masses[i])
        var correction: Vector3 = penetration_at(mass_world, piston)
        if correction.length() > 0.01:
            cube.masses[i] += cube.to_local(correction)
            cube.velocities[i] += cube.to_local(piston.linear_velocity)
```

The soft body mass inherits the piston's velocity. Energy transfers from rigid to soft.

Spawn a rotating spoke.

```gdscript
class_name Spoke extends StaticBody3D

@export var rotation_speed: float = 3.0

func _physics_process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

Angular rotation; combined with a collision shape, the spoke sweeps through the soft body.

Moving-collision-shape damage.

```gdscript
func apply_moving_shape(cube: MassSpringCube, shape_node: Node3D, shape_velocity: Vector3) -> void:
    for i in cube.masses.size():
        var mass_world: Vector3 = cube.to_global(cube.masses[i])
        var correction: Vector3 = penetration_at(mass_world, shape_node)
        if correction.length() > 0.01:
            cube.masses[i] += cube.to_local(correction)
            cube.velocities[i] += cube.to_local(shape_velocity * 0.5)
```

Scaled velocity inheritance (half the shape's velocity transfers). Softer than full transfer; avoids runaway acceleration.

Log impact events.

```gdscript
func log_impact(cube: MassSpringCube, point: Vector3, force: Vector3) -> void:
    impact_log.append({
        "time": Time.get_ticks_msec() / 1000.0,
        "position": point,
        "force_magnitude": force.length(),
    })
```

Timestamped impact records. Later analysis shows where and when forces hit.

You can now spawn moving pistons and rotating spokes, compute their velocities, apply them to soft bodies for velocity transfer, and log impact events. SoftBodies_Cloth_Physics extends into cloth simulation.

<<<MAP: SoftBodies_Cloth_Physics>>>
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

<<<MAP: SoftBodies_Playground_of_Joy>>>
# Playground of Joy

Interactive soft bodies. Throw, catch, mash.

Spawn a throwable soft sphere.

```gdscript
class_name SoftBall extends Node3D

@export var radius: float = 0.5
@export var segment_count: int = 16

func build() -> void:
    # Build a spherical mass-spring mesh
    for i in segment_count:
        var theta: float = i * PI / (segment_count - 1)
        for j in segment_count * 2:
            var phi: float = j * TAU / (segment_count * 2)
            var p := Vector3(
                radius * sin(theta) * cos(phi),
                radius * cos(theta),
                radius * sin(theta) * sin(phi)
            )
            spawn_mass_at(p)
```

Spherical parameterisation. Masses cover the surface of a sphere.

Make it grabbable.

```gdscript
func make_grabbable() -> void:
    add_to_group("grabbable")
    var grab_area := Area3D.new()
    var shape := CollisionShape3D.new()
    var s := SphereShape3D.new()
    s.radius = radius
    shape.shape = s
    grab_area.add_child(shape)
    add_child(grab_area)
```

Standard VR grab pattern. The learner's controller triggers the area.

Apply a grab as force to each mass.

```gdscript
func apply_grab_force(grab_position: Vector3, grab_strength: float = 5.0) -> void:
    for i in masses.size():
        var to_grab: Vector3 = grab_position - masses[i]
        velocities[i] += to_grab * grab_strength * get_physics_process_delta_time()
```

Each mass is pulled toward the grab point. Strong force deforms the ball into a bag shape.

Detect a release.

```gdscript
var was_grabbed: bool = false
var release_velocity: Vector3

func _on_grab_released(controller: XRController3D) -> void:
    if was_grabbed:
        release_velocity = controller.velocity
        was_grabbed = false
        apply_throw(release_velocity)
```

Capture the controller's velocity at release. The ball inherits it.

Apply a throw.

```gdscript
func apply_throw(initial_velocity: Vector3) -> void:
    for i in velocities.size():
        velocities[i] += initial_velocity
```

Add the velocity to every mass. The whole ball travels as a unit, then deformation propagates.

Spawn a soft floor mat.

```gdscript
class_name SoftMat extends MassSpringCube

func _ready() -> void:
    super()
    pinned_indices = get_bottom_layer_indices()

func get_bottom_layer_indices() -> Array:
    var indices: Array = []
    for x in size:
        for z in size:
            indices.append(index_of(x, 0, z))
    return indices
```

Bottom layer pinned to the floor. Balls land softly.

Detect bounce height.

```gdscript
var last_y: float = 0.0

func _process(_delta: float) -> void:
    var centroid_y: float = compute_centroid().y
    if centroid_y > last_y + 0.5:
        record_bounce(centroid_y)
    last_y = centroid_y
```

Record the height of each bounce. Useful for scoring or visual feedback.

You can now build a soft ball, make it grabbable, throw it, spawn a soft mat, and detect bounces. SoftBodies_Affect_Theory_Visualization extends into biological soft-body form.

<<<MAP: SoftBodies_Affect_Theory_Visualization>>>
# Affect Theory Visualization

A radiolarian. Soft cell with rigid silica skeleton.

Build a Voronoi sphere.

```gdscript
class_name Radiolarian extends Node3D

@export var seed_count: int = 60
@export var radius: float = 1.0

func generate_seeds() -> Array:
    var seeds: Array = []
    for _i in seed_count:
        var theta: float = acos(2.0 * randf() - 1.0)  # uniform over sphere
        var phi: float = randf() * TAU
        var p := Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)) * radius
        seeds.append(p)
    return seeds
```

Uniform distribution on the sphere's surface. Each seed becomes a Voronoi cell.

Compute Voronoi neighbours.

```gdscript
func voronoi_neighbours(seeds: Array) -> Array:
    var adjacency: Array = []
    for i in seeds.size():
        adjacency.append([])
    for i in seeds.size():
        for j in range(i + 1, seeds.size()):
            if are_voronoi_neighbours(seeds, i, j):
                adjacency[i].append(j)
                adjacency[j].append(i)
    return adjacency
```

Two cells are neighbours if they share a boundary. For spheres, this is roughly proximity-based.

Approximate Voronoi adjacency.

```gdscript
func are_voronoi_neighbours(seeds: Array, i: int, j: int) -> bool:
    var midpoint: Vector3 = (seeds[i] + seeds[j]) / 2.0
    for k in seeds.size():
        if k == i or k == j: continue
        if seeds[k].distance_to(midpoint) < seeds[i].distance_to(midpoint):
            return false
    return true
```

The midpoint test: two seeds are neighbours iff no third seed is closer to their midpoint. Fast approximation; not exact for non-convex cells.

Build the silica skeleton.

```gdscript
func build_skeleton(seeds: Array, adjacency: Array) -> void:
    for i in seeds.size():
        spawn_node_at(seeds[i])
        for j in adjacency[i]:
            if j > i:
                spawn_strut_between(seeds[i], seeds[j])
```

Nodes at seed positions; struts between neighbours. The skeleton is a wireframe.

Add the soft protoplasm.

```gdscript
func add_protoplasm() -> void:
    var sphere := MeshInstance3D.new()
    sphere.mesh = SphereMesh.new()
    sphere.mesh.radius = radius * 0.95
    var mat := StandardMaterial3D.new()
    mat.albedo_color = Color(0.8, 0.6, 0.9, 0.4)
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    sphere.material_override = mat
    add_child(sphere)
```

Semi-transparent sphere inside the skeleton. The soft living matter visible through the rigid structure.

Animate growth.

```gdscript
var current_radius: float = 0.0
@export var grow_rate: float = 0.2

func _process(delta: float) -> void:
    current_radius = min(radius, current_radius + grow_rate * delta)
    update_skeleton_scale(current_radius / radius)
```

The radiolarian grows over time. Skeleton struts extend; protoplasm fills the interior.

Show Haeckel's illustration reference.

```gdscript
func display_haeckel_reference() -> void:
    var image := preload("res://commons/softbodies/haeckel_radiolaria.jpg")
    var quad := QuadMesh.new()
    var mat := StandardMaterial3D.new()
    mat.albedo_texture = image
    quad.size = Vector2(2, 2)
    mesh_instance.mesh = quad
    mesh_instance.material_override = mat
```

Historical illustration as a reference panel. The procedural form is a reinterpretation of Haeckel's 19th-century drawing.

You can now build a radiolarian with Voronoi-partitioned silica skeleton, soft protoplasm, animated growth, and a Haeckel reference panel. Topology_Entropy_Morphogenesis extends into morphogenetic algorithms.

<<<MAP: Topology_Entropy_Morphogenesis>>>
# Topology Entropy Morphogenesis

Form from flow. Turing patterns, reaction-diffusion, metaballs.

Run Gray-Scott reaction-diffusion.

```gdscript
class_name GrayScott extends Node3D

@export var grid_size: Vector2i = Vector2i(128, 128)
@export var feed: float = 0.055
@export var kill: float = 0.062
@export var du: float = 1.0
@export var dv: float = 0.5

var U: Array = []  # activator
var V: Array = []  # inhibitor

func initialise() -> void:
    U.clear(); V.clear()
    for y in grid_size.y:
        var u_row: Array = []
        var v_row: Array = []
        for x in grid_size.x:
            u_row.append(1.0)
            v_row.append(0.0)
        U.append(u_row); V.append(v_row)
    # Seed a small region
    for dy in 5:
        for dx in 5:
            V[grid_size.y / 2 + dy][grid_size.x / 2 + dx] = 1.0
```

Two coupled concentrations. U is high everywhere; V is seeded in a small region.

Compute the Laplacian.

```gdscript
func laplacian(grid: Array, x: int, y: int) -> float:
    var w := grid_size.x; var h := grid_size.y
    return (
        grid[(y - 1 + h) % h][x] +
        grid[(y + 1) % h][x] +
        grid[y][(x - 1 + w) % w] +
        grid[y][(x + 1) % w] -
        4.0 * grid[y][x]
    )
```

Five-point stencil with periodic boundaries. Wrapping prevents edge artifacts.

Step once.

```gdscript
@export var dt: float = 1.0

func step() -> void:
    var new_U: Array = []
    var new_V: Array = []
    for y in grid_size.y:
        new_U.append([]); new_V.append([])
        for x in grid_size.x:
            var u := U[y][x]; var v := V[y][x]
            var uvv := u * v * v
            new_U[y].append(u + dt * (du * laplacian(U, x, y) - uvv + feed * (1.0 - u)))
            new_V[y].append(v + dt * (dv * laplacian(V, x, y) + uvv - (feed + kill) * v))
    U = new_U; V = new_V
```

Gray-Scott update. Different feed/kill combinations produce spots, stripes, labyrinths.

Render as a texture.

```gdscript
func render_to_texture() -> ImageTexture:
    var image := Image.create(grid_size.x, grid_size.y, false, Image.FORMAT_RGBA8)
    for y in grid_size.y:
        for x in grid_size.x:
            var intensity: float = V[y][x]
            image.set_pixel(x, y, Color(intensity, intensity * 0.5, intensity * 0.8, 1.0))
    return ImageTexture.create_from_image(image)
```

Purple intensity tracks V. Patterns emerge over thousands of steps.

Metaball rendering.

```gdscript
func metaball_value_at(p: Vector3, centres: Array, radii: Array) -> float:
    var total: float = 0.0
    for i in centres.size():
        var distance: float = p.distance_to(centres[i])
        if distance > radii[i] * 2: continue
        total += radii[i] * radii[i] / (distance * distance + 0.001)
    return total
```

Sum of inverse-square contributions from all metaballs. Surface at a threshold level.

Extract iso-surface via marching cubes.

```gdscript
func marching_cubes_surface(field_func: Callable, threshold: float, resolution: int) -> ArrayMesh:
    var st := SurfaceTool.new()
    st.begin(Mesh.PRIMITIVE_TRIANGLES)
    # ... full MC lookup tables, omitted for brevity
    # For each 2x2x2 voxel, determine which vertices/edges produce the surface
    return st.commit()
```

Standard marching cubes. Voxel grid samples the scalar field; the 256-case lookup determines triangles.

You can now run Gray-Scott reaction-diffusion, render it as a texture, sample a metaball field, and extract the iso-surface via marching cubes. Chamber_SoftBodies closes the sequence with push-as-interaction.

<<<MAP: Chamber_SoftBodies>>>
# Chamber SoftBodies

Push the spring_hopper directly. No catalyst, just contact.

Build the spring hopper.

```gdscript
class_name SpringHopper extends MassSpringCube

@export var hop_strength: float = 3.0

func _ready() -> void:
    size = 4
    super()
    add_periodic_hop()

func add_periodic_hop() -> void:
    var timer := Timer.new()
    timer.wait_time = 2.0
    timer.timeout.connect(periodic_bounce)
    add_child(timer)
    timer.start()
```

A small mass-spring lattice that bounces periodically. The hopping is part of the creature's life.

Apply a bounce.

```gdscript
func periodic_bounce() -> void:
    for i in velocities.size():
        velocities[i] += Vector3.UP * hop_strength + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
```

Every two seconds, add upward velocity with a small horizontal scatter. The hopper bounces around.

Render the deformation field.

```gdscript
func compute_displacement_field() -> Array:
    var field: Array = []
    for i in masses.size():
        var rest_position := compute_rest_position(i)
        field.append(masses[i] - rest_position)
    return field
```

Each mass's displacement from its rest position. The field shows where and how the body is deformed.

Visualise the field as arrows.

```gdscript
func render_displacement_field(field: Array) -> void:
    for i in field.size():
        if field[i].length() > 0.05:
            spawn_arrow(masses[i], field[i])
```

One arrow per deformed mass. The arrows together show the deformation wave traveling through the body.

Track energy over time.

```gdscript
var energy_history: Array = []

func compute_total_energy() -> float:
    var kinetic: float = 0.0
    for v in velocities:
        kinetic += 0.5 * v.length_squared()
    var potential: float = 0.0
    for spring in springs:
        var delta: Vector3 = masses[spring[1]] - masses[spring[0]]
        var extension: float = delta.length() - spring[2]
        potential += 0.5 * spring[3] * extension * extension
    return kinetic + potential

func log_energy() -> void:
    energy_history.append(compute_total_energy())
```

Sum of kinetic plus spring potential energies. Without external input, energy decays.

Detect a push from the learner.

```gdscript
func detect_learner_push(learner: Node3D, threshold: float = 1.0) -> Vector3:
    var learner_velocity: Vector3 = learner.get("velocity") or Vector3.ZERO
    if learner_velocity.length() > threshold:
        return learner_velocity
    return Vector3.ZERO
```

Check the learner's velocity. If fast enough, treat as a push.

Propagate the push.

```gdscript
func _physics_process(delta: float) -> void:
    super(delta)
    var learner_push: Vector3 = detect_learner_push(learner)
    if learner_push.length() > 0:
        var contact_point: Vector3 = learner.global_position
        apply_push(contact_point, learner_push, 0.8)
```

Each push adds velocity to nearby masses. The wave propagates through the lattice as deformation.

You can now build a spring_hopper with periodic bouncing, compute and visualise the displacement field, track total energy, and propagate learner pushes through the lattice. The Soft Bodies sequence closes with contact as distributed wave.
