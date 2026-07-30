# boids_aquarium.gd
# Flocking simulation in a glass tank
# VR-enabled with parameter controls

extends Node3D

# @identity
# essence: v_i = w_sep·separate + w_align·align + w_coh·cohere, O(n) via spatial hash grid — Reynolds (1987) in a 1m cube
# desire: to peer through glass at thirty tiny creatures and realize the school has a shape, a mood, a personality — and you made it with three sliders
# critical_parameter: separation_weight — below 0.5 boids collapse into a clump; above 3.0 they scatter into permanent isolation; the narrow band between is life
# triggers: dragging SEP slider to max produces cold dispersal; dragging COH to max produces a pulsing sphere; ALIGN at max produces a synchronized arrow of motion
# emerges: rotating toroids, figure-eight loops, and sudden directional consensus events — the tank finds shapes the designer never chose
# needs: [has] VR sliders for separation, alignment, cohesion; [has] reset push button; [missing] no speed slider; no perception_radius slider
# relationships: shares Reynolds rules with boid_manager but adds glass-tank scale and O(n) grid optimization; contrasts with stigmergy_grid (social vs. environmental memory)
# truth: the boundary of the tank is the only rule that is truly external — every other behavior is the boids talking to each other
#
# ── STAGE-2 DNA: `accord` ──────────────────────────────────────────────────
#
# The header above says the narrow band between clump and scatter is where life
# is, and until now no map could stand on either side of that band — every
# placement showed the same balanced school. `accord` is the collective noun for
# what neighbours have agreed, which is precisely the thing that is not
# agreement: which of Reynolds' three rules the neighbourhood is actually
# obeying, and therefore what standing shape the flock holds. The values name
# the FLOCK, not the slider, so the still can be read without the code.
#
# WHY THE DEPOSITS ARE WHAT THEY ARE. The capturer waits ~1.1 s and shoots, so
# the axis has to be legible in the STANDING configuration, not after a long
# run. Every value is deposited arithmetically — no pre-roll, no convergence
# loop — and each deposit had to be a genuine fixed point of its own rule set or
# it melts into the school before the shutter opens. Three of the four sets of
# weights first written for this axis were measured against this exact update
# loop and did NOT hold; the notes on each branch of `_accord_weights()` record
# what was measured and what had to change. The shapes are the contract. The
# weights are whatever actually produces them.

class_name BoidsAquarium

## Tank dimensions (1m cube)
@export var tank_size: Vector3 = Vector3(1.0, 1.0, 1.0)

## Boid count
@export_range(10, 200) var boid_count: int = 30

## Which of Reynolds' three rules the neighbourhood is actually obeying, and
## therefore what standing shape the flock holds.
##   school  — the shipped balance: an irregular cloud, needles every which way
##   orb     — cohesion alone: one bright bead ~0.20 m across at tank centre
##   lane    — alignment alone: a 0.12 m thick sheet of parallel needles
##   lattice — separation alone: three even ranks of five, doubled in depth
@export_enum("school", "orb", "lane", "lattice") var accord: String = "school"

## Flocking parameters
@export_group("Flocking")
## How strongly boids push away from nearby neighbors (0=none, 5=max)
@export_range(0.0, 5.0, 0.1) var separation_weight: float = 1.5:
	set(value):
		separation_weight = clampf(value, 0.0, 5.0)
		_update_boid_params()
		_sync_separation_slider()

## How strongly boids match neighbors' heading (0=none, 5=max)
@export_range(0.0, 5.0, 0.1) var alignment_weight: float = 1.0:
	set(value):
		alignment_weight = clampf(value, 0.0, 5.0)
		_update_boid_params()
		_sync_alignment_slider()

## How strongly boids steer toward the flock center (0=none, 5=max)
@export_range(0.0, 5.0, 0.1) var cohesion_weight: float = 1.5:
	set(value):
		cohesion_weight = clampf(value, 0.0, 5.0)
		_update_boid_params()
		_sync_cohesion_slider()

## Maximum boid velocity in meters per second
@export_range(0.1, 1.5, 0.1) var max_speed: float = 0.5:
	set(value):
		max_speed = clampf(value, 0.1, 1.5)
		_update_boid_params()

## How far each boid can see neighbors (meters)
@export_range(0.01, 0.5, 0.01) var perception_radius: float = 0.15

