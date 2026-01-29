# voxel_grid.gd - Voxel grid with marching squares
extends Node3D

@export var resolution: int = 8
@export var voxel_material: Material

var voxels: Array = []
var voxel_size: float = 1.0
var grid_size: float = 1.0
var surface: Node3D
var dummy_x: Voxel = Voxel.new()
var dummy_y: Voxel = Voxel.new()
var dummy_t: Voxel = Voxel.new()

# Chunk neighbors
var x_neighbor: Node3D = null
var y_neighbor: Node3D = null
var xy_neighbor: Node3D = null

# Voxel visualization
var voxel_objects: Array = []

func initialize(res: int, size: float):
	resolution = res
	grid_size = size
	voxel_size = size / float(resolution)
	
	# Create voxel array
	voxels.clear()
	for i in range(resolution * resolution):
		voxels.append(null)
	
	# Create voxels
	for y in range(resolution):
		for x in range(resolution):
			var i = y * resolution + x
			voxels[i] = Voxel.new(x, y, voxel_size)
			create_voxel_visual(i, x, y)
	
	# Create surface
	var surface_script = load("res://voxel_grid_surface.gd")
	surface = Node3D.new()
	var mesh_inst = MeshInstance3D.new()
	mesh_inst.set_script(surface_script)
	if voxel_material:
		mesh_inst.material_override = voxel_material
	surface.add_child(mesh_inst)
	add_child(surface)
	
	mesh_inst.initialize(resolution)
	
	refresh()

func create_voxel_visual(i: int, x: int, y: int):
	var quad = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2.ONE * voxel_size * 0.1
	quad.mesh = quad_mesh
	
	quad.position = Vector3(
		(x + 0.5) * voxel_size,
		(y + 0.5) * voxel_size,
		-0.01
	)
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material_override = mat
	
	add_child(quad)
	voxel_objects.append({"mesh": quad, "material": mat})

func set_voxel(x: int, y: int, state: bool):
	voxels[y * resolution + x].state = state
	refresh()

func apply(stencil: VoxelStencil):
	var x_start = stencil.get_x_start()
	if x_start < 0:
		x_start = 0
	var x_end = stencil.get_x_end()
	if x_end >= resolution:
		x_end = resolution - 1
	
	var y_start = stencil.get_y_start()
	if y_start < 0:
		y_start = 0
	var y_end = stencil.get_y_end()
	if y_end >= resolution:
		y_end = resolution - 1
	
	for y in range(y_start, y_end + 1):
		var i = y * resolution + x_start
		for x in range(x_start, x_end + 1):
			voxels[i].state = stencil.apply(x, y, voxels[i].state)
			i += 1
	
	refresh()

func refresh():
	set_voxel_colors()
	triangulate()

func set_voxel_colors():
	for i in range(voxels.size()):
		var color = Color.BLACK if voxels[i].state else Color.WHITE
		voxel_objects[i].material.albedo_color = color

func triangulate():
	var surf = surface.get_child(0)
	surf.clear()
	
	if x_neighbor:
		dummy_x.become_x_dummy_of(x_neighbor.voxels[0], grid_size)
	
	fill_first_row_cache()
	triangulate_cell_rows()
	
	if y_neighbor:
		triangulate_gap_row()
	
	surf.apply()

func fill_first_row_cache():
	var surf = surface.get_child(0)
	cache_first_corner(voxels[0])
	
	for i in range(resolution - 1):
		cache_next_edge_and_corner(i, voxels[i], voxels[i + 1])
	
	if x_neighbor:
		dummy_x.become_x_dummy_of(x_neighbor.voxels[0], grid_size)
		cache_next_edge_and_corner(resolution - 1, voxels[resolution - 1], dummy_x)

func cache_first_corner(voxel: Voxel):
	if voxel.state:
		surface.get_child(0).cache_first_corner(voxel)

