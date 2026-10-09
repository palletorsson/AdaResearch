extends Node3D

# @identity
# essence: c(t) = f·c(t-1) + i·tanh(W·[h,x]); h(t) = o·tanh(c(t)) — three gates control memory flow
# desire: walk inside a room-scale LSTM cell, grab the forget/input/output gates, watch memory particles flow
# critical_parameter: forget_gate_activation — controls how much the cell remembers vs forgets at each step
# triggers: gate height changes sphere appearance; particles follow a prescribed path independently of gates
# emerges: a diagram of retain/admit/expose relationships, not trained recurrent state
# needs: grabbable gate spheres [has], throwable input tokens [has], memory flow particles [has]
# relationships: unlocks transformers_vr (attention replaces recurrence); contrasts neural_networks_vr (feedforward has no memory)
# truth: memory is not storage — it is the continuous decision of what to keep and what to let go

# VR-Reimagined LSTM Networks Visualization
# Room-scale interactive LSTM cell where you can walk inside and manipulate gates
# Designed for educational VR experience

@export_group("VR Scale")
@export var cell_size: float = 3.0  # Room-scale cell (3m cube you can walk into)
@export var gate_size: float = 0.4  # Grabbable gate spheres
@export var token_size: float = 0.15  # Throwable input tokens

@export_group("Training Simulation")
@export var auto_train: bool = true
@export var training_speed: float = 0.1
@export var sequence_length: int = 8

@export_group("Interactive Elements")
@export var enable_gate_grabbing: bool = true
@export var enable_token_throwing: bool = true
@export var show_memory_particles: bool = true
@export var particle_count: int = 20

## RECURRENCE — a cell state that actually carries a past (2026-09-23).
##
## Until now this artifact was a diagram with three clocks bolted to it. Its own
## @identity header states the LSTM update as its essence and no such expression
## existed anywhere in the file: no state variable, no timestep, no weight. The hall
## said so too — "it does not yet carry an input sequence through a computed
## recurrent memory" — and named the fix. This is the fix.
##
## The rule is LINEAR and that is deliberate. A real LSTM squashes through tanh; this
## does not, because the whole encounter rests on an arithmetic the visitor can check:
## two histories differing at one earlier step diverge by exactly 2*f*i, so the forget
## gate sets HOW MUCH the past matters and at zero the two runs land identically.
## Squashing would hide that. Say it is linear; do not call it an LSTM.
##
## Gated, because lstms_vr also stands in MachineLearning_LSTMs and
## Ribbon_Machinelearnin_01 and neither asked for this.
@export var recurrent: bool = false

var cell_state: float = 0.0     # c — what survived
var hidden_out: float = 0.0     # h — what is exposed
var last_retain: float = 0.0    # f * c, the term that carries the past
var last_admit: float = 0.0     # i * x, the term that carries the present
var step_index: int = 0
var run_label: String = "—"
var _readout: Label3D
var _rail: Node3D


# State
var time: float = 0.0
var training_progress: float = 0.0
var loss_value: float = 1.0
var accuracy: float = 0.0

# Gate activations (can be controlled by VR interaction)
var forget_gate_activation: float = 0.5
var input_gate_activation: float = 0.5
var output_gate_activation: float = 0.5

# Memory flow particles
var memory_particles: Array = []
var input_tokens: Array = []
var output_tokens: Array = []

# Gate nodes for interaction
var forget_gate_body: RigidBody3D
var input_gate_body: RigidBody3D
var output_gate_body: RigidBody3D

func _ready() -> void:
	# Config arrives as meta BEFORE add_child in the grid lane, so read it first.
	if has_meta("config_recurrent"):
		recurrent = str(get_meta("config_recurrent")).to_lower() not in ["0", "false", "no"]
	_build_lstm_cell()
	_create_input_zone()
	_create_output_zone()
	_create_memory_flow()
	_create_interactive_gates()
	_create_training_controls()
	_create_info_panels()
	if recurrent:
		_make_reachable()
		_build_recurrent_readout()

func _process(delta: float) -> void:
	time += delta

	if auto_train:
		training_progress = min(1.0, training_progress + delta * training_speed)
		loss_value = max(0.1, 1.0 - training_progress * 0.8)
		accuracy = training_progress * 0.9

	_update_gate_activations(delta)
	_animate_memory_flow(delta)
	_update_cell_state_visual(delta)
	_update_training_metrics(delta)

