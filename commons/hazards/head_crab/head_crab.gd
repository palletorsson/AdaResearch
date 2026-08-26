extends MeshInstance3D
# NO class_name — preloaded by path (the loader-thread class_name race).

# ── THE HEAD CRAB (2026-08-26, Palle: "There is already a walking leg critter
# octapod other numbers of legs that can walk procedurally. use that the make
# the small head crab") ──────────────────────────────────────────────────────
#
# The octapod has eight FABRIK legs and NO GAIT — its own `_update_legs()` is a
# `pass`, so its feet are SpringArm markers that slide with the body while the
# solver bends the legs to reach them. It skates.
#
# The four-leg critter is the opposite: `four_leg_critter.gd:137 _update_gait`
# is the only true plant-and-step locomotion in this corpus. A foot PLANTS in
# world space and stays planted while the body walks away from it; when it is
# stretched past `step_threshold` it lifts, arcs over a parabola and re-plants
# ahead of its home. One leg at a time. That gait is the thing worth keeping,
# and it is what this crab walks on — the same rig scene, the same arithmetic.
#
# Two things change. It is SMALL: the authored critter is 4.4 m across the
# shoulders, and a head crab is a thing that fits on a face, so the whole rig
# is scaled and every world-space gait number is scaled with it — the gait
# constants are distances, not ratios, and leaving them alone would give a
# 40 cm animal a 1.5 m stride. And it is STEERED BY HUNGER rather than by the
# keyboard: the leg critters read Input.get_vector("move_left", ...) — the
# PLAYER's own WASD actions — so placed in a map they walk off the visitor's
# movement keys. This one looks for the visitor instead.

## THE HEAD CRAB ALREADY EXISTS (2026-08-26, Palle: "there are better
## versions"). csg_walker.gd subclasses four_leg_critter, hides its boxy body
## and builds a CSG creature through CSGBodyBuilder — and its creature_form
## DEFAULTS to "headcrab", with the leg geometry bone-skinned to the FABRIK
## chain so body and gait share one skeleton. Hand-building a dome on the bare
## rig was rebuilding what the repo had already made better.
const RIG := "res://commons/hazards/octapod_crawler/csg_four_leg_walker.tscn"

## the authored rig is 4.4 m across; 0.13 puts the crab at ~57 cm
@export var crab_scale: float = 0.13
@export var body_colour: Color = Color(0.42, 0.14, 0.20)
@export var eye_colour: Color = Color(1.0, 0.22, 0.16)
@export var detect_m: float = 9.0
@export var chase_speed: float = 0.85
@export var patrol_speed: float = 0.3
@export var turn_speed_deg: float = 150.0

# the gait, in the authored rig's own units — scaled to world in _ready
@export_group("Gait")
@export var step_threshold_local: float = 2.2
@export var step_height_local: float = 1.0
@export var step_duration: float = 0.15
@export var step_overshoot_local: float = 0.5

const LEG_COUNT := 4
## the authored shoulder ring: 45/135/225/315 degrees at radius 2.2, body y 2.2
const SHOULDERS: Array = [
	Vector3(1.5556, -2.2, -1.5556),
	Vector3(-1.5556, -2.2, -1.5556),
	Vector3(-1.5556, -2.2, 1.5556),
	Vector3(1.5556, -2.2, 1.5556),
]

var _rig: Node3D = null
var _feet: Array = []
var _planted: Array = []
var _stepping: Array = []
var _from: Array = []
var _to: Array = []
var _t: Array = []
var _step_threshold: float = 0.2
var _step_height: float = 0.13
var _step_overshoot: float = 0.07
var _target: Node3D = null
var _look_t: float = 0.0
var _patrol_angle: float = 0.0
var _patrol_t: float = 0.0
var _rng := RandomNumberGenerator.new()
var _ride: float = 0.29   # body height above the floor, set from crab_scale
var _stance: float = 1.0  # how far out the feet plant, as a fraction of the rig's


