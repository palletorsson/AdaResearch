<<<ADA_BUNDLE>>>
sequence: qfeplaboratory
file: tutorial.md
maps: 9
<<</ADA_BUNDLE>>>

<<<MAP: QFEP_Introduction>>>
# QFEP Introduction

The formula arrives as four grabbable spheres on a plinth. Pick them up, read their names, feel the weights.

Declare a term sphere.

```gdscript
class_name TermSphere
extends RigidBody3D

@export var symbol: String = "F"
@export var description: String = ""
@export var base_color: Color = Color.WHITE
```

Each sphere is a RigidBody3D that carries a symbol and a description. The formula is a bag of four such spheres. Physics treats them as objects; the learner treats them as ideas.

Instantiate the four terms.

```gdscript
func build_formula(parent: Node3D) -> void:
    _add_term(parent, "F", "free energy", Color(0.9, 0.7, 0.3))
    _add_term(parent, "E", "entropy", Color(0.3, 0.6, 0.9))
    _add_term(parent, "λ", "order-chaos mix", Color(0.8, 0.4, 0.7))
    _add_term(parent, "φ", "rate sensitivity", Color(0.5, 0.9, 0.5))
```

Warm gold for F. Cool blue for E. Magenta for λ. Green for φ. The colour key stays stable across every map in the sequence.

Lay the spheres on a plinth.

```gdscript
func _add_term(parent: Node3D, sym: String, desc: String, col: Color) -> void:
    var sphere := preload("res://commons/artifacts/qfep/term_sphere.tscn").instantiate()
    sphere.symbol = sym
    sphere.description = desc
    sphere.base_color = col
    parent.add_child(sphere)
```

The helper loads the prefab and configures it from the scene. Changing term data means changing exports, not rewriting the artifact.

Render the symbol on the sphere.

```gdscript
func render_label(label: Label3D) -> void:
    label.text = symbol
    label.modulate = base_color
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
```

Billboarded labels stay readable at every angle. The sphere is both a body and a sign.

Speak the description when grabbed.

```gdscript
func _on_grabbed(_hand: Node) -> void:
    var panel: Label3D = get_tree().get_first_node_in_group("term_readout")
    panel.text = "%s — %s" % [symbol, description]
```

Grabbing a sphere publishes its meaning to a shared panel. The learner reads by touching. The formula becomes a conversation with the body.

Display the assembled formula.

```gdscript
func show_formula(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 64
    label.modulate = Color(1.0, 1.0, 0.95)
```

The full line hangs above the plinth. Learners see the whole before the parts. Later maps will isolate each term.

You have met the formula. The next map, F Term, zooms into free energy and the trap of pure order.
<<</MAP>>>

<<<MAP: QFEP_F_Term>>>
# F Term

F is free energy — the prediction error that every adaptive system tries to minimize. Build a room where minimizing F is both the task and the trap.

Declare the F meter.

```gdscript
class_name FMeter
extends Node3D

@export var prediction: float = 0.0
@export var observation: float = 0.0

func f_value() -> float:
    return abs(prediction - observation)
```

F is the distance between prediction and observation. The meter reads the absolute difference. Other formulations add log terms; this one is the floor model.

Crystallize particles to minimize F.

```gdscript
func settle_toward(target: Vector3) -> void:
    for particle in particles:
        var d := target - particle.position
        particle.linear_velocity += d * settle_strength
```

Particles drift toward a lattice point. The lattice is the prediction; the particle position is the observation. Over time, the cluster becomes a crystal.

Update F from the cluster state.

```gdscript
func update_f() -> void:
    var total := 0.0
    for particle in particles:
        total += particle.position.distance_to(target_for(particle))
    prediction = 0.0
    observation = total / particles.size()
```

Average distance from lattice gives the observation. Prediction is zero — the lattice is the expectation. F falls as the crystal forms.

Show the dark room.

```gdscript
func enter_dark_room() -> void:
    particles.clear()
    environment.ambient_light_energy = 0.0
    status_label.text = "F = 0.000  (nothing moves)"
```

A sealed room with no particles. F is zero. Nothing surprises the system because nothing happens. Perfect prediction, no life.

