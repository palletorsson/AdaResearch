# MarchingCubesSculptVR.gd
# VR Paintable Marching Cubes - Paint in 3D with your controllers!
extends Node3D

# --- DNA (stage 2, promoted 2026-08-12) -------------------------------------
# WHAT THIS ARTIFACT ARGUES THAT NO OTHER ONE IN ISOSURFACES DOES. Every other
# field in this sequence is GIVEN: gyroid_demo's is a formula, animated_noise's is
# noise, fifteen_cases' is a lookup table, metaballs' is a fixed set of sources.
# This one's field is DEPOSITED — a hand puts material in and the extractor finds
# a boundary through whatever was put. So its axis is what the hand did.
#
# And the hand has only ever done one thing. TerrainGeneratorSculpt._ready (lines
# 15-27) lays six blobs climbing +y, commented "wide base / torso / shoulder /
# neck / top"; _create_terrain_generator below adds a seventh at the centre. That
# is the whole vocabulary this tool has ever been photographed with, in 13 map
# files, and it reads as a figure — which invites exactly the wrong conclusion,
# that marching cubes produces figures. It does not. It produces the boundary of
# whatever the field says, and the field says what the hand said.
#
# hand — WHAT THE HAND PUT INTO THE VOLUME. All four rungs use THE SAME SEVEN
#   DEPOSITS: the same six radii, computed by the generator's own expressions
#   (s = chunk_scale * 0.15, then 0.5/0.35/0.25/0.22/0.18/0.15 of it) plus the
#   same centre deposit at radius 0.3. Nothing about the amount of material, the
#   threshold or the sampling changes between them. Only the arrangement.
#     stack  SHIPPED. The six climbing +y with the big centre deposit through
#            them: one lump, taller than wide, reading as a standing form.
#     sweep  the same seven dragged along one horizontal arc that rises and
#            settles, heavy end at +x/-z tapering to -x/+z: one continuous
#            gesture ~1.9 units long and ~1.2 thick, where stack is ~1.2 x 1.33
#            and upright. The arc runs BROADSIDE to the sweep camera on purpose
#            — an earlier version ran along +x, which is 35 degrees off the
#            canonical view direction, and a gesture pointing at the lens is a
#            lump. Measured as silhouettes, that one cost half the axis: 4.4% of
#            frame against stack, where this one is 9.8%.
#     dab    the same seven pushed to seven of the volume's eight corners, spaced
#            so that no two of their extracted surfaces touch. SEVEN separate
#            closed surfaces where every other rung gives one. This is the honest
#            picture of what a deposit IS before anything fuses it, and it is the
#            rung that makes the point: the extractor did not build a body, it
#            found the boundary of what was there.
#     heap   the same seven piled low around the floor of the volume — a mound
#            with the top half of the box empty.
#
# WHY THE dab NUMBERS ARE WHAT THEY ARE, and they are not free. iso_level is 0.3
# and the SDF is a plain sphere distance, so every deposit renders at radius
# r + 0.3 — the smallest of the seven is a 0.345 ball, the largest a 0.6 ball,
# inside a box of half-extent 1.0. Two surfaces separated by a gap g are bridged
# by opSmoothUnion(k = scale * 0.06 = 0.12) when g <= k/2 = 0.06. The dab
# positions are each pushed to 0.96 - (r + 0.3) per axis (as close to the wall as
# the deposit can sit without being clipped by the sampled domain), which leaves a
# minimum surface gap of 0.073 between the big deposit and its nearest neighbour
# and >= 0.21 for every other pair. So dab genuinely separates, with about 20%
# margin on the tightest pair. These numbers are tuned against the shipped
# volume_size = 2.0 and iso_level = 0.3; they scale with chunk_scale and they do
# NOT survive a change of iso_level.
#
# WHAT IS DECLINED. paint_rate (line 9) is seconds between strokes — a rate, and
#   one that only ticks while a trigger is held, so it is invisible to a still.
#   brush_radius / _min / _max only rescale the deposit and self-cancel under an
#   AABB-fitted camera. iso_level (hardcoded 0.3 at _create_terrain_generator) is
#   the sequence's central question and WOULD bite hard, but on a union of blended
#   spheres it moves precisely what raymarched_metaballs / metaballs /
#   implicit_surface_modeling already own as `fusion` (53.15%) — how much the
#   field merges — and re-arguing a claim the sequence has already made is worse
#   than leaving a knob plain.
#
# FLAGGED, NOT PROPOSED. erase_mode is BROKEN, not merely unpromotable: line ~382
#   negates the radius to erase and the very next call passes abs() of it, so the
#   sign is discarded and erase ADDS material. volume_resolution (line 18) is
#   declared and read by nothing — the sampling is TerrainGeneratorBase's
#   num_voxels_per_axis, a const 64.
#
# DETERMINISM. The audit's 14 random calls are real and every one of them is in an
# interactive path (_input's KEY_R and the mouse handler, _regenerate_sculpture's
# three randf_range pairs). None runs during a capture, the build path contains no
# randf at all, and the four rungs are literal position tables — so this artifact
# needs NO seed export and none was added. Adding one would imply a randomness the
# axis does not use.
const HANDS: PackedStringArray = ["stack", "sweep", "dab", "heap"]

