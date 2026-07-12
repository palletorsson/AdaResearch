# rule30_random.gd — DETERMINISM WEARING RANDOMNESS.
#
# The cellular-automata seam. Rule 30, run from a single lit cell, produces a
# centre column that passes the standard tests for randomness — it shipped for
# years as the random-number generator inside Mathematica. And yet it is a
# fixed rule on a fixed seed: rewind it and every "random" bit returns, exactly.
# The crank in another costume. The triangle is the whole proof, drawn once:
# structure this intricate, this unpredictable-looking, from three cells and an
# XOR — and none of it is chance.
extends Node3D
class_name Rule30Random

@export var rows: int = 48
@export var cell: float = 0.014
@export var color_on: Color = Color(0.95, 0.96, 1.0)
@export var color_col: Color = Color(1.0, 0.62, 0.18)   # the "random" centre column
@export var color_off: Color = Color(0.10, 0.11, 0.14)


func _ready() -> void:
	var w: int = rows * 2 + 1
	var state: Array = []
	for _i in range(w):
		state.append(0)
	state[rows] = 1
	var mid: int = rows
	var x0: float = -float(w) * cell * 0.5
	var y0: float = float(rows) * cell * 0.5
	for r in range(rows):
		for c in range(w):
			if state[c] == 1:
				var col: Color = color_col if c == mid else color_on
				_cell(x0 + float(c) * cell, y0 - float(r) * cell, col)
		state = _step(state)
	_plate("RULE 30",
		"one lit cell · new = left XOR (centre OR right)\nthe amber column passed the randomness tests —\nyet rewind the seed and every bit returns, exact",
		Vector3(0.0, y0 + 0.13, 0.0), color_col)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_rows"):
		rows = int(str(get_meta("config_rows")))


func _step(s: Array) -> Array:
	var n: int = s.size()
	var out: Array = []
	for i in range(n):
		var l: int = s[i - 1] if i > 0 else 0
		var c: int = s[i]
		var rr: int = s[i + 1] if i < n - 1 else 0
		# Rule 30: left XOR (centre OR right)
		out.append((l ^ (c | rr)) & 1)
	return out


func _cell(x: float, y: float, color: Color) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(cell * 0.92, cell * 0.92, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.25
	mi.material_override = mat
	mi.position = Vector3(x, y, 0.0)
	add_child(mi)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.82, 0.13, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.82, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.072, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 32
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