func _build_lstm_cell() -> void:
	"""Create the main LSTM cell structure - large enough to walk into"""
	var cell_container = Node3D.new()
	cell_container.name = "CellStructure"
	add_child(cell_container)

	# Main cell core (wireframe cube you can walk into)
	var cell_mesh = MeshInstance3D.new()
	cell_mesh.name = "CellCore"
	var box = BoxMesh.new()
	box.size = Vector3(cell_size, cell_size, cell_size)
	cell_mesh.mesh = box

	# Transparent material so you can see through
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.8, 0.2, 0.2)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.2)
	mat.emission_energy_multiplier = 0.3
	mat.metallic = 0.0
	mat.roughness = 1.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # See from inside
	cell_mesh.material_override = mat

	cell_mesh.position = Vector3(0, cell_size/2, 0)
	cell_container.add_child(cell_mesh)

	# Create floor reference
	_create_floor_grid()

func _create_floor_grid() -> void:
	"""Create a floor grid for spatial reference"""
	var grid_size = 10
	var grid_spacing = 0.5

	for x in range(-grid_size, grid_size + 1):
		for z in range(-grid_size, grid_size + 1):
			if x % 2 == 0 and z % 2 == 0:
				var marker = MeshInstance3D.new()
				var sphere = SphereMesh.new()
				sphere.radius = 0.02
				sphere.height = 0.04
				marker.mesh = sphere

				var mat = StandardMaterial3D.new()
				mat.albedo_color = Color(0.3, 0.3, 0.3, 0.5)
				mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				mat.metallic = 0.0
				mat.roughness = 1.0
				marker.material_override = mat

				marker.position = Vector3(x * grid_spacing, 0, z * grid_spacing)
				add_child(marker)

func _create_interactive_gates() -> void:
	"""Create grabbable gate spheres positioned around the cell"""
	var gates_container = Node3D.new()
	gates_container.name = "InteractiveGates"
	gates_container.position = Vector3(0, cell_size/2, 0)
	add_child(gates_container)

	# Forget Gate (Left side, red)
	forget_gate_body = _create_gate_sphere(
		"ForgetGate",
		Vector3(-cell_size/2 - 0.6, 0.5, 0),
		Color(0.9, 0.2, 0.2),
		"Forget Gate"
	)
	gates_container.add_child(forget_gate_body)

	# Input Gate (Front, blue)
	input_gate_body = _create_gate_sphere(
		"InputGate",
		Vector3(0, 0.5, cell_size/2 + 0.6),
		Color(0.2, 0.4, 0.9),
		"Input Gate"
	)
	gates_container.add_child(input_gate_body)

	# Output Gate (Right side, green)
	output_gate_body = _create_gate_sphere(
		"OutputGate",
		Vector3(cell_size/2 + 0.6, 0.5, 0),
		Color(0.2, 0.9, 0.4),
		"Output Gate"
	)
	gates_container.add_child(output_gate_body)

func _create_gate_sphere(gate_name: String, pos: Vector3, color: Color, label: String) -> RigidBody3D:
	"""Create a single grabbable gate sphere"""
	var body = RigidBody3D.new()
	body.name = gate_name
	body.position = pos
	body.gravity_scale = 0.0  # Float in space
	body.lock_rotation = true

	# Mesh
	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = gate_size
	sphere.height = gate_size * 2.0
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	# Collision for physics
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = gate_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable (XRTools compatible layers)
	body.collision_layer = 1 | (1 << 20)  # Layer 1 and layer 21 (XRTools pickable)
	body.collision_mask = 1

	# Add label above gate
	var label_node = Label3D.new()
	label_node.text = label
	label_node.font_size = 32
	label_node.outline_size = 8
	label_node.outline_modulate = Color.BLACK
	label_node.modulate = Color.WHITE
	label_node.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_node.position = Vector3(0, gate_size + 0.3, 0)
	body.add_child(label_node)

	return body

