extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ForceCube

## @identity
## lineage: a vector you hold — grab the cube, and the force you apply draws itself as an
##   arrow out of its centre, split into its x / y / z components. An embodied force-display
##   prop (the grabbable that shows what your hand is doing to it).
## essence: the cube IS the tail of the vector; wherever you push it, the arrow points, and
##   the three coloured component arrows show how that one push is really three — so much
##   right, so much up, so much forward. Let go and the arrow falls to zero.
## truth: a force has no existence apart from the thing it acts on; bolt the vector to the
##   cube and "direction and magnitude" stop being abstract — they're where you shoved it.
##
## DNA: push 0..1 is the magnitude of the applied force; seed sets its direction. (Live,
## the direction + magnitude come from the grabbing hand's motion.)

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var push: float = 0.6
@export var cube_color: Color = Color(0.42, 0.78, 0.98)   # the cube
@export var force_color: Color = Color(0.98, 0.84, 0.32)  # the resultant force F
@export var x_color: Color = Color(0.95, 0.42, 0.40)      # Fx
@export var y_color: Color = Color(0.50, 0.92, 0.52)      # Fy
@export var z_color: Color = Color(0.46, 0.66, 0.98)      # Fz


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("push"): push = clampf(float(config_data["push"]), 0.0, 1.0)
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	cube_color = _parse_color(config_data.get("cube_color", cube_color), cube_color)
	force_color = _parse_color(config_data.get("force_color", force_color), force_color)
	_build()


func _build() -> void:
	for c in get_children():
		remove_child(c); c.queue_free()
	var rig := Node3D.new()
	rig.name = "ForceCubeRig"
	add_child(rig)
	_rng.seed = hash(seed)

	var center := Vector3(0.0, 0.7, 0.0)
	var mag: float = lerpf(0.55, 1.7, push)
	# seeded direction — biased forward + up so the components read
	var dir := Vector3(_rng.randf_range(0.4, 1.0), _rng.randf_range(0.2, 0.9), _rng.randf_range(-0.7, 0.7)).normalized()
	var f: Vector3 = dir * mag
	var tip: Vector3 = center + f

	# --- the cube (the grabbable, the tail of the vector) -----------------------
	rig.add_child(_box(center, Vector3(0.42, 0.42, 0.42), _glass_mat(cube_color, 0.30)))
	rig.add_child(_box(center, Vector3(0.30, 0.30, 0.30), _glow_mat(cube_color, 0.9)))
	# edge frame
	for ex in [-0.21, 0.21]:
		for ey in [-0.21, 0.21]:
			rig.add_child(_cylinder_between(center + Vector3(ex, ey, -0.21), center + Vector3(ex, ey, 0.21), 0.008, _glow_mat(cube_color.lerp(Color.WHITE, 0.4), 1.4)))

	# --- the component decomposition (a dashed box: F = Fx + Fy + Fz) -----------
	var cx := center + Vector3(f.x, 0, 0)
	var cxy := center + Vector3(f.x, f.y, 0)
	var dim := _glow_mat(Color(0.6, 0.62, 0.68), 0.35)
	rig.add_child(_dashed(center, cx, 0.006, dim))
	rig.add_child(_dashed(cx, cxy, 0.006, dim))
	rig.add_child(_dashed(cxy, tip, 0.006, dim))

	# --- the component arrows (x / y / z) ---------------------------------------
	if absf(f.x) > 0.05: rig.add_child(_arrow(center, cx, 0.016, _glow_mat(x_color, 1.2)))
	if absf(f.y) > 0.05: rig.add_child(_arrow(center, center + Vector3(0, f.y, 0), 0.016, _glow_mat(y_color, 1.2)))
	if absf(f.z) > 0.05: rig.add_child(_arrow(center, center + Vector3(0, 0, f.z), 0.016, _glow_mat(z_color, 1.2)))

	# --- the resultant force F (the hero arrow) ---------------------------------
	rig.add_child(_arrow(center, tip, 0.03, _glow_mat(force_color, 1.8)))

	# --- a faint motion trail behind the cube (opposite F) ----------------------
	for i in range(1, 4):
		var t := float(i) / 4.0
		rig.add_child(_box(center - f.normalized() * (0.18 * i), Vector3(0.30, 0.30, 0.30) * (1.0 - 0.2 * i),
			_glass_mat(cube_color, 0.12 * (1.0 - t))))

	# --- readout ----------------------------------------------------------------
	var lbl := _billboard_label(
		"F = (%+.2f, %+.2f, %+.2f)\n|F| = %.2f" % [f.x, f.y, f.z, mag],
		center + Vector3(0.0, mag * 0.6 + 0.7, 0.0), 28, force_color.lerp(Color.WHITE, 0.3))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rig.add_child(lbl)

	_settle(rig, 1.9)
