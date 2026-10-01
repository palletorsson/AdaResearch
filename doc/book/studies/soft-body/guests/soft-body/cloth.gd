extends MeshInstance3D
## A soft part for a guest: a cloth of particles and links, hung by its two
## top corners from where this node is. A body that comes near pushes it aside.
## It is cloth.gd of the Soft body study, made to stand alone:
##   - it writes its colour out, since a guest cannot use the look of a kit;
##   - it asks the room itself which bodies are near, through an Area3D it
##     makes, `Reach`: a walker (a CharacterBody3D) is kept out as a capsule
##     1.8 m high and 0.6 m wide, a loose body (a RigidBody3D) as a small ball;
##   - it rests: after two seconds in which nothing moved and nobody is near,
##     it stops stepping until a body enters its reach again.
## Everything it needs is in this file, and it declares no class_name, so it
## can be copied alone into the folder of another guest.

const BODY := Color("c6ff3d")   # the BODY colour of the kits, written out
const GRAVITY := Vector3(0.0, -9.8, 0.0)
const SKIN := 0.04              # metres the cloth keeps from a body

# A point of the cloth: where it is, and where it was one step ago.
class Particle extends RefCounted:
	var position := Vector3.ZERO
	var previous := Vector3.ZERO

	func _init(at: Vector3) -> void:
		position = at
		previous = at

	func step(delta: float) -> void:
		var here := position
		position += (position - previous) * 0.99 + GRAVITY * delta * delta
		previous = here

	func nudge(by: Vector3) -> void:
		position += by

	# Out of a ball or a capsule: all that is nearer than `radius` to the line from a to b.
	func push_out(a: Vector3, b: Vector3, radius: float) -> void:
		var away := position - Geometry3D.get_closest_point_to_segment(position, a, b)
		if away.length() < radius:
			nudge(away.normalized() * (radius - away.length()))
			previous = position   # it stops where it touches

# A particle that is held by a nail.
class PinnedParticle extends Particle:
	func step(_delta: float) -> void:
		pass

	func nudge(_by: Vector3) -> void:
		pass

@export_range(1, 64) var iterations := 8   # passes over the links in one step
@export var across := 11       # particles in a row
@export var down := 11         # rows
@export var spacing := 0.12    # metres from one particle to the next

var particles: Array[Particle] = []
var links := PackedInt32Array()     # two particles for every link
var corners := PackedInt32Array()   # three particles for every triangle
var bodies: Array = []              # what the cloth keeps out of, told anew every step
var reach: Area3D                   # the bodies inside it are the ones the cloth is told about
var awake := true                   # false: it rests, and costs one question a step
var still := 0                      # steps in a row in which nothing moved

func _ready() -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED   # a cloth is seen from both sides
	material_override = paint
	build()
	# The reach: a box around the cloth, 0.8 m to the front and to the back of it.
	var drop := (down - 1) * spacing * 1.7
	var box := BoxShape3D.new()
	box.size = Vector3((across - 1) * spacing + 0.4, drop, 1.6)
	var room := CollisionShape3D.new()
	room.shape = box
	room.position = Vector3(0.0, -drop / 2.0, 0.0)
	reach = Area3D.new()
	reach.name = "Reach"
	reach.add_child(room)
	add_child(reach)

func build() -> void:
	particles.clear()
	links.clear()
	corners.clear()
	for row in down:
		for column in across:
			var at := Vector3((column - (across - 1) / 2.0) * spacing, -row * spacing, 0.0)
			var i := particles.size()
			if row == 0 and (column == 0 or column == across - 1):
				particles.append(PinnedParticle.new(at))
			else:
				particles.append(Particle.new(at))
			if column > 0:
				links.append_array([i - 1, i])
			if row > 0:
				links.append_array([i - across, i])
			if column > 0 and row > 0:
				corners.append_array([i - across - 1, i - across, i - 1, i - across, i, i - 1])
	awake = true
	still = 0
	draw()

func _physics_process(delta: float) -> void:
	for body in reach.get_overlapping_bodies():
		var at: Vector3 = body.global_position
		if body is CharacterBody3D:
			meet(at + Vector3(0.0, 0.3, 0.0), at + Vector3(0.0, 1.5, 0.0), 0.3 + SKIN)
		elif body is RigidBody3D:
			meet(at, at, 0.1 + SKIN)
	if not bodies.is_empty():
		awake = true
		still = 0
	if not awake:
		return
	step(delta)
	draw()
	var moved := 0.0
	for particle in particles:
		moved = maxf(moved, particle.position.distance_to(particle.previous))
	still = still + 1 if moved < 0.0002 else 0
	awake = still < 120

func step(delta: float) -> void:
	for particle in particles:
		particle.step(delta)
	for pass_number in iterations:
		relax()
	for body: Array in bodies:
		for particle in particles:
			particle.push_out(body[0], body[1], body[2])
	bodies.clear()

# One pass: every link pulls its two particles half of the way back to its length.
func relax() -> void:
	for k in range(0, links.size(), 2):
		var a := particles[links[k]]
		var b := particles[links[k + 1]]
		var between := b.position - a.position
		var half := between.normalized() * (between.length() - spacing) * 0.5
		a.nudge(half)
		b.nudge(-half)

func draw() -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for particle in particles:
		tool.add_vertex(particle.position)
	for corner in corners:
		tool.add_index(corner)
	tool.generate_normals()
	mesh = tool.commit()

# A body to keep out of in the next step: a ball (a and b the same place) or a capsule.
func meet(a: Vector3, b: Vector3, radius: float) -> void:
	bodies.append([to_local(a), to_local(b), radius])
