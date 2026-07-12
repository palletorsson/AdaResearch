# aliasing_wave.gd — THE FREQUENCY THAT WAS NEVER THERE.
#
# The waves seam (the sampling crack). A wave is continuous; the machine reads
# it at intervals. Above half the sample rate — the Nyquist limit — a wave does
# not vanish. It FOLDS BACK and impersonates a slower one. The machine shows
# you a frequency that was never there, using its own clock.
#
# Shown two ways, one static and one live:
#   THE PANEL — a true 15-cycle wave (amber), 16 sample dots on it (white), and
#     the straight-line reconstruction those samples give (blue): a clean
#     1-cycle wave. |15 - 16| = 1. The lie is exact and it photographs.
#   THE WHEEL — a spoked disc that spins faster than the frame rate. Because
#     the display samples it at ~90 Hz, past Nyquist it appears to slow, stop,
#     and turn BACKWARD (the wagon-wheel effect) — real aliasing, no faking,
#     the medium demonstrating its own bias in the room with you.
extends Node3D
class_name AliasingWave

@export var true_cycles: float = 15.0
@export var samples: int = 16
@export var width: float = 0.95
@export var amp: float = 0.13
@export var wheel_spokes: int = 14
@export var wheel_rpm: float = 5400.0
@export var color_true: Color = Color(1.0, 0.62, 0.18)
@export var color_sample: Color = Color(0.95, 0.96, 1.0)
@export var color_alias: Color = Color(0.3, 0.7, 1.0)

var _wheel: Node3D


func _ready() -> void:
	_backing()
	_draw_true_wave()
	_draw_samples_and_alias()
	_build_wheel()
	var alias_cycles: float = absf(true_cycles - float(samples))
	_plate("THE ALIAS",
		"true %d cycles · sampled %d points\nreconstructed as %d — the wave folded back"
		% [int(true_cycles), samples, int(alias_cycles)],
		Vector3(0.0, 0.30, 0.0), color_alias)
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	if has_meta("config_true_cycles"):
		true_cycles = float(str(get_meta("config_true_cycles")))
	if has_meta("config_samples"):
		samples = int(str(get_meta("config_samples")))


func _process(delta: float) -> void:
	if _wheel != null:
		# spins far faster than any display can sample -> aliases live
		_wheel.rotate_z(deg_to_rad(wheel_rpm * 6.0) * delta)


# ── the panel ────────────────────────────────────────────────────────────────
func _backing() -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width + 0.08, amp * 2.0 + 0.1, 0.006)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.07, 0.08, 0.10)
	mat.roughness = 0.7
	mi.material_override = mat
	mi.position = Vector3(0.0, 0.0, -0.01)
	add_child(mi)


func _wave_point(t: float, cycles: float) -> Vector3:
	var x: float = -width * 0.5 + t * width
	var y: float = amp * sin(TAU * cycles * t)
	return Vector3(x, y, 0.0)


func _draw_true_wave() -> void:
	var steps: int = 260
	var prev: Vector3 = _wave_point(0.0, true_cycles)
	for i in range(1, steps + 1):
		var t: float = float(i) / float(steps)
		var p: Vector3 = _wave_point(t, true_cycles)
		_seg(prev, p, color_true, 0.004, 0.004)
		prev = p


func _draw_samples_and_alias() -> void:
	var pts: Array[Vector3] = []
	for i in range(samples + 1):
		var t: float = float(i) / float(samples)
		pts.append(_wave_point(t, true_cycles))
	# the reconstruction: connect the samples with straight lines (blue) — this
	# is the low-frequency wave the machine believes it saw
	for i in range(pts.size() - 1):
		_seg(pts[i], pts[i + 1], color_alias, 0.008, 0.008)
	# the sample dots themselves (white), sitting on the true wave
	for p in pts:
		var dot := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.008
		sm.height = 0.016
		dot.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_sample
		mat.emission_enabled = true
		mat.emission = color_sample
		mat.emission_energy_multiplier = 0.4
		dot.material_override = mat
		dot.position = p + Vector3(0.0, 0.0, 0.012)
		add_child(dot)


func _seg(a: Vector3, b: Vector3, color: Color, thick_y: float, thick_z: float) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	var d: float = a.distance_to(b)
	bm.size = Vector3(maxf(d, 0.001), thick_y, thick_z)
	mi.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mi.material_override = mat
	mi.position = (a + b) * 0.5
	mi.rotation = Vector3(0.0, 0.0, atan2(b.y - a.y, b.x - a.x))
	add_child(mi)


# ── the wheel (aliases live, past the frame rate) ────────────────────────────
func _build_wheel() -> void:
	_wheel = Node3D.new()
	_wheel.position = Vector3(0.0, -0.34, 0.0)
	add_child(_wheel)
	var hub := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.02
	cm.height = 0.02
	hub.mesh = cm
	hub.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.5, 0.53, 0.6)
	hub.material_override = hmat
	_wheel.add_child(hub)
	var r: float = 0.11
	for i in range(wheel_spokes):
		var ang: float = TAU * float(i) / float(wheel_spokes)
		var spoke := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r, 0.012, 0.008)
		spoke.mesh = bm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color_sample if i % 2 == 0 else color_alias
		mat.emission_enabled = true
		mat.emission = mat.albedo_color
		mat.emission_energy_multiplier = 0.3
		spoke.material_override = mat
		spoke.position = Vector3(cos(ang) * r * 0.5, sin(ang) * r * 0.5, 0.0)
		spoke.rotation = Vector3(0.0, 0.0, ang)
		_wheel.add_child(spoke)
	_plate("THE WHEEL",
		"spin me faster than the display\npast the frame rate I turn backward",
		Vector3(0.0, -0.52, 0.0), color_true)


# ── plate (2D-in-3D, no floating label) ──────────────────────────────────────
func _plate(title: String, body: String, pos: Vector3, accent: Color) -> void:
	var panel := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.62, 0.11, 0.008)
	panel.mesh = pm
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.09, 0.10, 0.12)
	pmat.roughness = 0.6
	panel.material_override = pmat
	panel.position = pos
	add_child(panel)
	var strip := MeshInstance3D.new()
	var sbm := BoxMesh.new()
	sbm.size = Vector3(0.62, 0.01, 0.012)
	strip.mesh = sbm
	var smat := StandardMaterial3D.new()
	smat.albedo_color = accent
	smat.emission_enabled = true
	smat.emission = accent
	strip.material_override = smat
	strip.position = pos + Vector3(0.0, 0.06, 0.006)
	add_child(strip)
	var t := Label3D.new()
	t.text = title + "\n" + body
	t.font_size = 34
	t.pixel_size = 0.00040
	t.modulate = Color(0.93, 0.95, 0.99)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.position = pos + Vector3(0.0, 0.0, 0.006)
	add_child(t)
