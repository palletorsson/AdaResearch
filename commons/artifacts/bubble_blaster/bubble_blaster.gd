extends "res://commons/artifacts/_embodied/pickable_prop.gd"
class_name BubbleBlaster

## @identity
## lineage: a particle launcher with its launch vector drawn on the muzzle — a soap-bubble
##   gun that fires a stream of bubbles and shows the output force/velocity that throws them.
##   An embodied force-display prop (the held thing whose output IS a vector).
## essence: pull the trigger and bubbles pour out a spreading cone; the muzzle wears an
##   arrow for the launch speed and a faint cone for the spread. Crank the output and the
##   arrow stretches, the cone widens, the bubbles fly faster and further.
## truth: every emitter is a little vector field — each particle leaves with a velocity, and
##   the "force" of a spray is just that launch vector, made of thousands of tiny departures.
##
## DNA: output 0..1 dials the launch — the muzzle vector's length, the spread angle, and how
## far/fast the bubbles travel. seed jitters the bubbles.

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var output: float = 0.6
@export var body_color: Color = Color(0.98, 0.55, 0.74)   # the pink gun
@export var trim_color: Color = Color(1.0, 0.95, 0.98)    # white trim
@export var force_color: Color = Color(0.40, 0.86, 1.0)   # the output velocity vector
@export var fluid_color: Color = Color(0.98, 0.62, 0.80)  # soap reservoir

# fire-when-held state
var _bubbles: Array = []          # [{node, mat, ar, radf, phase, size, alpha}]
var _fire_level: float = 0.0      # 0 idle (dim slow drift) -> 1 firing (bright fast stream)
var _fire_target: float = 0.0
var _stream_t: float = 0.0
var _noz: Vector3
var _maxd: float = 1.0
var _spr: float = 0.2


func _ready() -> void:
	super()                                  # pickable.gd._ready — grabbable
	freeze = true
	_ensure_collision(Vector3(1.2, 0.7, 0.4))
	_build()
	# picking it up starts the spray; dropping it stops
	if not grabbed.is_connected(_on_grab): grabbed.connect(_on_grab)
	if not dropped.is_connected(_on_drop): dropped.connect(_on_drop)


func _on_grab(_p: Variant, _by: Variant) -> void:
	_fire_target = 1.0

func _on_drop(_p: Variant) -> void:
	_fire_target = 0.0


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("output"): output = clampf(float(config_data["output"]), 0.0, 1.0)
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	body_color = _parse_color(config_data.get("body_color", body_color), body_color)
	force_color = _parse_color(config_data.get("force_color", force_color), force_color)
	_build()


