extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name WeatherVane

## @identity
## lineage: wind made playable — F_drag = ½ ρ v² C_d A — the weather the embodied
##   vectors-forces arc was missing: a force you can't see, only the bend of the things it
##   pushes. The clean toy the old wind-tunnel / windmill examples never became.
## essence: a weather vane swings to point downwind while a flag streams off the pole; the
##   wind's force grows with the SQUARE of its speed, so a doubling of wind quadruples the
##   push — the flag goes from a lazy ripple to a horizontal snap.
## truth: wind is just air with somewhere to be; the force is in the speed, squared, and a
##   flag is a little instrument that integrates it for you.
##
## A ToyConsole: the WIND slider sets the speed; the demo is the vane + flag + the drag
## vector (∝ v²) + streaming air. DNA: wind 0..1 — the force climbs quadratically.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var wind: float = 0.55
@export var vane_color: Color = Color(0.62, 0.66, 0.72)    # the steel vane / pole
@export var flag_color: Color = Color(0.95, 0.42, 0.30)    # the flag
@export var force_color: Color = Color(0.98, 0.82, 0.32)   # the drag force (∝ v²)
@export var air_color: Color = Color(0.55, 0.85, 1.0)      # the streaming air

const POLE_H := 1.6


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("wind"): wind = clampf(float(config_data["wind"]), 0.0, 1.0)
	apply_base_config(config_data)
	vane_color = _parse_color(config_data.get("vane_color", vane_color), vane_color)
	flag_color = _parse_color(config_data.get("flag_color", flag_color), flag_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "WEATHER VANE", "slider": "WIND"}

func _param_get() -> float:
	return wind

func _param_set(v: float) -> void:
	wind = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("WeatherVaneRig")
	_rng.seed = hash(seed)
	var v: float = lerpf(2.0, 22.0, wind)              # wind speed
	var drag: float = (v * v) / 484.0                  # ∝ v² (normalised to 1 at max)
	var steel := _steel_mat(vane_color)

	# --- the pole + base --------------------------------------------------------
	rig.add_child(_cylinder(Vector3(0, 0.06, 0), 0.18, 0.12, _steel_mat(vane_color.darkened(0.3))))
	rig.add_child(_cylinder(Vector3(0, POLE_H * 0.5, 0), 0.04, POLE_H, steel))
	var hub := Vector3(0, POLE_H, 0)
	rig.add_child(_sphere(hub, 0.07, steel))

	# --- the weather vane: arrow points downwind (+X) ---------------------------
	# tail fin (upwind) + arrow head (downwind), the whole vane swung to face the wind
	rig.add_child(_arrow(hub - Vector3(0.46, 0, 0), hub + Vector3(0.5, 0, 0), 0.03, steel))
	var fin := _box(hub - Vector3(0.42, 0.0, 0.0), Vector3(0.04, 0.26, 0.30), steel)
	rig.add_child(fin)
	# N/S/E/W direction stubs below the vane
	for d in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
		rig.add_child(_cylinder_between(hub - Vector3(0, 0.12, 0), hub - Vector3(0, 0.12, 0) + d * 0.16, 0.012, _steel_mat(vane_color.darkened(0.2))))

	# --- the flag streaming off the pole, bending with the wind -----------------
	var fly_y: float = POLE_H - 0.35
	var segs := 7
	var prev := Vector3(0.04, fly_y, 0.0)
	for i in range(segs):
		var t: float = float(i + 1) / float(segs)
		# more bend toward the tip and with stronger wind; a little flutter
		var bend: float = (0.18 + 0.62 * wind) * t
		var flutter: float = sin(t * 6.0 + wind * 5.0) * 0.06 * t * (0.4 + wind)
		var p := Vector3(0.04 + t * 0.55, fly_y + bend * 0.0 + flutter, 0.0) + Vector3(0, -t * (0.3 - 0.28 * wind), 0)
		p.x = 0.04 + t * lerpf(0.35, 0.7, wind)
		rig.add_child(_box((prev + p) * 0.5, Vector3((p - prev).length(), 0.16, 0.01), _glow_mat(flag_color.lerp(Color.WHITE, t * 0.3), 0.6)))
		prev = p

	# --- the wind force vector (horizontal, ∝ v²) -------------------------------
	var fpos := Vector3(0.0, fly_y, 0.4)
	rig.add_child(_arrow(fpos, fpos + Vector3(drag * 1.3, 0, 0), 0.03, _glow_mat(force_color, 1.7)))

	# --- streaming air: dashed streaks flowing downwind, denser with speed -------
	var streaks: int = clampi(int(2.0 + wind * 9.0), 2, 12)
	for i in range(streaks):
		var sy: float = _rng.randf_range(0.3, POLE_H + 0.2)
		var sz: float = _rng.randf_range(-0.5, 0.5)
		var sx: float = _rng.randf_range(-1.2, -0.6)
		rig.add_child(_dashed(Vector3(sx, sy, sz), Vector3(sx + lerpf(0.4, 1.3, wind), sy, sz), 0.012, _glow_mat(air_color, 0.4 + wind)))

	# --- readout ----------------------------------------------------------------
	set_readout("WIND\n\nv = %.1f m/s\nF = ½ρv²C_dA\n∝ v²  →  %.2f\n%s" % [v, drag,
		("GALE" if wind > 0.75 else ("BREEZE" if wind > 0.35 else "CALM"))],
		force_color.lerp(Color.WHITE, 0.2))
	_settle(rig)
