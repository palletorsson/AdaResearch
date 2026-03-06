# Tall vertical chamber where a flat grid of springs learns to drape

In Soft Body Deformation, the jelly cube taught that form is negotiated, not given. Eight vertices, twenty-eight springs, a body that wobbles, compresses, and recovers. But the cube is a three-dimensional volume. Compress it from any angle and roughly the same thing happens.

Cloth is different. A two-dimensional surface embedded in three-dimensional space. A flat grid of mass points connected only within the plane, suspended at edges and released into gravity. No depth, no interior diagonals, no volumetric resistance. It folds, crumples, drapes, billows. The same spring-mass substrate produces radically different behavior when topology flattens from volume to membrane.

The tall vertical room exists for one reason: gravity needs distance to do its work. The longer the drape, the more clearly spring configuration reveals itself. A short drop hides differences between spring types. A five-meter cascade amplifies them — structural springs pull the grid taut, shear springs prevent diamond-collapse, bend springs prevent crumpling. Height separates these contributions.

## The Grid: From Volume to Surface

A soft body cube distributes mass points in three dimensions. Cloth distributes them in two — a regular lattice of rows and columns, each intersection holding a mass point identical to the cube's vertices.

```gdscript
var grid_width: int = 16
var grid_height: int = 16
var spacing: float = 0.15
var points: Array = []

func _create_cloth_grid(origin: Vector3) -> void:
    for row in range(grid_height):
        for col in range(grid_width):
            var pos := origin + Vector3(col * spacing, 0.0, row * spacing)
            points.append(MassPoint.new(pos))

func grid_index(row: int, col: int) -> int:
    return row * grid_width + col
```

A 16x16 grid produces 256 mass points. The cube had 8. Same conceptual structure — particles governed by Verlet integration. The difference is topological: which points connect to which, and how. The `grid_index` function maps two-dimensional addresses to flat-array storage, the standard pattern for grid simulation. The grid is a graph before it is a surface. What determines whether it behaves as silk, canvas, or rubber sheet is not the nodes but the edge topology.

## Three Spring Types: Structure, Shear, Bend

The jelly cube introduced structural, shear, and bend springs as three constraint categories at different geometric scales. In cloth, the same three types persist but geometry changes to match the two-dimensional lattice.

**Structural springs** connect each point to its immediate horizontal and vertical neighbors. Every interior point has four structural connections. These springs resist stretching — they hold the cloth's dimensions. Pull the bottom edge and structural springs transmit tension upward through the grid. Without them, the cloth is a cloud of unconnected particles raining down.

```gdscript
func _create_structural_springs(k: float, d: float) -> void:
    for row in range(grid_height):
        for col in range(grid_width):
            var idx := grid_index(row, col)
            # Horizontal neighbor
            if col < grid_width - 1:
                var right := grid_index(row, col + 1)
                springs.append(Spring.new(points[idx], points[right], k, d))
            # Vertical neighbor
            if row < grid_height - 1:
                var down := grid_index(row + 1, col)
                springs.append(Spring.new(points[idx], points[down], k, d))
```

**Shear springs** connect each point to its diagonal neighbors. Four diagonals per interior point. These resist angular deformation. A cloth with only structural springs can skew freely — push the top-right corner and the grid collapses into a parallelogram, every structural spring at rest length while angles fold. Shear springs prevent this, enforcing that row-column angles hold approximately square.

```gdscript
func _create_shear_springs(k: float, d: float) -> void:
    for row in range(grid_height):
        for col in range(grid_width):
            var idx := grid_index(row, col)
            if col < grid_width - 1 and row < grid_height - 1:
                var diag_dr := grid_index(row + 1, col + 1)
                springs.append(Spring.new(points[idx], points[diag_dr], k, d))
                var right := grid_index(row, col + 1)
                var down := grid_index(row + 1, col)
                springs.append(Spring.new(points[right], points[down], k, d))
```

