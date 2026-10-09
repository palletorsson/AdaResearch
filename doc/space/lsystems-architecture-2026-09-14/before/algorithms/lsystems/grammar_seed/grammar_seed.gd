# grammar_seed.gd — THE WHOLE TREE IS A FEW BYTES, RUN.
#
# The L-systems seam, and the compression thesis made literal. This plant is
# not stored. It is a tiny grammar — an axiom and two rewrite rules — expanded
# a few times and walked by a turtle. A handful of bytes become a forest. That
# is the machine's native drive (compression) seen as a gift instead of a
# theft: a short seed with a costly, branching run. And the cost of the gift is
# reproducibility — the seam under the beauty: run the same grammar again and
# you get the same tree, leaf for leaf. Two "different" plants from one seed are
# identical. The organic was a formula the whole time.
extends Node3D
class_name GrammarSeed

@export var iterations: int = 4
@export var angle_deg: float = 22.0
@export var step: float = 0.016
@export var color_plant: Color = Color(1.0, 0.62, 0.18)


func _ready() -> void:
	var s: String = _expand("X", iterations)
	_draw_turtle(s)
	_plate("THE SEED",
		"axiom  X\nX → F+[[X]-X]-F[-FX]+X\nF → FF        (%d iterations)\n\nthe whole tree is these few bytes, run —\nand run again, identical, leaf for leaf" % iterations,
		Vector3(0.42, 0.14, 0.0), color_plant)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_iterations"):
		iterations = int(str(get_meta("config_iterations")))


func _expand(axiom: String, iters: int) -> String:
	var s: String = axiom
	for _i in range(iters):
		var out: String = ""
		for ch in s:
			if ch == "X":
				out += "F+[[X]-X]-F[-FX]+X"
			elif ch == "F":
				out += "FF"
			else:
				out += ch
			if out.length() > 60000:
				break
		s = out
	return s


func _draw_turtle(s: String) -> void:
	var pos: Vector2 = Vector2(-0.34, -0.30)
	var ang: float = 90.0
	var stack: Array = []
	for ch in s:
		if ch == "F":
			var rad: float = deg_to_rad(ang)
			var nxt: Vector2 = pos + Vector2(cos(rad), sin(rad)) * step
			_seg(pos, nxt)
			pos = nxt
		elif ch == "+":
			ang += angle_deg
		elif ch == "-":
			ang -= angle_deg
		elif ch == "[":
			stack.push_back([pos, ang])
		elif ch == "]":
			if not stack.is_empty():
				var st = stack.pop_back()
				pos = st[0]
				ang = st[1]


func _seg(a: Vector2, b: Vector2) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), 0.0035, 0.0035)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color_plant
	mat.emission_enabled = true
	mat.emission = color_plant
	mat.emission_energy_multiplier = 0.4
	mi.material_override = mat
	mi.position = Vector3((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, 0.0)
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.5, 0.28, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.5, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.15, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n\n" + body
	t.font_size = 30
	t.pixel_size = 0.00038
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
