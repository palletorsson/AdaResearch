extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MandelbrotBench

## @identity
## The Mandelbrot set on a panel: one question — does z -> z² + c stay bounded? — asked of
## every point c in the plane. Truth: "z -> z² + c, asked of every point". The black body is
## where the iteration never escapes; the burning fringe is where it almost does, and that edge
## is infinitely intricate.

@export var grid: int = 72
@export var max_iter: int = 70
@export var panel_size: float = 0.7
@export var sway: bool = true

const X_MIN: float = -2.2
const X_MAX: float = 0.8
const Y_MIN: float = -1.5
const Y_MAX: float = 1.5

var _panel: Node3D
var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = int(config["grid"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_build_bench()
	add_child(_mandel_field())
	add_child(_billboard_label("z -> z² + c", Vector3(0.0, 1.6, 0.0), 22, Color(1.0, 0.7, 0.35)))


func _build_bench() -> void:
	var top_mat := _matte_mat(Color(0.16, 0.18, 0.22), 0.7, 0.1)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.08, 0.45), top_mat))
	var leg_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_box(Vector3(-0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	# Backing frame for the fractal panel.
	add_child(_box(Vector3(0.0, 1.25, -0.02), Vector3(panel_size + 0.06, panel_size + 0.06, 0.02), _matte_mat(Color(0.08, 0.08, 0.1), 0.6)))


func _mandel_field() -> MultiMeshInstance3D:
	var g: int = clampi(grid, 16, 96)
	var n: int = g * g
	var mi := _field(n, true)
	var mm: MultiMesh = mi.multimesh
	var cell: float = panel_size / float(g)
	var s: float = cell * 0.96
	var base_y: float = 1.25
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var cx: float = X_MIN + (X_MAX - X_MIN) * (float(gx) + 0.5) / float(g)
			var cy: float = Y_MIN + (Y_MAX - Y_MIN) * (float(gy) + 0.5) / float(g)
			var esc: int = _escape(cx, cy)
			var col: Color = _color_for(esc)
			var px: float = -panel_size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = base_y - panel_size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)), Vector3(px, py, 0.0)))
			mm.set_instance_color(i, col)
			i += 1
	return mi


func _escape(cx: float, cy: float) -> int:
	var zr: float = 0.0
	var zi: float = 0.0
	var it: int = 0
	while it < max_iter:
		# z = z*z + c ; (a+bi)^2 = (a^2 - b^2) + (2ab)i
		var nzr: float = zr * zr - zi * zi + cx
		var nzi: float = 2.0 * zr * zi + cy
		zr = nzr
		zi = nzi
		if zr * zr + zi * zi > 4.0:
			break
		it += 1
	return it


func _color_for(esc: int) -> Color:
	if esc >= max_iter:
		return Color(0.02, 0.02, 0.05)
	var t: float = float(esc) / float(max_iter)
	# Warm ramp: deep purple -> red -> orange -> pale yellow as escape gets faster -> slower.
	if t < 0.33:
		return Color(0.25, 0.0, 0.35).lerp(Color(0.9, 0.15, 0.1), t / 0.33)
	elif t < 0.66:
		return Color(0.9, 0.15, 0.1).lerp(Color(1.0, 0.6, 0.1), (t - 0.33) / 0.33)
	else:
		return Color(1.0, 0.6, 0.1).lerp(Color(1.0, 0.95, 0.7), (t - 0.66) / 0.34)


func _field(n: int, box: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = (BoxMesh.new() if box else SphereMesh.new())
	mm.instance_count = n
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.2 if emissive else 0.0
	mi.material_override = mat
	return mi


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if not sway:
		return
	_t += delta
