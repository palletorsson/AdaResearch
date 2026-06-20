extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FurnitureRecursionBench

## @identity
## name: "Fractal furniture"
## tier: medium
## lineage: a chair derived, not designed — a strut that subdivides into its own frame.
## essence: A bench demonstration. One strut subdivides into a four-post frame, each
##   post subdivides again, and at the readable bottom of the recursion the frame is
##   a chair: seat, back, four legs. A counter shows the depth, so you can watch the
##   chair appear as the rule runs one more time.
## truth: "a chair that is chairs — furniture is a frame that keeps being a frame"
## applications: recurse a strut and get a chair — design as a stopping rule on a
##   self-similar frame rather than a drawn shape.

@export var depth: int = 3
@export var frame_col: Color = Color(0.58, 0.42, 0.26)
@export var seat_col: Color = Color(0.72, 0.54, 0.32)
@export var bench_col: Color = Color(0.30, 0.32, 0.34)
@export var label_col: Color = Color(0.80, 0.64, 0.40)

var _t: float = 0.0
var _chair_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("frame_col"):
		frame_col = _parse_color(config["frame_col"], frame_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_chair_root = null
	_build()


func _build() -> void:
	# --- bench base ---------------------------------------------------------
	var top_y: float = 0.85
	var top_mat: StandardMaterial3D = _matte_mat(bench_col, 0.6, 0.1)
	add_child(_box(Vector3(0.0, top_y, 0.0), Vector3(1.1, 0.2, 0.55), top_mat))
	var leg_mat: StandardMaterial3D = _steel_mat(Color(0.22, 0.23, 0.25))
	add_child(_cylinder(Vector3(0.0, top_y * 0.5, 0.0), 0.07, top_y, leg_mat))
	add_child(_cylinder(Vector3(0.0, 0.02, 0.0), 0.22, 0.04, leg_mat))

	# --- the recursive chair on top -----------------------------------------
	var root := Node3D.new()
	root.name = "RecursionChair"
	root.position = Vector3(0.0, top_y + 0.1, 0.0)
	add_child(root)
	_chair_root = root

	var frame_mat: StandardMaterial3D = _matte_mat(frame_col, 0.7, 0.0)
	var seat_mat: StandardMaterial3D = _matte_mat(seat_col, 0.6, 0.0)

	# Build a chair-shaped frame whose legs are themselves smaller frames.
	# A chair "cell" = a box footprint with four corner posts and a seat+back.
	_chair(root, Vector3.ZERO, 0.62, depth, frame_mat, seat_mat)

	add_child(_billboard_label("A CHAIR THAT IS CHAIRS", Vector3(0.0, 1.6, 0.0), 18, label_col))
	# depth readout — the recursion made readable
	add_child(_billboard_label("recursion depth: %d" % depth, Vector3(0.0, 1.44, 0.0), 14, Color(0.85, 0.80, 0.72)))


func _chair(parent: Node3D, base_centre: Vector3, size: float, d: int, frame_mat: Material, seat_mat: Material) -> void:
	# A chair of footprint `size`, sitting with its feet at base_centre.y.
	var half: float = size * 0.5
	var seat_h: float = size * 0.5
	var post_r: float = maxf(size * 0.03, 0.006)
	var corners: Array = [
		Vector3(-half, 0.0, -half), Vector3(half, 0.0, -half),
		Vector3(half, 0.0, half), Vector3(-half, 0.0, half)
	]

	if d <= 1:
		# Base case: an actual little chair — four legs, a seat, a back.
		for cn: Vector3 in corners:
			var foot: Vector3 = base_centre + cn
			parent.add_child(_cylinder_between(foot, foot + Vector3(0.0, seat_h, 0.0), post_r, frame_mat))
		var seat_centre: Vector3 = base_centre + Vector3(0.0, seat_h, 0.0)
		parent.add_child(_box(seat_centre + Vector3(0.0, post_r, 0.0), Vector3(size, post_r * 2.0, size), seat_mat))
		# back rest along the -Z edge
		var back_bottom_l: Vector3 = seat_centre + Vector3(-half, 0.0, -half)
		var back_bottom_r: Vector3 = seat_centre + Vector3(half, 0.0, -half)
		parent.add_child(_cylinder_between(back_bottom_l, back_bottom_l + Vector3(0.0, seat_h, 0.0), post_r, frame_mat))
		parent.add_child(_cylinder_between(back_bottom_r, back_bottom_r + Vector3(0.0, seat_h, 0.0), post_r, frame_mat))
		var back_top_l: Vector3 = back_bottom_l + Vector3(0.0, seat_h, 0.0)
		var back_top_r: Vector3 = back_bottom_r + Vector3(0.0, seat_h, 0.0)
		parent.add_child(_cylinder_between(back_top_l, back_top_r, post_r, frame_mat))
		return

	# Recurse: each of the four corner posts is itself a smaller chair-frame,
	# and a seat slab caps them — the frame is made of frames.
	var child_size: float = size * 0.46
	for cn: Vector3 in corners:
		var sub_centre: Vector3 = base_centre + cn * 0.62
		_chair(parent, sub_centre, child_size, d - 1, frame_mat, seat_mat)
	# the seat of THIS frame, resting on the four sub-chairs
	var seat_centre2: Vector3 = base_centre + Vector3(0.0, seat_h + size * 0.5, 0.0)
	parent.add_child(_box(seat_centre2, Vector3(size, post_r * 2.0, size), seat_mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _chair_root != null:
		_chair_root.rotation.y = sin(_t * 0.4) * 0.12
