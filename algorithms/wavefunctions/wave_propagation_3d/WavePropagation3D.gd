extends Node3D

@export var grid_size: int = 20
@export var tile_size: float = 0.4
@export var tile_gutter: float = 0.1
@export var tile_height: float = 0.06
@export var floor_tilt_degrees: float = -12.0
@export var frequency: float = 0.7
@export var amplitude: float = 0.5
@export var wave_speed: float = 0.6
@export var wave_damping: float = 0.08

var time: float = 0.0
var tile_positions: Array[Vector2] = []
var tile_multimesh_instance: MultiMeshInstance3D
var tile_multimesh: MultiMesh
var wave_rings: Array = []
var tile_collision_bodies: Array[StaticBody3D] = []

var base_tile_color := Color(0.22, 0.55, 0.85, 1.0)
var peak_tile_color := Color(0.95, 0.85, 0.4, 1.0)

func _ready():
	create_wave_surface()
	#create_wave_rings()
	setup_materials()

func create_wave_surface():
	var surface_parent = $WaveSurface
	var instance = MultiMeshInstance3D.new()
	tile_multimesh_instance = instance
	tile_multimesh = MultiMesh.new()
	var tile_mesh = BoxMesh.new()
	tile_mesh.size = Vector3(tile_size, tile_height, tile_size)
	tile_multimesh.mesh = tile_mesh
	tile_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	tile_multimesh.use_colors = true
	tile_multimesh.set("color_format", 1)  # Fallback for MultiMesh.COLOR_8BIT
	tile_multimesh.instance_count = grid_size * grid_size
	tile_multimesh_instance.multimesh = tile_multimesh
	surface_parent.add_child(tile_multimesh_instance)
	
	# Create collision bodies for each tile
	_create_tile_collision_bodies(surface_parent)
	
	tile_positions.clear()
	var spacing = tile_size + tile_gutter
	var half = (grid_size - 1) * 0.5
	var index = 0
	for x in range(grid_size):
		for z in range(grid_size):
			var pos2 = Vector2((x - half) * spacing, (z - half) * spacing)
			tile_positions.append(pos2)
			var origin = Vector3(pos2.x, tile_height * 0.5, pos2.y)
			var transform = Transform3D(Basis.IDENTITY, origin)
			tile_multimesh.set_instance_transform(index, transform)
			tile_multimesh.set_instance_color(index, base_tile_color)
			index += 1

func create_wave_rings():
	var rings_parent = $WaveRings
	wave_rings.clear()
	var ring_count = 4
	for i in range(ring_count):
		var ring = CSGCylinder3D.new()
		ring.radius = 0.2 + float(i) * 0.9
		ring.height = 0.04
		ring.position.y = -0.4
		rings_parent.add_child(ring)
		wave_rings.append(ring)

func setup_materials():
	var tile_material = StandardMaterial3D.new()
	tile_material.vertex_color_use_as_albedo = true
	tile_material.metallic = 0.0
	tile_material.roughness = 0.4
	tile_material.emission_enabled = true
	tile_material.emission = Color(0.05, 0.08, 0.1, 1.0)
	tile_multimesh_instance.material_override = tile_material
	
	var ring_material = StandardMaterial3D.new()
	ring_material.albedo_color = Color(0.75, 0.82, 1.0, 0.35)
	ring_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ring_material.emission_enabled = true
	ring_material.emission = Color(0.22, 0.22, 0.45, 1.0)
	for ring in wave_rings:
		ring.material_override = ring_material
	
	var source_material = StandardMaterial3D.new()
	source_material.albedo_color = Color(1.0, 0.35, 0.35)
	source_material.emission_enabled = true
	source_material.emission = Color(0.6, 0.1, 0.1)
	$WaveSource.material_override = source_material
	
	var freq_material = StandardMaterial3D.new()
	freq_material.albedo_color = Color(1.0, 0.85, 0.35)
	freq_material.emission_enabled = true
	freq_material.emission = Color(0.35, 0.22, 0.08)
	$FrequencyControl.material_override = freq_material
	
	var amp_material = StandardMaterial3D.new()
	amp_material.albedo_color = Color(0.85, 1.0, 0.35)
	amp_material.emission_enabled = true
	amp_material.emission = Color(0.2, 0.32, 0.08)
	$AmplitudeControl.material_override = amp_material

