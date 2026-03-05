# Bouncy room with elevated platforms where a cube learns to yield

In Forces we applied F=ma to rigid objects — balls that bounced but never deformed. The sphere fell, hit the ground, reversed its velocity, and rose again with the same shape it started with. Every collision was a negotiation of speed, never of form. The objects were actors that could move through space but could not change themselves.

Now the objects themselves yield.

A soft body is a collection of mass points connected by springs. The vertices of a mesh become particles with position and velocity. The edges become elastic constraints — springs that pull neighboring particles toward their rest distance. Drop the mesh, and gravity acts on every particle independently. The springs resist, stretch, compress, propagate forces through the topology. The shape deforms. It lands on a platform, flattens under its own weight, then recovers — partially, imperfectly — as the springs haul the vertices back toward their remembered positions. Form is not a given property. It is a dynamic equilibrium between external forces and internal constraints.

The jelly cube is this idea made visible. Eight vertices, twelve edges, internal diagonals — a cube-shaped spring-mass system that wobbles, compresses, and oscillates when disturbed. The bouncy room provides the test environment: a flat arena with elevated platforms to drop from, collide against, and slide across.

## Mass Points: Vertices as Particles

Every vertex of the cube becomes a particle with mass, position, and velocity. No mesh renderer decides where the vertex sits — the physics simulation does.

```gdscript
class MassPoint:
    var position: Vector3
    var old_position: Vector3
    var acceleration: Vector3
    var mass: float

    func _init(pos: Vector3, m: float = 1.0) -> void:
        position = pos
        old_position = pos
        acceleration = Vector3.ZERO
        mass = m
```

Two positions — current and previous. This is the signature of Verlet integration, which stores velocity implicitly as the difference between frames rather than as an explicit variable. More on that shortly. The `acceleration` accumulator works the same way as in Forces: forces are applied each frame, converted to acceleration via F/m, then cleared.

A cube has eight vertices. Construct them at the corners of a unit cube:

```gdscript
var points: Array[MassPoint] = []
var cube_size := 1.0
var half := cube_size / 2.0

func _create_mass_points() -> void:
    for x in [-half, half]:
        for y in [-half, half]:
            for z in [-half, half]:
                points.append(MassPoint.new(Vector3(x, y, z)))
```

Eight particles. No connections yet. Drop them and they fall independently — eight separate objects obeying gravity, unaware of each other. The cube dissolves instantly. Structure requires springs.

## Springs as Edges: Hooke's Law

A spring connects two mass points and applies a restoring force proportional to the displacement from rest length. This is Hooke's law:

```
F = -k * (|d| - rest_length) * d_hat
```

`k` is the spring constant — stiffness. `d` is the vector from one point to the other. `|d|` is the current distance. `rest_length` is the distance at which the spring is relaxed. `d_hat` is the unit direction. The force pulls the points together when stretched, pushes them apart when compressed. The negative sign ensures the force opposes the displacement.

```gdscript
class Spring:
    var point_a: MassPoint
    var point_b: MassPoint
    var rest_length: float
    var stiffness: float
    var damping: float

    func _init(a: MassPoint, b: MassPoint, k: float, d: float) -> void:
        point_a = a
        point_b = b
        rest_length = a.position.distance_to(b.position)
        stiffness = k
        damping = d

    func apply_force() -> void:
        var delta := point_b.position - point_a.position
        var distance := delta.length()
        if distance < 0.0001:
            return  # avoid division by zero
        var direction := delta / distance
        var stretch := distance - rest_length

        # Hooke's law: restoring force
        var force := direction * stretch * stiffness

        # Damping: resist velocity along the spring axis
        var relative_vel := point_b.get_velocity() - point_a.get_velocity()
        var damping_force := direction * relative_vel.dot(direction) * damping

        var total := force + damping_force
        point_a.acceleration += total / point_a.mass
        point_b.acceleration -= total / point_b.mass
```

The damping term deserves attention. Without it, the spring oscillates forever — energy transfers back and forth between kinetic and potential with no loss. The damping force opposes the relative velocity along the spring axis. It is a viscous drag that converts kinetic energy to heat (or rather, discards it from the simulation). The `dot(direction)` projection ensures damping only acts along the spring direction — lateral motion is unaffected. This prevents the damping from freezing the system into an artificial stillness.

