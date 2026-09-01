extends XRToolsPickable

## EXTENDS THE PICKABLE, NOT RigidBody3D. The first version extended
## RigidBody3D, and because a .tscn that instances pickable.tscn and sets
## `script =` REPLACES the root's script, the hammer silently stopped being
## an XRToolsPickable: it compiled, instantiated, built its geometry and
## could not be picked up by anything. grab_cube.gd, the corpus's own
## minimal example, extends XRToolsPickable for exactly this reason.

## THE LINE, TWO SECONDS LATER.
##
## 2026-09-01, Palle: "you walk a corridor and see walk_this_line_marking, then
## line_demo — you create a line, the line is just a line and you can adjust its
## length. After two seconds the line is turned into a big sledgehammer. You can
## hold and destroy other artifacts with it. And in front of you there is a police
## line barrier that says DO NOT CROSS. You can use the sledgehammer to break it."
##
## This is the room's argument stopping being an argument. Point_Lines claims that
## measuring and destroying are one technique in two situations — that pointing
## and striking differ in what is at the far end, not in the line. A wall label
## can assert that. A hammer that was a measuring line ninety seconds ago, in your
## hand, in front of a barrier, does not have to.
##
## SO IT REUSES THE LASER'S CONTRACT, WHICH IS THE WHOLE POINT. Nothing here
## invents a private way to break things. `laser_exploding_sphere` already
## defined one — collision layer 21 for the raycast, `trigger_explosion()` to
## destroy — and its own header says why it is in this room: "both are objects
## that the laser interacts with, but one measures and one destroys." The hammer
## calls the SAME entry points. If a thing can be destroyed by the beam it can be
## destroyed by the head, because the target never knew which was coming.
##
##     strike(from, by) -> bool      the contract, for things that want the hit
##     trigger_explosion()           the laser's, honoured for free
##
## IT MUST BE SWUNG. A hammer that destroys whatever it rests against is a wand,
## and a wand makes the opposite argument: that the damage is in the object
## rather than in what you did with it. So a strike needs speed at the head, and
## the threshold is a real one you can fail to reach.

const HEAD_SPEED_MIN := 1.15        ## m/s at the head. Below this it is a lean.
const STRIKE_COOLDOWN := 0.45       ## so one swing is one strike, not thirty
## HOW LONG A SWING STAYS A SWING, in seconds.
##
## The first version compared the INSTANTANEOUS head speed against the threshold
## on the same frame it queried the overlap, and a probe caught that those two
## are almost never true together: Area3D publishes its overlaps a frame late, so
## the frame that has the speed has no contact and the frame that has the contact
## has no speed. It happened to work when a hand moved the hammer continuously
## and failed completely on any discrete motion — the worst kind of bug, since VR
## would have hidden it.
##
## A hammer that made contact 80 ms after being swung has still been swung. So
## the speed is remembered and decays, and the strike test reads the remembered
## value rather than this frame's.
const SWING_MEMORY := 0.18
## ABOVE THIS IT IS A TELEPORT, NOT A SWING.
##
## The probe caught the hammer destroying a barrier it was merely resting
## against — at 24 m/s, because BEING PLACED somewhere is a single-frame
## displacement and the speed test could not tell that from a blow. In the room
## that is not hypothetical: the grid spawns this at a cell, line_demo spawns it
## at the line's midpoint, and a hand grabbing it snaps it to the palm. Each of
## those is a jump, and each would have broken whatever the head happened to
## land next to.
##
## A human swing tops out around 10-15 m/s at the head of a sledgehammer. Above
## that, nothing was swung — something was moved — so the memory is cleared
## rather than filled.
const HEAD_SPEED_MAX := 45.0

@export var haft_m: float = 0.86
@export var head_len_m: float = 0.28
## PINK AND QUEER (2026-09-01, Palle's words). A sledgehammer is the most
## conventionally masculine object in the corpus — the crowbar, the tool that
## solves a room by force — and it arrives here having been a measuring line
## ninety seconds earlier. Painting it hot pink with a violet haft is not a
## decoration on that joke, it IS the joke: the instrument of force is the same
## object as the instrument of measure, and neither of them has to look the way
## the genre says. It also matches what comes out of whatever it breaks.
## PINK THAT SURVIVES ACES.
##
## 2026-09-01, Palle: "the hammer is not pink yet." It photographed hot pink on
## the capture bench and did not read pink in the museum, and the bench was the
## thing lying: it renders FILMIC with a 1.2 key light, while the museum renders
## ACES with tonemap_white 6.0 (em_lighting.gd:207-209). ACES compresses highly
## saturated reds and magentas hard - it is the tonemapper's best-known failure
## and it pushes exactly this hue toward a washed orange-grey.
##
## So the colour is carried by EMISSION rather than albedo. The museum has
## glow_enabled true (em_lighting.gd:212), so an emissive head blooms pink
## through the tonemapper instead of being flattened by it. Albedo alone cannot
## win that argument; light can.
@export var head_color: Color = Color(1.0, 0.30, 0.66)      # hot pink
@export var haft_color: Color = Color(0.66, 0.38, 0.98)     # violet
## Was 0.45 - enough on a FILMIC bench, invisible under ACES.
@export var head_glow: float = 1.1
@export var haft_glow: float = 0.9
## Set by line_demo when the line becomes this. Purely for the record — the
## hammer works the same whether it was born one or transformed into one.
@export var was_a_line: bool = false

