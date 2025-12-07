extends Node3D

# Pink Floyd "Dark Side of the Moon" Prism Effect in 3D
# Generates a procedural prism and light spectrum

func _ready():
	_create_environment()
	_create_prism()
	_create_light_beams()
	_create_camera()

func _create_environment():
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.05, 0.05, 0.05) # Nearly black
	env.glow_enabled = true
	env.glow_intensity = 1.0
	env.glow_strength = 1.1
	env.glow_bloom = 0.2
	env_node.environment = env
	add_child(env_node)

func _create_camera():
	var cam = Camera3D.new()
	cam.position = Vector3(0, 0, 5)
	add_child(cam)

func _create_prism():
	var prism = MeshInstance3D.new()
	var mesh = PrismMesh.new()
	mesh.size = Vector3(2.5, 2.5, 1.0)
	prism.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.1, 0.1, 0.1, 0.4)
	material.metallic = 0.8
	material.roughness = 0.1
	material.refraction_enabled = true
	material.refraction_scale = 0.05
	
	# Rim for the white outline effect
	material.rim_enabled = true
	material.rim = 0.5
	material.rim_tint = 1.0
	
	# Emission for edges (using a wireframe trick or just rim)
	# Since proper wireframe is hard in GDScript only, we rely on rim and specific lights
	
	prism.material_override = material
	
	# Rotate to face camera correctly (PrismMesh points up Y, flat on Z?)
	# PrismMesh: triangle base is on XZ plane? No, default is standing up.
	# Let's assume standard orientation.
	
	add_child(prism)
	
	# Add some edge lines for the "Album Cover" look
	_add_prism_edges(prism, mesh.size)

func _add_prism_edges(parent, size):
	# Create a simple wireframe triangle using 3 thin cylinders
	var corners = [
		Vector3(0, size.y/2, size.z/2),    # Top Front
		Vector3(size.x/2, -size.y/2, size.z/2),  # Bottom Right Front
		Vector3(-size.x/2, -size.y/2, size.z/2)  # Bottom Left Front
	]
	# And corresponding Back points...
	# The album cover is flat-ish, but let's just outline the front face
	
	_create_line_segment(parent, corners[0], corners[1])
	_create_line_segment(parent, corners[1], corners[2])
	_create_line_segment(parent, corners[2], corners[0])

func _create_line_segment(parent, p1, p2):
	var line = MeshInstance3D.new()
	var length = p1.distance_to(p2)
	var mesh = CylinderMesh.new()
	mesh.top_radius = 0.02
	mesh.bottom_radius = 0.02
	mesh.height = length
	line.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.8, 0.8, 0.8) # Off-white outline
	line.material_override = material
	
	line.position = (p1 + p2) / 2.0
	
	# Align cylinder (which is along Y) to the vector p2-p1
	# look_at aligns -Z... we need to align Y.
	# Standard way:
	if p1 != p2:
		var direction = (p2 - p1).normalized()
		# Create a basis where Y is direction
		# Or use look_at and rotate 90 deg?
		line.look_at(p2, Vector3.UP if abs(direction.y) < 0.99 else Vector3.RIGHT)
		line.rotate_object_local(Vector3(1, 0, 0), -PI/2) # Rotate so cylinder Y aligns with look_at Z
	
	parent.add_child(line)

func _create_light_beams():
	# Beam Parameters
	# Beam Parameters
	var input_start = Vector3(-4, -0.5, 0) # Coming from lower left
	var prism_hit = Vector3(-0.6, 0.2, 0) # Hitting left face (Z=0 centered)
	var prism_exit_start = Vector3(0.6, 0.2, 0) # Exiting right face
	
	# 1. White Input Beam
	var white_beam = _create_beam_mesh(input_start, prism_hit, Color.WHITE, 0.05)
	add_child(white_beam)
	
	# 2. Internal Refraction (faint)
	var internal_beam = _create_beam_mesh(prism_hit, prism_exit_start, Color(1, 1, 1, 0.3), 0.06)
	add_child(internal_beam)
	
	# 3. Output Spectrum
	var colors = [
		Color.RED,
		Color(1, 0.5, 0), # Orange
		Color.YELLOW,
		Color.GREEN,
		Color.BLUE,
		Color(0.29, 0, 0.51), # Indigo
		Color(0.56, 0, 1) # Violet
	]
	
	var spread_start = prism_exit_start
	var spread_dist = 6.0
	
	for i in range(colors.size()):
		var t = float(i) / (colors.size() - 1)
		
		# Physics: Light bends towards base (down).
		# Red bends least, Violet most.
		# All should go downward relative to horizontal.
		var y_offset = lerp(-0.5, -2.5, t) 
		var end_pos = spread_start + Vector3(spread_dist, y_offset, 0)
		
		var beam = _create_beam_mesh(spread_start, end_pos, colors[i], 0.08)
		add_child(beam)

func _create_beam_mesh(start: Vector3, end: Vector3, color: Color, thickness: float) -> MeshInstance3D:
	var beam = MeshInstance3D.new()
	var mesh = BoxMesh.new()
	
	var length = start.distance_to(end)
	mesh.size = Vector3(thickness, thickness, length)
	beam.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	# Add some emission for glow
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = 2.0
	beam.material_override = material
	
	beam.position = (start + end) / 2.0
	beam.look_at(end)
	
	return beam
