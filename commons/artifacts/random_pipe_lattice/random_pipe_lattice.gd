extends Node3D
class_name RandomPipeLattice

# @identity
# essence: a grid net that starts in order and gradually becomes chance - at one end every point is piped up and to
#          the same two neighbours, at the other each of eight pipes exists only when a random draw beats a threshold
# desire: walk along one structure from a rule you can predict to a rule you can only describe
# critical_parameter: the randomness t along the net (gradient) - how often a pipe is decided by a draw, not the pattern
# triggers: built procedurally in _ready() from a seeded generator; rebuilt by apply_grid_config
# needs: a clear floor about size_x x size_y metres; the origin is the centre of the bottom level
# truth: the same rule and the same seed always build the same net; t only says how often chance is asked
#
# Palle, 2026-11-05, for the Randomness sequence: first "can you make this structure" (a Rhino Python script: a 7 x 7
# grid, four levels 1 unit apart, every point piped up and to each of eight next-level neighbours when random() > 0.6,
# pipes r 0.1); then "make the structure be a grid net that starts non random and gradually becomes more random, and
# make the vertices and edges smaller and thinner".
# Each start point has a randomness t in 0..1 (gradient "y": along the net's length; "levels": from the bottom level
# up; "none": 1 everywhere, the script as written):
#   - always a pipe straight up;
#   - for each of the script's eight draws, in its order - right (+1), left (-1), away up (+ny), away right (+ny-1),
#     away left (+ny, the same point as away up), back up (-ny), back left (-ny-1), back right (-ny+1) - with
#     probability t the script decides (a pipe when random() > prob), otherwise the regular net does (right and away
#     up only);
#   - the next level's points drift by up to `deviation` x t (the script's divation, growing with the gradient).
# As written: only points short of the last row and column start pipes, and Python's negative indices wrap some pipes
# to the far side (neighbours = "local" drops every pipe that is not to a true neighbour).
# Script units: x across (size_x points), y along (size_y points), z up (levels); Rhino's z is Godot's y.
# Config: #seed:7 #prob:0.6 #size_x:7 #size_y:13 #levels:3 #spacing:1 #pipe_radius:0.035 #joint_radius:0.07
#         #deviation:0.35 #gradient:y|levels|none #neighbours:as_written|local

@export var seed: int = 7
@export_range(0.0, 1.0) var prob: float = 0.6
@export var size_x: int = 7
@export var size_y: int = 13
@export var levels: int = 3
@export var spacing: float = 1.0
@export var pipe_radius: float = .035
@export var joint_radius: float = .07
@export var deviation: float = .35
@export_enum("y", "levels", "none") var gradient: String = "y"
@export_enum("as_written", "local") var neighbours: String = "as_written"

var pipe_count := 0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	_build()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "size_x", "size_y", "levels"]:
		if config_data.has(key): set(key, int(config_data[key]))
	for key in ["prob", "spacing", "pipe_radius", "joint_radius", "deviation"]:
		if config_data.has(key): set(key, float(config_data[key]))
	if config_data.has("gradient") and str(config_data.gradient) in ["y", "levels", "none"]: gradient = str(config_data.gradient)
	if config_data.has("neighbours") and str(config_data.neighbours) in ["as_written", "local"]: neighbours = str(config_data.neighbours)
	if is_inside_tree(): _build()

## How random a start point is: 0 = the regular net, 1 = the script.
func _t(y: int, level: int) -> float:
	match gradient:
		"y": return float(y) / maxf(size_y - 1, 1)
		"levels": return float(level) / maxf(levels, 1)
	return 1.0