signal struck(target: Node, speed: float)

var _head: Node3D
var _strike_shape: SphereShape3D
var _last_head_pos := Vector3.ZERO
var _head_speed := 0.0
var _recent_speed := 0.0        ## the swing, still counting for SWING_MEMORY
var _cool := 0.0
var _primed := false
var _broken: Array[Node] = []


func _ready() -> void:
	_build()
	set_physics_process(true)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("haft_m"):
		haft_m = float(config_data["haft_m"])
	if config_data.has("head_len_m"):
		head_len_m = float(config_data["head_len_m"])
	if config_data.has("was_a_line"):
		was_a_line = bool(config_data["was_a_line"])
	if config_data.has("freeze"):
		# HELD STILL. This is a RigidBody with gravity, so on a capture bench it
		# is measured correctly and then falls out of frame before the shutter —
		# the AABB in the log was right and the photograph was empty grass. A
		# hammer resting in a hand is not falling either, so freezing is not a
		# lie about the object, only about who is holding it.
		freeze = true
	if _head:
		_build()


func _build() -> void:
	for c in get_children():
		if c is MeshInstance3D or c.name == "StrikeHead":
			c.queue_free()

	var haft := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.021
	cyl.bottom_radius = 0.024
	cyl.height = haft_m
	haft.mesh = cyl
	haft.position = Vector3(0, haft_m * 0.5, 0)
	haft.material_override = _mat(haft_color, 0.82, 0.0, haft_glow)
	add_child(haft)

	_head = Node3D.new()
	_head.name = "StrikeHead"
	_head.position = Vector3(0, haft_m, 0)
	add_child(_head)

	var steel := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(head_len_m, 0.13, 0.13)
	steel.mesh = bm
	# metallic 0.0, NOT 0.55: a metallic surface takes its colour from the
	# environment it reflects, and the museum's is warm plaster (3400 K key,
	# SDFGI/SSIL bounce, blue-grey fog). The capture bench has no environment
	# to reflect, so metal was free there and pink read fine -- it is the
	# bench that was lying, not the museum. Keep the head dielectric.
	steel.material_override = _mat(head_color, 0.42, 0.0, head_glow)
	_head.add_child(steel)

	# THE STRIKE VOLUME IS A SHAPE QUERY, NOT AN Area3D.
	#
	# It was an Area3D riding the head, and a probe proved that unreliable: with
	# the area's mask correct, monitoring on, and the head passing straight
	# through the barrier at 8.4 m/s, get_overlapping_bodies() returned ZERO on
	# every frame — while a direct intersect_shape at the same place found the
	# collider immediately. An Area3D nested inside the pickable's RigidBody3D
	# does not reliably publish overlaps when the body is being moved by
	# something other than the physics integrator, which is exactly how a held
	# hammer moves.
	#
	# So the head asks the space itself, on the frames when it matters. That is
	# fewer moving parts, it needs no monitoring state, and it is the mechanism
	# the probe could actually verify.
	_strike_shape = SphereShape3D.new()
	_strike_shape.radius = head_len_m * 0.62

	_last_head_pos = _head.global_position if is_inside_tree() else Vector3.ZERO
	_primed = false


