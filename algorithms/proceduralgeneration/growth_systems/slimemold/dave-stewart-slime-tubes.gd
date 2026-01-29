extends Node3D

# Dave Stewart-inspired Slimy Pools and Tubes Generator
# Creates viscous, organic tubular forms with pooling liquid effects

# Configuration
@export var pool_count: int = 5
@export var tube_segments_per_pool: int = 3
@export var pool_size_min: float = 2.0
@export var pool_size_max: float = 6.0
@export var tube_thickness_min: float = 0.3
@export var tube_thickness_max: float = 1.2
@export var viscosity: float = 0.7
@export var glossiness: float = 0.9
@export var color_primary: Color = Color(0.05, 0.4, 0.38)
@export var color_secondary: Color = Color(0.2, 0.65, 0.3)
@export var color_highlight: Color = Color(0.7, 0.9, 0.6)
@export var drip_amount: float = 1.5
@export var animation_speed: float = 0.2
@export_range(0.0, 1.0) var bubbles_amount: float = 0.6

# Internal variables
var noise = FastNoiseLite.new()
var time: float = 0.0
var pools = []
var tubes = []
var drips = []
var bubbles = []

# Materials
var slime_material: StandardMaterial3D
var tube_material: StandardMaterial3D
var bubble_material: StandardMaterial3D

func _ready():
	# Set up noise for organic deformation
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = 0.08
	
	# Create materials
	create_materials()
	
	# Generate initial scene
	generate_scene()

func _process(delta):
	time += delta * animation_speed
	
	# Animate drips
	update_drips(delta)
	
	# Animate bubbles
	update_bubbles(delta)
	
	# Slow continuous deformation of tubes
	update_tubes(delta)

func create_materials():
	# Main slime material (pools)
	slime_material = StandardMaterial3D.new()
	slime_material.albedo_color = color_primary
	slime_material.metallic = 0.1
	slime_material.metallic_specular = 0.9
	slime_material.roughness = 1.0 - glossiness
	slime_material.refraction_enabled = true
	slime_material.refraction_scale = 0.05
	slime_material.subsurf_scatter_enabled = true
	slime_material.subsurf_scatter_strength = 0.3
	slime_material.subsurf_scatter_texture = create_noise_texture()
	
	# Tube material (slightly different from pools)
	tube_material = slime_material.duplicate()
	tube_material.albedo_color = color_secondary
	tube_material.emission_enabled = true
	tube_material.emission = color_secondary * 0.2
	
	# Bubble material
	bubble_material = StandardMaterial3D.new()
	bubble_material.albedo_color = color_highlight.lightened(0.2)
	bubble_material.metallic = 0.0
	bubble_material.roughness = 0.1
	bubble_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bubble_material.albedo_color.a = 0.6
	bubble_material.emission_enabled = true
	bubble_material.emission = color_highlight * 0.3

func create_noise_texture() -> NoiseTexture2D:
	var texture = NoiseTexture2D.new()
	texture.noise = FastNoiseLite.new()
	texture.noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	texture.noise.seed = randi()
	texture.noise.frequency = 0.04
	texture.seamless = true
	texture.width = 512
	texture.height = 512
	return texture

func generate_scene():
	clear_scene()
	
	# Generate pools at various positions
	var positions = []
	for i in range(pool_count):
		var position = Vector3(
			randf_range(-10.0, 10.0),
			randf_range(-3.0, 3.0),
			randf_range(-10.0, 10.0)
		)
		
		# Keep pools somewhat separate
		var too_close = false
		for existing_pos in positions:
			if position.distance_to(existing_pos) < 5.0:
				too_close = true
				break
		
		if too_close:
			position = Vector3(
				randf_range(-10.0, 10.0),
				randf_range(-3.0, 3.0),
				randf_range(-10.0, 10.0)
			)
		
		positions.append(position)
		generate_pool(position)
	
	# Connect pools with tubes
	connect_pools_with_tubes()
	
	# Add drips
	generate_drips()
	
	# Add bubbles
	generate_bubbles()

