extends Node3D

var time = 0.0
var current_iteration = 0
var max_iterations = 5
var iteration_timer = 0.0
var iteration_interval = 4.0
var tiles = []
var golden_ratio = (1.0 + sqrt(5.0)) / 2.0

# Penrose tile types
enum TileType {
	KITE,
	DART
}

class PenroseTile:
	var type: TileType
	var vertices: Array
	var visual_object: CSGMesh3D
	var level: int
	
	func _init(tile_type: TileType, tile_vertices: Array, tile_level: int = 0):
		type = tile_type
		vertices = tile_vertices
		level = tile_level

func _ready():
	setup_materials()
	initialize_penrose_tiling()

func setup_materials():
	# Iteration control material
	var iter_material = StandardMaterial3D.new()
	iter_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	iter_material.emission_enabled = true
	iter_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$IterationControl.material_override = iter_material
	
	# Tile count material
	var count_material = StandardMaterial3D.new()
	count_material.albedo_color = Color(0.2, 1.0, 0.8, 1.0)
	count_material.emission_enabled = true
	count_material.emission = Color(0.05, 0.3, 0.2, 1.0)
	$TileCount.material_override = count_material

func initialize_penrose_tiling():
	# Start with initial sun pattern
	tiles.clear()
	clear_visual_tiles()
	
	var center = Vector2.ZERO
	var radius = 3.0
	
	# Create 10 kites around center (sun pattern)
	for i in range(10):
		var angle1 = i * 2.0 * PI / 10.0
		var angle2 = (i + 1) * 2.0 * PI / 10.0
		
		var p1 = center
		var p2 = center + Vector2(cos(angle1), sin(angle1)) * radius
		var p3 = center + Vector2(cos(angle2), sin(angle2)) * radius
		var p4 = center + Vector2(cos((angle1 + angle2) * 0.5), sin((angle1 + angle2) * 0.5)) * radius * 0.6
		
		var kite = PenroseTile.new(TileType.KITE, [p1, p2, p4, p3])
		tiles.append(kite)
	
	current_iteration = 0
	update_visual_representation()

func _process(delta):
	time += delta
	iteration_timer += delta
	
	# Advance iteration
	if iteration_timer >= iteration_interval:
		iteration_timer = 0.0
		
		if current_iteration < max_iterations:
			current_iteration += 1
			subdivide_tiles()
		else:
			initialize_penrose_tiling()
	
	animate_penrose_tiling()
	animate_indicators()

func subdivide_tiles():
	var new_tiles = []
	
	for tile in tiles:
		var subdivided = subdivide_tile(tile)
		new_tiles.append_array(subdivided)
	
	tiles = new_tiles
	update_visual_representation()

func subdivide_tile(tile: PenroseTile) -> Array:
	match tile.type:
		TileType.KITE:
			return subdivide_kite(tile)
		TileType.DART:
			return subdivide_dart(tile)
		_:
			return [tile]

func subdivide_kite(kite: PenroseTile) -> Array:
	var v = kite.vertices
	if v.size() != 4:
		return [kite]
	
	# Kite subdivision rule
	var p1 = v[0]  # Tip
	var p2 = v[1]  # Side
	var p3 = v[2]  # Base
	var p4 = v[3]  # Side
	
	# Golden ratio subdivisions
	var q1 = p1 + (p2 - p1) / golden_ratio
	var q2 = p1 + (p4 - p1) / golden_ratio
	
	# Create new smaller kite
	var small_kite = PenroseTile.new(TileType.KITE, [p1, q1, p3, q2], kite.level + 1)
	
	# Create two darts
	var dart1 = PenroseTile.new(TileType.DART, [q1, p2, p3], kite.level + 1)
	var dart2 = PenroseTile.new(TileType.DART, [q2, p3, p4], kite.level + 1)
	
	return [small_kite, dart1, dart2]

func subdivide_dart(dart: PenroseTile) -> Array:
	var v = dart.vertices
	if v.size() != 3:
		return [dart]
	
	# Dart subdivision rule
	var p1 = v[0]  # Tip
	var p2 = v[1]  # Base corner
	var p3 = v[2]  # Base corner
	
	# Golden ratio subdivision
	var q = p2 + (p1 - p2) / golden_ratio
	
	# Create new kite and dart
	var new_kite = PenroseTile.new(TileType.KITE, [p3, q, p1], dart.level + 1)
	var new_dart = PenroseTile.new(TileType.DART, [q, p2, p3], dart.level + 1)
	
	return [new_kite, new_dart]

