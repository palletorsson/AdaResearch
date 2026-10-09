# ===========================================================================
# NOC Example 8.3: Recursion: Circles
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

## Example 8.3: Recursion Circles
## Recursive circles within circles
## Chapter 08: Fractals

# @identity
# essence: circle(center, r, d) = torus(r) + 4 * circle(center +/- offset, r * 0.5, d-1)
# desire: To hypnotize — nested tori spinning at depth-dependent speeds, each ring a portal into the next scale
# critical_parameter: depth — at 3 it's a simple pattern, at 5 the circles overlap and interfere, creating moire-like density
# triggers: Full rotation of outermost ring → pause; depth-varying rotation_per_depth creates visual decoherence
# emerges: Interference patterns between spinning tori at different depths — visual beats from simple rotation ratios
# needs: VR depth slider [missing], rotation speed control [missing]
# relationships: Simplest fractal recursion — precedes Koch and Sierpinski; introduces the 4-fold branching pattern
# truth: Recursion is not repetition — it is self-reference, and the circle that contains circles is the first fractal you can hold.

const MAT_PINK := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_POP_PLASTIC := preload("res://algorithms/shaders/queer_materials/mat_pop_plastic.tres")

## AXIS — DEPTH. How many times the rule is allowed to call itself.
##
## The word is the L-system family's — lsystem_editor, room_grammar and
## space_filling_curve_gallery all carry `depth` for exactly this — and it is also this
## file's own: the export was called max_depth, the caption reads "Depth: %d", and the
## @identity names it as the critical parameter. THIS IS DELIBERATELY NOT `tick`.
## cantor_set, sierpinski_pyramid and zeno_staircase share tick | once, coarse, fine, dense,
## limit for a rule reapplied to a SET, and their top rung `limit` gestures at an idealised
## limit object. Here the branch is 4-fold, so the ring count is (4^d - 1)/3 — 1, 5, 21, 85,
## 341 — and a `limit` rung is not a picture, it is five and a half thousand tori. A word
## whose top value cannot be drawn is a word taken without its answers.
##
## Declared 1-5 and not 1-6: 4 is the shipped number and 5 is the top of the range the
## artifact's own @identity describes ("at 5 the circles overlap and interfere").
@export_range(1, 5) var depth: int = 4

## AXIS — PACKING. How much of the space it is given each child ring claims.
##
## Taken word for word AND value for value from sierpinski_pyramid and cantor_set, which ask
## the same question of the same kind of object: the extent never moves (every child sits
## exactly internally tangent to its parent for ANY reduction, so the outermost ring is 2.0
## across at every rung) and the ring COUNT never moves (4^d regardless), and only the
## atom's claim on its neighbours changes. ONE THING DIFFERS AND IT IS A FACT ABOUT THIS
## ARTIFACT: the shipped value is `fused`, the TOP rung, one past tangency. This fractal was
## already drawn overlapping, which is where the moire in its own @identity comes from.
##
##   fused    0.60 — THE SHIPPED LOOK, all 5 rooms. The two in-plane children overlap each
##            other by 0.2 of the parent radius and the out-of-plane pair is pulled in close;
##            rings cut through rings and the field reads as interference.
##   contact  0.50 — the two in-plane children exactly tangent: 2 * offset = 2 * r, the one
##            reduction at which the packing is as tight as it can be with nothing crossing.
##            Also this file's own historical default, before the scene overrode it.
##   open     0.35 — clear daylight between the children; the recursion stops being a texture
##            and reads as a branching tree of separate rings.
##   dust     0.25 — children small and flung wide. The self-similarity is still exactly the
##            same rule; almost nothing of the picture survives it.
@export_enum("fused", "contact", "open", "dust") var packing: String = "fused"

## The reduction each named rung stands for. The float stays an export because the SCENE
## writes it (radius_reduction = 0.6 on the root), and `fused` deliberately hands that value
## back untouched rather than reasserting it.
const PACKING_R: Dictionary = {"fused": 0.6, "contact": 0.5, "open": 0.35, "dust": 0.25}

@export var radius_reduction: float = 0.5
@export var rotation_speed: float = 0.3
@export var rotation_per_depth: float = 0.5
@export var pause_duration: float = 10.0

var _sim_root: Node3D
var _status_label: Label3D
var _circles: Array = []
var _is_paused: bool = false
var _pause_timer: float = 0.0
var _built: bool = false

func _ready() -> void:
	_read_dna()
	_setup_environment()
	_draw_circles(Vector3.ZERO, 2.0, depth)
	set_process(true)
	_built = true


## Read the two axes off the metadata the grid writes on the artifact ROOT before add_child,
## so this runs before a single torus exists. An unknown word or a number outside the range
## keeps the value already held.
func _read_dna() -> void:
	if has_meta("config_depth"):
		_take_depth(get_meta("config_depth"))
	elif has_meta("config_max_depth"):
		# `max_depth` was this export's name until the promotion; kept as an alias so a
		# token written against the old name is not silently ignored.
		_take_depth(get_meta("config_max_depth"))
	if has_meta("config_packing"):
		var p: String = str(get_meta("config_packing")).strip_edges().to_lower()
		if PACKING_R.has(p):
			packing = p
	_apply_packing()