func generate_pool(position: Vector3):
	var pool_size = randf_range(pool_size_min, pool_size_max)
	
	# Create base mesh for pool
	var pool_mesh = SphereMesh.new()
	pool_mesh.radius = pool_size
	pool_mesh.height = pool_size * 1.2
	
	# Flatten the pool to create a puddle-like shape
	pool_mesh.radius = pool_size
	pool_mesh.height = pool_size * 0.7
	
	# Create mesh instance
	var pool_instance = MeshInstance3D.new()
	pool_instance.mesh = pool_mesh
	pool_instance.material_override = slime_material
	
	# Add some noise-based deformation
	var surface_tool = SurfaceTool.new()
	surface_tool.create_from(pool_mesh, 0)
	
	var array_mesh = surface_tool.commit()
	var mdt = MeshDataTool.new()
	mdt.create_from_surface(array_mesh, 0)
	
	# Deform vertices to create organic shape
	for i in range(mdt.get_vertex_count()):
		var vertex = mdt.get_vertex(i)
		var direction = vertex.normalized()
		
		# Apply noise-based displacement
		var noise_val = noise.get_noise_3dv(vertex * 0.5 + Vector3(0, time * 0.1, 0))
		var displacement = direction * noise_val * pool_size * 0.3 * viscosity
		
		# Extra displacement at bottom to create dripping effect
		if vertex.y < 0:
			displacement.y -= abs(vertex.y) * drip_amount * 0.2
		
		mdt.set_vertex(i, vertex + displacement)
	
	# Reconstruct the mesh
	mdt.commit_to_surface(array_mesh)
	pool_instance.mesh = array_mesh
	
	# Position and add to scene
	pool_instance.position = position
	pool_instance.rotation = Vector3(randf_range(0, PI), randf_range(0, PI), randf_range(0, PI))
	add_child(pool_instance)
	
	# Store reference
	pools.append({"instance": pool_instance, "position": position, "size": pool_size})

func connect_pools_with_tubes():
	# Create tubes that connect some pools
	for i in range(pools.size()):
		var start_pool = pools[i]
		
		# Each pool connects to up to 2 others
		for j in range(min(2, tube_segments_per_pool)):
			# Find a target pool that's not too far away
			var potential_targets = []
			for k in range(pools.size()):
				if k != i:
					var distance = start_pool["position"].distance_to(pools[k]["position"])
					if distance < 20.0:
						potential_targets.append(k)
			
			if potential_targets.size() > 0:
				var target_idx = potential_targets[randi() % potential_targets.size()]
				var end_pool = pools[target_idx]
				
				generate_tube(start_pool, end_pool)

func generate_tube(start_pool, end_pool):
	var start_pos = start_pool["position"]
	var end_pos = end_pool["position"]
	var start_radius = start_pool["size"] * 0.5
	var end_radius = end_pool["size"] * 0.5
	
	# Create a path for the tube
	var path = Curve3D.new()
	path.add_point(start_pos)
	
	# Add some control points to make tube curve organically
	var distance = start_pos.distance_to(end_pos)
	var mid_point = (start_pos + end_pos) / 2.0
	
	# Add vertical displacement to create drooping
	mid_point.y -= distance * 0.15 * viscosity
	
	# Add random horizontal displacement
	var perpendicular = Vector3(
		randf_range(-1.0, 1.0),
		0.0,
		randf_range(-1.0, 1.0)
	).normalized() * distance * 0.3
	mid_point += perpendicular
	
	# Add control points
	path.add_point(mid_point)
	path.add_point(end_pos)
	
	# Create the tube mesh
	var tube_thickness = randf_range(tube_thickness_min, tube_thickness_max)
	var tube_mesh = create_tube_mesh(path, tube_thickness)
	
	# Create mesh instance
	var tube_instance = MeshInstance3D.new()
	tube_instance.mesh = tube_mesh
	tube_instance.material_override = tube_material
	add_child(tube_instance)
	
	# Store for animation
	tubes.append({
		"instance": tube_instance, 
		"path": path,
		"thickness": tube_thickness,
		"start_pool": start_pool,
		"end_pool": end_pool
	})