func _ready() -> void:
	_rng.randomize()
	# THE WHOLE ANIMAL SCALES, NOT THE RIG. Scaling the rig alone put its
	# SpringArms and FootTargets in a shrunken frame while the gait drove them
	# by WORLD position: the solver chased targets it read as fifteen units
	# away and the legs came out as metre-long spikes. Scaling the ROOT keeps
	# one frame — global_transform carries the scale into every home, and the
	# feet, the carapace and the bones all shrink together.
	scale = Vector3.ONE * crab_scale
	_patrol_angle = _rng.randf_range(0.0, TAU)
	# THE GAIT NUMBERS ARE DISTANCES. They are measured in world space by
	# distance_to, so they must shrink with the animal or a 57 cm crab takes a
	# metre-and-a-half stride and never plants a foot.
	_step_threshold = step_threshold_local * crab_scale
	_step_height = step_height_local * crab_scale
	_step_overshoot = step_overshoot_local * crab_scale
	# THE BODY RIDES AT SHOULDER HEIGHT. The rig is authored with its shoulders
	# 2.2 units above the feet; placed with its origin ON the floor, the legs
	# have to reach DOWN to a ground they are already standing on, so FABRIK
	# extends them straight and the crab drags four spikes behind it. That is
	# what the first walk frames photographed. The gait's own flat-ground
	# assumption (homes.y = 0, four_leg_critter.gd:142) makes the ride height
	# a constant, not a raycast.
	# 2.2 is the shoulder height of the AUTHORED rig, and at that ride the legs
	# reach their feet dead straight — the crab stands on four rigid stilts.
	# A crab crouches: the body comes down so the chain has to BEND, which is
	# what makes a joint read as a joint. Measured by eye against the stilts.
	_ride = 1.35 * crab_scale
	# and the stance draws in — a wide sprawl at this scale reads as a spider
	_stance = 0.62
	_build_rig()
	set_process(true)


func _build_rig() -> void:
	if not ResourceLoader.exists(RIG):
		push_warning("head_crab: the four-leg rig is missing — no legs")
		return
	var ps: PackedScene = load(RIG) as PackedScene
	_rig = ps.instantiate() as Node3D
	if _rig == null:
		return
	# KEEP the rig's own script: its _ready skins the four leg chains, and
	# hand-rolling that skin produced folded garbage. Only its _process is
	# unwanted — that is the one that reads the player's WASD — so it is
	# switched off the frame after it has built itself.
	_rig.name = "Rig"
	add_child(_rig)
	_rig.set_process(false)
	call_deferred("_quiet_rig")
	for i in range(LEG_COUNT):
		var foot: Node = _rig.get_node_or_null("SpringArm3D_%d/FootTarget_%d" % [i, i])
		_feet.append(foot)
	_planted.resize(LEG_COUNT)
	_stepping.resize(LEG_COUNT)
	_from.resize(LEG_COUNT)
	_to.resize(LEG_COUNT)
	_t.resize(LEG_COUNT)
	for i in range(LEG_COUNT):
		_stepping[i] = false
		_from[i] = Vector3.ZERO
		_to[i] = Vector3.ZERO
		_t[i] = 0.0
		_planted[i] = _home(i)


## A tapered tube down the leg's bones, skinned so FABRIK bends it. The rig
## ships bare skeletons; four_leg_critter._add_skinned_mesh does the same job
## for the big critter.
## The rig has built itself by now: stop it walking, take its body box (this
## crab has a carapace instead) and put out the orange debug foot markers.
func _quiet_rig() -> void:
	if _rig == null or not is_instance_valid(_rig):
		return
	_rig.set_process(false)
	_rig.set_physics_process(false)
	# the rig hangs an orange debug sphere on every foot marker; find them by
	# their PARENT rather than by a path, so a renamed rig node cannot leave
	# four glowing dots on the floor
	for m in _rig.find_children("*", "Marker3D", true, false):
		for c in (m as Node).get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false


