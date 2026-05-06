# Where friction gripped surfaces, drag fills the volume of space itself

Friction in Forces_4 resisted motion at contact — a surface property, constant once sliding began. Drag operates in the medium. Air, water, any fluid. The force depends not on a surface coefficient but on how fast the object moves through the space. Push harder, move faster, and the medium pushes back harder still. This is velocity-dependent resistance: a force that grows with the very motion it opposes. The result is terminal velocity — a speed ceiling that emerges not from any designed limit but from two forces reaching exact balance.

## The Drag Equation

Drag force follows a specific relationship with velocity:

```
F_d = ½ * ρ * v² * C_d * A
```

Five quantities:

- `ρ` (rho) — fluid density. Air at sea level is roughly 1.225 kg/m³, water about 1000 kg/m³.
- `v` — the object's speed through the fluid.
- `C_d` — the drag coefficient, a dimensionless number encoding how shape interacts with flow.
- `A` — the cross-sectional area facing the flow direction.
- The ½ is a convention from the kinetic energy derivation.

The critical term is `v²`. Drag scales with the square of velocity. Double your speed, quadruple the drag. Triple your speed, nine times the resistance. This nonlinearity is what makes drag qualitatively different from kinetic friction. Friction exerts constant force regardless of speed. Drag accelerates its opposition.

In code, the drag vector points opposite to velocity:

```gdscript
var drag_force := -0.5 * fluid_density * velocity.length_squared() * drag_coefficient * cross_section_area * velocity.normalized()
```

The `velocity.normalized()` provides direction. The magnitude comes from the squared-speed term and the physical constants. The negative sign ensures drag always opposes motion — a vector antiparallel to velocity. No object accelerates itself through drag. The medium only resists.

Note the use of `length_squared()` rather than `length()` followed by squaring. The drag equation needs v², and `length_squared()` avoids the square root that `length()` computes internally — the same optimization pattern from VectorBasics applied to a physics formula. The squared magnitude is the native quantity here. The square root would be immediately undone.

## Terminal Velocity: The Emergent Speed Limit

Drop an object. Gravity accelerates it downward. As speed increases, drag increases — proportional to v². At some speed, drag force equals gravitational force exactly. Net force reaches zero. Acceleration ceases. The object falls at constant velocity from that point forward.

This speed is terminal velocity. Solve for it by setting drag equal to weight:

```
½ * ρ * v_t² * C_d * A = m * g
v_t = √(2mg / (ρ * C_d * A))
```

Terminal velocity depends on mass, gravity, fluid density, drag coefficient, and cross-sectional area. A skydiver spreads arms and legs — larger A, lower terminal velocity. Tuck into a ball — smaller A, faster fall. The shape matters because `C_d * A` together determine how efficiently the object parts the fluid.

```gdscript
func compute_terminal_velocity(mass: float, gravity: float,
        fluid_density: float, drag_coeff: float, cross_area: float) -> float:
    return sqrt(2.0 * mass * gravity / (fluid_density * drag_coeff * cross_area))
```

A single function, five parameters, one output. The square root means terminal velocity grows slowly with mass — doubling mass increases terminal velocity by only a factor of √2. Heavy objects fall faster in air, but not proportionally faster. A bowling ball and a baseball differ in mass by a factor of roughly 30, but their terminal velocities differ by far less because shape and area also vary.

The denominator `ρ * C_d * A` groups the medium and the geometry together. Increase fluid density (drop the object in water instead of air) and terminal velocity plummets. Increase drag coefficient (flatten the shape) and it drops again. Every factor in the denominator acts as a brake. Every factor in the numerator acts as an accelerator. Terminal velocity is the ratio — the point where brake and accelerator produce the same torque on the system.

## Dynamic Equilibrium

Terminal velocity is equilibrium — but not the static kind. The object moves. Forces act. Nothing is at rest. Yet nothing accelerates. The net force is zero because two opposing forces balance perfectly, and they balance precisely because one of them adjusts with speed until it matches the other.

This is the first dynamic equilibrium in the Forces sequence. Static equilibrium (a book on a table) involves zero velocity and zero net force. Dynamic equilibrium involves nonzero velocity and zero net force. The system is in motion but in steady state.

The QFEP structure here reveals something about how stable configurations emerge: the system does not need a designer to set the speed limit. Gravity pulls. Drag pushes back proportional to v². The two forces negotiate through physics until they agree on a number. Terminal velocity is the fixed point of that negotiation — a stable attractor in velocity space.

