extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name WhereTheMachineStops

## @identity
## lineage: fractals' cheat-code is that infinity is a promise the machine refuses to
##   keep. Every other fractal gallery in this corpus photographs the promise. This one
##   photographs the refusal.
## essence: a Sierpinski tetrahedron at depths one through six — 4, 16, 64, 256, 1024 and
##   4096 cells — with the count etched on the sill of every frame. The seventh value is
##   `refused`: the root tetrahedron's six edges in wire and NOTHING inside, because
##   depth seven is 16,384 cells and the machine declines. That frame is not an error
##   state. It is the honest one.
## truth: the recursion is defined for all n. The object exists for six of them. The gap
##   between those two sentences is the entire sequence, and it has a number: the frame
##   where the count stopped being paid for.
## critical_parameter: depth — d1..d6 build, `refused` does not. The refusal is a VALUE of
##   the axis rather than a failure of it, which is the only way a limit gets photographed.
## triggers: none. Built once in _ready.
##
## Built 2026-08-27 for fractals-dna, the last of three sequences with no DNA gallery.

const BRASS := Color(0.77, 0.69, 0.48)
const BRASS_DARK := Color(0.44, 0.38, 0.25)
const STONE := Color(0.13, 0.13, 0.15)
const REFUSAL := Color(0.86, 0.42, 0.30)

const DEPTHS := {"d1": 1, "d2": 2, "d3": 3, "d4": 4, "d5": 5, "d6": 6}
const SIDE := 2.6

@export var seed: int = 6
## d1..d6 build the solid. `refused` draws the outline and nothing inside.
@export_enum("d1", "d2", "d3", "d4", "d5", "d6", "refused") var depth: String = "d4"
@export var show_count: bool = true


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("depth"):
		depth = str(config_data["depth"])
	if config_data.has("show_count"):
		show_count = bool(config_data["show_count"])
	if config_data.has("seed"):
		seed = int(config_data["seed"])
	for c in get_children():
		c.queue_free()
	_build()


func _corners(centre: Vector3, s: float) -> Array:
	var h: float = s * 0.5
	return [
		centre + Vector3(-h, -h * 0.7, -h),
		centre + Vector3(h, -h * 0.7, -h),
		centre + Vector3(0.0, -h * 0.7, h),
		centre + Vector3(0.0, h * 1.05, 0.0),
	]


func _build() -> void:
	_rng.seed = seed
	add_child(_box(Vector3(0, -SIDE * 0.42, 0), Vector3(SIDE * 0.62, 0.05, SIDE * 0.62),
		_matte_mat(STONE, 0.9, 0.0)))

	var pts: Array = _corners(Vector3.ZERO, SIDE)

	if depth == "refused":
		# the promise, drawn, and nothing keeping it
		var wire := _glow_mat(REFUSAL, 1.4)
		for i in range(4):
			for j in range(i + 1, 4):
				add_child(_cylinder_between(pts[i], pts[j], 0.012, wire))
		if show_count:
			_sill("16384 — refused", REFUSAL)
		return

	var n: int = int(DEPTHS.get(depth, 4))
	var mat := _glow_mat(BRASS, 0.55)
	var cells: int = _sierpinski(Vector3.ZERO, SIDE, n, mat)
	if show_count:
		_sill("%d" % cells, BRASS)


## Returns how many solid cells it placed — the number the frame is really about.
func _sierpinski(centre: Vector3, s: float, n: int, mat: Material) -> int:
	if n <= 0:
		add_child(_tetra(centre, s, mat))
		return 1
	var half: float = s * 0.5
	var total: int = 0
	for c in _corners(centre, s):
		var sub: Vector3 = centre + (c - centre) * 0.5
		total += _sierpinski(sub, half, n - 1, mat)
	return total


## A tetrahedron from four triangles. SurfaceTool rather than four boxes: at depth six
## there are 4,096 of these and the cell has to be one cheap mesh, not a node tree.
func _tetra(centre: Vector3, s: float, mat: Material) -> MeshInstance3D:
	var p: Array = _corners(centre, s)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var faces := [[0, 2, 1], [0, 1, 3], [1, 2, 3], [2, 0, 3]]
	for f in faces:
		var a: Vector3 = p[int(f[0])]
		var b: Vector3 = p[int(f[1])]
		var c: Vector3 = p[int(f[2])]
		var nrm: Vector3 = (b - a).cross(c - a).normalized()
		for v in [a, b, c]:
			st.set_normal(nrm)
			st.add_vertex(v)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	return mi


func _sill(text: String, col: Color) -> void:
	var l := _billboard_label(text, Vector3(0, -SIDE * 0.36, SIDE * 0.40), 96, col)
	l.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	l.rotation_degrees = Vector3(-90, 0, 0)
	l.outline_size = 0
	add_child(l)
