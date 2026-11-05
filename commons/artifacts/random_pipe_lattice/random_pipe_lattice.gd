extends Node3D
class_name RandomPipeLattice

# @identity
# essence: a lattice grown by chance - a grid of points stacked in levels, each point always piped straight up and
#          piped to each of eight neighbours on the next level only when a random draw beats a threshold
# desire: walk into a structure whose every crossing was a coin toss, and see the same rule give another maze
# critical_parameter: prob - the threshold a draw must beat (0.6: each optional pipe has a 40 % chance)
# triggers: built procedurally in _ready() from a seeded generator; rebuilt by apply_grid_config
# needs: a clear floor about size x size metres; the origin is the centre of the bottom level
# truth: the same rule and the same seed always build the same lattice; a new seed is a new draw, never a new rule
#
# Palle, 2026-11-05, for the Randomness sequence: "can you make this structure" - a Rhino Python script (a 7 x 7 grid,
# four levels 1 unit apart, pipes of radius 0.1). Ported as written, quirks included:
#   - only points with x < size-1 and y < size-1 start pipes (the last row and column are only ever reached);
#   - the eight draws per point, in the script's order: right (+1), left (-1), away up (+size), away right
#     (+size-1), away left (+size, the same point as away up - so that pipe gets two chances), back up (-size),
#     back left (-size-1), back right (-size+1);
#   - indices are Python's: a negative index counts from the end of the level, so pipes from the first row and
#     column can wrap to the far side of the lattice. neighbours = "local" drops every pipe that is not to a true
#     neighbour (the 3 x 3 cells above).
# Rhino's z (up) is Godot's y. Units: 1 = spacing metres.
# Config: #seed:7 #prob:0.6 #size:7 #levels:3 #spacing:1 #pipe_radius:0.1 #deviation:0 #neighbours:as_written|local

@export var seed: int = 7
@export_range(0.0, 1.0) var prob: float = 0.6
@export var size: int = 7
@export var levels: int = 3
@export var spacing: float = 1.0
@export var pipe_radius: float = 0.1
@export var deviation: float = 0.0
@export_enum("as_written", "local") var neighbours: String = "as_written"

var pipe_count := 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "size", "levels"]:
		if config_data.has(key): set(key, int(config_data[key]))
	for key in ["prob", "spacing", "pipe_radius", "deviation"]:
		if config_data.has(key): set(key, float(config_data[key]))
	if config_data.has("neighbours") and str(config_data.neighbours) in ["as_written", "local"]: neighbours = str(config_data.neighbours)
	if is_inside_tree(): _build()

func _build() -> void:
	for child in get_children(): child.queue_free()
	_rng.seed = seed
	pipe_count = 0
	var half := (size - 1) * .5
	# The levels: the script's createFirstLevel, then createNextLevel (each point jittered by up to deviation/2,
	# and one unit up). Points as (x, y, z) in script units; index = x * size + y.
	var lvls: Array = []
	var first: Array[Vector3] = []
	for x in size:
		for y in size:
			first.append(Vector3(x, y, 0))
	lvls.append(first)
	for z in levels:
		var prev: Array = lvls[z]
		var nxt: Array[Vector3] = []
		for p: Vector3 in prev:
			nxt.append(Vector3(p.x + _rng.randf() * deviation - deviation / 2, p.y + _rng.randf() * deviation - deviation / 2, p.z + _rng.randf() * deviation - deviation / 2 + 1))
		lvls.append(nxt)
	var pipes := SurfaceTool.new();pipes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var joints := SurfaceTool.new();joints.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new();body.name = "Lattice";add_child(body)
	var used := {}
	var count: int = size * size
	var offsets := [1, -1, size, size - 1, size, -size, -size - 1, -size + 1]
	for z in levels:
		var current: Array = lvls[z]
		var above: Array = lvls[z + 1]
		for x in size - 1:
			for y in size - 1:
				var pos := x * size + y
				_pipe(pipes, body, _world(current[pos], half), _world(above[pos], half))
				used[Vector2i(z, pos)] = true;used[Vector2i(z + 1, pos)] = true
				for k in offsets.size():
					var draw := _rng.randf()   # the script draws for every neighbour, kept or not
					if draw <= prob:
						continue
					var raw: int = pos + int(offsets[k])
					var target: int = raw + count if raw < 0 else raw   # Python's negative index
					if target < 0 or target >= count:
						continue   # the script would have raised IndexError; never reached at the script's sizes
					if neighbours == "local":
						var tx := target / size;var ty := target % size
						if absi(tx - x) > 1 or absi(ty - y) > 1 or raw < 0:
							continue
					_pipe(pipes, body, _world(current[pos], half), _world(above[target], half))
					used[Vector2i(z + 1, target)] = true
	var ball := SphereMesh.new();ball.radius = pipe_radius * 1.6;ball.height = pipe_radius * 3.2;ball.radial_segments = 12;ball.rings = 6
	for key: Vector2i in used:
		var p: Vector3 = _world(lvls[key.x][key.y], half)
		joints.append_from(ball, 0, Transform3D(Basis.IDENTITY, p))
		var shape := CollisionShape3D.new();var sphere := SphereShape3D.new();sphere.radius = pipe_radius * 1.6
		shape.shape = sphere;shape.position = p;body.add_child(shape)
	var steel := StandardMaterial3D.new();steel.albedo_color = Color("d8d5ce");steel.roughness = .45;steel.metallic = .35
	var node_paint := StandardMaterial3D.new();node_paint.albedo_color = Color("ff4f9a");node_paint.roughness = .5
	var pipe_mesh := MeshInstance3D.new();pipe_mesh.name = "Pipes";pipe_mesh.mesh = pipes.commit();pipe_mesh.material_override = steel
	add_child(pipe_mesh)
	var joint_mesh := MeshInstance3D.new();joint_mesh.name = "Joints";joint_mesh.mesh = joints.commit();joint_mesh.material_override = node_paint
	add_child(joint_mesh)
	set_meta("pipes", pipe_count);set_meta("joints", used.size())

## Script units to metres: x across, the script's y as Godot's z, the script's z (level) up; centred on the origin.
func _world(p: Vector3, half: float) -> Vector3:
	return Vector3((p.x - half) * spacing, p.z * spacing + pipe_radius, (p.y - half) * spacing)

func _pipe(st: SurfaceTool, body: StaticBody3D, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 1e-4:
		return
	var y := (b - a) / length
	var reference := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > .95 else Vector3.UP
	var x := reference.cross(y).normalized()
	var frame := Transform3D(Basis(x, y, x.cross(y)), (a + b) * .5)
	var cylinder := CylinderMesh.new();cylinder.top_radius = pipe_radius;cylinder.bottom_radius = pipe_radius
	cylinder.height = length;cylinder.radial_segments = 10;cylinder.rings = 1;cylinder.cap_top = false;cylinder.cap_bottom = false
	st.append_from(cylinder, 0, frame)
	var shape := CollisionShape3D.new();var capsule := CapsuleShape3D.new()
	capsule.radius = pipe_radius;capsule.height = length + 2 * pipe_radius
	shape.shape = capsule;shape.transform = frame;body.add_child(shape)
	pipe_count += 1