The `stiffness` parameter controls how aggressively the spring resists deformation. High k — the spring snaps back instantly, the cube feels rigid. Low k — the spring allows large displacement, the cube sags and wobbles. The `damping` parameter controls how quickly oscillations decay. High damping — the cube deforms and settles. Low damping — the cube rings like a bell.

## Mesh Topology: Structural, Shear, and Bend Springs

Twelve edges define a cube. Connecting only those edges produces structural springs — they resist stretching along each face. But a cube wired with structural springs alone has no resistance to shearing. Push the top face sideways and the whole structure collapses into a parallelogram. The edges stay at rest length while the angles between them fold freely.

Three types of spring solve this:

**Structural springs** connect adjacent vertices along cube edges. Twelve springs. They maintain edge lengths.

**Shear springs** connect diagonal vertices across each face. Twelve springs (two diagonals per face, six faces). They resist angular deformation — preventing the diamond-collapse problem.

**Bend springs** connect vertices diagonally through the cube's interior — opposite corners. Four springs. They resist volumetric compression and give the cube its deep stiffness.

```gdscript
func _create_springs(k_struct: float, k_shear: float, k_bend: float,
                     damp: float) -> void:
    var n := points.size()
    for i in range(n):
        for j in range(i + 1, n):
            var dist := points[i].position.distance_to(points[j].position)
            if abs(dist - cube_size) < 0.01:
                # Edge-length apart: structural
                springs.append(Spring.new(points[i], points[j], k_struct, damp))
            elif abs(dist - cube_size * sqrt(2.0)) < 0.01:
                # Face diagonal: shear
                springs.append(Spring.new(points[i], points[j], k_shear, damp))
            elif abs(dist - cube_size * sqrt(3.0)) < 0.01:
                # Space diagonal: bend
                springs.append(Spring.new(points[i], points[j], k_bend, damp))
```

The distances reveal the topology. Edge length is `cube_size`. Face diagonal is `cube_size * sqrt(2)`. Space diagonal is `cube_size * sqrt(3)`. Each threshold maps a geometric relationship to a spring type. Twelve structural, twelve shear, four bend — twenty-eight springs total. The cube is now a graph: vertices are nodes, springs are weighted edges. The graph's connectivity determines the body's material properties.

Different stiffness values per type let the material feel directionally distinct. Structural springs stiff, shear springs softer, bend springs somewhere between — the cube holds its edges firmly but allows some angular give. Reverse the ratios and the material feels rubbery along edges but resists volumetric change. The topology is fixed. The material character is in the constants.

## Verlet Integration: Why Not Euler

In Forces, Euler integration was sufficient. One object, one force, predictable trajectories. But spring-mass systems expose Euler's weakness: energy drift.

Euler integration computes velocity explicitly and updates position from it:

```gdscript
velocity += acceleration * delta
position += velocity * delta
```

Each step introduces a small error. For a single falling object, this error accumulates slowly and the trajectory remains plausible. For a network of springs pulling against each other, the errors compound. Springs overshoot their rest length, which increases the restoring force, which causes a larger overshoot next frame. The system gains energy from nowhere. The cube explodes.

Verlet integration avoids storing velocity altogether. Instead, it derives velocity from the difference between the current and previous position:

```gdscript
func integrate(delta: float) -> void:
    for point in points:
        var velocity := point.position - point.old_position
        point.old_position = point.position
        point.position += velocity + point.acceleration * delta * delta
        point.acceleration = Vector3.ZERO
```

The update `position += velocity + acceleration * dt^2` is symplectic — it conserves energy over long simulations rather than accumulating drift. The velocity term `position - old_position` is implicit. No velocity variable to go wrong. The acceleration term uses `delta * delta` rather than just `delta` because it is applied directly to position (second integral) rather than to velocity (first integral).

