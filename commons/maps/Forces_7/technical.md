# Where fields acted on lone bodies, a burst scatters hundreds into the same air

Forces_6 introduced action at a distance — gravity and charge reaching across space through inverse-square fields. A single body fell into a gravitational well. A single charge orbited another. The field filled space, but only one object at a time responded to it. That isolation ends here. Particle systems apply the same forces — gravity, drag, spatial fields — to hundreds or thousands of bodies simultaneously. Each particle obeys F=ma independently. No particle knows the shape of the firework. The shape emerges from the ensemble. This is the jump from dynamics to statistical dynamics: same laws, many subjects, collective patterns that exist nowhere in any individual.

## Per-Particle State

Every particle carries its own state: position, velocity, age. The `firework_launcher` stores these in a dictionary per particle:

```gdscript
var particle := {
    "pos": pos,
    "vel": dir * speed,
    "color": color,
    "life": particle_lifetime,
    "max_life": particle_lifetime,
    "mesh": null,
}
```

Six fields. Position and velocity are vectors — they encode where and how fast. Color is visual metadata. Life and max_life are scalars tracking age. The mesh reference connects physics state to rendering. This dictionary is the particle's entire world. It knows nothing about other particles, nothing about the firework pattern, nothing about the burst that spawned it. It knows its position, its velocity, how long it has lived, and how long it may live.

The system maintains an array of these dictionaries. Each frame iterates over every particle, applies forces, updates state, checks for death. The array is the population. The loop is natural selection — particles that exhaust their lifetime are culled; those still alive receive another frame of physics.

```gdscript
var _particles: Array = []  # Exploded particles falling
```

A flat list. No spatial hierarchy, no neighbor queries, no interaction between particles. Each particle is an island of F=ma floating in shared force fields. The simplicity of the data structure reflects the simplicity of the model: particles do not collide with each other, do not attract each other, do not communicate. They share gravity and drag. That is their only connection — mediated by the environment, not by each other.

## Emission: The Birth Event

Particles do not exist from the start. They are emitted — spawned at a point in time with initial conditions. The `firework_launcher` emits in bursts: a rocket rises, reaches target height, and detonates into `particle_count_per_burst` particles.

```gdscript
func _explode(rocket: Dictionary):
    var pos: Vector3 = rocket["pos"]
    var colors: Array = rocket["colors"]
    var pattern: String = rocket["pattern"]

    for i in range(particle_count_per_burst):
        var dir: Vector3
        if pattern == "ring":
            var angle := float(i) / float(particle_count_per_burst) * TAU
            dir = Vector3(cos(angle), randf_range(-0.2, 0.4), sin(angle))
        else:
            dir = Vector3(
                randf_range(-1, 1),
                randf_range(-1, 1),
                randf_range(-1, 1)
            ).normalized()

        var speed := burst_force * randf_range(0.5, 1.0)
```

Two emission patterns. The sphere pattern generates random directions by sampling three random components and normalizing — a crude uniform sampling on the unit sphere (biased toward corners of the unit cube before normalization, but visually sufficient for a firework). The ring pattern distributes particles evenly around a horizontal circle using `cos(angle)` and `sin(angle)` on x and z, with a small random y component adding vertical scatter.

The speed varies between half and full `burst_force`. This variance is essential. If every particle received identical speed, the burst would expand as a hollow shell — all particles at the same radius at any given moment. The speed range creates a filled volume. Fast particles race ahead. Slow particles linger near the burst center. The distribution in initial speed becomes a distribution in spatial extent. Randomness in launch conditions produces structure in the result.

The `TAU` constant is 2*PI — a full circle in radians. Dividing the loop index by the total count and multiplying by `TAU` distributes angles evenly. The ring firework is deterministic in angle but random in speed and vertical offset. The sphere firework is random in both direction and speed. The same emission function produces two distinct collective shapes from different initial condition generators.

## Force Accumulation Per Frame

Each particle receives forces and integrates. The `_physics_process` loop handles the entire population:

```gdscript
for i in range(_particles.size()):
    var p: Dictionary = _particles[i]
    p["vel"].y -= gravity_strength * delta
    p["vel"] *= drag
    p["pos"] += p["vel"] * delta
    p["life"] -= delta
```

