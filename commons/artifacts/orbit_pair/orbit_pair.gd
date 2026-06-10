extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name OrbitPair

## @identity
## lineage: gravity made playable — F = G m₁m₂ / r², the inverse-square attraction that
##   holds two bodies in orbit about their shared centre of mass. The clean rebuild of the
##   old two-body sim, for the embodied vectors-forces arc (gravity / orbits gap).
## essence: two bodies pull on each other along the line between them, equal and opposite
##   (Newton's third law); they don't fall together because they're falling *around* a
##   point that balances their masses — the barycenter. Make one heavier and that point
##   slides toward it; the orbits resize to match.
## truth: an orbit is two things falling toward each other and missing, forever, around a
##   centre that belongs to neither.
##
## A ToyConsole: the readout lives on the monitor, the MASS-RATIO slider drives the demo.
## DNA: mass_ratio 0..1 from an equal binary to a dominant star + planet.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var mass_ratio: float = 0.6
@export var color_a: Color = Color(0.98, 0.82, 0.40)     # the heavier body (star)
@export var color_b: Color = Color(0.45, 0.72, 0.96)     # the lighter body (planet)
@export var accent: Color = Color(0.96, 0.45, 0.42)      # gravity force vectors
@export var orbit_color: Color = Color(0.40, 0.60, 0.72) # the orbit paths
@export var complexity: int = 6

const SEP := 1.15   # total separation scale


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("mass_ratio"): mass_ratio = clampf(float(config_data["mass_ratio"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	orbit_color = _parse_color(config_data.get("orbit_color", orbit_color), orbit_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "ORBIT PAIR", "slider": "MASS RATIO"}

func _param_get() -> float:
	return mass_ratio

func _param_set(v: float) -> void:
	mass_ratio = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("OrbitPairRig")
	_rng.seed = hash(seed)

	# --- the two-body system ----------------------------------------------------
	var m1: float = 1.0 + mass_ratio * 2.6     # heavier (star)
	var m2: float = 1.0                         # lighter (planet)
	var d1: float = SEP * m2 / (m1 + m2)        # star's distance from barycenter
	var d2: float = SEP * m1 / (m1 + m2)        # planet's distance
	var phi: float = _rng.randf_range(0.0, TAU)
	var radial: Vector3 = Vector3(cos(phi), 0.0, sin(phi))
	var bary: Vector3 = Vector3(0.0, 0.5, 0.0)
	var p1: Vector3 = bary + radial * d1        # star
	var p2: Vector3 = bary - radial * d2        # planet
	var r: float = p1.distance_to(p2)
	var force: float = m1 * m2 / (r * r)        # G = 1; same on both (3rd law)

	# --- orbit paths + barycenter -----------------------------------------------
	_add_orbit_ring(rig, bary, d1, _glow_mat(orbit_color.lerp(color_a, 0.3), 0.7))
	_add_orbit_ring(rig, bary, d2, _glow_mat(orbit_color.lerp(color_b, 0.3), 0.7))
	rig.add_child(_sphere(bary, 0.035, _glow_mat(Color(0.9, 0.9, 0.95), 0.8)))
	rig.add_child(_dashed(p1, p2, 0.01, _glow_mat(Color(0.5, 0.52, 0.58), 0.4)))

	# --- the bodies -------------------------------------------------------------
	var r1: float = 0.13 * pow(m1, 0.34)
	var r2: float = 0.13 * pow(m2, 0.34)
	rig.add_child(_sphere(p1, r1, _glow_mat(color_a, 1.6)))
	rig.add_child(_sphere(p1, r1 * (1.15 + mass_ratio * 0.95), _halo_mat(color_a)))   # halo ∝ dominance
	rig.add_child(_sphere(p2, r2, _body_mat(color_b)))

	# --- the gravity vectors: equal and opposite --------------------------------
	var to2: Vector3 = (p2 - p1).normalized()
	rig.add_child(_arrow(p1, p1 + to2 * force * 0.5, 0.026, _glow_mat(accent, 1.6)))
	rig.add_child(_arrow(p2, p2 - to2 * force * 0.5, 0.026, _glow_mat(accent, 1.6)))

	# --- velocity tangents ------------------------------------------------------
	var tangent: Vector3 = Vector3(-radial.z, 0.0, radial.x)
	rig.add_child(_arrow(p1, p1 + tangent * (d1 * 0.7 + 0.12), 0.02, _glow_mat(color_a.lerp(Color.WHITE, 0.3), 1.0)))
	rig.add_child(_arrow(p2, p2 - tangent * (d2 * 0.7 + 0.12), 0.02, _glow_mat(color_b.lerp(Color.WHITE, 0.3), 1.0)))

	# --- readout -> the monitor --------------------------------------------------
	set_readout("GRAVITY\n\nF = G m₁m₂/r²\nm₁:m₂ = %.1f : 1" % m1, Color(1.0, 0.82, 0.5))

	_settle(rig)


# --- toy-specific helpers ---------------------------------------------------

func _add_orbit_ring(parent: Node3D, center: Vector3, radius: float, mat: Material) -> void:
	var n: int = clampi(complexity * 5 + 12, 24, 60)
	for i in range(n):
		var a: float = TAU * float(i) / float(n)
		parent.add_child(_sphere(center + Vector3(cos(a) * radius, 0.0, sin(a) * radius), 0.012, mat))


func _halo_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.18)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 1.4 if emissive else 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	return m


func _body_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.5
	m.metallic = 0.2
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.3 if emissive else 0.1
	return m