Perturb the system and it returns. Speed up past terminal velocity — drag exceeds gravity, net force decelerates the object back down. Slow below terminal velocity — gravity exceeds drag, net force accelerates it back up. The equilibrium self-corrects. This is stability: not the absence of disturbance but the presence of restoring tendency.

```gdscript
func _physics_process(delta: float) -> void:
    var gravity_force := Vector3(0, -mass * gravity, 0)
    var speed := velocity.length()
    var drag_magnitude := 0.5 * fluid_density * speed * speed * drag_coefficient * cross_area
    var drag_force := -velocity.normalized() * drag_magnitude if speed > 0.001 else Vector3.ZERO

    var net_force := gravity_force + drag_force
    var acceleration := net_force / mass
    velocity += acceleration * delta
    position += velocity * delta
```

Each frame: compute gravity (constant, downward), compute drag (velocity-dependent, opposing motion), sum them, divide by mass for acceleration, integrate. As speed climbs toward terminal velocity, `drag_magnitude` approaches `mass * gravity`, net force approaches zero, and acceleration vanishes. The velocity curve flattens into a horizontal asymptote. The code does not check for terminal velocity or clamp speed. The equilibrium emerges from the math alone.

The guard `speed > 0.001` prevents normalizing a near-zero velocity vector. Normalizing zero produces undefined results — division by zero magnitude. The threshold acts as a numerical floor. Below it, drag is effectively zero anyway (v² of a thousandth is a millionth), so the approximation costs nothing and prevents NaN propagation. This pattern — guarding normalization with a minimum magnitude check — appears throughout the `force_field_visualizer` as well.

## The Force Field Visualizer and Spatial Drag

The `force_field_visualizer` artifact in this map renders force vectors across a spatial grid. Each arrow represents the force a fluid exerts at that point in space. For uniform flow — wind blowing steadily in one direction — every arrow points the same way with the same magnitude. The field is constant. An object moving through it experiences drag proportional to its velocity relative to the flow.

```gdscript
func _calculate_field(pos: Vector3) -> Vector3:
    match field_type:
        FieldType.GRAVITY:
            return Vector3(0, -field_strength, 0)

        FieldType.POINT_CHARGE:
            var r = pos - source_position
            var dist = r.length()
            if dist < 0.01:
                return Vector3.ZERO
            return r.normalized() * field_strength / (dist * dist + 0.01)
```

Gravity produces a uniform field — every grid point returns the same downward vector. The point charge field varies with position: arrows radiate outward from the source, shrinking with inverse-square distance. Both are relevant to drag. Gravity is the force that drag opposes during freefall. The radial field pattern mirrors how pressure distributions form around objects in fluid flow — highest at the front face, lowest in the wake.

The `+ 0.01` in the denominator of the inverse-square calculation is a softening parameter. Without it, the field magnitude diverges to infinity as distance approaches zero — a singularity. The softening caps the maximum force, preventing numerical explosion at the source point. This is the same regularization technique used in gravitational N-body simulations. The physics says infinite force at zero distance; the simulation says "close enough" and moves on.

The visualizer computes orientation per arrow using the field vector's direction:

```gdscript
func _orient_arrow(idx: int, pos: Vector3, field: Vector3) -> void:
    var magnitude = field.length()
    if magnitude < 0.001:
        var hidden_xf := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -100, 0))
        _shaft_mm.set_instance_transform(idx, hidden_xf)
        _head_mm.set_instance_transform(idx, hidden_xf)
        return

    var scale_factor = clampf(magnitude * 0.5, 0.3, 2.0)
    var direction = field.normalized()
```

Magnitude below threshold hides the arrow entirely — scaled to near-zero and moved offscreen. Above threshold, arrow length scales with field magnitude (clamped to prevent visual overflow). Direction comes from normalization. The visual encoding is direct: longer arrow means stronger force, arrow heading means force direction. The field becomes legible as a spatial map of resistance.

The MultiMesh approach renders all arrows in a single draw call per component (one for shafts, one for heads). Each arrow instance gets its own transform and color, but the GPU batches them into one mesh draw. For a 16x16 grid — 256 arrows, 512 mesh instances total — individual MeshInstance3D nodes would create 512 draw calls per frame. MultiMesh reduces that to two.

The performance difference scales with grid resolution. At 8x8 (the default `grid_resolution`), the savings are modest. At 32x32, they are essential. This is the same instancing principle behind particle systems and foliage rendering: many identical meshes, each with a unique transform, drawn as one operation.

## Reynolds Number and Flow Regimes

Not all drag behaves the same. The Reynolds number `Re` determines the flow regime:

```
Re = ρ * v * L / μ
```

