extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name FractalAntennaToy

## @identity
## name: "Fractal antennas & structures"
## tier: small
## lineage: a Sierpinski gasket folded out of conductor — Mandelbrot's edge, soldered.
## essence: A held self-similar antenna. The same triangle of conductor at three
##   scales: the small notch and the big notch are the same shape, so the metal
##   has a resonant length for every band at once. An infinite edge packed into a
##   palm-sized plate.
## truth: "a self-similar antenna hears every band"
## applications: infinite edge in finite room — recurse a triangle of wire and the
##   same metal answers to many frequencies.

@export var depth: int = 3
@export var side: float = 0.34
@export var wire_radius: float = 0.006
@export var conductor_col: Color = Color(0.86, 0.74, 0.42)
@export var board_col: Color = Color(0.10, 0.16, 0.12)
@export var label_col: Color = Color(0.92, 0.82, 0.50)

var _t: float = 0.0
var _spin_root: Node3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("depth"):
		depth = clampi(int(config["depth"]), 1, 4)
	if config.has("side"):
		side = float(config["side"])
	if config.has("conductor_col"):
		conductor_col = _parse_color(config["conductor_col"], conductor_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_spin_root = null
	_build()


func _build() -> void:
	# Held toy — no table. A thin dielectric board carrying the gasket of wire.
	var root := Node3D.new()
	root.name = "AntennaSpin"
	add_child(root)
	_spin_root = root

	var wire_mat: StandardMaterial3D = _steel_mat(conductor_col)
	var board_mat: StandardMaterial3D = _matte_mat(board_col, 0.5, 0.1)

	var h: float = side * 0.5 * sqrt(3.0)
	# substrate board just behind the conductor
	root.add_child(_box(Vector3(0.0, h * 0.5, -0.01), Vector3(side * 1.18, h * 1.18, 0.012), board_mat))

	# the three outer corners of the master triangle (apex up)
	var a := Vector3(-side * 0.5, 0.0, 0.0)
	var b := Vector3(side * 0.5, 0.0, 0.0)
	var c := Vector3(0.0, h, 0.0)
	_gasket(root, a, b, c, depth, wire_mat)

	# little feed point / coax stub at the base centre
	root.add_child(_cylinder(Vector3(0.0, -0.015, 0.0), wire_radius * 2.2, 0.03, wire_mat))
	root.add_child(_sphere(Vector3(0.0, 0.0, 0.0), wire_radius * 2.6, _glow_mat(conductor_col, 2.0)))

	add_child(_billboard_label("HEARS EVERY BAND", Vector3(0.0, side * 0.92, 0.0), 20, label_col))


func _gasket(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, d: int, mat: Material) -> void:
	# Draw this triangle's three edges as wire.
	parent.add_child(_cylinder_between(a, b, wire_radius, mat))
	parent.add_child(_cylinder_between(b, c, wire_radius, mat))
	parent.add_child(_cylinder_between(c, a, wire_radius, mat))
	if d <= 1:
		return
	# Recurse into the three corner sub-triangles (the central one stays empty).
	var ab: Vector3 = (a + b) * 0.5
	var bc: Vector3 = (b + c) * 0.5
	var ca: Vector3 = (c + a) * 0.5
	_gasket(parent, a, ab, ca, d - 1, mat)
	_gasket(parent, ab, b, bc, d - 1, mat)
	_gasket(parent, ca, bc, c, d - 1, mat)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _spin_root != null:
		_spin_root.rotation.y = sin(_t * 0.6) * 0.25
		_spin_root.rotation.x = cos(_t * 0.45) * 0.05
