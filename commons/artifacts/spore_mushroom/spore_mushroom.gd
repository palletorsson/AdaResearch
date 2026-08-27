# @identity
# essence: bait(t) = arc(fired) -> rest(floor) -> graft(eaten) -- a thrown thing that changes what eats it
# desire: to be more interesting to a predator than the person holding it
# critical_parameter: nothing about the mushroom -- what it changes is the DEGREE it adds to its eater
# triggers: launch() from the hand; the floor stops it; a spider within bite range consumes it
# emerges: a hunter becomes a garden, one mushroom at a time
# needs: a floor to land on [raycast]; something that eats [head_crab]; five of them [the hand]
# relationships: the catalyst bracelet's sibling — both are fired, both transform what they touch
# truth: the way to stop being hunted is not to be faster; it is to be less interesting than a mushroom.

extends Node3D
class_name SporeMushroom

## THE MUSHROOM (2026-08-27, Palle: "let me throw mushrooms, by firing, that
## land on the floor and that the spider rather eats. And that makes it get
## metamorphosed in a spider plant where the leg becomes branched").
##
## Three lives in one object. FLYING: a ballistic arc, integrated here rather
## than by the physics server, because everything this animal family does is a
## position write and a projectile that alone used RigidBody would be the only
## thing in the room obeying a different clock. LANDED: it sits in the group
## `spider_bait`, which is the whole of its interface — head_crab looks for the
## nearest member of that group and prefers it to the visitor. EATEN: it hands
## one DEGREE to whatever consumed it and collapses.
##
## It does not know what a degree does. That is the spider's business.

signal landed(where: Vector3)
signal eaten(by: Node)

const BAIT_GROUP := "spider_bait"

@export var cap_colour: Color = Color(0.92, 0.42, 0.60)      ## rose
@export var gill_colour: Color = Color(0.99, 0.94, 0.90)     ## bone
@export var stem_colour: Color = Color(0.96, 0.93, 0.86)
@export var spot_colour: Color = Color(1.0, 0.98, 0.94)
@export var cap_radius: float = 0.085
@export var stem_height: float = 0.115
@export var spots: int = 9
@export var gravity: float = 6.2          ## a little lighter than the world's, so the arc reads
@export var bounce: float = 0.18
@export var settle_speed: float = 0.35    ## below this it stops and becomes bait

## WALK OVER IT AND IT IS YOURS (2026-08-27, Palle: "place mushroom i can pick
## up by work over them"). No button and no aiming: a landed mushroom is picked
## up by standing on it, which is the only interaction a museum visitor already
## knows how to do. Whoever gets there first gets it — the spider eats what it
## reaches, and so do you.
## TRUE for the one riding in a hand. Without it the deferred settle below
## would plant the held mushroom where the controller happened to be, and the
## visitor would spend the whole game carrying a piece of bait the spider was
## walking toward.
@export var held_in_hand: bool = false
@export var can_be_picked_up: bool = true
@export var pickup_radius: float = 0.62
## a thrown mushroom that lands at your feet must not jump straight back into
## your hand, or a throw at close range is a no-op you cannot see
@export var pickup_delay: float = 1.4

## a scene to use as the body instead of the built one — set by the placer when
## the corpus turns out to own a better mushroom than this file draws
@export var visual_scene: String = ""

enum State { HELD, FLYING, LANDED, EATEN }
var _state: int = State.HELD
var _vel: Vector3 = Vector3.ZERO
var _life: float = 0.0
var _bob: float = 0.0
var _muzzle: float = 0.0     # metres of flight before it may land
var _look_t: float = 0.0     # throttles the pickup test
var _from: Vector3 = Vector3.ZERO
var _from_checked: bool = false
var _absorbing: bool = false
var _rest_y: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.randomize()
	# PLACED BY A MAP, not thrown: the grid stands it on the floor and nobody
	# ever calls launch(), so it has to make itself bait on its own or it is
	# scenery — invisible to the spider and to a visitor walking over it.
	call_deferred("_settle_if_placed")
	if visual_scene != "" and ResourceLoader.exists(visual_scene):
		var ps: PackedScene = load(visual_scene) as PackedScene
		if ps != null:
			add_child(ps.instantiate())
		else:
			_build()
	else:
		_build()
	set_process(true)


func _settle_if_placed() -> void:
	if held_in_hand:
		return
	if _state == State.HELD:
		_plant(global_position)