func create_tube_mesh(path: Curve3D, thickness: float) -> Mesh:
	# Create a tube along the path
	var path_follow = PathFollow3D.new()
	
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var resolution = 24  # Circle resolution
	var path_steps = 24  # Path resolution
	
	var rings = []
	
	# Create vertices along the path
	for i in range(path_steps + 1):
		var t = float(i) / path_steps
		var path_point = path.sample_baked(path.get_baked_length() * t)
		
		# Get direction for tube at this point
		var forward_dir
		if i < path_steps:
			forward_dir = (path.sample_baked(path.get_baked_length() * (t + 0.01)) - path_point).normalized()
		else:
			forward_dir = (path_point - path.sample_baked(path.get_baked_length() * (t - 0.01))).normalized()
		
		# Create up vector (arbitrary but consistent)
		var up_dir = Vector3.UP
		if abs(forward_dir.dot(up_dir)) > 0.9:
			up_dir = Vector3.FORWARD
		
		var right_dir = forward_dir.cross(up_dir).normalized()
		up_dir = right_dir.cross(forward_dir).normalized()
		
		# Create ring of vertices
		var ring = []
		for j in range(resolution):
			var angle = j * TAU / resolution
			var dir = (right_dir * cos(angle) + up_dir * sin(angle)).normalized()
			
			# Apply some noise to thickness for organic feel
			var noise_val = noise.get_noise_3dv(path_point * 0.2 + Vector3(0, time * 0.1, 0))
			var varied_thickness = thickness * (1.0 + noise_val * 0.3 * viscosity)
			
			# Extra deformation on lower side of tube to create drooping
			if dir.y < 0:
				dir.y -= abs(dir.y) * drip_amount * 0.1
			
			var vertex = path_point + dir * varied_thickness
			ring.append(vertex)
		
		rings.append(ring)
	
	# Create triangles between rings
	for i in range(path_steps):
		var ring1 = rings[i]
		var ring2 = rings[i + 1]
		
		for j in range(resolution):
			var j_next = (j + 1) % resolution
			
			# Create two triangles for a quad
			surface_tool.add_vertex(ring1[j])
			surface_tool.add_vertex(ring2[j])
			surface_tool.add_vertex(ring1[j_next])
			
			surface_tool.add_vertex(ring1[j_next])
			surface_tool.add_vertex(ring2[j])
			surface_tool.add_vertex(ring2[j_next])
	
	surface_tool.generate_normals()
	return surface_tool.commit()

func generate_drips():
	# Create drip effects hanging from pools and tubes
	var drip_count = int(pool_count * drip_amount)
	
	for i in range(drip_count):
		# Choose a random pool or tube to drip from
		var source
		var position
		var is_pool = randf() < 0.7  # 70% chance to drip from pool, 30% from tube
		
		if is_pool and pools.size() > 0:
			source = pools[randi() % pools.size()]
			
			# Random position on bottom half of pool
			var pool_radius = source["size"]
			var angle = randf() * TAU
			var radius_factor = randf() * 0.8
			position = source["position"] + Vector3(
				cos(angle) * pool_radius * radius_factor,
				-pool_radius * (0.3 + randf() * 0.3),
				sin(angle) * pool_radius * radius_factor
			)
		elif tubes.size() > 0:
			var tube = tubes[randi() % tubes.size()]
			var t = randf()
			position = tube["path"].sample_baked(tube["path"].get_baked_length() * t)
			position.y -= tube["thickness"] * 1.2
		else:
			# Fallback if no pools or tubes
			position = Vector3(randf_range(-5, 5), randf_range(-2, 0), randf_range(-5, 5))
		
		generate_drip(position)

func generate_drip(position: Vector3):
	var drip_length = randf_range(1.0, 3.0) * drip_amount
	var drip_width = randf_range(0.2, 0.6)
	
	# Create drip mesh (elongated teardrop shape)
	var drip_mesh = create_drip_mesh(drip_length, drip_width)
	
	var drip_instance = MeshInstance3D.new()
	drip_instance.mesh = drip_mesh
	drip_instance.material_override = slime_material
	drip_instance.position = position
	
	add_child(drip_instance)
	
	drips.append({
		"instance": drip_instance,
		"position": position,
		"length": drip_length,
		"width": drip_width,
		"growth_factor": 0.0,
		"max_growth": randf_range(0.8, 1.2),
		"growth_speed": randf_range(0.1, 0.4) * animation_speed
	})

