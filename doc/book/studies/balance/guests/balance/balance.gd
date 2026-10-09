extends Node3D
## The Balance guest: the kit's table for the room. A plate on posts with three
## members of a family stacked on it, held for a second and then let go. A label
## counts what falls, by listening to the guest's own signal `fallen`. The plate
## feels a walker who stands on it and takes its weight. Everything it needs is in
## this folder: the kit's colours are written out, there is no plumb line (that
## needs a supplied part), and it declares no class_name.
## `rider`: a scene of yours, stood on top of the stack as one more member. Its
## look is kept; its own colliders are switched off and a box around its meshes
## is what collides; it weighs 2 kg, as the members do.

signal fallen(body: RigidBody3D)          # a body of the table has turned more than 20 degrees from upright

const BODY := Color("c6ff3d")             # the kit's BODY, written out
const SECOND := Color("22d9ff")           # SECOND
const THIRD := Color("ff8b1f")            # THIRD
const BONE := Color("f4efe6")             # BONE
const GHOST := Color("9b7bff")            # GHOST
const INK := Color("ffffff")              # INK
const SHADE := Color("0d0620")            # SHADE
const BODIES: Array[Color] = [BODY, SECOND, THIRD, BONE]
const POST := Vector3(0.08, 0.3, 0.08)    # metres: a post
const PLATE := Vector3(1.2, 0.06, 0.8)    # metres: the plate
const EDGE := 0.24                        # metres: a member, a cube

@export_range(2, 4) var legs := 4         # posts under the plate
@export var mass := 10.0                  # kilograms, of the plate
@export var offset := 0.0                 # metres: the plate's centre of mass, from its middle towards +x
@export var hold := 1.0                   # seconds before the plate is let go
@export var members := 3                  # members of the family stacked on the plate
@export var lean := 0.04                  # metres: each member this much further to +x than the one below
@export var walker_mass := 60.0           # kilograms: what a walker standing on the plate weighs on it
@export var rider: PackedScene            # a body of yours on top of the stack; empty: none

var plate: RigidBody3D
var words: Label3D
var clock := 0.0
var falls := 0
var bodies: Array[RigidBody3D] = []
var down: Array[RigidBody3D] = []
var standing: Array[CharacterBody3D] = []

func _ready() -> void:
	for spot: Vector2 in spots():
		var post := StaticBody3D.new()
		post.position = Vector3(spot.x, POST.y / 2.0, spot.y)
		dress(post, POST, SECOND)
		add_child(post)
	plate = RigidBody3D.new()
	plate.name = "Plate"
	plate.position = Vector3(0, POST.y + PLATE.y / 2.0 + 0.01, 0)   # 1 cm above the posts
	plate.mass = mass
	plate.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	plate.center_of_mass = Vector3(offset, 0, 0)
	plate.freeze = true
	dress(plate, PLATE, BODY)
	add_child(plate)
	bodies.append(plate)
	mark()
	stack()
	if rider != null:
		ride()
	feel()
	words = Label3D.new()
	words.text = "fallen: 0"
	words.pixel_size = 0.004
	words.font_size = 48
	words.modulate = INK
	words.outline_modulate = SHADE
	words.outline_size = 12
	words.position = Vector3(0, 1.5, 0)
	add_child(words)
	fallen.connect(count)

## Where the posts stand, seen from above: x to the right, y towards you.
func spots() -> Array:
	if legs == 2:
		return [Vector2(-0.3, -0.2), Vector2(0.3, 0.2)]
	if legs == 3:
		return [Vector2(-0.3, -0.2), Vector2(-0.3, 0.2), Vector2(0.3, 0)]
	return [Vector2(-0.3, -0.2), Vector2(0.3, -0.2), Vector2(0.3, 0.2), Vector2(-0.3, 0.2)]

