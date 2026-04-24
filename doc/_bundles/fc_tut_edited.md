<<<ADA_BUNDLE>>>
sequence: foundationscrisis
file: tutorial.md
maps: 9
<<</ADA_BUNDLE>>>

<<<MAP: Euclid_Parallel>>>
# Euclid Parallel

Five postulates. The first four feel inevitable. Build a room that exposes the fifth as a choice.

Declare the five postulates as data.

```gdscript
const POSTULATES := [
    "Any two points can be joined by a straight line.",
    "Any finite line can be extended indefinitely.",
    "Any line segment and radius define a circle.",
    "All right angles are equal.",
    "Through a point not on a line, exactly one parallel can be drawn.",
]
```

Text, not logic. The postulates live as strings in a constant array so the room can render them on five plinths without a parser.

Lay the plinths in a horseshoe.

```gdscript
func place_plinths(parent: Node3D) -> void:
    var count := POSTULATES.size()
    for i in count:
        var angle := PI * (i + 1) / (count + 1)
        var p := preload("res://commons/maps/elements/text_plinth.tscn").instantiate()
        p.position = Vector3(cos(angle) * 4.0, 0.0, -sin(angle) * 4.0)
        p.text = POSTULATES[i]
        parent.add_child(p)
```

The horseshoe lets the learner read the sequence by walking it. Four feel like description; the fifth feels like an extra step.

Mark the fifth plinth.

```gdscript
func emphasize_fifth(plinth: Node3D) -> void:
    var label: Label3D = plinth.get_node("Label3D")
    label.modulate = Color(0.9, 0.7, 0.3)
    plinth.scale = Vector3.ONE * 1.2
```

Gold tint and a slightly larger scale. The fifth is set apart before any argument is made. The architecture performs the claim.

Animate parallel lines that actually stay parallel.

```gdscript
func draw_parallels(mesh: ImmediateMesh) -> void:
    mesh.clear_surfaces()
    mesh.surface_begin(Mesh.PRIMITIVE_LINES)
    for i in 5:
        var y := -2.0 + i * 1.0
        mesh.surface_add_vertex(Vector3(-5, y, 0))
        mesh.surface_add_vertex(Vector3(5, y, 0))
    mesh.surface_end()
```

Five lines, all parallel, all horizontal. The demonstration is quiet. Euclid's claim looks like a property of the world.

Toggle the fifth postulate.

```gdscript
func toggle_fifth() -> void:
    fifth_active = not fifth_active
    if fifth_active:
        parallel_preview.visible = true
    else:
        parallel_preview.visible = false
        chaos_preview.visible = true
```

Turn the fifth off and a second preview appears. Lines that should stay parallel begin to diverge. The postulate was doing work; without it, the picture fractures.

Record the 2300-year history on a scroll.

```gdscript
func populate_history(scroll: Label3D) -> void:
    scroll.text = "300 BCE Euclid\n1733 Saccheri\n1829 Lobachevsky\n1832 Bolyai\n1854 Riemann"
```

Five names across two millennia. Every one tried to prove the fifth from the first four. Every one failed — because it is independent.

Open the door once the learner reads the scroll.

```gdscript
func _on_scroll_read(duration_ms: int) -> void:
    if duration_ms > 2000:
        door.unlock()
```

The door waits until the scroll has been dwelt with. Reading is the action, not clicking.

You have seen geometry as a list of choices. The next map, NonEuclidean Spaces, turns the fifth postulate off and walks what remains.
<<</MAP>>>

<<<MAP: NonEuclidean_Spaces>>>
# NonEuclidean Spaces

Two alternatives, equally consistent with the first four postulates. Build a curvature slider that moves continuously between hyperbolic, Euclidean, and elliptic space.

Declare the curvature state.

```gdscript
class_name CurvatureField
extends Node3D

@export var curvature: float = 0.0

func set_curvature(k: float) -> void:
    curvature = clamp(k, -1.0, 1.0)
    _update_grid()
```

A single scalar controls everything. Negative is hyperbolic, zero is Euclidean, positive is elliptic. The slider is the curvature.

Build the base grid.

```gdscript
func _update_grid() -> void:
    for i in grid_vertices.size():
        var v := grid_vertices[i]
        grid_vertices[i] = _warp(v, curvature)
    grid_mesh.update_from(grid_vertices)
```