## int(str(...)) because a map token value arrives as a String, and assigning a String to a
## typed int property is rejected without a word of complaint.
func _take_depth(raw) -> void:
	depth = clampi(int(str(raw)), 1, 5)


## SHORT-CIRCUIT AT THE SHIPPED VALUE. Before the first build, `fused` returns without
## touching radius_reduction, so the 0.6 the .tscn wrote on the root — or any other number a
## placement chose to override — survives intact. Only a value that ARRIVED afterwards, from
## a map token, writes the table's number.
func _apply_packing() -> void:
	if packing == "fused" and not _built:
		return
	radius_reduction = PACKING_R[packing]


## GUARDED. Returns on an empty dict, assigns only on a value that is both legal and
## DIFFERENT, and rebuilds only when something actually moved and only after _ready has
## built once. Was a bare `pass`: the artifact advertised the hook and threw every key away.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var changed: bool = false

	if config.has("depth") or config.has("max_depth"):
		var raw = config.get("depth", config.get("max_depth", depth))
		var d: int = clampi(int(str(raw)), 1, 5)
		if d != depth:
			depth = d
			changed = true

	if config.has("packing"):
		var p: String = str(config["packing"]).strip_edges().to_lower()
		if PACKING_R.has(p) and p != packing:
			packing = p
			_apply_packing()
			changed = true

	# NOT AN AXIS, a FIXTURE knob. The tori tumble, and the outermost one's rate is
	# rotation_speed * (1 + depth * rotation_per_depth) — so a depth sweep photographed at a
	# fixed settle time compares five different rings at five different tumble PHASES, and
	# the critic would read some of that pose difference as the axis. Setting this to 0 from
	# dna.fixture holds every variant at the pose it was built in. Read live in _process, so
	# it needs no rebuild and never sets `changed`.
	if config.has("rotation_speed"):
		rotation_speed = float(str(config["rotation_speed"]))

	if not changed or not _built:
		return
	_rebuild()


func _rebuild() -> void:
	_circles.clear()
	_is_paused = false
	_pause_timer = 0.0
	if is_instance_valid(_sim_root):
		remove_child(_sim_root)
		_sim_root.queue_free()
	_sim_root = null
	_setup_environment()
	_draw_circles(Vector3.ZERO, 2.0, depth)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 24
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.75, 0)
	_status_label.text = "Recursive Circles | Depth: %d" % depth
	_sim_root.add_child(_status_label)

## `level` is the recursion counter; the member `depth` is the ceiling it starts from. The
## parameter was called `depth` too, which shadowed the export the moment it became one.
func _draw_circles(center: Vector3, radius: float, level: int) -> void:
	if level <= 0 or radius < 0.01:
		return

	# Draw circle at current level
	_create_circle(center, radius, level)

	# Recurse: create 4 smaller circles around this one
	var new_radius := radius * radius_reduction
	var offset := radius - new_radius

	_draw_circles(center + Vector3(offset, 0, 0), new_radius, level - 1)
	_draw_circles(center + Vector3(-offset, 0, 0), new_radius, level - 1)
	_draw_circles(center + Vector3(0, offset, 0), new_radius, level - 1)
	_draw_circles(center + Vector3(0, -offset, 0), new_radius, level - 1)

func _create_circle(center: Vector3, radius: float, level: int) -> void:
	var mesh_instance := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = radius * 0.9
	torus.outer_radius = radius
	mesh_instance.mesh = torus
	mesh_instance.position = center

	# Use the pop plastic shader material
	mesh_instance.material_override = MAT_POP_PLASTIC

	_sim_root.add_child(mesh_instance)

	# Store circle data for rotation
	_circles.append({
		"node": mesh_instance,
		"depth": level,
		"center": center,
		"rotation": 0.0  # Track total rotation
	})

func _process(delta: float) -> void:
	# Handle pause timer
	if _is_paused:
		_pause_timer += delta
		if _pause_timer >= pause_duration:
			_is_paused = false
			_pause_timer = 0.0
		return

	# Rotate each circle based on its depth
	for circle_data in _circles:
		var node = circle_data["node"]
		var level = circle_data["depth"]

		# Different rotation speeds per depth level
		var speed_multiplier = rotation_speed * (1.0 + level * rotation_per_depth)
		var rotation_amount = delta * speed_multiplier

		node.rotate_z(rotation_amount)
		circle_data["rotation"] += rotation_amount

		# Check if this circle completed a full rotation (2π radians)
		if circle_data["rotation"] >= TAU:  # TAU = 2π
			circle_data["rotation"] = fmod(circle_data["rotation"], TAU)

			# Pause animation when the outermost/first created circle completes
			if level == depth:
				_is_paused = true
				_pause_timer = 0.0

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
