extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name GrandZoetrope

## @identity
## lineage: the change SUPER OBJECT — a Victorian zoetrope grown into a calculus
##   engine. The drum spins with twelve poses of one bouncing ball inside it: motion
##   that exists only as frames, which is the engine's whole secret. Beside the drum,
##   the derivative stands as furniture — the ball's last two poses with a slope
##   batten wedged between them, (now − before) / delta. A sand column rises as the
##   integral of its pouring rate and empties on the loop; its two dials, rate and
##   level, are the fundamental theorem holding hands. Around the base run two bead
##   lanes: the delta runner's ghosts evenly spaced, the frame-counter runner's
##   ghosts bunching and stretching — spacing as the confession. A skirt of vanes
##   leans to a field (flow), and the crown is an arrow eating its own tail (fmod:
##   change that comes home).
## essence: _process(delta) is a Riemann sum you live inside. The zoetrope was
##   always the honest machine: nothing in it moves — it only remembers twelve
##   stillnesses fast enough.
## truth: things change; change accumulates; accumulation flows — one frame at a time.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 66
@export var drum_rate: float = 0.9       # drum rad/s
@export var loop_s: float = 8.0          # the sand loop — fmod's period

var _drum: Node3D
var _sand: MeshInstance3D
var _rate_needle: Node3D
var _level_needle: Node3D
var _readout: Node3D

func _ready() -> void:
	_rng.seed = seed
	_build_base()
	_build_drum()
	_build_derivative()
	_build_sand()
	_build_lanes()
	_build_flow_skirt()
	_build_crown()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "drum_rate", "loop_s"]:
		if config_data.has(key):
			set(key, config_data[key])

func _process(delta: float) -> void:
	_drum.rotation.y += drum_rate * delta
	# the sand: level is the INTEGRAL of a varying pour rate; both dials read the
	# same story from opposite ends, and fmod sends it home
	var t := fmod(float(Time.get_ticks_msec()) / 1000.0, loop_s) / loop_s
	var rate := 0.5 + 0.5 * sin(t * TAU * 2.0)
	# closed-form integral of the same rate, so the dials genuinely agree
	var level := (0.5 * t + (1.0 - cos(t * TAU * 2.0)) / (TAU * 4.0)) / 0.5
	_sand.scale.y = maxf(level, 0.02)
	_sand.position.y = 0.55 + 0.325 * _sand.scale.y
	_rate_needle.rotation.z = -PI * 0.75 + rate * PI * 0.5
	_level_needle.rotation.z = -PI * 0.75 + clampf(level, 0.0, 1.0) * PI * 0.5
	if _readout and _readout.has_method("set_text") and int(t * 40.0) % 8 == 0:
		_readout.set_text("x += rate * delta", "level %.2f - the frames keep pouring" % level)

func _build_base() -> void:
	var base := MeshInstance3D.new()
	var bm := CylinderMesh.new()
	bm.top_radius = 1.7
	bm.bottom_radius = 1.8
	bm.height = 0.14
	base.mesh = bm
	base.position = Vector3(0.0, 0.07, 0.0)
	base.material_override = _matte_mat(Color(0.13, 0.11, 0.1), 0.85)
	add_child(base)
	var pillar := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.06
	pm.bottom_radius = 0.09
	pm.height = 0.75
	pillar.mesh = pm
	pillar.position = Vector3(0.0, 0.5, 0.0)
	pillar.material_override = _steel_mat(Color(0.5, 0.42, 0.26))
	add_child(pillar)