func _process(delta):
	time += delta
	animate_3d_wave_propagation()
	animate_wave_rings()
	animate_controls()

func animate_3d_wave_propagation():
	if tile_multimesh == null:
		return
	var instance_index = 0
	var tile_half_height = tile_height * 0.5
	for pos2 in tile_positions:
		var distance = pos2.length()
		var wave_phase = distance * frequency - wave_speed * time
		var attenuation = exp(-distance * wave_damping)
		var displacement = amplitude * sin(wave_phase) * attenuation
		var origin = Vector3(pos2.x, tile_half_height + displacement, pos2.y)
		var transform = Transform3D(Basis.IDENTITY, origin)
		tile_multimesh.set_instance_transform(instance_index, transform)
		var intensity = clamp((sin(wave_phase) + 1.0) * 0.5, 0.0, 1.0)
		var color = base_tile_color.lerp(peak_tile_color, intensity)
		tile_multimesh.set_instance_color(instance_index, color)
		
		# Update collision body position to match visual tile
		if instance_index < tile_collision_bodies.size():
			tile_collision_bodies[instance_index].position = origin
		
		instance_index += 1

func animate_wave_rings():
	if wave_rings.is_empty():
		return
	var travel_rate = max(wave_speed * 1.8, 0.01)
	var max_radius = 7.5
	var cycle_duration = max_radius / travel_rate
	for i in range(wave_rings.size()):
		var ring = wave_rings[i]
		var local_time = time - float(i) * 0.9
		if cycle_duration <= 0.0:
			cycle_duration = 1.0
		local_time = fposmod(local_time, cycle_duration)
		var ring_radius = max(0.15, travel_rate * local_time)
		ring.radius = ring_radius
		var fade = clamp(1.0 - local_time * 0.18, 0.0, 1.0)
		var ring_material = ring.material_override as StandardMaterial3D
		if ring_material:
			ring_material.albedo_color.a = fade * 0.35
			ring_material.emission = Color(0.22 * fade, 0.22 * fade, 0.45 * fade, 1.0)

func animate_controls():
	var freq_height = frequency * 0.8
	var freq_size = $FrequencyControl.size
	freq_size.y = max(0.2, freq_height)
	$FrequencyControl.size = freq_size
	$FrequencyControl.position.y = -3.0 + freq_size.y * 0.5
	var amp_height = amplitude * 1.6
	var amp_size = $AmplitudeControl.size
	amp_size.y = max(0.2, amp_height)
	$AmplitudeControl.size = amp_size
	$AmplitudeControl.position.y = -3.0 + amp_size.y * 0.5
	frequency = 0.55 + sin(time * 0.12) * 0.25
	amplitude = 0.22 + cos(time * 0.1) * 0.12
	wave_speed = 0.5 + sin(time * 0.09) * 0.18
	$WaveSource.radius = 0.28 + sin(time * frequency * 2.4) * 0.05

func _create_tile_collision_bodies(surface_parent: Node3D):
	"""Create collision bodies for each tile"""
	tile_collision_bodies.clear()
	
	var spacing = tile_size + tile_gutter
	var half = (grid_size - 1) * 0.5
	
	for x in range(grid_size):
		for z in range(grid_size):
			var pos2 = Vector2((x - half) * spacing, (z - half) * spacing)
			var origin = Vector3(pos2.x, tile_height * 0.5, pos2.y)
			
			# Create StaticBody3D for collision
			var collision_body = StaticBody3D.new()
			collision_body.name = "TileCollision_%d_%d" % [x, z]
			collision_body.position = origin
			
			# Create collision shape
			var collision_shape = CollisionShape3D.new()
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(tile_size, tile_height, tile_size)
			collision_shape.shape = box_shape
			
			collision_body.add_child(collision_shape)
			surface_parent.add_child(collision_body)
			
			# Store reference for animation
			tile_collision_bodies.append(collision_body)