## Fired from a hand. `dir` need not be normalised; `speed` is metres per second.
## `muzzle` is how far it flies before it is allowed to land on anything — the
## first half metre out of a hand is the player's own arm, their controller and
## whatever they are standing against.
func launch(from: Vector3, dir: Vector3, speed: float = 5.5, muzzle: float = 0.5) -> void:
	# THE WHOLE TRANSFORM, IN WORLD SPACE (2026-08-27, Palle: "the positioning of
	# the mushroom when shooting is related to local global, the mushroom all are
	# coming out around the zero point"). Writing global_position alone leaves
	# the node carrying whatever rotation and SCALE its parent has, and it does
	# nothing at all if the node is not in the tree yet — which is silent.
	# _from is kept so the first frame can check the write actually took.
	_from = from
	if is_inside_tree():
		global_transform = Transform3D(Basis(), from)
	else:
		push_warning("spore_mushroom: launched before entering the tree — position will be its parent's")
		position = from
	var d: Vector3 = dir.normalized() if dir.length() > 0.001 else Vector3.FORWARD
	_vel = d * speed
	_state = State.FLYING
	_life = 0.0
	_muzzle = maxf(0.0, muzzle)


## Called by whatever eats it. Returns the number of degrees it is worth, which
## is always one — a mushroom is a unit, and the ladder is counted in mushrooms.
func consume(by: Node = null) -> int:
	if _state == State.EATEN:
		return 0
	_state = State.EATEN
	remove_from_group(BAIT_GROUP)
	emit_signal("eaten", by)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "scale", Vector3.ONE * 0.001, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "position:y", position.y + 0.06, 0.35)
	tw.chain().tween_callback(queue_free)
	return 1


func is_bait() -> bool:
	return _state == State.LANDED


func _process(delta: float) -> void:
	if _state == State.FLYING:
		# and it says so if the write did not take, rather than appearing at the
		# origin and leaving somebody to guess why
		if not _from_checked:
			_from_checked = true
			var off: float = global_position.distance_to(_from)
			if off > 0.05:
				push_warning("spore_mushroom: launched at %s but stands at %s (%.2f m out) — a parent transform is in the way"
					% [str(_from), str(global_position), off])
				global_transform = Transform3D(Basis(), _from)
		# A FRAME HITCH MUST NOT TELEPORT IT (2026-08-27, Palle: "it seems that I
		# am throwing backwards and the mushroom ends up on the wall"). The step
		# is velocity times delta and the cast is only as long as the step, so a
		# 0.3 s hitch on the frame after instantiation — a new scene, a shader,
		# anything — makes one step nearly two metres and the mushroom plants on
		# the first wall along that line instead of flying. Capped at a frame of
		# 30 fps, it can only ever advance a hand's width at a time.
		var dt: float = minf(delta, 0.033)
		_life += dt
		_vel.y -= gravity * dt
		var step: Vector3 = _vel * dt
		var hit := _cast(global_position, global_position + step)
		if _muzzle > 0.0:
			_muzzle -= step.length()
			hit = {}                      # nothing lands in the first half metre
		if hit.is_empty():
			global_position += step
			# it tumbles while it flies
			rotate_x(dt * 5.2)
			rotate_z(dt * 3.1)
		else:
			_plant(hit["position"] as Vector3)
		if _life > 8.0:                      # never fall forever
			_plant(Vector3(global_position.x, _find_floor(), global_position.z))
	elif _state == State.LANDED:
		if _absorbing:
			return       # whatever is eating it owns its transform now
		# a slow breath, so a landed mushroom reads as alive rather than as debris
		_bob += delta
		position.y = _rest_y + sin(_bob * 1.6) * 0.004
		if can_be_picked_up and _bob > pickup_delay:
			_look_t += delta
			if _look_t > 0.15:            # eight times a second is plenty
				_look_t = 0.0
				_try_pickup()


## Anyone standing on it takes it: the grid's player, the museum's walker, both
## by group so neither lane needs to know about this artifact.
## SOMETHING IS DRAWING IT IN (2026-08-27, Palle: "the spider should walk over
## the mush a suck up the mushroom though this body"). The mushroom stops
## breathing, stops being pick-up-able, and hands its transform to whatever is
## taking it — otherwise the resting bob writes position.y every frame and
## fights the lift, and the visitor could pluck it out mid-swallow.
func begin_absorb() -> void:
	_absorbing = true
	remove_from_group(BAIT_GROUP)


func _try_pickup() -> void:
	if _absorbing:
		return
	var tree := get_tree()
	if tree == null:
		return
	var gm := tree.root.get_node_or_null("GameManager")
	if gm == null or not gm.has_method("add_mushroom"):
		return
	if int(gm.get("mushrooms")) >= int(gm.get("max_mushrooms")):
		return                            # a full hand walks straight over it
	for g in ["player", "player_body", "em_walker"]:
		for n in tree.get_nodes_in_group(g):
			if not (n is Node3D) or not is_instance_valid(n):
				continue
			var off: Vector3 = (n as Node3D).global_position - global_position
			if absf(off.y) > 2.2:
				continue                  # a visitor on the floor above is not standing on it
			off.y = 0.0
			if off.length() > pickup_radius:
				continue
			if bool(gm.call("add_mushroom", 1)):
				_collect()
			return


