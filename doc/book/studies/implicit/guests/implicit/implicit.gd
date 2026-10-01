extends MeshInstance3D
## The guest of the Implicit study: one field with three sources, and a skin
## where the field crosses a threshold. While nobody is near, the threshold is
## high and three bodies stand apart, one of them in the air. When a body comes
## within 2.5 m the threshold falls, a step for every build, and the three
## become one. Walk away and they part again. Each skin is built on a worker
## thread, and a body at rest is not built at all.
## It is field_body.gd of the study, made to stand alone:
##   - it writes its colour out, since a guest cannot use the look of a kit;
##   - it is 0.3 of the study's size, to fit a place of the room;
##   - it asks the room itself who is near, through an Area3D it makes, `Reach`:
##     a walker (a CharacterBody3D) or a loose body (a RigidBody3D) counts.
## To fuse: add a place to `centres`. To carve: add a foot to `cuts`. Do either
## in _ready(), above rebuild(). It names nothing outside its folder and
## declares no class_name.

const Table := preload("res://guests/implicit/mc_table.gd")
const BODY := Color("c6ff3d")   # the BODY colour of the kits, written out

signal built   # a new skin is on

@export var apart := 0.6       # the threshold while nobody is near: three bodies
@export var together := 0.3    # the threshold while somebody is near: one body
@export var pace := 0.05       # how far the threshold moves from one build to the next
@export var radius := 0.3      # metres: the reach of one source
@export var wobble := 0.08     # how much noise the field carries
@export var cells := 20        # cells along one side of the grid
@export var size := 1.6        # metres: the side of the box the field is asked in

var threshold := 0.6               # the value of the field where the skin is now
var centres := PackedVector3Array([Vector3(-0.36, 0.15, 0.0), Vector3(0.36, 0.15, 0.0), Vector3(0.0, 0.78, 0.0)])
var cuts := PackedVector3Array()   # the feet of standing holes, each 0.5 m high and 0.1 m in radius
var noise := FastNoiseLite.new()
var wall: StaticBody3D             # what a walker meets
var reach: Area3D                  # who is inside it is near
var builds := 0                    # how many skins have been built
var task := -1                     # the build that is running, or -1
var stale := false                 # asked again while a build was running

func _ready() -> void:
	var paint := StandardMaterial3D.new()
	paint.albedo_color = BODY
	paint.roughness = 0.8
	material_override = paint
	noise.seed = 36
	noise.frequency = 2.85
	threshold = apart
	var ball := SphereShape3D.new()
	ball.radius = 2.5
	var room := CollisionShape3D.new()
	room.shape = ball
	reach = Area3D.new()
	reach.name = "Reach"
	reach.add_child(room)
	add_child(reach)
	rebuild()

# Is somebody near? Then the threshold has somewhere to go, and we build again.
func _physics_process(_delta: float) -> void:
	if task != -1:
		return
	var goal := apart
	for body in reach.get_overlapping_bodies():
		if body is CharacterBody3D or body is RigidBody3D:
			goal = together
	if not is_equal_approx(threshold, goal):
		threshold = move_toward(threshold, goal, pace)
		rebuild()

# The field: one number for every place. A source adds 1 at its centre and less further out.
func value_at(p: Vector3) -> float:
	var sum := wobble * noise.get_noise_3dv(p)
	for centre in centres:
		sum += exp(-p.distance_squared_to(centre) / (radius * radius))
	for foot in cuts:
		var nearest := Geometry3D.get_closest_point_to_segment(p, foot, foot + Vector3(0.0, 0.5, 0.0))
		sum = minf(sum, (p.distance_to(nearest) - 0.1) * 12.0)
	return sum

# build() runs on a worker thread. It reads the field and touches no node.
func rebuild() -> void:
	if task != -1:
		stale = true   # a build is running: build once more when it has ended
		return
	task = WorkerThreadPool.add_task(build.bind(threshold))

func build(level: float) -> void:
	var n := cells + 1          # samples along one side
	var step := size / cells    # metres from one sample to the next
	var origin := Vector3(-size / 2.0, 0.0, -size / 2.0)
	var values := PackedFloat32Array()
	values.resize(n * n * n)
	for z in n:
		for y in n:
			for x in n:
				values[x + n * (y + n * z)] = value_at(origin + Vector3(x, y, z) * step)
	var offsets := PackedInt32Array()   # from a cell's first sample to each of its eight corners
	for corner in Table.CUBE_VERTICES:
		offsets.append(int(corner.x) + n * (int(corner.y) + n * int(corner.z)))
	var at := PackedFloat32Array()      # the field at the eight corners of one cell
	at.resize(8)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for z in cells:
		for y in cells:
			for x in cells:
				var first := x + n * (y + n * z)
				var which := 0          # the case: one bit for each of the eight corners
				for i in 8:
					at[i] = values[first + offsets[i]]
					if at[i] > level:
						which |= 1 << i
				for edge: int in Table.TRIANGLE_TABLE[which]:
					var a: int = Table.EDGE_CONNECTIONS[edge][0]
					var b: int = Table.EDGE_CONNECTIONS[edge][1]
					var along := (level - at[a]) / (at[b] - at[a])
					var crossing: Vector3 = Table.CUBE_VERTICES[a].lerp(Table.CUBE_VERTICES[b], along)
					tool.add_vertex(origin + (Vector3(x, y, z) + crossing) * step)
	tool.generate_normals()
	show_mesh.call_deferred(tool.commit())

# The hand-back. Only here do we touch the scene.
func show_mesh(made: ArrayMesh) -> void:
	mesh = made
	builds += 1
	if wall != null:
		wall.queue_free()
	wall = StaticBody3D.new()
	if made.get_surface_count() > 0:
		var shape := CollisionShape3D.new()
		shape.shape = made.create_trimesh_shape()
		wall.add_child(shape)
	add_child(wall)
	if task != -1:
		WorkerThreadPool.wait_for_task_completion(task)   # it has ended; this lets the pool forget it
		task = -1
	if stale:
		stale = false
		rebuild()
	built.emit()

func _exit_tree() -> void:
	if task != -1:
		WorkerThreadPool.wait_for_task_completion(task)   # do not leave while a thread still works for us
		task = -1
