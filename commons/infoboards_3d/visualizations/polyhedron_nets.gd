# PolyhedronNets.gd - 2D net visualizations for polyhedra
#
# @identity
# essence: the 2D nets of tetrahedron, cube, and octahedron that fold up along hinges into their closed 3D solids
# desire: learner watches a flat strip of faces become a volume — surface area precedes and predicts the solid
# critical_parameter: fold_progress (0..1) — the single scalar that carries the shape from unfolded plane to sealed polyhedron
# triggers: builds the flat net on ready, then animates hinge rotations across fold_progress to close it into the solid
# emerges: the understanding that a 3D form is a folded 2D one — every polyhedron is a plane that learned to close
# needs: [animated fold from net to solid for cube [has], missing folds for the tetra and octa nets it also draws]
# relationships: the unfolding of the platonic solids; kin to the fold_system and the Melencolia net
# truth: a polyhedron is a flat thing that folded — the net is not a diagram of the solid, it is the solid unfolded
extends Node3D

# STAGE-2 DNA PROMOTION (2026-08-03). The exports existed — fold_duration,
# fold_delay, auto_fold — and the registry had never declared any of them. It
# was right not to. Every one of them is a RATE or a DELAY, and the evidence in
# this loop is one still PNG per value, which cannot see a rate at all. Six
# frames of the same cube at six speeds is a finished-looking experiment that
# answers nothing.
#
# What a still CAN see is where the fold got to, and which of the eleven nets it
# started from. Both were welded shut:
#
#   fold   where the fold has got to    animated · closed · hinged · flat
#   net    which cube net is unfolded   latin_cross · staircase · zed · two_rows
#
# `net` is the one that carries the artifact's own truth line. There are exactly
# eleven distinct nets of a cube, this scene drew one of them, and drawing one
# net makes the fold look like a property of THAT shape instead of a property of
# the cube. Standing a 2-2-2 staircase and a 3-3 double row next to the 1-4-1
# cross is the statement: four different flat things, one solid, and no way to
# tell from the solid which flat thing it was. That is the unfolding argument in
# its strong form and it is legible in a single frame.
#
# HOW THE FOUR NETS WERE CHOSEN. Not by eye. tools-side, every 6-cell polyomino
# was enumerated, folded through the same hinge-sign rule this file uses, and
# checked for landing on six distinct cube faces; that recovered exactly the
# eleven known nets, which is the proof the rule is right. Three of the four
# shipped values come from that set, one per family (1-4-1 aligned, 2-2-2, 3-3);
# two of my first guesses at a 2-3-1 failed the check and were dropped rather
# than shipped as a broken cube nobody would notice at fold=flat.
#
# latin_cross is the default and is a NO-OP: it runs _create_cube_faces()
# untouched, the same six faces, the same five hinges, the same names, the same
# 0.15 delay on the back flap. The generic builder is not even entered. fold's
# default `animated` is the shipped tween — delay 0.4, duration 2.0, sine in-out
# — so all 7 existing placements animate exactly as before.
#
# Usage in map_data.json:
#   "polyhedron_nets_cube#fold:closed"
#   "polyhedron_nets_cube#net:staircase#fold:flat"

@export var net_type: String = "tetrahedron"
@export var edge_length: float = 0.5
@export var line_thickness: float = 0.01
@export var face_color: Color = Color(1.0, 0.9, 0.7, 0.8)
@export var edge_color: Color = Color(0.2, 0.2, 0.2, 1.0)
@export var fold_progress: float = 0.0:
	set(value):
		_fold_progress = clamp(value, 0.0, 1.0)
		_apply_fold()
	get:
		return _fold_progress
@export var auto_fold: bool = true
@export var fold_delay: float = 0.4
@export var fold_duration: float = 2.0
@export var fold_hold: float = 0.8
@export var loop_fold: bool = false

