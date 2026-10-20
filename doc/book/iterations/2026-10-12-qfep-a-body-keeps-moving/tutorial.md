# A body keeps moving

**Learning elements**

- Mapping two controls to requested mechanical properties
- Live pressure and damping; the limits of stiffness and drag controls
- A pressure baseline and a timed modulation
- Changing coefficients without resetting a simulated body
- Separating a setting, an observation and an interpretation

We are in Endless Museum's QFEP Synthesis. Find the specimen in its jar and use its own controls. Choose PAIR B. Watch **pressure base** and **pressure now**, then press PULSE / STEADY. The pressure becomes steady. Does the body immediately stop? The distinction is our last experiment in this laboratory.

Sandbox separated a value offered by a hand from the value received by an object. Here the route is direct and local: two values reach one deformable body. Keep the PointBody sphere as the hand control. Return to the SphereMesh we have made since Primitives, but give this receiver to `SoftBody3D` so its constituent positions can move. The control sphere stays a pickable rigid body; it does not secretly become the specimen. We retain both objects throughout the experiment.

## Carry the working bench

Work in `res://doc/book/studies/qfep-lineage/` inside the prepared Ada project. Keep `point_body.gd`, `line_skin.gd` and `bench.gd` unchanged. Their full sources remain in [Euclid](../Euclid_Parallel/tutorial.md#carried-files-complete) and [Russell](../Russell_Paradox/tutorial.md). Bench initializes our labels, sphere and five buttons. XRTools, the player and `res://commons/interactables/push_button.tscn` are supplied by the museum.

Godot supplies the soft-body solver; this project selects Jolt. We write the mapping that reaches it. Unlike the familiar rigid PointBody, a SoftBody3D uses its mesh for deformable contact. Do not give the specimen a rigid SphereShape3D. Its surrounding fixed boundaries do use ordinary BoxShape3D colliders.

The working copy uses a larger violet sphere in an outlined box, making the body and the limits of its movement readable on the bench. It copies the installed specimen's four requested coefficient mappings with base pressure 1.0, mass 0.5 and simulation precision 8. It does not copy the jar's dimensions, glass, fluid shader or colour changes. Those differences affect appearance and contact: matching coefficients is not a claim of identical trajectories. The outlined walls are solid even though their faces are not drawn.

## State the mapping

Create `morphology_map.gd`:

<!-- student-code:morphology_map.gd -->
```gdscript
extends RefCounted
var values: Array[float] = [0.5, 0.0]
var elapsed := 0.0
var pulsing := true
var kept: Dictionary = {}

func set_value(term: int, value: float) -> void:
    if term == 0: values[0] = clampf(value,0.0,1.0)
    elif term == 1: values[1] = clampf(value,-1.0,1.0)

func active() -> bool:
    return pulsing and values[0] > 0.3 and values[0] < 0.7

func reading() -> Dictionary:
    var l := values[0]
    var u := (values[1]+1.0)*0.5
    var base := 1.0+0.5*(1.0-absf(l-0.5)*2.0)
    var pressure := base
    if active():
        pressure *= 1.0+sin(elapsed*lerpf(0.5,2.0,l))*lerpf(0.02,0.1,l)
    return {"values":values.duplicate(), "stiffness":lerpf(0.9,0.1,l),
        "damping":lerpf(0.2,0.001,u), "drag":lerpf(0.3,0.0,u),
        "baseline":base, "pressure":pressure, "elapsed":elapsed,
        "enabled":pulsing, "active":active()}

func apply_to(body: SoftBody3D) -> void:
    var r := reading()
    body.linear_stiffness = r.stiffness
    body.damping_coefficient = r.damping
    body.drag_coefficient = r.drag
    body.pressure_coefficient = r.pressure

func advance(delta: float) -> void:
    elapsed += maxf(delta,0.0)

func toggle() -> void:
    pulsing = not pulsing
    elapsed = 0.0

func keep() -> void:
    kept = reading()
```

`values[0]` is lambda, from zero to one. `values[1]` is signed phi, from minus one to one. We continue the last halls' signed range rather than silently substituting Introduction's unsigned control.

Lambda requests **two properties together**. `lerpf(0.9, 0.1, l)` lowers requested stiffness as lambda increases. The baseline pressure peaks at lambda 0.5: it is 1.0 at either end and 1.5 in the middle. This triangular peak is an authored rule. It is not measured entropy or a discovered physical transition.

Phi also requests two properties together. The expression `(phi + 1) / 2` maps its signed range to the zero-to-one interpolation range. Requested damping changes from 0.2 to 0.001; requested drag changes from 0.3 to zero. But requests are not enough: the current engine ignores drag, and the stiffness readback can change without updating the running body's constraints. We keep those requests visible so the mismatch can be inspected. In this build, pressure and damping are the live mechanical controls.

**Check the engine as well as the script.** On Godot 4.6-stable with Jolt, our tests found drag readback fixed at zero. Matching bodies with different runtime stiffness settings followed the same motion; bodies built with different stiffnesses responded differently. The [Godot 4.6 source](https://github.com/godotengine/godot/blob/4.6-stable/modules/jolt_physics/objects/jolt_soft_body_3d.cpp) confirms the missing drag implementation and that stiffness is used when constraints are built. This is a version-specific limit. Our bench sets stiffness before entering the tree and retains that body; it labels both the request and its built value. It does not secretly rebuild the mesh to make a slider appear effective.

Bring back Wavefunctions: a sine multiplies the baseline, rather than replacing it. At lambda 0.5, speed is 1.25 radians per second and amplitude is 0.06. Pressure therefore ranges from 1.41 to 1.59. Pulsing operates only inside the open interval 0.3 < lambda < 0.7. At the endpoints, even an enabled pulse produces steady pressure. `active()` is what the readout reports.

`toggle` resets the modulation's phase clock, not the physical body. `apply_to` requests four properties on the specific receiver passed to it. Two affect the running mechanics here; drag is unused, and stiffness is retained for a future constraint construction. It neither makes a replacement mesh nor sets any vertex back to a starting position. KEEP copies the settings and the modulation clock for this run. It does not save vertex positions, velocities or a restartable physics checkpoint.

## Let those values reach a real body

Create `synthesis_study.gd`:

<!-- student-code:synthesis_study.gd -->
```gdscript
extends "bench.gd"
const Mapping = preload("morphology_map.gd")
const LOW := 1.12
const TRAVEL := 0.48
var model := Mapping.new()
var selected := 0
var body: SoftBody3D
var state_label: Label3D
var built_stiffness := 0.5

func _ready() -> void:
    start("A BODY RECEIVES THE MAPPING",["LAMBDA","PHI","PULSE / STEADY","NUDGE","KEEP"],
        [select.bind(0),select.bind(1),toggle,nudge,keep])
    block(self,Vector3(-1.12,LOW+TRAVEL/2,0.04),Vector3(0.018,TRAVEL,0.018),Color("526071"))
    # Six fixed boundaries; the thin frame makes the invisible collision box visible.
    boundary(Vector3(0.4,0.99,0),Vector3(1.1,0.02,0.9))
    boundary(Vector3(0.4,1.65,0),Vector3(1.1,0.02,0.9))
    boundary(Vector3(-0.15,1.32,0),Vector3(0.02,0.66,0.9))
    boundary(Vector3(0.95,1.32,0),Vector3(0.02,0.66,0.9))
    boundary(Vector3(0.4,1.32,-0.45),Vector3(1.1,0.66,0.02))
    boundary(Vector3(0.4,1.32,0.45),Vector3(1.1,0.66,0.02))
    block(self,Vector3(0.4,0.99,0),Vector3(1.1,0.02,0.9),Color("b8b0a6"))
    for y: float in [1.0,1.64]:
        for z: float in [-0.45,0.45]:
            block(self,Vector3(0.4,y,z),Vector3(1.1,0.012,0.012),Color("526071"))
        for x: float in [-0.15,0.95]:
            block(self,Vector3(x,y,0),Vector3(0.012,0.012,0.9),Color("526071"))
    for x: float in [-0.15,0.95]:
        for z: float in [-0.45,0.45]:
            block(self,Vector3(x,1.32,z),Vector3(0.012,0.64,0.012),Color("526071"))
    body = SoftBody3D.new()
    var sphere := SphereMesh.new()
    sphere.radius = 0.16
    sphere.height = 0.32
    sphere.radial_segments = 16
    sphere.rings = 12
    body.mesh = sphere
    body.position = Vector3(0.4,1.34,0)
    body.total_mass = 0.5
    body.simulation_precision = 8
    body.collision_layer = 2
    body.collision_mask = 1
    var material := StandardMaterial3D.new()
    material.albedo_color = Color("ac7fd0")
    material.roughness = 0.45
    body.material_override = material
    model.apply_to(body)
    built_stiffness = body.linear_stiffness
    add_child(body)
    state_label = label(self,"",Vector3(-0.91,1.71,0.15),20)
    label(self,"FIXED BOUNDARY / soft sphere",Vector3(0.4,1.04,0.52),17)
    redraw()

func boundary(at: Vector3, size: Vector3) -> void:
    var wall := StaticBody3D.new()
    wall.position = at
    wall.collision_layer = 1
    var collision := CollisionShape3D.new()
    var shape := BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    wall.add_child(collision)
    add_child(wall)

func _process(_delta: float) -> void:
    if point == null: return
    if point.held():
        var fraction := clampf((to_local(point.global_position).y-LOW)/TRAVEL,0.0,1.0)
        model.set_value(selected,fraction if selected == 0 else 2.0*fraction-1.0)
        model.apply_to(body)
    redraw()

func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if body == null: return
    model.advance(delta)
    model.apply_to(body)

func select(term: int) -> void:
    if point.held(): return
    selected = term
    redraw()

func toggle() -> void:
    if point.held(): return
    model.toggle()
    model.apply_to(body)
    redraw()

func nudge() -> void:
    if point.held(): return
    body.apply_central_impulse(global_basis*Vector3(0.08,0.04,0))

func keep() -> void:
    if point.held(): return
    model.keep()
    redraw()

func redraw() -> void:
    var r := model.reading()
    var fraction: float = r.values[0] if selected == 0 else (r.values[1]+1.0)*0.5
    point_home = Vector3(-1.12,LOW+fraction*TRAVEL,0.22)
    state_label.text = "L %.2f / P %+.2f" % r.values
    var kept := "KEEP: no settings kept"
    if not model.kept.is_empty():
        kept = "Kept L %.2f / P %+.2f / settings only" % model.kept.values
    readout.text = "%s / hand edits %s\nStiffness request %.3f / built %.3f / damping %.3f\nPressure base %.3f / now %.3f\nDrag request %.3f / engine %.3f (unused)\n%s" % [
        "PULSE" if r.active else "STEADY","LAMBDA" if selected == 0 else "PHI",
        body.linear_stiffness,built_stiffness,body.damping_coefficient,
        r.baseline,body.pressure_coefficient,r.drag,body.drag_coefficient,kept]
```

The familiar sphere recipe now belongs to SoftBody3D. Rings and segments supply the surface the solver can deform. The six `boundary` calls make a fixed box with an inside floor at height 1.0; the frame shows where its faces stand. The museum bench's tabletop is a visual mesh, so we explicitly construct the floor collider instead of assuming a visible surface will support the specimen.

The collision mask is deliberate: the specimen sees layer 1, which includes its box and museum architecture. The carried control sphere lives on layer 3 and does not shove the specimen accidentally while editing a value. NUDGE gives the body a small impulse in the bench's local direction, converted to world space. The values are a repeatable input, but the resulting motion depends on the body's current state and contacts.

Lift the same PointBody to edit lambda or phi. `to_local` keeps the height control meaningful when the bench is translated or rotated in the museum. Release before selecting a term or pressing an action. Only the selected value changes. The model sends its properties straight to this body; it broadcasts nothing to the original specimen, ceiling or term spheres.

The new `_physics_process` first calls the inherited method so the released PointBody still returns to its rail. Then it advances the pressure clock and applies the mapping once per physics update. `_process` handles the hand and refreshes the plate. Drawing a label does not advance simulation time. The plate reads properties back from the actual SoftBody3D, alongside the computed pressure baseline. It distinguishes the requested stiffness from the value used when this body was built, and requested drag from the engine's zero. Even a nonzero readback is not sufficient evidence of a physical effect.

PULSE / STEADY changes the forcing. NUDGE adds an impulse. Neither operation resets the mesh, its current deformation or its motion. The engine keeps integrating after the pressure becomes steady. We also keep the material colour fixed: here a change in silhouette must come from moving geometry, not from the shader changing colour.

## Run inside the museum

Open the supplied `synthesis.tscn` and press F6. Its `synthesis_museum.gd` adapter mounts this bench in the real Synthesis hall alongside the existing works and player. The adapter and room are supplied infrastructure; all new lesson behavior is printed above. Desktop grab or the VR grip moves the control sphere; the five nearby buttons select and apply the actions.

1. At the opening pair, lambda 0.5 and phi 0, predict built stiffness 0.5, damping 0.1005 and pressure base 1.5. Requested drag is 0.15; the engine still reports zero. Watch the changing pressure.
2. Press PULSE / STEADY, then NUDGE. Track a part of the surface. Steady pressure and continuing motion can occur together. KEEP records this setting, not that moving surface's full state.
3. Hold lambda at 0.5; change phi to +1. Pressure base and stiffness should stay the same. Damping becomes 0.001. The drag request becomes zero, matching its already-unused engine value. Give another nudge. The starting physical state was not reset, so identical impulses are not identical experiments.
4. Change lambda while keeping phi fixed. Check the requested stiffness and pressure base. Built stiffness remains 0.5. Move beyond the pulsing band and notice that the effective mode reads STEADY even when pulsing remains enabled.

**Make a new comparison.** Without a preset, form lambda 0.2 / phi +0.8 and KEEP it. Predict requested stiffness 0.74, baseline 1.2, damping 0.0209 and requested drag 0.03. Then form lambda 0.8 / phi -0.8: requested stiffness 0.26, the same baseline 1.2, damping 0.1801 and requested drag 0.27. In both, built stiffness stays 0.5 and engine drag stays zero. Both pairs have steady pressure. Nudge each and describe what you see without pretending that equal pressure supplies equal histories. Which quantities are controlled, and which are still changing?

## Check the claims

Create `morphology_checks.gd`:

<!-- student-code:morphology_checks.gd -->
```gdscript
extends RefCounted
const Mapping = preload("morphology_map.gd")

func run() -> void:
    var m := Mapping.new()
    var r := m.reading()
    assert(is_equal_approx(r.stiffness,0.5))
    assert(is_equal_approx(r.baseline,1.5))
    assert(is_equal_approx(r.damping,0.1005))
    assert(is_equal_approx(r.drag,0.15))
    m.advance(PI/(2.0*1.25))
    assert(is_equal_approx(m.reading().pressure,1.59))
    m.advance(PI/1.25)
    assert(is_equal_approx(m.reading().pressure,1.41))
    m.toggle()
    assert(not m.pulsing and m.elapsed == 0.0)
    m.advance(10.0)
    assert(is_equal_approx(m.reading().pressure,1.5))
    m.set_value(1,1.0)
    r = m.reading()
    assert(is_equal_approx(r.damping,0.001) and is_zero_approx(r.drag))
    assert(is_equal_approx(r.stiffness,0.5) and is_equal_approx(r.baseline,1.5))
    m.set_value(0,0.0)
    assert(is_equal_approx(m.reading().stiffness,0.9))
    assert(is_equal_approx(m.reading().baseline,1.0))
    assert(is_equal_approx(m.reading().damping,0.001))
    m.set_value(0,1.0)
    assert(is_equal_approx(m.reading().stiffness,0.1))
    assert(is_equal_approx(m.reading().baseline,1.0))
    m.toggle()
    for l: float in [0.0,0.3,0.7,1.0]:
        m.set_value(0,l)
        assert(not m.active())
    m.set_value(0,0.5)
    assert(m.active())
    m.keep()
    m.set_value(0,-4.0)
    m.set_value(1,4.0)
    assert(m.values == [0.0,1.0])
    assert(m.kept.values == [0.5,1.0])
    r = m.reading()
    r.values[0] = 0.8
    assert(m.values[0] == 0.0)
    m.set_value(3,0.2)
    assert(m.values == [0.0,1.0])
    var time := m.elapsed
    m.advance(-10.0)
    assert(m.elapsed == time)
    var other := Mapping.new()
    assert(other.values == [0.5,0.0])
```

Run `python tools/test_qfep_synthesis.py` from the repository root. The supplied harness reconstructs these three files from this tutorial and the three declared inherited files from their earlier chapters. It runs the printed assertions, operates the sphere under a transformed parent, checks the independent comparison, and tests real Jolt vertex movement with pulsing disabled. It also checks that toggling pressure does not immediately rewrite vertex positions or replace the body.

The arithmetic assertions establish what coefficients are requested. A separate engine comparison checks live stiffness edits against construction-time stiffness and verifies the ignored drag setting. The physics checks establish that an actual simulated mesh can keep moving under steady pressure. Neither test proves a physical model of life or queerness, predicts identical trajectories at different time steps, or establishes what a human learner understood. Headset reach and comfort still need a person in the room.

## What leaves this laboratory

We can now distinguish an input, its route, its mapping, the evolving body and a retained observation. Each has a different job. The QFEP expression does not calculate this specimen's motion; an authored mapping feeds an existing mechanics solver. Post-Crisis asks what our resulting descriptions preserve and what they leave out. Carry the habit of keeping a setting separate from the body it helped produce.

**Short instruction:** Continue PointBody + Bench. Reuse sphere geometry as one SoftBody3D receiver; explicit fixed boundaries. L requests stiffness + pressure baseline. Signed P requests damping + drag. On tested Jolt: pressure/damping live, stiffness built at creation, drag unused. Show request versus effective value. Physics clock modulates pressure only for .3<L<.7. STEADY is not pause/reset. Keep material fixed. NUDGE current body; KEEP settings only. Assert ranges, pulse extrema, same-body continuity, moving vertices under steady pressure, local hand control and independent comparison. No measured QFEP/life/queerness claim.
