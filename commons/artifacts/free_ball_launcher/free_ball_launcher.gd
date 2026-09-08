extends Node3D
class_name FreeBallLauncher

# @identity
# essence: a mouth at the side of a room that throws a heavy ball across it on its own clock, for ever, whether anybody is standing there or not
# desire: to put one unaimed thing in a room made entirely of aimed ones, so the visitor meets a hazard that was never waiting for them
# critical_parameter: rise — how much of the throw goes upward, and therefore whether the ball crosses the room or skids into the near floor
# triggers: a seeded interval and nothing else; never a body, never a distance, never a glance
# emerges: the pit stops being a thing you avoid and becomes a thing you can be put into by something that has no opinion about you
# needs: clear floor in front of the mouth — about five metres to land and more to roll [external]
# relationships: the fourth hazard in a room of three — pusher, sweeper and grower are authored motion on rails, this is the same motion let go of
# truth: a hazard that aims at you has already agreed that you are the point
#
## 2026-09-08, Palle: "in Trans_Pit add shorting free ball from the sides."
##
## FREE MEANS NOBODY AIMED IT.
##
## The project already owns the other artifact. cube_projectile_spawner is described in its own
## registry line as a thing that "spawns projectile cubes, leads the target, and fires
## warning effects before launch", and every clause of that is about you. It hunts for
## a player node at boot, reads that player's velocity, multiplies by the flight time
## and throws at where you are going to be. It is a room paying attention.
##
## This one is not. It fires into an empty hall exactly the way it fires into a full
## one. It never leads, never homes, never corrects, and once the ball is out of the
## mouth the launcher has no further opinion about it at all. There is no line in this
## file that reads a visitor's position, and if a later hand finds itself adding one to
## work out a bearing, it has rebuilt cube_spawner and should say so out loud.
##
## It stands beside a pusher block rather than instead of one because it is the same
## operation LET GO OF. The pusher block translates on rails — so far out, so far back,
## for ever — and that translation is authored, which means it can be learned, timed and
## walked past. Here the identical translation is handed to gravity at the muzzle and it
## is never the same twice: the ball arcs, lands, rolls, comes off a wall and finishes
## somewhere nobody chose, sometimes in the pit and sometimes under your feet. It is
## translation you cannot rehearse against, next to translation you can.
##
## IT SHOVES AND DOES NOT WOUND. Trans_Pit's blurb is explicit — "the pit below is the
## same in every case, only the geometry of your removal changes" — so the killing is
## the floor's job and this thing only moves you. It carries no damage, no DangerZone
## and no health call of any kind.
##
## WHICH WAY IT POINTS IS THE WHOLE PLACEMENT, AND IT IS THE LIKELIEST WAY THIS ENDS UP
## DOING NOTHING. It fires along its own local -Z, so a map aims it with the token's
## rotation the way every other artifact in the grid is aimed: `free_ball_launcher:90`
## turns the mouth a quarter turn. A launcher facing a wall a metre off fires perfectly,
## on time, for ever, and photographs as a handsome piece of furniture. That exact
## failure is what the `silent` signal exists to say out loud, because nothing else in
## the chain will notice it.
##
## A RIGIDBODY3D DOES NOT MOVE A CHARACTERBODY3D, AND THAT IS THE FACT THAT COST THE
## MOST. All three visitors are CharacterBody3D — the xr-tools PlayerBody, the desktop
## grid player and the endless museum's Walker — and a character is immovable as far as
## the rigid-body solver is concerned. A twelve-kilogram ball at seven metres a second
## hits one and bounces off it, cleanly, with the visitor standing exactly where they
## were: the shove that the whole artifact is for simply does not happen, and it does
## not happen quietly, it happens with a convincing thud. So each ball carries a small
## Area3D of its own, and when that area reports a visitor the code adds shove_mps to
## that body's `velocity` by hand. The bounce is left in because it looks right; the
## Area3D is what actually does the work.
##
## AND THE AREA HAS TO MASK TWO LAYERS, NOT ONE. The museum's Walker is a bare
## CharacterBody3D on collision layer 1, in group `em_walker` and nothing else — no
## XROrigin3D above it, not on layer 20, not in any grid player group. An Area3D masking
## the player layer alone never overlaps it, with no error, no refusal and no log line,
## which is why force_pad does nothing in the museum. This masks 1 | 524288 so all three
## visitors are shoved by the same ball.
##
## The price of layer 1 is that the area also sees the building, and this launcher's own
## post, which is a StaticBody3D and therefore on layer 1 by default. So a body counts
## only if it is a VISITOR: one of the four visitor groups, or an XROrigin3D somewhere
## above it, and never one of our own nodes. Never "any CharacterBody3D" — that test
## passes for hazard_creature_base, and in the museum it would mean this thing spends
## the day knocking the museum's own silhouettes around the hall.
##
## THE BALLS ARE NOT OUR CHILDREN, AND THAT IS DELIBERATE. endless_museum._extent_of
## merges the AABB of every MeshInstance3D and every CollisionShape3D in an artifact's
## subtree and seals the result as solid floor. A ball in flight halfway across the room
## is a MeshInstance3D in that subtree, so a launcher that parented its own ammunition
## would report a footprint the size of the hall and the walk map would seal it. The
## pool therefore lives in a sibling node, and every collider in this file — the post's
## and each ball's sensing volume — is hung on its body through create_shape_owner
## rather than as a CollisionShape3D child, the way carve_grid and approach_wall do it,
## so the only thing _extent_of can find here is the muzzle it should be measuring.
##
## THE BALL IS WIDER THAN THE BORE. It is a mouth, not a magazine; the launcher is not
## a machine that could be storing what it produces and it does not pretend to be one.

