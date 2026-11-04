class_name PhysicsPlay
extends Node3D
## PHYSICS PLAY (Palle, 2026-11-03): "swap some of these for physical principles, like a physical sphere and a plank on
## top, the tyre and the boxes, but use jolt physics instead of simulation, add some more of these kinds of examples.
## Imagine the work just playing with the physics engine. This will be a precursor to the logical artifacts."
##
## One family, seven set-ups, each on its own mat. Nothing here is scripted motion: every loose body is a real Jolt
## RigidBody3D (an XRToolsPickable, so the desktop pointer and an XR hand grab, carry and throw the same body), the
## stands are static bodies, and the pendulum hangs on a real HingeJoint3D. NO BUTTONS (Palle, 2026-11-03: "remove the
## button and instead have a mechanism physically that release whatever process - I mean reset etc"): what holds a
## process is a thing in the world. Rollers rest against a GATE - a bar laid in two steel forks across the ramp - and
## lifting the bar out lets them go; the other set-ups are released by the act itself (push the first domino, throw
## or roll the ball, pull the bob aside and let go, push the heavy box off its ledge). RESET is a PLATE in the floor
## beside the mat: stand on it and every body goes back where it began. A body that leaves the floor goes home by
## itself. release() is what a hand does there, for the probes.
##   plank_on_ball   a plank laid across a ball: balance that cannot last
##   tyre_and_boxes  a tyre rolls down a ramp into a stack of four boxes (the source's tyre chain, without the logic)
##   dominoes        nine slabs; one push travels down the row
##   stack           a tower of five boxes and a ball thrown at it
##   pendulum        a bob on a hinge; the console times its swing against 2 pi sqrt(L / g)
##   seesaw          a plank on a fulcrum, a light box on one end, a heavy box dropped on the other
##   ramp_race       a ball, a cylinder and a box let go together down one slope

# built from the inventory (Palle, 2026-11-03: "we should use the prefabs created from primitives, the ones we have
# access to in the inventory"): a term of the grammar as its own body, and an item as the inventory carries it
const Composite := preload("res://commons/modular/composite.tscn")
const Carrier := preload("res://commons/player/inventory_carrier.gd")
const Items := preload("res://commons/player/inventory_items.gd")
const SETUPS := {
	"plank_on_ball": ["PLANK ON A BALL", "balance that cannot last"],
	"tyre_and_boxes": ["TYRE AND BOXES", "momentum passes into the stack"],
	"dominoes": ["DOMINOES", "one push, passed along"],
	"stack": ["A STACK AND A BALL", "what holds a tower up"],
	"pendulum": ["PENDULUM", "the swing keeps its own time"],
	"seesaw": ["SEESAW", "a heavy drop throws a light box"],
	"ramp_race": ["RAMP RACE", "rolling against sliding"],
	"extinguisher_ramp": ["EXTINGUISHER AND BOXES", "association(config(cylinder)) rolls into the inventory's boxes"],
	"propped_ramp": ["A PROPPED RAMP", "a board on cinder blocks; an oil drum rolls into the cans"],
	"tin_can_alley": ["TIN-CAN ALLEY", "ten cans on a shelf; throw the ball"],
	"bowling": ["BOWLING", "ten pins; the ball rolled"],
	"marble_run": ["MARBLE RUN", "a chute propped on a block; five marbles let go"],
}
const MAT_COLOR := Color("2c3036")
const BODY_LAYER := 1 | 4   # the world's layer (the player and the floor meet it) and the pickable layer (hands grab it)

@export_enum("plank_on_ball", "tyre_and_boxes", "dominoes", "stack", "pendulum", "seesaw", "ramp_race", "extinguisher_ramp", "propped_ramp", "tin_can_alley", "bowling", "marble_run") var setup := "plank_on_ball"

var bodies: Array[RigidBody3D] = []
var gates: Array[RigidBody3D] = []   # the bars that hold a ramp's rollers; lifted out, they let go
var plate: MeshInstance3D            # the reset plate's top
var _on_plate := false
var _plate_at := Vector3.ZERO
var _mat_size := Vector2.ONE
var _finger := 0.0
var homes: Dictionary = {}        # body -> [transform, frozen]
var released := false
var readout: Label3D
var _built := false
var _swing := {"last_sign": 0, "crossings": [], "period": 0.0, "t": 0.0}
var _race := {"t": 0.0, "order": []}

func apply_grid_config(config: Dictionary) -> void:
	if config.has("setup") and SETUPS.has(str(config.setup)) and str(config.setup) != setup:
		setup = str(config.setup)
		if _built: _build()

func _ready() -> void:
	if has_meta("config_setup") and SETUPS.has(str(get_meta("config_setup"))): setup = str(get_meta("config_setup"))
	_build()