func create_drip_mesh(length: float, width: float) -> Mesh:
	var surface_tool = SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var resolution = 12
	var segments = 8
	
	# Create rings going down the drip, getting narrower
	for i in range(segments + 1):
		var t = float(i) / segments
		var y = -length * t
		
		# Width narrows as we go down
		var current_width = width * (1.0 - t * 0.9)
		if i == segments:  # Make the tip pointy
			current_width = width * 0.05
		
		# Create ring of vertices
		for j in range(resolution):
			var angle = j * TAU / resolution
			var vertex = Vector3(
				cos(angle) * current_width,
				y,
				sin(angle) * current_width
			)
			
			# Apply slight noise
			var noise_val = noise.get_noise_3dv(vertex * 3.0)
			vertex += vertex.normalized() * noise_val * 0.05
			
			surface_tool.add_vertex(vertex)
	
	# Create triangles between rings
	for i in range(segments):
		var base_index = i * resolution
		
		for j in range(resolution):
			var j_next = (j + 1) % resolution
			
			# Connect one ring to the next
			surface_tool.add_vertex(Vector3(
				cos(j * TAU / resolution) * width * (1.0 - float(i) / segments * 0.9),
				-length * float(i) / segments,
				sin(j * TAU / resolution) * width * (1.0 - float(i) / segments * 0.9)
			))
			
			surface_tool.add_vertex(Vector3(
				cos(j * TAU / resolution) * width * (1.0 - float(i+1) / segments * 0.9),
				-length * float(i+1) / segments,
				sin(j * TAU / resolution) * width * (1.0 - float(i+1) / segments * 0.9)
			))
			
			surface_tool.add_vertex(Vector3(
				cos(j_next * TAU / resolution) * width * (1.0 - float(i) / segments * 0.9),
				-length * float(i) / segments,
				sin(j_next * TAU / resolution) * width * (1.0 - float(i) / segments * 0.9)
			))
			
			surface_tool.add_vertex(Vector3(
				cos(j_next * TAU / resolution) * width * (1.0 - float(i) / segments * 0.9),
				-length * float(i) / segments,
				sin(j_next * TAU / resolution) * width * (1.0 - float(i) / segments * 0.9)
			))
			
			surface_tool.add_vertex(Vector3(
				cos(j * TAU / resolution) * width * (1.0 - float(i+1) / segments * 0.9),
				-length * float(i+1) / segments,
				sin(j * TAU / resolution) * width * (1.0 - float(i+1) / segments * 0.9)
			))
			
			surface_tool.add_vertex(Vector3(
				cos(j_next * TAU / resolution) * width * (1.0 - float(i+1) / segments * 0.9),
				-length * float(i+1) / segments,
				sin(j_next * TAU / resolution) * width * (1.0 - float(i+1) / segments * 0.9)
			))
	
	surface_tool.generate_normals()
	return surface_tool.commit()

func generate_bubbles():
	# Create bubbles inside pools and tubes
	var bubble_count = int(15 * bubbles_amount)
	
	for i in range(bubble_count):
		var position
		var source_type
		
		if randf() < 0.8 and pools.size() > 0:  # 80% chance for bubbles in pools
			var pool = pools[randi() % pools.size()]
			var radius = pool["size"] * randf() * 0.8
			var angle = randf() * TAU
			var height_factor = randf() * 0.6 - 0.3  # -0.3 to 0.3
			
			position = pool["position"] + Vector3(
				cos(angle) * radius,
				pool["size"] * height_factor,
				sin(angle) * radius
			)
			source_type = "pool"
		elif tubes.size() > 0:
			var tube = tubes[randi() % tubes.size()]
			var t = randf()
			position = tube["path"].sample_baked(tube["path"].get_baked_length() * t)
			
			# Random position within tube
			var random_dir = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized()
			position += random_dir * tube["thickness"] * randf() * 0.7
			source_type = "tube"
		else:
			position = Vector3(randf_range(-5, 5), randf_range(-2, 2), randf_range(-5, 5))
			source_type = "free"
		
		var bubble_size = randf_range(0.1, 0.5)
		var bubble_mesh = SphereMesh.new()
		bubble_mesh.radius = bubble_size
		bubble_mesh.height = bubble_size * 2
		
		var bubble_instance = MeshInstance3D.new()
		bubble_instance.mesh = bubble_mesh
		bubble_instance.material_override = bubble_material
		bubble_instance.position = position
		
		add_child(bubble_instance)
		
		bubbles.append({
			"instance": bubble_instance,
			"position": position,
			"size": bubble_size,
			"rise_speed": randf_range(0.1, 0.3) * animation_speed,
			"wobble_factor": randf_range(0.2, 0.5),
			"source_type": source_type,
			"source_index": randi() % pools.size() if source_type == "pool" else randi() % tubes.size()
		})

