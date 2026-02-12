extends Node3D
class_name ProfileRenderer

## Renders 1D curves as ribbon-strip ImmediateMesh in 3D space.
## Multiple traces, optional grid background, vertical markers.
## Designed for VR: thick enough to read at arm's length.

const BASE_LINE_WIDTH: float = 0.003
const DISPLAY_WIDTH: float = 0.4    # meters along X
const DISPLAY_HEIGHT: float = 0.25  # meters along Y
const GLOW_PASSES: int = 2
const GLOW_SPREAD: float = 0.004

# Rendering
var _trace_meshes: Array[MeshInstance3D] = []
var _trace_immediates: Array[ImmediateMesh] = []
var _grid_mesh: MeshInstance3D
var _marker_meshes: Array[MeshInstance3D] = []

# Materials cached per trace
var _trace_materials: Array[ShaderMaterial] = []
var _grid_material: ShaderMaterial

# State
var _trace_count: int = 0
var _sample_count: int = 256
var _y_range: Vector2 = Vector2(-1.0, 1.0)


func setup(trace_count: int, sample_count: int, cartridge: ProfileCartridge) -> void:
	_trace_count = trace_count
	_sample_count = sample_count
	_y_range = cartridge.get_y_range()

	_clear_traces()
	_setup_grid(cartridge)

	for t in range(trace_count):
		var im = ImmediateMesh.new()
		var mmi = MeshInstance3D.new()
		mmi.name = "Trace_%d" % t
		mmi.mesh = im
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var mat = ShaderMaterial.new()
		mat.shader = preload("res://commons/substrates/profile/profile_line.gdshader")
		mat.set_shader_parameter("trace_color", cartridge.get_trace_color(t))
		mat.set_shader_parameter("emission_energy", cartridge.get_trace_emission(t))
		mmi.material_override = mat

		add_child(mmi)
		_trace_meshes.append(mmi)
		_trace_immediates.append(im)
		_trace_materials.append(mat)


func update_traces(traces: Array, cartridge: ProfileCartridge) -> void:
	for t in range(min(traces.size(), _trace_count)):
		var buf: PackedFloat32Array = traces[t]
		var im: ImmediateMesh = _trace_immediates[t]
		var color: Color = cartridge.get_trace_color(t)
		var width: float = BASE_LINE_WIDTH * cartridge.get_trace_width(t)

		im.clear_surfaces()

		if buf.size() < 2:
			continue

		# Glow passes (wider, dimmer)
		for g in range(GLOW_PASSES):
			var glow_w = width + GLOW_SPREAD * (GLOW_PASSES - g)
			var glow_alpha = 0.12 * (g + 1)
			var glow_color = Color(color.r, color.g, color.b, glow_alpha)
			_draw_ribbon(im, buf, glow_w, glow_color)

		# Main trace
		_draw_ribbon(im, buf, width, color)

		# Hot center (thinner, brighter)
		var hot_color = Color(
			minf(color.r + 0.3, 1.0),
			minf(color.g + 0.3, 1.0),
			minf(color.b + 0.3, 1.0),
			1.0
		)
		_draw_ribbon(im, buf, width * 0.3, hot_color)


func update_markers(markers: Array) -> void:
	# Clear old markers
	for m in _marker_meshes:
		m.queue_free()
	_marker_meshes.clear()

	for marker in markers:
		var x_norm: float = marker.get("x", 0.5)
		var color: Color = marker.get("color", Color(1.0, 1.0, 0.2, 0.6))

		var x_pos = (x_norm - 0.5) * DISPLAY_WIDTH
		var im = ImmediateMesh.new()
		var mmi = MeshInstance3D.new()
		mmi.mesh = im
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

		var mat = StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = color
		mat.vertex_color_use_as_albedo = true
		mmi.material_override = mat

		# Vertical line from bottom to top
		im.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		var hw = 0.001  # half-width of marker line
		var bottom = Vector3(x_pos - hw, -DISPLAY_HEIGHT * 0.5, 0.001)
		var top = Vector3(x_pos - hw, DISPLAY_HEIGHT * 0.5, 0.001)
		var bottom_r = Vector3(x_pos + hw, -DISPLAY_HEIGHT * 0.5, 0.001)
		var top_r = Vector3(x_pos + hw, DISPLAY_HEIGHT * 0.5, 0.001)

		im.surface_set_color(color)
		im.surface_add_vertex(bottom)
		im.surface_set_color(color)
		im.surface_add_vertex(top)
		im.surface_set_color(color)
		im.surface_add_vertex(top_r)

		im.surface_set_color(color)
		im.surface_add_vertex(bottom)
		im.surface_set_color(color)
		im.surface_add_vertex(top_r)
		im.surface_set_color(color)
		im.surface_add_vertex(bottom_r)
		im.surface_end()

		add_child(mmi)
		_marker_meshes.append(mmi)


func _draw_ribbon(im: ImmediateMesh, buf: PackedFloat32Array, width: float,
		color: Color) -> void:
	## Draw a ribbon strip: two triangles per segment, width in Z direction.
	var n = buf.size()
	if n < 2:
		return

	var y_min = _y_range.x
	var y_span = _y_range.y - _y_range.x
	if y_span == 0.0:
		y_span = 1.0

	var hw = width * 0.5  # half-width in Z

	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)

	for i in range(n):
		var t = float(i) / float(n - 1)
		var x = (t - 0.5) * DISPLAY_WIDTH

		# Map value from y_range to display height
		var val = buf[i]
		var y_norm = clampf((val - y_min) / y_span, 0.0, 1.0)
		var y = (y_norm - 0.5) * DISPLAY_HEIGHT

		im.surface_set_color(color)
		im.surface_add_vertex(Vector3(x, y, -hw))
		im.surface_set_color(color)
		im.surface_add_vertex(Vector3(x, y, hw))

	im.surface_end()


func _setup_grid(cartridge: ProfileCartridge) -> void:
	if _grid_mesh:
		_grid_mesh.queue_free()

	if not cartridge.show_grid():
		return

	var quad = QuadMesh.new()
	quad.size = Vector2(DISPLAY_WIDTH, DISPLAY_HEIGHT)
	quad.orientation = 2  # FACE_Z

	_grid_mesh = MeshInstance3D.new()
	_grid_mesh.name = "GridBackground"
	_grid_mesh.mesh = quad
	_grid_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Slightly behind the traces
	_grid_mesh.position.z = -0.002

	_grid_material = ShaderMaterial.new()
	_grid_material.shader = preload("res://commons/substrates/profile/profile_grid.gdshader")
	_grid_material.set_shader_parameter("grid_divisions_x", float(cartridge.get_x_divisions()))
	_grid_material.set_shader_parameter("grid_divisions_y", float(cartridge.get_y_divisions()))
	_grid_mesh.material_override = _grid_material

	add_child(_grid_mesh)


func _clear_traces() -> void:
	for mmi in _trace_meshes:
		mmi.queue_free()
	_trace_meshes.clear()
	_trace_immediates.clear()
	_trace_materials.clear()

	for m in _marker_meshes:
		m.queue_free()
	_marker_meshes.clear()

	if _grid_mesh:
		_grid_mesh.queue_free()
		_grid_mesh = null
