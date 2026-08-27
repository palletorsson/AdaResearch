extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TwoCostumes

## @identity
## lineage: the wavefunctions SUPER OBJECT — one phase, every costume. A brass unit
##   wheel turns at the centre; a scotch yoke rides its pin, and the yoke's plumb is
##   the sine, drawn live as a lane of beads walking sin(x − ωt). Behind it, three
##   epicycle wheels chained at speeds 1, 3, 5 and radii 1, 1/3, 1/5 trace the
##   Fourier chorus — their tip-lane visibly squaring. Two bead-waves cross in an
##   interference pool, their sum-lane beating slowly. A pendulum cut to the wheel's
##   own period swings agreement (tuned, not forced — the placard says so). A small
##   brass horn sings the SAME phase through AudioStreamGenerator at 220 Hz: the
##   second costume, audible. And on the rim, a tiny double pendulum tumbles
##   chaotically — the one station that keeps no promise, the door to randomness.
## essence: sin(t) is the engine's only oscillator; everything here is that one
##   rotation dressed differently — shadowed, summed, met, answered, walked, heard,
##   and finally broken. One clock drives every station, which is the whole claim.
## truth: everything oscillates, and it is all one wheel. Seen and heard are the
##   same function.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 67
@export var omega: float = 1.2          # the one clock, rad/s
@export var tone_hz: float = 220.0

var _wheel: Node3D
var _pin: Node3D
var _yoke: Node3D
var _wave_beads: Array = []
var _epi: Array = []                    # chained wheels
var _epi_beads: Array = []
var _pool_beads: Array = []             # [laneA, laneB, laneSum] arrays
var _pend: Node3D
var _pend_theta := 0.0
var _pend_omega := 0.0
var _pend_len := 0.0
var _dp_a := 1.4                        # double pendulum state
var _dp_b := 2.3
var _dp_va := 0.0
var _dp_vb := 0.0
var _dp1: Node3D
var _dp2: Node3D
var _player: AudioStreamPlayer3D
var _playback: AudioStreamGeneratorPlayback
var _sample_phase := 0.0

func _ready() -> void:
	_rng.seed = seed
	_pend_len = 9.8 / (omega * omega)   # T_pendulum == T_wheel, by construction
	_build_table()
	_build_wheel_and_yoke()
	_build_wave_lane()
	_build_epicycles()
	_build_pool()
	_build_pendulum()
	_build_double_pendulum()
	_build_horn()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "omega", "tone_hz"]:
		if config_data.has(key):
			set(key, config_data[key])

func _physics_process(delta: float) -> void:
	var t := float(Time.get_ticks_msec()) / 1000.0
	var phase := t * omega
	# the wheel and its shadow
	_wheel.rotation.z = phase
	_yoke.position.y = 1.35 + 0.32 * sin(phase)
	# the walked wave
	for i in range(_wave_beads.size()):
		var x := float(i) / float(_wave_beads.size() - 1)
		_wave_beads[i].position.y = 1.05 + 0.22 * sin(x * TAU * 1.5 - phase)
	# the Fourier chain: wheels at 1, 3, 5 - each mounted on the previous pin
	var tip := Vector3.ZERO
	for k in range(3):
		var n := float(k * 2 + 1)
		_epi[k].rotation.z = phase * n
		tip += Vector3(cos(phase * n), sin(phase * n), 0.0) * (0.22 / n)
	for i in range(_epi_beads.size()):
		var x := float(i) / float(_epi_beads.size() - 1)
		var y := 0.0
		for k in range(3):
			var n := float(k * 2 + 1)
			y += sin((x * TAU * 1.5 - phase) * 1.0 * n) / n
		_epi_beads[i].position.y = 2.05 + 0.16 * y
	# the meeting: two waves, slightly detuned, and their pointwise sum beating
	for i in range(_pool_beads[0].size()):
		var x := float(i) / float(_pool_beads[0].size() - 1)
		var ya := 0.1 * sin(x * TAU * 2.0 - phase)
		var yb := 0.1 * sin(x * TAU * 2.0 - phase * 1.1 + 0.7)
		_pool_beads[0][i].position.y = 0.62 + ya
		_pool_beads[1][i].position.y = 0.62 + yb
		_pool_beads[2][i].position.y = 0.62 + ya + yb
	# resonance: the true pendulum equation, period matched to the wheel by length
	var acc := -(9.8 / _pend_len) * sin(_pend_theta) - 0.01 * _pend_omega
	_pend_omega += acc * delta
	_pend_theta += _pend_omega * delta
	_pend.rotation.z = _pend_theta
	# the break: a real double pendulum, equal masses and lengths, RK-free but honest
	var l := 0.16
	var d := _dp_b - _dp_a
	var den := 2.0 - cos(d) * cos(d)
	var a1 := (-sin(d) * (_dp_vb * _dp_vb + _dp_va * _dp_va * cos(d)) - (9.8 / l) * (2.0 * sin(_dp_a) - sin(_dp_b) * cos(d))) / den
	var a2 := (sin(d) * (2.0 * _dp_va * _dp_va + _dp_vb * _dp_vb * cos(d)) + (9.8 / l) * 2.0 * (sin(_dp_a) * cos(d) - sin(_dp_b))) / den
	_dp_va += a1 * delta
	_dp_vb += a2 * delta
	_dp_a += _dp_va * delta
	_dp_b += _dp_vb * delta
	_dp1.rotation.z = _dp_a
	_dp2.rotation.z = _dp_b - _dp_a
	# the second costume: the same phase, pushed as samples
	if _playback:
		var frames := _playback.get_frames_available()
		var rate := 44100.0
		for i in range(mini(frames, 512)):
			var s := 0.2 * sin(_sample_phase)
			_playback.push_frame(Vector2(s, s))
			_sample_phase += TAU * tone_hz / rate