func _build_drum() -> void:
	_drum = Node3D.new()
	_drum.position = Vector3(0.0, 1.25, 0.0)
	add_child(_drum)
	var floor_disc := MeshInstance3D.new()
	var fm := CylinderMesh.new()
	fm.top_radius = 0.72
	fm.bottom_radius = 0.72
	fm.height = 0.03
	floor_disc.mesh = fm
	floor_disc.position = Vector3(0.0, -0.34, 0.0)
	floor_disc.material_override = _matte_mat(Color(0.16, 0.13, 0.11), 0.8)
	_drum.add_child(floor_disc)
	# twelve wall panels with slit gaps between them — the shutter that makes
	# stillness into motion
	for i in range(12):
		var ang := TAU * float(i) / 12.0
		var panel := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.3, 0.66, 0.02)
		panel.mesh = pm
		panel.position = Vector3(cos(ang) * 0.72, 0.0, sin(ang) * 0.72)
		panel.rotation.y = -ang + PI * 0.5
		panel.material_override = _matte_mat(Color(0.09, 0.07, 0.07), 0.9)
		_drum.add_child(panel)
		# the twelve poses of one bounce: height follows |sin|, squash at the floor
		var ph := float(i) / 12.0
		var h := absf(sin(ph * TAU * 0.5)) if true else 0.0
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.055
		sm.height = 0.11
		ball.mesh = sm
		var squash := 1.0 - 0.45 * clampf(0.12 - h, 0.0, 0.12) / 0.12
		ball.scale = Vector3(1.0 / sqrt(squash), squash, 1.0 / sqrt(squash))
		ball.position = Vector3(cos(ang) * 0.5, -0.27 + 0.5 * h, sin(ang) * 0.5)
		ball.material_override = _glow_mat(Color(0.95, 0.6, 0.2), 1.2)
		_drum.add_child(ball)

func _build_derivative() -> void:
	# frames n-1 and n of the same ball, with the slope batten between them:
	# (now - before) / delta as a physical wedge
	var a := Vector3(-1.35, 1.02, 0.55)
	var b := Vector3(-1.05, 1.24, 0.55)
	for spec in [[a, 0.35], [b, 1.0]]:
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.06
		sm.height = 0.12
		ball.mesh = sm
		ball.position = spec[0]
		var m := _glow_mat(Color(0.95, 0.6, 0.2), spec[1])
		if spec[1] < 1.0:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.albedo_color.a = 0.4
		ball.material_override = m
		add_child(ball)
	var batten := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(a.distance_to(b), 0.02, 0.02)
	batten.mesh = bm
	batten.position = (a + b) * 0.5
	batten.rotation.z = atan2(b.y - a.y, b.x - a.x)
	batten.material_override = _glow_mat(Color(0.45, 0.85, 0.8), 1.0)
	add_child(batten)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.2
	tag.position = Vector3(-1.25, 0.16, 0.95)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("(now - before) / delta", "the rate")

func _build_sand() -> void:
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.6, 0.78, 0.82, 0.12)
	glass.roughness = 0.05
	var tube := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.16
	tm.bottom_radius = 0.16
	tm.height = 0.7
	tube.mesh = tm
	tube.position = Vector3(1.3, 0.9, 0.45)
	tube.material_override = glass
	add_child(tube)
	_sand = MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.14
	sm.bottom_radius = 0.14
	sm.height = 0.65
	_sand.mesh = sm
	_sand.position = Vector3(1.3, 0.9, 0.45)
	_sand.scale.y = 0.02
	_sand.material_override = _glow_mat(Color(0.9, 0.75, 0.4), 0.7)
	add_child(_sand)
	# recentre the sand about its base, so scale.y grows it upward
	_sand.position.y = 0.55 + 0.325 * _sand.scale.y
	for spec in [["rate", Vector3(1.05, 1.45, 0.45)], ["level", Vector3(1.55, 1.45, 0.45)]]:
		var dial := MeshInstance3D.new()
		var dm := CylinderMesh.new()
		dm.top_radius = 0.09
		dm.bottom_radius = 0.09
		dm.height = 0.02
		dial.mesh = dm
		dial.rotation.x = PI * 0.5
		dial.position = spec[1]
		dial.material_override = _matte_mat(Color(0.9, 0.88, 0.8), 0.6)
		add_child(dial)
		var needle := Node3D.new()
		needle.position = spec[1] + Vector3(0.0, 0.0, 0.015)
		add_child(needle)
		var nm := MeshInstance3D.new()
		var nb := BoxMesh.new()
		nb.size = Vector3(0.075, 0.012, 0.008)
		nm.mesh = nb
		nm.position = Vector3(0.037, 0.0, 0.0)
		nm.material_override = _matte_mat(Color(0.75, 0.2, 0.15), 0.5)
		needle.add_child(nm)
		if spec[0] == "rate":
			_rate_needle = needle
		else:
			_level_needle = needle
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.22
	tag.position = Vector3(1.3, 0.16, 0.95)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("rate and level", "the fundamental theorem, holding hands")