func _build() -> void:
	for c in get_children(): c.queue_free()
	bodies.clear(); gates.clear(); homes.clear(); released = false; _on_plate = false
	_swing = {"last_sign": 0, "crossings": [], "period": 0.0, "t": 0.0}; _race = {"t": 0.0, "order": []}
	var size: Vector2 = {"plank_on_ball": Vector2(2.6, 1.4), "tyre_and_boxes": Vector2(4.4, 1.4), "dominoes": Vector2(4.2, 1.0),
		"stack": Vector2(3.0, 1.6), "pendulum": Vector2(2.4, 1.2), "seesaw": Vector2(3.0, 1.2), "ramp_race": Vector2(3.8, 1.8), "extinguisher_ramp": Vector2(4.4, 1.4), "propped_ramp": Vector2(4.4, 1.6), "tin_can_alley": Vector2(3.8, 1.6), "bowling": Vector2(4.8, 1.4), "marble_run": Vector2(2.8, 1.0)}[setup]
	_mat_size = size
	_static_box("Mat", Vector3(0, .02, 0), Vector3(size.x, .04, size.y), MAT_COLOR)
	call("_setup_" + setup)
	_reset_plate(size)
	for b in bodies: homes[b] = [b.transform, b.freeze]
	_built = true

## --- the set-ups (local metres; the mat's top is y 0.04) -----------------------------------------------------------

## From the inventory: the beach ball (association(config(sphere))) and the 2 m timber plank laid across it.
func _setup_plank_on_ball() -> void:
	var ball := _term_body("Ball", "beach_ball", 3.0)
	if ball:
		ball.position = Vector3(0, .04, 0); ball.angular_damp = .4   # the floor is not ice: a resting ball comes to rest
	var plank := _inventory_body("Plank", "plank2", Vector3(0, 0, 0), 0)
	if plank: _rest_on(plank, .04 + .6 + .002)

func _setup_tyre_and_boxes() -> void:
	_ramp("Ramp", -2.1, -.7, .8, 1.0)          # x from, x to, rise, width
	_static_box("RampTop", Vector3(-2.1, .4 + .02, 0), Vector3(.2, .8, 1.0), Color("6f767e"))
	# from the inventory: the tyre (association(config(torus))), stood on its tread, and three cardboard boxes
	var slope := atan2(.8, 1.4)
	var tyre := _term_body("Tyre", "tyre", 8.0)
	if tyre:
		var stand := Basis(Vector3(1, 0, 0), deg_to_rad(90))   # the ring's axis along z: it rolls down x
		var g := _gate_on_ramp(-2.1, -.7, .8, -1.05, .9)
		var centre := _roll_to(_on_ramp(-2.1, -.7, .8, -1.95, .342), slope, .342, g)
		tyre.transform = Transform3D(stand, centre - stand * Vector3(0, .06, 0))
	for i in 3:
		var box := _inventory_body("Cardboard%d" % i, "cardboard", Vector3(.9, 0, 0), i)
		if box: box.mass = .4
	_static_box("Buffer", Vector3(2.15, .04 + .2, 0), Vector3(.1, .4, 1.4), Color("3b4048"))

## From the inventory: twelve domino tiles (association(config(cube))), 30 cm tall, a fifth of a metre apart.
func _setup_dominoes() -> void:
	for i in 12:
		var tile := _term_body("Domino%d" % i, "domino_tile", .5)
		if tile: tile.position = Vector3(-1.65 + i * .2 + .025, .04, 0)

func _setup_stack() -> void:
	# from the inventory: four cardboard boxes stacked, and the rubber ball (association(config(point))) to throw
	for i in 4:
		var box := _inventory_body("Cardboard%d" % i, "cardboard", Vector3(.7, 0, 0), i)
		if box: box.mass = .4
	var ball := _term_body("Ball", "rubber_ball", 1.5)
	if ball:
		ball.position = Vector3(-1.2, .04, 0)   # on the mat: a hand takes it and throws

func _setup_pendulum() -> void:
	_static_box("PostA", Vector3(0, 1.15, -.5), Vector3(.08, 2.3, .08), Color("6f767e"))
	_static_box("PostB", Vector3(0, 1.15, .5), Vector3(.08, 2.3, .08), Color("6f767e"))
	var beam := _static_box("Beam", Vector3(0, 2.3, 0), Vector3(.1, .1, 1.1), Color("6f767e"))
	# from the inventory: the rubber ball (association(config(point))) is the bob, the hinge sits at the pivot
	var bob := _term_body("Bob", "rubber_ball", 3.0)
	if bob == null: bob = _sphere("Bob", Vector3(0, 2.3 - 1.6, 0), .18, 3.0, Color("e04f7a"))
	else: bob.position = Vector3(0, 2.3 - 1.6 - .11, 0)   # the term's origin is its base; its centre 0.11 above
	var plate := _term_body("HingePlate", "hinge", .3)
	if plate:
		bodies.erase(plate); plate.freeze = true; plate.collision_layer = 0; plate.collision_mask = 0   # a fitting, not a loose body
		plate.position = Vector3(0, 2.35, 0); plate.rotation_degrees = Vector3(0, 90, 0)
	var rod := MeshInstance3D.new(); rod.name = "Rod"; var cyl := CylinderMesh.new(); cyl.top_radius = .012; cyl.bottom_radius = .012; cyl.height = 1.6
	rod.mesh = cyl; rod.position = Vector3(0, .8 + (.11 if bob.name == "Bob" and bob.get_script() != null else 0.0), 0); rod.material_override = _mat(Color("2a2d33")); bob.add_child(rod)
	var hinge := HingeJoint3D.new(); hinge.name = "Hinge"; hinge.position = Vector3(0, 2.3, 0)
	# a HingeJoint3D turns about its own z: unrotated, the bob swings in the x-y plane
	add_child(hinge); hinge.node_a = hinge.get_path_to(beam); hinge.node_b = hinge.get_path_to(bob)
	bob.angular_damp = 0; bob.linear_damp = 0