Four lines of physics per particle per frame. Gravity subtracts from the y-component of velocity — a constant downward acceleration applied as a velocity change scaled by `delta`. Drag multiplies the entire velocity vector by a coefficient less than one (0.98 by default) — a per-frame damping that reduces speed exponentially over time. Position advances by velocity times delta. Life decrements by delta.

The drag model here is simpler than Forces_5's quadratic drag equation. `p["vel"] *= drag` applies a multiplicative decay — each frame, velocity retains 98% of its magnitude. This is exponential damping: after n frames, speed is `initial_speed * drag^n`. The approximation ignores velocity-squared dependence and fluid density. It works for fireworks because visual plausibility, not physical accuracy, governs the design. Particles slow gracefully, arc under gravity, and fade. The eye accepts the trajectory.

The gravity term uses direct velocity modification rather than force accumulation followed by F/m division. Since all particles share the same mass (implicitly 1.0), `gravity_strength * delta` is both the force and the acceleration. This shortcut collapses two steps into one. The conceptual chain is still F=ma — gravity exerts force, force produces acceleration, acceleration changes velocity — but the code elides the intermediate variables because mass is uniform.

The order matters. Gravity modifies velocity. Drag scales velocity. Position uses the modified velocity. Life ticks down. If drag were applied before gravity, the gravitational impulse would not be damped until the next frame — a subtle ordering difference that changes the trajectory slightly. The current order applies gravity, then immediately damps the result, producing tighter arcs. For visual effects this distinction is negligible. For engineering simulation it would matter.

## Lifetime, Death, and Recycling

Particles are mortal. Each carries a countdown:

```gdscript
p["life"] -= delta

if p["life"] <= 0:
    dead_indices.append(i)
```

When life reaches zero, the particle dies. Its index enters a death list. After the update loop completes, dead particles are removed in reverse order to preserve index validity:

```gdscript
for i in range(dead_indices.size() - 1, -1, -1):
    var p: Dictionary = _particles[dead_indices[i]]
    if p["mesh"]:
        (p["mesh"] as MeshInstance3D).queue_free()
    _particles.remove_at(dead_indices[i])
```

Reverse iteration prevents index shifting from invalidating later removals. If particle at index 5 is removed first, every particle above index 5 shifts down by one, and the index for particle 8 becomes 7. Removing from the top down avoids this — index 8 is removed while 5 still occupies its original position, then 5 is removed with no ambiguity.

The `queue_free()` call schedules the mesh node for deletion at the end of the frame. Immediate deletion during iteration would risk dangling references. `queue_free` is Godot's deferred destruction — safe to call from within loops, guaranteed to execute after the current frame's processing completes.

The `life_ratio` drives visual decay:

```gdscript
var life_ratio: float = float(p["life"]) / float(p["max_life"])
var mat := mesh.material_override as StandardMaterial3D
if mat:
    mat.albedo_color.a = life_ratio
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.emission_energy_multiplier = 2.5 * life_ratio

var s: float = life_ratio * 0.8 + 0.2
mesh.scale = Vector3(s, s, s)
```

Opacity fades linearly with remaining life. Emission energy fades proportionally — dying particles glow less. Scale shrinks from full size to 20% of original (the `* 0.8 + 0.2` maps the ratio from [0, 1] to [0.2, 1.0], preventing particles from vanishing to a point before their alpha reaches zero). Three visual channels — opacity, glow, size — all driven by the same normalized parameter. The particle does not simply disappear; it wanes.

## Spatial Force Fields

The `force_fields` artifact demonstrates a complementary approach: Godot's built-in `Area3D` gravity overrides applying forces to `RigidBody3D` objects that enter their volume.

```gdscript
area.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
area.gravity_direction = Vector3(1.0, 0.5, 0.0).normalized()
area.gravity = 15.0
area.gravity_point = false
```

The `SPACE_OVERRIDE_COMBINE` mode adds this area's gravity to the default world gravity rather than replacing it. A ball falling into this zone experiences both downward global gravity and the area's directional push — a net force that bends the trajectory sideways and slightly upward. The `normalized()` call on the direction vector ensures unit length so that `gravity` (the scalar magnitude) controls strength independently of direction.

