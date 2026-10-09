# @identity
# essence: leg_walker(n) = one body, n IK chains, one gait -- the shared trunk of the 1-to-8 ladder
# desire: to be placed in a room and walk it, instead of waiting for a keyboard
# critical_parameter: driven_by_player -- the same animal is a puppet or an inhabitant
# triggers: _walk(delta) each frame; the pace turns for home at pace_reach
# emerges: a ladder legible as a ladder -- the leg count is the only thing that differs
# needs: a Body child carrying this script [has]; a floor under it [probed]; a collider [missing by design]
# relationships: base of two/three/four/five/six_leg_critter; four_leg_critter is head_crab's rig
# truth: the number of legs is the whole argument -- everything else must be held equal for it to show.

extends MeshInstance3D

## THE SHARED TRUNK OF THE LEG LADDER (2026-08-27, Palle: "build the leg ladder
## into the forces spine").
##
## Five scripts — two, three, four, five and six legs — were one script pasted
## five times: the same seven exports verbatim, the same random-turn patrol, the
## same three places where a foot is planted at ABSOLUTE world zero. Putting the
## ladder in a walked room needed three repairs, and doing them five times over
## is how a family ends up with five rival implementations of its own gait.
##
## WHAT CHANGED, and none of it is new behaviour for anything already placed:
##
##   THE PATROL WAS ALREADY THERE and it was unbounded. It sat on the ELSE
##   branch of the player's own movement keys, so a critter in a room either
##   stood still or marched in step with the visitor, and once it did move it
##   walked out of the room — no home, no bound. It is a LEASH now: it turns
##   back when it is further than pace_reach from where it was placed.
##
##   THE FLOOR WAS ABSOLUTE ZERO. Every plant wrote y = 0.0, which is only the
##   floor on a map whose floor happens to be there. head_crab paid for this
##   twice in one day. _ground() answers with the height the body was placed
##   at, improved by a downward ray once the physics space has the structure in
##   it — which is not true on the frame this first runs.
##
##   THE INPUT COUPLING IS AN EXPORT. driven_by_player defaults TRUE, so every
##   existing demo and F6 scene behaves exactly as before; a placed critter sets
##   it false through its map token.
##
## THE ROOT IS NOT THE RIG. This script lives on a `Body` CHILD of a bare Node3D
## root in all five scenes — the trap head_crab.gd already documents in this
## directory. Never move it to the root: `$IK_leg_0/Armature/Skeleton3D` and
## head_crab's own `_rig.get_node_or_null("Body")` both depend on where it is.

@export var move_speed: float = 2.0
@export var turn_speed: float = 40.0
@export var patrol_speed: float = 1.0

## Step gait parameters
@export_group("Gait")
@export var step_threshold: float = 1.5   ## How far foot can be from "home" before stepping
@export var step_height: float = 1.0      ## How high the foot lifts during a step
@export var step_duration: float = 0.25   ## How long a step takes (seconds)
@export var step_overshoot: float = 0.5   ## How far ahead of home to place foot

@export_group("Placement")
## FALSE for a critter standing in a room: it paces its own short line instead
## of moving whenever the visitor moves.
@export var driven_by_player: bool = true
## metres from where it was placed before the pace turns it back
@export var pace_reach: float = 1.5
## The demos add an orange debug sphere under every foot. They are how you read
## a gait on a test bench and they are wrong in an exhibit, so a placed specimen
## turns them off. BOOL on purpose: measured in VFM_09_Legs, the grid's config
## fallback sets a bool property from a token and silently refuses a float, so
## a switch reaches this animal and a number does not.
@export var show_foot_markers: bool = true:
	set(v):
		show_foot_markers = v
		_apply_markers()
## THE GAIT NUMBERS ARE DISTANCES, compared in world space by distance_to, so
## they have to shrink with the body or a shrunken animal takes a full-size
## stride and never plants a foot. head_crab measured exactly that failure.
## A SETTER, because the grid does not call apply_grid_config on this node.
## Measured in VFM_09_Legs: a token carrying #driven_by_player:false#walker_scale:0.16
## arrived with the boolean applied and the scale untouched at 1.00 — the grid
## reaches a scriptless root, fails, and falls back to setting PROPERTIES by
## name on the child that has them. A plain @export takes the number and nothing
## re-derives from it. A setter fires on every path there is.
@export var walker_scale: float = 1.0:
	set(v):
		walker_scale = v
		if _authored_y >= 0.0:        # only once _ready has read the scene's own offset
			_apply_walker_scale()