Gate progress on F curiosity.

```gdscript
func _on_dark_room_timer_timeout() -> void:
    if time_in_dark > 3.0:
        prompt.text = "F = 0 is also a grave."
        door.unlock()
```

The door only opens after the learner has stood in the zero-F room long enough to feel it. The prompt writes the lesson. F-minimization without entropy is closure.

Solve the snap puzzle to reduce F.

```gdscript
func _on_piece_snapped(piece: Node3D) -> void:
    score += 1
    prediction = float(score) / float(total_pieces)
    observation = 1.0
    meter.update_visual(f_value())
```

Each snapped piece reduces the gap between prediction and observation. The meter visibly drops. The learner's body performs the gradient descent.

Celebrate minimization and warn against it.

```gdscript
func on_puzzle_solved() -> void:
    play_chime()
    warning.text = "Beautiful. Now notice: nothing new can happen here."
```

The chime is the reward; the warning is the lesson. Closed puzzles are local optima. The F room tells the truth about both.

You have built the F side of the dialectic. The next map, E Term, introduces the counterweight: entropy as possibility.
<<</MAP>>>

<<<MAP: QFEP_E_Term>>>
# E Term

E(S) is the size of the possibility space. Build a room where freedom is felt as cubes refusing to stay still.

Declare the entropy meter.

```gdscript
class_name EMeter
extends Node3D

@export var sample_count: int = 256
var positions: PackedVector3Array = PackedVector3Array()

func entropy() -> float:
    return _spread(positions)
```

The meter holds recent positions and computes their spread. Spread is the entropy proxy; more spread means more possibility.

Spawn a cloud of random cubes.

```gdscript
func spawn_random() -> void:
    for i in sample_count:
        var cube := preload("res://commons/artifacts/qfep/entropy_cube.tscn").instantiate()
        cube.position = _sample_in_box()
        add_child(cube)
        positions.append(cube.position)
```

Each cube is placed inside the room's volume by rejection sampling. No two cubes share a target. The room begins in high entropy.

Kick every cube randomly per frame.

```gdscript
func _physics_process(_dt: float) -> void:
    for cube in cubes:
        cube.linear_velocity += Vector3(
            randf_range(-1.0, 1.0),
            randf_range(-0.5, 0.5),
            randf_range(-1.0, 1.0)
        )
```

Brownian kicks keep the entropy alive. Nothing settles. The room refuses to predict itself.

Compute spread as a proxy for E(S).

```gdscript
func _spread(pts: PackedVector3Array) -> float:
    if pts.is_empty(): return 0.0
    var mean := Vector3.ZERO
    for p in pts: mean += p
    mean /= pts.size()
    var total := 0.0
    for p in pts: total += mean.distance_squared_to(p)
    return sqrt(total / pts.size())
```

Standard deviation from the centre of mass. Not true Shannon entropy, but proportional in this volume. The meter updates each physics frame.

Render the meter as a glass column.

```gdscript
func update_visual(level: float) -> void:
    var mapped: float = clamp(level / max_spread, 0.0, 1.0)
    column.scale.y = mapped
    column.position.y = mapped * 0.5
```

The column rises and falls with the cloud. Entropy becomes posture in the room.

Offer a freeze button.

```gdscript
func _on_freeze_pressed() -> void:
    for cube in cubes:
        cube.freeze = true
    meter.update_visual(0.01)
```

Freezing the cubes collapses the cloud. The column shrinks. The learner sees that entropy is a rate, not a property.

Offer a release button.

```gdscript
func _on_release_pressed() -> void:
    for cube in cubes:
        cube.freeze = false
```

Released cubes resume Brownian motion. Entropy returns. The two buttons make the dialectic interactive.

You have built the E side of the dialectic. The next map, Lambda Spectrum, combines F and E into a walkable gradient.
<<</MAP>>>

<<<MAP: QFEP_Lambda_Spectrum>>>
# Lambda Spectrum

Your position is the λ value. Walk from crystal at λ=0 to dissolution at λ=1, through the edge of chaos in between.

Declare the lambda reader.