## Radii of the six seeded deposits, as fractions of s = chunk_scale * 0.15 —
## the same six numbers, in the same order, that TerrainGeneratorSculpt._ready
## uses. Every rung lays these; only the positions differ.
const DEPOSIT_FRACTIONS := [0.5, 0.35, 0.25, 0.22, 0.18, 0.15]

## The seventh deposit's radius, the literal this file has always passed.
const CENTRE_DEPOSIT_RADIUS: float = 0.3

## Positions for the three non-shipped gestures, in units of the volume's HALF
## extent (so [-1, 1] is exactly the domain the compute shader samples, and the
## layout scales with chunk_scale the way the seeded one does). Index 0-5 are the
## six seeded deposits in descending radius; index 6 is the centre deposit.
##
## `stack` is deliberately absent: it is not a table but a short-circuit, and its
## numbers are read back out of the generator's own seeding (see _stack_deposits)
## rather than retyped here, so the two cannot drift apart.
const HAND_LAYOUTS := {
	"sweep": [
		Vector3(-0.016, 0.150, 0.012),
		Vector3(-0.212, 0.156, 0.151),
		Vector3(-0.367, 0.122, 0.261),
		Vector3(-0.489, 0.072, 0.349),
		Vector3(-0.562, 0.031, 0.401),
		Vector3(-0.611, 0.000, 0.436),
		Vector3(0.342, 0.000, -0.244),
	],
	"dab": [
		Vector3(0.510, 0.510, 0.510),
		Vector3(0.555, 0.555, -0.555),
		Vector3(0.585, -0.585, 0.585),
		Vector3(-0.594, 0.594, 0.594),
		Vector3(-0.606, -0.606, 0.606),
		Vector3(-0.615, 0.615, -0.615),
		Vector3(-0.360, -0.360, -0.360),
	],
	"heap": [
		Vector3(-0.40, -0.50, 0.10),
		Vector3(0.38, -0.52, -0.16),
		Vector3(0.10, -0.55, 0.40),
		Vector3(-0.18, -0.56, -0.38),
		Vector3(0.26, -0.58, 0.30),
		Vector3(-0.30, -0.60, 0.26),
		Vector3(0.00, -0.36, 0.00),
	],
}

@export_category("Deposit")
@export_enum("stack", "sweep", "dab", "heap") var hand: String = "stack"

@export_category("Sculpting")
@export var brush_radius: float = 0.15
@export var brush_radius_min: float = 0.05
@export var brush_radius_max: float = 0.5
@export var paint_rate: float = 0.05  # Time between paint strokes
@export var erase_mode: bool = false  # When true, removes material

@export_category("Visuals")
@export var sculpt_color: Color = Color(0.4, 0.7, 0.9)
@export var show_brush_indicator: bool = true

@export_category("Volume")
@export var volume_size: float = 2.0  # Size of the sculpting volume in meters
@export var volume_resolution: int = 64  # Voxels per axis (affects detail)


# References
var terrain_generator: Node  # TerrainGeneratorSculpt
var brush_indicator: MeshInstance3D
var volume_bounds: MeshInstance3D
var _status_label: Label3D