Verlet has a secondary advantage: constraints are trivial to enforce. After integration, iterate over all springs and directly correct any point that has drifted too far from its neighbor. This position-based correction is natural in Verlet and awkward in Euler, where you would need to back-compute the velocity adjustment. Constraint satisfaction is what makes the soft body hold together.

```gdscript
func satisfy_constraints(iterations: int) -> void:
    for i in range(iterations):
        for spring in springs:
            var delta := spring.point_b.position - spring.point_a.position
            var distance := delta.length()
            if distance < 0.0001:
                continue
            var correction := (distance - spring.rest_length) / distance * 0.5
            var offset := delta * correction
            spring.point_a.position += offset
            spring.point_b.position -= offset
```

Each iteration moves both endpoints halfway toward the rest length. Multiple iterations per frame improve accuracy — three to five is typical for a jelly cube. The correction is symmetric: both points share the error equally, preserving the center of mass. This is Jakobsen-style constraint relaxation, and it works precisely because Verlet stores position as the primary quantity.

## Collision Against Rigid Planes

The bouncy room has a floor. The elevated platforms are rigid surfaces. Collision detection for a soft body means testing every mass point against every plane — not just the bounding box of the mesh.

```gdscript
func resolve_collisions(floor_y: float, restitution: float) -> void:
    for point in points:
        if point.position.y < floor_y:
            point.position.y = floor_y
            # Reflect the implicit velocity via old_position
            var depth := floor_y - point.old_position.y
            point.old_position.y = floor_y + depth * restitution
```

In Verlet, velocity is `position - old_position`. To reflect velocity on collision, manipulate `old_position`. Placing `old_position` above the floor by `depth * restitution` means the implicit velocity on the next frame will point upward with reduced magnitude. The restitution coefficient governs how much bounce survives — identical in function to the Forces map, but implemented through position history rather than explicit velocity reversal.

The cube doesn't collide as a single object. Each of its eight vertices collides independently. When the bottom four vertices hit the floor, they stop. The top four continue downward, compressing the structural and shear springs. The cube flattens. Then the springs push back, the top vertices reverse, and the cube bounces — not as a rigid block but as a squashing, stretching, wobbling mass that overshoots and oscillates before settling.

For platform edges, the same principle extends. A platform at a given y-level with bounded x-z extent: test each point against the plane only if it falls within the platform's horizontal footprint. Points that slide off the edge stop colliding and fall freely. The cube can drape over a ledge — some points resting on the surface, others dangling below, springs stretching across the boundary. This is deformation that rigid bodies cannot express.

## The Softmill: Continuous Mechanical Force

Gravity is a constant force. Collisions are instantaneous impulse events. The softmill introduces a third mode: continuous, localized, mechanical pressure.

The softmill is a rotating rigid arm that sweeps through the arena. When it contacts the jelly cube, it does not bounce off — it pushes through, displacing mass points along its path. The cube deforms around the arm, flattens against the floor beneath it, then reforms after the arm passes.

```gdscript
func apply_softmill_force(point: MassPoint, mill_pos: Vector3,
                          mill_radius: float, mill_force: float) -> void:
    var to_point := point.position - mill_pos
    var distance := to_point.length()
    if distance < mill_radius:
        var penetration := mill_radius - distance
        var push_dir := to_point.normalized()
        point.position += push_dir * penetration
```

The mill does not apply a force in the Newtonian sense — it enforces a position constraint. Any mass point inside the mill's radius is pushed outward to the boundary. This is rigid-versus-soft collision resolution: the mill wins, the cube yields. The spring network then propagates the displacement through the body. Points far from the contact zone shift as well, pulled by their spring connections. One local push becomes a global deformation.

The mill reveals how the spring topology distributes force. Structural springs carry the compression along edges. Shear springs prevent the cube from collapsing into the mill's path. Bend springs resist volumetric collapse. The cube wraps around the obstacle rather than passing through it or shattering. The three spring types cooperate to produce material behavior that none of them could achieve alone.

## Rest Shape as Memory

The rest lengths stored in each spring encode the cube's identity — its original shape. Without external forces, the springs drive every vertex back toward its initial configuration. The rest shape is the body's memory. Deformation is deviation from that memory. Recovery is the springs asserting what the body was before the world intervened.

