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
@export var crab_scale: float = 0.15
@export var body_colour: Color = Color(0.42, 0.14, 0.20)
@export var eye_colour: Color = Color(1.0, 0.22, 0.16)
@export var detect_m: float = 9.0
@export var chase_speed: float = 0.95
@export var patrol_speed: float = 0.3
@export var turn_speed_deg: float = 150.0

# the gait, in the authored rig's own units — scaled to world in _ready
@export_group("Gait")
@export var step_threshold_local: float = 1.25
@export var step_height_local: float = 0.85
@export var step_duration: float = 0.08
@export var step_overshoot_local: float = 0.55
## POSTURE, exported so a variant can be handed in from outside (2026-08-26,
## Palle: "iterate and improve with multi agent many different versions").
## ride_local is the body height in RIG units; stance is how far out the feet
## plant as a fraction of the authored shoulder ring. Together with the chain
## length (6 bones, 5.00 units) they decide whether the leg bends or reaches
## straight — which is the whole open question.
@export var ride_local: float = -1.2
@export var stance: float = 1.25
## forwarded to the CSG rig BEFORE it builds itself, since its _ready reads its
## own exports once: creature_* and leg_* keys from csg_walker.gd
## THE CHOSEN ANIMAL (2026-08-26, Palle: "all black spider 3 look good! use
## that as a start and deploy it in to the game"). Variant 3 of eight —
## graphite body, brass joints, long fine legs — is the shipped default now.
## ride_local is NEGATIVE on purpose: the rig bakes a 2.2-unit shoulder height
## into its .tscn, so the only route to a low-slung body is to sink the root
## beneath the floor. Nothing is drawn at the root and position.y is re-pinned
## every frame, so it is safe — and it is what puts the knees above the shell.
@export var csg_params: Dictionary = {
	"leg_joint_style": "cylinder",
	"leg_shaft_radius": 0.075,
	"leg_hub_radius": 0.15,
	"leg_foot_radius": 0.115,
	"leg_taper": 0.62,
	"creature_atom_radius": 0.3,
	"creature_bulge_factor": 2.0,
	"creature_atom_count": 9,
	"creature_pack": 0.42,
	"creature_knee_at": 0.3,
	"creature_post_knee_drop": 2.2,
	"creature_initial_lift": 0.95,
	"creature_seed": 7,
	"creature_base_color": Color("#0f0f10"),
	"creature_accent_color": Color("#b78e47"),
}
## ── THE FINISH (2026-08-26, Palle: "make them look artificial very beautiful,
## other dark color, like fetch object") ─────────────────────────────────────
## csg_body_builder hardcodes its materials at metallic 0.15 / roughness 0.6 —
## the numbers of something grown. A manufactured object is the opposite: a
## dark body that is almost a mirror, and joints that are a different metal.
## Applied AFTER the rig has built, over every CSG shape it made, because the
## builder gives no way to hand a material in.
@export var finish_on: bool = true
@export var finish_base: Color = Color(0.062, 0.062, 0.065)     # graphite, all but black
@export var finish_accent: Color = Color(0.72, 0.56, 0.28)      # brass at every joint
@export var finish_metallic: float = 0.94
@export var finish_roughness: float = 0.16
@export var finish_accent_metallic: float = 1.0
@export var finish_accent_roughness: float = 0.12
@export var finish_glow: float = 0.0                             # accent emission

const LEG_COUNT := 4
## the authored shoulder ring: 45/135/225/315 degrees at radius 2.2, body y 2.2
const SHOULDERS: Array = [
	Vector3(1.5556, -2.2, -1.5556),
	Vector3(-1.5556, -2.2, -1.5556),
	Vector3(-1.5556, -2.2, 1.5556),
	Vector3(1.5556, -2.2, 1.5556),
]