# Controller tracking
var left_controller: Node3D
var right_controller: Node3D
var left_trigger_pressed: bool = false
var right_trigger_pressed: bool = false

# Paint timing
var left_paint_timer: float = 0.0
var right_paint_timer: float = 0.0

# VR control panel
var _control_panel: Node3D
var _btn_regen: Node3D
var _btn_clear: Node3D
var _btn_erase_toggle: Node3D
var _btn_brush_up: Node3D
var _btn_brush_down: Node3D

# State
var is_initialized: bool = false
var blobs_painted: int = 0

## The six deposits TerrainGeneratorSculpt._ready seeded, snapshotted verbatim the
## instant the generator entered the tree. This is where `hand = stack` comes from
## on a rebuild — the numbers are read back out of the generator's own code, never
## retyped here.
var _stack_deposits: Array[Vector4] = []

func _ready() -> void:
	print("MarchingCubesSculptVR: Initializing VR sculpting...")
	# BEFORE the build. GridInteractablesComponent stamps config_* metadata on the
	# artifact and only THEN adds it to the tree (_apply_artifact_config at line
	# 1195, add_child at line 1220), so a placement's `hand` is already on the node
	# here and the first build is the right one. The deferred apply_grid_config that
	# follows then finds an unchanged signature and returns without rebuilding.
	_read_metadata_overrides()
	_create_terrain_generator()
	_create_brush_indicator()
	_create_volume_bounds()
	_build_vr_controls()
	_build_status_label()
	_find_controllers()
	is_initialized = true
	_update_status_label()
	print("MarchingCubesSculptVR: Ready! Use triggers to paint in 3D.")

func _create_terrain_generator() -> void:
	# Load and instantiate the sculpt terrain generator
	var sculpt_script = load("res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Scripts/TerrainGeneratorSculpt.gd")
	if not sculpt_script:
		push_error("MarchingCubesSculptVR: Could not load TerrainGeneratorSculpt.gd")
		return

	terrain_generator = MeshInstance3D.new()
	terrain_generator.name = "SculptMesh"
	terrain_generator.set_script(sculpt_script)

	# Configure the generator
	terrain_generator.chunk_scale = volume_size  # 1:1 with VR volume (meters)
	terrain_generator.center_position = Vector3(0, 0, 0)  # Ground level
	terrain_generator.iso_level = 0.3
	terrain_generator.noise_scale = 0.0  # No noise - pure sculpting
	terrain_generator.invert_faces = true  # View from outside
	terrain_generator.continuous_update = true  # Needs re-render on each paint stroke

	# Material — glass wireframe shader (same as voxel_noise_demo)
	var shader = load("res://algorithms/proceduralgeneration/isosurfaces/marchingcave/Shaders/glass_wireframe.gdshader")
	if shader:
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("glass_color", sculpt_color)
		material.set_shader_parameter("outline_color", Color(1.0, 0.0, 0.5, 1.0))
		material.set_shader_parameter("outline_width", 1.5)
		terrain_generator.material_override = material
	else:
		# Fallback to simple material
		var material = StandardMaterial3D.new()
		material.albedo_color = sculpt_color
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		terrain_generator.material_override = material

	# add_child runs TerrainGeneratorSculpt._ready SYNCHRONOUSLY: it seeds its six
	# deposits and TerrainGeneratorBase._ready dispatches, syncs and builds the mesh
	# before this line returns.
	add_child(terrain_generator)

	# Snapshot the seeded gesture before anything is added to or cleared from it.
	_snapshot_seeded_gesture()

	# THE SEVENTH DEPOSIT, AND WHY IT NO LONGER WAITS TWO FRAMES. This used to be
	# `await process_frame` twice and then add_blob — which meant the mesh at frame
	# 0 was the six-blob figure and the seven-blob one only appeared once the
	# generator's async pipeline had come round again: 12 frames to the GPU sync
	# plus 90 to the mesh thread, ~1.7 s at 60 fps. capture_config_sweep settles for
	# 1.1 s, so the bench was photographing a half-built artifact, and a player
	# walking in saw the object change under them. The deposits are laid
	# synchronously now and the field is re-extracted once, in the same three calls
	# TerrainGeneratorBase._ready makes. The blob array ends up byte for byte what
	# it was — same values, same order — so the steady-state mesh is unchanged; only
	# the moment it exists moves, from ~frame 102 to frame 0.
	if terrain_generator.has_method("add_blob"):
		if hand == "stack":
			# SHORT-CIRCUIT. The generator's own six are already in the buffer,
			# untouched and in order, and this is the same single call with the same
			# literal radius the file has always made.
			terrain_generator.add_blob(Vector3(0, 0, 0), CENTRE_DEPOSIT_RADIUS)
		else:
			terrain_generator.clear_blobs()
			_lay_deposits()
		# Counted exactly as shipped: ONE. The seeded gesture has never been counted
		# as painted and is not counted in any rung either, so the status label reads
		# the same on all four tiles and the difference between them is the surface.
		blobs_painted += 1
		_reextract_field()