func _setup_seesaw() -> void:
	_ramp("FulcrumL", 0, -.25, .35, .5); _ramp("FulcrumR", 0, .25, .35, .5)   # a ridge at x 0
	# it starts as it settles: the light end resting on the mat, the plank tipped about the ridge
	# the plank's underside on the ridge (0, 0.39), its low end's underside on the mat (y 0.04)
	var tip := asin((.39 - .04) / 1.3); var turn := Basis(Vector3(0, 0, 1), tip); var pivot := Vector3(0, .39, 0) + turn * Vector3(0, .025, 0)
	var plank := _box("Plank", pivot, Vector3(2.6, .05, .34), 3.0, Color("b98a55")); plank.rotation.z = tip
	var light := _box("LightBox", pivot + turn * Vector3(-1.1, .025 + .15, 0), Vector3(.3, .3, .3), .6, Color("f2efe8")); light.rotation.z = tip
	# the heavy box waits on a ledge beside the raised end: push it off and it drops onto the plank
	_static_box("LedgePost", Vector3(1.1, .78, .62), Vector3(.05, 1.48, .05), Color("6f767e"))
	_static_box("Ledge", Vector3(1.1, 1.52, .5), Vector3(.5, .04, .36), Color("6f767e"))
	_box("HeavyBox", Vector3(1.1, 1.54 + .18 + .002, .5), Vector3(.36, .36, .36), 6.0, Color("3b4048"))

func _setup_ramp_race() -> void:
	_ramp("Slope", -1.7, .5, .6, 1.6)
	_static_box("Top", Vector3(-1.8, .3 + .02, 0), Vector3(.2, .6, 1.6), Color("6f767e"))
	# each racer resting on the slope at x -1.4: its centre a radius (or half a side) off the surface, along the normal
	var slope := atan2(.6, 2.2); var n := Vector3(sin(slope), cos(slope), 0); var at := Vector3(-1.4, _slope_y(-1.7, .5, .6, -1.4), 0)
	# from the inventory: the rubber ball (point), the extinguisher (cylinder) on its side, the die (cube)
	var g := _gate_on_ramp(-1.7, .5, .6, -1.15, .9)
	var a := _term_body("Ball", "rubber_ball", 1.0)
	if a: a.position = _roll_to(_on_ramp(-1.7, .5, .6, -1.6, .112) + Vector3(0, 0, -.6), slope, .112, g) - Vector3(0, .11, 0)
	var b := _term_body("Extinguisher", "fire_extinguisher", 3.0)
	if b:
		var lie := Basis(Vector3(1, 0, 0), deg_to_rad(90))
		b.transform = Transform3D(lie, _roll_to(_on_ramp(-1.7, .5, .6, -1.6, .088), slope, .088, g) - lie * Vector3(0, .3, 0))
	var c := _term_body("Dice", "dice", 1.0)
	if c:
		var flat := Basis(Vector3(0, 0, 1), -slope)
		c.transform = Transform3D(flat, _roll_to(_on_ramp(-1.7, .5, .6, -1.6, .081) + Vector3(0, 0, .6), slope, .095, g) - flat * Vector3(0, .08, 0))
	if c:
		c.physics_material_override = PhysicsMaterial.new(); c.physics_material_override.friction = .1   # measured (ada_run/physics_play_friction): the order flips at 0.06-0.09 = tan 15 / 3; at 0.1 it slides slower than the rollers roll (ball, cylinder, box) and still crosses the line
	_static_box("FinishLine", Vector3(.9, .045, 0), Vector3(.04, .01, 1.6), Color("f2efe8"))
	_static_box("Buffer", Vector3(1.85, .04 + .15, 0), Vector3(.1, .3, 1.8), Color("3b4048"))   # nothing rolls off the floor