var _rig: Node3D = null
## THE RIG'S ROOT IS NOT THE RIG (2026-08-26, found by two independent design
## agents reading the .tscn while I was tuning numbers against it). In
## csg_four_leg_walker.tscn the root CSGFourLegWalker is a bare Node3D and
## EVERYTHING — the script, the four IK chains, the SpringArms and their
## FootTargets — hangs off a "Body" child. Three consequences, all silent:
##   the foot paths resolved against the root and returned null four times, so
##   _update_gait wrote to nothing and every gait number here was inert;
##   csg_params were set() on a scriptless node, so every creature_/leg_ key
##   was dropped without a word (the typed/absent set() this repo has been
##   bitten by before);
##   set_process(false) stopped the root, not the script, so four_leg_critter
##   kept walking on its OWN defaults — a 1.5 METRE step threshold against a
##   57 cm animal, which is exactly why the legs never stepped and the body
##   dragged them straight. THAT was the stilts, not the posture numbers.
var _body: Node3D = null
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
var _floor_y: float = 0.0     # the height the artifact was PLACED at
var _floor_learned: bool = false
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
	_ride = ride_local * crab_scale
	_stance = stance
	_build_rig()
	set_process(true)


## Everything that is DERIVED from crab_scale, in one place so it can be run
## twice. GridInteractablesComponent calls apply_grid_config AFTER the node is
## in the tree, so _ready has already run: a token that set crab_scale changed
## the number and nothing else, and #scale:0.11 shipped an animal of 0.15 with
## the right accent. Measured before the fix: 0.882 of default size where
## 0.733 was asked for.
func _apply_scale() -> void:
	scale = Vector3.ONE * crab_scale
	_step_threshold = step_threshold_local * crab_scale
	_step_height = step_height_local * crab_scale
	_step_overshoot = step_overshoot_local * crab_scale
	_ride = ride_local * crab_scale
	_stance = stance


## Map tokens: `head_crab:0:0#scale:0.18#speed:1.2#detect:12`
func apply_grid_config(config: Dictionary) -> void:
	# A map token tunes the animal:
	#   head_crab:0:0#scale:0.11#speed:1.2#detect:12#accent:7fd8cf
	#
	# THE ACCENT HEX CARRIES NO '#'. That character is the token's own config
	# separator, so a value written as `accent:#7fd8cf` is split BEFORE the
	# parser ever sees it and arrives as two junk keys ("accent:" and "7fd8cf",
	# both true) — the colour is dropped in silence, exactly the failure mode
	# the typed-set() audit found in 54 artifacts. Bare hex is the only form
	# that survives the split, and a leading '#' is accepted anyway for a hand
	# that types one.
	if config.has("scale"):
		crab_scale = clampf(_cfg_num(config["scale"], crab_scale), 0.03, 1.0)
	if config.has("speed"):
		chase_speed = _cfg_num(config["speed"], chase_speed)
	if config.has("detect"):
		detect_m = _cfg_num(config["detect"], detect_m)
	if config.has("patrol"):
		patrol_speed = _cfg_num(config["patrol"], patrol_speed)
	if config.has("glow"):
		finish_glow = _cfg_num(config["glow"], finish_glow)
	if config.has("accent"):
		finish_accent = _cfg_colour(config["accent"], finish_accent)
	# already built? then re-derive, or the token changed a number nobody reads
	if is_inside_tree():
		_apply_scale()
		if _body != null and is_instance_valid(_body):
			_apply_finish()


## a token value is always TEXT, and a valueless key arrives as `true` —
## float("true") is 0.0, which would silently shrink the animal to nothing
func _cfg_num(v: Variant, fallback: float) -> float:
	var s := str(v).strip_edges()
	return float(s) if s.is_valid_float() else fallback


