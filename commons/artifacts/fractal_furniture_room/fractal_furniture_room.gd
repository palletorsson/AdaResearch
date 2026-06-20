extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalFurnitureRoom

## @identity
## name: "Fractal furniture"
## tier: large
## lineage: a furnished room derived from one move — recurse a strut, and the room fills.
## essence: A room of fractal furniture. A recursive chair whose legs are chairs, a
##   recursive table whose legs branch, and a shelf that splits into shelves. Three
##   pieces, ~2m, one idea: every support is a smaller copy of the support above it.
##   Walk in and you are inside the rule, standing among the things it makes.
## truth: "recurse a strut, get a chair — a whole room from one branching support"
## applications: self-supporting structure — the same recursion furnishes a room,
##   the way a grammar furnishes a forest.

@export var depth: int = 3
@export var floor_size: float = 7.0
@export var wood_col: Color = Color(0.56, 0.40, 0.24)
@export var wood_warm: Color = Color(0.70, 0.52, 0.30)
@export var floor_col: Color = Color(0.20, 0.18, 0.16)
@export var label_col: Color = Color(0.82, 0.66, 0.42)

var _t: float = 0.0
var _pieces: Array[Node3D] = []


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	if config.has("wood_col"):
		wood_col = _parse_color(config["wood_col"], wood_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_pieces.clear()
	_build()


func _build() -> void:
	# --- room floor ---------------------------------------------------------
	var floor_mat: StandardMaterial3D = _matte_mat(floor_col, 0.9, 0.05)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), floor_mat))

	var frame_mat: StandardMaterial3D = _matte_mat(wood_col, 0.7, 0.0)
	var top_mat: StandardMaterial3D = _matte_mat(wood_warm, 0.6, 0.0)

	# --- a recursive chair --------------------------------------------------
	var chair := Node3D.new()
	chair.name = "RecursiveChair"
	chair.position = Vector3(-1.8, 0.0, -0.6)
	add_child(chair)
	_pieces.append(chair)
	_recursive_support_piece(chair, 0.5, depth, frame_mat)
	# seat + back
	chair.add_child(_box(Vector3(0.0, 0.92, 0.0), Vector3(0.7, 0.06, 0.7), top_mat))
	chair.add_child(_box(Vector3(0.0, 1.28, -0.32), Vector3(0.7, 0.7, 0.06), top_mat))

	# --- a recursive table --------------------------------------------------
	var table := Node3D.new()
	table.name = "RecursiveTable"
	table.position = Vector3(1.6, 0.0, 0.2)
	add_child(table)
	_pieces.append(table)
	_recursive_support_piece(table, 0.9, depth, frame_mat)
	table.add_child(_box(Vector3(0.0, 1.5, 0.0), Vector3(1.4, 0.07, 1.0), top_mat))

	# --- a branching shelf --------------------------------------------------
	var shelf := Node3D.new()
	shelf.name = "BranchingShelf"
	shelf.position = Vector3(0.1, 0.0, -2.4)
	add_child(shelf)
	_pieces.append(shelf)
	_shelf(shelf, Vector3(0.0, 0.0, 0.0), 1.6, 1.2, depth, frame_mat, top_mat)

	add_child(_billboard_label("RECURSE A STRUT, GET A CHAIR", Vector3(0.0, 3.6, 0.0), 26, label_col))


func _recursive_support_piece(parent: Node3D, footprint: float, d: int, mat: Material) -> void:
	# Four corner legs; each leg, except at the base case, splits into a smaller
	# four-leg cluster — the support is self-similar.
	var half: float = footprint * 0.5
	var corners: Array = [
		Vector3(-half, 0.0, -half), Vector3(half, 0.0, -half),
		Vector3(half, 0.0, half), Vector3(-half, 0.0, half)
	]
	var leg_h: float = footprint * 1.6
	var leg_r: float = maxf(footprint * 0.05, 0.02)
	for cn: Vector3 in corners:
		_leg(parent, cn, leg_h, leg_r, d, mat)


func _leg(parent: Node3D, base: Vector3, height: float, radius: float, d: int, mat: Material) -> void:
	var top: Vector3 = base + Vector3(0.0, height, 0.0)
	if d <= 1:
		parent.add_child(_cylinder_between(base, top, radius, mat))
		return
	# lower trunk, then split into a splayed bundle of SMALLER LEGS that rejoin
	# at the top — a strut that is itself made of struts (capped by d).
	var mid: Vector3 = base + Vector3(0.0, height * 0.45, 0.0)
	parent.add_child(_cylinder_between(base, mid, radius, mat))
	var splits: int = 3
	for i in range(splits):
		var ang: float = TAU * float(i) / float(splits)
		var off := Vector3(cos(ang), 0.0, sin(ang)) * radius * 2.4
		var sub_top: Vector3 = top + off
		# each branch is a recursive sub-leg rising from mid, then a tie back to the top
		var sub_height: float = height * 0.55
		_leg(parent, mid, sub_height, radius * 0.62, d - 1, mat)
		parent.add_child(_cylinder_between(mid + Vector3(0.0, sub_height, 0.0), sub_top, radius * 0.6, mat))
		parent.add_child(_cylinder_between(sub_top, top, radius * 0.55, mat))


func _shelf(parent: Node3D, base: Vector3, width: float, height: float, d: int, post_mat: Material, plank_mat: Material) -> void:
	# A vertical post that sheds horizontal planks, each plank sprouting a smaller
	# shelf at its end — shelves of shelves.
	var post_r: float = 0.035
	var top: Vector3 = base + Vector3(0.0, height, 0.0)
	parent.add_child(_cylinder_between(base, top, post_r, post_mat))
	var planks: int = 3
	for i in range(planks):
		var ph: float = lerpf(height * 0.25, height, float(i) / float(planks - 1))
		var plank_centre: Vector3 = base + Vector3(width * 0.5, ph, 0.0)
		parent.add_child(_box(plank_centre, Vector3(width, 0.04, 0.34), plank_mat))
		if d > 1 and i == planks - 1:
			var end_base: Vector3 = base + Vector3(width, ph, 0.0)
			_shelf(parent, end_base, width * 0.5, height * 0.5, d - 1, post_mat, plank_mat)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for i in range(_pieces.size()):
		var p: Node3D = _pieces[i]
		p.rotation.y = sin(_t * 0.3 + float(i) * 1.1) * 0.04