## Where the fold has got to. Only `animated` runs a tween; the other three are
## static poses, which is the only way one still frame can carry the answer.
##   animated: the shipped exhibit. auto_fold honoured, delay 0.4, duration 2.0.
##   closed:   the sealed solid. The net has become a cube and the argument is
##             over — this is what the thing IS, with no record of what it was.
##   hinged:   caught at 0.45, the half-open moment. Six faces standing at angles
##             to each other, still flat things, already a volume. The hinges are
##             the whole claim and this is the only pose that shows them.
##   flat:     the net itself, progress 0. Surface area before solid: the plan.
@export_enum("animated", "closed", "hinged", "flat") var fold: String = "animated"

## WHICH of the eleven distinct cube nets is unfolded. Only meaningful when
## net_type is "cube"; the tetra and octa strips ignore it.
##   latin_cross: the shipped net. 1-4-1 — a band of four with the top and
##                bottom flaps on the SAME square. Runs the original builder.
##   staircase:   2-2-2. Three dominoes stepping diagonally; no row of four
##                anywhere, and it still closes.
##   zed:         1-4-1 again, but with the two flaps at OPPOSITE ends of the
##                band. Same family as the default, and it does not look it —
##                which is the point of having it next to the cross.
##   two_rows:    3-3. Two rows of three overlapping in one column, the net that
##                looks least like a cube of any of the eleven.
@export_enum("latin_cross", "staircase", "zed", "two_rows") var net: String = "latin_cross"

const FOLD_VALUES := ["animated", "closed", "hinged", "flat"]
const NET_VALUES := ["latin_cross", "staircase", "zed", "two_rows"]

## Each net as [u, v, parent_index] cells on the flat grid, parent first. The
## hinge direction, and therefore the fold, is DERIVED from the cell delta —
## nothing here is hand-authored geometry, so a wrong entry is a broken net and
## not a subtly wrong one.
##
## `latin_cross` is absent ON PURPOSE: it means "use the shipped builder", so the
## default path never touches this table at all.
const NETS := {
	"staircase": [[0, 0, -1], [1, 0, 0], [1, 1, 1], [2, 1, 2], [2, 2, 3], [3, 2, 4]],
	"zed": [[0, 0, -1], [-1, 0, 0], [1, 0, 0], [2, 0, 2], [-1, 1, 1], [2, -1, 3]],
	"two_rows": [[0, 0, -1], [1, 0, 0], [2, 0, 1], [2, 1, 2], [3, 1, 3], [4, 1, 4]],
}

## Where the pose lands when fold = "hinged". Late enough that the back flap,
## which starts 15% behind the others, is already moving.
const HINGED_AT: float = 0.45

const PrimitiveMeshBuilder = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const GridMaterialFactory = preload("res://commons/primitives/shared/grid_material_factory.gd")

var _cube_root: Node3D
var _cube_hinges: Dictionary = {}
## One record per hinge of a GENERIC net: {node, axis, sign, depth}. Empty for
## latin_cross, which is what routes _apply_fold back to the original code.
var _generic_hinges: Array = []
var _fold_progress: float = 0.0
var _built: bool = false

func _ready():
	match net_type:
		"tetrahedron":
			create_tetrahedron_net()
		"cube":
			create_cube_net()
		"octahedron":
			create_octahedron_net()

	if net_type == "cube":
		_apply_fold_mode()
	_built = true

## At the default this is `if auto_fold: _play_fold_animation()` — character for
## character the line it replaced.
func _apply_fold_mode() -> void:
	match fold:
		"flat":
			fold_progress = 0.0
		"hinged":
			fold_progress = HINGED_AT
		"closed":
			fold_progress = 1.0
		_:
			if auto_fold:
				_play_fold_animation()

func create_tetrahedron_net():
	# Strip of 4 equilateral triangles
	var h = edge_length * sqrt(3.0) / 2.0  # Triangle height

	# 4 triangles laid flat in a strip
	var vertices_3d: Array[Vector3] = [
		# Triangle 1 (leftmost)
		Vector3(-1.5 * edge_length, 0, 0),
		Vector3(-edge_length, 0, 0),
		Vector3(-1.25 * edge_length, 0, h),
		# Triangle 2
		Vector3(-edge_length, 0, 0),
		Vector3(-0.5 * edge_length, 0, 0),
		Vector3(-0.75 * edge_length, 0, h),
		# Triangle 3 (center)
		Vector3(-0.5 * edge_length, 0, 0),
		Vector3(0, 0, 0),
		Vector3(-0.25 * edge_length, 0, h),
		# Triangle 4 (rightmost)
		Vector3(0, 0, 0),
		Vector3(0.5 * edge_length, 0, 0),
		Vector3(0.25 * edge_length, 0, h)
	]

	var faces = [
		[0, 1, 2],    # Triangle 1
		[3, 4, 5],    # Triangle 2
		[6, 7, 8],    # Triangle 3
		[9, 10, 11]   # Triangle 4
	]

	create_net_mesh(vertices_3d, faces)
	add_fold_line_labels()