**Bend springs** skip one point, connecting each vertex to the neighbor two steps away. These resist folding. Three consecutive points A, B, C: structural springs connect A-B and B-C. If B drops below line A-C, structural springs stay at rest length while the surface creases sharply. A bend spring from A to C resists this, enforcing curvature smoothness across a wider span. Bend springs produce smooth drapes rather than jagged zigzags.

```gdscript
func _create_bend_springs(k: float, d: float) -> void:
    for row in range(grid_height):
        for col in range(grid_width):
            var idx := grid_index(row, col)
            # Skip-one horizontal
            if col < grid_width - 2:
                var skip_right := grid_index(row, col + 2)
                springs.append(Spring.new(points[idx], points[skip_right], k, d))
            # Skip-one vertical
            if row < grid_height - 2:
                var skip_down := grid_index(row + 2, col)
                springs.append(Spring.new(points[idx], points[skip_down], k, d))
```

The bend rest length is `2 * spacing` — twice the structural rest length. Any folding shortens A-to-C below that, activating the restoring force. Three spring types, three scales of resistance: local stretch, angular shear, regional curvature. The softstopscene artifact demonstrates all three active through Godot's `SoftBody3D`, which encodes these relationships internally via `linear_stiffness` and `simulation_precision`.

## Pinning: Fixed Points and Attachment

A cloth with no fixed points falls as a unit — all 256 points accelerating identically, springs inactive because no relative displacement occurs. Pinning freezes selected points in world space, creating the tension differential that makes draping possible.

```gdscript
func _pin_top_edge() -> void:
    for col in range(grid_width):
        var idx := grid_index(0, col)
        points[idx].is_fixed = true
```

Fix the top row. Gravity pulls unpinned rows downward. Structural springs between row 0 and row 1 stretch. The restoring force pulls row 1 up. Row 2's weight pulls it down. Equilibrium propagates row by row until the cloth hangs in a curve — approximately catenary, shaped by the spring parameters.

The VerletCloth artifact pins two corners through Godot's built-in constraint system:

```gdscript
func _pin_corners(cols: int, rows: int):
    cloth.set_point_pinned(0, true)          # Top-left
    cloth.set_point_pinned(cols - 1, true)   # Top-right
```

Two pins produce the classic hanging-sheet: a U-shape between corners, lowest point set by mass and stiffness. Four pins make a canopy — taut edges, sagging center. One pin makes a cone. No pins and the cloth falls as a unit. Same material, different pins, completely different forms. The integration phase argument distilled: form emerges from the relationship between constraints and environment, not from the material alone.

## Verlet Integration for Cloth

The Verlet scheme from Soft Body Deformation carries forward unchanged:

```gdscript
func integrate(delta: float) -> void:
    for point in points:
        if point.is_fixed:
            continue
        var velocity := point.position - point.old_position
        velocity *= 0.999  # air friction
        point.old_position = point.position
        point.position += velocity + point.acceleration * delta * delta
        point.acceleration = Vector3.ZERO
```

The `0.999` multiplier is global damping — air resistance. Without it, the cloth oscillates indefinitely. With it, oscillation decays over seconds. Too much drag and it moves through honey. Too little and it rings for minutes. Constraint satisfaction follows integration. Cloth needs more iterations than a cube because constraints propagate slowly through hundreds of springs. Five to eight iterations prevent visible stretching at attachment points.

```gdscript
func satisfy_constraints(iterations: int) -> void:
    for i in range(iterations):
        for spring in springs:
            var delta_pos := spring.point_b.position - spring.point_a.position
            var distance := delta_pos.length()
            if distance < 0.0001:
                continue
            var correction := (distance - spring.rest_length) / distance * 0.5
            var offset := delta_pos * correction
            if not spring.point_a.is_fixed:
                spring.point_a.position += offset
            if not spring.point_b.is_fixed:
                spring.point_b.position -= offset
```

