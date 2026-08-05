# jelly_cube.gd
# A soft, deformable cube that jiggles when touched
# VR-enabled with physics parameter controls

extends Node3D

# @identity
# essence: SoftBody3D with spring-mass physics — stiffness, damping, and pressure_coefficient govern deformation response
# desire: to let you poke a translucent cube and feel its resistance change under your hands as you drag sliders between rigid and liquid
# critical_parameter: stiffness — at 0 the cube collapses into a puddle, at 1 it barely yields, the sweet spot between is where jelly lives
# triggers: hand collision with the SoftBody3D surface causes real-time vertex displacement; pressure slider inflates or deflates the volume
# emerges: at low stiffness and high pressure the cube becomes a breathing balloon; at low pressure it drapes over the pedestal like cloth
# needs: slider_horizontal [has] (stiffness, damping, pressure); push_button [has] (color cycle, reset); Label3D [has]
# relationships: introduces spring-mass foundation before cloth_straps and soft_mushroom; contrasts with rounded_softbody_test which adds strain visualization
# truth: elasticity is not a property of the object — it is a negotiation between the object's internal forces and whatever touches it

class_name JellyCube

# --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
# assay — what the apparatus does with a shape you just squashed.
#
# THE AXIS IS ON THE APPARATUS, NEVER ON THE STARTING CONDITIONS, and that rule is
# what makes this artifact promotable at all. Everything jelly_cube exposes today is
# a starting condition: stiffness, damping, pressure, mass. A soft body RELAXES —
# five cubes started five different ways settle into the same shape and photograph
# as one object five times — so a still of a physics parameter is a still of nothing.
# The pedestal is the thing that holds still, so the pedestal is the thing that can
# carry a claim, and the claim is that a laboratory decides what counts as a result.
#
#   none     nothing added. The specimen on its plinth, trust the eye. THE SHIPPED
#            LINEAGE, and the default: this branch builds no node at all.
#   gauge    a graduated column beside it with a cantilever arm reaching in and a
#            stylus dropped onto the cube — the shape gets a NUMBER.
#   control  an empty wire cage at the size the cube had before anything happened to
#            it, on its own witness plate — the shape gets a COMPARISON.
#   chart    a plotted board standing behind it carrying the settling trace, damped
#            onto the rest line — the shape gets a HISTORY, and what you are looking
#            at becomes the END of a line that was drawn.
#   vitrine  glass on four posts, capped and captioned — the shape gets a CANON, and
#            the demonstration stops being something you can reach into.
#
# The word and its five values are the soft-body bench family's, character for
# character: grab_jelly_bench, mass_spring_bench, energy_landscape_bench,
# membrane_bench, rigidity_dial_bench, abject_bench, octopus_bench, becoming_bench
# and tentacle_grab_bench all answer this question already, and jelly_cube stands in
# the same `softbodies` sequence as every one of them. The geometry below is the
# family's, re-dimensioned — that kit is drawn around a 0.5 m specimen on a 0.86 m
# bench top and this is a 0.3 m cube on a plinth whose top is y = 0 — so the SCALE
# is derived from cube_size while the proportions, the accent colours and the
# captions are the family's untouched. (The kit has been written longhand nine times
# now and still has no shared module; that is a real debt, recorded not paid here,
# because factoring it would edit nine shipped artifacts in a promotion pass.)
@export_enum("none", "gauge", "control", "chart", "vitrine") var assay: String = "none"
const ASSAYS: PackedStringArray = ["none", "gauge", "control", "chart", "vitrine"]

## Side length of the jelly cube in meters (0.1–1.0)
@export_range(0.1, 1.0, 0.01) var cube_size: float = 0.3

## Subdivisions per axis — more = smoother deformation but slower (1–8)
@export_range(1, 8) var subdivisions: int = 4

## Translucent color of the jelly surface (alpha < 1 for transparency)
@export var jelly_color: Color = Color(0.2, 0.9, 0.5, 0.8):
	set(value):
		jelly_color = value
		if _material:
			_material.albedo_color = value
			if emission_strength > 0:
				_material.emission = value

