extends "res://commons/artifacts/_embodied/pickable_prop.gd"
class_name ForceCube

## @identity
## lineage: a vector you hold — grab the cube and the force you apply draws itself as an
##   arrow out of its centre, split into x / y / z components. An embodied force-display
##   prop, now genuinely grabbable (XRTools pickable).
## essence: the cube IS the tail of the vector; move it and the arrow points the way it's
##   going, its length the speed; the three coloured component arrows show how that one
##   motion is really three. Hold it still and it shows its resting force.
## truth: a force has no existence apart from the thing it acts on — bolt the vector to the
##   cube and "direction and magnitude" become where, and how hard, you shoved it.
##
## Grab it (VR) or pointer-drag it; the live vector is the cube's own velocity. seed/push
## set the resting vector shown when it isn't moving (and in the gallery).

@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var push: float = 0.6
@export var cube_color: Color = Color(0.42, 0.78, 0.98)
@export var force_color: Color = Color(0.98, 0.84, 0.32)
@export var x_color: Color = Color(0.95, 0.42, 0.40)
@export var y_color: Color = Color(0.50, 0.92, 0.52)
@export var z_color: Color = Color(0.46, 0.66, 0.98)

const CUBE := 0.40

var _last_pos: Vector3
var _last_f: Vector3 = Vector3.INF


func _ready() -> void:
	super()                                  # pickable_prop._ready -> pickable.gd._ready + set_process
	freeze = true
	# zero-gravity throw: on release it unfreezes and keeps the throw velocity (let_go sets
	# linear_velocity); with no gravity it flies straight off the way you let it go.
	gravity_scale = 0.0
	linear_damp = 0.3                        # drifts to a slow stop so it stays recoverable
	angular_damp = 0.5
	release_mode = 0                         # ReleaseMode.UNFROZEN — become dynamic on release
	_ensure_collision(Vector3(CUBE, CUBE, CUBE))
	_build_body()
	demo_root = Node3D.new(); demo_root.name = "Vec"; add_child(demo_root)
	_last_pos = global_position
	_redraw(_resting_force())


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("push"): push = clampf(float(config_data["push"]), 0.0, 1.0)
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	cube_color = _parse_color(config_data.get("cube_color", cube_color), cube_color)
	force_color = _parse_color(config_data.get("force_color", force_color), force_color)
	if demo_root == null:
		demo_root = Node3D.new(); demo_root.name = "Vec"; add_child(demo_root)
	_redraw(_resting_force())


# the resting/default vector (seeded) — shown when the cube isn't being moved
func _resting_force() -> Vector3:
	_rng.seed = hash(seed)
	var mag: float = lerpf(0.55, 1.7, push)
	return Vector3(_rng.randf_range(0.4, 1.0), _rng.randf_range(0.2, 0.9), _rng.randf_range(-0.7, 0.7)).normalized() * mag


func _build_body() -> void:
	if has_node("Body"):
		return
	var b := Node3D.new(); b.name = "Body"; add_child(b)
	b.add_child(_box(Vector3.ZERO, Vector3(CUBE, CUBE, CUBE), _glass_mat(cube_color, 0.30)))
	b.add_child(_box(Vector3.ZERO, Vector3(0.30, 0.30, 0.30), _glow_mat(cube_color, 0.9)))
	for ex in [-0.20, 0.20]:
		for ey in [-0.20, 0.20]:
			b.add_child(_cylinder_between(Vector3(ex, ey, -0.20), Vector3(ex, ey, 0.20), 0.008, _glow_mat(cube_color.lerp(Color.WHITE, 0.4), 1.4)))


# --- per-frame: the live vector is the cube's own velocity -------------------
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var vel: Vector3 = (global_position - _last_pos) / maxf(delta, 0.0001)
	_last_pos = global_position
	var f_world: Vector3 = (vel * 0.5).limit_length(2.6)
	if f_world.length() < 0.12:
		f_world = global_transform.basis * _resting_force()   # at rest → resting vector
	# draw in body-local so the arrow keeps pointing the world way it's moving
	_redraw(global_transform.basis.inverse() * f_world)


func _redraw(f: Vector3) -> void:
	if demo_root == null or f.distance_to(_last_f) < 0.02:
		return
	_last_f = f
	for c in demo_root.get_children():
		demo_root.remove_child(c); c.queue_free()
	var tip := f
	# component decomposition box
	var dim := _glow_mat(Color(0.6, 0.62, 0.68), 0.35)
	demo_root.add_child(_dashed(Vector3.ZERO, Vector3(f.x, 0, 0), 0.006, dim))
	demo_root.add_child(_dashed(Vector3(f.x, 0, 0), Vector3(f.x, f.y, 0), 0.006, dim))
	demo_root.add_child(_dashed(Vector3(f.x, f.y, 0), tip, 0.006, dim))
	if absf(f.x) > 0.05: demo_root.add_child(_arrow(Vector3.ZERO, Vector3(f.x, 0, 0), 0.016, _glow_mat(x_color, 1.2)))
	if absf(f.y) > 0.05: demo_root.add_child(_arrow(Vector3.ZERO, Vector3(0, f.y, 0), 0.016, _glow_mat(y_color, 1.2)))
	if absf(f.z) > 0.05: demo_root.add_child(_arrow(Vector3.ZERO, Vector3(0, 0, f.z), 0.016, _glow_mat(z_color, 1.2)))
	demo_root.add_child(_arrow(Vector3.ZERO, tip, 0.03, _glow_mat(force_color, 1.8)))
	var lbl := _billboard_label("F = (%+.2f, %+.2f, %+.2f)\n|F| = %.2f" % [f.x, f.y, f.z, f.length()],
		Vector3(0.0, f.length() * 0.6 + 0.55, 0.0), 26, force_color.lerp(Color.WHITE, 0.3))
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	demo_root.add_child(lbl)