```gdscript
class_name LambdaReader
extends Node3D

@export var track_start: Vector3 = Vector3.ZERO
@export var track_end: Vector3 = Vector3(20.0, 0.0, 0.0)

func lambda_for(player_pos: Vector3) -> float:
    var total := track_start.distance_to(track_end)
    var here := track_start.distance_to(player_pos)
    return clamp(here / total, 0.0, 1.0)
```

A straight track with a start and end. Player position projects onto the track to yield λ. The reader is the only translator between body and number.

Sample the player every frame.

```gdscript
func _process(_dt: float) -> void:
    var l := lambda_for(player.global_position)
    lambda_label.text = "λ = %.2f" % l
    world.apply_lambda(l)
```

The label updates with each step. The world reshapes itself to match.

Shape the world by λ.

```gdscript
func apply_lambda(l: float) -> void:
    crystallizer.strength = 1.0 - l
    chaos_field.strength = l
    edge_field.strength = _edge_weight(l)
```

Three fields scale with λ. Order dominates near zero. Chaos dominates near one. Edge peaks in the middle.

Compute the edge weight.

```gdscript
func _edge_weight(l: float) -> float:
    return exp(-pow((l - 0.4) / 0.12, 2.0))
```

A Gaussian centred on λ=0.4 with tight sigma. The edge is narrow. Miss by 0.2 and complexity falls off sharply.

Populate the edge with living patterns.

```gdscript
func populate_edge() -> void:
    for i in 18:
        var pattern := preload("res://commons/artifacts/qfep/edge_creature.tscn").instantiate()
        pattern.position = Vector3(track_start.x + 8.0 + randf_range(-2, 2), 0, randf_range(-2, 2))
        add_child(pattern)
```

Eighteen small creatures live only in the middle band. Their meshes breathe. They vanish at either end.

Drain each creature's life by distance from the edge.

```gdscript
func update_creature(creature: Node3D, l: float) -> void:
    var life := _edge_weight(l)
    creature.scale = Vector3.ONE * life
    creature.modulate.a = life
```

Outside the edge band, the creatures shrink and fade. The learner watches complexity retreat as they step toward either end.

Mark the three stations.

```gdscript
func label_stations() -> void:
    crystal_sign.text = "λ = 0\ncrystal"
    edge_sign.text = "λ ≈ 0.4\nthe edge"
    dissolution_sign.text = "λ = 1\ndissolution"
```

Signs name the three regimes. The learner is not reading about them; the learner is standing in them.

You have walked the spectrum. The next map, Phi Term, adds the system's attitude toward movement along it.
<<</MAP>>>

<<<MAP: QFEP_Phi_Term>>>
# Phi Term

φ is the attitude toward change. Negative φ resists; positive φ welcomes. Build a room where your φ choice reshapes what the world lets you do.

Declare the phi dial.

```gdscript
class_name PhiDial
extends Node3D

signal phi_changed(value: float)

@export var value: float = 0.0

func set_value(v: float) -> void:
    value = clamp(v, -1.0, 1.0)
    phi_changed.emit(value)
```

One exported value, clamped to [-1, 1]. Negative resists, zero is neutral, positive welcomes. The signal is how the world hears it.

Grab the dial.

```gdscript
func _on_dial_grabbed(offset: float) -> void:
    set_value(value + offset * turn_gain)
    dial_label.text = "φ = %+.2f" % value
```

The learner turns a physical dial. Each degree updates φ. The label shows the sign explicitly because the sign is the lesson.

Apply φ to a morphing object.

```gdscript
func _on_phi_changed(v: float) -> void:
    morph_target.blend_shapes = _shape_for(v)
    morph_target.metallic = 0.3 + 0.5 * clamp(v, 0.0, 1.0)
```

The object becomes smoother and more iridescent as φ rises. Negative φ hardens it. Zero holds a neutral pose.

Let the rate of change matter.

```gdscript
func delta_energy(prev_state: float, state: float, dt: float) -> float:
    return (state - prev_state) / max(dt, 0.0001)
```

ΔE/Δt is the instantaneous rate. φ multiplies this rate. The formula's third term is a response to motion, not to position.

Accumulate the φ·ΔE contribution.