If one endpoint is pinned, the entire correction applies to the free endpoint — preserving boundary conditions while enforcing the constraint. Each iteration relaxes the system toward a state where all springs sit at rest length simultaneously, a state geometrically impossible under gravity. That impossibility is precisely why the cloth deforms.

## Collision and Draping

The cloth_straps artifact demonstrates cloth colliding with a rigid frame and thrown projectiles. Collision tests each mass point independently — same principle as soft bodies, 256 points instead of 8.

```gdscript
func resolve_sphere_collision(point: MassPoint, sphere_pos: Vector3,
                               sphere_radius: float) -> void:
    var to_point := point.position - sphere_pos
    var distance := to_point.length()
    if distance < sphere_radius and not point.is_fixed:
        var push_dir := to_point.normalized()
        var penetration := sphere_radius - distance
        point.position += push_dir * penetration
        var normal_vel := push_dir * (point.position - point.old_position).dot(push_dir)
        point.old_position = point.position - normal_vel * 0.3
```

Position correction pushes the point to the sphere's surface. The `old_position` adjustment adds friction — reducing implicit velocity along the collision normal so the cloth wraps and grips rather than sliding off. The `0.3` coefficient governs grip: zero is frictionless, one is total adhesion. Draping over an obstacle is where cloth diverges from volumetric soft bodies. A jelly cube deforms locally at the contact. A cloth sheet redistributes its entire geometry — conforming above, hanging freely below, the transition governed by bend springs. The tall vertical room provides the hanging length needed for full drape development.

A folding cloth can also intersect itself — two regions of the same grid occupying the same space. Without self-collision, the cloth passes through itself silently. The ClothSimulation artifact handles this by checking every node pair:

```gdscript
func check_self_collision(cloth_nodes: Array, min_distance: float) -> void:
    for i in range(cloth_nodes.size()):
        for j in range(i + 1, cloth_nodes.size()):
            var node_a := cloth_nodes[i]
            var node_b := cloth_nodes[j]
            if node_a.is_fixed or node_b.is_fixed:
                continue
            var delta := node_a.position - node_b.position
            var dist := delta.length()
            if dist < min_distance and dist > 0.0001:
                var push := delta.normalized() * (min_distance - dist) * 0.5
                node_a.position += push
                node_b.position -= push
```

This is O(n^2) — 32,640 checks per frame for 256 points. Tractable at this resolution; larger grids need spatial acceleration (hash grids, BVH). The `min_distance` threshold acts as virtual thickness, giving infinitely thin grid points a nonzero radius that prevents interpenetration at the cost of slight stiffening in tight folds. Self-collision is what makes folds stack and produce the layered geometry of real fabric.

## Wind: External Force on a Surface

The flagdancer artifact demonstrates wind through sinusoidal bone displacement. For a mass-point cloth, wind is a per-point force with spatial and temporal variation:

```gdscript
func apply_wind(time: float) -> void:
    for point in points:
        if point.is_fixed:
            continue
        var wind_base := Vector3(2.0, 0.0, 0.5)
        var turbulence := sin(time * 3.0 + point.position.x * 2.0) * 0.8
        var gust := wind_base + Vector3(turbulence, turbulence * 0.3, 0.0)
        point.acceleration += gust / point.mass
```

The `turbulence` term varies spatially — points at different x-positions receive different forces at the same instant, producing rippling rather than uniform billowing. The sine's dependence on both time and position creates a traveling wave across the surface. Real wind-cloth interaction accounts for the angle between wind and the local surface normal, requiring per-frame normal recomputation. The simplified version above applies force regardless of orientation — cheaper and sufficient for teaching.

## Material Character from Spring Ratios

The same 16x16 grid with different spring stiffness ratios produces drastically different fabrics. Three regimes illustrate the continuum:

**Silk**: Low structural stiffness, very low shear, minimal bend resistance. The cloth stretches easily, folds at the slightest perturbation, and drapes in deep, narrow folds. It conforms tightly to obstacles, almost liquid in its willingness to yield.