func _cfg_colour(v: Variant, fallback: Color) -> Color:
	var s := str(v).strip_edges()
	if s.begins_with("#"):
		s = s.substr(1)
	if not Color.html_is_valid(s):
		push_warning("head_crab: '%s' is not a colour — accent unchanged" % s)
		return fallback
	return Color.html(s)


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
	# the node that actually carries the script and the legs
	_body = _rig.get_node_or_null("Body") as Node3D
	if _body == null:
		for c in _rig.get_children():
			if c is Node3D and (c as Node).get_script() != null:
				_body = c as Node3D
				break
	if _body == null:
		_body = _rig
	# BEFORE the tree: csg_walker._ready reads its own exports once and builds
	# the body from them, so a param set handed in afterwards shapes nothing
	for k in csg_params:
		_body.set(String(k), csg_params[k])
	add_child(_rig)
	# _ready has run for the rig by now: stop ITS gait, keep its geometry
	_body.set_process(false)
	call_deferred("_quiet_rig")
	for i in range(LEG_COUNT):
		var foot: Node = _body.get_node_or_null("SpringArm3D_%d/FootTarget_%d" % [i, i])
		if foot == null:
			push_warning("head_crab: no FootTarget_%d — the gait has nothing to drive" % i)
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
## Every shape the builder made, re-finished. The base and the accent are told
## apart by the albedo the builder gave them — the accent is whatever is not
## the base colour — so the joint beads stay joints and the shell stays shell.
func _apply_finish() -> void:
	if not finish_on or _rig == null or not is_instance_valid(_rig):
		return
	var was_base: Color = csg_params.get("creature_base_color", Color("#d8a878"))
	var base := StandardMaterial3D.new()
	base.albedo_color = finish_base
	base.metallic = finish_metallic
	base.roughness = finish_roughness
	base.metallic_specular = 0.85
	var accent := StandardMaterial3D.new()
	accent.albedo_color = finish_accent
	accent.metallic = finish_accent_metallic
	accent.roughness = finish_accent_roughness
	accent.metallic_specular = 1.0
	if finish_glow > 0.001:
		accent.emission_enabled = true
		accent.emission = finish_accent
		accent.emission_energy_multiplier = finish_glow
	var n_base := 0
	var n_acc := 0
	for node in _rig.find_children("*", "", true, false):
		var cur: Material = null
		if node is CSGShape3D:
			cur = (node as CSGShape3D).material
		elif node is MeshInstance3D:
			cur = (node as MeshInstance3D).material_override
		else:
			continue
		var is_accent := false
		if cur is StandardMaterial3D:
			var a: Color = (cur as StandardMaterial3D).albedo_color
			# the builder tints accents away from the base; anything that is not
			# the base colour is a joint, a bead or a mark
			is_accent = (absf(a.r - was_base.r) + absf(a.g - was_base.g) + absf(a.b - was_base.b)) > 0.12
		var m: Material = accent if is_accent else base
		if node is CSGShape3D:
			(node as CSGShape3D).material = m
		else:
			(node as MeshInstance3D).material_override = m
		if is_accent:
			n_acc += 1
		else:
			n_base += 1
	print("[head_crab] finish: %d body shape(s), %d joint(s)" % [n_base, n_acc])


func _quiet_rig() -> void:
	if _rig == null or not is_instance_valid(_rig):
		return
	_rig.set_process(false)
	_rig.set_physics_process(false)
	if _body != null and is_instance_valid(_body):
		_body.set_process(false)
		_body.set_physics_process(false)
	_apply_finish()
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
	h.y = _ground_at(h)
	return h


## THE FLOOR IS NOT ALWAYS AT ZERO. Every plant used to be written to y = 0.0
## absolute, which is only correct on a map whose floor happens to sit there.
## Both arena crabs stand on structure cells of height 1 — seated at 0.5 m by
## GridCommon.surface_world_y — so their feet planted half a metre THROUGH the
## deck they were placed on. Four SpringArm3D probes hang under the body,
## unread, and this is the two-line version of what they were for: cast down,
## take the hit, fall back to the height the artifact was placed at.
func _ground_at(p: Vector3) -> float:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space != null:
		var from := Vector3(p.x, _floor_y + 1.2, p.z)
		var to := Vector3(p.x, _floor_y - 3.0, p.z)
		var q := PhysicsRayQueryParameters3D.create(from, to)
		q.collision_mask = 1
		var hit: Dictionary = space.intersect_ray(q)
		if not hit.is_empty():
			return float((hit["position"] as Vector3).y)
	return _floor_y


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
	# THE FLOOR IS LEARNED ON FRAME ONE, NOT IN _ready. Artifacts are seated on
	# the floor surface by the grid AFTER instantiation (GridCommon.surface_world_y),
	# so a height read in _ready is the height before placement — zero.
	if not _floor_learned:
		_floor_learned = true
		_floor_y = global_position.y
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
	position.y = _floor_y + _ride
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
				tgt.y = _ground_at(tgt)
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