func cache_next_edge_and_corner(i: int, x_min: Voxel, x_max: Voxel):
	var surf = surface.get_child(0)
	if x_min.state != x_max.state:
		surf.cache_x_edge(i, x_min)
	if x_max.state:
		surf.cache_next_corner(i, x_max)

func cache_next_middle_edge(y_min: Voxel, y_max: Voxel):
	var surf = surface.get_child(0)
	surf.prepare_cache_for_next_cell()
	if y_min.state != y_max.state:
		surf.cache_y_edge(y_min)

func triangulate_cell_rows():
	var cells = resolution - 1
	
	for y in range(cells):
		var i = y * resolution
		swap_row_caches()
		cache_first_corner(voxels[i + resolution])
		cache_next_middle_edge(voxels[i], voxels[i + resolution])
		
		for x in range(cells):
			var a = voxels[i]
			var b = voxels[i + 1]
			var c = voxels[i + resolution]
			var d = voxels[i + resolution + 1]
			
			cache_next_edge_and_corner(x, c, d)
			cache_next_middle_edge(b, d)
			triangulate_cell(x, a, b, c, d)
			i += 1
		
		if x_neighbor:
			triangulate_gap_cell(i)

func triangulate_gap_cell(i: int):
	var swap = dummy_t
	swap.become_x_dummy_of(x_neighbor.voxels[i + 1], grid_size)
	dummy_t = dummy_x
	dummy_x = swap
	triangulate_cell(resolution - 1, voxels[i], dummy_t, voxels[i + resolution], dummy_x)

func triangulate_gap_row():
	var surf = surface.get_child(0)
	swap_row_caches()
	
	dummy_y.become_y_dummy_of(y_neighbor.voxels[0], grid_size)
	var cells = resolution - 1
	var offset = cells * resolution
	
	cache_first_corner(dummy_y)
	cache_next_middle_edge(voxels[offset], dummy_y)
	
	for x in range(cells):
		var swap = dummy_t
		swap.become_y_dummy_of(y_neighbor.voxels[x + 1], grid_size)
		dummy_t = dummy_y
		dummy_y = swap
		
		cache_next_edge_and_corner(x, dummy_t, dummy_y)
		cache_next_middle_edge(voxels[x + offset + 1], dummy_y)
		triangulate_cell(x, voxels[x + offset], voxels[x + offset + 1], dummy_t, dummy_y)
	
	if x_neighbor:
		dummy_t.become_xy_dummy_of(xy_neighbor.voxels[0], grid_size)
		cache_next_edge_and_corner(cells, dummy_y, dummy_t)
		cache_next_middle_edge(dummy_x, dummy_t)
		triangulate_cell(cells, voxels[voxels.size() - 1], dummy_x, dummy_y, dummy_t)

func swap_row_caches():
	surface.get_child(0).prepare_cache_for_next_row()

func triangulate_cell(i: int, a: Voxel, b: Voxel, c: Voxel, d: Voxel):
	var cell_type = 0
	if a.state:
		cell_type |= 1
	if b.state:
		cell_type |= 2
	if c.state:
		cell_type |= 4
	if d.state:
		cell_type |= 8
	
	var surf = surface.get_child(0)
	match cell_type:
		0:
			return
		1:
			surf.add_triangle_a(i)
		2:
			surf.add_triangle_b(i)
		3:
			surf.add_quad_a(i)
		4:
			surf.add_triangle_c(i)
		5:
			surf.add_quad_b(i)
		6:
			surf.add_triangle_b(i)
			surf.add_triangle_c(i)
		7:
			surf.add_pentagon_a(i)
		8:
			surf.add_triangle_d(i)
		9:
			surf.add_triangle_a(i)
			surf.add_triangle_d(i)
		10:
			surf.add_quad_c(i)
		11:
			surf.add_pentagon_b(i)
		12:
			surf.add_quad_d(i)
		13:
			surf.add_pentagon_c(i)
		14:
			surf.add_pentagon_d(i)
		15:
			surf.add_quad_e(i)