func _create_input_zone() -> void:
	"""Create input token spawn zone (left side of room)"""
	var input_zone = Node3D.new()
	input_zone.name = "InputZone"
	input_zone.position = Vector3(-cell_size - 1.5, 1.0, 0)
	add_child(input_zone)

	# Zone marker
	var marker = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.1, 2.0)
	marker.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.3, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.9, 0.9, 0.3)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	marker.material_override = mat
	input_zone.add_child(marker)

	# Label
	var label = Label3D.new()
	label.text = "INPUT\nSEQUENCE"
	label.font_size = 48
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	input_zone.add_child(label)

	# Create throwable tokens
	for i in range(sequence_length):
		var token = _create_throwable_token(
			Vector3(0, 0.3 + i * 0.4, 0),
			Color(0.9, 0.9, 0.3)
		)
		input_zone.add_child(token)
		input_tokens.append(token)
		# x. Alternating so a visitor can pick a pale +1 or a dark -1 and build a history.
		token.set_meta("x", 1.0 if i % 2 == 0 else -1.0)
		if recurrent:
			var tm: StandardMaterial3D = StandardMaterial3D.new()
			tm.albedo_color = Color(0.93, 0.92, 0.85) if i % 2 == 0 else Color(0.22, 0.20, 0.28)
			tm.emission_enabled = true
			tm.emission = tm.albedo_color
			tm.emission_energy_multiplier = 0.5
			for c in token.get_children():
				if c is MeshInstance3D:
					c.material_override = tm

func _create_output_zone() -> void:
	"""Create output visualization zone (right side of room)"""
	var output_zone = Node3D.new()
	output_zone.name = "OutputZone"
	output_zone.position = Vector3(cell_size + 1.5, 1.0, 0)
	add_child(output_zone)

	# Zone marker
	var marker = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(1.0, 0.1, 2.0)
	marker.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.9, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.3, 0.9, 0.9)
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.0
	mat.roughness = 1.0
	marker.material_override = mat
	output_zone.add_child(marker)

	# Label
	var label = Label3D.new()
	label.text = "OUTPUT\nSEQUENCE"
	label.font_size = 48
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0, 1.0, 0)
	output_zone.add_child(label)

func _create_throwable_token(pos: Vector3, color: Color) -> RigidBody3D:
	"""Create a throwable input token"""
	var body = RigidBody3D.new()
	body.position = pos
	body.mass = 0.1

	var mesh = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = token_size
	sphere.height = token_size * 2.0
	mesh.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.6
	mat.metallic = 0.0
	mat.roughness = 1.0
	mesh.material_override = mat
	body.add_child(mesh)

	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = token_size
	collision.shape = shape
	body.add_child(collision)

	# Make grabbable and throwable
	body.collision_layer = 1 | (1 << 20)  # XRTools pickable
	body.collision_mask = 1

	return body

func _create_memory_flow() -> void:
	"""Create flowing memory particles through the cell"""
	if not show_memory_particles:
		return

	var particles_container = Node3D.new()
	particles_container.name = "MemoryParticles"
	add_child(particles_container)

	for i in range(particle_count):
		var particle = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.05
		sphere.height = 0.1
		particle.mesh = sphere

		var mat = StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.3, 0.9, 0.8)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.emission_enabled = true
		mat.emission = Color(0.9, 0.3, 0.9)
		mat.emission_energy_multiplier = 1.0
		mat.metallic = 0.0
		mat.roughness = 1.0
		particle.material_override = mat

		particles_container.add_child(particle)
		memory_particles.append({
			"node": particle,
			"progress": float(i) / particle_count,
			"height_offset": randf_range(-0.3, 0.3)
		})

func _create_training_controls() -> void:
	"""Create VR-accessible training control panel"""
	var controls = Node3D.new()
	controls.name = "TrainingControls"
	controls.position = Vector3(0, 1.7, -cell_size - 2.0)
	controls.rotation.y = PI
	add_child(controls)

	# Control panel background
	var panel = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(3.0, 1.5, 0.1)
	panel.mesh = box

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.3, 0.9)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.metallic = 0.0
	mat.roughness = 1.0
	panel.material_override = mat
	controls.add_child(panel)

	# Title
	var title = Label3D.new()
	title.text = "LSTM GATE DIAGRAM\nTrace the routes\nNo sequence is learned here"
	title.font_size = 32
	title.outline_size = 12
	title.position = Vector3(0, 0.0, 0.1)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	controls.add_child(title)

func _create_info_panels() -> void:
	"""Create floating info panels explaining LSTM components"""
	# Cell State info
	_create_info_panel(
		Vector3(0, cell_size + 0.5, 0),
		"CELL STATE\nLong-term Memory",
		Color(0.2, 0.8, 0.2)
	)

	# Hidden State info
	_create_info_panel(
		Vector3(0, cell_size + 0.5, -cell_size/2 - 1.0),
		"HIDDEN STATE\nShort-term Memory",
		Color(0.2, 0.8, 0.2)
	)