## Physics properties
@export_group("Physics")

## Spring stiffness — higher values resist deformation (0.0–1.0)
@export_range(0.0, 1.0, 0.01) var stiffness: float = 0.5:
	set(value):
		stiffness = clampf(value, 0.0, 1.0)
		if _soft_body:
			_soft_body.linear_stiffness = stiffness
		_sync_stiffness_slider()

## Velocity damping — higher values slow oscillation (0.0–0.1)
@export_range(0.0, 0.1, 0.001) var damping: float = 0.01:
	set(value):
		damping = clampf(value, 0.0, 0.1)
		if _soft_body:
			_soft_body.damping_coefficient = damping
		_sync_damping_slider()

## Internal pressure that inflates the soft body (0.0–5.0)
@export_range(0.0, 5.0, 0.1) var pressure: float = 1.0:
	set(value):
		pressure = clampf(value, 0.0, 5.0)
		if _soft_body:
			_soft_body.pressure_coefficient = pressure
		_sync_pressure_slider()

## Total mass of the soft body in kg (0.1–10.0)
@export_range(0.1, 10.0, 0.1) var mass: float = 1.0

## Appearance
@export_group("Appearance")

## Glow intensity — 0 disables emission (0.0–2.0)
@export_range(0.0, 2.0, 0.01) var emission_strength: float = 0.2

## Whether the jelly uses alpha transparency
@export var use_transparency: bool = true

var _soft_body: SoftBody3D
var _material: StandardMaterial3D
var _info_label: Label3D
var _color_index: int = 0
var _created_nodes: Array[Node] = []

# VR Controls
var _stiffness_slider: Node
var _damping_slider: Node
var _pressure_slider: Node
var _control_panel: Node3D

## Everything the `assay` axis builds hangs off this one pivot, so re-dressing the
## bench can never reach the soft body, the pedestal, the label or the rack. A
## teardown that restarted the SoftBody3D would be a physics reset disguised as a
## config call.
var _assay_root: Node3D

# Signal connections for cleanup
var _signal_connections: Array[Dictionary] = []


const JELLY_COLORS = [
	Color(0.2, 0.9, 0.5, 0.8),   # Green
	Color(0.9, 0.3, 0.5, 0.8),   # Pink
	Color(0.3, 0.5, 0.9, 0.8),   # Blue
	Color(0.9, 0.7, 0.2, 0.8),   # Orange
	Color(0.7, 0.3, 0.9, 0.8),   # Purple
]

func _ready() -> void:
	_read_dna_meta()
	_create_soft_body()
	_create_pedestal()
	_create_labels()
	_create_vr_controls()
	# ASSAY apparatus, appended LAST so every child index and position above is
	# untouched on the legacy path. "none" falls through and adds nothing at all.
	_assay_dressing()


## The grid sets `config_*` metadata BEFORE add_child, so this runs ahead of the
## build. An unknown word keeps the default; no metadata, no change — which is all
## four existing placements. The DNA sweep sets the @export directly instead, also
## before add_child, and lands in the same place.
func _read_dna_meta() -> void:
	if has_meta("config_assay"):
		var a: String = str(get_meta("config_assay")).strip_edges().to_lower()
		assay = a if ASSAYS.has(a) else assay

func _exit_tree() -> void:
	for conn in _signal_connections:
		var obj = conn["object"] as Object
		var sig = conn["signal"] as String
		var callable = conn["callable"] as Callable
		if is_instance_valid(obj) and obj.has_signal(sig):
			if (obj as Node).get(sig) is Signal or true:
				var s = Signal(obj, sig)
				if s.is_connected(callable):
					s.disconnect(callable)
	_signal_connections.clear()
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func _track_node(node: Node) -> void:
	_created_nodes.append(node)

func _track_signal(obj: Object, sig_name: String, callable: Callable) -> void:
	_signal_connections.append({"object": obj, "signal": sig_name, "callable": callable})