## Visual
@export_group("Visual")
## Dimensions of each boid mesh (x, y, z in meters)
@export var boid_size: Vector3 = Vector3(0.008, 0.008, 0.025)
## Alpha transparency of boid meshes (0=invisible, 1=opaque)
@export_range(0.0, 1.0, 0.05) var boid_transparency: float = 0.7
## Alpha transparency of glass tank panels (0=invisible, 1=opaque)
@export_range(0.0, 1.0, 0.05) var tank_transparency: float = 0.15


# ═══════════════════════════════════════════════════════════════════
# ACCORD — the allow-list, the deposits, the rule sets
# ═══════════════════════════════════════════════════════════════════

const ACCORDS: PackedStringArray = ["school", "orb", "lane", "lattice"]

## The sanctioned framer for hanging captions. Only used after a config-driven
## rebuild, to re-plate the info label the grid had already framed once — never
## in _ready(), where the grid does it for us.
const LabelFramerScript: GDScript = preload("res://commons/grid/LabelFramer.gd")

## Every draw in the build path comes from one of these two generators, seeded
## from a fixed constant. The global seed()/randomize() is NEVER called — that
## would reseed the whole process from inside one artifact.
const DEPOSIT_SEED: int = 1987          # Reynolds, "Flocks, Herds and Schools"
const COLOUR_SEED: int = 30             # colour is not the axis: same in all four

const GOLDEN_ANGLE: float = 2.399963229728653   # PI * (3 - sqrt(5))

## orb — ball radius as a fraction of tank width. 0.12 (not the 0.10 first
## written) because pure cohesion breathes: measured over 0..4 s the ball
## oscillates between 0.15 and 0.23 m across, which reads as the intended
## ~0.20 m bead. At 0.10 it settles nearer 0.16; at 0.16 it is unstable and
## has grown past 0.36 by 1.6 s.
const ORB_RADIUS_FRAC: float = 0.12

## lane — slab proportions of the tank, and the deposit heading speed. 0.12 m/s,
## not max_speed: at 0.5 m/s the whole sheet translates 0.55 m inside a 0.9 m
## box during the capture wait and piles against the +X glass (measured X extent
## 0.36 m at 1.1 s, centroid +0.26). At 0.12 m/s the sheet is still tank-wide at
## 1.1 s (X 0.71, Z 0.84) and still 0.120 m thick.
const LANE_SLAB_FRAC: Vector3 = Vector3(0.84, 0.12, 0.84)
const LANE_SPEED: float = 0.12
const LANE_COLS: int = 6
const LANE_ROWS: int = 5

## lattice — 5 x 3 x 2 sites spanning this fraction of the tank (spacing
## 0.20 / 0.30 / 0.44 m at tank 1.0), plus the drift that keeps the needles
## pointing in thirty different directions. Drift 0.03 m/s, not 0.05: at 0.05 the
## ranks have blurred by 0.055 m at 1.1 s; at 0.03 the grid is still crisp
## (measured 0.85 x 0.66 x 0.50 at 1.1 s against a 0.80 x 0.60 x 0.44 deposit).
const LATTICE_NX: int = 5
const LATTICE_NY: int = 3
const LATTICE_NZ: int = 2
const LATTICE_SPAN_FRAC: Vector3 = Vector3(0.80, 0.60, 0.44)
const LATTICE_DRIFT: float = 0.03

## Caption geometry. The info label hangs above the tank top with air under it;
## the scene's "BOIDS" label lies flat on the outer face of the front pane.
const INFO_LABEL_LIFT: float = 0.17     # above tank top -> y 0.67 on a 1.0 tank
const INFO_COLS: int = 24               # every line padded to this, at every value
const FRONT_LABEL_PROUD: float = 0.005  # pane half-thickness 0.0025 + 0.0025 clear

var _boids: Array = []
var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _info_label: Label3D
var _created_nodes: Array[Node] = []

var _built: bool = false
var _emissive: bool = true

## The authored weights, snapshotted once before `accord` ever touches them, so
## `school` restores the PRE-PROMOTION look exactly — whatever the scene file or
## the inspector actually set, not what the script's own defaults happen to say.
## (boids_aquarium.tscn ships cohesion_weight = 1.0 and perception_radius = 0.2,
## both different from the script defaults. Hard-coding "the default triple"
## would have silently changed every shipped placement.)
var _base_sep: float = 0.0
var _base_ali: float = 0.0
var _base_coh: float = 0.0
var _base_perception: float = 0.0
var _base_captured: bool = false

# Spatial hash grid for O(n) neighbor lookup
var _grid: Dictionary = {}  # Vector3i -> Array[int] (boid indices)
var _cell_size: float = 0.15  # Will be set to perception_radius