func create_cube_net():
	if net == "latin_cross" or not NETS.has(net):
		_create_cube_faces()
	else:
		_create_cube_faces_generic(NETS[net])
	add_fold_line_labels()

func create_octahedron_net():
	# Strip of 8 triangles
	var h = edge_length * sqrt(3.0) / 2.0
	var vertices_3d: Array[Vector3] = []
	var faces = []

	# Create strip of 8 triangles alternating up/down
	for i in range(8):
		var x_offset = i * edge_length * 0.5
		var base_idx = vertices_3d.size()

		if i % 2 == 0:  # Point up
			vertices_3d.append(Vector3(x_offset, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.5, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.25, 0, h))
		else:  # Point down
			vertices_3d.append(Vector3(x_offset, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.5, 0, 0))
			vertices_3d.append(Vector3(x_offset + edge_length * 0.25, 0, -h))

		faces.append([base_idx, base_idx + 1, base_idx + 2])

	create_net_mesh(vertices_3d, faces)
	add_fold_line_labels()

func create_net_mesh(vertices: Array[Vector3], faces: Array):
	# Create the flat net with transparency
	var material = GridMaterialFactory.make(face_color, {
		"double_sided": true,
		"edge_color": edge_color
	})

	var mesh_instance = PrimitiveMeshBuilder.build_mesh_instance(
		vertices,
		faces,
		{
			"name": net_type + "_Net",
			"material": material,
			"double_sided": true
		}
	)

	add_child(mesh_instance)

func _create_cube_faces():
	# Build 6 square faces with hinges so we can fold into a cube.
	var s = edge_length
	_cube_root = Node3D.new()
	_cube_root.name = "CubeNet"
	add_child(_cube_root)

	var material = GridMaterialFactory.make(face_color, {
		"double_sided": true,
		"edge_color": edge_color
	})

	# Center face
	var center_face = _make_face(material)
	_cube_root.add_child(center_face)

	# Top face hinge (positive Z)
	var top_hinge = Node3D.new()
	top_hinge.name = "TopHinge"
	top_hinge.position = Vector3(0, 0, s * 0.5)
	_cube_root.add_child(top_hinge)
	var top_face = _make_face(material)
	top_face.position = Vector3(0, 0, s * 0.5)
	top_hinge.add_child(top_face)
	_cube_hinges["top"] = top_hinge

	# Bottom face hinge (negative Z)
	var bottom_hinge = Node3D.new()
	bottom_hinge.name = "BottomHinge"
	bottom_hinge.position = Vector3(0, 0, -s * 0.5)
	_cube_root.add_child(bottom_hinge)
	var bottom_face = _make_face(material)
	bottom_face.position = Vector3(0, 0, -s * 0.5)
	bottom_hinge.add_child(bottom_face)
	_cube_hinges["bottom"] = bottom_hinge

	# Left face hinge (negative X)
	var left_hinge = Node3D.new()
	left_hinge.name = "LeftHinge"
	left_hinge.position = Vector3(-s * 0.5, 0, 0)
	_cube_root.add_child(left_hinge)
	var left_face = _make_face(material)
	left_face.position = Vector3(-s * 0.5, 0, 0)
	left_hinge.add_child(left_face)
	_cube_hinges["left"] = left_hinge

	# Right face hinge (positive X)
	var right_hinge = Node3D.new()
	right_hinge.name = "RightHinge"
	right_hinge.position = Vector3(s * 0.5, 0, 0)
	_cube_root.add_child(right_hinge)
	var right_root = Node3D.new()
	right_hinge.add_child(right_root)
	var right_face = _make_face(material)
	right_face.position = Vector3(s * 0.5, 0, 0)
	right_root.add_child(right_face)
	_cube_hinges["right"] = right_hinge

	# Back face hinge (attached to right face outer edge)
	var back_hinge = Node3D.new()
	back_hinge.name = "BackHinge"
	back_hinge.position = Vector3(s, 0, 0)
	right_root.add_child(back_hinge)
	var back_face = _make_face(material)
	back_face.position = Vector3(s * 0.5, 0, 0)
	back_hinge.add_child(back_face)
	_cube_hinges["back"] = back_hinge

	_apply_fold()

