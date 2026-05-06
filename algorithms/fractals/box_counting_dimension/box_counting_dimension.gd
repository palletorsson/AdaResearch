extends Node3D

# @identity
# essence: D = lim(log N(e) / log(1/e)). Cover the shape with boxes. Count. Shrink. Count again. The slope IS the dimension.
# desire: To measure. To show that fractals live between integer dimensions. Sierpinski is not 1D or 2D — it's 1.585D.
# critical_parameter: Grid resolution — coarse grids give rough estimates, fine grids converge to true dimension.
# triggers: Grid cycles → progressively finer overlay, log-log plot updates → regression line converges to D, highlight → current scale shown
# emerges: Fractal dimension from the scaling relationship. The number 1.585 from pure geometry. Measurement from counting.
# needs: VR shape selector [missing — only Sierpinski]. Manual grid control [missing — auto-cycles]. Different fractal inputs.
# relationships: Lives in Fractal_KochSierpinski. Complements the geometric fractals with quantitative measurement. Feeds into the concept that dimension is not always integer.
# truth: Fractal dimension is not a property of the shape. It's a property of how the shape fills space at every scale.

## Box-counting dimension measurement tool.
## Generates a fractal shape (Sierpinski triangle), then overlays progressively
## finer grids and counts occupied boxes at each scale. Plots log(count) vs
## log(1/box_size) — the slope IS the fractal dimension.

const GRID_SCALES := [2, 4, 8, 16, 32, 64]
const SHAPE_SIZE := 6.0
const POINT_COUNT := 8000

var _fractal_points: Array[Vector3] = []
var _grid_lines: Array[MeshInstance3D] = []
var _current_scale_idx := 0
var _display_timer := 0.0
var _counts: Array[int] = []
var _plot_mesh: ImmediateMesh
var _plot_instance: MeshInstance3D
var _point_cloud: MultiMeshInstance3D
var _grid_instance: MeshInstance3D
var _grid_mesh: ImmediateMesh
var _scale_label: Label3D
var _dimension_label: Label3D


func _ready() -> void:
	_generate_sierpinski_points()
	_setup_point_cloud()
	_setup_grid_display()
	_setup_plot()
	_setup_labels()

	# Pre-compute all counts
	for scale in GRID_SCALES:
		_counts.append(_count_boxes(scale))

	_update_grid_display()
	_update_plot()


func _generate_sierpinski_points() -> void:
	# Chaos game: Sierpinski triangle in XZ plane
	var vertices := [
		Vector3(-SHAPE_SIZE * 0.5, 0.0, -SHAPE_SIZE * 0.3),
		Vector3(SHAPE_SIZE * 0.5, 0.0, -SHAPE_SIZE * 0.3),
		Vector3(0.0, 0.0, SHAPE_SIZE * 0.5),
	]
	var current := Vector3(0.0, 0.0, 0.0)
	# Burn in
	for _i in 100:
		current = (current + vertices[randi() % 3]) * 0.5

	for _i in POINT_COUNT:
		current = (current + vertices[randi() % 3]) * 0.5
		_fractal_points.append(current)


func _setup_point_cloud() -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = _fractal_points.size()
	mm.visible_instance_count = _fractal_points.size()

	var sphere := SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	sphere.radial_segments = 4
	sphere.rings = 2
	mm.mesh = sphere

	for i in _fractal_points.size():
		var xform := Transform3D.IDENTITY
		xform.origin = _fractal_points[i]
		mm.set_instance_transform(i, xform)
		mm.set_instance_color(i, Color(0.3, 0.8, 1.0, 0.6))

	_point_cloud = MultiMeshInstance3D.new()
	_point_cloud.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_point_cloud.material_override = mat
	add_child(_point_cloud)


func _setup_grid_display() -> void:
	_grid_mesh = ImmediateMesh.new()
	_grid_instance = MeshInstance3D.new()
	_grid_instance.mesh = _grid_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_grid_instance.material_override = mat
	add_child(_grid_instance)