# VR Controls
var _separation_slider: Node
var _alignment_slider: Node
var _cohesion_slider: Node
var _control_panel: Node3D


class BoidData:
	var position: Vector3
	var velocity: Vector3

	func _init(pos: Vector3, vel: Vector3):
		position = pos
		velocity = vel


func _ready() -> void:
	_build_all()
	_built = true


## SYNCHRONOUS, built from the @export values alone, and it RETURNS. No await,
## no call_deferred, no convergence loop — the sweep sets `accord` before the
## node enters the tree and this is the whole build.
func _build_all() -> void:
	if not _base_captured:
		_base_sep = separation_weight
		_base_ali = alignment_weight
		_base_coh = cohesion_weight
		_base_perception = perception_radius
		_base_captured = true
	_apply_accord_rules()
	_create_tank()
	_create_multimesh()
	_create_labels()
	_create_vr_controls()
	_spawn_boids()
	_refresh_info_label()


## The rule set each accord names. Returns (separation, alignment, cohesion);
## perception is set alongside because WHO COUNTS AS A NEIGHBOUR is part of the
## rule, not a dial.
##
## MEASURED, NOT ASSUMED. Every triple below was run through this file's own
## _update_boids at 60 Hz for 0..4 s before it was written down.
##
##   orb     sep 0.30 -> 0.0. Thirty boids inside a 0.10 m ball sit ~0.05 m
##           apart, and this code's separation term is an unnormalised sum of
##           diff/dist², so even sep 0.05 saturates the velocity clamp and the
##           bead fills the whole tank (0.88 m extent) within 1.1 s — a twin of
##           `school`. align 0.5 -> 0.0 for the same reason inverted: averaging
##           a shell's velocities gives ~zero, so alignment acts as pure drag
##           and collapses the bead to 0.076 m by 3 s. Cohesion alone, with the
##           deposit given orbital speed r·sqrt(coh) in varied planes and net
##           momentum zeroed, holds 0.19..0.21 m across the entire window.
##   lane    sep 0.8 -> 0.0. At 0.14 m spacing separation thickens the slab from
##           0.120 m to 0.201 m by 1.1 s and 0.487 m by 2.5 s — it stops being a
##           sheet. With separation off the thickness is 0.120 m at 1.1 s and
##           0.118 m at 3 s, and heading agreement stays at 0.98.
##   lattice sep 4.5 / coh 0 / align 0 exactly as written. At 0.20 m spacing and
##           perception 0.15 nobody has a neighbour, so the deposit is a fixed
##           point trivially; separation only bites if drift closes a pair to
##           under 0.15 m, and then it shoves them back out. Self-correcting.
##   school  untouched — the authored weights, restored from the snapshot.
func _accord_weights(which: String) -> Vector3:
	match which:
		"orb":
			return Vector3(0.0, 0.0, 4.5)
		"lane":
			return Vector3(0.0, 4.5, 0.5)
		"lattice":
			return Vector3(4.5, 0.0, 0.0)
	return Vector3(_base_sep, _base_ali, _base_coh)


func _accord_perception(which: String) -> float:
	match which:
		"orb":
			return 0.20      # a 0.20 m ball: everyone sees the whole flock
		"lane":
			return 0.15
		"lattice":
			return 0.15      # strictly under the 0.20 m rank spacing
	return _base_perception


func _apply_accord_rules() -> void:
	var w: Vector3 = _accord_weights(accord)
	separation_weight = w.x
	alignment_weight = w.y
	cohesion_weight = w.z
	perception_radius = clampf(_accord_perception(accord), 0.01, 0.5)


