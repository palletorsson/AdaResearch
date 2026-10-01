extends MeshInstance3D

const Look := preload("res://supplied/look.gd")
const Table := preload("res://mc_table.gd")
const Pieces := preload("res://pieces.gd")

signal built   # a new skin is on

@export_range(0.05, 0.95) var threshold := 0.4   # the value of the field where the skin is
@export var radius := 0.95     # metres: the reach of one source
@export var wobble := 0.08     # how much noise the field carries
@export var cells := 40        # cells along one side of the grid
@export var size := 5.0        # metres: the side of the box the field is asked in
@export var threaded := true   # build on a worker thread

var centres := PackedVector3Array([Vector3(-1.15, 0.9, 0.0), Vector3(1.15, 0.9, 0.0), Vector3(0.0, 2.9, 0.0)])
var cuts := PackedVector3Array()   # the feet of the standing holes carved so far
var noise := FastNoiseLite.new()
var wall: StaticBody3D             # what a walker meets
var pieces := 0                    # how many separate bodies the skin has
var cost := 0.0                    # milliseconds the last build took
var task := -1                     # the build that is running, or -1
var stale := false                 # asked again while a build was running

func _ready() -> void:
	material_override = Look.paint(Look.BODY)
	noise.seed = 36
	noise.frequency = 0.9
	rebuild()

# The field: one number for every place. A source adds 1 at its centre and less further out.
func value_at(p: Vector3) -> float:
	var sum := wobble * noise.get_noise_3dv(p)
	for centre in centres:
		sum += exp(-p.distance_squared_to(centre) / (radius * radius))
	for foot in cuts:
		var nearest := Geometry3D.get_closest_point_to_segment(p, foot, foot + Vector3(0.0, 1.5, 0.0))
		sum = minf(sum, (p.distance_to(nearest) - 0.45) * 4.0)
	return sum

# With `threaded` on, build() runs on a worker thread. It reads the field and touches no node.
func rebuild() -> void:
	if task != -1:
		stale = true   # a build is running: build once more when it has ended
		return
	if threaded:
		task = WorkerThreadPool.add_task(build.bind(threshold))
	else:
		build(threshold)

func build(level: float) -> void:
	var began := Time.get_ticks_usec()
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
	var points := PackedVector3Array()  # three for every triangle
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
					points.append(origin + (Vector3(x, y, z) + crossing) * step)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	for point in points:
		tool.add_vertex(point)
	tool.generate_normals()
	var made := tool.commit()
	var count := Pieces.count(points)
	show_mesh.call_deferred(made, count, (Time.get_ticks_usec() - began) / 1000.0)

# The hand-back. Only here do we touch the scene.
func show_mesh(made: ArrayMesh, count: int, took: float) -> void:
	mesh = made
	pieces = count
	cost = took
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

# A standing hole, as high as a walker, with its foot on the ground under `at`.
func carve(at: Vector3) -> void:
	while task != -1:
		await built   # a thread is reading the field: do not change it under its hands
	var foot := to_local(at)
	cuts.append(Vector3(foot.x, 0.0, foot.z))
	rebuild()

func _exit_tree() -> void:
	if task != -1:
		WorkerThreadPool.wait_for_task_completion(task)   # do not leave while a thread still works for us
		task = -1