func clear_visual_tiles():
	for child in $PenroseTiles.get_children():
		child.queue_free()

func update_visual_representation():
	clear_visual_tiles()
	
	for tile in tiles:
		create_visual_tile(tile)

func create_visual_tile(tile: PenroseTile):
	var vertices = tile.vertices
	if vertices.size() < 3:
		return
	
	# Create mesh for tile
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var mesh_vertices = PackedVector3Array()
	var mesh_normals = PackedVector3Array()
	var mesh_indices = PackedInt32Array()
	
	# Convert 2D vertices to 3D
	for vertex in vertices:
		mesh_vertices.append(Vector3(vertex.x, vertex.y, 0))
		mesh_normals.append(Vector3(0, 0, 1))
	
	# Create triangular indices
	if vertices.size() == 3:
		# Triangle (dart)
		mesh_indices.append_array([0, 1, 2])
	elif vertices.size() == 4:
		# Quad (kite) - split into two triangles
		mesh_indices.append_array([0, 1, 2, 0, 2, 3])
	
	arrays[Mesh.ARRAY_VERTEX] = mesh_vertices
	arrays[Mesh.ARRAY_NORMAL] = mesh_normals
	arrays[Mesh.ARRAY_INDEX] = mesh_indices
	
	var mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	
	var tile_mesh = CSGMesh3D.new()
	tile_mesh.mesh = mesh
	
	# Material based on tile type and level
	var tile_material = StandardMaterial3D.new()
	
	if tile.type == TileType.KITE:
		var level_intensity = tile.level / 5.0
		tile_material.albedo_color = Color(
			0.8 + level_intensity * 0.2,
			0.3 + level_intensity * 0.4,
			0.2,
			1.0
		)
	else:  # DART
		var level_intensity = tile.level / 5.0
		tile_material.albedo_color = Color(
			0.2,
			0.3 + level_intensity * 0.4,
			0.8 + level_intensity * 0.2,
			1.0
		)
	
	tile_material.emission_enabled = true
	tile_material.emission = tile_material.albedo_color * 0.3
	
	# Add outline
	tile_material.flags_use_point_size = true
	tile_material.no_depth_test = false
	tile_material.vertex_color_use_as_albedo = true
	
	tile_mesh.material_override = tile_material
	tile.visual_object = tile_mesh
	
	$PenroseTiles.add_child(tile_mesh)

func animate_penrose_tiling():
	# Animate tiles with subtle effects
	for i in range($PenroseTiles.get_child_count()):
		var tile_visual = $PenroseTiles.get_child(i)
		
		# Gentle pulsing
		var pulse = 1.0 + sin(time * 3.0 + i * 0.2) * 0.1
		tile_visual.scale = Vector3.ONE * pulse
		
		# Subtle rotation
		tile_visual.rotation_degrees.z += 5.0 * get_process_delta_time()

func animate_indicators():
	# Iteration control
	var iter_height = (current_iteration + 1) * 0.4 + 0.5
	$IterationControl.size.y = iter_height
	$IterationControl.position.y = -3 + iter_height/2
	
	# Tile count indicator
	var tile_count = tiles.size()
	var max_tiles = 1000  # Rough estimate
	var count_height = (float(tile_count) / max_tiles) * 2.0 + 0.5
	$TileCount.size.y = count_height
	$TileCount.position.y = -3 + count_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$IterationControl.scale.x = pulse
	$TileCount.scale.x = pulse
	
	# Update colors based on iteration
	var iter_material = $IterationControl.material_override as StandardMaterial3D
	if iter_material:
		var intensity = float(current_iteration) / max_iterations
		iter_material.albedo_color = Color(
			1.0,
			0.8 - intensity * 0.3,
			0.2 + intensity * 0.6,
			1.0
		)
		iter_material.emission = iter_material.albedo_color * 0.3

func get_tiling_info() -> Dictionary:
	var kite_count = 0
	var dart_count = 0
	
	for tile in tiles:
		if tile.type == TileType.KITE:
			kite_count += 1
		else:
			dart_count += 1
	
	return {
		"iteration": current_iteration,
		"total_tiles": tiles.size(),
		"kites": kite_count,
		"darts": dart_count,
		"golden_ratio": golden_ratio
	}
