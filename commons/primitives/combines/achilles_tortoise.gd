extends Node3D
class_name AchillesTortoise

## Zeno's paradox of Achilles and the Tortoise.
## Achilles chases the Tortoise — each step he reaches where it WAS,
## but the Tortoise has moved forward. The gap halves every step.
## Tick marks accumulate at the limit, never reaching it.
##
## Math: A_n = L*(1 - 1/2^n), T_n = L*(1 - 1/2^(n+1))
## Both converge to L (the limit). Initial gap = L/2.

@export var track_length: float = 6.0
@export var step_count: int = 10
@export var step_interval: float = 2.0

var _achilles: Node3D
var _tortoise: Node3D
var _markers: Array[MeshInstance3D] = []
var _gap_labels: Array[Label3D] = []
var _current_step: int = 0
var _step_timer: float = 0.0
var _paused: bool = false
var _loop_timer: float = 0.0


func _ready() -> void:
	_build_track()
	_build_achilles()
	_build_tortoise()
	_build_step_markers()
	_reset()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("length"):
		track_length = float(config_data["length"])
	if config_data.has("steps"):
		step_count = int(config_data["steps"])


# ── track ────────────────────────────────────────────────────────────────────

func _build_track() -> void:
	# Rail along -Z (south)
	var rail := MeshInstance3D.new()
	var m := BoxMesh.new()
	m.size = Vector3(0.04, 0.01, track_length)
	rail.mesh = m
	rail.set_surface_override_material(0, _mat(
		Color(0.45, 0.45, 0.55, 0.6), Color(0.15, 0.15, 0.25)))
	rail.position = Vector3(0.0, 0.0, -track_length * 0.5)
	add_child(rail)

	# Origin tick (start)
	add_child(_tick(Vector3.ZERO, 0.12, Color(0.7, 0.7, 0.8)))

	# Limit tick (end — the unreachable point)
	add_child(_tick(Vector3(0.0, 0.0, -track_length), 0.15, Color(0.8, 0.4, 0.9)))

	# Title
	var title := Label3D.new()
	title.text = "Achilles & Tortoise"
	title.font_size = 22
	title.pixel_size = 0.002
	title.modulate = Color(0.85, 0.75, 0.95)
	title.position = Vector3(0.0, 0.35, -0.3)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)

	# Limit label
	var lim := Label3D.new()
	lim.text = "limit"
	lim.font_size = 16
	lim.pixel_size = 0.002
	lim.modulate = Color(0.8, 0.4, 0.9, 0.7)
	lim.position = Vector3(0.15, 0.0, -track_length)
	lim.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(lim)

	# Origin label
	var orig := Label3D.new()
	orig.text = "0"
	orig.font_size = 16
	orig.pixel_size = 0.002
	orig.modulate = Color(0.7, 0.7, 0.8, 0.7)
	orig.position = Vector3(0.12, 0.0, 0.0)
	orig.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(orig)


# ── figures ──────────────────────────────────────────────────────────────────

func _build_achilles() -> void:
	_achilles = Node3D.new()
	_achilles.name = "Achilles"

	# Body — golden capsule (warrior)
	var body := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.04
	cm.height = 0.18
	body.mesh = cm
	body.set_surface_override_material(0, _mat(
		Color(0.92, 0.62, 0.15), Color(0.5, 0.3, 0.05), 0.6))
	body.position.y = 0.1
	_achilles.add_child(body)

	# Label
	var lbl := _label_3d("A", Color(0.92, 0.62, 0.15), Vector3(0.0, 0.25, 0.0))
	_achilles.add_child(lbl)
	add_child(_achilles)


