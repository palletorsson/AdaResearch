extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name DragLane

## @identity
## lineage: friction / drag made felt — F = -b·v, so velocity decays v ∝ e^(-bt) — a
##   forces toy for the embodied vectors-forces arc (the resistance you feel in the legs).
## essence: a runner enters a resistant medium at full tilt and slows; frozen
##   stroboscopically, its snapshots bunch together and its velocity arrows shrink as
##   the drag eats the motion. Run through air, water, honey — each pulls back harder.
## truth: drag is a force that only ever opposes — it never starts you moving, it only
##   spends what you already had; the faster you go, the harder it takes it back.
##
## A ToyConsole: the readout lives on the monitor, the DRAG slider drives the demo.
## DNA: drag 0..1 sweeps from glide (snapshots evenly spread) to dead-stop (piled up).

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var drag: float = 0.5
@export var color_a: Color = Color(0.50, 0.54, 0.60)      # lane / rig
@export var color_b: Color = Color(0.40, 0.82, 0.96)      # runner + velocity arrows
@export var accent: Color = Color(0.98, 0.82, 0.32)       # drag particles
@export var medium_color: Color = Color(0.30, 0.62, 0.85) # the resistant medium
@export var complexity: int = 6


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("drag"): drag = clampf(float(config_data["drag"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	medium_color = _parse_color(config_data.get("medium_color", medium_color), medium_color)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "DRAG LANE", "slider": "DRAG"}

func _param_get() -> float:
	return drag

func _param_set(v: float) -> void:
	drag = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("DragLaneRig")
	_rng.seed = hash(seed)

	# --- the decay ---------------------------------------------------------------
	var snaps: int = clampi(complexity + 3, 6, 12)
	var retention: float = clampf(1.0 - drag * 0.62, 0.20, 0.985)   # per-step velocity factor
	var v0: float = 0.46
	var run_y: float = 0.42
	var positions: Array[float] = []
	var speeds: Array[float] = []
	var x: float = 0.0
	for i in range(snaps):
		var v: float = v0 * pow(retention, float(i))
		positions.append(x)
		speeds.append(v)
		x += maxf(v, 0.02)
	var lane_len: float = x + 0.5

	var steel := _steel_mat(color_a)

	# --- lane + start gate + travel axis ----------------------------------------
	rig.add_child(_box(Vector3(lane_len * 0.5, 0.0, 0.0), Vector3(lane_len, 0.06, 0.7), steel))
	rig.add_child(_box(Vector3(0.0, 0.22, 0.0), Vector3(0.08, 0.44, 0.7), steel))
	rig.add_child(_arrow(Vector3(0.0, 0.05, 0.34), Vector3(lane_len, 0.05, 0.34), 0.016, _glow_mat(color_a, 0.5)))

	# --- the resistant medium (translucent volume + suspended particles) --------
	var med_start: float = positions[1] if positions.size() > 1 else 0.3
	var med_len: float = lane_len - med_start
	rig.add_child(_box(Vector3(med_start + med_len * 0.5, run_y, 0.0), Vector3(med_len, 0.7, 0.66), _medium_mat(medium_color)))
	var motes: int = clampi(int(med_len * 9.0), 8, 40)
	for _i in range(motes):
		rig.add_child(_sphere(Vector3(_rng.randf_range(med_start, lane_len - 0.1), run_y + _rng.randf_range(-0.28, 0.30), _rng.randf_range(-0.28, 0.28)),
			_rng.randf_range(0.012, 0.024), _glow_mat(accent, 1.0)))

	# --- stroboscopic runner: balls bunch up, velocity arrows shrink ------------
	for i in range(snaps):
		var fade: float = float(i) / float(snaps - 1)
		rig.add_child(_sphere(Vector3(positions[i], run_y, 0.0), 0.13, _glow_mat(color_b.lerp(Color(0.16, 0.18, 0.22), fade * 0.7), lerpf(1.2, 0.25, fade))))
		var vlen: float = speeds[i] * 1.05
		if vlen > 0.05:
			var base: Vector3 = Vector3(positions[i], run_y + 0.24, 0.0)
			rig.add_child(_arrow(base, base + Vector3(vlen, 0.0, 0.0), 0.022, _glow_mat(color_b, lerpf(1.5, 0.5, fade))))

	rig.add_child(_sphere(Vector3(positions[snaps - 1] + speeds[snaps - 1], run_y, 0.0), 0.06, _glow_mat(accent, 2.4)))

	# --- readout -> the monitor --------------------------------------------------
	set_readout("DRAG  F = -b·v\n\nv ∝ e^(-bt)\nb = %.2f" % drag, Color(0.55, 0.92, 1.0))

	_settle(rig)


# --- toy-specific helper ----------------------------------------------------

func _medium_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(c.r, c.g, c.b, 0.22)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = 0.25 if emissive else 0.0
	return m
