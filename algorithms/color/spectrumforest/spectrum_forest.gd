@tool
extends Node3D

# Spectrum Forest: A field of hanging lines visualizing the color spectrum
# Uses ImmediateMesh for thin, glowing "trace" lines.

@export_category("Forest Settings")
@export var forest_size: Vector2 = Vector2(20.0, 20.0):
	set(value):
		forest_size = value
		if is_inside_tree(): generate_forest()

@export var line_count: int = 5000:
	set(value):
		line_count = value
		if is_inside_tree(): generate_forest()

@export_category("Line Settings")
@export var line_length: float = 3.0:
	set(value):
		line_length = value
		if is_inside_tree(): generate_forest()

@export var ceiling_height: float = 4.0:
	set(value):
		ceiling_height = value
		if is_inside_tree(): generate_forest()

var _mesh_instance: MeshInstance3D
var _rng = RandomNumberGenerator.new()

func _ready():
	_setup_mesh_instance()
	generate_forest()

func _setup_mesh_instance():
	if _mesh_instance:
		_mesh_instance.queue_free()
	
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "ForestLines"
	add_child(_mesh_instance)
	
	# Material for glowing trace lines
	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.emission_enabled = true
	material.emission = Color.WHITE
	material.emission_energy_multiplier = 1.0
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh_instance.material_override = material

func generate_forest():
	if not _mesh_instance:
		return
		
	_rng.seed = 12345
	
	# Use ImmediateMesh for simple line drawing
	# Note: For 5000 lines, ArrayMesh might be slightly more performant if this were dynamic per-frame,
	# but for static generation, ImmediateMesh (which builds an ArrayMesh internally) is fine.
	# Or better, let's construct an ArrayMesh directly for efficiency with large vertex counts.
	# Actually, ImmediateMesh is easier to read and "trace-like". Let's stick to user request style.
	
	var im = ImmediateMesh.new()
	_mesh_instance.mesh = im
	
	var start_x = -forest_size.x / 2.0
	var end_x = forest_size.x / 2.0
	var start_z = -forest_size.y / 2.0
	var end_z = forest_size.y / 2.0
	
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in range(line_count):
		# Random position within bounds
		var x = _rng.randf_range(start_x, end_x)
		var z = _rng.randf_range(start_z, end_z)
		
		# Position hanging from ceiling
		var top_y = ceiling_height
		var bottom_y = ceiling_height - line_length
		
		var top_pos = Vector3(x, top_y, z)
		var bottom_pos = Vector3(x, bottom_y, z)
		
		# Color calculation (Spectrum Mapping)
		var normalized_x = remap(x, start_x, end_x, 0.0, 1.0)
		var hue = normalized_x
		var color = Color.from_hsv(hue, 0.9, 1.0)
		color.a = 0.8 # Slight transparency
		
		# Add Line Segment
		im.surface_set_color(color)
		im.surface_add_vertex(top_pos)
		im.surface_set_color(color) # Gradient? Or solid. Let's keep solid for now.
		im.surface_add_vertex(bottom_pos)
		
	im.surface_end()