func _setup_plot() -> void:
	_plot_mesh = ImmediateMesh.new()
	_plot_instance = MeshInstance3D.new()
	_plot_instance.mesh = _plot_mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_plot_instance.material_override = mat
	_plot_instance.position = Vector3(5.0, 3.0, 0.0)
	add_child(_plot_instance)

	# Plot axes labels
	var x_label := Label3D.new()
	x_label.text = "log(1/box_size)"
	x_label.font_size = 12
	x_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	x_label.position = Vector3(5.0, 2.2, 0.0)
	x_label.modulate = Color(1, 1, 1, 0.6)
	add_child(x_label)

	var y_label := Label3D.new()
	y_label.text = "log(count)"
	y_label.font_size = 12
	y_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	y_label.position = Vector3(3.5, 4.5, 0.0)
	y_label.modulate = Color(1, 1, 1, 0.6)
	add_child(y_label)


func _setup_labels() -> void:
	var title := Label3D.new()
	title.text = "Box-Counting Dimension"
	title.font_size = 22
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.position = Vector3(0.0, 5.5, 3.0)
	title.modulate = Color(1, 1, 1, 0.9)
	add_child(title)

	_scale_label = Label3D.new()
	_scale_label.font_size = 16
	_scale_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_scale_label.position = Vector3(0.0, 4.8, 3.0)
	_scale_label.modulate = Color(1.0, 0.9, 0.3, 0.8)
	add_child(_scale_label)

	_dimension_label = Label3D.new()
	_dimension_label.font_size = 18
	_dimension_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_dimension_label.position = Vector3(5.0, 5.5, 0.0)
	_dimension_label.modulate = Color(0.3, 1.0, 0.5, 0.9)
	add_child(_dimension_label)


func _process(delta: float) -> void:
	_display_timer += delta
	if _display_timer >= 2.0:
		_display_timer = 0.0
		_current_scale_idx = (_current_scale_idx + 1) % GRID_SCALES.size()
		_update_grid_display()
		_update_plot()


func _count_boxes(divisions: int) -> int:
	var box_size := SHAPE_SIZE / float(divisions)
	var occupied := {}
	var offset := Vector3(SHAPE_SIZE * 0.5, 0.0, SHAPE_SIZE * 0.5)

	for pt in _fractal_points:
		var shifted := pt + offset
		var ix := int(shifted.x / box_size)
		var iz := int(shifted.z / box_size)
		var key := ix * 10000 + iz
		occupied[key] = true

	return occupied.size()


func _update_grid_display() -> void:
	var divisions: int = GRID_SCALES[_current_scale_idx]
	var box_size := SHAPE_SIZE / float(divisions)
	var count: int = _counts[_current_scale_idx]

	_scale_label.text = "%d boxes, %d occupied" % [divisions * divisions, count]

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 1.0, 1.0, 0.12)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_grid_mesh.clear_surfaces()
	_grid_mesh.surface_begin(Mesh.PRIMITIVE_LINES, mat)

	var half := SHAPE_SIZE * 0.5
	# Vertical lines
	for i in divisions + 1:
		var x := -half + i * box_size
		_grid_mesh.surface_add_vertex(Vector3(x, 0.01, -half))
		_grid_mesh.surface_add_vertex(Vector3(x, 0.01, half))

	# Horizontal lines
	for i in divisions + 1:
		var z := -half + i * box_size
		_grid_mesh.surface_add_vertex(Vector3(-half, 0.01, z))
		_grid_mesh.surface_add_vertex(Vector3(half, 0.01, z))

	_grid_mesh.surface_end()