func _collect() -> void:
	_state = State.EATEN
	remove_from_group(BAIT_GROUP)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "position:y", position.y + 0.45, 0.34).set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "scale", Vector3.ONE * 0.001, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)


func _plant(at: Vector3) -> void:
	if _state == State.EATEN:
		return
	global_position = at
	# LOCAL, because the bob below writes `position`. Storing the global y here
	# and assigning it as a local one is the mix Palle spotted: under any parent
	# that is not at the origin it teleports the mushroom on the frame after it
	# lands.
	_rest_y = position.y
	rotation = Vector3(0.0, _rng.randf_range(0.0, TAU), 0.0)   # upright, any facing
	_vel = Vector3.ZERO
	_state = State.LANDED
	if not is_in_group(BAIT_GROUP):
		add_to_group(BAIT_GROUP)
	emit_signal("landed", at)
	# a small arrival, so the eye finds where it went
	scale = Vector3(1.25, 0.7, 1.25)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.28).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _cast(from: Vector3, to: Vector3) -> Dictionary:
	if not is_inside_tree():
		return {}
	var w := get_world_3d()
	if w == null:
		return {}
	var space := w.direct_space_state
	if space == null:
		return {}
	var q := PhysicsRayQueryParameters3D.create(from, to)
	q.collision_mask = 1
	return space.intersect_ray(q)


func _find_floor() -> float:
	var hit := _cast(global_position + Vector3(0, 1.0, 0), global_position - Vector3(0, 20.0, 0))
	return float((hit["position"] as Vector3).y) if not hit.is_empty() else global_position.y


## Map tokens: spore_mushroom#cap:e0699a#radius:0.09
func apply_grid_config(config: Dictionary) -> void:
	if config.has("cap"):
		var s := str(config["cap"]).strip_edges()
		if s.begins_with("#"): s = s.substr(1)
		if Color.html_is_valid(s): cap_colour = Color.html(s)
	if config.has("radius"):
		var r := str(config["radius"]).strip_edges()
		if r.is_valid_float(): cap_radius = clampf(float(r), 0.02, 0.5)


# ── the body ────────────────────────────────────────────────────────────────

func _mat(c: Color, rough: float, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _build() -> void:
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = cap_radius * 0.26
	sm.bottom_radius = cap_radius * 0.36
	sm.height = stem_height
	sm.radial_segments = 14
	stem.mesh = sm
	stem.position = Vector3(0, stem_height * 0.5, 0)
	stem.material_override = _mat(stem_colour, 0.82)
	add_child(stem)

	# the gills: a shallow cone under the cap, paler than either
	var gills := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = cap_radius * 0.92
	gm.bottom_radius = cap_radius * 0.30
	gm.height = cap_radius * 0.34
	gm.radial_segments = 18
	gills.mesh = gm
	gills.position = Vector3(0, stem_height + cap_radius * 0.10, 0)
	gills.material_override = _mat(gill_colour, 0.9)
	add_child(gills)

	# the cap: a squashed sphere, cut off flat underneath by the gills
	var cap := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = cap_radius
	cm.height = cap_radius * 1.35
	cm.radial_segments = 24
	cm.rings = 12
	cap.mesh = cm
	cap.position = Vector3(0, stem_height + cap_radius * 0.30, 0)
	cap.material_override = _mat(cap_colour, 0.55)
	add_child(cap)

	# spots, scattered on the dome — the one flourish, and the reason it reads
	# as a mushroom from four metres away instead of as a pin
	var spot_mat := _mat(spot_colour, 0.35)
	for i in range(spots):
		# ON the dome, not in it. The cap is a sphere squashed to 1.35/2 of its
		# radius in y, so a spot's height has to use 0.675 and not the 0.62 the
		# first pass guessed — eight percent short is enough to bury every spot
		# inside the cap and leave two poking through the rim like an error.
		# The 1.03 lifts them clear of the surface they sit on.
		var u: float = _rng.randf_range(0.10, 0.86)
		var a: float = _rng.randf_range(0.0, TAU)
		var r: float = cap_radius * sqrt(1.0 - u * u) * 1.03
		var s := MeshInstance3D.new()
		var ss := SphereMesh.new()
		var sr: float = cap_radius * _rng.randf_range(0.13, 0.22)
		ss.radius = sr
		ss.height = sr * 1.2
		ss.radial_segments = 10
		ss.rings = 5
		s.mesh = ss
		s.position = Vector3(cos(a) * r, stem_height + cap_radius * 0.30 + u * cap_radius * 0.675 * 1.03, sin(a) * r)
		s.scale = Vector3(1.0, 0.40, 1.0)
		s.material_override = spot_mat
		add_child(s)