The point attractor uses `gravity_point = true`:

```gdscript
area.gravity_space_override = Area3D.SPACE_OVERRIDE_COMBINE
area.gravity_point = true
area.gravity_point_unit_distance = 1.0
area.gravity = 20.0
```

Point gravity pulls toward the area's origin. The `gravity_point_unit_distance` sets the reference distance at which the full `gravity` value applies. At twice that distance, the force is one-quarter (inverse-square). At half, four times. This is the same 1/r^2 law from Forces_6, now implemented as a spatial volume that any rigid body can wander into.

The wind/drag field adds damping:

```gdscript
area.linear_damp_space_override = Area3D.SPACE_OVERRIDE_COMBINE
area.linear_damp = 4.0
area.angular_damp_space_override = Area3D.SPACE_OVERRIDE_COMBINE
area.angular_damp = 2.0
```

Linear damping decelerates translation. Angular damping decelerates rotation. Together they simulate a viscous medium — balls entering this zone slow down as if moving through thick air. Combined with an upward gravity direction, the zone produces buoyancy: objects drift upward slowly, resisted by damping, reaching a terminal velocity dictated by the balance between buoyancy force and linear drag.

The three zones — directional gravity, point attractor, viscous buoyancy — demonstrate that particle behavior depends entirely on the forces present in the local region. The same ball follows a straight diagonal in one zone, spirals inward in another, and floats lazily in a third. The ball has not changed. The field has.

## GPU Particle Systems

The `particle_systems` artifact uses Godot's `GPUParticles3D` — a fundamentally different architecture from the `firework_launcher`'s CPU-side loop.

```gdscript
var particles := GPUParticles3D.new()
particles.amount = 200
particles.lifetime = 2.0

var mat := ParticleProcessMaterial.new()
mat.direction = Vector3(0, 1, 0)
mat.spread = 15.0
mat.initial_velocity_min = 4.0
mat.initial_velocity_max = 6.0
mat.gravity = Vector3(0, -9.8, 0)
```

No per-particle loop in GDScript. No dictionary array. No manual position integration. The `ParticleProcessMaterial` declares the rules — direction, spread angle, velocity range, gravity — and the GPU executes them for all 200 particles in parallel. The CPU sets parameters; the GPU runs the simulation. This is the performance model for large particle counts: thousands or tens of thousands of particles at frame rate, because the GPU's massively parallel architecture processes all particles simultaneously rather than sequentially.

The tradeoff is control. The `firework_launcher` can run arbitrary GDScript logic per particle — conditional branching, dictionary lookups, custom force functions. The GPU system is constrained to what `ParticleProcessMaterial` expresses: direction, velocity range, gravity vector, damping, color ramps, scale curves. Complex per-particle behavior (particles that avoid obstacles, respond to player input, or interact with each other) requires the CPU path. Simple forces applied uniformly belong on the GPU.

The fire effect demonstrates color ramps:

```gdscript
var gradient := Gradient.new()
gradient.set_color(0, Color(1.0, 0.9, 0.2))    # Yellow core
gradient.add_point(0.3, Color(1.0, 0.4, 0.1))   # Orange
gradient.add_point(0.7, Color(0.8, 0.1, 0.0))   # Red
gradient.set_color(1, Color(0.2, 0.1, 0.1, 0.0)) # Smoke fade
mat.color_ramp = color_ramp
```

The gradient maps particle age (normalized 0 to 1) to color. Newborn particles glow yellow. As they age, they shift through orange to red to dark translucent smoke. The ramp encodes a physical intuition — hot things glow bright, cooling things redden, cold things fade. No per-particle color logic runs on the CPU. The GPU samples the gradient texture for each particle's age ratio every frame. The entire visual progression is a texture lookup.

## Emergence: Shape Without Blueprint

The firework's shape — the expanding sphere, the ring, the cascading arc — exists nowhere in any particle's state. No particle stores "I am part of a sphere." Each stores only position, velocity, life. The sphere is a statistical property of the ensemble: a population of particles with isotropic initial velocities and uniform speed range, all subject to gravity and drag, produces a shape that a human observer calls a sphere.