func _create_soft_body() -> void:
	_soft_body = SoftBody3D.new()
	_soft_body.name = "JellySoftBody"

	var box = BoxMesh.new()
	box.size = Vector3(cube_size, cube_size, cube_size)
	box.subdivide_width = subdivisions
	box.subdivide_height = subdivisions
	box.subdivide_depth = subdivisions
	_soft_body.mesh = box

	_soft_body.simulation_precision = 5
	_soft_body.total_mass = mass
	_soft_body.linear_stiffness = stiffness
	_soft_body.pressure_coefficient = pressure
	_soft_body.damping_coefficient = damping
	_soft_body.drag_coefficient = 0.0

	_soft_body.collision_layer = 1
	_soft_body.collision_mask = 393217  # Include hand layers

	_material = StandardMaterial3D.new()
	_material.albedo_color = jelly_color

	if use_transparency:
		_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED

	if emission_strength > 0:
		_material.emission_enabled = true
		_material.emission = jelly_color
		_material.emission_energy_multiplier = emission_strength

	_material.roughness = 0.2
	_material.metallic = 0.0

	_soft_body.material_override = _material
	_soft_body.position = Vector3(0, cube_size / 2 + 0.05, 0)

	add_child(_soft_body)
	_track_node(_soft_body)

func _create_pedestal() -> void:
	var pedestal = MeshInstance3D.new()
	pedestal.name = "Pedestal"

	var cylinder = CylinderMesh.new()
	cylinder.top_radius = cube_size * 0.6
	cylinder.bottom_radius = cube_size * 0.7
	cylinder.height = 0.04
	pedestal.mesh = cylinder

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.18)
	mat.metallic = 0.8
	mat.roughness = 0.3
	pedestal.material_override = mat

	pedestal.position = Vector3(0, -0.02, 0)
	add_child(pedestal)
	_track_node(pedestal)

	var static_body = StaticBody3D.new()
	static_body.name = "PedestalCollision"
	var collision = CollisionShape3D.new()
	var shape = CylinderShape3D.new()
	shape.radius = cube_size * 0.7
	shape.height = 0.04
	collision.shape = shape
	static_body.add_child(collision)
	static_body.position = Vector3(0, -0.02, 0)
	add_child(static_body)
	_track_node(static_body)

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, cube_size + 0.15, 0)
	_info_label.text = "JELLY CUBE\nTouch to deform"
	add_child(_info_label)
	_track_node(_info_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("JELLY CUBE", [
		[
			{"type": "slider_h", "label": "STIFF", "default": stiffness},
			{"type": "slider_h", "label": "DAMP", "default": damping / 0.1},
			{"type": "slider_h", "label": "PRESS", "default": pressure / 5.0},
		],
		[
			{"type": "button", "label": "COLOR"},
			{"type": "button", "label": "RESET"},
		],
	])
	_control_panel.position = Vector3(0, 0.04, cube_size * 0.7 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_track_node(_control_panel)

	_stiffness_slider = _control_panel.find_child("Param_0", true, false)
	if _stiffness_slider and _stiffness_slider.has_signal("slider_moved"):
		_stiffness_slider.slider_moved.connect(_on_stiffness_slider_moved)
		_track_signal(_stiffness_slider, "slider_moved", _on_stiffness_slider_moved)

	_damping_slider = _control_panel.find_child("Param_1", true, false)
	if _damping_slider and _damping_slider.has_signal("slider_moved"):
		_damping_slider.slider_moved.connect(_on_damping_slider_moved)
		_track_signal(_damping_slider, "slider_moved", _on_damping_slider_moved)

	_pressure_slider = _control_panel.find_child("Param_2", true, false)
	if _pressure_slider and _pressure_slider.has_signal("slider_moved"):
		_pressure_slider.slider_moved.connect(_on_pressure_slider_moved)
		_track_signal(_pressure_slider, "slider_moved", _on_pressure_slider_moved)

	var color_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if color_btn:
		var color_area: Node = color_btn.get_node_or_null("InteractableAreaButton")
		if color_area:
			color_area.button_pressed.connect(_on_color_pressed)
			_track_signal(color_area, "button_pressed", _on_color_pressed)

	var reset_btn: Node = _control_panel.find_child("Btn_1", true, false)
	if reset_btn:
		var reset_area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if reset_area:
			reset_area.button_pressed.connect(_reset_physics)
			_track_signal(reset_area, "button_pressed", _reset_physics)

func _sync_stiffness_slider() -> void:
	if _stiffness_slider and _stiffness_slider.has_method("set_normalized_value"):
		_stiffness_slider.set_normalized_value(stiffness)

func _sync_damping_slider() -> void:
	if _damping_slider and _damping_slider.has_method("set_normalized_value"):
		_damping_slider.set_normalized_value(damping / maxf(0.1, 0.0001))

func _sync_pressure_slider() -> void:
	if _pressure_slider and _pressure_slider.has_method("set_normalized_value"):
		_pressure_slider.set_normalized_value(pressure / maxf(5.0, 0.0001))

func _on_stiffness_slider_moved(_position) -> void:
	if _stiffness_slider and _stiffness_slider.has_method("get_normalized_value"):
		stiffness = _stiffness_slider.get_normalized_value()

func _on_damping_slider_moved(_position) -> void:
	if _damping_slider and _damping_slider.has_method("get_normalized_value"):
		damping = _damping_slider.get_normalized_value() * 0.1

func _on_pressure_slider_moved(_position) -> void:
	if _pressure_slider and _pressure_slider.has_method("get_normalized_value"):
		pressure = _pressure_slider.get_normalized_value() * 5.0

func _on_color_pressed(_button = null) -> void:
	_color_index = (_color_index + 1) % JELLY_COLORS.size()
	jelly_color = JELLY_COLORS[_color_index]

func _reset_physics(_button = null) -> void:
	stiffness = 0.5
	damping = 0.01
	pressure = 1.0

## Apply an impulse to the jelly (for poking)
func poke(_world_position: Vector3, _force: float = 2.0) -> void:
	if not _soft_body:
		return
	# SoftBody interaction handled by physics collision

func set_color(color: Color) -> void:
	jelly_color = color

func set_stiffness(value: float) -> void:
	stiffness = value

func set_pressure(value: float) -> void:
	pressure = value

func set_damping(value: float) -> void:
	damping = value

func apply_grid_config(config_data: Dictionary) -> void:
	# This was an empty `pass`, and every key a map could send was ignored. It still
	# ignores all of them but one: adding the physics knobs here would change what
	# existing placements look like, which is a regression rather than a promotion.
	#
	# Guarded three ways. The word must be one the code can build, it must actually
	# DIFFER from what is standing, and _ready must already have run — otherwise the
	# deferred call would dress a bench before the plinth exists. Nothing is torn
	# down but the assay pivot, so the soft body never restarts.
	if not config_data.has("assay"):
		return
	var a: String = str(config_data["assay"]).strip_edges().to_lower()
	if not ASSAYS.has(a) or a == assay:
		return
	assay = a
	if is_node_ready():
		_assay_dressing()


# ── ASSAY ────────────────────────────────────────────────────────────────
# The same settled cube, five times over, is a curiosity, a measurement, a
# difference, a record and an exhibit. Nothing about the soft body changes between
# them — no branch below touches _soft_body, _material or a single physics value.

const ASSAY_READ := Color(0.98, 0.74, 0.26)    # the instrument accent: readings and ink
const ASSAY_WIRE := Color(0.55, 0.88, 0.98)    # the reference standard's cool wire


## Where this artifact puts its apparatus. Its working surface is the plinth top at
## y = 0 (the cylinder sits at -0.02 and is 0.04 tall), the cube stands on it from
## 0.05 to cube_size + 0.05, and the VR rack occupies the front at +z — so the
## instruments take the back margin and the two flanks, and only the vitrine is
## allowed over the middle.
func _assay_dressing() -> void:
	if _assay_root != null and is_instance_valid(_assay_root):
		remove_child(_assay_root)
		_assay_root.queue_free()
	_assay_root = null
	if assay == "none":
		return                                  # the legacy lineage: nothing at all
	_assay_root = Node3D.new()
	_assay_root.name = "Assay"
	add_child(_assay_root)
	_track_node(_assay_root)

	# The family kit is drawn around a 0.5 m specimen; this one is cube_size. One
	# factor carries the whole re-dimensioning so the proportions stay the family's.
	var u: float = cube_size / 0.5
	var rad: float = cube_size * 0.7            # the plinth's own footprint radius
	var top: float = cube_size + 0.05           # the cube's crown
	match assay:
		"gauge":
			_assay_gauge(Vector3(-(rad + 0.12), 0.0, -0.10), rad + 0.09, u)
		"control":
			_assay_control(Vector3(rad + 0.14, 0.0, -0.08), u)
		"chart":
			_assay_chart(cube_size * 1.9, -(rad + 0.10), u)
		"vitrine":
			_assay_vitrine(Vector3(0.0, (top + 0.05) * 0.5, 0.0),
				Vector3(rad * 2.4, top + 0.05, rad * 2.4))
		_:
			pass


## GAUGE — a graduated column standing beside the plinth with a cantilever arm
## reaching in over the cube and a stylus dropping onto it. The plinth stops merely
## holding a shape and starts reporting a height.
func _assay_gauge(post: Vector3, reach: float, u: float) -> void:
	var steel: StandardMaterial3D = _a_mat(Color(0.42, 0.45, 0.50), 0.4, 0.6)
	var tick: StandardMaterial3D = _a_mat(Color(0.88, 0.88, 0.84), 0.5, 0.0)
	var read: StandardMaterial3D = _a_glow(ASSAY_READ, 0.95)
	var top_y: float = 0.58 * u
	_a_add(_a_box(Vector3(post.x, 0.015 * u, post.z), Vector3(0.17, 0.03, 0.17) * u, steel))
	_a_add(_a_box(Vector3(post.x, top_y * 0.5, post.z),
		Vector3(0.05 * u, maxf(top_y, 0.05 * u), 0.05 * u), steel))
	# Graduations up the inward face — every fifth one long and lit, the rest hairlines.
	for i in range(13):
		var ty: float = (0.02 + float(i) * 0.045) * u
		var tl: float = (0.085 if (i % 5) == 0 else 0.045) * u
		_a_add(_a_box(Vector3(post.x + 0.025 * u + tl * 0.5, ty, post.z),
			Vector3(tl, 0.008 * u, 0.012 * u), read if (i % 5) == 0 else tick))
	# The reading itself: a collar clamped on the column, an arm out over the cube, a
	# lit point, and a stylus dropped from it onto the jelly.
	var ay: float = 0.30 * u
	_a_add(_a_box(Vector3(post.x, ay, post.z), Vector3(0.09, 0.06, 0.09) * u,
		_a_mat(Color(0.20, 0.21, 0.25), 0.6, 0.0)))
	_a_add(_a_box(Vector3(post.x + reach * 0.5 + 0.03 * u, ay, post.z),
		Vector3(reach, 0.024 * u, 0.024 * u), read))
	_a_add(_a_sphere(Vector3(post.x + reach + 0.03 * u, ay, post.z), 0.028 * u, read))
	_a_add(_a_box(Vector3(post.x + reach + 0.03 * u, (ay + 0.10 * u) * 0.5, post.z),
		Vector3(0.012 * u, maxf(ay - 0.10 * u, 0.02 * u), 0.012 * u), read))
	_a_add(_a_label("GAUGE", Vector3(post.x, top_y + 0.07 * u, post.z), 11, ASSAY_READ))


## CONTROL — the reference the bench keeps beside the specimen: an empty cage at the
## size the cube had before anything happened to it, on its own witness plate. The
## settled shape stops being a thing and becomes a difference from something.
## The cage is cube_size EXACTLY — this artifact's plinth is empty enough to let the
## reference be literal rather than a token of one.
func _assay_control(at: Vector3, u: float) -> void:
	var pale: StandardMaterial3D = _a_mat(Color(0.80, 0.80, 0.76), 0.6, 0.0)
	var wire: StandardMaterial3D = _a_glow(ASSAY_WIRE, 0.9)
	_a_add(_a_box(Vector3(at.x, at.y + 0.02 * u, at.z),
		Vector3(cube_size * 1.5, 0.04 * u, cube_size * 1.5), pale))
	var s: float = cube_size * 0.5
	var cy: float = at.y + 0.05 * u + s
	var w: float = 0.009 * u
	for sx in [-s, s]:
		for sz in [-s, s]:
			_a_add(_a_box(Vector3(at.x + sx, cy, at.z + sz), Vector3(w, s * 2.0, w), wire))
	for sy in [-s, s]:
		for sz in [-s, s]:
			_a_add(_a_box(Vector3(at.x, cy + sy, at.z + sz), Vector3(s * 2.0, w, w), wire))
		for sx in [-s, s]:
			_a_add(_a_box(Vector3(at.x + sx, cy + sy, at.z), Vector3(w, w, s * 2.0), wire))
	for sx2 in [-s, s]:
		for sy2 in [-s, s]:
			for sz2 in [-s, s]:
				_a_add(_a_sphere(Vector3(at.x + sx2, cy + sy2, at.z + sz2), 0.016 * u, wire))
	_a_add(_a_label("CONTROL", Vector3(at.x, cy + s + 0.09 * u, at.z), 11, ASSAY_WIRE))


## CHART — a record board behind the plinth carrying the settling trace: an
## oscillation that damps out onto the rest line. The bench stops showing a state and
## starts keeping a history.
func _assay_chart(board_w: float, bz: float, u: float) -> void:
	var board_h: float = 0.52 * u
	var by: float = 0.06 * u + board_h * 0.5
	var frame: StandardMaterial3D = _a_mat(Color(0.26, 0.27, 0.31), 0.7, 0.0)
	var paper: StandardMaterial3D = _a_mat(Color(0.87, 0.86, 0.81), 0.85, 0.0)
	var rule: StandardMaterial3D = _a_mat(Color(0.58, 0.58, 0.54), 0.7, 0.0)
	var ink: StandardMaterial3D = _a_glow(ASSAY_READ, 1.0)
	var foot: float = by - board_h * 0.5
	for lx in [-board_w * 0.36, board_w * 0.36]:
		_a_add(_a_box(Vector3(lx, foot * 0.5, bz),
			Vector3(0.03 * u, maxf(foot, 0.02 * u), 0.03 * u), frame))
	_a_add(_a_box(Vector3(0.0, by, bz - 0.012 * u),
		Vector3(board_w + 0.04 * u, board_h + 0.04 * u, 0.016 * u), frame))
	_a_add(_a_box(Vector3(0.0, by, bz), Vector3(board_w, board_h, 0.012 * u), paper))
	var x0: float = -board_w * 0.42
	var x1: float = board_w * 0.42
	var y0: float = by - board_h * 0.34
	var y1: float = by + board_h * 0.34
	_a_add(_a_box(Vector3(0.0, y0, bz + 0.009 * u),
		Vector3(board_w * 0.86, 0.008 * u, 0.006 * u), rule))
	_a_add(_a_box(Vector3(x0, by, bz + 0.009 * u),
		Vector3(0.008 * u, board_h * 0.70, 0.006 * u), rule))
	for i in range(4):
		_a_add(_a_box(Vector3(0.0, lerpf(y0, y1, float(i + 1) / 5.0), bz + 0.008 * u),
			Vector3(board_w * 0.86, 0.003 * u, 0.004 * u), rule))
	# The trace is CLOSED FORM, not sampled from the running solver: a plot that came
	# out different on every launch would be noise wearing the costume of a record.
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(29):
		var f: float = float(i) / 28.0
		var v: float = exp(-3.4 * f) * cos(f * 13.0)
		pts.append(Vector3(lerpf(x0, x1, f), lerpf(y0, y1, 0.5 + v * 0.44), bz + 0.015 * u))
	for i in range(pts.size() - 1):
		_a_add(_a_seg(pts[i], pts[i + 1], 0.011 * u, ink))
	_a_add(_a_sphere(pts[pts.size() - 1], 0.015 * u, ink))
	_a_add(_a_label("CHART", Vector3(0.0, by + board_h * 0.5 + 0.07 * u, bz), 11, ASSAY_READ))


## VITRINE — a case. The demonstration stops being something you can reach into and
## becomes an exhibit: glass on four posts, a capping plate, a caption on the front
## rail. The jelly goes on wobbling inside and can no longer be touched.
func _assay_vitrine(c: Vector3, s: Vector3) -> void:
	var post: StandardMaterial3D = _a_mat(Color(0.30, 0.32, 0.36), 0.4, 0.6)
	var cap: StandardMaterial3D = _a_mat(Color(0.20, 0.21, 0.25), 0.7, 0.0)
	var hx: float = s.x * 0.5
	var hz: float = s.z * 0.5
	var y0: float = c.y - s.y * 0.5
	var y1: float = c.y + s.y * 0.5
	_a_add(_a_box(c, s, _a_glass(Color(0.72, 0.84, 0.95), 0.09)))
	for sx in [-hx, hx]:
		for sz in [-hz, hz]:
			_a_add(_a_box(Vector3(c.x + sx, c.y, c.z + sz), Vector3(0.024, s.y, 0.024), post))
	# Rails, not floors: a solid pan at the base would hide the plinth it stands on.
	for yy in [y0, y1]:
		for sz2 in [-hz, hz]:
			_a_add(_a_box(Vector3(c.x, yy, c.z + sz2), Vector3(s.x, 0.018, 0.018), post))
		for sx2 in [-hx, hx]:
			_a_add(_a_box(Vector3(c.x + sx2, yy, c.z), Vector3(0.018, 0.018, s.z), post))
	_a_add(_a_box(Vector3(c.x, y1 + 0.018, c.z), Vector3(s.x + 0.04, 0.022, s.z + 0.04), cap))
	_a_add(_a_box(Vector3(c.x, y0 + 0.05, c.z + hz + 0.012),
		Vector3(minf(s.x * 0.5, 0.34), 0.05, 0.010),
		_a_mat(Color(0.13, 0.14, 0.17), 0.8, 0.0)))
	_a_add(_a_label("VITRINE", Vector3(c.x, y0 + 0.05, c.z + hz + 0.030), 11,
		Color(0.90, 0.92, 0.97)))


# ── assay primitives ───────────────────────────────────────────────────
# Only the ASSAY block uses these; nothing above this line changes.

func _a_add(n: Node3D) -> void:
	_assay_root.add_child(n)


func _a_mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _a_glow(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.4
	m.emission_enabled = true
	m.emission = c
	# The cube itself ships with a faint glow; an unlit instrument beside a lit
	# specimen would read as a grey stick, so the floor keeps the reading readable.
	m.emission_energy_multiplier = energy if emission_strength > 0.0 else energy * 0.55
	return m


func _a_glass(c: Color, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.1
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _a_box(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


func _a_sphere(center: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


## One segment of the plotted trace. The whole chart lies in a plane at constant z,
## so a box turned about Z is enough — no general basis needed.
func _a_seg(a: Vector3, b: Vector3, w: float, mat: Material) -> MeshInstance3D:
	var d: Vector3 = b - a
	var mi: MeshInstance3D = _a_box((a + b) * 0.5, Vector3(maxf(d.length(), w), w, w), mat)
	mi.rotation.z = atan2(d.y, d.x)
	return mi


func _a_label(text: String, pos: Vector3, size: int, tint: Color) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = pos
	l.font_size = size
	l.pixel_size = 0.0016
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = tint
	l.outline_size = 5
	return l