func _physics_process(delta: float) -> void:
	if _head == null or not is_instance_valid(_head):
		return
	var now := _head.global_position
	# THE FIRST FRAME ONLY RECORDS. _last_head_pos is set in _build(), which runs
	# before the node has been positioned by whoever spawned it — so frame one
	# measured the gap between "at the origin" and "where I was actually put" and
	# called it a swing. A probe caught the hammer striking while completely
	# motionless, which in the room means it takes a picture off the wall the
	# instant line_demo hands it to you, or the instant a hand grabs it.
	if not _primed:
		_primed = true
		_last_head_pos = now
		return
	if delta > 0.0:
		_head_speed = (now - _last_head_pos).length() / delta
	_last_head_pos = now

	# Remember the swing. Peak-hold, then decay to zero over SWING_MEMORY.
	if _head_speed > HEAD_SPEED_MAX:
		pass                           # a teleport: placed, spawned, or grabbed
		# IGNORE the sample; do NOT zero the memory. The old line set
		# _recent_speed = 0.0 here, and the cap was 14 m/s -- which a real VR
		# swing clears easily, because the head sits at the end of a haft and
		# the lever arm multiplies wrist speed. So every hard swing was thrown
		# away AT THE MOMENT OF IMPACT, and only feeble taps got through: the
		# barrier leaned 7 degrees and never took a third hit. A grab or spawn
		# moves the head metres in ONE frame (72+ m/s at 72 fps), so 45 m/s
		# still separates a teleport from the hardest human swing.
	elif _head_speed > _recent_speed:
		_recent_speed = _head_speed
	elif SWING_MEMORY > 0.0:
		_recent_speed = maxf(0.0, _recent_speed - delta * (HEAD_SPEED_MIN * 4.0) / SWING_MEMORY)

	if _cool > 0.0:
		_cool -= delta
		return
	if _recent_speed < HEAD_SPEED_MIN:
		return
	if _strike_shape == null or not is_inside_tree():
		return

	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	if space == null:
		return
	# SWEEP, DO NOT SAMPLE.
	#
	# The head is a 0.17 m sphere tested at one point per frame. A VR swing runs
	# 5-14 m/s, and at 14 m/s a 72 Hz frame steps 0.19 m — further than the head
	# is wide. So the fastest swings, the ones a person is most sure they landed,
	# are exactly the ones that step OVER a thin barrier plank and report nothing.
	# Godot's motion query sweeps the shape from last frame's position to this
	# one, which closes the gap without making the head bigger (a bigger head
	# would start breaking things beside what you aimed at).
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = _strike_shape
	q.transform = Transform3D(Basis(), _last_head_pos)
	q.motion = now - _last_head_pos
	# Bit 21 is the laser's layer — the same set of things the beam can reach —
	# plus bit 1 for ordinary world bodies. Areas as well as bodies, because a
	# wall showing has NO COLLIDER by contract and would otherwise be unhittable.
	q.collision_mask = 1048576 | 1
	q.collide_with_areas = true
	q.collide_with_bodies = true
	q.exclude = [get_rid()]
	# intersect_shape ignores `motion`, so the sweep is done as two queries: the
	# swept path first (cheap, tells us WHETHER something was crossed), then the
	# ordinary overlap at both ends to find out WHAT. Two cheap queries beat one
	# that quietly ignores half its parameters.
	var swept: Array = space.cast_motion(q)
	var crossed: bool = swept.size() == 2 and float(swept[0]) < 1.0
	var probes: Array = [now]
	if crossed:
		probes.append(_last_head_pos + (now - _last_head_pos) * float(swept[0]))
		probes.append(_last_head_pos)
	q.motion = Vector3.ZERO
	for at in probes:
		q.transform = Transform3D(Basis(), at)
		for hit in space.intersect_shape(q, 8):
			var c = hit.get("collider")
			if c is Node and _try_break(c, now):
				return

	# AND THEN ASK THE MUSEUM, because a wall work is not there to be found.
	#
	# 2026-09-01, Palle: "The hammer does not destroy the wall works with the
	# text in VR." It could not: a showing is instances of a MultiMesh with NO
	# COLLIDER by contract, so no shape query will ever return one however wide
	# the head swings. The museum owns the wall works and already answers the
	# laser this way (on_beam_swept) — this is the same handshake, and the hammer
	# stays as ignorant of what a wall work is as the laser is.
	var tree := get_tree()
	if tree != null and tree.get_node_count_in_group("em_lethal") > 0:
		for m in tree.get_nodes_in_group("em_lethal"):
			if m.has_method("on_strike_swung") and bool(m.call("on_strike_swung",
					now, _strike_shape.radius * 2.0)):
				_cool = STRIKE_COOLDOWN
				_recent_speed = 0.0
				struck.emit(m, _head_speed)
				return


## Walk up from what was touched looking for something that knows how to break.
## Up, because the collider is almost never the artifact — it is a child of it,
## and an artifact that has to expose its own colliders to be hittable is an
## artifact that has to know it might be hit.
func _try_break(node: Node, from: Vector3) -> bool:
	var n: Node = node
	while n != null:
		if n == self or n.is_ancestor_of(self):
			return false
		if _broken.has(n):
			return false
		if n.has_method("strike"):
			if bool(n.call("strike", from, self)):
				# ONLY blacklist a target that is actually FINISHED. strike()
				# returns true for "that landed", not "that killed it", and a
				# target with hit points governs its own repeat-refusal. The
				# version before this appended on every landed blow, so one
				# hammer could hit a given barrier exactly ONCE, ever: hp went
				# 3 -> 2, the barrier leaned 7 degrees, and every later swing
				# returned false at the guard above without ever calling
				# strike(). That is the "it only tilts a bit" report, and it
				# had nothing to do with swing speed -- the tilt is only
				# reachable from INSIDE strike(), so it proves the sweep, the
				# mask, the parent walk and the speed gate all worked.
				var done: bool = (not is_instance_valid(n)) 					or (not n.has_method("is_broken")) 					or bool(n.call("is_broken"))
				_landed(n, done)
				return true
		elif n.has_method("trigger_explosion"):
			# THE LASER'S OWN CONTRACT, honoured without asking permission.
			# This one returns VOID, so the hammer cannot ask whether it
			# survived -- which is the one case where the blacklist is right.
			n.call("trigger_explosion")
			_landed(n, true)
			return true
		n = n.get_parent()
	return false


func _landed(target: Node, finished: bool = true) -> void:
	if finished:
		_broken.append(target)
	_cool = STRIKE_COOLDOWN
	struck.emit(target, _recent_speed)
	print("line_sledgehammer: struck %s at %.2f m/s" % [target.name, _recent_speed])
	_recent_speed = 0.0


func _mat(c: Color, rough: float, metal: float, glow: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	if glow > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow
	return m