const PLAYER_LAYER := 524288          # physics layer 20 — the xr-tools PlayerBody
const WALKER_LAYER := 1               # physics layer 1  — museum Walker, desktop player, static world
const DYNAMIC_LAYER := 2              # physics layer 2  — "Dynamic World": where the balls themselves live

## How far in front of the mouth a ball is placed before it is let go, on top of its own
## radius. Small enough to read as leaving the mouth, large enough that it never begins
## the frame inside the post it was fired from.
const MUZZLE_CLEAR := 0.10
## The interval is jittered by this fraction either way. Small on purpose: the point is
## that the clock is indifferent, not that it is chaotic, and a visitor should still be
## able to feel a rhythm they cannot quite count on.
const INTERVAL_JITTER := 0.22
## A ball that never got this far from the mouth went nowhere at all.
const STUCK_M := 0.60
## When a ball is asked how far it has got. Early enough that a wrongly-turned token
## is reported in the first few seconds of the hall rather than after a minute of
## nine-second lifetimes.
const STUCK_AT_S := 0.5
## How many shots have to go nowhere before the artifact says so.
const STUCK_SHOTS := 3
## Seconds of standing there having fired nothing before that is reported as a fault.
const SILENT_GRACE_S := 8.0
## Ceiling on the pool. Forty rigid bodies is not a hazard, it is a frame-rate bug.
const MAX_POOL := 12
## Each ball is built with exactly one shape owner, so it is the one with id 0. Named
## rather than typed as a bare zero in three places.
const BALL_OWNER := 0

## Seconds between shots, before jitter. The clock is the artifact: it does not speed up
## when you arrive and it does not stop when you leave.
@export var interval_s: float = 2.6
## How hard the ball leaves the mouth, metres per second. At the default seven it lands
## about four metres out from chest height and keeps going.
@export var speed_mps: float = 7.0
## The ball's radius in metres. At 0.34 it is a thing you see coming and cannot step over.
@export var ball_r: float = 0.34
## Kilograms. Heavy enough that it does not skitter off the first wall it meets, and it
## is the number that decides how a stack of them behaves in the corner they collect in.
@export var ball_mass: float = 12.0
## How much of the throw is upward, as a fraction of the forward aim. Zero is a flat shot
## that hits the floor two metres out; 0.18 is about ten degrees of elevation, which is
## what carries the ball across a room rather than into it.
@export var rise: float = 0.18
## Metres per second added to a visitor's own velocity when a ball reaches them, along the
## ball's line of travel. Six is a stumble of a metre or so, which over a pit is the
## whole hazard and on solid floor is a shock and nothing worse.
@export var shove_mps: float = 6.0
## Seconds a ball is allowed to exist before it is taken back, however far it got. This is
## what stops a hall slowly filling with balls that came to rest in a corner.
@export var life_s: float = 9.0
## World height, metres, below which a ball is considered to have gone into the pit and is
## taken back early. Well under any floor a map is likely to build.
@export var kill_y: float = -12.0
## How many balls may be in the air at once. The pool is exactly this size and it is
## reused round-robin, so this is also the total number of rigid bodies this artifact ever
## creates.
@export var max_live: int = 4
## The seed for the jitter on interval and direction. Fixed by default, so five captures of
## this artifact are five pictures of one object rather than five different ones.
@export var seed: int = 7
## How far off its own axis a shot may wander, degrees, total cone. This is the only
## variation there is, and it is not a bearing — it is drawn before anybody is looked at,
## because nobody is ever looked at.
@export var spread_deg: float = 6.0
## How high the mouth stands above the cell it is placed on, metres. Chest height by
## default, so the throw starts above the floor and has somewhere to fall from.
@export var mount_m: float = 1.12
@export var muzzle_color: Color = Color(0.95, 0.42, 0.16)

