extends "res://commons/artifacts/_toy_console/toy_console.gd"
class_name BounceWell

## @identity
## lineage: restitution made playable — h' = e·h, the bounce that keeps a fraction of its
##   height — a forces toy for the embodied vectors-forces arc (the clean console rebuild
##   of the old bouncing-ball sim).
## essence: a ball dropped into a well bounces, and each bounce returns to e times the last
##   height; frozen stroboscopically, the arcs shrink geometrically and bunch toward the
##   rest. e = 1 is a perpetual bounce, e = 0 a dead thud.
## truth: a bounce is a negotiation with the floor — how much of your fall you are allowed
##   to keep; restitution is the floor's mercy, between nothing and everything.
##
## A ToyConsole: the readout lives on the monitor, the RESTITUTION slider drives the demo.
## DNA: restitution 0..1 from dead thud to perpetual bounce.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var restitution: float = 0.6
@export var color_a: Color = Color(0.52, 0.56, 0.62)     # floor / rig
@export var color_b: Color = Color(0.40, 0.82, 0.96)     # the ball + arcs
@export var accent: Color = Color(0.98, 0.72, 0.30)      # apex markers / height ticks
@export var complexity: int = 6


func _ready() -> void:
	_console_ready()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("restitution"): restitution = clampf(float(config_data["restitution"]), 0.0, 1.0)
	if config_data.has("complexity"): complexity = int(config_data["complexity"])
	apply_base_config(config_data)
	color_a = _parse_color(config_data.get("color_a", color_a), color_a)
	color_b = _parse_color(config_data.get("color_b", color_b), color_b)
	accent = _parse_color(config_data.get("accent", accent), accent)
	_ensure_rack()
	_build_demo()


func _console_meta() -> Dictionary:
	return {"title": "BOUNCE WELL", "slider": "RESTITUTION"}

func _param_get() -> float:
	return restitution

func _param_set(v: float) -> void:
	restitution = v


func _build_demo() -> void:
	var rig := _fresh_demo_rig("BounceWellRig")
	_rng.seed = hash(seed)

	var e: float = clampf(restitution, 0.05, 0.97)
	var bounces: int = clampi(complexity + 3, 5, 9)
	var h0: float = 0.95
	var base_w: float = 0.6
	var steel := _steel_mat(color_a)

	# --- the floor + a drop guide -----------------------------------------------
	# total span first, so we can size the floor
	var total_w: float = 0.0
	for i in range(bounces):
		total_w += base_w * sqrt(maxf(pow(e, float(i)), 0.03))
	rig.add_child(_box(Vector3(total_w * 0.5, -0.03, 0.0), Vector3(total_w + 0.5, 0.06, 0.5), steel))
	rig.add_child(_box(Vector3(-0.18, h0 * 0.5, 0.0), Vector3(0.05, h0, 0.18), steel))   # drop tower

	# --- incoming drop ----------------------------------------------------------
	var drop_seg: int = 6
	for j in range(drop_seg + 1):
		var t: float = float(j) / float(drop_seg)
		var y: float = h0 * (1.0 - t * t)
		rig.add_child(_sphere(Vector3(lerpf(-0.05, 0.06, t), y, 0.0), 0.04, _glow_mat(color_b, lerpf(0.6, 1.2, t))))

	# --- the bounce series: apex heights decay by e -----------------------------
	var x: float = 0.0
	for i in range(bounces):
		var hi: float = h0 * pow(e, float(i))
		var wi: float = base_w * sqrt(maxf(hi / h0, 0.03))
		var fade: float = float(i) / float(bounces - 1)
		var arc_mat := _glow_mat(color_b.lerp(Color(0.16, 0.18, 0.22), fade * 0.7), lerpf(1.2, 0.4, fade))
		var steps: int = 9
		for j in range(steps + 1):
			var t: float = float(j) / float(steps)
			var px: float = x + wi * t
			var py: float = 4.0 * hi * t * (1.0 - t)
			rig.add_child(_sphere(Vector3(px, py, 0.0), 0.035, arc_mat))
		# apex ball + a faint height tick
		var apex_x: float = x + wi * 0.5
		rig.add_child(_sphere(Vector3(apex_x, hi, 0.0), 0.085, _glow_mat(accent, 2.2)))
		rig.add_child(_box(Vector3(apex_x, hi * 0.5, 0.0), Vector3(0.006, hi, 0.006), _glow_mat(accent.lerp(Color(0.2, 0.2, 0.24), 0.5), 0.4)))
		x += wi

	# rest marker where the bouncing dies
	rig.add_child(_sphere(Vector3(x, 0.04, 0.0), 0.06, _glow_mat(accent, 2.6)))

	set_readout("RESTITUTION\n\nh' = e·h\ne = %.2f" % e, Color(1.0, 0.82, 0.5))
	_settle(rig)