func _update_plot() -> void:
	_plot_mesh.clear_surfaces()

	if _counts.size() < 2:
		return

	# Compute log-log points
	var log_points: Array[Vector2] = []
	for i in _counts.size():
		var box_size := SHAPE_SIZE / float(GRID_SCALES[i])
		var log_inv_size := log(1.0 / box_size) / log(2.0)
		var log_count := log(float(_counts[i])) / log(2.0)
		log_points.append(Vector2(log_inv_size, log_count))

	# Scale to display
	var x_min := log_points[0].x
	var x_max := log_points[log_points.size() - 1].x
	var y_min := log_points[0].y
	var y_max := log_points[log_points.size() - 1].y
	var x_range := maxf(x_max - x_min, 0.1)
	var y_range := maxf(y_max - y_min, 0.1)
	var plot_size := 3.0

	# Linear regression for dimension
	var sum_x := 0.0
	var sum_y := 0.0
	var sum_xy := 0.0
	var sum_xx := 0.0
	var n := float(log_points.size())
	for pt in log_points:
		sum_x += pt.x
		sum_y += pt.y
		sum_xy += pt.x * pt.y
		sum_xx += pt.x * pt.x
	var slope := (n * sum_xy - sum_x * sum_y) / maxf(n * sum_xx - sum_x * sum_x, 0.001)
	_dimension_label.text = "D = %.3f" % slope

	# Draw axes
	var axis_mat := StandardMaterial3D.new()
	axis_mat.albedo_color = Color(0.5, 0.5, 0.5, 0.4)
	axis_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	axis_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINES, axis_mat)
	_plot_mesh.surface_add_vertex(Vector3(0, 0, 0))
	_plot_mesh.surface_add_vertex(Vector3(plot_size, 0, 0))
	_plot_mesh.surface_add_vertex(Vector3(0, 0, 0))
	_plot_mesh.surface_add_vertex(Vector3(0, plot_size, 0))
	_plot_mesh.surface_end()

	# Draw data points and connecting line
	var point_mat := StandardMaterial3D.new()
	point_mat.albedo_color = Color(0.3, 0.8, 1.0)
	point_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, point_mat)
	for i in log_points.size():
		var px := (log_points[i].x - x_min) / x_range * plot_size
		var py := (log_points[i].y - y_min) / y_range * plot_size
		_plot_mesh.surface_add_vertex(Vector3(px, py, 0))
	_plot_mesh.surface_end()

	# Highlight current scale point
	var highlight_mat := StandardMaterial3D.new()
	highlight_mat.albedo_color = Color(1.0, 0.3, 0.4)
	highlight_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	if _current_scale_idx < log_points.size():
		var pt := log_points[_current_scale_idx]
		var px := (pt.x - x_min) / x_range * plot_size
		var py := (pt.y - y_min) / y_range * plot_size
		# Draw a small cross
		_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINES, highlight_mat)
		_plot_mesh.surface_add_vertex(Vector3(px - 0.1, py, 0))
		_plot_mesh.surface_add_vertex(Vector3(px + 0.1, py, 0))
		_plot_mesh.surface_add_vertex(Vector3(px, py - 0.1, 0))
		_plot_mesh.surface_add_vertex(Vector3(px, py + 0.1, 0))
		_plot_mesh.surface_end()

	# Draw regression line
	var fit_mat := StandardMaterial3D.new()
	fit_mat.albedo_color = Color(0.3, 1.0, 0.5, 0.6)
	fit_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fit_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	var intercept := (sum_y - slope * sum_x) / n

	_plot_mesh.surface_begin(Mesh.PRIMITIVE_LINES, fit_mat)
	var x0 := x_min
	var y0 := slope * x0 + intercept
	var x1 := x_max
	var y1 := slope * x1 + intercept
	_plot_mesh.surface_add_vertex(Vector3(0, (y0 - y_min) / y_range * plot_size, 0))
	_plot_mesh.surface_add_vertex(Vector3(plot_size, (y1 - y_min) / y_range * plot_size, 0))
	_plot_mesh.surface_end()


func apply_grid_config(config: Dictionary) -> void:
	pass