func _create_tank():
	# Glass panels
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.85, 1.0, tank_transparency)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.metallic = 0.2
	glass_mat.roughness = 0.1

	# Create panels
	var panels = [
		[Vector3(0, 0, -tank_size.z/2), Vector3(tank_size.x, tank_size.y, 0.005)],  # Back
		[Vector3(0, 0, tank_size.z/2), Vector3(tank_size.x, tank_size.y, 0.005)],   # Front
		[Vector3(-tank_size.x/2, 0, 0), Vector3(0.005, tank_size.y, tank_size.z)],  # Left
		[Vector3(tank_size.x/2, 0, 0), Vector3(0.005, tank_size.y, tank_size.z)],   # Right
		[Vector3(0, -tank_size.y/2, 0), Vector3(tank_size.x, 0.005, tank_size.z)],  # Bottom
	]

	for i in range(panels.size()):
		var panel = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = panels[i][1]
		panel.mesh = box
		panel.material_override = glass_mat
		panel.position = panels[i][0]
		add_child(panel)
		_created_nodes.append(panel)

	# Frame
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.2, 0.2, 0.25)
	frame_mat.metallic = 0.7
	frame_mat.roughness = 0.3

	var frame_thickness = 0.015
	_create_frame_edge(Vector3(0, -tank_size.y/2, -tank_size.z/2), Vector3(tank_size.x + frame_thickness*2, frame_thickness, frame_thickness), frame_mat)
	_create_frame_edge(Vector3(0, -tank_size.y/2, tank_size.z/2), Vector3(tank_size.x + frame_thickness*2, frame_thickness, frame_thickness), frame_mat)
	_create_frame_edge(Vector3(-tank_size.x/2, -tank_size.y/2, 0), Vector3(frame_thickness, frame_thickness, tank_size.z), frame_mat)
	_create_frame_edge(Vector3(tank_size.x/2, -tank_size.y/2, 0), Vector3(frame_thickness, frame_thickness, tank_size.z), frame_mat)

func _create_frame_edge(pos: Vector3, size: Vector3, mat: StandardMaterial3D):
	var edge = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	edge.mesh = box
	edge.material_override = mat
	edge.position = pos
	add_child(edge)
	_created_nodes.append(edge)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = boid_count

	# Elongated cube shape
	var mesh = BoxMesh.new()
	mesh.size = boid_size
	_multimesh.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = _emissive
	mat.emission_energy_multiplier = 0.4

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "BoidMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)
	_created_nodes.append(_multimesh_instance)


# ═══════════════════════════════════════════════════════════════════
# CAPTIONS — two labels, opposite treatments
# ═══════════════════════════════════════════════════════════════════

## (a) The info label HANGS with nothing behind it, so it is billboarded and the
##     framer plates it — which is the honest thing to do with floating text.
##     It sits above the tank top with 0.06+ m of air, clear of the viewing
##     corridor, and its two lines are padded to a constant 24 characters at
##     every accord value so the plate is the same size in all four tiles.
## (b) The scene's "BOIDS" label lies FLAT ON the front pane, so it keeps
##     billboard disabled and the framer skips it by design — a caption printed
##     on glass already has a body behind every glyph.
## One plated label only, so nothing merges. The RackTemplates panel below the
## tank carries its own on-panel text and is not touched.
func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_info_label.position = Vector3(0.0, tank_size.y * 0.5 + INFO_LABEL_LIFT, 0.0)
	_info_label.text = _info_text()
	add_child(_info_label)
	_created_nodes.append(_info_label)
	_place_front_label()


## The scene Label3D moved flush onto the outer face of the front pane. NOT
## created here and NEVER freed here — the framer needs the node and the scene
## owns it.
func _place_front_label() -> void:
	var front: Label3D = get_node_or_null("Label3D") as Label3D
	if front == null:
		return
	front.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	front.position = Vector3(
		0.0,
		-tank_size.y * 0.40,
		tank_size.z * 0.5 + FRONT_LABEL_PROUD)
	front.rotation = Vector3.ZERO


## Two lines, each padded to exactly INFO_COLS characters whatever the accord is,
## so LabelFramer measures the same string width in every tile.
func _info_text() -> String:
	return "%s\n%s" % [
		_centre_pad("BOIDS AQUARIUM"),
		_centre_pad("accord: " + _accord_display().rpad(8))]


func _centre_pad(s: String) -> String:
	var pad: int = INFO_COLS - s.length()
	if pad <= 0:
		return s
	var left: int = pad >> 1
	return " ".repeat(left) + s + " ".repeat(pad - left)


## What the flock is actually obeying right now. A VR user who drags a slider has
## left the declared accord, and the label says so — in six characters, so the
## padded width never changes.
func _accord_display() -> String:
	if not _base_captured:
		return accord
	var w: Vector3 = _accord_weights(accord)
	if absf(separation_weight - w.x) < 0.01 \
			and absf(alignment_weight - w.y) < 0.01 \
			and absf(cohesion_weight - w.z) < 0.01:
		return accord
	return "custom"


func _refresh_info_label() -> void:
	if is_instance_valid(_info_label):
		_info_label.text = _info_text()


