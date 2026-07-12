# banding_gradient.gd — THE COLORS BETWEEN THE STEPS WERE NEVER SAYABLE.
#
# The color seam (the gamut + bit-depth crack). Real light is a continuum; the
# machine gives it three channels of eight bits — a finite lattice. A smooth
# gradient becomes a stack of steps (banding), and the colors between the steps
# are not dimmed, they simply have no address. Each row below quantizes the
# same gradient to fewer levels: eat the mushroom and your gamut shrinks, from
# a near-smooth sweep to a posterized handful. The staircase was always there;
# the top row just hid it below your eye.
extends Node3D
class_name BandingGradient

@export var width: float = 0.95
@export var row_h: float = 0.09
@export var c0: Color = Color(0.10, 0.30, 0.85)   # deep blue
@export var c1: Color = Color(1.0, 0.72, 0.16)    # amber
@export var levels: Array = [48, 12, 6, 3, 2]


func _ready() -> void:
	var n: int = levels.size()
	var top: float = float(n - 1) * 0.5 * (row_h + 0.01)
	for r in range(n):
		var L: int = int(levels[r])
		var y: float = top - float(r) * (row_h + 0.01)
		_row(L, y)
		_tag("%d" % L, Vector3(width * 0.5 + 0.07, y, 0.0))
	_plate("THE GAMUT",
		"real light is a continuum · the machine gives 3×8 bits\n%d levels → %d — the smooth becomes steps (banding)\nthe colors between the steps were never sayable"
			% [int(levels[0]), int(levels[n - 1])],
		Vector3(0.0, top + row_h * 0.9, 0.0), c1)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])


func _row(L: int, y: float) -> void:
	var cell_w: float = width / float(L)
	for i in range(L):
		var f: float = float(i) / float(maxi(L - 1, 1))
		var col: Color = c0.lerp(c1, f)
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(cell_w * 0.98, row_h, 0.006)
		mi.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = col
		mat.emission_enabled = true
		mat.emission = col
		mat.emission_energy_multiplier = 0.25
		mi.material_override = mat
		var x: float = -width * 0.5 + (float(i) + 0.5) * cell_w
		mi.position = Vector3(x, y, 0.0)
		add_child(mi)


func _tag(text: String, pos: Vector3) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 32
	t.pixel_size = 0.0005
	t.modulate = Color(0.7, 0.75, 0.85)
	t.position = pos
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.86, 0.12, 0.008)
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
	strip.position = pos + Vector3(0.0, 0.065, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 32
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