## A ball has just left the mouth. The index is its pool slot, so a probe can tell reuse
## from a fresh shot.
signal fired(index: int)
## A ball reached a visitor and their velocity was changed. Sent per contact, not per
## frame — the area reports an entry, and a ball resting against somebody is not an event.
signal struck(body: Node3D)
## THE FAILURE THIS ARTIFACT IS MOST LIKELY TO HAVE, said out loud once.
##
## A launcher pointed into a wall a metre away fires on time, for ever, and does nothing;
## so does one whose rotation was never set and which is throwing into the corner it
## stands in. Both look exactly like a launcher that is working, from every angle and in
## every still. So the artifact watches two things about itself: whether anything has ever
## left the mouth at all, and whether the shots that did leave all died within
## STUCK_M of it. Either one is reported once and then never again.
signal silent(why: String)

var _rng := RandomNumberGenerator.new()
var _balls_root: Node3D = null
var _balls: Array[RigidBody3D] = []
var _areas: Array[Area3D] = []
## Per pool slot, all sized to the pool and never resized during play, so the per-frame
## sweep over them allocates nothing.
var _age := PackedFloat32Array()
var _live := PackedByteArray()
var _travel := PackedVector3Array()   # unit direction each ball was let go along
var _origin := PackedVector3Array()   # where it was let go, for measuring how far it got

var _pool_n := 0
var _next := 0
var _cool := 0.0
var _shots := 0
var _idle_s := 0.0
var _short_deaths := 0
var _reach_best := 0.0
var _last_travel := Vector3.ZERO
var _silent_said := false
var _bore := 0.0
var _muzzle_z := 0.0


func _ready() -> void:
	_build()


## AN UNLISTED NUMERIC KEY DOES NOT ARRIVE AS NOTHING. IT ARRIVES AS `true`.
##
## GridInteractablesComponent._parse_config_token (:1680) reads `#key:value` as the
## TUTORIAL SHORTHAND — an id and a rotation — whenever the key is not in its
## CONFIG_PARAM_NAMES list AND the value parses as a float. The artifact is then
## handed `{key: true}` and the node is separately re-aimed. `float(true)` is 1.0
## and `int(true)` is 1, so the export is not left at its default: it is set to one.
## `#kill_y:-30` becomes kill_y = 1.0 and every ball is retired the moment it falls
## below head height, on the artifact whose whole point is a ball crossing a room.
## And the yaw is rewritten, on the artifact whose whole placement is its yaw.
##
## MEASURED against the live list rather than assumed, because the first version of
## this paragraph named the wrong keys: `interval`, `speed` and `color` ARE listed
## and work as numbers. `ball_r`, `mass`, `rise`, `shove`, `life`, `kill_y`,
## `max_live`, `seed`, `spread` and `mount` are not.
##
## So every numeric read goes through _num/_int, which refuse a bool and say so —
## a silent wrong number becomes a line naming the spellings that work. And the
## knobs a MAP is expected to turn are WORDS, which no engine can mistake for a
## rotation: `#rate:brisk`, `#throw:lob`. Adding the names to CONFIG_PARAM_NAMES
## would fix it properly for both engines, and is a grid change with its own
## negative test — deliberately not folded into this one.
## A number, or the current value and a complaint. See the paragraph above: an
## unlisted key arrives as `true`, and taking float(true) would set the export to 1.
func _num(cfg: Dictionary, key: String, cur: float) -> float:
	if not cfg.has(key):
		return cur
	var v: Variant = cfg[key]
	if typeof(v) == TYPE_BOOL:
		push_warning(("free_ball_launcher: #%s:<number> does not reach this artifact from a map"
			+ " token — the key is not in CONFIG_PARAM_NAMES, so the grid read it as a rotation"
			+ " and handed me `true`. Use #rate: or #throw:, which are words.") % key)
		return cur
	return float(v)


func _int(cfg: Dictionary, key: String, cur: int) -> int:
	if not cfg.has(key):
		return cur
	if typeof(cfg[key]) == TYPE_BOOL:
		push_warning("free_ball_launcher: #%s:<number> is not a key a map token can carry — see _num" % key)
		return cur
	return int(cfg[key])


