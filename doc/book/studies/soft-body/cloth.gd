extends MeshInstance3D

const Look := preload("res://supplied/look.gd")
const GRAVITY := Vector3(0.0, -9.8, 0.0)

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

# A particle that is held: by a nail, or by a node that carries it.
class PinnedParticle extends Particle:
	var holder: Node3D   # null: a nail

	func _init(at: Vector3, by: Node3D = null) -> void:
		super(at)
		holder = by

	func step(_delta: float) -> void:
		if holder != null:
			position = holder.position

	func nudge(_by: Vector3) -> void:
		pass

@export_range(1, 64) var iterations := 4   # passes over the links in one step
@export var across := 11       # particles in a row
@export var down := 11         # rows
@export var spacing := 0.12    # metres from one particle to the next

var particles: Array[Particle] = []
var links := PackedInt32Array()     # two particles for every link
var corners := PackedInt32Array()   # three particles for every triangle
var bodies: Array = []              # what the cloth keeps out of, told anew every step
var cost := 0.0                     # milliseconds the last step took

func _ready() -> void:
	var paint := Look.paint(Look.BODY)
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED   # a cloth is seen from both sides
	material_override = paint
	build()

func build() -> void:
	particles.clear()
	links.clear()
	corners.clear()
	for row in down:
		for column in across:
			var at := Vector3((column - (across - 1) / 2.0) * spacing, -row * spacing, 0.0)
			var i := particles.size()
			if row == 0 and column == 0:
				particles.append(PinnedParticle.new(at))
			elif row == 0 and column == across - 1:
				particles.append(PinnedParticle.new(at, get_node_or_null("Hand")))
			else:
				particles.append(Particle.new(at))
			if column > 0:
				links.append_array([i - 1, i])
			if row > 0:
				links.append_array([i - across, i])
			if column > 0 and row > 0:
				corners.append_array([i - across - 1, i - across, i - 1, i - across, i, i - 1])
	draw()

func _physics_process(delta: float) -> void:
	var began := Time.get_ticks_usec()
	step(delta)
	cost = (Time.get_ticks_usec() - began) / 1000.0
	draw()

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

func report() -> String:
	var lowest := INF
	for particle in particles:
		lowest = minf(lowest, to_global(particle.position).y)
	var longest := 0.0
	for k in range(0, links.size(), 2):
		longest = maxf(longest, particles[links[k]].position.distance_to(particles[links[k + 1]].position))
	return "%d passes: lowest point %.2f m, longest link %.0f%% of its length, %.2f ms a step" % [iterations, lowest, 100.0 * longest / spacing, cost]

# A body to keep out of in the next step: a ball (a and b the same place) or a capsule.
func meet(a: Vector3, b: Vector3, radius: float) -> void:
	bodies.append([to_local(a), to_local(b), radius])

# A PinnedParticle cannot become a Particle. So a new Particle takes the place of the first one found.
func let_go() -> void:
	for i in particles.size():
		if particles[i] is PinnedParticle:
			particles[i] = Particle.new(particles[i].position)
			return