func _build() -> void:
	# clear only the Visual child — never the CollisionShape the grab needs
	var old := get_node_or_null("Visual")
	if old: old.queue_free()
	var rig := Node3D.new()
	rig.name = "Visual"
	add_child(rig)
	_rng.seed = hash(seed)

	var v_out: float = lerpf(0.85, 2.0, output)
	var spread: float = lerpf(deg_to_rad(7.0), deg_to_rad(28.0), output)
	var pink := _matte_mat(body_color, 0.5)
	var white := _matte_mat(trim_color, 0.4)

	# --- the gun (points +X) ----------------------------------------------------
	rig.add_child(_box(Vector3(0.0, 0.55, 0.0), Vector3(0.58, 0.20, 0.16), pink))          # barrel body
	rig.add_child(_box(Vector3(0.22, 0.60, 0.0), Vector3(0.18, 0.12, 0.14), pink))          # top rib
	var nozzle := Vector3(0.32, 0.55, 0.0)
	var ring := _torus(nozzle, 0.10, 0.03, white); ring.rotation.z = PI * 0.5
	rig.add_child(ring)                                                                     # muzzle ring
	# trigger handle — a proper pistol grip: hangs down and angles back toward the shooter
	var grip := _box(Vector3(-0.16, 0.32, 0.0), Vector3(0.15, 0.38, 0.13), pink)
	grip.rotation.z = deg_to_rad(-24.0)
	rig.add_child(grip)
	rig.add_child(_box(Vector3(-0.20, 0.16, 0.0), Vector3(0.17, 0.07, 0.12), _matte_mat(body_color.darkened(0.1), 0.5)))  # grip base
	rig.add_child(_box(Vector3(-0.05, 0.46, 0.0), Vector3(0.05, 0.11, 0.06), white))               # trigger
	# soap reservoir under the barrel (translucent, with fluid)
	var tank := _cylinder(Vector3(0.04, 0.33, 0.0), 0.11, 0.26, _glass_mat(Color(0.95, 0.97, 1.0), 0.22))
	tank.rotation.x = PI * 0.5
	rig.add_child(tank)
	var fluid := _cylinder(Vector3(0.04, 0.30, 0.0), 0.10, 0.13, _glass_mat(fluid_color, 0.45))
	fluid.rotation.x = PI * 0.5
	rig.add_child(fluid)
	# the bubble window (round, with foam) on the barrel side
	rig.add_child(_sphere(Vector3(-0.05, 0.55, 0.085), 0.07, _glass_mat(Color(0.9, 0.95, 1.0), 0.3)))

	# --- the bubble stream — a pool _process animates (drifts idle, streams when held) ---
	_bubbles.clear()
	_noz = nozzle
	_maxd = 0.9 * (0.7 + v_out * 0.6)
	_spr = spread
	var stream := Node3D.new(); stream.name = "Stream"; rig.add_child(stream)
	var count: int = int(lerpf(11.0, 26.0, output))
	for i in range(count):
		var hue: float = fposmod(0.55 + float(i) * 0.07, 1.0)
		var mat := _glass_mat(Color.from_hsv(hue, 0.35, 1.0), 0.4)
		var node := _sphere(Vector3.ZERO, 1.0, mat)   # unit sphere, scaled per-frame
		stream.add_child(node)
		_bubbles.append({"node": node, "mat": mat, "ar": _rng.randf_range(0.0, TAU),
			"radf": _rng.randf_range(0.25, 1.0), "phase": float(i) / float(count),
			"size": _rng.randf_range(0.020, 0.055)})
	_place_bubbles()

	# --- the output velocity vector + spread cone -------------------------------
	rig.add_child(_arrow(nozzle, nozzle + Vector3(v_out, 0.0, 0.0), 0.028, _glow_mat(force_color, 1.8)))
	var cone_mat := _glow_mat(force_color.lerp(Color.WHITE, 0.3), 0.5)
	for ar2 in [0.0, PI * 0.5, PI, PI * 1.5]:
		var edge: Vector3 = nozzle + Vector3(v_out * 0.8, sin(ar2) * tan(spread) * v_out * 0.8, cos(ar2) * tan(spread) * v_out * 0.8)
		rig.add_child(_dashed(nozzle, edge, 0.006, cone_mat))

	# --- readout ----------------------------------------------------------------
	rig.add_child(_billboard_label(
		"v_out = %.2f\nspread = %d°\nbubbles = %d" % [v_out, int(roundf(rad_to_deg(spread))), count],
		nozzle + Vector3(0.3, 0.5, 0.0), 28, force_color.lerp(Color.WHITE, 0.3)))

	_settle(rig, 1.9)


# --- the spray: each bubble flies the nozzle→cone path, recycling -------------
func _place_bubbles() -> void:
	for bdata in _bubbles:
		_place_one(bdata, float(bdata["phase"]))


func _place_one(bdata: Dictionary, ph: float) -> void:
	var dist: float = lerpf(0.05, _maxd, ph)
	var rad: float = tan(_spr) * dist * float(bdata["radf"])
	var ar: float = float(bdata["ar"])
	var node: Node3D = bdata["node"]
	node.position = _noz + Vector3(dist, sin(ar) * rad, cos(ar) * rad)
	node.scale = Vector3.ONE * (float(bdata["size"]) * (0.5 + 0.5 * sin(ph * PI)))   # born, swell, pop
	var mat: StandardMaterial3D = bdata["mat"]
	mat.emission_energy_multiplier = (0.3 + 1.2 * _fire_level) if emissive else 0.0   # glows when firing


func _process(delta: float) -> void:
	if Engine.is_editor_hint() or _bubbles.is_empty():
		return
	_fire_level = lerpf(_fire_level, _fire_target, clampf(delta * 4.0, 0.0, 1.0))
	_stream_t += delta * lerpf(0.10, 0.9, _fire_level)        # idle drift → fast stream when held
	for bdata in _bubbles:
		_place_one(bdata, fposmod(float(bdata["phase"]) + _stream_t, 1.0))