The grid starts flat. Each frame, vertices warp according to the current curvature. The mesh is the same vertex list differently placed.

Warp a vertex.

```gdscript
func _warp(v: Vector3, k: float) -> Vector3:
    var r := v.length()
    var factor: float = 1.0 + k * r * r * 0.02
    return v * factor
```

Parabolic scaling with distance from origin. Close to the slider, the warp is subtle; far away, it bends dramatically.

Draw two parallel geodesics.

```gdscript
func draw_parallels(k: float) -> void:
    var a := _geodesic(Vector3(-2, 0, -5), Vector3.FORWARD, k)
    var b := _geodesic(Vector3(2, 0, -5), Vector3.FORWARD, k)
    parallels_mesh.draw(a, b)
```

Two lines start parallel. At k=-1 they diverge. At k=0 they stay parallel. At k=+1 they converge and meet.

Integrate a geodesic step by step.

```gdscript
func _geodesic(start: Vector3, direction: Vector3, k: float) -> PackedVector3Array:
    var points := PackedVector3Array()
    var pos := start
    var dir := direction
    for i in 40:
        pos += dir * 0.2
        dir = (_warp(pos + dir * 0.1, k) - _warp(pos, k)).normalized()
        points.append(_warp(pos, k))
    return points
```

Forty steps per geodesic. Direction updates each step by tangent to the warped grid. The line walks the curvature rather than assuming it.

Label the three regimes.

```gdscript
func label_regime(k: float) -> void:
    if k < -0.1: regime_label.text = "hyperbolic"
    elif k > 0.1: regime_label.text = "elliptic"
    else: regime_label.text = "euclidean"
```

Hyperbolic, euclidean, elliptic. The slider passes through all three continuously. No regime is privileged.

Colour the floor by curvature sign.

```gdscript
func tint_floor(k: float) -> void:
    var mat: StandardMaterial3D = floor.material_override
    mat.albedo_color = Color(0.5 - k * 0.3, 0.5, 0.5 + k * 0.3)
```

Cool toward negative, warm toward positive. The learner's steps tell them which geometry they're inside.

You have moved continuously through three geometries. The next map, Russell Paradox, turns from geometry to logic and finds the first genuine contradiction.
<<</MAP>>>

<<<MAP: Russell_Paradox>>>
# Russell Paradox

The set of all sets that don't contain themselves. Build two boxes and the third box that breaks both.

Declare a set container.

```gdscript
class_name SetBox
extends Node3D

@export var members: Array[String] = []

func contains_self() -> bool:
    return members.has(label)
```

A box holds named members. `contains_self` checks whether the box's own label is in its own member list. Recursion as a property.

Populate two example boxes.

```gdscript
func populate() -> void:
    even_box.members = ["2", "4", "6"]
    boxes_box.members = ["box1", "box2", "boxes_box"]
```

The even-number box does not contain itself. The box-of-boxes does. Two clean examples before the paradox.

Build Russell's set.

```gdscript
func collect_non_self_containing(all_sets: Array[SetBox]) -> Array[String]:
    var out: Array[String] = []
    for s in all_sets:
        if not s.contains_self():
            out.append(s.label)
    return out
```

The filter returns all boxes that do not contain themselves. This list is the rule for the third box.

Create the paradox box.

```gdscript
func build_russell_box(all_sets: Array[SetBox]) -> void:
    russell.members = collect_non_self_containing(all_sets)
    russell.label = "russell"
```

Russell's box collects every non-self-containing box. Then ask whether it belongs to itself.

Check membership.

```gdscript
func russell_paradox() -> String:
    var in_self := russell.members.has("russell")
    if in_self:
        return "russell is in russell → russell must NOT contain itself"
    else:
        return "russell is not in russell → russell MUST contain itself"
```

Either answer produces the opposite requirement. The function returns the two halves of the paradox as a sentence.

Render the paradox as a spinning box.

```gdscript
func _process(dt: float) -> void:
    russell_mesh.rotation.y += dt * 0.6
    var t := sin(Time.get_ticks_msec() / 500.0)
    russell_mesh.scale = Vector3.ONE * (1.0 + 0.1 * t)
```

The box pulses because it cannot resolve. Its geometry is a visual restlessness.

Alarm when the learner opens the box.

```gdscript
func _on_russell_opened() -> void:
    alarm_sound.play()
    alarm_light.visible = true
    readout.text = russell_paradox()
```

