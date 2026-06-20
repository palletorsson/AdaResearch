extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LyapunovBench

## @identity
## A Lyapunov fractal: over a grid of two growth rates (a, b), drive the logistic map with a
## repeating AB sequence and average log|r·(1-2x)|. Truth: "stability as a landscape". Negative
## exponent = orbits converge = order (green); positive = orbits diverge = chaos (dark). The
## boundary between them is the marbled coastline you see.

@export var grid: int = 64
@export var warmup: int = 60
@export var sample: int = 80
@export var panel_size: float = 0.7
@export var sequence: String = "AABAB"
@export var sway: bool = true

const A_MIN: float = 2.5
const A_MAX: float = 4.0
const B_MIN: float = 2.5
const B_MAX: float = 4.0

var _t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("sequence"):
		sequence = str(config["sequence"])
	if config.has("grid"):
		grid = int(config["grid"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	_build_bench()
	add_child(_lyapunov_field())
	add_child(_billboard_label("STABILITY AS A LANDSCAPE", Vector3(0.0, 1.6, 0.0), 19, Color(0.6, 0.95, 0.6)))
	add_child(_billboard_label("seq " + _seq_clean(), Vector3(0.0, 0.95, 0.0), 13, Color(0.8, 0.9, 0.8)))


func _build_bench() -> void:
	var top_mat := _matte_mat(Color(0.16, 0.18, 0.22), 0.7, 0.1)
	add_child(_box(Vector3(0.0, 0.85, 0.0), Vector3(1.1, 0.08, 0.45), top_mat))
	var leg_mat := _steel_mat(Color(0.3, 0.32, 0.36))
	add_child(_box(Vector3(-0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.45, 0.42, 0.0), Vector3(0.06, 0.85, 0.06), leg_mat))
	add_child(_box(Vector3(0.0, 1.25, -0.02), Vector3(panel_size + 0.06, panel_size + 0.06, 0.02), _matte_mat(Color(0.06, 0.07, 0.06), 0.6)))


func _seq_clean() -> String:
	var s: String = sequence.to_upper()
	var out: String = ""
	for i in range(s.length()):
		var ch: String = s[i]
		if ch == "A" or ch == "B":
			out += ch
	if out.length() == 0:
		out = "AB"
	return out


func _lyapunov_field() -> MultiMeshInstance3D:
	var g: int = clampi(grid, 16, 80)
	var n: int = g * g
	var mi := _field(n, true)
	var mm: MultiMesh = mi.multimesh
	var seq: String = _seq_clean()
	var cell: float = panel_size / float(g)
	var s: float = cell * 0.96
	var base_y: float = 1.25
	var i: int = 0
	for gy in range(g):
		for gx in range(g):
			var a: float = A_MIN + (A_MAX - A_MIN) * (float(gx) + 0.5) / float(g)
			var b: float = B_MIN + (B_MAX - B_MIN) * (float(gy) + 0.5) / float(g)
			var lam: float = _lyapunov(a, b, seq)
			var col: Color = _color_for(lam)
			var px: float = -panel_size * 0.5 + (float(gx) + 0.5) * cell
			var py: float = base_y - panel_size * 0.5 + (float(gy) + 0.5) * cell
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(s, s, cell * 0.4)), Vector3(px, py, 0.0)))
			mm.set_instance_color(i, col)
			i += 1
	return mi


func _lyapunov(a: float, b: float, seq: String) -> float:
	var x: float = 0.5
	var seq_len: int = seq.length()
	# Warm-up so the orbit settles onto its attractor.
	for k in range(warmup):
		var r: float = a if seq[k % seq_len] == "A" else b
		x = r * x * (1.0 - x)
	var total: float = 0.0
	var count: int = 0
	for k in range(sample):
		var r2: float = a if seq[(warmup + k) % seq_len] == "A" else b
		x = r2 * x * (1.0 - x)
		var d: float = absf(r2 * (1.0 - 2.0 * x))
		if d > 1e-9:
			total += log(d)
			count += 1
	if count == 0:
		return 0.0
	return total / float(count)


func _color_for(lam: float) -> Color:
	if lam < 0.0:
		# Stable: deeper green for more strongly converging.
		var t: float = clampf(-lam / 1.2, 0.0, 1.0)
		return Color(0.04, 0.2, 0.06).lerp(Color(0.3, 1.0, 0.5), t)
	else:
		# Chaotic: warm/dark, brighter for more violently diverging.
		var t2: float = clampf(lam / 0.8, 0.0, 1.0)
		return Color(0.12, 0.05, 0.02).lerp(Color(0.85, 0.35, 0.1), t2)


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
