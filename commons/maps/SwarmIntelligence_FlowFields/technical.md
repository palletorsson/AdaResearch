# The flow field assigns direction to space — agents read the field and follow, producing global streams from local obedience

Physarum agents coordinated through trail — chemical substance deposited and sensed, persisting across time, accumulated through reinforcement. The trail map was both output and input: agents wrote to it, and agents read from it. The coordination was indirect, mediated by a substance in the environment.

Flow fields abstract this. Instead of trail that agents deposit and sense, a vector field assigns a direction to every point in space before any agent arrives. The field is the program. Agents are the execution.

Each particle reads the local vector at its position and moves accordingly. No deposit. No memory. No agent-to-agent interaction. Just a pre-existing field of arrows and particles that follow them.

This is the mathematical substrate underlying all the swarm phenomena that follow. Physarum's trail gradient is a vector field. Boids' steering forces compute local vectors. Ant pheromone gradients define vector fields on graphs. The flow field map makes the abstraction explicit by stripping away the agent-generated feedback loop and presenting the field itself as the primary object.

## The Vector Field

A flow field is a function that assigns a 2D or 3D vector to every point in a continuous domain. In practice, the field is sampled on a grid.

```gdscript
var field_width: int = 64
var field_height: int = 64
var field: PackedVector2Array

func _ready() -> void:
    field.resize(field_width * field_height)
    _generate_perlin_field()

func _generate_perlin_field() -> void:
    var noise := FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = noise_scale

    for y in field_height:
        for x in field_width:
            # Use noise to generate angle at each grid point
            var angle: float = noise.get_noise_2d(float(x), float(y)) * TAU
            var idx: int = y * field_width + x
            field[idx] = Vector2(cos(angle), sin(angle))
```

Perlin noise maps grid coordinates to a scalar value between -1 and 1. Multiplying by TAU converts that scalar to an angle. The angle becomes a unit vector. Each grid cell holds a direction. The noise's spatial coherence ensures that nearby cells point in similar directions — the field has structure, not chaos. Streams will flow in smooth curves, not random walks.

The `noise_scale` parameter controls the field's spatial frequency. Low frequency produces broad, sweeping currents — large vortices and long parallel streams. High frequency produces tight, turbulent patterns — small eddies and rapid direction changes. The same noise generator that produced terrain heights in the procedural generation sequences now produces flow directions.

## Curl Noise: Divergence-Free Flow

For fluid-like behavior, the field should be divergence-free — no sources or sinks. Particles should flow without accumulating or depleting. Curl noise achieves this by computing the curl of a scalar potential field.

```gdscript
func _generate_curl_field() -> void:
    var noise := FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = noise_scale
    var epsilon: float = 0.01

    for y in field_height:
        for x in field_width:
            # Finite difference approximation of curl
            var fx: float = float(x) / float(field_width)
            var fy: float = float(y) / float(field_height)

            var dn_dx: float = (noise.get_noise_2d(fx + epsilon, fy) -
                                noise.get_noise_2d(fx - epsilon, fy)) / (2.0 * epsilon)
            var dn_dy: float = (noise.get_noise_2d(fx, fy + epsilon) -
                                noise.get_noise_2d(fx, fy - epsilon)) / (2.0 * epsilon)

            # Curl of 2D scalar field: rotate gradient 90 degrees
            var idx: int = y * field_width + x
            field[idx] = Vector2(-dn_dy, dn_dx).normalized()
```

The curl computation takes the gradient of the noise (the direction of steepest increase) and rotates it 90 degrees. The result is a vector field that flows along the contours of the noise landscape rather than across them. Particles follow these contours in closed or spiraling paths. No particle converges to a point or radiates outward. The flow preserves density.

This is the same mathematics that generates weather patterns. Atmospheric flow follows pressure contours. Ocean currents follow temperature contours. The curl noise field is a miniature meteorological system — structurally identical to a weather map, produced by the same operation applied to a different scalar potential.

## Particle Advection

Particles are minimal: position and nothing else. No velocity memory, no heading, no state. Each frame, a particle reads the field at its current position and moves.

```gdscript
var num_particles: int = 500
var particle_positions: PackedVector2Array
var particle_speed: float = 0.1

func _ready() -> void:
    particle_positions.resize(num_particles)
    for i in num_particles:
        particle_positions[i] = Vector2(randf(), randf())

func advect_particles(delta: float) -> void:
    for i in num_particles:
        var pos: Vector2 = particle_positions[i]
        var field_vec: Vector2 = sample_field(pos)
        particle_positions[i] = pos + field_vec * particle_speed * delta

        # Wrap at boundaries
        particle_positions[i].x = fposmod(particle_positions[i].x, 1.0)
        particle_positions[i].y = fposmod(particle_positions[i].y, 1.0)
```

