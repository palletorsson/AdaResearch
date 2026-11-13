extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## Sample one cave field, then use its extracted boundary for both rock and collision.
const Marcher = preload("res://algorithms/spacetopology/marchingcubes/VoxelNoiseMarchingCubes.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const ROCK_SHADER = preload("res://commons/void/trials/isosurfaces/cave_threshold.gdshader")
const CUTS := [-0.20, 0.0, 0.35]
const SAMPLE_SCALE := 0.25
const FIELD_LIFT := 1.45
const ROCK_HALF := Vector3(3.26, 2.25, 3.04)
const ROCK_CENTER := Vector3(0, 0.91, 0)
const LANES := [-1.30, 1.30]
const ENDS := 4.25

var field: Array = []
var cut_index := 0
var actions_taken := 0
var surface: MeshInstance3D
var rock_collision: CollisionShape3D
var stations: Array[Label3D] = []
var _variants: Dictionary = {}
var _marcher: VoxelNoiseMarchingCubes


func _ready() -> void:
	# The source marcher stays off-tree. It owns extraction and its lookup table,
	# while this room owns the metre-scale field and the persistent collision body.
	_marcher = Marcher.new()
	_marcher.chunk_size = 40
	_marcher.num_points_per_axis = 37
	_marcher.setup_marching_cubes_tables()
	_sample_field()
	_build_surface()
	_build_station(1.0)
	_build_station(-1.0)
	_mark_routes()
	_set_cut(0)


func _exit_tree() -> void:
	if is_instance_valid(_marcher):
		_marcher.free()


func _sample_field() -> void:
	var noise := FastNoiseLite.new()
	noise.seed = 1337
	noise.frequency = 1.45
	noise.fractal_octaves = 3
	var count := _marcher.num_points_per_axis
	var side := _marcher.chunk_size * SAMPLE_SCALE
	var origin := Vector3(-side * 0.5, FIELD_LIFT - side * 0.5, -side * 0.5)
	var spacing := side / (count - 1)
	field.resize(count * count * count)
	for z in count:
		for y in count:
			for x in count:
				var p := origin + Vector3(x, y, z) * spacing
				var grit := noise.get_noise_3dv(p)
				var q := (p - ROCK_CENTER).abs() - ROCK_HALF
				var envelope := q.max(Vector3.ZERO).length() + minf(maxf(q.x, maxf(q.y, q.z)), 0.0)
				var y_distance := p.y - clampf(p.y, -1.0, 1.47)
				var bend := 0.07 * sin(p.z * 1.1)
				var main := Vector2(p.x - LANES[0] - bend, y_distance).length() - 1.02
				var pinch_radius := 0.72 - 0.41 * exp(-pow((p.z - 0.25) / 0.95, 2.0))
				var pinch := Vector2(p.x - LANES[1] + bend, y_distance).length() - pinch_radius
				# Rock has high density. The steep base keeps each cut seated in the slab.
				var rock_distance := maxf(envelope, -minf(main, pinch)) + grit * 0.10
				field[x + count * (y + count * z)] = minf(-rock_distance, (p.y + 0.23) * 6.0)


func _build_surface() -> void:
	var terrain := Node3D.new()
	terrain.position.y = FIELD_LIFT
	add_child(terrain)
	surface = MeshInstance3D.new()
	surface.name = "CaveBoundary"
	var finish := ShaderMaterial.new()
	finish.shader = ROCK_SHADER
	surface.material_override = finish
	terrain.add_child(surface)
	var body := StaticBody3D.new()
	body.name = "CaveRock"
	terrain.add_child(body)
	rock_collision = CollisionShape3D.new()
	body.add_child(rock_collision)


func _build_station(side: float) -> void:
	var station := Node3D.new()
	station.position.z = side * ENDS
	station.rotation.y = 0.0 if side > 0.0 else PI
	add_child(station)
	var metal := material("373747")
	var fascia := material("eee2d6")
	box(Vector3(0, 1.07, 0), Vector3(0.92, 0.29, 0.16), metal, true, station)
	box(Vector3(0, 0.48, 0), Vector3(0.22, 0.96, 0.17), metal, true, station)
	box(Vector3(0, 1.43, 0), Vector3(0.92, 0.35, 0.15), metal, false, station)
	box(Vector3(0, 1.43, 0.081), Vector3(0.87, 0.30, 0.02), material("242634"), false, station)
	box(Vector3(0, 0.04, 0), Vector3(0.58, 0.08, 0.4), fascia, true, station)
	var status := label("", Vector3.ZERO, 0.001)
	status.reparent(station, false)
	status.position = Vector3(0, 1.43, 0.10)
	status.font_size = 34
	stations.append(status)
	var controls := ["AIR +", "RESET", "ROCK +"]
	for i in controls.size():
		var action: String = controls[i]
		var button := PUSH.instantiate() as Node3D
		button.position = Vector3((i - 1) * 0.28, 1.10, 0.128)
		button.rotation.x = PI / 2
		station.add_child(button)
		Rack.make_button_rectangular(button)
		button.pressed.connect(act.bind(action))
		buttons["%s/%s" % ["south" if side > 0 else "north", action]] = button
		var caption := label(action, Vector3.ZERO, 0.00067)
		caption.reparent(station, false)
		caption.position = button.position + Vector3(0, -0.113, 0.002)
	# Power comes down a visible conduit from the slab above.
	box(Vector3(0, 3.62, -0.04), Vector3(0.065, 4.04, 0.072), metal, false, station)
	box(Vector3(0, 5.58, -0.04), Vector3(0.36, 0.12, 0.32), metal, false, station)


func _mark_routes() -> void:
	var tape := [material("89e3df", true), material("f49abe", true)]
	for lane in LANES.size():
		box(Vector3(LANES[lane], 0.01, 0), Vector3(0.065, 0.012, 9.1), tape[lane])
		for side in [-1.0, 1.0]:
			var mark := label("A  MAIN" if lane == 0 else "B  PINCH",
				Vector3(LANES[lane], 0.025, side * 4.78), 0.0028)
			mark.rotation_degrees = Vector3(-90, 0 if side > 0 else 180, 0)
			mark.modulate = tape[lane].albedo_color
	for z in [-3.85, 3.85]:
		var lamp := OmniLight3D.new()
		lamp.position = Vector3(0, 3.25, z)
		lamp.omni_range = 6.0
		lamp.light_energy = 1.6
		lamp.light_color = Color("f1d1e5")
		add_child(lamp)


func act(action: String) -> void:
	var game := get_tree().get_first_node_in_group("void_game")
	if is_instance_valid(game) and is_instance_valid(game.body):
		var feet := to_local(game.body.global_position)
		if absf(feet.x) < 3.85 and absf(feet.z) < 3.85 and feet.y > -0.4 and feet.y < 4.4:
			_update_status("STEP OUT TO CHANGE CUT")
			return
	var next := 0
	if action == "AIR +":
		next = mini(CUTS.size() - 1, cut_index + 1)
	elif action == "ROCK +":
		next = maxi(0, cut_index - 1)
	actions_taken += 1
	_set_cut(next)


func _set_cut(index: int) -> void:
	if not _variants.has(index):
		_marcher.iso_level = CUTS[index]
		var mesh := _marcher.create_mesh_from_triangles(_marcher.march_cubes(field))
		var arrays := mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			vertices[i] *= SAMPLE_SCALE
		arrays[Mesh.ARRAY_VERTEX] = vertices
		mesh = ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		var collision := mesh.create_trimesh_shape()
		collision.backface_collision = true
		_variants[index] = [mesh, collision]
	cut_index = index
	surface.mesh = _variants[index][0]
	rock_collision.shape = _variants[index][1]
	_update_status("WALK A OR B")


func _update_status(instruction: String) -> void:
	for status in stations:
		status.text = "CAVE THRESHOLD  %+.2f\n%s\nSAME FIELD / SEED 1337" % [CUTS[cut_index], instruction]