# --- stations -----------------------------------------------------------------------

func _build_table() -> void:
	var top := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(4.4, 0.1, 1.6)
	top.mesh = tm
	top.position = Vector3(0.0, 0.5, 0.0)
	top.material_override = _matte_mat(Color(0.13, 0.11, 0.1), 0.85)
	add_child(top)
	for sx in [-1.0, 1.0]:
		var leg := MeshInstance3D.new()
		var lm := BoxMesh.new()
		lm.size = Vector3(0.12, 0.5, 1.2)
		leg.mesh = lm
		leg.position = Vector3(sx * 2.0, 0.25, 0.0)
		leg.material_override = _matte_mat(Color(0.1, 0.1, 0.12), 0.9)
		add_child(leg)

func _build_wheel_and_yoke() -> void:
	_wheel = Node3D.new()
	_wheel.position = Vector3(-1.55, 1.35, 0.0)
	add_child(_wheel)
	var rim := MeshInstance3D.new()
	var rm := TorusMesh.new()
	rm.inner_radius = 0.3
	rm.outer_radius = 0.34
	rim.mesh = rm
	rim.rotation.x = PI * 0.5
	rim.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	_wheel.add_child(rim)
	for k in range(4):
		var spoke := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.6, 0.02, 0.02)
		spoke.mesh = sm
		spoke.rotation.z = PI * 0.5 * float(k) * 0.5
		spoke.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
		_wheel.add_child(spoke)
	_pin = Node3D.new()
	_pin.position = Vector3(0.32, 0.0, 0.06)
	_wheel.add_child(_pin)
	var pin_mesh := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.025
	pm.bottom_radius = 0.025
	pm.height = 0.1
	pin_mesh.mesh = pm
	pin_mesh.rotation.x = PI * 0.5
	pin_mesh.material_override = _glow_mat(Color(0.95, 0.6, 0.2), 1.4)
	_pin.add_child(pin_mesh)
	# the yoke: a vertical slider whose height IS sin(phase)
	_yoke = Node3D.new()
	_yoke.position = Vector3(-1.05, 1.35, 0.0)
	add_child(_yoke)
	var plumb := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.05
	bm.height = 0.1
	plumb.mesh = bm
	plumb.material_override = _glow_mat(Color(0.95, 0.6, 0.2), 1.6)
	_yoke.add_child(plumb)
	var rail := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.012
	lm.bottom_radius = 0.012
	lm.height = 0.85
	rail.mesh = lm
	rail.position = Vector3(-1.05, 1.35, 0.0)
	rail.material_override = _matte_mat(Color(0.3, 0.3, 0.33), 0.7)
	add_child(rail)

func _build_wave_lane() -> void:
	for i in range(22):
		var bead := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.03
		sm.height = 0.06
		bead.mesh = sm
		bead.position = Vector3(-0.85 + 2.6 * float(i) / 21.0, 1.05, 0.0)
		bead.material_override = _glow_mat(Color(0.95, 0.6, 0.2), 1.1)
		add_child(bead)
		_wave_beads.append(bead)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.16
	tag.position = Vector3(0.4, 0.56, 0.72)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("sin(x - wt)", "the shadow, walked")

func _build_epicycles() -> void:
	# chained wheels at 1x, 3x, 5x - Fourier as brass
	var mount := Vector3(-1.55, 2.05, -0.3)
	var parent: Node3D = self
	var at := mount
	for k in range(3):
		var n := float(k * 2 + 1)
		var w := Node3D.new()
		w.position = at if parent == self else Vector3(0.22 / (n - 2.0 if n > 1.0 else 1.0), 0.0, 0.0)
		parent.add_child(w)
		var rim := MeshInstance3D.new()
		var rm := TorusMesh.new()
		rm.inner_radius = 0.2 / n - 0.015
		rm.outer_radius = 0.2 / n
		rim.mesh = rm
		rim.rotation.x = PI * 0.5
		rim.material_override = _steel_mat(Color(0.6, 0.55, 0.4))
		w.add_child(rim)
		_epi.append(w)
		parent = w
		at = Vector3.ZERO
	for i in range(22):
		var bead := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.022
		sm.height = 0.044
		bead.mesh = sm
		bead.position = Vector3(-0.85 + 2.6 * float(i) / 21.0, 2.05, -0.3)
		bead.material_override = _glow_mat(Color(0.45, 0.85, 0.8), 1.0)
		add_child(bead)
		_epi_beads.append(bead)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.2
	tag.position = Vector3(0.4, 2.28, -0.3)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("sin + sin/3 + sin/5", "the chorus, squaring")

