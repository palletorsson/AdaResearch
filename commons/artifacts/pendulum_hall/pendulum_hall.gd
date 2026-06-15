extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PendulumHall

## @identity
## lineage: the walk-in twin of pendulum_swing — a body-scale pendulum you stand under and
##   watch swing at its real period, T = 2π√(L/g). The console toy made into an installation.
## essence: a long arm hangs a heavy bob from a tall pivot; it swings on the actual physics
##   (ω = √(g/L)), the restoring force mg sin θ hauling it back through bottom-dead-centre,
##   and a glowing arc on the floor records the path it sweeps. Stand in the hall and the
##   force vectors ride the bob at the scale of your own body.
## truth: a pendulum keeps time because the pull back grows with how far it's pulled — and at
##   this size you don't read that off an arrow, you feel the bob pass.
##
## The large companion in the "intimate toy → walk-in installation" pair. Swings live in
## _process; the gravity / tension / restoring vectors redraw on the bob each frame.

@export var arm_length: float = 4.6           # metres — a real, large pendulum
@export var pivot_height: float = 6.0
@export_range(0.05, 0.6, 0.01) var amplitude: float = 0.42   # rad (~24°)
@export var bob_color: Color = Color(0.45, 0.72, 0.98)
@export var steel_color: Color = Color(0.62, 0.65, 0.72)
@export var grav_color: Color = Color(0.95, 0.40, 0.38)
@export var tension_color: Color = Color(0.55, 0.95, 0.58)
@export var restore_color: Color = Color(0.98, 0.72, 0.32)

var _arm: Node3D
var _vectors: Node3D
var _t: float = 0.0
var _omega: float = 1.5


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("arm_length"): arm_length = float(config["arm_length"])
	if config.has("amplitude"): amplitude = clampf(float(config["amplitude"]), 0.05, 0.6)
	if config.has("emissive"): emissive = bool(config["emissive"])
	bob_color = _parse_color(config.get("bob_color", bob_color), bob_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_omega = sqrt(9.8 / arm_length)               # real angular frequency → real period
	var steel := _steel_mat(steel_color)
	var dark := _matte_mat(Color(0.13, 0.14, 0.17), 0.6, 0.4)

	# --- the gantry: two angled legs + a cross-beam carrying the pivot ----------
	for sx in [-1.4, 1.4]:
		add_child(_cylinder_between(Vector3(sx, 0, 0.0), Vector3(0, pivot_height, 0.0), 0.09, steel))
		add_child(_box(Vector3(sx, 0.1, 0.0), Vector3(0.6, 0.2, 0.6), dark))           # foot
	add_child(_cylinder_between(Vector3(-0.3, pivot_height, 0), Vector3(0.3, pivot_height, 0), 0.08, steel))  # axle
	add_child(_sphere(Vector3(0, pivot_height, 0), 0.16, _glow_mat(steel_color.lerp(Color.WHITE, 0.3), 0.6)))

	# --- the swept arc on the floor (the path the bob traces) -------------------
	var arc_mat := _glow_mat(bob_color.lerp(Color.WHITE, 0.2), 0.8)
	var floor_y: float = pivot_height - arm_length      # bob height at bottom dead centre
	var steps := 36
	for i in range(steps):
		var a0: float = lerpf(-amplitude, amplitude, float(i) / steps)
		var a1: float = lerpf(-amplitude, amplitude, float(i + 1) / steps)
		add_child(_cylinder_between(_swing(a0), _swing(a1), 0.02, arc_mat))
	# a faint shadow disc under bottom dead centre
	add_child(_cylinder(Vector3(0, 0.02, 0), 0.5, 0.02, _glow_mat(bob_color, 0.3)))

	# --- the arm + bob (pivots in _process) -------------------------------------
	_arm = Node3D.new(); _arm.position = Vector3(0, pivot_height, 0); add_child(_arm)
	_arm.add_child(_cylinder_between(Vector3.ZERO, Vector3(0, -arm_length, 0), 0.035, steel))   # the rod
	_arm.add_child(_sphere(Vector3(0, -arm_length, 0), 0.42, _glow_mat(bob_color, 0.9)))         # the bob
	_arm.add_child(_sphere(Vector3(0, -arm_length, 0), 0.58, _halo(bob_color)))

	_vectors = Node3D.new(); add_child(_vectors)

	# --- plaque ----------------------------------------------------------------
	var period: float = TAU / _omega
	add_child(_billboard_label(
		"PENDULUM\nT = 2π√(L/g)\nL = %.1f m  →  T = %.1f s\nrestoring = mg sin θ" % [arm_length, period],
		Vector3(2.2, 1.6, 0.0), 30, bob_color.lerp(Color.WHITE, 0.3)))

	_redraw_vectors(amplitude)


# bob offset from the pivot at swing angle a
func _swing(a: float) -> Vector3:
	return Vector3(0, pivot_height, 0) + Vector3(sin(a) * arm_length, -cos(a) * arm_length, 0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _arm == null:
		return
	_t += delta
	var theta: float = amplitude * cos(_t * _omega)     # real swing, starts at amplitude
	_arm.rotation.x = 0.0
	_arm.rotation.z = theta                              # swing in the X-Y plane
	_redraw_vectors(theta)


# gravity / tension / restoring at the bob, body-scale
func _redraw_vectors(theta: float) -> void:
	if _vectors == null:
		return
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var bob := _swing(theta)
	var s := 1.2
	var to_pivot: Vector3 = (Vector3(0, pivot_height, 0) - bob).normalized()
	var tangent := Vector3(to_pivot.y, -to_pivot.x, 0.0)
	if tangent.x * sign(theta) > 0: tangent = -tangent          # point back toward the bottom
	_vectors.add_child(_arrow(bob, bob + Vector3(0, -1, 0) * s, 0.05, _glow_mat(grav_color, 1.4)))          # weight mg
	_vectors.add_child(_arrow(bob, bob + to_pivot * cos(theta) * s, 0.05, _glow_mat(tension_color, 1.4)))   # tension
	if absf(theta) > 0.02:
		_vectors.add_child(_arrow(bob, bob + tangent * absf(sin(theta)) * s * 1.4, 0.055, _glow_mat(restore_color, 1.7)))  # restoring


func _halo(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.16)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = c
	m.emission_energy_multiplier = 1.2 if emissive else 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