The alarm is not playful. Naive set theory is broken at the foundation. The readout says so in full.

You have met the first genuine contradiction. The next map, Gödel Incompleteness, encodes logic in numbers and finds the limit even careful systems share.
<<</MAP>>>

<<<MAP: Godel_Incompleteness>>>
# Gödel Incompleteness

Encode statements as numbers. Build a statement that refers to its own unprovability and watch the system refuse to prove or disprove it.

Declare a Gödel encoding.

```gdscript
func godel_encode(statement: String) -> int:
    var primes := [2, 3, 5, 7, 11, 13, 17, 19, 23]
    var code := 1
    for i in statement.length():
        var ord_c: int = statement.unicode_at(i)
        code *= int(pow(primes[i % primes.size()], ord_c % 10))
    return code
```

A toy encoding using primes. Real Gödel numbering is more careful; the principle is the same. Statements become integers, and integers become arguments inside arithmetic.

Decode a code back to a key.

```gdscript
func godel_key(code: int) -> String:
    return "stmt_%d" % (code % 100000)
```

The decoded key is what the system uses to look up a statement. Lookup on integers is the trick that lets the system talk about itself.

Declare the self-referential statement.

```gdscript
const GODEL_STATEMENT := "This statement is not provable in this system."
var godel_code: int = 0

func prepare_godel() -> void:
    godel_code = godel_encode(GODEL_STATEMENT)
```

The statement is stored as text and as a code. The system can hold both representations and reason about the code numerically.

Run the proof search.

```gdscript
func search_proof(code: int, depth: int) -> String:
    var axioms := ["PA1", "PA2", "PA3", "PA4"]
    for step in depth:
        if _derives(axioms, code):
            return "proved"
    return "not found"
```

A finite search. The function returns either a proof or the absence of one within the depth budget. Gödel's theorem says the absence is permanent, not a budget issue.

Detect the impossibility.

```gdscript
func evaluate_godel() -> String:
    var result := search_proof(godel_code, 1000)
    if result == "proved":
        return "contradiction: system proved its own unprovability claim"
    else:
        return "incomplete: a true statement no proof can reach"
```

Either outcome is an incompleteness. The text says so. The formal system is closed; the question is not.

Render the verdict on the plaque.

```gdscript
func show_verdict(label: Label3D) -> void:
    label.text = evaluate_godel()
    label.modulate = Color(0.85, 0.85, 0.6)
```

Cream-yellow on a stone plaque. The verdict is not rewritten on each visit; the result is stable and inescapable.

Dim the lights on the verdict.

```gdscript
func dim_for_verdict() -> void:
    world_environment.environment.ambient_light_energy = 0.35
    spotlight_on_plaque.light_energy = 2.5
```

The ambient drops; a spot focuses on the plaque. The statement is a monument. Incompleteness is what the room is for.

You have encountered the hardest limit on formal systems. The next map, Escher Impossible, translates the limit into architecture the body can walk.
<<</MAP>>>

<<<MAP: Escher_Impossible>>>
# Escher Impossible

Local truth, global impossibility. Build a staircase where every step is correct and the whole cannot exist.

Declare the staircase graph.

```gdscript
class_name StairGraph
extends Node3D

const SIDES := [Vector3.FORWARD, Vector3.RIGHT, Vector3.BACK, Vector3.LEFT]

@export var rise_per_side: float = 1.0
```

Four sides, each rising by the same amount. The graph is a perimeter loop with monotonic height. Locally consistent by construction.

Place the corners.

```gdscript
func build_corners() -> void:
    var height := 0.0
    for i in SIDES.size():
        var corner := MeshInstance3D.new()
        corner.mesh = BoxMesh.new()
        corner.position = Vector3(i * 2, height, 0.0)
        height += rise_per_side
        add_child(corner)
```

Four corners, each raised by rise_per_side above the previous. Every edge feels like a normal staircase.

Connect the last corner back to the first.

```gdscript
func close_loop() -> void:
    var first := corners[0].position
    var last := corners[-1].position
    var line := ImmediateMesh.new()
    line.surface_begin(Mesh.PRIMITIVE_LINES)
    line.surface_add_vertex(last)
    line.surface_add_vertex(first)
    line.surface_end()
    loop_mesh.mesh = line
```

The edge from the last corner back to the first is the impossibility. Height has risen four times; the return edge must descend all four rises in one step or the loop does not close.