func _build_pool() -> void:
	for lane in range(3):
		var beads: Array = []
		for i in range(18):
			var bead := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.022
			sm.height = 0.044
			bead.mesh = sm
			bead.position = Vector3(0.55 + 1.5 * float(i) / 17.0, 0.62, -0.55 + 0.18 * float(lane))
			var tints := [Color(0.35, 0.65, 0.95), Color(0.95, 0.6, 0.25), Color(0.95, 0.9, 0.5)]
			var tint: Color = tints[lane]
			bead.material_override = _glow_mat(tint, 1.0)
			add_child(bead)
			beads.append(bead)
		_pool_beads.append(beads)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.18
	tag.position = Vector3(1.3, 0.56, 0.2)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("the meeting", "two waves, and their sum beating")

func _build_pendulum() -> void:
	var mast := MeshInstance3D.new()
	var mm := CylinderMesh.new()
	mm.top_radius = 0.02
	mm.bottom_radius = 0.03
	mm.height = 1.1
	mast.mesh = mm
	mast.position = Vector3(1.95, 1.15, 0.45)
	mast.material_override = _steel_mat(Color(0.5, 0.42, 0.26))
	add_child(mast)
	_pend = Node3D.new()
	_pend.position = Vector3(1.95, 1.7, 0.45)
	add_child(_pend)
	_pend_theta = 0.35
	var rod := MeshInstance3D.new()
	var rm := CylinderMesh.new()
	rm.top_radius = 0.007
	rm.bottom_radius = 0.007
	var vis_len := minf(_pend_len, 0.9)
	rm.height = vis_len
	rod.mesh = rm
	rod.position = Vector3(0.0, -vis_len * 0.5, 0.0)
	rod.material_override = _steel_mat(Color(0.4, 0.38, 0.35))
	_pend.add_child(rod)
	var bob := MeshInstance3D.new()
	var bm := SphereMesh.new()
	bm.radius = 0.05
	bm.height = 0.1
	bob.mesh = bm
	bob.position = Vector3(0.0, -vis_len, 0.0)
	bob.material_override = _glow_mat(Color(0.85, 0.3, 0.25), 0.9)
	_pend.add_child(bob)

func _build_double_pendulum() -> void:
	var mount := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.04, 0.3, 0.04)
	mount.mesh = mm
	mount.position = Vector3(2.05, 1.05, -0.5)
	mount.material_override = _steel_mat(Color(0.5, 0.42, 0.26))
	add_child(mount)
	_dp1 = Node3D.new()
	_dp1.position = Vector3(2.05, 1.2, -0.5)
	add_child(_dp1)
	var arm1 := MeshInstance3D.new()
	var a1 := BoxMesh.new()
	a1.size = Vector3(0.015, 0.16, 0.015)
	arm1.mesh = a1
	arm1.position = Vector3(0.0, -0.08, 0.0)
	arm1.material_override = _glow_mat(Color(0.9, 0.4, 0.3), 0.9)
	_dp1.add_child(arm1)
	_dp2 = Node3D.new()
	_dp2.position = Vector3(0.0, -0.16, 0.0)
	_dp1.add_child(_dp2)
	var arm2 := MeshInstance3D.new()
	arm2.mesh = a1
	arm2.position = Vector3(0.0, -0.08, 0.0)
	arm2.material_override = _glow_mat(Color(0.9, 0.6, 0.3), 0.9)
	_dp2.add_child(arm2)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.16
	tag.position = Vector3(2.05, 0.56, -0.75)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("the break", "the promise fails - the door to randomness")

func _build_horn() -> void:
	var horn := MeshInstance3D.new()
	var hm := CylinderMesh.new()
	hm.top_radius = 0.14
	hm.bottom_radius = 0.03
	hm.height = 0.3
	horn.mesh = hm
	horn.position = Vector3(-2.0, 1.05, 0.45)
	horn.rotation.z = deg_to_rad(-65.0)
	horn.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(horn)
	_player = AudioStreamPlayer3D.new()
	var gen := AudioStreamGenerator.new()
	gen.mix_rate = 44100.0
	gen.buffer_length = 0.12
	_player.stream = gen
	_player.position = Vector3(-2.0, 1.05, 0.45)
	_player.unit_size = 3.0
	_player.autoplay = true
	add_child(_player)
	_player.play()
	_playback = _player.get_stream_playback()
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.2
	tag.position = Vector3(-2.0, 0.56, 0.8)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("the second costume", "the same phase, 44,100 times a second: pitch")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CostumesPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.35, 0.24, 1.0)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("TWO COSTUMES",
			"One clock drives every station: the wheel and its yoke-shadow, the walked\nwave, the epicycle chorus squaring, two waves beating in the pool, a pendulum\ncut to the wheel's own period (tuned, not forced), a horn singing the same\nphase as pitch - and the double pendulum, where the promise breaks.\nEverything oscillates, and it is all one wheel.")
