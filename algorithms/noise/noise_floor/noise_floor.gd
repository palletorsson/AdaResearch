# noise_floor.gd — WHAT PROCGEN CALLS "NOISE" IS THE CRANK.
#
# The noise seam. Two grids. LEFT: gradient (Perlin/simplex) noise — the smooth,
# rolling field procgen calls "noise" and uses for terrain, cloud, texture. It
# looks organic. It is a seeded formula: the same field every run, rewindable,
# ownable. RIGHT: white noise — a fresh random value in every cell, structure-
# less, the incompressible entropy floor where signal = noise. The one on the
# left is a crank in a smoother coat; the one on the right is the real thing,
# and it is the one procgen never uses, because you cannot build a world on a
# field that has no shape. Real noise is too structureless to be useful — so
# the "noise" you meet is always manufactured.
extends Node3D
class_name NoiseFloor

@export var cols: int = 18
@export var rows: int = 22
@export var cell: float = 0.018
@export var noise_seed: int = 1955


func _ready() -> void:
	var n := FastNoiseLite.new()
	n.seed = noise_seed
	n.frequency = 0.14
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var rng := RandomNumberGenerator.new()
	rng.seed = noise_seed
	var lx: float = -0.30 - float(cols) * cell * 0.5
	var rx: float = 0.30 - float(cols) * cell * 0.5
	var y0: float = float(rows) * cell * 0.5
	for r in range(rows):
		for c in range(cols):
			var y: float = y0 - float(r) * cell
			var gv: float = (n.get_noise_2d(float(c), float(r)) + 1.0) * 0.5
			_cell(lx + float(c) * cell, y, gv)
			var wv: float = rng.randf()
			_cell(rx + float(c) * cell, y, wv)
	_tag("gradient noise — a seeded formula", Vector3(-0.30, -y0 - 0.04, 0.0), Color(0.55, 0.75, 1.0))
	_tag("white noise — the floor", Vector3(0.30, -y0 - 0.04, 0.0), Color(0.95, 0.96, 1.0))
	_plate("NOISE",
		"the left field is what procgen calls 'noise':\nsmooth, organic-looking, seeded — the same every run\nthe right is real noise: structureless, incompressible\nand useless — so the noise you meet is always made",
		Vector3(0.0, y0 + 0.14, 0.0), Color(0.55, 0.75, 1.0))


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_noise_seed"):
		noise_seed = int(str(get_meta("config_noise_seed")))


func _cell(x: float, y: float, v: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(cell * 0.94, cell * 0.94, 0.005)
	mi.mesh = bm
	var g: float = clampf(v, 0.0, 1.0)
	var col := Color(g, g, g)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.2
	mi.material_override = mat
	mi.position = Vector3(x, y, 0.0)
	add_child(mi)


func _tag(text: String, pos: Vector3, color: Color) -> void:
	var t := Label3D.new()
	t.text = text
	t.font_size = 28
	t.pixel_size = 0.00044
	t.modulate = color
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos
	add_child(t)


func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.84, 0.15, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.84, 0.01, 0.012)
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
