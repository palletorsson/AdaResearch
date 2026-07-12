# tick_flock.gd — NO BIRD, JUST THE UPDATE LOOP.
#
# The swarm-intelligence seam. A flock looks alive — emergence, a whole that
# exceeds its parts. Underneath there is no whole and no life: N agents, each
# reading its neighbours and doing a little arithmetic, all of it advanced one
# discrete tick at a time. Between ticks nothing moves; the smooth glide is a
# row of frozen frames the eye splices. Blue: each boid's positions, one per
# tick, visibly separated — it teleports, it does not fly. Amber: the continuous
# arc we imagine it tracing. Slow the clock and the flock is bookkeeping: a for-
# loop over structs, running fast enough to fool a nervous system into seeing a
# bird.
extends Node3D
class_name TickFlock

@export var count: int = 14
@export var color_boid: Color = Color(0.3, 0.7, 1.0)
@export var color_true: Color = Color(1.0, 0.62, 0.18)


func _ready() -> void:
	_backing()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7731
	var heading: float = deg_to_rad(28.0)
	var hdir: Vector2 = Vector2(cos(heading), sin(heading))
	var tick_gap: float = 0.05
	for i in range(count):
		var cx: float = rng.randf_range(-0.28, 0.10)
		var cy: float = rng.randf_range(-0.22, 0.18)
		var pos: Vector2 = Vector2(cx, cy)
		var hj: float = heading + deg_to_rad(rng.randf_range(-14.0, 14.0))
		var dir: Vector2 = Vector2(cos(hj), sin(hj))
		# trailing tick positions — discrete jumps, fading back
		for k in range(1, 4):
			var tp: Vector2 = pos - dir * tick_gap * float(k)
			var a: float = 0.5 - 0.13 * float(k)
			_dot(tp, Color(color_boid.r, color_boid.g, color_boid.b, a), 0.006)
		_arrow(pos, dir, color_boid, 0.05)
	# one highlighted boid: amber smooth arc vs its blue tick-dots
	var hp: Vector2 = Vector2(0.16, -0.02)
	var amber_prev: Vector2 = Vector2.ZERO
	var samp: int = 40
	for s in range(samp + 1):
		var t: float = float(s) / float(samp)
		var x: float = hp.x - 0.26 + t * 0.30
		var y: float = hp.y - 0.10 + sin(t * PI) * 0.12
		var p: Vector2 = Vector2(x, y)
		if s > 0:
			_seg(amber_prev, p, Color(color_true.r, color_true.g, color_true.b, 0.7), 0.003)
		amber_prev = p
	for tk in range(7):
		var t2: float = float(tk) / 6.0
		var x2: float = hp.x - 0.26 + t2 * 0.30
		var y2: float = hp.y - 0.10 + sin(t2 * PI) * 0.12
		_dot(Vector2(x2, y2), color_boid, 0.008)
	_tag("one boid: amber flight vs blue ticks", Vector2(0.03, -0.28), color_true, 24)
	_tag("TICK 7", Vector2(-0.30, 0.24), color_boid, 26)
	_plate("SWARM",
		"emergence looks alive — a whole beyond its parts\nunder it: N agents, each doing arithmetic on a discrete tick\nslow the clock and the flock is a for-loop — no bird, just the update",
		Vector3(0.0, 0.37, 0.0), color_boid)


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_count"):
		count = int(str(get_meta("config_count")))


func _arrow(pos: Vector2, dir: Vector2, color: Color, length: float) -> void:
	var tip: Vector2 = pos + dir * length
	_seg(pos, tip, color, 0.004)
	# two barbs
	var back: Vector2 = tip - dir * (length * 0.4)
	var perp: Vector2 = Vector2(-dir.y, dir.x) * (length * 0.22)
	_seg(tip, back + perp, color, 0.003)
	_seg(tip, back - perp, color, 0.003)


func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.86, 0.74, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.04, -0.014)
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
	mat.emission = Color(color.r, color.g, color.b)
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
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