func apply_grid_config(config_data: Dictionary) -> void:
	# THE WORD-VALUED KNOBS, safe from a map token in either engine.
	if config_data.has("rate"):
		match String(config_data["rate"]).to_lower():
			"idle": interval_s = 6.0
			"slow": interval_s = 4.0
			"steady": interval_s = 2.6
			"brisk": interval_s = 1.7
			"relentless": interval_s = 1.0
			_: push_warning("free_ball_launcher: #rate:%s is not a word this reads — idle|slow|steady|brisk|relentless"
				% String(config_data["rate"]))
	if config_data.has("throw"):
		match String(config_data["throw"]).to_lower():
			# flat skids into the near floor and rolls; lob clears a pit and lands
			# in the far half. The word is the arc, because the number is a ratio
			# nobody can picture.
			"flat": rise = 0.05
			"level": rise = 0.18
			"lob": rise = 0.42
			"high": rise = 0.70
			_: push_warning("free_ball_launcher: #throw:%s is not a word this reads — flat|level|lob|high"
				% String(config_data["throw"]))
	interval_s = _num(config_data, "interval", interval_s)
	speed_mps = _num(config_data, "speed", speed_mps)
	ball_r = _num(config_data, "ball_r", ball_r)
	ball_mass = _num(config_data, "mass", ball_mass)
	rise = _num(config_data, "rise", rise)
	shove_mps = _num(config_data, "shove", shove_mps)
	life_s = _num(config_data, "life", life_s)
	kill_y = _num(config_data, "kill_y", kill_y)
	max_live = _int(config_data, "max_live", max_live)
	seed = _int(config_data, "seed", seed)
	spread_deg = _num(config_data, "spread", spread_deg)
	mount_m = _num(config_data, "mount", mount_m)
	if config_data.has("color"):
		var c: Variant = config_data["color"]
		if c is Color:
			muzzle_color = c
		elif typeof(c) == TYPE_STRING and Color.html_is_valid(str(c)):
			muzzle_color = Color.html(str(c))
	if is_inside_tree():
		_build()


## The muzzle only. The pool is deliberately not built here — see _ensure_pool.
func _build() -> void:
	_drop_pool()
	for c in get_children():
		c.queue_free()

	interval_s = maxf(interval_s, 0.15)
	ball_r = clampf(ball_r, 0.05, 1.2)
	ball_mass = maxf(ball_mass, 0.1)
	life_s = maxf(life_s, 0.5)
	mount_m = clampf(mount_m, 0.1, 4.0)

	_rng.seed = seed
	_cool = _next_interval()
	_shots = 0
	_idle_s = 0.0
	_short_deaths = 0
	_reach_best = 0.0
	_last_travel = Vector3.ZERO
	_silent_said = false

	# The bore is not the ball. Kept under a quarter metre so the whole muzzle stays
	# inside its own cell — a hazard that eats the floor around it is a different
	# artifact — and the ball leaves it looking like more than went in, which is the
	# honest reading of a thing nobody loaded.
	_bore = clampf(ball_r * 0.62, 0.07, 0.21)
	var collar_l: float = 0.11
	var barrel_l: float = 0.30
	var lip_l: float = 0.06
	# The front face of the lip, which is where the mouth actually ends. Everything that
	# leaves does so from here, so it is derived from the same three lengths the meshes are
	# built with rather than typed twice.
	_muzzle_z = -(collar_l + barrel_l + lip_l)

	var steel := StandardMaterial3D.new()
	steel.albedo_color = Color(0.30, 0.31, 0.34)
	steel.metallic = 0.65
	steel.roughness = 0.42

	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.05, 0.05, 0.06)
	dark.roughness = 0.95
	dark.metallic = 0.0

	var lit := StandardMaterial3D.new()
	lit.albedo_color = muzzle_color
	lit.emission_enabled = true
	lit.emission = muzzle_color
	lit.emission_energy_multiplier = 2.1
	lit.roughness = 0.35

	# The post. Slim, because the artifact is the mouth and not the furniture holding it.
	_box(Vector3(0.30, 0.05, 0.30), Vector3(0.0, 0.025, 0.0), steel)
	_box(Vector3(0.13, mount_m, 0.13), Vector3(0.0, mount_m * 0.5, 0.0), steel)

	# The barrel, lying along local -Z. A Godot cylinder stands along +Y, and turning it
	# -90 degrees about X carries +Y onto -Z, which is the direction this thing fires.
	var lay := Vector3(deg_to_rad(-90.0), 0.0, 0.0)
	_cyl(_bore + 0.075, _bore + 0.075, collar_l, Vector3(0.0, mount_m, -collar_l * 0.5), lay, steel)
	_cyl(_bore + 0.035, _bore + 0.035, barrel_l, Vector3(0.0, mount_m, -collar_l - barrel_l * 0.5), lay, steel)

	# THE MOUTH, and the one place the geometry had to be argued rather than typed. The
	# only thing a visitor must be able to read about this artifact from the far side of a
	# room is which way it faces, and the obvious build — a lit cylinder capping the barrel
	# — is a SOLID DISC. It would enclose the throat completely and photograph as an orange
	# coin: a mouth with nothing behind it, from every angle, forever. So the rim is a
	# torus, which has a hole in it by construction, and the black throat sits a centimetre
	# and a half proud of the barrel's own front face so it is in front of the steel rather
	# than behind it. Ring of light, hole of dark, and the facing reads at ten metres.
	_torus(_bore, _bore + 0.055, Vector3(0.0, mount_m, _muzzle_z + lip_l * 0.5), lay, lit)
	_cyl(_bore, _bore, 0.02, Vector3(0.0, mount_m, -collar_l - barrel_l - 0.015), lay, dark)
	# A stripe down the top of the barrel, so the facing survives being seen from above
	# or in a still where the mouth is edge-on.
	_box(Vector3(0.028, 0.016, barrel_l + lip_l), Vector3(0.0, mount_m + _bore + 0.05, -collar_l - (barrel_l + lip_l) * 0.5), lit)

	# Solid, so a visitor cannot walk through a steel post, and so a ball that comes back
	# off a wall bounces off its own launcher instead of resting inside it. Layer 1 is
	# what all three visitors actually collide against; it masks nothing, because a post
	# has no business detecting anything.
	var post := StaticBody3D.new()
	post.name = "Post"
	post.collision_layer = WALKER_LAYER
	post.collision_mask = 0
	add_child(post)
	_own_box(post, Vector3(0.15, mount_m, 0.15), Vector3(0.0, mount_m * 0.5, 0.0))
	var head: float = (_bore + 0.075) * 2.0
	_own_box(post, Vector3(head, head, -_muzzle_z), Vector3(0.0, mount_m, _muzzle_z * 0.5))