Change the initial velocity distribution and the shape changes. The ring pattern distributes directions around a horizontal circle instead of randomly on a sphere. Same physics, same forces, same per-particle update loop. Different initial conditions produce a different collective form. The ring is not programmed as a ring. It is programmed as a distribution of angles, and the ring is what that distribution looks like after gravity and time act on it.

This is emergence in its most transparent form. The rules are local — each particle knows only its own state and the global forces. The pattern is global — visible only from outside, only by observing the population. The QFEP structure applies directly: the system's macroscopic state (the firework shape) is not reducible to any microscopic state (a single particle's dictionary). It is a property of the distribution. Entropy enters here — the spread of initial speeds creates disorder within the form; the directional distribution creates order. The tension between them produces the recognizable shape that fades, spreads, and dissolves as drag and gravity and death erode the population.

The `particle_count_per_burst` parameter controls fidelity. At 10 particles, the sphere is sparse — a scattering of dots with no discernible shape. At 60 (the default), the shape reads clearly. At 500, it would appear dense and continuous. The shape does not exist at low counts. It emerges as count increases. There is a threshold — not sharp, but real — below which randomness dominates and above which pattern dominates. This threshold is a statistical phenomenon. It is the same reason a coin flipped 5 times might show 80% heads, but a coin flipped 5000 times will show close to 50%. Large numbers suppress fluctuation. Structure becomes visible.

## The Rocket Phase

Before the burst, there is ascent. The `firework_launcher` models rockets as a separate population:

```gdscript
var rocket := {
    "pos": Vector3(randf_range(-0.05, 0.05), 0.2, randf_range(-0.05, 0.05)),
    "vel": Vector3(randf_range(-0.3, 0.3), launch_speed, randf_range(-0.3, 0.3)),
    "target_height": launch_height + randf_range(-0.3, 0.3),
    "colors": colors,
    "pattern": preset[2] as String,
}
```

Rockets carry their eventual burst parameters: colors, pattern, target height. They are particles themselves — position, velocity, physics update — but with a death condition based on altitude rather than age:

```gdscript
if r["pos"].y >= r["target_height"]:
    exploded_indices.append(i)
```

Reaching target height triggers `_explode()`, which destroys the rocket and spawns the burst population. The rocket is a single-particle system whose death event is the birth event of a many-particle system. One becomes many. The transition is discontinuous — one frame there is a rocket, the next frame there are sixty particles and no rocket. The population appears in a single instant, fully formed with initial conditions derived from the rocket's final position.

Rockets experience lighter gravity (`gravity_strength * 0.3 * delta` versus the full `gravity_strength * delta` for burst particles). This is a design choice, not physics. Real firework rockets burn fuel, producing thrust that overcomes gravity. The simulation approximates thrust by reducing effective gravity during ascent — a simpler model that produces visually similar results without modeling combustion.

## Possible Artifacts

**particle_inspector** — Pauses the particle system and lets the learner click any single particle to see its individual force vectors, velocity arrow, and acceleration arrow drawn in space. Hovering over a particle displays its dictionary state: position coordinates, velocity components, remaining life. The inspector makes visible how one particle's obedience to F=ma contributes to the collective pattern. When unpaused, the selected particle remains highlighted as it arcs and fades, its vectors updating in real time among the hundreds of anonymous siblings.

**emission_shape_explorer** — Provides sliders to control the initial velocity distribution: spread angle, speed range, directional bias, vertical offset. As the learner adjusts parameters, a preview shows the resulting emission shape as a wireframe envelope before any physics applies, then launches a burst to see how gravity and drag deform that envelope over time. Connects initial condition distributions to emergent shapes — the same physics producing spheres, cones, rings, jets, or curtains depending on how the velocities are seeded.

**cpu_gpu_comparator** — Runs identical particle configurations side by side: one using the `firework_launcher`'s CPU dictionary loop, the other using `GPUParticles3D` with equivalent `ParticleProcessMaterial` settings. A frame time readout shows the performance difference as particle count increases. At 100 particles, both perform similarly. At 1000, the GPU path dominates. At 10000, the CPU path drops frames while the GPU path remains smooth. The learner sees the architectural tradeoff: CPU flexibility versus GPU throughput, and the crossover point where the choice becomes obvious.
