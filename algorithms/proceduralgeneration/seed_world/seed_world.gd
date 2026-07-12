# seed_world.gd — THE WORLD WAS NEVER STORED, ONLY THE SEED.
#
# The procedural-generation seam. An open world promises infinite variety, more
# terrain than anyone could author. The truth is smaller and stranger: the world
# is a finite formula fed one number. Nothing is stored — not the mountains, not
# the coastline — only the seed and the recipe. Walk away and the terrain is
# freed from memory; walk back and it is rebuilt bit-for-bit from the same seed.
# Here are two visits to the same seed, drawn side by side: identical, because
# they are not two worlds but one number run twice. Infinity you can explore, and
# a compression so total the place has no existence between your visits.
extends Node3D
class_name SeedWorld

@export var world_seed: int = 20250712
@export var samples: int = 60
@export var color_world: Color = Color(1.0, 0.62, 0.18)
@export var color_seed: Color = Color(0.3, 0.7, 1.0)


func _ready() -> void:
	_backing()
	var heights: Array[float] = _terrain(world_seed)
	# stacked at the SAME x so identical shapes read as identical under any camera yaw
	_draw_terrain(heights, Vector2(-0.18, 0.04), "first visit")
	_draw_terrain(heights, Vector2(-0.18, -0.22), "walk away, return — identical")
	_tag("seed %d" % world_seed, Vector2(0.30, -0.09), color_seed, 30)
	_plate("PROCEDURAL",
		"infinite variety is a finite formula fed one number\nnothing is stored between visits — only the seed\nleave and return: rebuilt bit-for-bit, the same place twice",
		Vector3(0.0, 0.40, 0.0), color_seed)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_world_seed"):
		world_seed = int(str(get_meta("config_world_seed")))


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.88, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.06, -0.016)
	add_child(mi)


func _terrain(s: int) -> Array[float]:
	var n := FastNoiseLite.new()
	n.seed = s
	n.frequency = 0.09
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var out: Array[float] = []
	for i in range(samples):
		var v: float = (n.get_noise_2d(float(i), 0.0) + 1.0) * 0.5
		# a second octave for a mountainous silhouette
		var v2: float = (n.get_noise_2d(float(i) * 2.7, 11.0) + 1.0) * 0.5
		out.append(clampf(v * 0.72 + v2 * 0.28, 0.0, 1.0))
	return out


func _draw_terrain(heights: Array[float], origin: Vector2, label: String) -> void:
	var w: float = 0.36
	var maxh: float = 0.15
	var dx: float = w / float(samples - 1)
	var prev: Vector2 = Vector2.ZERO
	for i in range(samples):
		var x: float = origin.x + float(i) * dx
		var y: float = origin.y + heights[i] * maxh
		var p: Vector2 = Vector2(x, y)
		# faint vertical fill down to the baseline
		_seg(Vector2(x, origin.y), p, Color(color_world.r, color_world.g, color_world.b, 0.22), 0.004)
		if i > 0:
			_seg(prev, p, color_world, 0.005)
		prev = p
	# baseline
	_seg(Vector2(origin.x, origin.y), Vector2(origin.x + w, origin.y), Color(0.4, 0.44, 0.5), 0.003)
	_tag(label, Vector2(origin.x + w * 0.5, origin.y - 0.05), color_world, 24)


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