func _exit_tree() -> void:
	_drop_pool()


func _physics_process(delta: float) -> void:
	if not _ensure_pool():
		return
	_retire_expired(delta)

	_cool -= delta
	if _cool <= 0.0:
		_cool = _next_interval()
		_fire()

	_watch_for_silence(delta)


## THE CLOCK, and the whole argument in four lines. Nothing is read here except the time
## and the seeded generator. There is no branch on whether anybody is present, because the
## presence of a visitor is not information this artifact has any use for.
func _fire() -> void:
	var i: int = _next
	_next = (_next + 1) % _pool_n
	if i >= _balls.size():
		return
	var rb: RigidBody3D = _balls[i]
	if rb == null or not is_instance_valid(rb):
		return
	# Round-robin over a fixed pool: if the slot is still in the air it is taken back and
	# reused. Freeing and instantiating a RigidBody3D every couple of seconds for the life
	# of a hall is churn a Quest feels, and this artifact runs for as long as the hall does.
	if _live[i] == 1:
		_retire(i)

	var dir: Vector3 = _shot_direction()
	var start: Vector3 = global_transform * Vector3(0.0, mount_m, _muzzle_z - ball_r - MUZZLE_CLEAR)
	var vel: Vector3 = dir * maxf(speed_mps, 0.01)

	rb.freeze = false
	rb.sleeping = false
	rb.visible = true
	rb.shape_owner_set_disabled(BALL_OWNER, false)
	# Assigned from inside _physics_process, where a transform written onto a rigid body is
	# taken as a teleport rather than fought over by the solver for a frame.
	rb.global_position = start
	rb.linear_velocity = vel
	# A little spin, drawn from the same generator, so the ball reads as thrown rather than
	# extruded. It has no effect on where it goes; it is only how it looks going.
	rb.angular_velocity = Vector3(_rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0), _rng.randf_range(-2.0, 2.0))

	var ar: Area3D = _areas[i]
	if ar != null and is_instance_valid(ar):
		ar.set_deferred("monitoring", true)

	_live[i] = 1
	_age[i] = 0.0
	_travel[i] = dir
	_origin[i] = start
	_shots += 1
	_last_travel = vel
	fired.emit(i)


## Local -Z, tilted up by `rise`, then wandered by a seeded amount inside `spread_deg`.
##
## The wander is drawn BEFORE anything else happens and from nothing but the generator.
## That is the difference between this artifact and cube_spawner stated in code: the only
## input to the direction of a shot is the number of shots that came before it.
func _shot_direction() -> Vector3:
	var basis_g: Basis = global_transform.basis
	var fwd: Vector3 = -basis_g.z.normalized()
	var up: Vector3 = basis_g.y.normalized()
	var side: Vector3 = basis_g.x.normalized()
	var dir: Vector3 = (fwd + up * maxf(rise, 0.0)).normalized()
	if spread_deg > 0.0:
		var half: float = deg_to_rad(spread_deg) * 0.5
		dir = dir.rotated(up, _rng.randf_range(-half, half))
		dir = dir.rotated(side, _rng.randf_range(-half, half))
	return dir.normalized()


func _next_interval() -> float:
	var j: float = _rng.randf_range(-INTERVAL_JITTER, INTERVAL_JITTER)
	return maxf(interval_s * (1.0 + j), 0.1)