This is what separates a soft body from a fluid. A fluid has no rest shape. Displace its particles and they redistribute according to pressure and viscosity, with no preference for any particular arrangement. A soft body resists. The springs encode a topological memory — not just distances but relationships. Vertex 0 is connected to vertex 1 at distance 1.0. That constraint persists regardless of what forces act. The cube can flatten, stretch, and wobble, but it always knows what shape it is trying to be.

The stiffness constant k governs the strength of that memory. At k approaching infinity, the body is rigid — the memory is absolute and deformation is impossible. At k approaching zero, the springs exert no restoring force and the body dissolves — the memory is forgotten. The interesting regime is between these extremes. At moderate k, the body deforms under load, stores elastic potential energy in the stretched springs, and releases it as kinetic energy during recovery. The oscillation between deformed and recovered states is the visible negotiation between force and memory.

The QFEP integration phase positions this map at lambda = 0.5 — halfway between rigid order and fluid disorder. The spring-mass system is the mechanical instantiation of that parameter. The spring constant is not literally lambda, but it governs the same continuum: how much the system's current state is determined by its remembered configuration versus its response to environmental pressure. Stiff springs — lambda near 1.0, order dominates, the cube barely deforms. Soft springs — lambda near 0.0, the environment dominates, the cube loses coherence. The jelly cube lives in the middle, where form is neither imposed nor abandoned but continuously renegotiated.

## The Full Simulation Loop

Assembling the pieces into a single frame update:

```gdscript
var gravity := Vector3(0.0, -9.8, 0.0)
var constraint_iterations := 4

func _physics_process(delta: float) -> void:
    # 1. Apply external forces
    for point in points:
        point.acceleration += gravity

    # 2. Apply spring forces
    for spring in springs:
        spring.apply_force()

    # 3. Verlet integration
    integrate(delta)

    # 4. Constraint satisfaction
    satisfy_constraints(constraint_iterations)

    # 5. Collision response
    resolve_collisions(floor_y, restitution)

    # 6. Update visual mesh
    _sync_mesh_to_points()
```

Six steps. Gravity pulls every particle downward. Springs pull connected particles toward their rest distances. Integration advances positions using implicit velocity. Constraints correct any springs that have drifted beyond tolerance. Collisions clamp particles above surfaces. The mesh renderer reads the final positions and draws the cube in its deformed state.

The `_sync_mesh_to_points` step bridges physics and rendering. The mass points live in simulation space. The visual mesh — the actual triangles drawn to screen — must track those points. Each vertex of the rendered cube maps to a mass point. Each frame, the vertex buffer updates to match the simulated positions. The learner sees a wobbling, deforming cube because the rendering layer faithfully reports what the physics layer computed.

The order matters. Forces before integration. Integration before constraints. Constraints before collision. Collision last, so the final positions are guaranteed valid. Swap collision and integration and points can tunnel through floors during high-velocity impacts. Swap constraints and forces and the springs fight their own corrections. The pipeline is a sequence, not a set.

## Possible Artifacts

**jelly_cube** — The core artifact. A spring-mass cube with adjustable stiffness, damping, and restitution. Drop it from the elevated platforms. Watch the deformation on impact — the bottom face flattens, the top face overshoots downward, the springs oscillate until damping settles the shape. Exports for mass, k values per spring type, damping coefficient, and constraint iterations.

**softmill** — A rotating rigid arm that sweeps through the arena at adjustable speed and height. Drives continuous deformation of any soft body in its path. Reveals how spring topology distributes localized force into global shape change. Exports for rotation speed, arm radius, and contact stiffness.

**spring_constant_comparator** — Three identical cubes rendered side by side with different k values: stiff (k = 500), medium (k = 50), soft (k = 5). All dropped from the same height simultaneously. The stiff cube barely deforms and bounces sharply. The medium cube flattens visibly and recovers with oscillation. The soft cube collapses nearly flat and reforms slowly. Same topology, same mass, same gravity — the only variable is stiffness. Makes the k-to-behavior relationship visible as a continuous spectrum rather than a single tuned parameter.
