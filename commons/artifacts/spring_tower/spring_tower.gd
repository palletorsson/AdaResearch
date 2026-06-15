extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name SpringTower

## @identity
## lineage: the walk-in twin of spring_bob — a body-scale coil. A heavy mass bobs on a giant
##   spring at its real period T = 2π√(m/k); stand beside it and watch the coil stretch and
##   compress while the spring force (−kx) and the weight trade places.
## essence: the spring returns force in exact proportion to how far it's stretched, so the
##   mass oscillates forever about equilibrium — F = −kx, the signature of everything that
##   keeps time. Stiffen it (the slider on the small twin) and it bobs faster, gives less.
## truth: a spring is honest; it gives back exactly what it's given, and that is why it ticks.
##
## The large half of the spring_bob pair. The coil scales in _process to follow the bobbing
## mass; the spring-force and weight vectors ride the mass at body scale.

@export_range(0.0, 1.0, 0.01) var stiffness: float = 0.45
@export var top_y: float = 5.6
@export var coil_color: Color = Color(0.66, 0.70, 0.78)
@export var mass_color: Color = Color(0.72, 0.52, 0.95)
@export var spring_color: Color = Color(0.55, 0.95, 0.58)
@export var weight_color: Color = Color(0.95, 0.40, 0.38)

const NATURAL := 1.8                            # built coil length (scaled at runtime)
var _coil: Node3D
var _mass: Node3D
var _vectors: Node3D
var _t: float = 0.0
var _omega: float = 1.0
var _eq_y: float = 0.0
var _amp: float = 0.6


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("stiffness"): stiffness = clampf(float(config["stiffness"]), 0.0, 1.0)
	if config.has("emissive"): emissive = bool(config["emissive"])
	coil_color = _parse_color(config.get("coil_color", coil_color), coil_color)
	mass_color = _parse_color(config.get("mass_color", mass_color), mass_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	var k: float = lerpf(8.0, 40.0, stiffness)
	var m := 6.0
	_omega = sqrt(k / m)                          # real angular frequency
	var x_eq: float = m * 9.8 / k * 0.18          # equilibrium stretch (scaled to fit the tower)
	_eq_y = top_y - NATURAL - x_eq                # resting mass height
	_amp = clampf(0.4 + (1.0 - stiffness) * 0.5, 0.3, 0.9)   # softer → bigger swing
	var steel := _steel_mat(Color(0.3, 0.32, 0.38))

	# gantry: a frame holding the ceiling anchor
	for sx in [-1.2, 1.2]:
		add_child(_cylinder_between(Vector3(sx, 0, 0.6), Vector3(sx, top_y, 0.0), 0.08, steel))
		add_child(_box(Vector3(sx, 0.1, 0.6), Vector3(0.5, 0.2, 0.5), _matte_mat(Color(0.13,0.14,0.17),0.6)))
	add_child(_box(Vector3(0, top_y + 0.08, 0), Vector3(1.3, 0.18, 0.5), _matte_mat(Color(0.13,0.14,0.17),0.6)))

	# the coil — a helix anchored at the ceiling, scaled in _process
	_coil = Node3D.new(); _coil.position = Vector3(0, top_y, 0); add_child(_coil)
	var coils := 9
	var n := coils * 9
	var prev := Vector3.ZERO
	var cm := _steel_mat(coil_color)
	for i in range(1, n + 1):
		var t: float = float(i) / float(n)
		var ang: float = t * float(coils) * TAU
		var p := Vector3(cos(ang) * 0.4, -t * NATURAL, sin(ang) * 0.4)
		_coil.add_child(_cylinder_between(prev, p, 0.035, cm))
		prev = p

	# the mass
	_mass = Node3D.new(); add_child(_mass)
	_mass.add_child(_box(Vector3.ZERO, Vector3(1.0, 0.8, 1.0), _glow_mat(mass_color, 0.7)))
	_mass.add_child(_box(Vector3(0, 0.5, 0), Vector3(0.3, 0.2, 0.3), _steel_mat(coil_color)))   # hook
	_vectors = Node3D.new(); add_child(_vectors)

	var period: float = TAU / _omega
	add_child(_billboard_label("SPRING\nF = −k x\nk = %.0f   T = 2π√(m/k)\nT = %.1f s" % [k, period],
		Vector3(2.0, _eq_y + 1.0, 0), 30, mass_color.lerp(Color.WHITE, 0.35)))
	_advance()


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _coil == null:
		return
	_t += delta
	_advance()


func _advance() -> void:
	var disp: float = -_amp * cos(_t * _omega)            # starts at max stretch (mass low)
	var mass_y: float = _eq_y + disp
	_mass.position = Vector3(0, mass_y + 0.4, 0)           # mass top sits at the coil end
	# scale the coil to span ceiling → mass top
	var span: float = top_y - (mass_y + 0.8)
	_coil.scale.y = maxf(span / NATURAL, 0.05)
	# body-scale vectors: weight (down, constant) on one side, spring force (up, longer the
	# more it's stretched) on the other — their difference is the net restoring force.
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var at := Vector3(0, mass_y, 0)
	_vectors.add_child(_arrow(at + Vector3(0.42, 0, 0), at + Vector3(0.42, -1.1, 0), 0.055, _glow_mat(weight_color, 1.4)))   # weight mg
	var slen: float = clampf(0.7 + (-disp) * 1.3, 0.25, 1.8)
	_vectors.add_child(_arrow(at - Vector3(0.42, 0, 0), at - Vector3(0.42, 0, 0) + Vector3(0, slen, 0), 0.06, _glow_mat(spring_color, 1.6)))   # spring force up
