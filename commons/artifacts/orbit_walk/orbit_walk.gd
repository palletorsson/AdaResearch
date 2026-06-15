extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name OrbitWalk

## @identity
## lineage: the walk-in twin of orbit_pair — a body-scale two-body system you stand inside.
##   A heavy star and a lighter planet wheel around the barycenter that belongs to neither,
##   and you stand at that still point while they fall around you, forever.
## essence: the two bodies pull on each other equally and oppositely (Newton's third law) and
##   orbit a common centre of mass; make one heavier and the barycenter slides toward it, the
##   orbits resizing to keep the balance. F = G m₁m₂/r².
## truth: an orbit is two things falling toward each other and missing, around a centre that
##   belongs to neither — and here you are standing on it.
##
## The large half of the orbit_pair pair. Bodies orbit live in _process; the equal-and-opposite
## gravity vectors ride them.

@export_range(0.0, 1.0, 0.01) var mass_ratio: float = 0.6
@export var separation: float = 3.6
@export var star_color: Color = Color(0.98, 0.82, 0.40)
@export var planet_color: Color = Color(0.45, 0.72, 0.96)
@export var force_color: Color = Color(0.96, 0.45, 0.42)
@export var orbit_color: Color = Color(0.42, 0.58, 0.72)

const BARY_Y := 2.3
var _star: Node3D
var _planet: Node3D
var _vectors: Node3D
var _t: float = 0.0
var _omega: float = 0.5
var _d1: float = 1.0
var _d2: float = 1.0
var _m1: float = 2.0


func _ready() -> void:
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("mass_ratio"): mass_ratio = clampf(float(config["mass_ratio"]), 0.0, 1.0)
	if config.has("separation"): separation = float(config["separation"])
	if config.has("emissive"): emissive = bool(config["emissive"])
	star_color = _parse_color(config.get("star_color", star_color), star_color)
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_m1 = 1.0 + mass_ratio * 2.6
	var m2 := 1.0
	_d1 = separation * m2 / (_m1 + m2)        # star's distance from the barycenter
	_d2 = separation * _m1 / (_m1 + m2)        # planet's distance
	_omega = 0.45
	var steel := _steel_mat(Color(0.4, 0.42, 0.48))

	# the barycenter: a pole you stand by + a bright marker
	add_child(_cylinder(Vector3(0, BARY_Y * 0.5, 0), 0.09, BARY_Y, steel))
	add_child(_sphere(Vector3(0, BARY_Y, 0), 0.12, _glow_mat(Color(0.95, 0.95, 1.0), 1.2)))
	add_child(_billboard_label("barycenter", Vector3(0, BARY_Y + 0.25, 0), 20, Color(0.8, 0.82, 0.9)))

	# orbit rings at d1 and d2
	_add_ring(_d1, _glow_mat(orbit_color.lerp(star_color, 0.3), 0.7))
	_add_ring(_d2, _glow_mat(orbit_color.lerp(planet_color, 0.3), 0.7))

	# the two bodies (orbit in _process)
	_star = Node3D.new(); add_child(_star)
	var r1 := 0.28 * pow(_m1, 0.34)
	_star.add_child(_sphere(Vector3.ZERO, r1, _glow_mat(star_color, 1.6)))
	_star.add_child(_sphere(Vector3.ZERO, r1 * 1.5, _halo(star_color)))
	_planet = Node3D.new(); add_child(_planet)
	_planet.add_child(_sphere(Vector3.ZERO, 0.28, _glow_mat(planet_color, 1.2)))
	_vectors = Node3D.new(); add_child(_vectors)

	add_child(_billboard_label("GRAVITY\nF = G m₁m₂/r²\nm₁ : m₂ = %.1f : 1" % _m1,
		Vector3(0, BARY_Y + 1.6, 0), 30, star_color.lerp(Color.WHITE, 0.3)))
	_advance()


func _add_ring(rad: float, mat: Material) -> void:
	var n := 48
	for i in range(n):
		var a := TAU * float(i) / float(n)
		add_child(_sphere(Vector3(cos(a) * rad, BARY_Y, sin(a) * rad), 0.025, mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _star == null:
		return
	_t += delta
	_advance()


func _advance() -> void:
	var theta: float = _t * _omega
	var radial := Vector3(cos(theta), 0, sin(theta))
	var bary := Vector3(0, BARY_Y, 0)
	var sp := bary + radial * _d1
	var pp := bary - radial * _d2                 # opposite side of the barycenter
	_star.position = sp
	_planet.position = pp
	# equal + opposite gravity along the line between them, magnitude ~ 1/r²
	for c in _vectors.get_children():
		_vectors.remove_child(c); c.queue_free()
	var to_p: Vector3 = (pp - sp).normalized()
	var r: float = sp.distance_to(pp)
	var f: float = clampf(_m1 / (r * r) * 3.0, 0.3, 1.6)
	_vectors.add_child(_arrow(sp, sp + to_p * f, 0.05, _glow_mat(force_color, 1.5)))      # pull on star
	_vectors.add_child(_arrow(pp, pp - to_p * f, 0.05, _glow_mat(force_color, 1.5)))      # pull on planet (opposite)


func _halo(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.18)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true; m.emission = c
	m.emission_energy_multiplier = 1.3 if emissive else 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m