func _create_info_panel(pos: Vector3, text: String, color: Color) -> void:
	"""Create a floating information panel"""
	var label = Label3D.new()
	label.text = text
	label.font_size = 32
	label.outline_size = 8
	label.outline_modulate = Color.BLACK
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	add_child(label)

func _update_gate_activations(_delta) -> void:
	"""Update gate activations based on position or training"""
	if enable_gate_grabbing:
		# Gate activation based on how high the gate is raised
		# The datum was WORLD y, so the resting activation depended on the floor height of
		# whatever map this stood in rather than being the 0.5 the variable initialises to.
		# Measured in the artifact frame it is the same everywhere. Gated so the two other
		# placements keep the numbers they have always had.
		if forget_gate_body:
			forget_gate_activation = _gate_value(forget_gate_body)
		if input_gate_body:
			input_gate_activation = _gate_value(input_gate_body)
		if output_gate_body:
			output_gate_activation = _gate_value(output_gate_body)
	else:
		# Automatic activation patterns
		forget_gate_activation = sin(time * 1.5) * 0.5 + 0.5
		input_gate_activation = cos(time * 1.8) * 0.5 + 0.5
		output_gate_activation = sin(time * 2.0) * 0.5 + 0.5

	# Update gate visual intensity based on activation
	_update_gate_visual(forget_gate_body, forget_gate_activation, Color(0.9, 0.2, 0.2))
	_update_gate_visual(input_gate_body, input_gate_activation, Color(0.2, 0.4, 0.9))
	_update_gate_visual(output_gate_body, output_gate_activation, Color(0.2, 0.9, 0.4))

## A sphere height as a gate value. Manual, and meant to read as manual: nothing here
## is trained, and the number is simply where a hand left a ball.
func _gate_value(body: RigidBody3D) -> float:
	var y: float = to_local(body.global_position).y if recurrent else body.global_position.y
	return clamp((y - 1.0) / 2.0, 0.0, 1.0)


func _update_gate_visual(gate: RigidBody3D, activation: float, base_color: Color) -> void:
	"""Update gate sphere visual based on activation level"""
	if not gate:
		return

	var mesh = gate.get_node_or_null("MeshInstance3D")
	if mesh and mesh.material_override:
		var intensity = 0.3 + activation * 1.5
		mesh.material_override.emission_energy_multiplier = intensity

		# Scale based on activation
		var target_scale = 0.9 + activation * 0.3
		gate.scale = gate.scale.lerp(Vector3.ONE * target_scale, 0.05)

func _animate_memory_flow(delta) -> void:
	"""Animate memory particles flowing through the cell"""
	for particle_data in memory_particles:
		var particle = particle_data.node
		var progress = particle_data.progress

		# Update progress
		progress = fmod(progress + delta * 0.3, 1.0)
		particle_data.progress = progress

		# Path from input to output through cell center
		var start_pos = Vector3(-cell_size - 1.0, 1.0, 0)
		var end_pos = Vector3(cell_size + 1.0, 1.0, 0)

		# Sinusoidal height variation
		var height = cell_size/2 + sin(progress * PI * 3) * (cell_size/3) + particle_data.height_offset

		var x = lerp(start_pos.x, end_pos.x, progress)
		var y = height
		var z = sin(progress * PI * 2) * (cell_size/4)

		particle.position = Vector3(x, y, z)

		# Color based on position (fade from purple to cyan)
		var color_progress = progress
		var r = lerp(0.9, 0.3, color_progress)
		var b = lerp(0.3, 0.9, color_progress)
		particle.material_override.albedo_color = Color(r, 0.3, b, 0.8)
		particle.material_override.emission = Color(r, 0.3, b)

func _update_cell_state_visual(_delta) -> void:
	"""Update main cell visual based on training state"""
	var cell_core = get_node_or_null("CellStructure/CellCore")
	if cell_core and cell_core.material_override:
		var intensity = 0.3 + training_progress * 0.7
		cell_core.material_override.emission_energy_multiplier = intensity

func _update_training_metrics(_delta) -> void:
	if not recurrent:
		return
	_poll_tokens()
	_show_state()