Hide the return seam.

```gdscript
func camouflage_seam(segment: MeshInstance3D, cam: Camera3D) -> void:
    var to_cam := (cam.global_position - segment.global_position).normalized()
    segment.visible = abs(to_cam.dot(Vector3.UP)) < 0.2
```

The seam only disappears from one viewing angle. The illusion depends on perspective. Move your head and the trick shows.

Simulate a creature walking the loop.

```gdscript
func step_creature(creature: Node3D, t: float) -> void:
    var idx := int(t) % corners.size()
    var next_idx := (idx + 1) % corners.size()
    creature.position = corners[idx].position.lerp(corners[next_idx].position, fmod(t, 1.0))
```

The creature walks forever. Each step is valid locally. The loop never ends because height climbs every leg.

Label each edge as locally valid.

```gdscript
func label_edge(label: Label3D, from: Vector3, to: Vector3) -> void:
    label.text = "Δh = %+0.2f" % (to.y - from.y)
    label.position = (from + to) * 0.5 + Vector3.UP * 0.5
```

Each edge reports its height change. All four read positive. The contradiction is global only; no edge is lying.

Show the global sum.

```gdscript
func show_global_sum(label: Label3D) -> void:
    var total := 0.0
    for i in corners.size():
        var a := corners[i].position
        var b := corners[(i + 1) % corners.size()].position
        total += b.y - a.y
    label.text = "loop Δh = %+0.2f" % total
```

The sum around the loop must be zero for the staircase to close. The plaque shows it is not. Gödel's result, rendered as a floor plan.

You have walked a local truth with a global impossibility. The next map, Brouwer Intuitionism, responds by restricting logic to what can be built.
<<</MAP>>>

<<<MAP: Brouwer_Intuitionism>>>
# Brouwer Intuitionism

No existence without construction. Build a room where claims are only valid if the learner assembles them step by step.

Declare an intuitionistic proposition.

```gdscript
class_name Proposition
extends Resource

@export var name: String = ""
@export var constructed: bool = false
@export var steps: Array[String] = []
```

A proposition has a name and a record of construction. It is not true until `constructed` flips. Proof is assembly, not assertion.

Instantiate a construction bench.

```gdscript
func begin_construction(prop: Proposition) -> void:
    prop.constructed = false
    prop.steps.clear()
    bench.display(prop)
```

The bench resets every time a proposition begins. No carryover from a previous proof. Each construction starts cold.

Append a step.

```gdscript
func add_step(prop: Proposition, step: String) -> void:
    prop.steps.append(step)
    bench.display(prop)
```

Each step is a text operation the learner performs. The display updates so the learner sees the proof growing in front of them.

Validate the construction.

```gdscript
func validate(prop: Proposition) -> bool:
    for required in required_steps_for(prop.name):
        if not prop.steps.has(required):
            return false
    prop.constructed = true
    return true
```

Required steps are listed per proposition. Missing any means the proposition stays unconstructed. No proof by absence.

Reject law of excluded middle.

```gdscript
func attempt_lem(prop: Proposition) -> String:
    if prop.constructed:
        return "true"
    return "not yet constructed"
```

Classical logic returns either "true" or "false" for every proposition. Brouwer's room returns "not yet constructed" instead of "false". The third option is the whole point.

Light the proposition when constructed.

```gdscript
func _on_prop_constructed(prop: Proposition) -> void:
    var light: OmniLight3D = lights[prop.name]
    light.light_energy = 2.5
    construction_chime.play()
```

Constructed propositions glow. Unbuilt ones stay dim. The room is a topology of what the learner has actually made.

Offer a palette of building blocks.

```gdscript
func present_blocks(panel: Node3D) -> void:
    for block_name in block_library:
        var block := preload("res://commons/artifacts/foundations/proof_block.tscn").instantiate()
        block.set_name(block_name)
        panel.add_child(block)
```

Blocks are physical. The learner assembles proofs by moving blocks onto the bench. Construction is a bodily act.

Refuse to finalize without all steps.

```gdscript
func _on_finalize_pressed(prop: Proposition) -> void:
    if validate(prop):
        lock_proof(prop)
    else:
        show_missing(prop)
```

Finalization either locks the proof or lists the missing steps. Errors are named, not silent. The rule is that claims require construction.

