extends Node3D

# Pink Floyd "Dark Side of the Moon" Prism Effect in 3D
# Generates a procedural prism and light spectrum using standard geometry

func _ready() -> void:
	_create_environment()
	_create_prism()
	# Disable old beams, use trace lines
	_create_trace_beams()
	_create_camera()

func _create_environment() -> void:
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.0, 0.0, 0.0) # Pure black
	env.glow_enabled = true
	env.glow_intensity = 1.5
	env.glow_strength = 1.3
	env.glow_bloom = 0.5 # High bloom for neon look
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env_node.environment = env
	add_child(env_node)

func _create_camera() -> void:
	var cam = Camera3D.new()
	cam.position = Vector3(0, 0, 4)
	add_child(cam)

func _create_prism() -> void:
	var prism = MeshInstance3D.new()
	var mesh = PrismMesh.new()
	mesh.size = Vector3(2.5, 2.5, 0.5) # Flatter depth
	prism.mesh = mesh
	
	var material = StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.1, 0.1, 0.1, 0.2)
	material.metallic = 0.5
	material.roughness = 0.1
	material.refraction_enabled = true
	material.refraction_scale = 0.05
	
	# Rim for the white outline effect
	material.rim_enabled = true
	material.rim = 0.8
	material.rim_tint = 1.0
	
	prism.material_override = material
	
	# PrismMesh default: Triangle points UP Y. Faces Z forward/back.
	# We want it facing camera Z.
	# This seems correct by default.
	
	add_child(prism)
	
	# Add subtle edge outlines
	_add_prism_edges(prism, mesh.size)

func _add_prism_edges(parent, size) -> void:
	# Create a simple wireframe triangle using ImmediateMesh for crisp lines
	var im = ImmediateMesh.new()
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.mesh = im
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.6, 0.6, 0.6) # Subtle grey outline
	mesh_inst.material_override = mat
	
	parent.add_child(mesh_inst)
	
	var top = Vector3(0, size.y/2, size.z/2)
	var br = Vector3(size.x/2, -size.y/2, size.z/2)
	var bl = Vector3(-size.x/2, -size.y/2, size.z/2)
	
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	im.surface_add_vertex(bl)
	im.surface_add_vertex(top)
	im.surface_add_vertex(br)
	im.surface_add_vertex(bl) # Close loop
	im.surface_end()


# --- TRACE BEAM SYSTEM (ImmediateMesh Lines) ---

func _create_trace_beams() -> void:
	var beam_root = MeshInstance3D.new()
	var im = ImmediateMesh.new()
	beam_root.mesh = im
	add_child(beam_root)
	
	# Material: Unshaded, Vertex Color
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 2.0
	beam_root.material_override = mat
	
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	
	# 1. Input Beam (White)
	var start = Vector3(-4, -0.2, 0)
	var hit = Vector3(-0.5, 0.0, 0) # Hit side
	_draw_line(im, start, hit, Color(2, 2, 2)) # Overbright white
	
	# 2. Internal Beam (White/Faint)
	var center = Vector3(0, 0, 0) # Approximate center path
	var exit = Vector3(0.5, 0.0, 0) # Exit right side
	_draw_line(im, hit, exit, Color(1, 1, 1, 0.5))
	
	# 3. Output Spectrum (Fan)
	var spectrum = [
		Color(1, 0, 0),       # Red
		Color(1, 0.5, 0),     # Orange
		Color(1, 1, 0),       # Yellow
		Color(0, 1, 0),       # Green
		Color(0, 0.5, 1),     # Blue
		Color(0.3, 0, 0.5),   # Indigo
		Color(0.6, 0, 1)      # Violet
	]
	
	var fan_length = 5.0
	# Fan spreads vertically as it goes right
	var top_y = -0.5
	var bottom_y = -2.0
	
	for i in range(spectrum.size()):
		var t = float(i) / (spectrum.size() - 1)
		var color = spectrum[i]
		# Overbright colors for glow
		color.r *= 1.5
		color.g *= 1.5
		color.b *= 1.5
		
		var y_target = lerp(top_y, bottom_y, t)
		var end_pos = exit + Vector3(fan_length, y_target, 0)
		
		# Draw from exit point to fan end
		_draw_line(im, exit, end_pos, color)
		
	im.surface_end()

func _draw_line(im: ImmediateMesh, from: Vector3, to: Vector3, color: Color) -> void:
	im.surface_set_color(color)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

