extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name EscapeTimeRoom

## @identity
## A room walled with escape-time fractals — Mandelbrot, a Julia, and Newton basins — each a
## different iteration asked of every point. Truth: "the edge of chaos". The flat interiors are
## decided fast; all the structure lives on the boundary where the answer takes forever to settle.

@export var grid: int = 60
@export var max_iter: int = 60
@export var room_size: float = 7.0
@export var wall_height: float = 3.0
@export var sway: bool = false

const J_C_RE: float = -0.8
const J_C_IM: float = 0.156

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
	_build_room()
	# Three fractal walls. Each is one MultiMesh so the whole room stays cheap.
	var half: float = room_size * 0.5
	add_child(_wall_field("mandel", Vector3(0.0, wall_height * 0.55, -half + 0.05), Vector3.FORWARD))
	add_child(_wall_field("julia", Vector3(-half + 0.05, wall_height * 0.55, 0.0), Vector3.RIGHT))
	add_child(_wall_field("newton", Vector3(half - 0.05, wall_height * 0.55, 0.0), Vector3.LEFT))
	add_child(_billboard_label("THE EDGE OF CHAOS", Vector3(0.0, 3.6, 0.0), 28, Color(1.0, 0.6, 0.3)))
	add_child(_billboard_label("MANDELBROT", Vector3(0.0, wall_height * 0.55 + 1.6, -half + 0.1), 16, Color(1.0, 0.7, 0.4)))
	add_child(_billboard_label("JULIA", Vector3(-half + 0.1, wall_height * 0.55 + 1.6, 0.0), 16, Color(0.5, 0.85, 1.0)))
	add_child(_billboard_label("NEWTON", Vector3(half - 0.1, wall_height * 0.55 + 1.6, 0.0), 16, Color(0.6, 1.0, 0.7)))


func _build_room() -> void:
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(room_size, 0.1, room_size), _matte_mat(Color(0.1, 0.11, 0.13), 0.85)))
	var half: float = room_size * 0.5
	var wall_mat := _matte_mat(Color(0.05, 0.05, 0.07), 0.7)
	# Backing walls behind the fractal panels (south/west/east) + a plain north wall.
	add_child(_box(Vector3(0.0, wall_height * 0.5, -half), Vector3(room_size, wall_height, 0.1), wall_mat))
	add_child(_box(Vector3(-half, wall_height * 0.5, 0.0), Vector3(0.1, wall_height, room_size), wall_mat))
	add_child(_box(Vector3(half, wall_height * 0.5, 0.0), Vector3(0.1, wall_height, room_size), wall_mat))


func _wall_field(kind: String, origin: Vector3, normal: Vector3) -> MultiMeshInstance3D:
	var g: int = clampi(grid, 16, 80)
	var n: int = g * g
	var mi := _field(n, true)
	var mm: MultiMesh = mi.multimesh
	var panel: float = room_size * 0.85
	var cell: float = panel / float(g)
	var s: float = cell * 0.96
	# Build a basis: the panel lies in the plane perpendicular to `normal`.
	var up := Vector3.UP
	var right: Vector3 = up.cross(normal).normalized()
	if right.length() < 0.001:
		right = Vector3.RIGHT
	var depth: float = cell * 0.4
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var u: float = (float(gx) + 0.5) / float(g)
			var v: float = (float(gy) + 0.5) / float(g)
			var col: Color = _sample(kind, u, v)
			var local_x: float = (u - 0.5) * panel
			var local_y: float = (v - 0.5) * panel
			var pos: Vector3 = origin + right * local_x + up * local_y
			var basis := Basis(right, up, normal).scaled(Vector3(s, s, depth))
			mm.set_instance_transform(i, Transform3D(basis, pos))
			mm.set_instance_color(i, col)
			i += 1
	return mi


func _sample(kind: String, u: float, v: float) -> Color:
	if kind == "mandel":
		var cx: float = -2.2 + 3.0 * u
		var cy: float = -1.5 + 3.0 * v
		return _mandel_color(cx, cy)
	elif kind == "julia":
		var zr: float = -1.6 + 3.2 * u
		var zi: float = -1.6 + 3.2 * v
		return _julia_color(zr, zi)
	else:
		var nx: float = -1.5 + 3.0 * u
		var ny: float = -1.5 + 3.0 * v
		return _newton_color(nx, ny)


func _mandel_color(cx: float, cy: float) -> Color:
	var zr: float = 0.0
	var zi: float = 0.0
	var it: int = 0
	while it < max_iter:
		var nzr: float = zr * zr - zi * zi + cx
		var nzi: float = 2.0 * zr * zi + cy
		zr = nzr
		zi = nzi
		if zr * zr + zi * zi > 4.0:
			break
		it += 1
	if it >= max_iter:
		return Color(0.02, 0.02, 0.05)
	var t: float = float(it) / float(max_iter)
	return Color(0.25, 0.0, 0.35).lerp(Color(1.0, 0.7, 0.2), t)


func _julia_color(zr0: float, zi0: float) -> Color:
	var zr: float = zr0
	var zi: float = zi0
	var it: int = 0
	while it < max_iter:
		var nzr: float = zr * zr - zi * zi + J_C_RE
		var nzi: float = 2.0 * zr * zi + J_C_IM
		zr = nzr
		zi = nzi
		if zr * zr + zi * zi > 4.0:
			break
		it += 1
	if it >= max_iter:
		return Color(0.02, 0.03, 0.08)
	var t: float = float(it) / float(max_iter)
	return Color(0.05, 0.0, 0.3).lerp(Color(0.3, 0.9, 0.95), t)


func _newton_color(zr0: float, zi0: float) -> Color:
	# z -> z - (z^3 - 1)/(3 z^2); colour by which cube root of unity it converges to.
	var zr: float = zr0
	var zi: float = zi0
	var it: int = 0
	while it < max_iter:
		# f = z^3 - 1
		var z2r: float = zr * zr - zi * zi
		var z2i: float = 2.0 * zr * zi
		var z3r: float = z2r * zr - z2i * zi
		var z3i: float = z2r * zi + z2i * zr
		var fr: float = z3r - 1.0
		var fi: float = z3i
		# f' = 3 z^2
		var dr: float = 3.0 * z2r
		var di: float = 3.0 * z2i
		var denom: float = dr * dr + di * di
		if denom < 1e-12:
			break
		# f / f' = (fr+fi i)(dr-di i)/denom
		var qr: float = (fr * dr + fi * di) / denom
		var qi: float = (fi * dr - fr * di) / denom
		zr -= qr
		zi -= qi
		if qr * qr + qi * qi < 1e-8:
			break
		it += 1
	# Identify root: roots are (1,0), (-0.5, 0.866), (-0.5, -0.866).
	var shade: float = 1.0 - clampf(float(it) / float(max_iter), 0.0, 0.7)
	if zi > 0.4:
		return Color(0.2, 0.8, 0.4) * shade
	elif zi < -0.4:
		return Color(0.3, 0.5, 1.0) * shade
	else:
		return Color(1.0, 0.6, 0.3) * shade


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