```gdscript
func phi_contribution(v: float, prev: float, state: float, dt: float) -> float:
    return v * delta_energy(prev, state, dt)
```

Positive φ amplifies fast change into reward. Negative φ amplifies it into penalty. The same rate becomes two very different forces depending on sign.

Paint the room's floor by φ sign.

```gdscript
func tint_floor(v: float) -> void:
    var mat: StandardMaterial3D = floor_mesh.material_override
    if v < 0.0:
        mat.albedo_color = Color(0.3, 0.2, 0.2)
    else:
        mat.albedo_color = Color(0.2, 0.3, 0.4)
```

Burgundy floor for preservation; cool blue for becoming. The room changes under the learner's feet with the dial.

Display the political reading.

```gdscript
func update_reading(v: float) -> void:
    if v < -0.2: reading.text = "conservative"
    elif v > 0.2: reading.text = "queer"
    else: reading.text = "neutral"
```

The reading names φ without euphemism. The formula is a politics; the dial lets the learner declare one.

You have built the attitude term. The next map, Edge Of Chaos, zooms into where φ-positive systems find their most productive balance.
<<</MAP>>>

<<<MAP: QFEP_Edge_Of_Chaos>>>
# Edge Of Chaos

λ near 0.4, φ positive, both held. Build the narrow band where Turing patterns, Langton's rules, and life itself live.

Declare the edge controller.

```gdscript
class_name EdgeController
extends Node3D

@export var lambda_value: float = 0.4
@export var phi_value: float = 0.6
@export var window: float = 0.12
```

Two live values and a tolerance. The controller holds the target and reports whether the learner is in the window.

Test the window.

```gdscript
func in_edge(l: float, p: float) -> bool:
    return abs(l - lambda_value) < window and p > 0.0
```

Inside the window means close to target λ and positive φ. Outside means nothing bad; only less complex. The edge is a location, not a judgement.

Drive a reaction-diffusion field by λ.

```gdscript
func step_rd(field: Image, l: float) -> void:
    var feed: float = 0.035 + l * 0.025
    var kill: float = 0.06 + l * 0.005
    _apply_rd(field, feed, kill)
```

Feed and kill parameters shift with λ. The Gray-Scott system produces spots, stripes, and dissolution across the swept range. The edge hosts the patterns.

Render the RD field to a floor texture.

```gdscript
func update_floor(field: Image) -> void:
    var tex := ImageTexture.create_from_image(field)
    floor_material.albedo_texture = tex
```

The texture updates live. The learner walks on the pattern. The pattern is λ made visible on the ground.

Spawn Langton ants at the edge.

```gdscript
func spawn_ants_if_edge(l: float, p: float) -> void:
    if not in_edge(l, p): return
    for i in 6:
        var ant := preload("res://commons/artifacts/qfep/langton_ant.tscn").instantiate()
        ant.position = Vector3(randf_range(-4, 4), 0.05, randf_range(-4, 4))
        add_child(ant)
```

Ants appear only when the conditions are met. They leave trails that remember the learner's location history. Rule 110 and Langton's ant both live in this neighbourhood.

Chime on entering the window.

```gdscript
func _on_window_entered() -> void:
    audio.stream = edge_chime
    audio.play()
    window_label.text = "you are at the edge"
```

The chime marks the threshold without spotlighting it. The window is a discovery, not a level.

Fade everything outside the window.

```gdscript
func _on_window_exited() -> void:
    for creature in creatures:
        creature.queue_free()
    rd_enabled = false
```

Leaving the edge clears the patterns. The learner sees complexity as something sustained, not something earned. Step back in and it returns.

You have inhabited the edge. The next map, Sandbox, removes every guardrail and gives the parameters to the learner.
<<</MAP>>>

<<<MAP: QFEP_Sandbox>>>
# Sandbox

No more guided tours. Every slider unlocked. Build the reactor that responds to whatever combination the learner invents.

Declare the reactor state.

```gdscript
class_name QFEPReactor
extends Node3D

@export var lambda_value: float = 0.4
@export var phi_value: float = 0.6
@export var f_weight: float = 1.0
@export var e_weight: float = 1.0
```

Four exports, all live. No hidden defaults. The reactor reads every parameter from its own properties each frame.