var _patrol_timer: float = 0.0
var _patrol_angle: float = 0.0
var _rng := RandomNumberGenerator.new()

var _floor_y: float = 0.0
var _floor_learned: bool = false
var _floor_settle: float = 0.0
var _pace_home: Vector3 = Vector3.ZERO
var _authored_y: float = -1.0        # the scene's own shoulder offset, read once
var _authored_step: Vector3 = Vector3.ZERO
var _markers_done: bool = false


func _ready() -> void:
	_rng.randomize()
	_patrol_angle = _rng.randf_range(0.0, TAU)
	_apply_walker_scale()


## Scale the whole body and re-derive every gait distance from it. Called from
## _ready and again from apply_grid_config, because the grid hands configuration
## to an artifact AFTER it is in the tree — a token that only set the number
## would change nothing anybody reads.
func _apply_walker_scale() -> void:
	if _authored_y < 0.0:
		_authored_y = position.y          # 2.2 in all six scenes
		_authored_step = Vector3(step_threshold, step_height, step_overshoot)
	# THE SHOULDER HEIGHT IS IN THE BODY'S OWN TRANSFORM, NOT IN THE MESH.
	# Every scene parks this node at y = 2.2 above a bare root and hangs the
	# legs beneath it, reaching down to the root's plane. Scaling the node
	# scales its children and NOT its own offset, so a body shrunk to a sixth
	# keeps standing 2.2 m up while its legs only reach 0.37 — it floats, feet
	# dangling, and every gate still passes. Both numbers scale or neither does.
	scale = Vector3.ONE * walker_scale
	position.y = _authored_y * walker_scale
	# and the gait distances, which are compared in WORLD space by distance_to
	step_threshold = _authored_step.x * walker_scale
	step_height = _authored_step.y * walker_scale
	step_overshoot = _authored_step.z * walker_scale


## Map tokens: two_leg_critter#driven_by_player:false#pace_reach:1.2#walker_scale:0.4
func apply_grid_config(config: Dictionary) -> void:
	if config.has("driven_by_player"):
		driven_by_player = _cfg_bool(config["driven_by_player"], driven_by_player)
	if config.has("show_foot_markers") or config.has("markers"):
		var raw2: Variant = config.get("show_foot_markers", config.get("markers"))
		show_foot_markers = _cfg_bool(raw2, show_foot_markers)
	if config.has("pace_reach"):
		pace_reach = _cfg_num(config["pace_reach"], pace_reach)
	if config.has("patrol_speed"):
		patrol_speed = _cfg_num(config["patrol_speed"], patrol_speed)
	if config.has("move_speed"):
		move_speed = _cfg_num(config["move_speed"], move_speed)
	if config.has("walker_scale") or config.has("scale"):
		var raw: Variant = config.get("walker_scale", config.get("scale"))
		var want: float = _cfg_num(raw, walker_scale)
		if not is_equal_approx(want, walker_scale):
			walker_scale = clampf(want, 0.02, 4.0)
			_apply_walker_scale()


## A token value is always TEXT, and a valueless key arrives as `true` —
## float("true") is 0.0, which would silently shrink an animal to nothing.
func _cfg_num(v: Variant, fallback: float) -> float:
	var s := str(v).strip_edges()
	return float(s) if s.is_valid_float() else fallback


func _cfg_bool(v: Variant, fallback: bool) -> bool:
	var s := str(v).strip_edges().to_lower()
	if s in ["1", "true", "on", "yes"]:
		return true
	if s in ["0", "false", "off", "no"]:
		return false
	return fallback


## The height a foot plants at. The shoulder array is authored at y = -2.2 and
## the Body node's own transform is +2.2, so the placed ROOT's world y is what
## a foot should reach — that is what this returns, refined by a real ray once
## the grid's structure bodies exist in the physics space.
func _ground() -> float:
	return _floor_y