func _build_lanes() -> void:
	# two rings of ghost beads: the delta runner spaced evenly, the per-frame
	# runner bunching where the frames ran long — spacing is the confession
	for lane in range(2):
		var r := 1.15 + 0.18 * float(lane)
		var n := 16
		for k in range(n):
			var ang := TAU * float(k) / float(n)
			if lane == 1:
				# the no-delta runner: seeded uneven spacing, the stumble made visible
				ang += _rng.randf_range(-0.09, 0.09)
			var bead := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.025
			sm.height = 0.05
			bead.mesh = sm
			bead.position = Vector3(cos(ang) * r, 0.16, sin(ang) * r)
			bead.material_override = _glow_mat(Color(0.45, 0.85, 0.8) if lane == 0 else Color(0.9, 0.4, 0.3), 0.9)
			add_child(bead)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.26
	tag.position = Vector3(0.0, 0.16, 1.55)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("x += v * delta", "even ghosts kept time; the red lane forgot delta")

func _build_flow_skirt() -> void:
	for i in range(10):
		var ang := TAU * float(i) / 10.0
		var vane := MeshInstance3D.new()
		var vm := PrismMesh.new()
		vm.size = Vector3(0.1, 0.02, 0.14)
		vane.mesh = vm
		vane.position = Vector3(cos(ang) * 0.95, 0.85, sin(ang) * 0.95)
		vane.rotation.y = -ang - PI * 0.5 + 0.4 * sin(ang * 2.0)
		vane.rotation.z = -0.3 * (0.5 + 0.5 * sin(ang * 3.0 + 1.0))
		vane.material_override = _glow_mat(Color.from_hsv(0.5 + 0.05 * sin(ang * 2.0), 0.5, 0.9), 0.7)
		add_child(vane)

func _build_crown() -> void:
	# fmod: the arrow eating its tail — eight segments of a ring, the head meeting
	# the last segment
	for i in range(8):
		var ang := TAU * float(i) / 8.0 * 0.92
		var seg := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.16, 0.025, 0.025)
		seg.mesh = sm
		seg.position = Vector3(cos(ang) * 0.28, 1.78, sin(ang) * 0.28)
		seg.rotation.y = -ang - PI * 0.5
		seg.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
		add_child(seg)
	var head := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.0
	hm.bottom_radius = 0.05
	hm.height = 0.12
	head.mesh = hm
	var hang := TAU * 0.94
	head.position = Vector3(cos(hang) * 0.28, 1.78, sin(hang) * 0.28)
	head.rotation.z = PI * 0.5
	head.rotation.y = -hang
	head.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(head)

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "ZoetropePlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-1.7, 0.24, 1.25)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("GRAND ZOETROPE",
			"_process(delta) is a Riemann sum you live inside. The drum remembers\ntwelve stillnesses fast enough to be a bounce; the batten is\n(now - before) / delta; the sand is x += rate * delta with its two dials\nagreeing on the fundamental theorem; the red lane forgot delta and bunches;\nthe vanes lean to a field; the crown eats its tail. Change comes home.")
	_readout = TextScreenScript.new()
	_readout.mode = 2
	_readout.width_m = 0.32
	_readout.position = Vector3(1.7, 0.24, 1.25)
	_readout.rotation.y = deg_to_rad(-38.0)
	add_child(_readout)