## The pilot of the associations: the fire extinguisher (fire_extinguisher = association(config(cylinder)), a term of
## commons/modular/terms.json, a grabbable body with a cylinder collider) lies held across the top of a ramp; three of
## the inventory's own cardboard boxes (items.json "cardboard", built as the inventory builds them, InventoryCarrier)
## stand stacked at its foot. Lift the gate: it rolls.
func _setup_extinguisher_ramp() -> void:
	_ramp("Ramp", -2.1, -.7, .8, 1.0)
	_static_box("RampTop", Vector3(-2.1, .4 + .02, 0), Vector3(.2, .8, 1.0), Color("6f767e"))
	var slope := atan2(.8, 1.4)
	var ext := _term_body("Extinguisher", "fire_extinguisher", 6.0)   # a 6 kg extinguisher
	if ext:
		# on its side across the slope (axis along z, so it rolls down x), its cylinder's centre a radius off the surface
		var lie := Basis(Vector3(1, 0, 0), deg_to_rad(90))
		var g := _gate_on_ramp(-2.1, -.7, .8, -1.25, .9)
		var axis_mid := _roll_to(_on_ramp(-2.1, -.7, .8, -1.95, .087), slope, .087, g)
		ext.transform = Transform3D(lie, axis_mid - lie * Vector3(0, .3, 0))
	for i in 3:
		var box := _inventory_body("Cardboard%d" % i, "cardboard", Vector3(.9, 0, 0), i)
		if box: box.mass = .4   # an empty cardboard box
	_static_box("Buffer", Vector3(2.15, .04 + .2, 0), Vector3(.1, .4, 1.4), Color("3b4048"))

## A term of the grammar standing as its own body: the composite builds it, the grabbable root is the body.
func _term_body(n: String, term: String, mass := 6.0) -> RigidBody3D:
	var c: Node3D = Composite.instantiate(); c.name = n + "Term"; c.set("term", term); add_child(c)
	var body: RigidBody3D = null
	for r in c.find_children("*", "RigidBody3D", true, false):
		body = r; break
	if body == null: return null
	body.name = n; body.reparent(self, false); c.queue_free()
	body.collision_layer = BODY_LAYER; body.collision_mask = 1; body.continuous_cd = true
	body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE; body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE; body.linear_damp = .02; body.angular_damp = .05
	body.mass = mass
	# a grabbable term sits frozen until a hand first takes it; in a play it is a body from the start (a set-up
	# that needs a hold uses a gate, and lifting the gate lets go)
	body.freeze = false
	bodies.append(body); return body

## An item as the inventory carries it (InventoryCarrier), stacked `level` high on the mat at `at`. Its grid snap
## is left out here: at rest the sand-block rule would freeze a box before anything could reach it.
func _inventory_body(n: String, id: String, at: Vector3, level: int) -> RigidBody3D:
	var it: Dictionary = Items.item(id).duplicate(true)
	if it.is_empty(): return null
	it.erase("snap")
	# an item that is a pickable of its own (the timber plank) is used as it is, as the inventory hand holds it
	var path := Items.scene_for(str(it.get("token", "")))
	if path != "" and ResourceLoader.exists(path):
		var inst: Node = load(path).instantiate()
		if inst is RigidBody3D:
			var own: RigidBody3D = inst; own.name = n
			for k in it.get("defaults", {}): own.set_meta("config_%s" % str(k), it.defaults[k])
			add_child(own)
			own.freeze = false; own.collision_layer = BODY_LAYER; own.collision_mask = 1
			if own.get("release_mode") != null: own.set("release_mode", 1)   # XRToolsPickable.ReleaseMode.UNFROZEN: a body when let go
			own.position = Vector3(at.x, .04 + .002, at.z)
			bodies.append(own); return own
		inst.free()
	var c: RigidBody3D = Carrier.new(); c.name = n; add_child(c)
	if not c.build(it, (it.get("defaults", {}) as Dictionary).duplicate()):
		c.queue_free(); return null
	var e: AABB = c.extent
	c.position = Vector3(at.x - e.get_center().x, .04 - e.position.y + level * e.size.y + .002, at.z - e.get_center().z)
	bodies.append(c); return c

## Stand a body so its lowest mesh point is at height y (in this node's space), keeping x and z.
func _rest_on(b: Node3D, y: float) -> void:
	var low := INF
	for mi in b.find_children("*", "MeshInstance3D", true, false):
		var t: Transform3D = global_transform.affine_inverse() * (mi as MeshInstance3D).global_transform
		var a: AABB = (mi as MeshInstance3D).get_aabb()
		for i in 8: low = minf(low, (t * a.get_endpoint(i)).y)
	if low < INF: b.position.y += y - low