func _make_face(material: Material) -> MeshInstance3D:
	var mesh = PlaneMesh.new()
	mesh.size = Vector2(edge_length, edge_length)
	var face = MeshInstance3D.new()
	face.mesh = mesh
	face.material_override = material
	return face

## The other ten nets, built from a cell table instead of by hand.
##
## Reproduces the shipped hierarchy exactly — hinge at the shared edge, a plain
## root under it, the face half a square further along — so the sign rule below
## is the same one _apply_fold already uses. That is not a coincidence to be
## trusted: the rule was checked by folding all 6-cell polyominoes through it and
## confirming that precisely eleven of them close into a cube.
func _create_cube_faces_generic(spec: Array) -> void:
	var s: float = edge_length
	_cube_root = Node3D.new()
	_cube_root.name = "CubeNet"
	add_child(_cube_root)

	var material = GridMaterialFactory.make(face_color, {
		"double_sided": true,
		"edge_color": edge_color
	})

	_cube_hinges.clear()
	_generic_hinges.clear()

	# Per face: the node its children hang under, its own offset inside that
	# node, and how many hinges deep it sits.
	var roots: Array = []
	var offsets: Array = []
	var depths: Array = []

	var root_face = _make_face(material)
	root_face.name = "Face_0"
	_cube_root.add_child(root_face)
	roots.append(_cube_root)
	offsets.append(Vector3.ZERO)
	depths.append(0)

	for i in range(1, spec.size()):
		var cell: Array = spec[i]
		var parent_index: int = int(cell[2])
		var parent_cell: Array = spec[parent_index]
		var du: int = int(cell[0]) - int(parent_cell[0])
		var dv: int = int(cell[1]) - int(parent_cell[1])

		# Half a square along the shared edge's normal, in the flat plane.
		var step := Vector3(float(du) * s * 0.5, 0.0, float(dv) * s * 0.5)
		# +u and -u swing about Z, +v and -v about X; the sign is whichever
		# takes the child DOWNWARD, which is the direction the shipped net
		# already folds. All four in one place instead of four literals.
		var axis_name: String = "z"
		var sgn: float = -1.0
		if du == 1:
			axis_name = "z"
			sgn = -1.0
		elif du == -1:
			axis_name = "z"
			sgn = 1.0
		elif dv == 1:
			axis_name = "x"
			sgn = 1.0
		else:
			axis_name = "x"
			sgn = -1.0

		var parent_root: Node3D = roots[parent_index]
		var parent_offset: Vector3 = offsets[parent_index]
		var child_depth: int = int(depths[parent_index]) + 1

		var hinge := Node3D.new()
		hinge.name = "Hinge_%d" % i
		hinge.position = parent_offset + step
		parent_root.add_child(hinge)

		var sub := Node3D.new()
		sub.name = "Root_%d" % i
		hinge.add_child(sub)

		var face = _make_face(material)
		face.name = "Face_%d" % i
		face.position = step
		sub.add_child(face)

		roots.append(sub)
		offsets.append(step)
		depths.append(child_depth)
		_generic_hinges.append({
			"node": hinge,
			"axis": axis_name,
			"sign": sgn,
			"depth": child_depth,
		})

	_apply_fold()