## Age, and the pit. A ball below kill_y has left the world and is not coming back, which
## in this room is the normal end of a ball rather than an error.
func _retire_expired(delta: float) -> void:
	for i in _pool_n:
		if _live[i] != 1:
			continue
		var rb: RigidBody3D = _balls[i]
		if rb == null or not is_instance_valid(rb):
			_live[i] = 0
			continue
		var was: float = _age[i]
		_age[i] += delta
		# PROGRESS ALONG THE THROW, JUDGED EARLY. Measuring at death meant a launcher
		# firing into a wall took life_s per ball to be suspected and STUCK_SHOTS of
		# them to be reported — a minute of a wrongly-turned token looking fine. Half
		# a second is already past the muzzle for any throw that is going anywhere,
		# and it is the projection onto the launch axis rather than the distance,
		# because a ball rattling in a gap moves without ever getting anywhere.
		if was < STUCK_AT_S and _age[i] >= STUCK_AT_S:
			var along: float = (rb.global_position - _origin[i]).dot(_travel[i].normalized())
			if along > _reach_best:
				_reach_best = along
			if along < STUCK_M:
				_short_deaths += 1
		var reach: float = rb.global_position.distance_to(_origin[i])
		if reach > _reach_best:
			_reach_best = reach
		if _age[i] >= life_s or rb.global_position.y < kill_y:
			_retire(i)


func _retire(i: int) -> void:
	_live[i] = 0
	var ar: Area3D = _areas[i]
	if ar != null and is_instance_valid(ar):
		# Deferred: an area's monitoring flag cannot be flipped while the physics server is
		# flushing its own queries, and this can be reached from inside a physics step.
		ar.set_deferred("monitoring", false)
	var rb: RigidBody3D = _balls[i]
	if rb == null or not is_instance_valid(rb):
		return
	rb.shape_owner_set_disabled(BALL_OWNER, true)
	rb.linear_velocity = Vector3.ZERO
	rb.angular_velocity = Vector3.ZERO
	rb.freeze = true
	rb.visible = false
	# Parked on the muzzle rather than a mile underground: it has no collider and no mesh
	# on screen, so it costs nothing to leave it here, and a ball parked at a huge offset
	# is a ball whose transform anything walking the tree has to reason about.
	rb.global_position = global_position + Vector3(0.0, mount_m, 0.0)


## THE ONLY THING THIS ARTIFACT EVER SAYS ABOUT ITSELF.
##
## Both branches describe a launcher that is working perfectly and achieving nothing, and
## neither is visible in a screenshot, a pathfinder run or a compile check.
func _watch_for_silence(delta: float) -> void:
	if _silent_said:
		return
	# NOT "has it fired" — it always has. _fire cannot fail once the pool exists, so
	# _shots reaches 1 at about one interval and this branch was unreachable in the
	# case it was written for. What is worth complaining about is a launcher that
	# fires perfectly into something a foot away, and that shows as PROGRESS, not as
	# a shot count.
	if _shots == 0:
		_idle_s += delta
		if _idle_s >= SILENT_GRACE_S:
			_say_silent("nothing has left the mouth in %.0f s — interval_s=%.2f and max_live=%d"
				% [_idle_s, interval_s, max_live])
		return
	if _short_deaths >= STUCK_SHOTS and _reach_best < STUCK_M:
		_say_silent(("%d balls have died within %.2f m of the mouth and not one has ever got"
			+ " further — the launcher is firing into something. It shoots along its own"
			+ " local -Z; check the token's rotation, and that there are five clear metres"
			+ " in front of it") % [_short_deaths, _reach_best])


func _say_silent(why: String) -> void:
	_silent_said = true
	push_warning("free_ball_launcher: " + why)
	silent.emit(why)


# ─── the pool ────────────────────────────────────────────────────────────────────────