## LEARNED ON THE FIRST FRAME, NEVER IN _ready. The subclasses plant their feet
## inside _ready, so a _ground() that learned on demand learned during _ready —
## and at that moment the node is still at the origin, because the grid (and any
## probe) sets the position AFTER add_child. Measured: every critter took its
## home as Vector3.ZERO and the leash pulled it toward the world origin, 130 m
## away. The base's own comment said not to do this and the code did it anyway.
## Hide (or restore) the per-foot debug spheres. layers = 0 rather than
## visible = false: visibility is hierarchical in Godot and would take the foot
## target's children with it.
func _apply_markers() -> void:
	if not is_inside_tree():
		return
	var stack: Array = [self]
	while not stack.is_empty():
		var q: Node = stack.pop_back()
		var nm := String(q.name).to_lower()
		if q is VisualInstance3D and (nm.contains("footvis") or nm.contains("foot_vis") or nm.contains("footdebug")):
			(q as VisualInstance3D).layers = 1 if show_foot_markers else 0
		elif q is MeshInstance3D and q.get_parent() != null and String(q.get_parent().name).to_lower().begins_with("foottarget"):
			(q as VisualInstance3D).layers = 1 if show_foot_markers else 0
		for c in q.get_children(): stack.append(c)


func _learn_place() -> void:
	if _floor_learned:
		return
	_floor_learned = true
	_pace_home = global_position
	# NOT the literal 2.2. Five of the six scenes park this node at y = 2.2 with
	# a five-unit leg under it, but octapod_ik is a rig at a twentieth of that
	# scale — 0.12 per bone, a 0.6 leg — so the shoulder height has to come from
	# the scene rather than from a constant that happened to be true five times.
	_floor_y = (global_transform * Vector3(0.0, -_authored_y, 0.0)).y


## Keep looking for the actual floor for two seconds. The structure's static
## bodies are not registered on the frame this artifact first runs, so a single
## early ray reports nothing and the fallback silently becomes the answer.
func _settle_floor(delta: float) -> void:
	if _floor_settle >= 2.0 or not is_inside_tree():
		return
	_floor_settle += delta
	var w := get_world_3d()
	if w == null:
		return
	var space := w.direct_space_state
	if space == null:
		return
	var p: Vector3 = global_position
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(p.x, _floor_y + 3.0, p.z), Vector3(p.x, _floor_y - 6.0, p.z))
	q.collision_mask = 1
	var hit: Dictionary = space.intersect_ray(q)
	if not hit.is_empty():
		_floor_y = float((hit["position"] as Vector3).y)
		_floor_settle = 99.0


## THE ONE MOVEMENT BLOCK, replacing five copies of it.
## Driven: the visitor's own movement keys, exactly as before.
## Paced: a short line. It keeps its heading until it is further than
## pace_reach from where it was placed, then turns for home — so a critter on a
## plinth stays on its plinth instead of wandering off down the hall.
func _walk(delta: float) -> void:
	if not _markers_done:
		_markers_done = true
		_apply_markers()      # the subclass adds them in its own _ready, after ours
	_learn_place()
	_settle_floor(delta)
	if driven_by_player:
		var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
		if input.length_squared() > 0.01:
			position += -basis.z.normalized() * input.y * delta * move_speed
			rotation.y += deg_to_rad(-input.x * delta * turn_speed)
			return
	var away: Vector3 = global_position - _pace_home
	away.y = 0.0
	var turn: float = 1.0
	if away.length() > pace_reach:
		# TURN FOR HOME. The heading that moves a body along -basis.z toward a
		# point p is atan2(-(p-here).x, -(p-here).z); home is here MINUS away,
		# so the two negations cancel and it is atan2(away.x, away.z). Writing
		# it with the minus signs still on pointed every critter directly away
		# from its plinth, which measured as a leash that pushed.
		_patrol_angle = atan2(away.x, away.z)
		_patrol_timer = 0.0
		turn = 3.0          # come about briskly, or it sails past on the arc
	else:
		_patrol_timer += delta
		if _patrol_timer >= 3.0:
			_patrol_timer = 0.0
			_patrol_angle += _rng.randf_range(-PI * 0.5, PI * 0.5)
	rotation.y = lerp_angle(rotation.y, _patrol_angle, minf(1.0, turn * delta))
	# NORMALISED: this node's basis carries walker_scale (set in _apply_walker_scale),
	# so a bare -basis.z advanced a scale-4 body four times faster than the token said.
	# VFM_09_Legs found it: 'same pace' broke on the eighth rung (2026-09-02).
	position += -basis.z.normalized() * delta * patrol_speed