## From the inventory: two cinder blocks stacked prop the wooden board as a ramp; the oil drum is held on its side
## at the top; six tin cans stand in a pyramid at the foot. Cinder blocks are what props things up (Palle).
func _setup_propped_ramp() -> void:
	for i in 2:
		var cb := _term_body("CinderBlock%d" % i, "cinder_block", 12.0)
		if cb: cb.position = Vector3(-1.75, .04 + i * .19 + .001, 0)
	var rise := .04 + .38 + .002 - .04; var tip := asin(rise / 1.2); var top := Vector3(-1.62, .422, 0)
	var foot := top + Vector3(cos(tip), -sin(tip), 0) * 1.2
	var board := _term_body("Board", "wooden_board", 4.0)
	if board: board.transform = Transform3D(Basis(Vector3(0, 0, 1), -tip), (top + foot) * .5 - Basis(Vector3(0, 0, 1), -tip) * Vector3(0, 0, 0))
	var drum := _term_body("OilDrum", "oil_drum", 15.0)
	if drum:
		var lie := Basis(Vector3(1, 0, 0), deg_to_rad(90))
		# the board's top face: its underside line from the block's edge to the floor, raised by its 2.5 cm
		var n := Vector3(sin(tip), cos(tip), 0); var t := Vector3(cos(tip), -sin(tip), 0)
		var face_pt := top + n * .025 + t * .72
		var g := _gate(face_pt.x, face_pt.y + .004, .55)
		var on := _roll_to(top + n * (.025 + .292) + t * .1, tip, .292, g)
		drum.transform = Transform3D(lie, on - lie * Vector3(0, .44, 0))
	var c_n := 0
	for row in 3:
		for k in 3 - row:
			var can := _term_body("Can%d" % c_n, "tin_can", .35); c_n += 1
			if can: can.position = Vector3(1.1, .04 + row * .121, (k - (2 - row) * .5) * .086)

## From the inventory: a wooden board laid across two cinder blocks is the shelf; ten tin cans stand on it (4-3-2-1);
## the rubber ball is thrown at them.
func _setup_tin_can_alley() -> void:
	for z in [-.42, .42]:
		var cb := _term_body("CinderBlock%d" % int(z > 0), "cinder_block", 12.0)
		if cb: cb.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(90)), Vector3(1.0, .041, z))
	var shelf := _term_body("Shelf", "wooden_board", 4.0)
	if shelf: shelf.transform = Transform3D(Basis(Vector3.UP, deg_to_rad(90)), Vector3(1.0, .04 + .19 + .002, 0))
	var n := 0
	for row in 4:
		for k in 4 - row:
			var can := _term_body("Can%d" % n, "tin_can", .35); n += 1
			if can: can.position = Vector3(1.0, .04 + .19 + .025 + .002 + row * .121, (k - (3 - row) * .5) * .086)
	var ball := _term_body("Ball", "rubber_ball", 1.0)
	if ball: ball.position = Vector3(-1.5, .04, 0)   # on the mat: a hand takes it and throws

## From the inventory: ten bowling pins in their triangle; the rubber ball, at a bowling ball's 5 kg, rolled at them.
func _setup_bowling() -> void:
	var n := 0
	for row in 4:
		for k in row + 1:
			var pin := _term_body("Pin%d" % n, "bowling_pin", 1.5); n += 1
			if pin: pin.position = Vector3(1.0 + row * .26, .04, (k - row * .5) * .3)
	var ball := _term_body("Ball", "rubber_ball", 5.0)
	if ball: ball.position = Vector3(-1.9, .04, .07)   # on the mat, in line with the pocket: a hand rolls it

## From the inventory: the marble chute propped on a cinder block; five marbles held at its top end.
func _setup_marble_run() -> void:
	var cb := _term_body("CinderBlock", "cinder_block", 12.0)
	if cb: cb.position = Vector3(-1.0, .041, 0)
	var top := Vector3(-.92, .04 + .19 + .002, 0); var tip := asin((.19 + .002) / 1.2)
	var foot := top + Vector3(cos(tip), -sin(tip), 0) * 1.2
	var chute := _term_body("Chute", "marble_chute", 1.5)
	if chute: chute.transform = Transform3D(Basis(Vector3(0, 0, 1), -tip), (top + foot) * .5)
	# the hold is the inventory's door stop (association(config(wedge))), laid in the channel in front of the marbles:
	# lift it out and they run. It fits between the chute's walls; the marbles queue behind it.
	var t := Vector3(cos(tip), -sin(tip), 0); var n := Vector3(sin(tip), cos(tip), 0)
	var floor_at := func(d: float) -> Vector3: return top + n * .0125 + t * d   # the channel floor, d along from the top
	var stop := _term_body("DoorStop", "door_stop", .3)
	if stop:
		stop.transform = Transform3D(Basis(Vector3(0, 0, 1), -tip), floor_at.call(.4) + n * .002)
		gates.append(stop)
	for i in 5:
		var m := _term_body("Marble%d" % i, "marble", .02)
		if m:
			var c: Vector3 = floor_at.call(.4 - .07 - .021 - i * .041) + n * .0205
			m.position = c - Vector3(0, .02, 0)

