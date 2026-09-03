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

## How heavily the cube falls. 1.0 is ordinary weight; 0.0 restores the old
## floating probe for a room that wants one. force_field_zone overrides this
## while the cube is inside a field, and puts it back on the way out.
@export var falls: float = 1.0
## A cube that drops this far below where it started has left the room, and
## comes back rather than falling forever. A chasm map has no floor to catch
## it and no reset cube; without this, throwing the probe in loses it.
@export var recover_below_m: float = 4.0
@export var seed: int = 0
@export_range(0.0, 1.0, 0.01) var push: float = 0.6
@export var cube_color: Color = Color(0.42, 0.78, 0.98)
@export var force_color: Color = Color(0.98, 0.84, 0.32)
@export var x_color: Color = Color(0.95, 0.42, 0.40)
@export var y_color: Color = Color(0.50, 0.92, 0.52)
@export var z_color: Color = Color(0.46, 0.66, 0.98)

## --- DNA (stage 2, promoted 2026-08-05) ---------------------------------------
## HOW THE COMPONENTS ARE PUT ON THE GEOMETRY. The word and the meanings of chain,
## box and none are taken character for character from basis_vectors_rig,
## vector_magnitude_demo and example_1_5_vector_magnitude_vr, which ask the same
## question of the same three RGB legs. This is the one member of that family you
## can PICK UP, so here the decomposition follows a vector you are holding.
##   both  - the three legs leaving the origin AND the dashed staircase walking
##           origin -> x -> xy -> tip. The shipped picture: this artifact is the
##           only one in the family that draws the star and the chain at once.
##   chain - the legs walked tip to tail, solid and coloured, so the last one
##           lands exactly on the arrow's tip: magnitude as a shortcut across a
##           staircase whose steps you can count.
##   box   - the twelve edges of the solid the components span, plus its diagonal.
##   none  - no legs: the claim left to the arrow and the readout.
## `star` is deliberately NOT offered; see the registry note. It differs from
## `both` only by three 6 mm dashed guides, which measured 0.12-0.29% of frame -
## a duplicate tile bought in advance.
@export_enum("both", "chain", "box", "none") var decomposition: String = "both"

const DECOMPOSITIONS: Array[String] = ["both", "chain", "box", "none"]

const CUBE := 0.40

var _last_pos: Vector3
var _last_f: Vector3 = Vector3.INF
var _home: Transform3D
var _home_set: bool = false