## Built on the first physics frame rather than in _ready, for two reasons. The pool is a
## SIBLING of this node — see the header, a ball in our own subtree is measured as our
## footprint — and a node may not add children to its parent while that parent is still
## adding us. It is also how the pool comes back if this artifact is removed from the tree
## and put back, which is what museum streaming does to everything in a hall.
func _ensure_pool() -> bool:
	if _balls_root != null and is_instance_valid(_balls_root) and _pool_n > 0:
		return true
	if not is_inside_tree():
		return false

	_pool_n = clampi(max_live, 1, MAX_POOL)
	_age.resize(_pool_n)
	_live.resize(_pool_n)
	_travel.resize(_pool_n)
	_origin.resize(_pool_n)
	_balls.clear()
	_areas.clear()
	_next = 0

	_balls_root = Node3D.new()
	_balls_root.name = "FreeBalls_%d" % get_instance_id()
	# The fallback only happens for a node standing alone as a scene root, which is a probe
	# and never a map or the museum, where an artifact always has a container above it.
	var host: Node = get_parent()
	if host == null:
		host = self
	host.add_child(_balls_root)

	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.16, 0.17, 0.19)
	shell.metallic = 0.5
	shell.roughness = 0.55
	var band := StandardMaterial3D.new()
	band.albedo_color = muzzle_color
	band.emission_enabled = true
	band.emission = muzzle_color
	band.emission_energy_multiplier = 1.2
	band.roughness = 0.4

	# One material shared by every ball. Bounce well under a half: this is a dense thing,
	# not a football, and a ball that returns most of its energy off a wall never settles
	# and never falls into the pit the room is built around.
	var phys := PhysicsMaterial.new()
	phys.bounce = 0.32
	phys.friction = 0.62

	for i in _pool_n:
		var rb := RigidBody3D.new()
		rb.name = "Ball%02d" % i
		rb.mass = ball_mass
		rb.physics_material_override = phys
		# Layer 2 is "Dynamic World". It masks the static world so it lands and rolls, the
		# dynamic world so a pile of them behaves like a pile, and the player layer so a VR
		# body it reaches actually stops it. The desktop player and the museum walker are
		# already covered by layer 1.
		rb.collision_layer = DYNAMIC_LAYER
		rb.collision_mask = WALKER_LAYER | DYNAMIC_LAYER | PLAYER_LAYER
		rb.can_sleep = true
		_balls_root.add_child(rb)

		# Shape owner rather than a CollisionShape3D child — the pool is out of our subtree
		# so nothing depends on it here, but every collider in this file is hung the same
		# way and one exception is how the next reader learns the wrong lesson.
		var sph := SphereShape3D.new()
		sph.radius = ball_r
		# The first and only owner on a fresh body, so its id is BALL_OWNER and _fire and
		# _retire can switch the collider on and off without asking.
		rb.shape_owner_add_shape(rb.create_shape_owner(rb), sph)

		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = ball_r
		sm.height = ball_r * 2.0
		sm.radial_segments = 20
		sm.rings = 12
		mi.mesh = sm
		mi.material_override = shell
		rb.add_child(mi)

		# A lit band around the ball, so a thing crossing a dark hall at seven metres a
		# second is something the eye can catch before it arrives.
		var ring := MeshInstance3D.new()
		var rm := TorusMesh.new()
		# Proud of the sphere on the outside and sunk into it on the inside, so it reads as
		# a band strapped round the thing rather than a decal that z-fights with it.
		rm.inner_radius = ball_r * 0.96
		rm.outer_radius = ball_r * 1.10
		rm.rings = 20
		rm.ring_segments = 8
		ring.mesh = rm
		ring.material_override = band
		rb.add_child(ring)

		# THE SHOVE LIVES HERE. A rigid body cannot move a character, so the contact that
		# matters is detected rather than simulated. Masking both visitor layers, monitorable
		# off because nothing is watching for this area and a monitorable area is reported to
		# every trigger volume in the hall for no reason.
		var ar := Area3D.new()
		ar.name = "Contact"
		ar.collision_layer = 0
		ar.collision_mask = PLAYER_LAYER | WALKER_LAYER
		ar.monitorable = false
		ar.monitoring = false
		var asph := SphereShape3D.new()
		asph.radius = ball_r + 0.06
		var aid: int = ar.create_shape_owner(ar)
		ar.shape_owner_add_shape(aid, asph)
		rb.add_child(ar)
		ar.body_entered.connect(_on_ball_touched.bind(i))

		_balls.append(rb)
		_areas.append(ar)
		_live[i] = 0
		_age[i] = 0.0
		_travel[i] = Vector3.FORWARD
		_origin[i] = Vector3.ZERO
		_retire(i)

	return true


func _drop_pool() -> void:
	_balls.clear()
	_areas.clear()
	_pool_n = 0
	_next = 0
	# queue_free alone, with no remove_child first. This is reached from _exit_tree, and
	# taking a child off a parent that is itself in the middle of being torn down is the
	# one call Godot refuses; a queued free is safe from anywhere. The old container
	# survives one more frame holding balls that are already frozen, invisible and without
	# colliders, so nothing it does in that frame is visible or felt.
	if _balls_root != null and is_instance_valid(_balls_root):
		_balls_root.queue_free()
	_balls_root = null