## Read the generator's own seeding back out of it, once, before anything touches
## the buffer. `stack` is defined as "whatever TerrainGeneratorSculpt._ready laid",
## not as a table in this file, so the shipped gesture cannot drift away from the
## rung that claims to be it.
func _snapshot_seeded_gesture() -> void:
	_stack_deposits.clear()
	if terrain_generator == null:
		return
	var seeded = terrain_generator.get("blobs_array")
	if seeded is Array:
		for b in seeded:
			if typeof(b) == TYPE_VECTOR4:
				_stack_deposits.append(b)


## Lay the seven deposits of the current `hand` into an EMPTY field. Same seven
## radii in every rung — the six from the generator's own expressions and the
## centre deposit's literal 0.3 — so only the arrangement is under the axis.
func _lay_deposits() -> void:
	if terrain_generator == null or not terrain_generator.has_method("add_blob"):
		return
	if hand == "stack":
		for b in _stack_deposits:
			terrain_generator.add_blob(Vector3(b.x, b.y, b.z), b.w)
		terrain_generator.add_blob(Vector3(0, 0, 0), CENTRE_DEPOSIT_RADIUS)
		return
	var table: Array = HAND_LAYOUTS.get(hand, HAND_LAYOUTS["sweep"])
	var half: float = float(terrain_generator.chunk_scale) * 0.5
	var s: float = float(terrain_generator.chunk_scale) * 0.15
	var origin: Vector3 = terrain_generator.center_position
	for i in range(DEPOSIT_FRACTIONS.size()):
		var p: Vector3 = table[i]
		terrain_generator.add_blob(origin + p * half, s * float(DEPOSIT_FRACTIONS[i]))
	var centre: Vector3 = table[DEPOSIT_FRACTIONS.size()]
	terrain_generator.add_blob(origin + centre * half, CENTRE_DEPOSIT_RADIUS)


## Re-extract the isosurface NOW — the same dispatch / sync / build triple
## TerrainGeneratorBase._ready() runs, so the mesh is complete before this frame
## is drawn instead of ~102 frames later.
##
## Guarded on the compute resources rather than trusted: init_compute() can fail
## (no rendering device, missing SPIRV) and its return value is not visible from
## here, and the sculpt subclass's run_compute() writes to blob_buffer without
## checking it. A half-initialised generator falls back to its own mesh and this
## returns without touching the device.
func _reextract_field() -> void:
	if terrain_generator == null:
		return
	if terrain_generator.get("rendering_device") == null:
		return
	var pipe_v = terrain_generator.get("pipeline")
	var blob_v = terrain_generator.get("blob_buffer")
	if typeof(pipe_v) != TYPE_RID or typeof(blob_v) != TYPE_RID:
		return
	var pipe_rid: RID = pipe_v
	var blob_rid: RID = blob_v
	if not pipe_rid.is_valid() or not blob_rid.is_valid():
		return
	if not terrain_generator.has_method("run_compute"):
		return
	terrain_generator.run_compute()
	terrain_generator.fetch_and_process_compute_data()
	terrain_generator.create_mesh()