func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("BOIDS", [
		[
			{"type": "slider_h", "label": "SEP", "default": separation_weight / 5.0},
			{"type": "slider_h", "label": "ALIGN", "default": alignment_weight / 5.0},
			{"type": "slider_h", "label": "COH", "default": cohesion_weight / 5.0},
		],
		[{"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0, -tank_size.y/2 - 0.08, tank_size.z/2 + 0.12)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	_separation_slider = _control_panel.find_child("Param_0", true, false)
	if _separation_slider and _separation_slider.has_signal("slider_moved"):
		_separation_slider.slider_moved.connect(_on_separation_slider_moved)

	_alignment_slider = _control_panel.find_child("Param_1", true, false)
	if _alignment_slider and _alignment_slider.has_signal("slider_moved"):
		_alignment_slider.slider_moved.connect(_on_alignment_slider_moved)

	_cohesion_slider = _control_panel.find_child("Param_2", true, false)
	if _cohesion_slider and _cohesion_slider.has_signal("slider_moved"):
		_cohesion_slider.slider_moved.connect(_on_cohesion_slider_moved)

	var reset_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(_respawn_boids)

func _sync_separation_slider():
	if is_instance_valid(_separation_slider) and _separation_slider.has_method("set_normalized_value"):
		_separation_slider.set_normalized_value(separation_weight / 5.0)

func _sync_alignment_slider():
	if is_instance_valid(_alignment_slider) and _alignment_slider.has_method("set_normalized_value"):
		_alignment_slider.set_normalized_value(alignment_weight / 5.0)

func _sync_cohesion_slider():
	if is_instance_valid(_cohesion_slider) and _cohesion_slider.has_method("set_normalized_value"):
		_cohesion_slider.set_normalized_value(cohesion_weight / 5.0)

func _on_separation_slider_moved(_position):
	if is_instance_valid(_separation_slider) and _separation_slider.has_method("get_normalized_value"):
		separation_weight = _separation_slider.get_normalized_value() * 5.0

func _on_alignment_slider_moved(_position):
	if is_instance_valid(_alignment_slider) and _alignment_slider.has_method("get_normalized_value"):
		alignment_weight = _alignment_slider.get_normalized_value() * 5.0

func _on_cohesion_slider_moved(_position):
	if is_instance_valid(_cohesion_slider) and _cohesion_slider.has_method("get_normalized_value"):
		cohesion_weight = _cohesion_slider.get_normalized_value() * 5.0

func _update_boid_params():
	# The readout used to print the three weights, which made the caption a
	# different width at every value and therefore a different plate size in
	# every tile. It now names the accord instead — constant width, and the
	# weights are already labelled on the rack panel.
	_refresh_info_label()


# ═══════════════════════════════════════════════════════════════════
# DEPOSITS — every value written arithmetically, O(boid_count), no pre-roll
# ═══════════════════════════════════════════════════════════════════

func _spawn_boids():
	_boids.clear()
	_boids.resize(boid_count)
	match accord:
		"orb":
			_deposit_orb()
		"lane":
			_deposit_lane()
		"lattice":
			_deposit_lattice()
		_:
			_deposit_school()
	_paint_boids()


## school — the shipped build. Same spawn box (the middle 60% of the tank), same
## random headings at half max_speed, same authored weights. The only change is
## that the draw comes from a seeded generator instead of the global one, so two
## builds of this tile are identical; the distribution is unchanged.
func _deposit_school() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = DEPOSIT_SEED
	var half: Vector3 = tank_size * 0.3
	for i in range(boid_count):
		var pos := Vector3(
			rng.randf_range(-half.x, half.x),
			rng.randf_range(-half.y, half.y),
			rng.randf_range(-half.z, half.z))
		var raw := Vector3(rng.randf() - 0.5, rng.randf() - 0.5, rng.randf() - 0.5)
		if raw.length() < 0.0001:
			raw = Vector3.FORWARD
		_boids[i] = BoidData.new(pos, raw.normalized() * max_speed * 0.5)


## orb — a solid ball at tank centre, on Fibonacci directions with radius
## r = R·t^(1/3) so the interior fills evenly, each boid given the orbital speed
## r·sqrt(cohesion) about its own axis. Varied orbit planes keep it a sphere
## rather than a disc; the net momentum is subtracted off so the bead floats at
## the centre instead of drifting out of frame.
func _deposit_orb() -> void:
	var radius: float = tank_size.x * ORB_RADIUS_FRAC
	var omega: float = sqrt(maxf(cohesion_weight, 0.0001))
	var n: int = boid_count
	var positions: Array[Vector3] = []
	var velocities: Array[Vector3] = []
	var momentum := Vector3.ZERO
	for i in range(n):
		var t: float = (float(i) + 0.5) / float(n)
		var y: float = 1.0 - 2.0 * t
		var ring: float = sqrt(maxf(0.0, 1.0 - y * y))
		var a: float = GOLDEN_ANGLE * float(i)
		var dir := Vector3(cos(a) * ring, y, sin(a) * ring)
		var r: float = radius * pow(t, 1.0 / 3.0)
		positions.append(dir * r)

		# a second, faster-spinning Fibonacci direction as this boid's orbit axis
		var t2: float = (float((i * 13) % n) + 0.5) / float(n)
		var y2: float = 1.0 - 2.0 * t2
		var ring2: float = sqrt(maxf(0.0, 1.0 - y2 * y2))
		var a2: float = GOLDEN_ANGLE * float(i) * 2.0
		var axis := Vector3(cos(a2) * ring2, y2, sin(a2) * ring2)
		var tang: Vector3 = dir.cross(axis)
		if tang.length() < 0.00001:
			tang = Vector3(-dir.z, 0.0, dir.x)
		if tang.length() < 0.00001:
			tang = Vector3.RIGHT
		var vel: Vector3 = tang.normalized() * minf(r * omega, max_speed)
		velocities.append(vel)
		momentum += vel
	var drift: Vector3 = momentum / float(n)
	for i in range(n):
		_boids[i] = BoidData.new(positions[i], velocities[i] - drift)


## lane — a horizontal slab at mid-height, LANE_COLS x LANE_ROWS across the tank
## floorplan and three layers deep inside the 0.12 m thickness, every velocity
## +X at the same speed. Identical velocities make the alignment term exactly
## zero, so the sheet is a fixed point that simply slides.
func _deposit_lane() -> void:
	var slab: Vector3 = tank_size * LANE_SLAB_FRAC
	var cols: float = float(maxi(LANE_COLS - 1, 1))
	var rows: float = float(maxi(LANE_ROWS - 1, 1))
	for i in range(boid_count):
		var wrap: int = i / (LANE_COLS * LANE_ROWS)
		var ix: int = i % LANE_COLS
		var iz: int = (i / LANE_COLS) % LANE_ROWS
		var layer: float = float(i % 3) / 2.0
		var pos := Vector3(
			-slab.x * 0.5 + slab.x * float(ix) / cols,
			-slab.y * 0.5 + slab.y * layer,
			-slab.z * 0.5 + slab.z * float(iz) / rows + float(wrap) * 0.01)
		_boids[i] = BoidData.new(pos, Vector3(LANE_SPEED, 0.0, 0.0))


## lattice — LATTICE_NX x LATTICE_NY x LATTICE_NZ sites on an even grid, given a
## slow drift in thirty different directions so the needles do NOT all point the
## same way (that is lane's picture, and a frozen lattice would render every
## mesh on the identity basis, i.e. parallel). Rank spacing sits outside
## perception, so the grid holds; if drift closes a pair, separation 4.5 pushes
## them back apart.
func _deposit_lattice() -> void:
	var span: Vector3 = tank_size * LATTICE_SPAN_FRAC
	var sx: float = span.x / float(maxi(LATTICE_NX - 1, 1))
	var sy: float = span.y / float(maxi(LATTICE_NY - 1, 1))
	var sz: float = span.z / float(maxi(LATTICE_NZ - 1, 1))
	var sites: int = LATTICE_NX * LATTICE_NY * LATTICE_NZ
	var rng := RandomNumberGenerator.new()
	rng.seed = DEPOSIT_SEED
	for i in range(boid_count):
		var s: int = i % sites
		var wrap: int = i / sites
		var ix: int = s % LATTICE_NX
		var iy: int = (s / LATTICE_NX) % LATTICE_NY
		var iz: int = s / (LATTICE_NX * LATTICE_NY)
		var pos := Vector3(
			-span.x * 0.5 + sx * float(ix),
			-span.y * 0.5 + sy * float(iy),
			-span.z * 0.5 + sz * float(iz) + float(wrap) * 0.02)
		var raw := Vector3(rng.randf() - 0.5, rng.randf() - 0.5, rng.randf() - 0.5)
		if raw.length() < 0.0001:
			raw = Vector3.UP
		_boids[i] = BoidData.new(pos, raw.normalized() * LATTICE_DRIFT)


## Colour is not the axis: the same seeded palette walk in all four values, so a
## reviewer comparing tiles is comparing SHAPE.
func _paint_boids() -> void:
	if _multimesh == null:
		return
	var colors: Array[Color] = [
		Color(1.0, 0.3, 0.3),  # Red
		Color(0.3, 1.0, 0.4),  # Green
		Color(0.3, 0.5, 1.0),  # Blue
		Color(1.0, 0.8, 0.2),  # Yellow
		Color(1.0, 0.4, 0.8),  # Pink
		Color(0.4, 1.0, 1.0),  # Cyan
		Color(0.8, 0.5, 1.0),  # Purple
		Color(1.0, 0.6, 0.3),  # Orange
	]
	var rng := RandomNumberGenerator.new()
	rng.seed = COLOUR_SEED
	for i in range(boid_count):
		var base_color: Color = colors[i % colors.size()]
		var hue_shift: float = rng.randf() * 0.05 - 0.025
		base_color.h = fmod(base_color.h + hue_shift + 1.0, 1.0)
		base_color.a = boid_transparency
		_multimesh.set_instance_color(i, base_color)


func _respawn_boids(_button = null):  # Accept optional button arg from signal
	_spawn_boids()

func _process(delta):
	if _multimesh == null or _boids.is_empty():
		return
	_update_boids(delta)
	_update_multimesh()

func _pos_to_cell(pos: Vector3) -> Vector3i:
	return Vector3i(
		floori(pos.x / _cell_size),
		floori(pos.y / _cell_size),
		floori(pos.z / _cell_size)
	)

func _rebuild_spatial_grid():
	_grid.clear()
	for i in range(_boids.size()):
		var cell = _pos_to_cell(_boids[i].position)
		if not _grid.has(cell):
			_grid[cell] = []
		_grid[cell].append(i)

func _update_boids(delta):
	var half = tank_size * 0.45
	_cell_size = perception_radius if perception_radius > 0.001 else 0.15
	var perception_sq = perception_radius * perception_radius
	var min_dist_sq = 0.001 * 0.001

	# Build spatial hash grid: each boid bucketed into its cell
	_rebuild_spatial_grid()

	for i in range(_boids.size()):
		var boid = _boids[i]
		var separation = Vector3.ZERO
		var alignment = Vector3.ZERO
		var cohesion = Vector3.ZERO
		var neighbors = 0

		# Only check boids in neighboring cells (3x3x3 neighborhood)
		var center_cell = _pos_to_cell(boid.position)
		for dx in range(-1, 2):
			for dy in range(-1, 2):
				for dz in range(-1, 2):
					var check_cell = Vector3i(center_cell.x + dx, center_cell.y + dy, center_cell.z + dz)
					if not _grid.has(check_cell):
						continue
					for j in _grid[check_cell]:
						if i == j:
							continue
						var other = _boids[j]
						var diff = boid.position - other.position
						var dist_sq = diff.length_squared()

						if dist_sq < perception_sq:
							neighbors += 1

							# Separation (uses dist_sq directly: diff / dist^2 = diff / dist_sq)
							if dist_sq > min_dist_sq:
								separation += diff / dist_sq

							# Alignment
							alignment += other.velocity

							# Cohesion
							cohesion += other.position

		if neighbors > 0:
			alignment /= neighbors
			alignment = (alignment - boid.velocity) * alignment_weight

			cohesion /= neighbors
			cohesion = (cohesion - boid.position) * cohesion_weight

			separation *= separation_weight

		# Apply forces
		var acceleration = separation + alignment + cohesion
		boid.velocity += acceleration * delta

		# Limit speed (use length_squared to avoid sqrt when possible)
		if boid.velocity.length_squared() > max_speed * max_speed:
			boid.velocity = boid.velocity.normalized() * max_speed

		# Move
		boid.position += boid.velocity * delta

		# Boundary bounce
		if abs(boid.position.x) > half.x:
			boid.position.x = signf(boid.position.x) * half.x
			boid.velocity.x *= -1
		if abs(boid.position.y) > half.y:
			boid.position.y = signf(boid.position.y) * half.y
			boid.velocity.y *= -1
		if abs(boid.position.z) > half.z:
			boid.position.z = signf(boid.position.z) * half.z
			boid.velocity.z *= -1

func _update_multimesh():
	for i in range(_boids.size()):
		var boid = _boids[i]
		var transform = Transform3D()
		transform.origin = boid.position

		# Orient to velocity
		if boid.velocity.length() > 0.001:
			var forward = boid.velocity.normalized()
			var up = Vector3.UP
			if abs(forward.dot(up)) > 0.99:
				up = Vector3.FORWARD
			transform = transform.looking_at(boid.position + forward, up)
			transform.basis = transform.basis.rotated(transform.basis.x, -PI/2)

		_multimesh.set_instance_transform(i, transform)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				separation_weight = clampf(separation_weight - 0.2, 0.0, 5.0)
			KEY_2:
				separation_weight = clampf(separation_weight + 0.2, 0.0, 5.0)
			KEY_3:
				alignment_weight = clampf(alignment_weight - 0.2, 0.0, 5.0)
			KEY_4:
				alignment_weight = clampf(alignment_weight + 0.2, 0.0, 5.0)
			KEY_5:
				cohesion_weight = clampf(cohesion_weight - 0.2, 0.0, 5.0)
			KEY_6:
				cohesion_weight = clampf(cohesion_weight + 0.2, 0.0, 5.0)
			KEY_R:
				_respawn_boids()


## String-form is_connected/disconnect, not `.slider_moved.disconnect(...)`: the
## slider is typed Node here, and a rebuild runs this against nodes that are
## already on their way out.
func _disconnect_controls() -> void:
	_drop_signal(_separation_slider, "slider_moved", _on_separation_slider_moved)
	_drop_signal(_alignment_slider, "slider_moved", _on_alignment_slider_moved)
	_drop_signal(_cohesion_slider, "slider_moved", _on_cohesion_slider_moved)


func _drop_signal(node: Node, sig: StringName, target: Callable) -> void:
	if not is_instance_valid(node):
		return
	if not node.has_signal(sig):
		return
	if node.is_connected(sig, target):
		node.disconnect(sig, target)


func _exit_tree():
	_disconnect_controls()
	# Free created nodes
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Called via call_deferred by GridInteractablesComponent, AFTER _ready(), and
## again by curation_station with {"emissive": false} one line after it frames
## the labels. That bare emissive call carries no axis key, so it must change
## the material IN PLACE and then return without rebuilding — a rebuild there
## would throw away the frames the station just made.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_accord: String = accord
	var before_count: int = boid_count
	var before_tank: Vector3 = tank_size

	if config_data.has("accord"):
		accord = _pick_axis(str(config_data["accord"]), ACCORDS, accord)
	if config_data.has("boid_count"):
		boid_count = clampi(int(config_data["boid_count"]), 10, 200)
	if config_data.has("tank_size"):
		var t: float = clampf(float(config_data["tank_size"]), 0.3, 3.0)
		tank_size = Vector3(t, t, t)

	# Non-geometry, applied here so it bites even on the early-return path.
	if config_data.has("emissive"):
		_emissive = _as_bool(config_data["emissive"], _emissive)
		_apply_emissive()

	if not _built:
		return
	if accord == before_accord and boid_count == before_count and tank_size == before_tank:
		return
	_rebuild_now()
	print("[BoidsAquarium] Config applied — accord=%s, boids=%d" % [accord, boid_count])


## Accept an axis value only if it names something we actually build. A typo in a
## map token has to fall back to the shipped look rather than strand a placement
## on a half-recognised word.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## bool("false") is TRUE, which is how an accepted key comes to mean its own
## opposite. Parse the word.
func _as_bool(v: Variant, fallback: bool) -> bool:
	if v is bool:
		var b: bool = v
		return b
	if v is int or v is float:
		return float(v) != 0.0
	if v is String:
		var s: String = str(v).strip_edges().to_lower()
		if s in ["true", "1", "yes", "on"]:
			return true
		if s in ["false", "0", "no", "off"]:
			return false
	return fallback


func _apply_emissive() -> void:
	if not is_instance_valid(_multimesh_instance):
		return
	var m: StandardMaterial3D = _multimesh_instance.material_override as StandardMaterial3D
	if m != null:
		m.emission_enabled = _emissive


## SYNCHRONOUS and inline. Nothing deferred: a deferred rebuild that removes
## children first makes the grid's auto-grounding measure a zero AABB and bail.
## Only nodes THIS script created are freed — the scene's own "BOIDS" label is
## not in _created_nodes and survives.
func _rebuild_now() -> void:
	_disconnect_controls()
	for c in _created_nodes:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_created_nodes.clear()
	_multimesh = null
	_multimesh_instance = null
	_info_label = null
	_control_panel = null
	_separation_slider = null
	_alignment_slider = null
	_cohesion_slider = null
	_boids.clear()
	_grid.clear()

	_build_all()
	# The grid framed the old info label before this call; the replacement needs
	# the same treatment or it hangs as naked text. The framer is idempotent.
	LabelFramerScript.frame_labels(self)
