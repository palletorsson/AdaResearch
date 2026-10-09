extends Node3D
## A plate on posts. The posts stand still; the plate is a body the physics moves.
## It is held for `hold` seconds, then let go, and then it stands or it falls.

signal fallen(body: RigidBody3D)          # a body of the table has turned more than 20 degrees from upright

const Look := preload("res://supplied/look.gd")
const Segment := preload("res://supplied/segment.gd")
const POST := Vector3(0.08, 0.3, 0.08)    # metres: a post, 8 cm square and 30 cm high
const PLATE := Vector3(1.2, 0.06, 0.8)    # metres: the plate
const EDGE := 0.24                        # metres: a member of the family, a cube

@export_range(2, 4) var legs := 4         # posts under the plate
@export var mass := 10.0                  # kilograms, of the plate
@export var offset := 0.0                 # metres: the plate's centre of mass, from its middle towards +x
@export var hold := 1.0                   # seconds before the plate is let go
@export var members := 3                  # members of the family stacked on the plate
@export var lean := 0.04                  # metres: each member stands this much further to +x than the one below
@export var walker_mass := 60.0           # kilograms: what a walker standing on the plate weighs on it

var plate: RigidBody3D
var plumb: Segment                        # the plumb line, from the centre of mass down to the floor
var clock := 0.0                          # seconds since the start
var bodies: Array[RigidBody3D] = []       # what can fall: the plate and the members
var down: Array[RigidBody3D] = []         # what has fallen
var standing: Array[CharacterBody3D] = [] # walkers on the plate's top now

func _ready() -> void:
	for spot: Vector2 in spots():
		var post := StaticBody3D.new()
		post.position = Vector3(spot.x, POST.y / 2.0, spot.y)
		dress(post, POST, Look.SECOND)
		add_child(post)
	plate = RigidBody3D.new()
	plate.name = "Plate"
	plate.position = Vector3(0, POST.y + PLATE.y / 2.0 + 0.01, 0)   # 1 cm above the posts
	plate.mass = mass
	plate.center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	plate.center_of_mass = Vector3(offset, 0, 0)
	plate.freeze = true
	dress(plate, PLATE, Look.BODY)
	add_child(plate)
	bodies.append(plate)
	draw_relation()
	stack()
	feel()

## Where the posts stand, seen from above: x to the right, y towards you.
func spots() -> Array:
	if legs == 2:
		return [Vector2(-0.3, -0.2), Vector2(0.3, 0.2)]
	if legs == 3:
		return [Vector2(-0.3, -0.2), Vector2(-0.3, 0.2), Vector2(0.3, 0)]
	return [Vector2(-0.3, -0.2), Vector2(0.3, -0.2), Vector2(0.3, 0.2), Vector2(-0.3, 0.2)]

## A box to see, and the same box to collide with.
func dress(body: Node3D, size: Vector3, colour: Color) -> void:
	var skin := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	skin.mesh = box
	skin.material_override = Look.paint(colour)
	body.add_child(skin)
	var shape := CollisionShape3D.new()
	var block := BoxShape3D.new()
	block.size = size
	shape.shape = block
	body.add_child(shape)

## Let go: from now on the physics moves the plate and the family on it.
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
		if walker.is_on_floor():           # standing on it, not jumping over it
			plate.apply_force(Vector3.DOWN * walker_mass * 9.8, walker.global_position - plate.global_position)
	var centre := plate.to_global(plate.center_of_mass)
	plumb.show_between(to_local(centre), to_local(Vector3(centre.x, 0.0, centre.z)))

## How far a body has turned from upright, in degrees.
func tilt(body: Node3D) -> float:
	return rad_to_deg(body.global_basis.y.angle_to(Vector3.UP))

## The relation drawn: a mark at the centre of mass, a plumb line from it to
## the floor, and on the floor the outline around the posts' tops.
func draw_relation() -> void:
	var mark := MeshInstance3D.new()
	mark.name = "Mark"
	var ball := SphereMesh.new()
	ball.radius = 0.07
	ball.height = 0.14
	mark.mesh = ball
	mark.material_override = Look.paint(Look.GHOST)
	mark.position = plate.center_of_mass
	plate.add_child(mark)
	var corners := PackedVector2Array()
	for spot: Vector2 in spots():
		for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
			corners.append(spot + corner * POST.x / 2.0)
	var hull := Geometry2D.convex_hull(corners)   # the outline; its first point comes again at its end
	for i in hull.size() - 1:
		var line := Segment.new()
		line.name = "Outline"
		add_child(line)
		line.show_between(Vector3(hull[i].x, 0.005, hull[i].y), Vector3(hull[i + 1].x, 0.005, hull[i + 1].y))
	plumb = Segment.new()
	plumb.name = "Plumb"
	add_child(plumb)

## The family on the plate: `members` cubes, one on the other, each `lean` further to +x.
func stack() -> void:
	for k in members:
		var member := RigidBody3D.new()
		member.name = "Member%d" % (k + 1)
		member.position = Vector3(lean * k, plate.position.y + PLATE.y / 2.0 + EDGE * (k + 0.5), 0)
		member.mass = 2.0
		member.freeze = true
		dress(member, Vector3(EDGE, EDGE, EDGE), Look.BODIES[(k + 2) % 4])
		add_child(member)
		bodies.append(member)

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