You have built without proving by contradiction. The next map, Florensky Paraconsistent, accepts contradictions without collapse.
<<</MAP>>>

<<<MAP: Florensky_Paraconsistent>>>
# Florensky Paraconsistent

Classical logic collapses from one contradiction. Florensky's supralogic holds both. Build a Schrödinger box where A and not-A coexist.

Declare the dual state.

```gdscript
class_name DualState
extends Resource

@export var value: String = ""
@export var anti_value: String = ""
@export var confidence: Vector2 = Vector2(0.5, 0.5)
```

Two values, two confidences. The resource holds both without preferring one. The observer decides what the reading means, later.

Initialise the Schrödinger box.

```gdscript
func initialise_box() -> void:
    dual.value = "alive"
    dual.anti_value = "dead"
    dual.confidence = Vector2(0.5, 0.5)
```

Equal confidence in both states. The box is properly superposed before any observation. Classical logic would already have panicked.

Render the box as a translucent sphere.

```gdscript
func render_box(mesh: MeshInstance3D) -> void:
    var mat := StandardMaterial3D.new()
    mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mat.albedo_color = Color(0.7, 0.5, 0.9, 0.4)
    mesh.material_override = mat
```

Lavender, translucent. The sphere is readable from every angle. Its colour shifts gently as confidences diverge.

Update confidence with a nudge.

```gdscript
func nudge(toward: String, amount: float) -> void:
    if toward == dual.value:
        dual.confidence.x = clamp(dual.confidence.x + amount, 0.0, 1.0)
        dual.confidence.y = 1.0 - dual.confidence.x
    else:
        dual.confidence.y = clamp(dual.confidence.y + amount, 0.0, 1.0)
        dual.confidence.x = 1.0 - dual.confidence.y
```

A nudge shifts confidence but never zeroes the opposite. Both sides stay in play. The system is tolerant of disagreement.

Run classical inference on the stable parts.

```gdscript
func safe_infer() -> Array[String]:
    var safe: Array[String] = []
    if dual.confidence.x > 0.9: safe.append(dual.value)
    if dual.confidence.y > 0.9: safe.append(dual.anti_value)
    return safe
```

Only near-certain claims pass to classical inference. The box shields the rest of the system from its own superposition.

Detect ex falso prevention.

```gdscript
func prevent_ex_falso(claim: String) -> bool:
    return claim in safe_infer()
```

Any derivation must cite a safe claim. Contradictions exist in the box; they cannot escape as "anything follows."

Render the two confidences on dials.

```gdscript
func update_dials(dual: DualState) -> void:
    alive_dial.value = dual.confidence.x
    dead_dial.value = dual.confidence.y
    sum_label.text = "Σ = %.2f" % (dual.confidence.x + dual.confidence.y)
```

Two dials, one sum. The sum is always 1.0; the distribution is what changes. The box is stable under contradiction.

You have held both A and not-A. The next map, Crisis Synthesis, gathers the four responses into a single architecture.
<<</MAP>>>

<<<MAP: Crisis_Synthesis>>>
# Crisis Synthesis

Four wings, one summit, one complete formula. Build the synthesis that turns crisis into capacity.

Declare the wing registry.

```gdscript
class_name WingRegistry
extends Node3D

const WINGS := {
    "russell": "paradox",
    "godel": "incompleteness",
    "brouwer": "construction",
    "florensky": "paraconsistency",
}
```

Four wings, four names, four words. The registry is the map key. Each wing hosts one artifact from the sequence.

Place the wings around the summit.

```gdscript
func place_wings() -> void:
    var angle := 0.0
    for key in WINGS:
        var wing := preload("res://commons/maps/elements/crisis_wing.tscn").instantiate()
        wing.position = Vector3(cos(angle) * 8.0, 0, sin(angle) * 8.0)
        wing.set_meta("key", key)
        add_child(wing)
        angle += TAU / WINGS.size()
```

Eight-metre radius around the summit. Equal spacing. No wing is privileged; each presents a distinct response to the crisis.

Render the summit formula.

```gdscript
func render_summit(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 80
    label.modulate = Color(1.0, 0.95, 0.8)
```

The complete formula for the first time. Earlier maps showed fragments. The summit holds the whole.

Wire the bifurcation diagram.