func _create_brush_indicator() -> void:
	brush_indicator = MeshInstance3D.new()
	brush_indicator.name = "BrushIndicator"

	var sphere = SphereMesh.new()
	sphere.radius = brush_radius
	sphere.height = brush_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	brush_indicator.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.5, 0.0, 0.4)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.5, 0.0)
	mat.emission_energy_multiplier = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	brush_indicator.material_override = mat

	brush_indicator.visible = false
	add_child(brush_indicator)

func _create_volume_bounds() -> void:
	# Visual indicator of the sculpting volume
	volume_bounds = MeshInstance3D.new()
	volume_bounds.name = "VolumeBounds"

	var box = BoxMesh.new()
	box.size = Vector3(volume_size, volume_size, volume_size)
	volume_bounds.mesh = box

	var mat = StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.3, 0.3, 0.5, 0.1)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	volume_bounds.material_override = mat

	add_child(volume_bounds)

func _build_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("MARCHING CUBES", [
		[{"type": "button", "label": "REGEN"}],
		[{"type": "button", "label": "CLEAR"}],
		[{"type": "button", "label": "ERASE"}],
		[{"type": "button", "label": "BRUSH +"}],
		[{"type": "button", "label": "BRUSH -"}],
	])
	panel.position = Vector3(volume_size * 0.75, 0.0, -volume_size * 0.3)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)
	_control_panel = panel

	# Connect buttons
	_btn_regen = panel.find_child("Btn_0", true, false)
	if _btn_regen:
		var area = _btn_regen.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _regenerate_sculpture())

	_btn_clear = panel.find_child("Btn_1", true, false)
	if _btn_clear:
		var area = _btn_clear.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): clear_sculpture())

	_btn_erase_toggle = panel.find_child("Btn_2", true, false)
	if _btn_erase_toggle:
		var area = _btn_erase_toggle.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _toggle_erase())

	_btn_brush_up = panel.find_child("Btn_3", true, false)
	if _btn_brush_up:
		var area = _btn_brush_up.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _change_brush_size(0.03))

	_btn_brush_down = panel.find_child("Btn_4", true, false)
	if _btn_brush_down:
		var area = _btn_brush_down.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _change_brush_size(-0.03))

func _build_status_label() -> void:
	_status_label = Label3D.new()
	_status_label.name = "StatusLabel"
	_status_label.font_size = 28
	_status_label.pixel_size = 0.001
	_status_label.position = Vector3(0, -volume_size * 0.65, 0)
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.modulate = Color(0.9, 0.9, 1.0, 0.9)
	_status_label.text = "Initializing..."
	add_child(_status_label)

func _update_status_label() -> void:
	if not _status_label:
		return
	var mode_str = "ERASE" if erase_mode else "PAINT"
	var mode_color = "🔴" if erase_mode else "🟠"
	_status_label.text = "%s %s | Brush: %.2f | Blobs: %d" % [mode_color, mode_str, brush_radius, blobs_painted]

func _regenerate_sculpture() -> void:
	# Clear everything and regenerate with a fresh starting blob
	if terrain_generator and terrain_generator.has_method("clear_blobs"):
		terrain_generator.clear_blobs()
		blobs_painted = 0
		print("MarchingCubesSculptVR: Regenerating sculpture...")

		await get_tree().process_frame
		if terrain_generator.has_method("add_blob"):
			# Add a few random blobs for variety
			terrain_generator.add_blob(Vector3(0, 0, 0), 0.3)
			terrain_generator.add_blob(
				Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)),
				randf_range(0.1, 0.25)
			)
			terrain_generator.add_blob(
				Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)),
				randf_range(0.1, 0.2)
			)
			blobs_painted = 3
		_update_status_label()

func _toggle_erase() -> void:
	erase_mode = !erase_mode
	_update_brush_color()
	_update_status_label()
	print("Erase mode: ", "ON" if erase_mode else "OFF")

func _change_brush_size(delta: float) -> void:
	brush_radius = clampf(brush_radius + delta, brush_radius_min, brush_radius_max)
	_update_brush_size()
	_update_status_label()
	print("Brush radius: ", brush_radius)