## THE GATE: the inventory's 2 m timber plank, on its edge across the ramp, in two steel forks at z +-half (outside the
## rollers). Its uphill face at x = face_x, its underside at y = bottom. Rollers rest against it; lifting it out of the
## forks is the release. Returns [face_x, bottom, top, depth] for _roll_to.
func _gate(face_x: float, bottom: float, half: float) -> Array:
	var bar := _inventory_body("Gate", "plank2", Vector3.ZERO, 0)
	var depth := .06; var height := .25
	if bar:
		bar.transform = Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3.ZERO)   # length along z, width up, thickness along x
		var box := _mesh_box(bar)
		bar.position += Vector3(face_x - box.position.x, bottom - box.position.y, -box.get_center().z)
		depth = box.size.x; height = box.size.y
		gates.append(bar)
	var steel := Color("5b6166")
	for z in [-half, half]:
		_static_box("ForkSaddle", Vector3(face_x + depth * .5, bottom - .01, z), Vector3(depth + .08, .02, .05), steel)
		_static_box("ForkDown", Vector3(face_x + depth + .012, bottom + height * .35, z), Vector3(.02, height * .7, .05), steel)
		_static_box("ForkUp", Vector3(face_x - .012, bottom + height * .2, z), Vector3(.02, height * .4, .05), steel)
		var leg := bottom - .02 - .04
		if leg > .01: _static_box("ForkLeg", Vector3(face_x + depth * .5, .04 + leg * .5, z), Vector3(.035, leg, .035), steel)
	return [face_x, bottom, bottom + height, depth]

## A gate across a _ramp at face_x, its underside just over the slope there.
func _gate_on_ramp(x0: float, x1: float, rise: float, face_x: float, half: float) -> Array:
	return _gate(face_x, _slope_y(x0, x1, rise, face_x) + .004, half)

## A roller of radius r resting on a _ramp near x: its centre.
func _on_ramp(x0: float, x1: float, rise: float, x: float, r: float) -> Vector3:
	var th := atan2(rise, absf(x1 - x0))
	return Vector3(x, _slope_y(x0, x1, rise, x), 0) + Vector3(sin(th), cos(th), 0) * r

## Slide a roller's centre down the slope (angle th) from start until it touches the gate - its face, or its top edge -
## so it begins at rest against the bar, not falling onto it.
func _roll_to(start: Vector3, th: float, r: float, g: Array) -> Vector3:
	var t := Vector3(cos(th), -sin(th), 0); var c := start
	for i in 4000:
		var nx := clampf(c.x, g[0], g[0] + g[3]); var ny := clampf(c.y, g[1], g[2])
		if Vector2(c.x - nx, c.y - ny).length() <= r + .002: return c - t * .001
		c += t * .001
	return start

## A body's mesh box in this node's space.
func _mesh_box(b: Node3D) -> AABB:
	var box := AABB(); var first := true
	for mi in b.find_children("*", "MeshInstance3D", true, false):
		var tr: Transform3D = global_transform.affine_inverse() * (mi as MeshInstance3D).global_transform
		var a: AABB = (mi as MeshInstance3D).get_aabb()
		for i in 8:
			var q := tr * a.get_endpoint(i)
			if first: box = AABB(q, Vector3.ZERO); first = false
			else: box = box.expand(q)
	return box

## --- release, reset, readouts --------------------------------------------------------------------------------------

## What a hand does to start the process (the probes call it; in the game the visitor does it), in the set-up's own
## frame (a velocity is the world's, so every push and throw is turned with the set-up): lift the gate out of
## its forks, push the first domino, throw or roll the ball, pull the bob aside and let go, push the box off its ledge.
func release() -> void:
	released = true
	for g in gates:   # lifted out of the forks and set down behind the mat, a free body again
		g.freeze = false; g.sleeping = false
		_place(g, Transform3D(g.transform.basis, Vector3(-_mat_size.x * .5 - .45, .5, g.transform.origin.z)))   # behind the ramp's top end, clear of every lane
	match setup:
		"dominoes":
			_finger = .25   # a finger presses the first tile near its top for a quarter of a second (see _physics_process)
		"plank_on_ball":
			bodies[1].apply_impulse(global_basis * Vector3(0, -.6, 0), global_basis * Vector3(.9, 0, 0))   # press one end
		"stack":
			var ball: RigidBody3D = bodies.back(); _place(ball, Transform3D(ball.transform.basis, ball.transform.origin + Vector3(0, .4, 0))); ball.linear_velocity = global_basis * Vector3(8.0, 2.0, 0)
		"tin_can_alley":
			var ball: RigidBody3D = bodies.back(); _place(ball, Transform3D(ball.transform.basis, ball.transform.origin + Vector3(0, .25, 0))); ball.linear_velocity = global_basis * Vector3(7.5, 1.3, 0)
		"bowling":
			var ball: RigidBody3D = bodies.back(); ball.linear_velocity = global_basis * Vector3(7.0, 0, 0)
		"seesaw":
			var heavy: RigidBody3D = bodies[2]; heavy.linear_velocity = global_basis * Vector3(0, 0, -1.6)
		"pendulum":
			var bob: RigidBody3D = bodies[0]
			var a := deg_to_rad(40.0)
			var centre := Vector3(1.6 * sin(a), 2.3 - 1.6 * cos(a), 0); var turn := Basis(Vector3(0, 0, 1), a)
			_place(bob, Transform3D(turn, centre - turn * Vector3(0, (.11 if bob.get_script() != null and bob.get_script().resource_path.ends_with("pickable.gd") else 0.0), 0)))
			_swing = {"last_sign": 0, "crossings": [], "period": 0.0, "t": 0.0}
		"ramp_race":
			_race = {"t": 0.0, "order": []}
	for b in bodies:   # a body asleep against its gate does not notice the gate has gone: wake them all
		if not (b in gates): b.sleeping = false
	_say()

