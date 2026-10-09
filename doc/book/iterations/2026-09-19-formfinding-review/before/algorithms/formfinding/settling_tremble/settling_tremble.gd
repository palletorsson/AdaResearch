# settling_tremble.gd — SETTLED MEANS TIRED, NOT STILL.
#
# The form-finding seam. A hanging chain finds a true equilibrium — the catenary,
# an exact curve where every link balances. A solver cannot reach it; it relaxes
# the form step by step and stops when the largest move falls below a tolerance,
# epsilon. So the "settled" shape is never at rest: it trembles inside a band of
# width epsilon, and someone chose that width. Amber: the true catenary. Blue:
# the relaxed nodes, each a hair off the ideal. The inset magnifies the seam —
# zoom the settled form and it still shivers. Equilibrium is a limit the machine
# approaches and then declares reached, because it ran out of patience.
extends Node3D
class_name SettlingTremble

@export var epsilon: float = 0.006
@export var nodes: int = 17
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_node: Color = Color(0.3, 0.7, 1.0)


func _ready() -> void:
	_backing()
	var rng := RandomNumberGenerator.new()
	rng.seed = 4021
	# amber true catenary
	var smooth: int = 100
	var prev: Vector2 = _catenary(-0.34)
	for i in range(1, smooth + 1):
		var x: float = lerp(-0.34, 0.34, float(i) / float(smooth))
		var p: Vector2 = _catenary(x)
		_seg(prev, p, color_true, 0.004)
		prev = p
	# blue relaxed nodes — each within epsilon of the ideal
	var bprev: Vector2 = Vector2.ZERO
	var jitters: Array[float] = []
	for i in range(nodes):
		var x2: float = lerp(-0.34, 0.34, float(i) / float(nodes - 1))
		var base: Vector2 = _catenary(x2)
		var jy: float = rng.randf_range(-epsilon, epsilon)
		jitters.append(jy)
		var p2: Vector2 = base + Vector2(0.0, jy)
		if i > 0:
			_seg(bprev, p2, Color(color_node.r, color_node.g, color_node.b, 0.7), 0.003)
		_dot(p2, color_node, 0.006)
		bprev = p2
	_tag("the catenary — true equilibrium", Vector2(0.0, -0.30), color_true, 26)
	# inset: magnify the middle nodes so the tremble is visible
	_inset(jitters)
	_plate("FORM-FINDING",
		"a hanging chain finds an exact curve — the catenary\nthe solver relaxes and stops when the step drops below epsilon\nzoom the 'settled' form: it still trembles — settled means tired, not still",
		Vector3(0.0, 0.34, 0.0), color_node)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_epsilon"):
		epsilon = float(str(get_meta("config_epsilon")))


func _catenary(x: float) -> Vector2:
	var c: float = 0.3
	var y: float = c * cosh(x / c) - 0.5
	return Vector2(x, y)


func _inset(jitters: Array[float]) -> void:
	# a magnified window (top-right) showing the residual tremble at x8
	var ox: float = 0.16
	var oy: float = 0.06
	var mag: float = 8.0
	var span: float = 0.05
	_seg(Vector2(ox - 0.02, oy - 0.09), Vector2(ox + 0.2, oy - 0.09), Color(0.4, 0.44, 0.5), 0.002)
	_seg(Vector2(ox - 0.02, oy + 0.09), Vector2(ox + 0.2, oy + 0.09), Color(0.4, 0.44, 0.5), 0.002)
	# amber ideal (a flat reference line at the inset centre)
	_seg(Vector2(ox - 0.02, oy), Vector2(ox + 0.2, oy), color_true, 0.003)
	var count: int = mini(6, jitters.size())
	var start: int = int((jitters.size() - count) / 2)
	var bprev: Vector2 = Vector2.ZERO
	for k in range(count):
		var x: float = (ox - 0.02) + span * float(k)
		var y: float = oy + jitters[start + k] * mag
		var p: Vector2 = Vector2(x, y)
		if k > 0:
			_seg(bprev, p, Color(color_node.r, color_node.g, color_node.b, 0.8), 0.003)
		_dot(p, color_node, 0.007)
		bprev = p
	_tag("×8 — still trembling", Vector2(ox + 0.09, oy - 0.13), color_node, 22)


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.7, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.0, -0.014)
	add_child(mi)


func _seg(a: Vector2, b: Vector2, color: Color, thick: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), thick, thick)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b)
	mat.emission_energy_multiplier = 0.5
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _dot(p: Vector2, color: Color, r: float) -> void:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mi.material_override = mat
	mi.position = Vector3(p.x, p.y, 0.008)
	add_child(mi)


func _tag(text: String, pos: Vector2, color: Color, fs: int) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = fs
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = Vector3(pos.x, pos.y, 0.01)
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.86, 0.15, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.86, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.083, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 30
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