## A token crossing into the cell IS the input. Edge-detected with a little hysteresis
## so a token resting on the boundary does not step the memory every frame.
func _poll_tokens() -> void:
	for token in input_tokens:
		if not is_instance_valid(token):
			continue
		var l: Vector3 = to_local(token.global_position)
		var was_in: bool = bool(token.get_meta("in_cell", false))
		var r: float = cell_size * 0.5 + (0.35 if was_in else 0.0)
		var inside: bool = absf(l.x) < r and absf(l.z) < r and l.y > -0.5 and l.y < cell_size
		if inside and not was_in:
			token.set_meta("in_cell", true)
			recurrent_step(float(token.get_meta("x", 1.0)))
		elif was_in and not inside:
			token.set_meta("in_cell", false)


## c drives the cube you can walk into; h drives the slab at the far end. Both were
## already here — the cube was tinted by a clock and the slab did nothing at all.
func _show_state() -> void:
	var core: Node = get_node_or_null("CellStructure/CellCore")
	if core and core.material_override:
		var warm: Color = Color(0.95, 0.35, 0.2)
		var cool: Color = Color(0.2, 0.55, 0.95)
		var t: float = clamp(cell_state * 0.5 + 0.5, 0.0, 1.0)
		core.material_override.emission = cool.lerp(warm, t)
		core.material_override.emission_energy_multiplier = 0.3 + absf(cell_state) * 0.9
	if is_instance_valid(_rail):
		_rail.position.y = clamp(hidden_out, -2.0, 2.0) * 0.9
	if is_instance_valid(_readout):
		_readout.text = ("step %d   %s\nretain f*c = %+.3f\nadmit  i*x = %+.3f\n"
			+ "c = %+.3f    h = %+.3f%s") % [step_index, run_label, last_retain, last_admit,
			cell_state, hidden_out, "   BEYOND ONE ADMISSION" if beyond_one_admission() else ""]

# Public API for external control
func set_training_progress(progress: float) -> void:
	training_progress = clamp(progress, 0.0, 1.0)

func reset_training() -> void:
	training_progress = 0.0
	loss_value = 1.0
	accuracy = 0.0
	time = 0.0

func get_gate_activations() -> Dictionary:
	return {
		"forget": forget_gate_activation,
		"input": input_gate_activation,
		"output": output_gate_activation
	}

## The rail and the readout. Both stand at the output end of the cell, where the
## artifact already put its output zone, so nothing new is introduced to the room —
## the slab that did nothing now rides h, and a band marks the height no single
## admission can reach.
## THE REACH. The gate spheres and the tokens were plain RigidBody3D with no script,
## and XR Tools rejects any grab target without a pick_up method
## (function_pickup.gd: "reject objects which don't support picking up"). So the one
## real computation in this artifact had no input in the headset: the spheres could be
## pushed on desktop and not touched at all in VR, under a source comment reading
## "XRTools pickable" and an @identity line claiming "grabbable gate spheres [has]".
##
## Giving them the addon's own pickable script is the whole repair. Gated with the
## rest, because the two other placements did not ask to become grabbable today —
## though they should, and the header is false in them until they do.
func _make_reachable() -> void:
	var pickable: GDScript = load("res://addons/godot-xr-tools/objects/pickable.gd")
	if pickable == null:
		push_warning("LSTMs_VR: XR Tools pickable.gd not found — gates stay desktop-only")
		return
	for body in [forget_gate_body, input_gate_body, output_gate_body]:
		if is_instance_valid(body) and body.get_script() == null:
			body.set_script(pickable)
	for token in input_tokens:
		if is_instance_valid(token) and token.get_script() == null:
			token.set_script(pickable)