func reset() -> void:
	released = false
	for b in bodies:
		# wake it, put it home, then hold it: a body asleep for a while and frozen first is not moved by a new transform
		b.freeze = false; b.sleeping = false
		_place(b, homes[b][0])
		b.freeze = homes[b][1]
	_swing = {"last_sign": 0, "crossings": [], "period": 0.0, "t": 0.0}; _race = {"t": 0.0, "order": []}
	_say()

func _place(b: RigidBody3D, t: Transform3D) -> void:
	b.transform = t; b.linear_velocity = Vector3.ZERO; b.angular_velocity = Vector3.ZERO
	PhysicsServer3D.body_set_state(b.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, b.global_transform)
	PhysicsServer3D.body_set_state(b.get_rid(), PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, Vector3.ZERO)
	PhysicsServer3D.body_set_state(b.get_rid(), PhysicsServer3D.BODY_STATE_ANGULAR_VELOCITY, Vector3.ZERO)

func _physics_process(delta: float) -> void:
	if bodies.is_empty(): return
	var on := _plate_pressed()
	if on and not _on_plate: reset()
	_on_plate = on
	if plate: plate.position.y = _plate_at.y + (.012 if on else .022)   # it gives under the foot
	if _finger > 0.0 and setup == "dominoes":
		var first: RigidBody3D = bodies[0]; first.freeze = false; first.sleeping = false
		first.apply_force(global_basis * Vector3(3.0, 0, 0), global_basis * Vector3(0, .25, 0)); _finger -= delta
	for b in bodies:   # a body thrown off the floor or out of the room goes home
		if not b.is_picked_up() and (to_local(b.global_position).y < -2.0 or to_local(b.global_position).length() > 14.0):
			b.freeze = homes[b][1]; _place(b, homes[b][0])
	if setup == "pendulum":
		var bob := bodies[0]; _swing.t += delta
		var x := to_local(bob.global_position).x; var s := int(signf(x))
		if s != 0 and _swing.last_sign != 0 and s != _swing.last_sign:
			_swing.crossings.append(_swing.t)
			if _swing.crossings.size() >= 3:
				var c: Array = _swing.crossings; _swing.period = float(c[-1]) - float(c[-3]); _say()
		if s != 0: _swing.last_sign = s
	if setup == "ramp_race" and released:
		_race.t += delta
		for b in bodies:
			if not (b.name in _race.order) and to_local(b.global_position).x > .9:
				_race.order.append(b.name); _say()

func _say() -> void:
	if readout == null: return
	var title: Array = SETUPS[setup]
	var line := "%s\n%s" % [title[0], title[1]]
	if setup == "pendulum":
		var expected := TAU * sqrt(1.6 / 9.8)
		line += "\nmeasured %s s  /  2 pi sqrt(L/g) = %.2f s" % [("%.2f" % _swing.period) if _swing.period > 0 else "-", expected]
	if setup == "ramp_race" and not _race.order.is_empty():
		line += "\n" + "  ".join(_race.order.map(func(n): return str(n).to_lower()))
	readout.text = line

## --- building blocks -----------------------------------------------------------------------------------------------

func _mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = .75; return m

func _static_box(n: String, at: Vector3, size: Vector3, c: Color) -> StaticBody3D:
	var s := StaticBody3D.new(); s.name = n; s.position = at
	var mi := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = size; mi.mesh = bm; mi.material_override = _mat(c); s.add_child(mi)
	var cs := CollisionShape3D.new(); var sh := BoxShape3D.new(); sh.size = size; cs.shape = sh; s.add_child(cs)
	add_child(s); return s

## A slope as a static prism: from x0 (rise high) down to x1 (0), width along z.
func _ramp(n: String, x0: float, x1: float, rise: float, width: float) -> void:
	var s := StaticBody3D.new(); s.name = n; s.position = Vector3(0, .04, 0)
	var p := PackedVector3Array()
	for z in [-width / 2, width / 2]:
		p.append(Vector3(x0, 0, z)); p.append(Vector3(x1, 0, z)); p.append(Vector3(x0, rise, z))
	var cs := CollisionShape3D.new(); var sh := ConvexPolygonShape3D.new(); sh.points = p; cs.shape = sh; s.add_child(cs)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var tris := [[0, 2, 1], [3, 4, 5], [0, 1, 4], [0, 4, 3], [1, 2, 5], [1, 5, 4], [2, 0, 3], [2, 3, 5]]
	for t in tris:
		for i in t: st.add_vertex(p[i])
	st.generate_normals()
	var mi := MeshInstance3D.new(); mi.mesh = st.commit(); mi.material_override = _mat(Color("6f767e")); mi.material_override.cull_mode = BaseMaterial3D.CULL_DISABLED
	s.add_child(mi); add_child(s)