**Canvas**: High structural, moderate shear and bend. Holds dimensions firmly, drapes in broad gentle curves, forms smooth catenaries rather than sharp creases.

**Rubber sheet**: High everything. Barely drapes — hangs nearly flat, sags minimally under gravity, deflects as a stiff surface under wind.

```gdscript
# Silk
_create_structural_springs(20.0, 0.5)
_create_shear_springs(5.0, 0.2)
_create_bend_springs(1.0, 0.1)

# Canvas
_create_structural_springs(200.0, 2.0)
_create_shear_springs(80.0, 1.0)
_create_bend_springs(40.0, 0.5)

# Rubber sheet
_create_structural_springs(500.0, 5.0)
_create_shear_springs(300.0, 3.0)
_create_bend_springs(200.0, 2.0)
```

The ratios matter more than absolute values. Silk has a structural-to-bend ratio of 20:1. Canvas has 5:1. Rubber has 2.5:1. The higher the ratio, the more the cloth prioritizes holding its length over resisting curvature — more folding, more draping, more flow. The elements are identical. The relations between them define everything.

This maps directly to the QFEP continuum. Stiffness ratios parameterize the cloth's position between rigid order (all springs infinite, the cloth is a rigid plane) and fluid disorder (all springs zero, the cloth dissolves into independent particles). Interesting behavior — draping, folding, billowing — lives in the continuum between extremes, where the system perpetually negotiates between structure and response.

## The Simulation Loop for Cloth

The full cloth frame update:

```gdscript
var gravity := Vector3(0.0, -9.8, 0.0)
var constraint_iterations := 6

func _physics_process(delta: float) -> void:
    # 1. Apply gravity
    for point in points:
        point.acceleration += gravity

    # 2. Apply wind
    apply_wind(time)

    # 3. Apply spring forces (structural, shear, bend)
    for spring in springs:
        spring.apply_force()

    # 4. Verlet integration
    integrate(delta)

    # 5. Constraint satisfaction
    satisfy_constraints(constraint_iterations)

    # 6. Object collision
    for obstacle in obstacles:
        for point in points:
            resolve_sphere_collision(point, obstacle.position, obstacle.radius)

    # 7. Self-collision
    check_self_collision(points, min_distance)

    # 8. Sync visual mesh
    _update_mesh_vertices()

    time += delta
```

Eight steps compared to the soft body's six. Wind and self-collision are the additions unique to surface simulation. The order preserves the same principle: forces first, integration second, constraints third, collisions last. For Godot's `SoftBody3D`, the integration, constraint solving, and mesh synchronization happen internally in compiled C++ rather than interpreted GDScript, yielding the performance needed for real-time cloth at higher resolutions.

## Possible Artifacts

**spring_type_isolator** — Three identical cloth grids, each with different spring types active: structural only, structural plus shear, all three. Structural-only cloth collapses into a diamond. Adding shear restores rectangular integrity but produces sharp folds. Adding bend smooths folds into curves. Toggles let the learner switch in real time, seeing each contribution layer onto the previous.

**material_tuner** — A hanging cloth with three sliders for structural, shear, and bend stiffness. Dragging bend from high to low transforms stiff canvas into flowing silk. A readout shows current stiffness ratios, demonstrating that material character is a function of spring relationships, not individual values.

**pin_configurator** — A cloth grid with clickable attachment points along all edges. Pin and unpin vertices; watch the drape reconfigure. Two corners for a hanging sheet. One edge for a curtain. One center point for a tent. Nothing for free fall. Boundary conditions determine form as much as material properties.

**wind_turbulence_field** — A hanging cloth with adjustable wind. A vector field overlay shows direction and magnitude at each grid point. Sliders control base speed, turbulence frequency, and amplitude. At zero turbulence the cloth deflects uniformly. At high turbulence it ripples and billows.