func _apply_fold():
	if not _generic_hinges.is_empty():
		_apply_fold_generic()
		return
	if _cube_hinges.is_empty():
		return
	var angle = deg_to_rad(90.0) * fold_progress
	if _cube_hinges.has("top"):
		_cube_hinges["top"].rotation.x = angle
	if _cube_hinges.has("bottom"):
		_cube_hinges["bottom"].rotation.x = -angle
	if _cube_hinges.has("left"):
		_cube_hinges["left"].rotation.z = angle
	if _cube_hinges.has("right"):
		_cube_hinges["right"].rotation.z = -angle
	if _cube_hinges.has("back"):
		# Back tucks under: needs to fold in OPPOSITE direction to close the cube
		# Delay slightly so it follows after right starts folding
		var back_progress = clamp((fold_progress - 0.15) / 0.85, 0.0, 1.0)
		var back_angle = deg_to_rad(90.0) * back_progress
		_cube_hinges["back"].rotation.z = -back_angle  # Negative to tuck under

## Same 90 degrees per hinge, same tuck-under delay for anything hanging off
## another flap — generalised to a chain of any length. At depth 1 the delay is
## zero and at depth 2 it is 0.15/0.85, which is the shipped back-flap formula
## to the digit.
func _apply_fold_generic() -> void:
	for record in _generic_hinges:
		var rec: Dictionary = record
		var node: Node3D = rec["node"]
		if not is_instance_valid(node):
			continue
		var depth: int = int(rec["depth"])
		var delay: float = minf(0.15 * float(depth - 1), 0.75)
		var progress: float = clampf((fold_progress - delay) / (1.0 - delay), 0.0, 1.0)
		var angle: float = deg_to_rad(90.0) * progress * float(rec["sign"])
		if String(rec["axis"]) == "x":
			node.rotation.x = angle
		else:
			node.rotation.z = angle

func _play_fold_animation():
	fold_progress = 0.0
	var tween = create_tween()
	tween.tween_interval(fold_delay)
	tween.tween_property(self, "fold_progress", 1.0, fold_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if loop_fold:
		tween.tween_interval(fold_hold)
		tween.tween_property(self, "fold_progress", 0.0, fold_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tween.set_loops()

func apply_grid_config(config_data: Dictionary) -> void:
	# Allow map strings to control folding behavior (e.g., #fold_duration:6)
	if config_data.has("fold_duration"):
		fold_duration = float(config_data.fold_duration)
	if config_data.has("fold_delay"):
		fold_delay = float(config_data.fold_delay)
	if config_data.has("fold_hold"):
		fold_hold = float(config_data.fold_hold)
	if config_data.has("fold_progress"):
		fold_progress = float(config_data.fold_progress)
	if config_data.has("auto_fold"):
		auto_fold = _parse_bool(config_data.auto_fold)
	if config_data.has("loop_fold"):
		loop_fold = _parse_bool(config_data.loop_fold)

	# The two DNA axes. `net` is the only one that costs a rebuild, so it is the
	# only one guarded on having actually changed — and on _ready having built
	# once, because before that the export alone is enough.
	var want_net: String = net
	if config_data.has("net"):
		want_net = _pick_value(config_data.net, NET_VALUES, net)
	if config_data.has("fold"):
		fold = _pick_value(config_data.fold, FOLD_VALUES, fold)

	var net_changed: bool = want_net != net
	net = want_net
	if net_changed and _built and net_type == "cube":
		_rebuild_cube_net()

	# Re-run animation when requested
	if net_type == "cube":
		_apply_fold_mode()

## An unrecognised string keeps the current value rather than silently becoming
## something else — a typo in a map token should do nothing, not pick a net.
func _pick_value(value, allowed: Array, fallback: String) -> String:
	var text: String = String(value).strip_edges().to_lower()
	if allowed.has(text):
		return text
	return fallback

func _rebuild_cube_net() -> void:
	if _cube_root != null and is_instance_valid(_cube_root):
		_cube_root.queue_free()
	_cube_root = null
	_cube_hinges.clear()
	_generic_hinges.clear()
	if net == "latin_cross" or not NETS.has(net):
		_create_cube_faces()
	else:
		_create_cube_faces_generic(NETS[net])

func _parse_bool(value) -> bool:
	var text = str(value).to_lower()
	return text == "true" or text == "1" or text == "yes" or text == "on"

func add_fold_line_labels():
	# Title removed for cleaner VR presentation
	pass