func _ready() -> void:
	super()                                  # pickable_prop._ready -> pickable.gd._ready + set_process
	freeze = true
	# WEIGHT, because the rooms that use this cube are about falling.
	#
	# It shipped at gravity_scale 0.0, and the comment gave a good reason: with
	# no gravity a thrown cube flies straight off the way you let it go, and the
	# damping brings it to a stop somewhere you can fetch it. That makes a clean
	# vector probe. It also makes a probe that cannot demonstrate the one thing
	# Vectors_Act5_ForceAsPlace is named for. Throwing a weightless cube into a
	# chasm to find out whether the field will carry it proves nothing: it was
	# never going to drop.
	#
	# So it falls now, and RECOVERS instead of being lost. The old zero gravity
	# was standing in for a way home; this is the way home, said directly.
	# force_field_zone saves and restores gravity_scale on entry and exit, so
	# inside a field the weight is switched off exactly as before.
	gravity_scale = falls
	linear_damp = 0.3                        # drifts to a slow stop so it stays recoverable
	angular_damp = 0.5
	release_mode = 0                         # ReleaseMode.UNFROZEN — become dynamic on release
	_ensure_collision(Vector3(CUBE, CUBE, CUBE))
	_build_body()
	demo_root = Node3D.new(); demo_root.name = "Vec"; add_child(demo_root)
	_last_pos = global_position
	_redraw(_resting_force())


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("falls"): falls = clampf(float(config_data["falls"]), 0.0, 4.0)
	if config_data.has("recover_below_m"):
		recover_below_m = maxf(0.5, float(config_data["recover_below_m"]))
	if config_data.has("seed"): seed = int(config_data["seed"])
	if config_data.has("push"): push = clampf(float(config_data["push"]), 0.0, 1.0)
	if config_data.has("emissive"): emissive = bool(config_data["emissive"])
	# An unknown word is ignored rather than assigned, so a typo falls back to the
	# shipped picture instead of blanking the decomposition. _last_f is only reset
	# when the value actually CHANGED: _redraw short-circuits on an unmoved vector,
	# so without this a config call naming a new decomposition would draw nothing
	# new — and with it, a call naming nothing this artifact owns still rebuilds
	# nothing at all.
	if config_data.has("decomposition"):
		var want: String = str(config_data["decomposition"])
		if DECOMPOSITIONS.has(want) and want != decomposition:
			decomposition = want
			_last_f = Vector3.INF
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
	# WHERE HOME IS, captured on the first frame rather than in _ready. The grid
	# seats an artifact with call_deferred, so at _ready the cube is not yet
	# standing where the map put it, and a home read there would send a fallen
	# cube back to the origin of the world.
	if not _home_set:
		_home = global_transform
		_home_set = true
		_last_pos = global_position
	# Home again. Checked before the velocity is differenced, so the teleport
	# does not read as a colossal one-frame force and draw an arrow to match.
	if not freeze and global_position.y < _home.origin.y - recover_below_m:
		_recover()
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
	match decomposition:
		"chain":
			# the legs walked tip to tail: origin -> x -> xy -> tip, solid this time,
			# so the last leg lands exactly on the resultant's point.
			if absf(f.x) > 0.05: demo_root.add_child(_arrow(Vector3.ZERO, Vector3(f.x, 0, 0), 0.016, _glow_mat(x_color, 1.2)))
			if absf(f.y) > 0.05: demo_root.add_child(_arrow(Vector3(f.x, 0, 0), Vector3(f.x, f.y, 0), 0.016, _glow_mat(y_color, 1.2)))
			if absf(f.z) > 0.05: demo_root.add_child(_arrow(Vector3(f.x, f.y, 0), tip, 0.016, _glow_mat(z_color, 1.2)))
		"box":
			# the twelve edges of the solid the components span; the diagonal is the
			# resultant arrow drawn below, so the box closes on the force itself.
			for e in _box_edges(f):
				demo_root.add_child(_dashed(e[0] as Vector3, e[1] as Vector3, 0.006, dim))
		"none":
			# the claim left to the arrow and the readout
			pass
		_:
			# "both" — the shipped picture, line for line: the dashed staircase AND
			# the three legs leaving the origin.
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


## The twelve edges of the axis-aligned solid spanned by the components, as [a, b]
## pairs. The origin corner and the tip corner are two of the eight, so the box is
## closed on the force it decomposes rather than floating beside it.
func _box_edges(f: Vector3) -> Array:
	var c: Array = [
		Vector3.ZERO, Vector3(f.x, 0, 0), Vector3(0, f.y, 0), Vector3(0, 0, f.z),
		Vector3(f.x, f.y, 0), Vector3(f.x, 0, f.z), Vector3(0, f.y, f.z), f]
	var pairs: Array = [[0, 1], [0, 2], [0, 3], [1, 4], [1, 5], [2, 4],
		[2, 6], [3, 5], [3, 6], [4, 7], [5, 7], [6, 7]]
	var out: Array = []
	for p in pairs:
		out.append([c[int(p[0])], c[int(p[1])]])
	return out


## Put the cube back where it was placed, at rest. Called when it has fallen out
## of the room. Freezing it again is deliberate: it returns in the state it
## shipped in, waiting to be picked up, rather than arriving mid-tumble.
func _recover() -> void:
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	global_transform = _home
	freeze = true
	_last_pos = global_position
	_last_f = Vector3.INF
	_redraw(_resting_force())
