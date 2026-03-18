extends Node3D

@export var room_size: Vector3 = Vector3(6, 4, 10)
@export var wall_thickness: float = 0.5
@export var breath_speed: float = 1.0
@export var breath_amplitude: float = 0.5 # Pressure variation

var _walls: Array[SoftBody3D] = []
var _time: float = 0.0

func _ready() -> void:
	setup_scene()
	setup_room()

func setup_scene() -> void:
	var cam = Camera3D.new()
	cam.position = Vector3(0, 2, room_size.z/2.0 + 2)
	cam.look_at(Vector3(0, 2, 0))
	add_child(cam)
	
	var light = OmniLight3D.new()
	light.position = Vector3(0, room_size.y - 1, 0)
	light.omni_range = 15.0
	light.light_color = Color(0.8, 0.9, 1.0)
	add_child(light)
	
	# Floor (Static)
	var floor_body = StaticBody3D.new()
	var fm = BoxMesh.new()
	fm.size = Vector3(room_size.x, 0.5, room_size.z)
	var fmi = MeshInstance3D.new()
	fmi.mesh = fm
	floor_body.add_child(fmi)
	var fcol = CollisionShape3D.new()
	fcol.shape = BoxShape3D.new()
	(fcol.shape as BoxShape3D).size = fm.size
	floor_body.add_child(fcol)
	add_child(floor_body)

func setup_room() -> void:
	# Create 2 side walls as SoftBodies
	# They need to be closed meshes (Boxes) to have pressure
	
	var wall_mesh = BoxMesh.new()
	wall_mesh.size = Vector3(wall_thickness, room_size.y, room_size.z)
	wall_mesh.subdivide_height = 8
	wall_mesh.subdivide_depth = 12
	wall_mesh.subdivide_width = 2
	
	# Left Wall
	create_breathing_wall(wall_mesh, Vector3(-room_size.x/2.0, room_size.y/2.0, 0))
	
	# Right Wall
	create_breathing_wall(wall_mesh, Vector3(room_size.x/2.0, room_size.y/2.0, 0))
	
	# Ceiling (Static for stability, or soft?) Let's make it static for now to hold the structure visually
	var ceiling = StaticBody3D.new()
	ceiling.position = Vector3(0, room_size.y, 0)
	var cm = BoxMesh.new()
	cm.size = Vector3(room_size.x, 0.5, room_size.z)
	var cmi = MeshInstance3D.new()
	cmi.mesh = cm
	ceiling.add_child(cmi)
	add_child(ceiling)

func create_breathing_wall(mesh: Mesh, pos: Vector3) -> void:
	var sb = SoftBody3D.new()
	sb.mesh = mesh
	sb.position = pos
	
	sb.total_mass = 5.0
	sb.linear_stiffness = 0.5
	sb.pressure_coefficient = 0.0 # Start neutral
	sb.damping_coefficient = 0.1
	sb.simulation_precision = 5
	
	# Material: Organic/Fleshy
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.5, 0.5)
	mat.subsurf_scatter_enabled = true
	mat.subsurf_scatter_strength = 0.8
	mat.subsurf_scatter_skin_mode = true
	sb.material_override = mat
	
	sb.collision_layer = 1
	sb.collision_mask = 1 | 524288
	
	add_child(sb)
	_walls.append(sb)
	
	# Pin the back side (the side touching the "frame" or outer world) so it expands inward
	# Or just pin top and bottom edges
	call_deferred("_pin_wall_edges", sb)

func _pin_wall_edges(sb: SoftBody3D) -> void:
	if not is_instance_valid(sb): return
	
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(sb.mesh, 0)
	
	var h = room_size.y
	var d = room_size.z
	var t = wall_thickness
	
	# Local bounds approx: y from -h/2 to h/2, z from -d/2 to d/2
	# We pin top and bottom rows
	
	var pinned_indices = []
	for i in range(mdt.get_vertex_count()):
		var v = mdt.get_vertex(i)
		# Pin top and bottom
		if abs(v.y - h/2.0) < 0.1 or abs(v.y + h/2.0) < 0.1:
			pinned_indices.append(i)
		# Pin ends (front/back) too?
		if abs(v.z - d/2.0) < 0.1 or abs(v.z + d/2.0) < 0.1:
			pinned_indices.append(i)
			
	for idx in pinned_indices:
		sb.set_point_pinned(idx, true, NodePath())

func _process(delta: float) -> void:
	_time += delta * breath_speed
	
	# Oscillate pressure
	# Base pressure 0, go up to amplitude
	var p = (sin(_time) + 1.0) * 0.5 * breath_amplitude
	
	for sb in _walls:
		sb.pressure_coefficient = p

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
