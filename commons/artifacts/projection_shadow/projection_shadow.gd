extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name ProjectionShadow

## @identity
## lineage: vector projection made playable — proj_n(a) = (a · n̂) n̂ — the third
##   operations toy (with dot_aligner and torque_crank) for the embodied vectors-forces arc.
## essence: a sun overhead, an object floating off a rail; the object's shadow lands on the
##   rail, and the shadow's distance from the origin IS a · n̂ — the projection of the
##   object's position onto the axis. The part that doesn't reach the rail is the rejection.
## truth: a projection is the part of one vector that lives along another — the shadow it
##   casts; what's left over is what makes it different.
##
## A ToyConsole: the readout lives on the monitor, the PROJECTION slider drives the demo.
## DNA: projection 0..1 swings the object from perpendicular (no shadow) to along the rail.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var projection: float = 0.7
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # rail / axis n̂
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the vector a
@export var accent: Color = Color(0.98, 0.82, 0.32)      # the projection shadow
@export var sun_color: Color = Color(1.0, 0.92, 0.62)    # the light
@export var complexity: int = 6


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("projection"): projection = clampf(float(config_data["projection"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	sun_color = _parse_color(config_data.get("sun_color", sun_color), sun_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "PROJECTION SHADOW", "slider": "PROJECTION"}

func _param_get() -> float:
	return projection

func _param_set(v: float) -> void:
	projection = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("ProjectionShadowRig")
	_rng.seed = hash(seed)

	# --- the geometry -----------------------------------------------------------
	var reach: float = _rng.randf_range(1.2, 1.45)            # |a|
	var origin: Vector3 = Vector3.ZERO
	var alpha: float = acos(clampf(projection, 0.0, 1.0))     # angle of a from the rail
	var px: float = reach * projection                       # a·n̂
	var py: float = reach * sqrt(maxf(1.0 - projection * projection, 0.0))  # rejection height
	var p: Vector3 = origin + Vector3(px, py, 0.0)           # the object
	var foot: Vector3 = origin + Vector3(px, 0.0, 0.0)       # shadow lands = (a·n̂)n̂

	var steel := _steel_mat(color_a)

	# --- the rail (axis n̂) + origin marker --------------------------------------
	var rail_len: float = reach + 0.35
	rig.add_child(_box(Vector3(rail_len * 0.5, 0.0, 0.0), Vector3(rail_len, 0.05, 0.18), steel))
	rig.add_child(_arrow(Vector3(0.0, 0.05, 0.0), Vector3(rail_len, 0.05, 0.0), 0.018, _glow_mat(color_a, 0.6)))
	rig.add_child(_sphere(origin + Vector3(0.0, 0.05, 0.0), 0.05, _glow_mat(Color(0.9, 0.9, 0.95), 0.6)))

	# --- the vector a + the object ----------------------------------------------
	rig.add_child(_arrow(origin + Vector3(0.0, 0.05, 0.0), p, 0.03, _glow_mat(color_b, 1.4)))
	rig.add_child(_box(p, Vector3(0.20, 0.20, 0.20), _glow_mat(color_b.lerp(Color.WHITE, 0.25), 0.8)))

	# --- the sun + rays straight down -------------------------------------------
	var sun_pos: Vector3 = p + Vector3(0.0, 0.95, 0.0)
	rig.add_child(_sphere(sun_pos, 0.16, _glow_mat(sun_color, 4.5)))
	var ray_mat := _glow_mat(sun_color, 0.5)
	for dx in [-0.07, 0.0, 0.07]:
		rig.add_child(_cylinder_between(sun_pos + Vector3(dx, 0.0, 0.0), foot + Vector3(dx, 0.0, 0.0), 0.004, ray_mat))

	# --- the projection (shadow): O → foot --------------------------------------
	rig.add_child(_box(Vector3(px * 0.5, 0.028, 0.0), Vector3(maxf(px, 0.02), 0.06, 0.22), _glow_mat(accent, 1.4 + 1.6 * projection)))
	rig.add_child(_sphere(foot + Vector3(0.0, 0.04, 0.0), 0.07, _glow_mat(accent, 2.4)))
	rig.add_child(_box(foot + Vector3(0.0, 0.03, 0.0), Vector3(0.22, 0.012, 0.22), _shadow_mat()))

	# --- the rejection (perpendicular drop) -------------------------------------
	if py > 0.03:
		rig.add_child(_dashed(p, foot, 0.014, _glow_mat(color_b.lerp(Color(0.2, 0.2, 0.24), 0.5), 0.5)))

	# --- readout -> the monitor --------------------------------------------------
	set_readout("PROJ  (a · n̂) n̂\n\na · n̂ = %.2f\nα = %d°" % [px, int(roundf(rad_to_deg(alpha)))],
		Color(1.0, 0.85, 0.5))

	_settle(rig)


# --- toy-specific helper ----------------------------------------------------

func _shadow_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.05, 0.05, 0.07)
	m.roughness = 1.0
	return m