```gdscript
func update_bifurcation(diagram: MeshInstance3D, lambda_value: float) -> void:
    var samples: Array = []
    for i in 100:
        var x := float(i) / 100.0
        samples.append(Vector2(x, _logistic_step(lambda_value, x)))
    diagram.mesh = _mesh_from_samples(samples)
```

The bifurcation rides λ. Low λ is stable; moving λ up opens doublings and then chaos. The diagram explains the critical zones visually.

Slide λ and φ.

```gdscript
func _on_lambda_slider_moved(v: float) -> void:
    lambda_value = v
    update_bifurcation(bif_diagram, v)

func _on_phi_slider_moved(v: float) -> void:
    phi_value = lerp(-1.0, 1.0, v)
    update_wings(phi_value)
```

Each slider rewrites the summit's readout. The wings update to show what their response implies under the current parameters.

Open the wings by proximity.

```gdscript
func _on_player_near_wing(wing: Node3D) -> void:
    wing.set_meta("open", true)
    wing.play_open_animation()
```

Proximity is the trigger, not a button. Walking toward Gödel unlocks Gödel. The learner pieces the argument together at their own pace.

Mark completion on all four visits.

```gdscript
func mark_wing_visited(wing: Node3D) -> void:
    visited[wing.get_meta("key")] = true
    if visited.size() == WINGS.size():
        summit_light.light_energy = 4.0
```

All four wings must be visited before the summit lights fully. The formula only reads complete after every response to the crisis has been witnessed.

You have assembled the crisis into capacity. The next map, Chamber Foundations, embodies Gödel as a creature you cannot distinguish from itself.
<<</MAP>>>

<<<MAP: Chamber_Foundations>>>
# Chamber Foundations

Two overlapping ghosts. One is real, one is not. Build a chamber whose lesson is the impossibility of telling them apart from inside.

Declare the twin spawner.

```gdscript
class_name TwinSpawner
extends Node3D

@export var twin_scene: PackedScene
@export var offset: Vector3 = Vector3(0.2, 0.0, 0.0)
```

Two instances spawn from the same scene at a small offset. The offset keeps them distinct to the learner's eye but not to the system's classifier.

Spawn the twins.

```gdscript
func spawn_twins(parent: Node3D) -> void:
    var a := twin_scene.instantiate()
    var b := twin_scene.instantiate()
    a.position = Vector3.ZERO
    b.position = offset
    parent.add_child(a)
    parent.add_child(b)
    twins = [a, b]
```

The twins share the same class and the same behaviour. Only position differs. The chamber treats them as interchangeable.

Randomise which is real.

```gdscript
func assign_reality() -> void:
    var real_idx := randi() % twins.size()
    for i in twins.size():
        twins[i].is_real = (i == real_idx)
```

One twin is real; the other is a ghost. The system knows; the learner does not. The chamber refuses to disclose.

Render both identically.

```gdscript
func render_twin(twin: Node3D) -> void:
    twin.material_override = shared_material
    twin.modulate = Color(1.0, 1.0, 1.0, 0.7)
```

Identical translucency. Identical colour. Identical animation timings. The classifier has nothing to tell them apart with.

Reject attempts to probe reality.

```gdscript
func probe(twin: Node3D) -> String:
    if twin.is_real:
        return "ambiguous"
    return "ambiguous"
```

Both answers are the same. The function does not lie; the system genuinely does not distinguish. Gödel's theorem is spoken by the chamber's refusal.

Dispense the catalyst mode.

```gdscript
func give_catalyst() -> void:
    CatalystBracelet.enable_mode("suspend")
    bracelet_label.text = "suspend: accept the undecidable"
```

The catalyst mode is "suspend". It does not resolve the twin; it lets the learner act without resolution.

Check completion by suspension rather than kill.

```gdscript
func on_suspend_used(target: Node3D) -> void:
    if target in twins:
        all_suspended.append(target)
    if all_suspended.size() == twins.size():
        open_exit()
```

Suspending both twins opens the exit. Choosing one and attacking fails. Incompleteness becomes a practice of deferral.

Write the lesson on the threshold.

```gdscript
func write_threshold(label: Label3D) -> void:
    label.text = "some questions cannot be answered from inside"
    label.modulate = Color(0.9, 0.85, 0.7)
```

The sentence closes the sequence. Incompleteness is not an obstacle. It is a shape of the practice.

You have closed the Foundations Crisis sequence. The next sequences ask what you build once you accept that some questions stay open.
<<</MAP>>>