Wire sliders to the reactor.

```gdscript
func _on_lambda_slider_moved(v: float) -> void:
    reactor.lambda_value = v

func _on_phi_slider_moved(v: float) -> void:
    reactor.phi_value = lerp(-1.0, 1.0, v)
```

Two sliders, two writes. No validation gating. If the learner sets λ=1.0 and φ=-1.0, the world becomes a dark dissolution and teaches that setting exists.

Compute QFE from the live state.

```gdscript
func compute_qfe(prev_energy: float, energy: float, dt: float) -> float:
    var f := f_weight
    var e := e_weight * entropy_proxy()
    var delta_e := (energy - prev_energy) / max(dt, 0.0001)
    return f - lambda_value * e + phi_value * delta_e
```

The full formula runs inside the reactor loop. Every slider move changes the result. The display shows QFE as a number alongside its visual effect.

Display the number.

```gdscript
func update_readout() -> void:
    qfe_label.text = "QFE = %+.3f" % current_qfe
    qfe_label.modulate = Color(1.0, 0.6, 0.6) if current_qfe < 0.0 else Color(0.6, 1.0, 0.6)
```

Red for negative, green for positive. No moral valence; just a colour for sign. The learner sees their parameter choices as a scalar.

Translate QFE to world behaviour.

```gdscript
func apply_qfe(qfe: float) -> void:
    world_speed = clamp(0.5 + qfe * 0.5, 0.1, 3.0)
    particle_count_target = int(clamp(200 + qfe * 300, 30, 800))
```

Higher QFE means a livelier world. Lower means a quieter one. The mapping is intentionally simple so the learner can hear their own choices.

Reset to a known state.

```gdscript
func _on_reset_pressed() -> void:
    reactor.lambda_value = 0.4
    reactor.phi_value = 0.6
    reactor.f_weight = 1.0
    reactor.e_weight = 1.0
```

A reset button returns the reactor to the edge default. The learner can always come back. Experimentation is framed as safe.

Log each exploration.

```gdscript
func snapshot() -> void:
    sessions.append({
        "lambda": reactor.lambda_value,
        "phi": reactor.phi_value,
        "qfe": reactor.current_qfe,
        "time": Time.get_ticks_msec(),
    })
```

A snapshot records the live state. The learner leaves a trail of tested combinations. The trail is the curriculum now.

You have taken the force of QFEP. The next map, Synthesis, gathers the arc and hands the formula back as a tool.
<<</MAP>>>

<<<MAP: QFEP_Synthesis>>>
# Synthesis

The formula understood, not just intellectually but felt. Build the closing room where all four terms return as bodies.

Declare the synthesis plinth.

```gdscript
class_name SynthesisPlinth
extends Node3D

@export var terms: Array[Node3D] = []
@export var creature_path: NodePath
```

One plinth, four term bodies, one queer-morphology specimen. The plinth is the altar; the specimen is the living thesis.

Place the term bodies.

```gdscript
func place_terms() -> void:
    var angles := [0.0, 90.0, 180.0, 270.0]
    for i in terms.size():
        var a := deg_to_rad(angles[i])
        terms[i].position = Vector3(cos(a) * 1.2, 0.0, sin(a) * 1.2)
```

Four terms arranged at the corners of a square around the plinth. The learner walks between them reading. The arrangement invites pacing.

Render the formula line.

```gdscript
func show_formula(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 72
    label.modulate = Color(1.0, 1.0, 0.95)
```

The formula hangs above the plinth as it did in the Introduction. What returns is not the same; the learner now carries the terms.

Animate the queer-morphology specimen.

```gdscript
func _process(dt: float) -> void:
    var t := Time.get_ticks_msec() / 1000.0
    specimen.blend_shapes = Vector3(sin(t), cos(t * 0.7), sin(t * 1.3))
    specimen.scale = Vector3.ONE * (0.9 + 0.05 * sin(t * 0.5))
```

Breath-like blend shapes on the specimen. The morphology is never still. φ>0 made flesh.

Light the terms in sequence.