func _find_controllers() -> void:
	# Try to find XR controllers in the scene tree
	await get_tree().process_frame

	# Search for controllers by common names
	var root = get_tree().root
	left_controller = _find_node_recursive(root, "LeftController")
	if not left_controller:
		left_controller = _find_node_recursive(root, "XRController3D")  # First one found
	if not left_controller:
		left_controller = _find_node_recursive(root, "LeftHand")

	right_controller = _find_node_recursive(root, "RightController")
	if not right_controller:
		right_controller = _find_node_recursive(root, "RightHand")

	if left_controller:
		print("MarchingCubesSculptVR: Found left controller: ", left_controller.name)
	if right_controller:
		print("MarchingCubesSculptVR: Found right controller: ", right_controller.name)

	if not left_controller and not right_controller:
		print("MarchingCubesSculptVR: No VR controllers found. Use keyboard: SPACE to paint, E to erase, +/- for brush size")

func _find_node_recursive(node: Node, name_contains: String) -> Node3D:
	if node.name.to_lower().contains(name_contains.to_lower()):
		if node is Node3D:
			return node
	for child in node.get_children():
		var found = _find_node_recursive(child, name_contains)
		if found:
			return found
	return null

func _process(delta: float) -> void:
	if not is_initialized:
		return

	# Update paint timers
	left_paint_timer += delta
	right_paint_timer += delta

	# Handle VR controller input
	_handle_vr_input(delta)

	# Handle keyboard input (fallback / desktop mode)
	_handle_keyboard_input(delta)

	# Update brush indicator
	_update_brush_indicator()

func _handle_vr_input(_delta) -> void:
	# Check for XR trigger actions
	if left_controller:
		var left_trigger: float = 0.0
		if InputMap.has_action("trigger_click"):
			left_trigger = Input.get_action_strength("trigger_click")
		if InputMap.has_action("trigger_left"):
			left_trigger = max(left_trigger, Input.get_action_strength("trigger_left"))

		if left_trigger > 0.5 and left_paint_timer >= paint_rate:
			_paint_at_controller(left_controller)
			left_paint_timer = 0.0

	if right_controller:
		var right_trigger: float = 0.0
		if InputMap.has_action("trigger_click"):
			right_trigger = Input.get_action_strength("trigger_click")
		if InputMap.has_action("trigger_right"):
			right_trigger = max(right_trigger, Input.get_action_strength("trigger_right"))

		if right_trigger > 0.5 and right_paint_timer >= paint_rate:
			_paint_at_controller(right_controller)
			right_paint_timer = 0.0

func _handle_keyboard_input(_delta) -> void:
	# Keyboard controls for desktop testing
	pass  # Handled in _input for key events

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				# Paint at center (desktop mode)
				_paint_at_position(Vector3(0, 0, 0))
			KEY_E:
				# Toggle erase mode
				_toggle_erase()
			KEY_EQUAL, KEY_KP_ADD:
				# Increase brush size
				_change_brush_size(0.02)
			KEY_MINUS, KEY_KP_SUBTRACT:
				# Decrease brush size
				_change_brush_size(-0.02)
			KEY_C:
				# Clear all blobs
				clear_sculpture()
			KEY_R:
				# Random paint at random position
				var pos = Vector3(
					randf_range(-volume_size/3, volume_size/3),
					randf_range(-volume_size/3, volume_size/3),
					randf_range(-volume_size/3, volume_size/3)
				)
				_paint_at_position(pos)

	# Handle mouse for desktop 3D painting
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			# Paint at a position based on mouse (simplified - center)
			_paint_at_position(Vector3(randf_range(-0.3, 0.3), randf_range(-0.3, 0.3), randf_range(-0.3, 0.3)))

func _paint_at_controller(controller: Node3D) -> void:
	if not controller:
		return

	# Get controller position in local space of the sculpt volume
	var world_pos = controller.global_position
	var local_pos = to_local(world_pos)

	_paint_at_position(local_pos)