## The surface height of a _ramp at x (its top at x0, its foot at x1), over the mat.
func _slope_y(x0: float, x1: float, rise: float, x: float) -> float:
	return .04 + rise * (x1 - x) / (x1 - x0)

func _body(n: String, at: Vector3, mass: float, shape: Shape3D, mesh: Mesh, c: Color) -> RigidBody3D:
	var b := XRToolsPickable.new(); b.name = n; b.position = at; b.mass = mass
	b.collision_layer = BODY_LAYER; b.collision_mask = 1
	b.continuous_cd = true; b.can_sleep = true
	# air, not syrup: the project default damps every body; here only a breath of it, so a roll and a swing carry
	b.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE; b.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE; b.linear_damp = .02; b.angular_damp = .05
	b.release_mode = XRToolsPickable.ReleaseMode.UNFROZEN
	var pm := PhysicsMaterial.new(); pm.friction = .6; pm.bounce = .05; b.physics_material_override = pm
	var cs := CollisionShape3D.new(); cs.shape = shape; b.add_child(cs)
	var mi := MeshInstance3D.new(); mi.mesh = mesh; mi.material_override = _mat(c); b.add_child(mi)
	add_child(b); bodies.append(b); return b

func _box(n: String, at: Vector3, size: Vector3, mass: float, c: Color) -> RigidBody3D:
	var sh := BoxShape3D.new(); sh.size = size; var m := BoxMesh.new(); m.size = size
	return _body(n, at, mass, sh, m, c)

func _sphere(n: String, at: Vector3, r: float, mass: float, c: Color) -> RigidBody3D:
	var sh := SphereShape3D.new(); sh.radius = r; var m := SphereMesh.new(); m.radius = r; m.height = 2 * r
	return _body(n, at, mass, sh, m, c)

## A cylinder lying with its axis along z (a wheel that rolls along x).
func _cylinder(n: String, at: Vector3, r: float, width: float, mass: float, c: Color) -> RigidBody3D:
	var sh := CylinderShape3D.new(); sh.radius = r; sh.height = width
	var m := CylinderMesh.new(); m.top_radius = r; m.bottom_radius = r; m.height = width
	var b := _body(n, at, mass, sh, m, c)
	b.rotation_degrees = Vector3(90, 0, 0)
	return b

## THE RESET PLATE: a steel plate in the floor beside the mat. Stand on it and every body goes back where it began
## (the visitor's own weight is the mechanism, desktop and XR alike). The readout stands on its post beside it.
func _reset_plate(size: Vector2) -> void:
	_plate_at = Vector3(size.x / 2 - .45, 0, size.y / 2 + .6)
	var base := _static_box("ResetPlateFrame", _plate_at + Vector3(0, .01, 0), Vector3(.76, .02, .76), Color("3b4048"))
	base.collision_layer = 0
	plate = MeshInstance3D.new(); plate.name = "ResetPlate"; var bm := BoxMesh.new(); bm.size = Vector3(.66, .02, .66); plate.mesh = bm
	plate.material_override = _mat(Color("9aa3a8")); plate.position = _plate_at + Vector3(0, .022, 0); add_child(plate)
	var word := Label3D.new(); word.text = "STAND HERE TO RESET"; word.font_size = 36; word.pixel_size = .0014; word.modulate = Color("1c1c1e")
	word.rotation_degrees.x = -90; word.position = _plate_at + Vector3(0, .034, 0); add_child(word)
	_static_box("ReadoutPost", Vector3(size.x / 2 - .25, .5 + .04, size.y / 2 + .15), Vector3(.05, 1.0, .05), Color("3b4048"))
	readout = Label3D.new(); readout.name = "Readout"; readout.font_size = 40; readout.pixel_size = .0016
	readout.position = Vector3(size.x / 2 - .25, 1.32, size.y / 2 + .15); readout.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	readout.modulate = Color("f2efe8"); readout.outline_size = 8; add_child(readout)
	_say()

## A visitor standing on the plate: feet on the floor, within it. Fires once per stepping on.
func _plate_pressed() -> bool:
	for body in get_tree().get_nodes_in_group("player_body"):
		if not body is CharacterBody3D or not (body as CharacterBody3D).is_on_floor(): continue
		var feet := to_local((body as Node3D).global_position) - _plate_at
		if absf(feet.x) < .38 and absf(feet.z) < .38 and absf(feet.y) < .2: return true
	return false

## The state for probes: the set-up, each body's place and speed, the readouts.
func get_state() -> Dictionary:
	var out := {"setup": setup, "released": released, "bodies": {}, "period": _swing.period, "race": _race.order.duplicate()}
	for b in bodies:
		out.bodies[str(b.name)] = {"at": to_local(b.global_position), "home": (homes[b][0] as Transform3D).origin, "speed": b.linear_velocity.length(), "frozen": b.freeze}
	return out