func _skin_leg_unused(sk: Skeleton3D, mat: Material, idx: int) -> void:
	var n: int = sk.get_bone_count()
	if n < 2:
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 5
	for b in range(n - 1):
		var a: Vector3 = sk.get_bone_global_rest(b).origin
		var c: Vector3 = sk.get_bone_global_rest(b + 1).origin
		var r0: float = lerpf(0.18, 0.06, float(b) / float(maxi(1, n - 1)))
		var r1: float = lerpf(0.18, 0.06, float(b + 1) / float(maxi(1, n - 1)))
		var d: Vector3 = c - a
		if d.length() < 0.0001:
			continue
		var yv: Vector3 = d.normalized()
		var ref: Vector3 = Vector3.UP if absf(yv.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
		var xv: Vector3 = ref.cross(yv).normalized()
		var zv: Vector3 = yv.cross(xv).normalized()
		for s in range(sides):
			var a0: float = TAU * float(s) / float(sides)
			var a1: float = TAU * float(s + 1) / float(sides)
			var p00: Vector3 = a + (xv * cos(a0) + zv * sin(a0)) * r0
			var p01: Vector3 = a + (xv * cos(a1) + zv * sin(a1)) * r0
			var p10: Vector3 = c + (xv * cos(a0) + zv * sin(a0)) * r1
			var p11: Vector3 = c + (xv * cos(a1) + zv * sin(a1)) * r1
			for tri in [[p00, p10, p11], [p00, p11, p01]]:
				for v in tri:
					st.set_bones([b, 0, 0, 0])
					st.set_weights([1.0, 0.0, 0.0, 0.0])
					st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.name = "LegSkin_%d" % idx
	mi.mesh = st.commit()
	mi.material_override = mat
	var skin := Skin.new()
	for b2 in range(n):
		skin.add_bind(b2, sk.get_bone_global_rest(b2).affine_inverse())
	sk.add_child(mi)
	mi.skin = skin
	mi.skeleton = mi.get_path_to(sk)


## The carapace: a low dome with a pair of lit eyes at the front. A head crab
## reads as a body that is mostly shell, close to the ground.
func _build_carapace() -> void:
	var dome := MeshInstance3D.new()
	dome.name = "Carapace"
	var sm := SphereMesh.new()
	sm.radius = 1.75
	sm.height = 2.35
	sm.radial_segments = 20
	sm.rings = 10
	dome.mesh = sm
	var m := StandardMaterial3D.new()
	m.albedo_color = body_colour
	m.roughness = 0.42
	m.metallic = 0.1
	dome.material_override = m
	dome.scale = Vector3(1.0, 0.62, 1.15)
	dome.position = Vector3(0, 2.30, 0)
	add_child(dome)
	var em := StandardMaterial3D.new()
	em.albedo_color = eye_colour
	em.emission_enabled = true
	em.emission = eye_colour
	em.emission_energy_multiplier = 2.0
	for sx in [-1.0, 1.0]:
		var eye := MeshInstance3D.new()
		var es := SphereMesh.new()
		es.radius = 0.28
		es.height = 0.56
		eye.mesh = es
		eye.material_override = em
		eye.position = Vector3(0.42 * sx, 2.42, -1.62)
		add_child(eye)


func _home(i: int) -> Vector3:
	var sh: Vector3 = SHOULDERS[i] as Vector3
	var h: Vector3 = global_transform * Vector3(sh.x * _stance, sh.y, sh.z * _stance)
	h.y = 0.0
	return h


## The visitor, on whichever lane is running. The museum's walker is in group
## em_walker ONLY and is deliberately not a player_body, so it is named here.
func _find_target() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for g in ["player", "player_body", "em_walker"]:
		var n: Node = tree.get_first_node_in_group(g)
		if n is Node3D:
			_target = n as Node3D
			return
	_target = null


func _process(delta: float) -> void:
	_look_t += delta
	if _look_t > 0.5:
		_look_t = 0.0
		if _target == null or not is_instance_valid(_target):
			_find_target()
	# ── steer: toward the visitor if it is near, otherwise wander ──────────
	var want_yaw: float = rotation.y
	var speed: float = patrol_speed
	if _target != null and is_instance_valid(_target):
		var to: Vector3 = _target.global_position - global_position
		to.y = 0.0
		if to.length() < detect_m and to.length() > 0.35:
			want_yaw = atan2(-to.x, -to.z)
			speed = chase_speed
		elif to.length() <= 0.35:
			speed = 0.0
	if is_equal_approx(speed, patrol_speed):
		_patrol_t += delta
		if _patrol_t >= 3.0:
			_patrol_t = 0.0
			_patrol_angle += _rng.randf_range(-PI * 0.5, PI * 0.5)
		want_yaw = _patrol_angle
	rotation.y = lerp_angle(rotation.y, want_yaw, minf(1.0, deg_to_rad(turn_speed_deg) * delta))
	if speed > 0.0:
		# NORMALIZE. basis carries the root's 0.13 scale, so -basis.z is 0.13
		# long and the crab walked at an eighth of its speed — measured: 0.79 m
		# where it should have covered four.
		position += -basis.z.normalized() * speed * delta
	position.y = _ride
	_update_gait(delta)


## PLANT AND STEP — four_leg_critter.gd:137, faithfully. A foot holds its world
## position while the body walks off it; the one that is furthest past the
## threshold lifts, arcs, and re-plants ahead of its home. One at a time, which
## is what makes it read as walking rather than sliding.
func _update_gait(delta: float) -> void:
	if _feet.size() < LEG_COUNT:
		return
	var homes: Array = []
	for i in range(LEG_COUNT):
		homes.append(_home(i))
	for i in range(LEG_COUNT):
		if _stepping[i]:
			_t[i] += delta / maxf(0.01, step_duration)
			if _t[i] >= 1.0:
				_t[i] = 1.0
				_stepping[i] = false
				_planted[i] = _to[i]
	var any := false
	for i in range(LEG_COUNT):
		if _stepping[i]:
			any = true
			break
	if not any:
		# DIAGONAL PAIRS — the trot. four_leg_critter steps ONE leg at a time,
		# and at this size that is arithmetically impossible: a cycle of four
		# single steps takes 0.88 s, in which a hunting crab covers 1.3 m, six
		# times its own stride. The legs can never catch up, and the first walk
		# frames photographed exactly that — four spikes dragged behind the
		# body. The file's OWN identity block already says what the answer is:
		#   "quadruped_gait(t) = diagonal_pairs(FL+BR, FR+BL)"
		#   "diagonal pairing discovered not designed"
		# The claim was in the header and never in the code. Opposite corners
		# swing together, which halves the cycle and is what a trotting animal
		# actually does.
		var pairs: Array = [[0, 2], [1, 3]]
		var best_pair: Array = []
		var best_d := 0.0
		for pr in pairs:
			var d: float = maxf((_planted[pr[0]] as Vector3).distance_to(homes[pr[0]]),
				(_planted[pr[1]] as Vector3).distance_to(homes[pr[1]]))
			if d > _step_threshold and d > best_d:
				best_d = d
				best_pair = pr
		if not best_pair.is_empty():
			var fwd: Vector3 = -global_transform.basis.z.normalized()
			for li in best_pair:
				_stepping[li] = true
				_t[li] = 0.0
				_from[li] = _planted[li]
				var tgt: Vector3 = (homes[li] as Vector3) + fwd * _step_overshoot
				tgt.y = 0.0
				_to[li] = tgt
	for i in range(LEG_COUNT):
		var foot: Node = _feet[i]
		if foot == null or not is_instance_valid(foot):
			continue
		var pos: Vector3
		if _stepping[i]:
			var t: float = _t[i]
			pos = (_from[i] as Vector3).lerp(_to[i], t * t * (3.0 - 2.0 * t))
			pos.y += _step_height * (4.0 * t * (1.0 - t))   # the parabola
		else:
			pos = _planted[i]
		(foot as Node3D).global_position = pos
