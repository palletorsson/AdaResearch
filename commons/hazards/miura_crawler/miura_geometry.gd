extends RefCounted
class_name MiuraGeometry
## Miura-ori fold pattern geometry solver.
## Generates a flat-foldable corrugated sheet with one degree of freedom.

# Pattern parameters
var rows: int = 4
var cols: int = 6
var panel_width: float = 0.15  # Width of each parallelogram
var panel_height: float = 0.12  # Height of each parallelogram
var skew_angle: float = 65.0  # Parallelogram angle in degrees (α)

# Computed geometry
var vertices: PackedVector3Array = []
var faces: Array[PackedInt32Array] = []  # Each face is 4 vertex indices
var mountain_creases: Array[Vector2i] = []
var valley_creases: Array[Vector2i] = []

# Grid indexing
var _vertex_grid: Array = []  # 2D array [row][col] -> vertex index


func build_pattern(p_rows: int, p_cols: int, p_width: float, p_height: float, p_skew: float) -> void:
	rows = max(2, p_rows)
	cols = max(2, p_cols)
	panel_width = max(0.01, p_width)
	panel_height = max(0.01, p_height)
	skew_angle = clamp(p_skew, 30.0, 85.0)
	
	vertices.clear()
	faces.clear()
	mountain_creases.clear()
	valley_creases.clear()
	_vertex_grid.clear()
	
	_generate_flat_vertices()
	_generate_faces()
	_generate_creases()


func _generate_flat_vertices() -> void:
	## Generate vertices in the flat (unfolded) state.
	## Miura-ori has a staggered grid due to the parallelogram geometry.
	
	var skew_rad: float = deg_to_rad(skew_angle)
	var skew_offset: float = panel_height / tan(skew_rad)
	
	_vertex_grid.resize(rows + 1)
	
	for row in range(rows + 1):
		_vertex_grid[row] = []
		for col in range(cols + 1):
			# Base position
			var x: float = col * panel_width
			var z: float = row * panel_height
			
			# Stagger: odd rows shift by skew offset, alternating direction per column
			if row % 2 == 1:
				if col % 2 == 0:
					x += skew_offset * 0.5
				else:
					x -= skew_offset * 0.5
			
			var idx: int = vertices.size()
			vertices.append(Vector3(x, 0.0, z))
			_vertex_grid[row].append(idx)


func _generate_faces() -> void:
	## Generate quadrilateral faces (parallelograms).
	
	for row in range(rows):
		for col in range(cols):
			var v0: int = _vertex_grid[row][col]
			var v1: int = _vertex_grid[row][col + 1]
			var v2: int = _vertex_grid[row + 1][col + 1]
			var v3: int = _vertex_grid[row + 1][col]
			
			var face: PackedInt32Array = [v0, v1, v2, v3]
			faces.append(face)


func _generate_creases() -> void:
	## Identify mountain and valley creases.
	## Horizontal creases: mountain on even rows, valley on odd
	## Vertical creases: alternate based on position
	
	# Horizontal creases (between rows)
	for row in range(1, rows):
		for col in range(cols):
			var v0: int = _vertex_grid[row][col]
			var v1: int = _vertex_grid[row][col + 1]
			
			if row % 2 == 1:
				mountain_creases.append(Vector2i(v0, v1))
			else:
				valley_creases.append(Vector2i(v0, v1))
	
	# Vertical creases (between columns) - zigzag pattern
	for row in range(rows):
		for col in range(1, cols):
			var v0: int = _vertex_grid[row][col]
			var v1: int = _vertex_grid[row + 1][col]
			
			var is_mountain: bool = ((row + col) % 2 == 0)
			if is_mountain:
				mountain_creases.append(Vector2i(v0, v1))
			else:
				valley_creases.append(Vector2i(v0, v1))


func solve_fold(fold_amount: float) -> void:
	## Apply folding transformation.
	## fold_amount: 0 = flat, 1 = fully corrugated
	
	fold_amount = clamp(fold_amount, 0.0, 1.0)
	
	var skew_rad: float = deg_to_rad(skew_angle)
	var max_fold_angle: float = PI * 0.48  # Maximum fold angle
	var fold_angle: float = fold_amount * max_fold_angle
	
	# Recompute vertex positions based on fold state
	var skew_offset: float = panel_height / tan(skew_rad)
	
	# Compression factors
	var height_factor: float = cos(fold_angle)  # Z compression
	var y_amplitude: float = sin(fold_angle) * panel_height * 0.5  # Y displacement
	
	# Width compression due to zigzag
	var width_factor: float = 1.0 - fold_amount * 0.3
	
	for row in range(rows + 1):
		for col in range(cols + 1):
			var idx: int = _vertex_grid[row][col]
			
			# Base flat position
			var x: float = col * panel_width * width_factor
			var z: float = row * panel_height * height_factor
			
			# Stagger
			if row % 2 == 1:
				if col % 2 == 0:
					x += skew_offset * 0.5 * width_factor
				else:
					x -= skew_offset * 0.5 * width_factor
			
			# Y displacement: alternating up/down pattern
			var y: float = 0.0
			var row_phase: int = row % 2
			var col_phase: int = col % 2
			
			if row_phase == 0:
				# Even rows: vertices on base plane or raised
				if col_phase == 0:
					y = 0.0
				else:
					y = y_amplitude
			else:
				# Odd rows: vertices raised or on base
				if col_phase == 0:
					y = y_amplitude
				else:
					y = 0.0
			
			# Additional wave for more dramatic fold
			y += sin(float(row) * PI) * y_amplitude * 0.3
			
			vertices[idx] = Vector3(x, y, z)
	
	# Center the mesh
	_center_vertices()


func _center_vertices() -> void:
	if vertices.is_empty():
		return
	
	var center: Vector3 = Vector3.ZERO
	for v in vertices:
		center += v
	center /= float(vertices.size())
	
	for i in range(vertices.size()):
		vertices[i] -= center


func get_dimensions() -> Vector3:
	## Return bounding box dimensions.
	if vertices.is_empty():
		return Vector3.ZERO
	
	var min_v: Vector3 = vertices[0]
	var max_v: Vector3 = vertices[0]
	
	for v in vertices:
		min_v = Vector3(min(min_v.x, v.x), min(min_v.y, v.y), min(min_v.z, v.z))
		max_v = Vector3(max(max_v.x, v.x), max(max_v.y, v.y), max(max_v.z, v.z))
	
	return max_v - min_v


func get_flat_length() -> float:
	## Return total length when flat (for locomotion calculations).
	return cols * panel_width


func get_flat_width() -> float:
	return rows * panel_height