func _build_tortoise() -> void:
	_tortoise = Node3D.new()
	_tortoise.name = "Tortoise"

	# Shell — green dome
	var shell := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.05
	sm.height = 0.05
	shell.mesh = sm
	var t_mat := _mat(Color(0.2, 0.65, 0.3), Color(0.1, 0.3, 0.1))
	shell.set_surface_override_material(0, t_mat)
	shell.position.y = 0.03
	_tortoise.add_child(shell)

	# Head
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.018
	hm.height = 0.036
	head.mesh = hm
	head.set_surface_override_material(0, _mat(
		Color(0.25, 0.6, 0.35), Color(0.1, 0.25, 0.1)))
	head.position = Vector3(0.0, 0.025, -0.045)
	_tortoise.add_child(head)

	# Label
	var lbl := _label_3d("T", Color(0.2, 0.65, 0.3), Vector3(0.0, 0.12, 0.0))
	_tortoise.add_child(lbl)
	add_child(_tortoise)


# ── step markers ─────────────────────────────────────────────────────────────

func _build_step_markers() -> void:
	for i in range(step_count):
		# Marker at Achilles' position after step (i+1)
		# A_n = track_length * (1 - 1/2^n)
		var frac := 1.0 - 1.0 / pow(2.0, float(i + 1))
		var z_pos := -frac * track_length

		# Tick
		var tk := _tick(Vector3(0.0, 0.0, z_pos), 0.06, Color(0.55, 0.35, 0.75, 0.4))
		tk.visible = false
		add_child(tk)
		_markers.append(tk)

		# Gap fraction label (remaining gap as fraction of initial gap)
		var lbl := Label3D.new()
		lbl.font_size = 12
		lbl.pixel_size = 0.002
		lbl.modulate = Color(0.6, 0.4, 0.8, 0.65)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.visible = false
		if i < 5:
			lbl.text = "1/%d" % int(pow(2, i + 1))
		else:
			lbl.text = "|"
		lbl.position = Vector3(0.12, 0.0, z_pos)
		add_child(lbl)
		_gap_labels.append(lbl)


# ── animation loop ───────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _paused:
		_loop_timer -= delta
		if _loop_timer <= 0.0:
			_paused = false
			_reset()
		return

	_step_timer += delta
	if _step_timer >= step_interval and _current_step < step_count:
		_step_timer = 0.0
		_advance()
	elif _current_step >= step_count:
		_paused = true
		_loop_timer = 4.0


func _advance() -> void:
	var n := _current_step + 1

	# Achilles goes to where Tortoise was: A_n = L*(1 - 1/2^n)
	var a_z := -track_length * (1.0 - 1.0 / pow(2.0, float(n)))

	# Tortoise moves forward: T_n = L*(1 - 1/2^(n+1))
	var t_z := -track_length * (1.0 - 1.0 / pow(2.0, float(n + 1)))

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_achilles, "position:z", a_z, step_interval * 0.5)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(_tortoise, "position:z", t_z, step_interval * 0.5)\
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)

	# Reveal marker and label
	if _current_step < _markers.size():
		_markers[_current_step].visible = true
	if _current_step < _gap_labels.size():
		_gap_labels[_current_step].visible = true

	_current_step += 1


func _reset() -> void:
	if _achilles:
		_achilles.position = Vector3(0.0, 0.0, 0.0)
	if _tortoise:
		_tortoise.position = Vector3(0.0, 0.0, -track_length * 0.5)
	_current_step = 0
	_step_timer = 0.0
	for m in _markers:
		m.visible = false
	for l in _gap_labels:
		l.visible = false


# ── helpers ──────────────────────────────────────────────────────────────────

func _mat(color: Color, emission: Color = Color.BLACK,
		metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if color.a < 1.0:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	if emission != Color.BLACK:
		mat.emission_enabled = true
		mat.emission = emission
	mat.metallic = metallic
	return mat


func _tick(pos: Vector3, height: float, color: Color) -> MeshInstance3D:
	var m := BoxMesh.new()
	m.size = Vector3(0.08, height, 0.012)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.set_surface_override_material(0, _mat(color))
	mi.position = pos
	return mi


func _label_3d(text: String, color: Color, pos: Vector3) -> Label3D:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.font_size = 20
	lbl.pixel_size = 0.002
	lbl.modulate = color
	lbl.position = pos
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	return lbl