func _build_recurrent_readout() -> void:

	if is_instance_valid(_readout):
		return
	var post := Node3D.new()
	post.name = "MemoryRail"
	post.position = Vector3(cell_size * 0.5 + 1.2, 0.0, 0.0)
	add_child(post)

	var stem := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.05, 4.0, 0.05)
	stem.mesh = sm
	stem.position = Vector3(0, 2.0, 0)
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.45, 0.47, 0.52)
	stem.material_override = stem_mat
	post.add_child(stem)

	# THE BAND. From a cleared state, |c| = |i*x| <= 1 and |h| = |o*c| <= 1, so this
	# height is unreachable in one step. Everything above it was carried.
	var band := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.22, (2.0 - MEMORY_ONLY) * 0.9, 0.22)
	band.mesh = bm
	band.position = Vector3(0, (MEMORY_ONLY + 2.0) * 0.5 * 0.9, 0)
	var band_mat := StandardMaterial3D.new()
	band_mat.albedo_color = Color(0.95, 0.72, 0.18, 0.35)
	band_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	band_mat.emission_enabled = true
	band_mat.emission = Color(0.95, 0.72, 0.18)
	band_mat.emission_energy_multiplier = 0.6
	band.material_override = band_mat
	post.add_child(band)

	var band_text := Label3D.new()
	band_text.text = "no single admission reaches this"
	band_text.font_size = 20
	band_text.outline_size = 6
	band_text.modulate = Color(0.95, 0.72, 0.18)
	band_text.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	band_text.position = Vector3(0, MEMORY_ONLY * 0.9 + 0.55, 0)
	post.add_child(band_text)

	# The slider that rides h.
	_rail = Node3D.new()
	_rail.name = "Exposed"
	post.add_child(_rail)
	var knob := MeshInstance3D.new()
	var km := BoxMesh.new()
	km.size = Vector3(0.5, 0.09, 0.5)
	knob.mesh = km
	var knob_mat := StandardMaterial3D.new()
	knob_mat.albedo_color = Color(0.3, 0.9, 0.9)
	knob_mat.emission_enabled = true
	knob_mat.emission = Color(0.3, 0.9, 0.9)
	knob_mat.emission_energy_multiplier = 0.8
	knob.material_override = knob_mat
	_rail.add_child(knob)

	_readout = Label3D.new()
	_readout.name = "StateReadout"
	_readout.font_size = 26
	_readout.outline_size = 8
	_readout.modulate = Color(0.85, 0.92, 1.0)
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.position = Vector3(0, 4.3, 0)
	_readout.text = "step 0
no token has crossed yet"
	post.add_child(_readout)

	# The signs this artifact was already hanging over nothing. Now they are true,
	# and the one that says no sequence is learned here stays true: none is.
	for label in find_children("*", "Label3D", true, false):
		if label == _readout or label == band_text:
			continue
		if "No sequence is learned here" in str(label.text):
			label.text = ("LSTM GATE DIAGRAM
The three spheres are set BY HAND
"
				+ "Nothing here is trained
c = f*c + i*x    h = o*c")


# -- the recurrence ----------------------------------------------------------


## One timestep. This is the whole computation, and every term in it is read at
## runtime: f, i and o are wherever the visitor left the three spheres, x is the
## token that just crossed in, and c is what the last step left behind.
func recurrent_step(x: float) -> void:
	last_retain = forget_gate_activation * cell_state
	last_admit = input_gate_activation * x
	cell_state = last_retain + last_admit
	hidden_out = output_gate_activation * cell_state
	step_index += 1


## Reset without a button: the rule already contains its own reset. With the forget
## and input spheres both on the floor, c = 0*c + 0*x = 0 on the very next token.
func recurrent_reset() -> void:
	cell_state = 0.0
	hidden_out = 0.0
	last_retain = 0.0
	last_admit = 0.0
	step_index = 0


## Feed a whole history at once, for a probe or a comparison. Returns h.
func run_history(xs: Array, label: String = "") -> float:
	recurrent_reset()
	for x in xs:
		recurrent_step(float(x))
	if label != "":
		run_label = label
	return hidden_out


## THE BAND. From a cleared state one admission cannot pass |h| = 1: |i| <= 1 and
## |x| <= 1 give |c| <= 1, and |o| <= 1 gives |h| <= 1. Anything beyond it was
## carried, not admitted. The rail paints that line so the reach is visible before
## anyone explains it.
const MEMORY_ONLY: float = 1.0

func beyond_one_admission() -> bool:
	return absf(hidden_out) > MEMORY_ONLY


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## Gated on the key: a config that does not mention recurrence gets no work at all,
## so the two other placements are the artifact that shipped.
func apply_grid_config(config: Dictionary) -> void:
	if not config.has("recurrent"):
		return
	var want: bool = str(config["recurrent"]).to_lower() not in ["0", "false", "no"]
	if want == recurrent:
		return
	recurrent = want
	if recurrent and is_inside_tree():
		_build_recurrent_readout()