func _build() -> void:
	for child in get_children(): child.queue_free()
	_rng.seed = seed
	pipe_count = 0
	var nx := size_x
	var ny := size_y
	var count := nx * ny
	var lvls: Array = []
	var first: Array[Vector3] = []
	for x in nx:
		for y in ny:
			first.append(Vector3(x, y, 0))
	lvls.append(first)
	for z in levels:
		var prev: Array = lvls[z]
		var nxt: Array[Vector3] = []
		for i in prev.size():
			var p: Vector3 = prev[i]
			var d := deviation * _t(i % ny, z + 1)
			nxt.append(Vector3(p.x + _rng.randf() * d - d / 2, p.y + _rng.randf() * d - d / 2, p.z + _rng.randf() * d - d / 2 + 1))
		lvls.append(nxt)
	var pipes := SurfaceTool.new();pipes.begin(Mesh.PRIMITIVE_TRIANGLES)
	var joints := SurfaceTool.new();joints.begin(Mesh.PRIMITIVE_TRIANGLES)
	var body := StaticBody3D.new();body.name = "Lattice";add_child(body)
	var used := {}
	var offsets := [1, -1, ny, ny - 1, ny, -ny, -ny - 1, -ny + 1]
	var regular := [0, 2]   # the ordered net: right and away up
	for z in levels:
		var current: Array = lvls[z]
		var above: Array = lvls[z + 1]
		for x in nx - 1:
			for y in ny - 1:
				var pos := x * ny + y
				var t := _t(y, z)
				_pipe(pipes, body, _world(current[pos]), _world(above[pos]))
				used[Vector2i(z, pos)] = true;used[Vector2i(z + 1, pos)] = true
				for k in offsets.size():
					var draw := _rng.randf()
					var by_chance := _rng.randf() < t
					var keep: bool = (draw > prob) if by_chance else (k in regular)
					if not keep:
						continue
					var raw: int = pos + int(offsets[k])
					var target: int = raw + count if raw < 0 else raw   # Python's negative index
					if target < 0 or target >= count:
						continue
					if neighbours == "local":
						var tx := target / ny;var ty := target % ny
						if absi(tx - x) > 1 or absi(ty - y) > 1 or raw < 0:
							continue
					_pipe(pipes, body, _world(current[pos]), _world(above[target]))
					used[Vector2i(z + 1, target)] = true
	var ball := SphereMesh.new();ball.radius = joint_radius;ball.height = joint_radius * 2;ball.radial_segments = 12;ball.rings = 6
	for key: Vector2i in used:
		var p: Vector3 = _world(lvls[key.x][key.y])
		joints.append_from(ball, 0, Transform3D(Basis.IDENTITY, p))
		var shape := CollisionShape3D.new();var sphere := SphereShape3D.new();sphere.radius = joint_radius
		shape.shape = sphere;shape.position = p;body.add_child(shape)
	var steel := StandardMaterial3D.new();steel.albedo_color = Color("d8d5ce");steel.roughness = .45;steel.metallic = .35
	var node_paint := StandardMaterial3D.new();node_paint.albedo_color = Color("ff4f9a");node_paint.roughness = .5
	var pipe_mesh := MeshInstance3D.new();pipe_mesh.name = "Pipes";pipe_mesh.mesh = pipes.commit();pipe_mesh.material_override = steel
	add_child(pipe_mesh)
	var joint_mesh := MeshInstance3D.new();joint_mesh.name = "Joints";joint_mesh.mesh = joints.commit();joint_mesh.material_override = node_paint
	add_child(joint_mesh)
	set_meta("pipes", pipe_count);set_meta("joints", used.size())

## Script units to metres: x across, the script's y as Godot's z, the script's z (level) up; centred on the origin.
func _world(p: Vector3) -> Vector3:
	return Vector3((p.x - (size_x - 1) * .5) * spacing, p.z * spacing + joint_radius, (p.y - (size_y - 1) * .5) * spacing)

func _pipe(st: SurfaceTool, body: StaticBody3D, a: Vector3, b: Vector3) -> void:
	var length := a.distance_to(b)
	if length < 1e-4:
		return
	var y := (b - a) / length
	var reference := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > .95 else Vector3.UP
	var x := reference.cross(y).normalized()
	var frame := Transform3D(Basis(x, y, x.cross(y)), (a + b) * .5)
	var cylinder := CylinderMesh.new();cylinder.top_radius = pipe_radius;cylinder.bottom_radius = pipe_radius
	cylinder.height = length;cylinder.radial_segments = 8;cylinder.rings = 1;cylinder.cap_top = false;cylinder.cap_bottom = false
	st.append_from(cylinder, 0, frame)
	var shape := CollisionShape3D.new();var capsule := CapsuleShape3D.new()
	capsule.radius = pipe_radius;capsule.height = length + 2 * pipe_radius
	shape.shape = capsule;shape.transform = frame;body.add_child(shape)
	pipe_count += 1
