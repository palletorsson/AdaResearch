extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name FireworkBurst

## @identity
## lineage: the firework as pure projectile motion — a mortar throws sparks up and gravity
##   arcs every one of them into a parabola — the console rebuild of the old firework
##   launcher, for the embodied vectors-forces arc.
## essence: a fountain of projectiles launched in a cone; each is its own launch vector bent
##   by the same g, and together they bloom into an umbrella that widens and rises with the
##   burst. Low burst is a tight column, high burst a broad canopy of falling embers.
## truth: a firework is many straight throws sharing one gravity — the bloom is what a
##   fan of vectors looks like when the world pulls them all the same way.
##
## A ToyConsole: the readout lives on the monitor, the BURST slider drives the demo.
## DNA: burst 0..1 from a tight low column to a wide high canopy.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var burst: float = 0.6
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # mortar / rig
@export var color_b: Color = Color(0.99, 0.80, 0.35)     # spark gold (rising)
@export var accent: Color = Color(0.95, 0.35, 0.28)      # spark red (falling) / apex
@export var complexity: int = 6

const GRAVITY := 3.0


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("burst"): burst = clampf(float(config_data["burst"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "FIREWORK BURST", "slider": "BURST"}

func _param_get() -> float:
	return burst

func _param_set(v: float) -> void:
	burst = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("FireworkBurstRig")
	_rng.seed = hash(seed)

	var v0: float = lerpf(1.5, 3.2, burst)
	var spread: float = deg_to_rad(lerpf(12.0, 58.0, burst))   # cone half-angle from vertical
	var arcs: int = clampi(complexity + 5, 8, 14)
	var base_y: float = 0.22
	var origin: Vector3 = Vector3(0.0, base_y, 0.0)

	# --- the mortar -------------------------------------------------------------
	var steel := _steel_mat(color_a)
	rig.add_child(_cylinder(Vector3(0.0, 0.11, 0.0), 0.16, 0.22, steel))
	rig.add_child(_cylinder(Vector3(0.0, base_y, 0.0), 0.07, 0.12, _glow_mat(accent, 1.2 + burst)))

	# --- the fountain of arcs ---------------------------------------------------
	var steps: int = 12
	for i in range(arcs):
		var phi: float = TAU * float(i) / float(arcs) + _rng.randf_range(-0.18, 0.18)
		var elev: float = spread * _rng.randf_range(0.78, 1.0)              # from vertical
		var v: float = v0 * _rng.randf_range(0.85, 1.12)
		var dir: Vector3 = Vector3(sin(elev) * cos(phi), cos(elev), sin(elev) * sin(phi))
		var vy: float = v * dir.y
		var t_land: float = 2.0 * vy / GRAVITY
		for j in range(steps + 1):
			var t: float = t_land * float(j) / float(steps)
			var p: Vector3 = origin + dir * v * t - Vector3(0.0, 0.5 * GRAVITY * t * t, 0.0)
			var frac: float = float(j) / float(steps)
			rig.add_child(_sphere(p, lerpf(0.045, 0.02, frac),
				_glow_mat(color_b.lerp(accent, frac), lerpf(2.2, 0.7, frac))))
		# apex ember
		var apex_t: float = vy / GRAVITY
		var apex: Vector3 = origin + dir * v * apex_t - Vector3(0.0, 0.5 * GRAVITY * apex_t * apex_t, 0.0)
		rig.add_child(_sphere(apex, 0.055, _glow_mat(color_b.lerp(Color.WHITE, 0.3), 2.6)))

	set_readout("FOUNTAIN\n\nsparks under g\nburst = %.2f" % burst, color_b.lerp(Color.WHITE, 0.2))
	_settle(rig)
