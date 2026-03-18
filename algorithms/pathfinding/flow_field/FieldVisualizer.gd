extends MeshInstance3D

var grid: FlowGrid

func setup(g: FlowGrid) -> void:
	grid = g
	mesh = ImmediateMesh.new()
	
	# Setup Material
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	material_override = mat

func update_visuals() -> void:
	mesh.clear_surfaces()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	var height_offset = Vector3(0, 0.2, 0)
	
	for y in range(grid.height):
		for x in range(grid.width):
			var idx = y * grid.width + x
			var pos = grid.grid_to_world(x, y) + height_offset
			var vec = grid.vector_field[idx]
			
			if vec.length_squared() > 0.01:
				# Draw Line
				var end_pos = pos + Vector3(vec.x, 0, vec.y) * 0.8
				
				# Tail (White-ish)
				mesh.surface_set_color(Color(0.5, 1, 1))
				mesh.surface_add_vertex(pos)
				
				# Head (Blue)
				mesh.surface_set_color(Color(0, 0.5, 1))
				mesh.surface_add_vertex(end_pos)
				
	mesh.surface_end()

func apply_grid_config(config: Dictionary) -> void:
	pass
