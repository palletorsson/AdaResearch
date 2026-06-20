extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name JuliaBench

## @identity
## A Julia set: the same map z -> z² + c, but now c is fixed and the question is asked of the
## starting point z. Truth: "move c, the set breathes". Nudge c by a hair and the whole figure
## reorganises — connected dust, spirals, dendrites — a one-parameter family of worlds.

@export var c_re: float = -0.4
@export var c_im: float = 0.6
@export var grid: int = 72
@export var max_iter: int = 70
@export var panel_size: float = 0.7
@export var animate_c: bool = true

const VIEW: float = 1.6

var _mm_inst: MultiMeshInstance3D
var _readout: Label3D
var _t: float = 0.0
var _base_re: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_base_re = c_re
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("c_re"):
		c_re = float(config["c_re"])
	if config.has("c_im"):
		c_im = float(config["c_im"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_base_re = c_re
	_build()


func _build() -> void:
	_build_bench()
	_mm_inst = _julia_field()
	add_child(_mm_inst)
	add_child(_billboard_label("MOVE c, THE SET BREATHES", Vector3(0.0, 1.6, 0.0), 20, Color(0.6, 0.85, 1.0)))
	_readout = _billboard_label(_c_text(), Vector3(0.0, 0.95, 0.0), 14, Color(0.8, 0.9, 1.0))
	add_child(_readout)


func _build_bench() -> void:
	var top_mat := _matte_mat(Color(0.16, 0.18, 0.22), 0.7, 0.1)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.08, 0.45), top_mat))
	var leg_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_box(Vector3(-0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.0, 1.25, -0.02), Vector3(panel_size + 0.06, panel_size + 0.06, 0.02), _matte_mat(Color(0.08, 0.08, 0.1), 0.6)))


func _c_text() -> String:
	return "c = %+.2f %+.2fi" % [c_re, c_im]


func _julia_field() -> MultiMeshInstance3D:
	var g: int = clampi(grid, 16, 96)
	var n: int = g * g
	var mi := _field(n, true)
	_fill_julia(mi.multimesh, g)
	return mi


func _fill_julia(mm: MultiMesh, g: int) -> void:
	var cell: float = panel_size / float(g)
	var s: float = cell * 0.96
	var base_y: float = 1.25
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var zr: float = -VIEW + 2.0 * VIEW * (float(gx) + 0.5) / float(g)
			var zi: float = -VIEW + 2.0 * VIEW * (float(gy) + 0.5) / float(g)
			var esc: int = _escape(zr, zi)
			var col: Color = _color_for(esc)
			var px: float = -panel_size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = base_y - panel_size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)), Vector3(px, py, 0.0)))
			mm.set_instance_color(i, col)
			i += 1


func _escape(zr0: float, zi0: float) -> int:
	var zr: float = zr0
	var zi: float = zi0
	var it: int = 0
	while it < max_iter:
		var nzr: float = zr * zr - zi * zi + c_re
		var nzi: float = 2.0 * zr * zi + c_im
		zr = nzr
		zi = nzi
		if zr * zr + zi * zi > 4.0:
			break
		it += 1
	return it


func _color_for(esc: int) -> Color:
	if esc >= max_iter:
		return Color(0.02, 0.03, 0.08)
	var t: float = float(esc) / float(max_iter)
	# Cool ramp: deep blue -> cyan -> teal -> pale, evoking the "breathing" Julia palette.
	if t < 0.33:
		return Color(0.05, 0.0, 0.3).lerp(Color(0.1, 0.3, 0.9), t / 0.33)
	elif t < 0.66:
		return Color(0.1, 0.3, 0.9).lerp(Color(0.2, 0.85, 0.85), (t - 0.33) / 0.33)
	else:
		return Color(0.2, 0.85, 0.85).lerp(Color(0.85, 1.0, 0.95), (t - 0.66) / 0.34)


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
	if not animate_c:
		return
	_t += delta
	# Slowly orbit c so the set visibly breathes; rebuild the grid at a modest cadence.
	c_re = _base_re + 0.12 * sin(_t * 0.35)
	c_im = 0.6 + 0.08 * cos(_t * 0.3)
	if _mm_inst != null and _mm_inst.multimesh != null:
		var g: int = clampi(grid, 16, 96)
		_fill_julia(_mm_inst.multimesh, g)
	if _readout != null:
		_readout.text = _c_text()