func _paint_at_position(local_pos: Vector3):
	if not terrain_generator or not terrain_generator.has_method("add_blob"):
		return

	# Check if position is within volume bounds
	var half_size = volume_size / 2.0
	if abs(local_pos.x) > half_size or abs(local_pos.y) > half_size or abs(local_pos.z) > half_size:
		return  # Outside sculpting volume

	# Convert to generator's coordinate space
	# The generator uses a different scale internally
	var scale_factor = terrain_generator.chunk_scale / volume_size
	var gen_pos = local_pos * scale_factor

	# Add blob (positive radius adds material, negative could remove - but shader may not support)
	var effective_radius = brush_radius * scale_factor
	if erase_mode:
		effective_radius = -effective_radius  # Negative radius for erasing (if shader supports)

	terrain_generator.add_blob(gen_pos, abs(effective_radius))
	blobs_painted += 1
	_update_status_label()

	# Visual feedback
	if show_brush_indicator:
		brush_indicator.position = local_pos
		brush_indicator.visible = true
		# Flash effect
		var mat = brush_indicator.material_override as StandardMaterial3D
		if mat:
			mat.emission_energy_multiplier = 2.0
			await get_tree().create_timer(0.1).timeout
			if mat:
				mat.emission_energy_multiplier = 0.5

func _update_brush_indicator() -> void:
	if not show_brush_indicator:
		brush_indicator.visible = false
		return

	# Position indicator at active controller
	var active_controller = right_controller if right_controller else left_controller
	if active_controller:
		var local_pos = to_local(active_controller.global_position)
		brush_indicator.position = local_pos
		brush_indicator.visible = true
	else:
		brush_indicator.visible = false

func _update_brush_size() -> void:
	if brush_indicator and brush_indicator.mesh:
		var sphere = brush_indicator.mesh as SphereMesh
		if sphere:
			sphere.radius = brush_radius
			sphere.height = brush_radius * 2.0

func _update_brush_color() -> void:
	if brush_indicator and brush_indicator.material_override:
		var mat = brush_indicator.material_override as StandardMaterial3D
		if mat:
			if erase_mode:
				mat.albedo_color = Color(1.0, 0.2, 0.2, 0.4)  # Red for erase
				mat.emission = Color(1.0, 0.2, 0.2)
			else:
				mat.albedo_color = Color(1.0, 0.5, 0.0, 0.4)  # Orange for paint
				mat.emission = Color(1.0, 0.5, 0.0)

func clear_sculpture() -> void:
	if terrain_generator and terrain_generator.has_method("clear_blobs"):
		terrain_generator.clear_blobs()
		blobs_painted = 0
		print("MarchingCubesSculptVR: Sculpture cleared")

		# Add back a small starting blob
		await get_tree().process_frame
		if terrain_generator.has_method("add_blob"):
			terrain_generator.add_blob(Vector3(0, 0, 0), 0.2)
			blobs_painted = 1
		_update_status_label()

func get_blob_count() -> int:
	return blobs_painted

func reset() -> void:
	clear_sculpture()
	erase_mode = false
	brush_radius = 0.15
	_update_brush_size()
	_update_brush_color()
	_update_status_label()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## THE REBUILD GUARD. This was a bare `pass`, so no map could reach anything in
## this artifact. It now reads exactly one key, `hand`, and it returns early on an
## unchanged signature — which is the path all 13 existing placements take, since
## GridInteractablesComponent only calls this at all when a token carries config
## and not one of them does.
##
## Nothing is freed here. The rebuild replaces the CONTENTS of the generator's blob
## buffer and re-extracts; no node this script created is touched, and in
## particular the _RotationTimer that GridInteractablesComponent parents to this
## root after spawn survives untouched.
func apply_grid_config(config: Dictionary) -> void:
	var before: String = _config_signature()
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_metadata_overrides()
	if not is_initialized:
		# _ready has not run yet; it reads the metadata itself before building.
		return
	if _config_signature() == before:
		return
	_rebuild_deposits()


func _config_signature() -> String:
	return "%s|%.4f" % [hand, volume_size]


func _read_metadata_overrides() -> void:
	if has_meta("config_hand"):
		var h: String = str(get_meta("config_hand")).strip_edges().to_lower()
		if HANDS.has(h):
			hand = h


## Re-lay the field for a hand that arrived after the build. Only reachable when a
## placement names a `hand` this artifact was not built with.
func _rebuild_deposits() -> void:
	if terrain_generator == null or not terrain_generator.has_method("clear_blobs"):
		return
	terrain_generator.clear_blobs()
	_lay_deposits()
	blobs_painted = 1
	_reextract_field()
	_update_status_label()