func paint(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.8
	material.metallic = 0.0
	return material

## A box to see, and the same box to collide with.
func dress(body: Node3D, size: Vector3, colour: Color) -> void:
	var skin := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	skin.mesh = box
	skin.material_override = paint(colour)
	body.add_child(skin)
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = size
	shape.shape = block
	body.add_child(shape)

## A mark at the plate's centre of mass.
func mark() -> void:
	var dot := MeshInstance3D.new()
	dot.name = "Mark"
	var ball := SphereMesh.new()
	ball.radius = 0.07
	ball.height = 0.14
	dot.mesh = ball
	dot.material_override = paint(GHOST)
	dot.position = plate.center_of_mass
	plate.add_child(dot)

## The family on the plate: `members` cubes, one on the other, each `lean` further to +x.
func stack() -> void:
	for k in members:
		var member := RigidBody3D.new()
		member.name = "Member%d" % (k + 1)
		member.position = Vector3(lean * k, plate.position.y + PLATE.y / 2.0 + EDGE * (k + 0.5), 0)
		member.mass = 2.0
		member.freeze = true
		dress(member, Vector3(EDGE, EDGE, EDGE), BODIES[(k + 2) % 4])
		add_child(member)
		bodies.append(member)

## A body of yours on top of the stack: its look, a box around its meshes, 2 kg.
func ride() -> void:
	var body := RigidBody3D.new()
	body.name = "Rider"
	body.mass = 2.0
	body.freeze = true
	body.position = Vector3(0, 50, 0)      # out of the way while it is measured
	add_child(body)
	var look: Node = rider.instantiate()
	body.add_child(look)
	var box := AABB()
	var first := true
	for mesh: MeshInstance3D in look.find_children("*", "MeshInstance3D", true, false):
		var here: AABB = body.global_transform.affine_inverse() * mesh.global_transform * mesh.get_aabb()
		box = here if first else box.merge(here)
		first = false
	if look is MeshInstance3D:
		var own: AABB = body.global_transform.affine_inverse() * look.global_transform * look.get_aabb()
		box = own if first else box.merge(own)
		first = false
	if first:
		print("Balance guest: the rider has no mesh to stand, so it is left out")
		body.free()
		return
	for other: CollisionObject3D in look.find_children("*", "CollisionObject3D", true, false):
		other.collision_layer = 0
		other.collision_mask = 0
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = box.size
	shape.shape = block
	shape.position = box.get_center()
	body.add_child(shape)
	var top := plate.position.y + PLATE.y / 2.0 + EDGE * members
	body.position = Vector3(lean * members - box.get_center().x, top - box.position.y, -box.get_center().z)
	bodies.append(body)

## The plate feels a walker: an Area3D on its top says who comes and who goes.
func feel() -> void:
	var area := Area3D.new()
	area.name = "Top"
	var shape := CollisionShape3D.new()
	var slab := BoxShape3D.new()
	slab.size = Vector3(PLATE.x, 0.1, PLATE.z)
	shape.shape = slab
	shape.position.y = PLATE.y / 2.0 + 0.05
	area.add_child(shape)
	plate.add_child(area)
	area.body_entered.connect(arrive)
	area.body_exited.connect(leave)

func arrive(body: Node3D) -> void:
	if body is CharacterBody3D:
		standing.append(body)

func leave(body: Node3D) -> void:
	if body is CharacterBody3D:
		standing.erase(body)

func release() -> void:
	for body in bodies:
		body.freeze = false

func _physics_process(delta: float) -> void:
	clock += delta
	if plate.freeze and clock >= hold:
		release()
	for body in bodies:
		if tilt(body) > 20.0 and not body in down:
			down.append(body)
			fallen.emit(body)
	for walker in standing:
		if walker.is_on_floor():
			plate.apply_force(Vector3.DOWN * walker_mass * 9.8, walker.global_position - plate.global_position)

## How far a body has turned from upright, in degrees.
func tilt(body: Node3D) -> float:
	return rad_to_deg(body.global_basis.y.angle_to(Vector3.UP))

func count(body: RigidBody3D) -> void:
	falls += 1
	words.text = "fallen: %d, the last %s" % [falls, body.name]