Here `ρ` is fluid density, `v` is flow speed, `L` is a characteristic length (the object's diameter, typically), and `μ` (mu) is the fluid's dynamic viscosity — its internal resistance to flow.

Low Reynolds number means viscous forces dominate: flow is laminar, smooth, predictable. High Reynolds number means inertial forces dominate: flow is turbulent, chaotic, eddying.

The drag equation `F_d = ½ρv²C_dA` assumes turbulent flow — the v² regime. At very low Reynolds numbers (small objects, slow speeds, viscous fluids), drag becomes linear with velocity instead:

```
F_d = 6πμrv    (Stokes drag for a sphere)
```

Linear drag decelerates exponentially — fast initial slowdown, then a long asymptotic tail toward zero. Quadratic drag decelerates hyperbolically — stronger braking at high speeds, weaker at low speeds, producing a different velocity curve shape during the approach to terminal velocity. The two regimes yield different approach profiles even when the final terminal velocity is the same.

```gdscript
func compute_drag(speed: float, regime: String) -> float:
    match regime:
        "laminar":
            # Stokes: F proportional to v
            return 6.0 * PI * viscosity * radius * speed
        "turbulent":
            # Newton: F proportional to v²
            return 0.5 * fluid_density * speed * speed * drag_coefficient * cross_area
        _:
            return 0.0
```

The regime determines which equation applies. In practice, most everyday objects in air (cars, baseballs, skydivers) operate in the turbulent regime. Dust particles, fog droplets, and microscopic organisms live in the laminar regime. The Reynolds number draws the boundary — roughly Re < 1 for Stokes drag, Re > 1000 for fully turbulent drag, and a transitional zone between where neither equation is exact.

The distinction matters for simulation fidelity. A game simulating a falling feather (low Re, laminar) should use linear drag. A game simulating a cannonball (high Re, turbulent) should use quadratic. Using the wrong regime produces the wrong velocity profile — the feather would fall too fast, the cannonball would brake too hard. The physics is the same; the approximation changes.

## Shape, Coefficient, and the Meaning of C_d

The drag coefficient `C_d` encodes geometry:

- Sphere: `C_d ≈ 0.47`
- Flat plate perpendicular to flow: `C_d ≈ 1.28`
- Streamlined airfoil: `C_d ≈ 0.04`

These numbers carry the entire story of how shape interacts with fluid — where flow separates, how large the wake region grows, how much pressure difference develops between front and back.

```gdscript
const DRAG_COEFFICIENTS := {
    "sphere": 0.47,
    "flat_plate": 1.28,
    "streamlined": 0.04,
    "cylinder": 0.82,
    "cube": 1.05,
}
```

A flat plate has nearly three times the drag coefficient of a sphere. That means at the same speed, size, and fluid, the plate experiences three times the drag force. Its terminal velocity is correspondingly lower — the plate reaches equilibrium sooner, at a slower fall. The streamlined shape slips through at a tenth of the sphere's drag, reaching much higher terminal velocity before balance is achieved.

The `force_field_visualizer` encodes this indirectly. Its arrows show force at each grid point, but the response of an object to that field depends on `C_d * A` — the product of coefficient and area. Two objects in the same field experience different forces. The field is the medium's offering. The object's geometry determines how much it accepts.

The color encoding in the visualizer maps outward alignment to red and inward alignment to blue:

```gdscript
var from_source = (pos - source_position).normalized()
var alignment = direction.dot(from_source)
color = color_negative.lerp(color_positive, (alignment + 1.0) / 2.0)
```

The dot product between field direction and radial direction produces a scalar from -1 (perfectly inward) to +1 (perfectly outward). Remapping to [0, 1] feeds it into a color interpolation.

Blue arrows point toward the source. Red arrows point away. The gradient between them shows oblique angles — arrows that partially face the source but partially slide past it. This dot-product-to-color mapping is a general technique for encoding directional relationships visually.

## Vortex Fields and Turbulent Wakes

The visualizer's vortex mode generates a tangential field:

```gdscript
FieldType.VORTEX:
    var r = pos - source_position
    var dist = r.length()
    if dist < 0.01:
        return Vector3.ZERO
    var tangent = Vector3(-r.z, 0, r.x).normalized()
    var profile = dist / (dist * dist + 0.02)
    return tangent * field_strength * profile
```

The tangent vector `(-r.z, 0, r.x)` is perpendicular to the radial direction — a 90-degree rotation in the xz-plane. Given a radial vector `(x, 0, z)`, swapping and negating one component produces the perpendicular. This is the 2D cross product extended into 3D on the xz-plane, with y held at zero.

The profile function `dist / (dist² + 0.02)` peaks at moderate distance and decays both toward the center and toward infinity. This creates a vortex: arrows swirl around the source, strongest at mid-range, fading at the core and the periphery. The `+ 0.02` serves the same softening role as in the point charge field — preventing division by zero at the source.

Vortices matter for drag because real objects generate them. The wake behind a moving sphere contains swirling structures — von Karman vortex streets, turbulent eddies. These structures extract kinetic energy from the object and deposit it as rotational motion in the fluid. The energy cost of creating vortices is drag. The vortex field in the visualizer models what the fluid does in the wake region — a spatial map of rotational energy the moving object leaves behind.

The color encoding uses angular hue:

```gdscript
var angle = atan2(r.x, r.z)
var hue = fmod((angle + PI) / TAU + 0.3, 1.0)
color = Color.from_hsv(hue, 0.7, 1.0)
```

Hue varies continuously around the vortex center. Each angular position gets a distinct color. The visual result is a color wheel of arrows spiraling around the source — a direct spatial encoding of the rotational symmetry inherent in vortex flow.

The pattern is continuous because the underlying field is continuous. No discontinuities, no boundaries. The curl field wraps smoothly. The `+ 0.3` offset in the hue calculation shifts the color wheel so that green starts at the "front" of the vortex rather than red — a visual design choice that avoids confusion with the red/blue directional encoding used in other field modes.

## From Constant to Velocity-Dependent

Friction in Forces_4 applied a constant force once motion began. Gravity in earlier maps applied a constant force always. Drag breaks the pattern. Its magnitude is a function of the system's own state — the faster the object moves, the stronger the opposing force. This feedback loop produces terminal velocity. Without velocity-dependence, there is no equilibrium during freefall. Gravity would accelerate an object forever (in vacuum, it does, limited only by relativity).

The progression through the Forces sequence traces a path from simple to coupled:

- Constant forces (gravity) produce constant acceleration.
- Contact forces (normal, friction) introduce conditional responses — friction depends on whether the object moves, but once moving, the force is fixed.
- Drag introduces continuous coupling — force depends on velocity, which depends on force, which depends on velocity.

The system becomes self-referential. The QFEP loop closes: the output (velocity) feeds back into the input (drag force), and the system converges to a stable state (terminal velocity) where the loop produces no further change.

This self-referential quality is what makes drag the bridge from mechanics to dynamics in the deeper sense. Earlier forces act on the object. Drag acts in response to the object. The medium observes the object's velocity and adjusts its resistance accordingly.

The force field is not static — it depends on the state of the thing it acts upon. The `force_field_visualizer` shows a static field because it samples force at each point independently. But for a moving object, the effective drag field is a function of the object's own motion. The field and the object co-evolve.

Forces_6 extends this coupling further. But here, at terminal velocity, the essential pattern is complete: a system that monitors its own output, feeds it back as input, and converges to equilibrium. The falling object is a closed-loop controller with no controller — just physics doing the regulating.

## Possible Artifacts

**terminal_velocity_demo** — Drops objects of different shapes (sphere, flat plate, streamlined body) through a visible fluid column. Each falls under gravity with quadratic drag computed from its `C_d` and cross-sectional area. Velocity readouts update in real time. The sphere reaches terminal velocity at one speed, the flat plate at a lower speed (higher drag), the streamlined body at a higher speed (lower drag). Side-by-side comparison makes `C_d` tangible — same gravity, same fluid, different geometries, different terminal velocities. The equilibrium point is visible as the moment each velocity curve flattens.

**drag_regime_comparator** — Simulates the same sphere falling under linear (Stokes) drag and quadratic (Newton) drag side by side. Two velocity-vs-time graphs plot in real time. The linear-drag curve approaches terminal velocity exponentially — fast initial convergence, long asymptotic tail. The quadratic-drag curve approaches differently — slower initial convergence but a sharper knee. A Reynolds number indicator shows where the transition between regimes occurs. The learner adjusts fluid viscosity and object size to shift between laminar and turbulent regimes and watches the velocity profile change shape.

**wake_vortex_visualizer** — Extends the force_field_visualizer's vortex mode into a dynamic simulation. A sphere moves through a grid of particles representing fluid. Behind the sphere, particles begin to rotate, forming visible vortex structures in the wake region. Arrow overlays show the velocity field around the sphere — high speed at the sides, recirculating flow behind. The learner controls sphere speed and watches how the wake structure changes: laminar at low speed, periodic vortex shedding at moderate speed, turbulent at high speed. Connects the drag coefficient to the physical mechanism that generates it.