## A ball reached somebody. The push goes along the direction the ball is TRAVELLING,
## not along the line from the ball to the body: the ball is not steering, and a shove
## that pointed at the visitor would be aiming after the fact.
##
## A BALL AT REST IS FURNITURE. `body_entered` fires whichever side moved, and the
## area keeps monitoring for the whole of life_s — so a ball that landed eight seconds
## ago sat on the floor as a mine, and a visitor who walked into it took the full
## shove along a heading the ball had not been on since it left the mouth. At the
## defaults three or four balls are lying about at any moment, which made the floor
## around the launcher permanently armed. Reading the ball's own linear_velocity fixes
## both halves — the direction is where it is actually going, and the strength is what
## it is actually carrying — and reads nothing about the visitor, so it stays free.
func _on_ball_touched(body: Node3D, i: int) -> void:
	if body == null or i >= _pool_n or _live[i] != 1:
		return
	# Every floor slab and wall in the hall is on layer 1 too, and a rolling ball
	# enters a new one every metre. One type check retires them before four group
	# lookups and an ancestor walk.
	if body is StaticBody3D:
		return
	if not _is_visitor(body):
		return
	var rb: RigidBody3D = _balls[i]
	if rb == null or not is_instance_valid(rb):
		return
	var vel: Vector3 = rb.linear_velocity
	if vel.length() < 1.0:
		return
	var push: Vector3 = vel.normalized() * maxf(shove_mps, 0.0) 		* minf(vel.length() / maxf(speed_mps, 0.01), 1.0)
	# A ball on its way down should shove you ACROSS the floor, not into it. At
	# #throw:high the launch elevation is 3.4 m/s up against 4.9 forward, and without
	# this more than half the hazard would go into lifting the visitor.
	push.y = clampf(push.y, 0.0, 1.5)
	if body is CharacterBody3D:
		# All three visitors land here. The addition is deliberate rather than an
		# assignment: whatever the visitor was already doing is still true, and the ball
		# is one more thing that happened to them.
		var cb := body as CharacterBody3D
		cb.velocity += push
	elif "velocity" in body:
		# Reached through get/set rather than as a property, because the static type here
		# is Node3D and Node3D has no velocity — written the other way this file would
		# not parse.
		var v: Variant = body.get("velocity")
		if typeof(v) != TYPE_VECTOR3:
			return
		body.set("velocity", (v as Vector3) + push)
	else:
		return
	struck.emit(body)


## A body counts only if it walks, and only if it is one of ours to shove.
##
## Everything static in a hall is on layer 1 — floors, hall walls, podiums, and this
## launcher's own post — so without this the ball's area would report the building and
## try to add velocity to a StaticBody3D. And never "any CharacterBody3D":
## hazard_creature_base extends CharacterBody3D, so that test hands the museum's own
## silhouettes to the launcher and it spends the hall knocking them about. The desktop
## player is in `player_body`, the museum Walker in `em_walker`, and the VR
## XRToolsPlayerBody in no group at all, so that one is found by the XROrigin3D above it.
## approach_wall's test (:579) plus one early-out for our own pool; approach_scale
## (:356) carries the same four groups, and carve_grid the same two constants.
func _is_visitor(b: Node) -> bool:
	if b == null or is_ancestor_of(b):
		return false
	if _balls_root != null and is_instance_valid(_balls_root) and _balls_root.is_ancestor_of(b):
		return false
	if b.is_in_group("em_walker") or b.is_in_group("player_body") \
		or b.is_in_group("player") or b.is_in_group("vr_player"):
		return true
	var n: Node = b.get_parent()
	while n != null:
		if n is XROrigin3D:
			return true
		n = n.get_parent()
	return false


# ─── build helpers ───────────────────────────────────────────────────────────────────

func _box(size: Vector3, pos: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	add_child(mi)


func _cyl(top_r: float, bot_r: float, h: float, pos: Vector3, rot: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = top_r
	cm.bottom_radius = bot_r
	cm.height = h
	cm.radial_segments = 18
	cm.rings = 1
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	add_child(mi)


## A ring, not a disc. A TorusMesh stands about +Y like a cylinder does, so it takes the
## same -90 degrees about X to lay it across the muzzle facing -Z.
func _torus(inner: float, outer: float, pos: Vector3, rot: Vector3, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 24
	tm.ring_segments = 8
	mi.mesh = tm
	mi.material_override = mat
	mi.position = pos
	mi.rotation = rot
	add_child(mi)


## Solid without a CollisionShape3D node, so the museum's extent walk finds the muzzle's
## meshes and nothing else. Shape owners are how a CollisionObject3D holds its shapes
## either way; the node is only ever a convenience for the editor.
func _own_box(body: CollisionObject3D, size: Vector3, pos: Vector3) -> void:
	var shape := BoxShape3D.new()
	shape.size = size
	var oid: int = body.create_shape_owner(body)
	body.shape_owner_add_shape(oid, shape)
	body.shape_owner_set_transform(oid, Transform3D(Basis.IDENTITY, pos))


# ─── for a probe ─────────────────────────────────────────────────────────────────────

## How many balls are in the air right now. Zero for the first interval after boot, and
## zero in a still that caught the gap between shots, neither of which is a fault.
func live_count() -> int:
	var n := 0
	for i in _pool_n:
		if _live[i] == 1:
			n += 1
	return n


## How many have ever left the mouth. The number a probe should assert on, because it is
## the one that does not depend on when the frame was taken.
func shots_fired() -> int:
	return _shots


## The velocity the most recent ball was let go with, in world space — direction and speed
## together, so a probe can check both the aim and the arc from one call. Zero before the
## first shot.
func last_travel() -> Vector3:
	return _last_travel