No integration of acceleration. No force accumulation. The velocity at each frame is entirely determined by the local field vector. The particle has no momentum — if the field points north at time t and east at time t+1, the particle turns instantly. This is first-order advection: position updates directly from the field, with no intermediary dynamics.

## Bilinear Interpolation

The field is discrete (sampled on a grid). Particle positions are continuous. Sampling the field at a non-grid-aligned position requires interpolation.

```gdscript
func sample_field(pos: Vector2) -> Vector2:
    var fx: float = pos.x * float(field_width - 1)
    var fy: float = pos.y * float(field_height - 1)
    var ix: int = int(fx)
    var iy: int = int(fy)
    var tx: float = fx - float(ix)
    var ty: float = fy - float(iy)

    var ix1: int = mini(ix + 1, field_width - 1)
    var iy1: int = mini(iy + 1, field_height - 1)

    var v00: Vector2 = field[iy * field_width + ix]
    var v10: Vector2 = field[iy * field_width + ix1]
    var v01: Vector2 = field[iy1 * field_width + ix]
    var v11: Vector2 = field[iy1 * field_width + ix1]

    var top: Vector2 = v00.lerp(v10, tx)
    var bottom: Vector2 = v01.lerp(v11, tx)
    return top.lerp(bottom, ty)
```

Four nearest grid vectors are blended using the fractional position within the cell. The result is a smooth vector field that particles experience as continuous, even though the underlying data is discrete. Without interpolation, particles would snap to grid-aligned directions, producing jagged, staircase-like paths. With it, they trace smooth curves that reveal the field's topology.

## Time Evolution

The field can evolve. Adding a time parameter to the noise generator produces a field that changes continuously, creating patterns that flow through the domain rather than standing still.

```gdscript
var time_offset: float = 0.0
var time_speed: float = 0.1

func _process(delta: float) -> void:
    time_offset += delta * time_speed
    _regenerate_field_with_time(time_offset)
    advect_particles(delta)
    update_display()

func _regenerate_field_with_time(t: float) -> void:
    var noise := FastNoiseLite.new()
    noise.noise_type = FastNoiseLite.TYPE_PERLIN
    noise.frequency = noise_scale

    for y in field_height:
        for x in field_width:
            var angle: float = noise.get_noise_3d(
                float(x), float(y), t) * TAU
            field[y * field_width + x] = Vector2(cos(angle), sin(angle))
```

The noise function gains a third dimension — time. The angle at each grid point drifts smoothly. Vortices migrate. Streams shift direction. Convergence zones move across the domain. Particles that were following a stream find the stream relocating and must adapt. The field is no longer a static infrastructure but a living medium.

## The Central Ridge

The map's channel geometry — a wide floor with a central ridge — creates a topological feature in the flow. The ridge divides the channel into two zones. Flow patterns bifurcate around the ridge, creating a saddle point or divergence zone where streams split. Particles approaching the ridge from one side are deflected; particles that cross it enter a different flow regime.

The ridge is the field's only architectural constraint. Everything else is open. The contrast between the constrained central feature and the unconstrained periphery makes the flow topology legible — the learner can see convergence, divergence, and saddle behavior organized around a single spatial landmark.

## From Physarum to Pure Field

Physarum built its field. The trail map was an emergent vector field — gradients formed by accumulated deposits, shaped by agent behavior, evolving through feedback. The flow field map presents the field pre-built. No agent authored it. No feedback loop shapes it. The field exists independently of the particles that traverse it.

This separation clarifies what is agent and what is environment. In Physarum, the distinction was blurred — agents created the field they navigated. Here, the distinction is sharp — the field is given, the agents merely follow. The pedagogical purpose is to isolate the concept of field-guided motion from the concept of field generation, so that when boids (next map) introduce agent-generated fields through peer interaction, the learner can recognize what is new: agents computing their own vectors from neighbor queries, rather than reading vectors from a pre-existing grid.

The flow field is also the mathematical bridge to fluid dynamics, meteorology, and electromagnetic theory. Every vector field visualization in science — wind maps, ocean current maps, magnetic field line diagrams — is a flow field. The particles are probes. The field is the physics. The `FlowFieldMain` artifact makes this visible in VR: thousands of particles streaming through invisible currents, their paths revealing the field's hidden structure.