func update_drips(delta):
	for drip in drips:
		drip["growth_factor"] += drip["growth_speed"] * delta
		
		if drip["growth_factor"] >= drip["max_growth"]:
			# Reset drip to begin growing again
			drip["growth_factor"] = 0
			
			# Move drip to a new position on a pool
			if pools.size() > 0:
				var pool = pools[randi() % pools.size()]
				var pool_radius = pool["size"]
				var angle = randf() * TAU
				var radius_factor = randf() * 0.8
				
				drip["position"] = pool["position"] + Vector3(
					cos(angle) * pool_radius * radius_factor,
					-pool_radius * (0.3 + randf() * 0.3),
					sin(angle) * pool_radius * radius_factor
				)
				
				drip["instance"].position = drip["position"]
			
			# Create new drip mesh with random dimensions
			drip["length"] = randf_range(1.0, 3.0) * drip_amount
			drip["width"] = randf_range(0.2, 0.6)
		
		# Update drip mesh based on growth factor
		var current_length = drip["length"] * min(drip["growth_factor"], 1.0)
		var drip_mesh = create_drip_mesh(current_length, drip["width"])
		drip["instance"].mesh = drip_mesh

func update_bubbles(delta):
	for bubble in bubbles:
		# Make bubbles rise and wobble
		var old_pos = bubble["instance"].position
		
		# Rising movement
		old_pos.y += bubble["rise_speed"] * delta
		
		# Wobbling movement
		old_pos.x += sin(time * 2.0 + old_pos.y) * bubble["wobble_factor"] * delta
		old_pos.z += cos(time * 2.3 + old_pos.y) * bubble["wobble_factor"] * delta
		
		bubble["instance"].position = old_pos
		
		# If bubble rises too high, reset it
		if bubble["source_type"] == "pool":
			var pool = pools[bubble["source_index"] % pools.size()]
			if old_pos.y > pool["position"].y + pool["size"] * 0.5:
				reset_bubble(bubble)
		elif bubble["source_type"] == "tube":
			if old_pos.y > 5.0:  # Arbitrary upper limit
				reset_bubble(bubble)
		else:
			if old_pos.y > 5.0:
				reset_bubble(bubble)

func reset_bubble(bubble):
	# Reset bubble to a new position
	if randf() < 0.8 and pools.size() > 0:
		var pool_index = randi() % pools.size()
		var pool = pools[pool_index]
		var radius = pool["size"] * randf() * 0.8
		var angle = randf() * TAU
		
		bubble["position"] = pool["position"] + Vector3(
			cos(angle) * radius,
			-pool["size"] * 0.3,  # Start at bottom of pool
			sin(angle) * radius
		)
		bubble["source_type"] = "pool"
		bubble["source_index"] = pool_index
	elif tubes.size() > 0:
		var tube_index = randi() % tubes.size()
		var tube = tubes[tube_index]
		var t = randf()
		var position = tube["path"].sample_baked(tube["path"].get_baked_length() * t)
		
		# Random position within tube
		var random_dir = Vector3(randf_range(-1,1), randf_range(-1,1), randf_range(-1,1)).normalized()
		position += random_dir * tube["thickness"] * randf() * 0.7
		
		bubble["position"] = position
		bubble["source_type"] = "tube"
		bubble["source_index"] = tube_index
	
	bubble["instance"].position = bubble["position"]
	bubble["size"] = randf_range(0.1, 0.5)
	
	var bubble_mesh = SphereMesh.new()
	bubble_mesh.radius = bubble["size"]
	bubble_mesh.height = bubble["size"] * 2
	bubble["instance"].mesh = bubble_mesh

func update_tubes(delta):
	for tube in tubes:
		# Slowly deform tubes over time
		var tube_mesh = create_tube_mesh(tube["path"], tube["thickness"])
		tube["instance"].mesh = tube_mesh

func clear_scene():
	# Clear existing elements
	for child in get_children():
		if child is MeshInstance3D:
			child.queue_free()
	
	pools = []
	tubes = []
	drips = []
	bubbles = []

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			# Regenerate scene
			generate_scene()