```gdscript
func sequence_lights() -> void:
    for i in terms.size():
        await get_tree().create_timer(0.5).timeout
        terms[i].emission = 1.5
        await get_tree().create_timer(0.3).timeout
        terms[i].emission = 0.5
```

A quiet choreography invites the learner to attend to each term in turn. The sequence runs once on entry and again on command.

Offer a personal phi signature.

```gdscript
func record_phi_signature(v: float) -> void:
    var signature := {"phi": v, "time": Time.get_unix_time_from_system()}
    UserSettings.set_value("qfep/phi_signature", signature)
```

The learner's chosen φ is saved as a signature. Future maps can read it. The force is not just understood; it becomes identity.

Write the threshold.

```gdscript
func write_threshold(label: Label3D) -> void:
    label.text = "carry it forward →"
    label.modulate = Color(0.9, 0.9, 0.9)
```

The exit sign is a charge, not a farewell. The learner leaves the laboratory with QFEP as a force they own.

You have completed the QFEP Laboratory. The final map, Chamber QFEP, gathers every befriended creature and every catalyst mode into one room.
<<</MAP>>>

<<<MAP: Chamber_QFEP>>>
# Chamber QFEP

All modes, all creatures, one room. Build the culminating chamber where befriending has already happened and recognition is the whole gesture.

Declare the chamber manifest.

```gdscript
class_name ChamberManifest
extends Resource

@export var creatures: PackedStringArray = PackedStringArray()
@export var catalyst_modes: PackedStringArray = PackedStringArray()
```

The manifest lists every creature and mode the arc befriended. The chamber reads the manifest to populate itself.

Load each befriended creature.

```gdscript
func spawn_creatures(parent: Node3D) -> void:
    for name in manifest.creatures:
        var path := "res://commons/creatures/%s.tscn" % name
        if ResourceLoader.exists(path):
            var c := load(path).instantiate()
            c.friendly = true
            parent.add_child(c)
```

Every creature arrives marked friendly. The friendly flag suppresses hostile behaviour trees. The creatures wander, not hunt.

Place them in a gathered ring.

```gdscript
func arrange_ring(nodes: Array[Node3D], radius: float) -> void:
    var n := nodes.size()
    for i in n:
        var a := TAU * i / n
        nodes[i].position = Vector3(cos(a) * radius, 0.0, sin(a) * radius)
```

Creatures occupy positions around a shared centre. The centre is where the formula lives. Arrangement is the argument: no one creature is at the head of the room.

Unlock every catalyst mode.

```gdscript
func unlock_all_modes() -> void:
    for mode in manifest.catalyst_modes:
        CatalystBracelet.enable_mode(mode)
    CatalystBracelet.current_mode = ""
```

All modes enabled, none selected. The bracelet rotates freely. The chamber does not ask for a choice; it offers the whole palette.

Write the full formula on the central plinth.

```gdscript
func render_central_formula(label: Label3D) -> void:
    label.text = "QFE = F − λ·E(S) + φ·ΔE(S,t)"
    label.font_size = 96
    label.modulate = Color(1.0, 0.95, 0.8)
```

A larger font than any earlier map. The formula is a monument here. The learner arrives knowing what it means.

Listen for greetings from the creatures.

```gdscript
func _on_creature_greeted(creature: Node3D) -> void:
    greetings_log.append(creature.name)
    if greetings_log.size() == manifest.creatures.size():
        open_final_door()
```

Each creature greets once. When every greeting is logged, the final door opens. Completion is recognition accumulated, not performance.

Dim the lights to memory.

```gdscript
func lower_lights() -> void:
    var env := world_environment.environment
    env.ambient_light_energy = 0.25
    env.fog_enabled = true
    env.fog_light_color = Color(0.5, 0.4, 0.6)
```

Warm violet fog replaces bright lab lighting. The laboratory has become a garden. The atmosphere is how memory feels.

Sound the arc closure.

```gdscript
func play_closing_tone() -> void:
    audio.stream = closing_drone
    audio.volume_db = -6.0
    audio.play()
```

A quiet drone marks the end of the formal arc. No fanfare. The chamber trusts the learner to notice what has ended.

You have closed the QFEP Laboratory arc. The next sequences ask what you do with this force once you have it.
<<</MAP>>>
