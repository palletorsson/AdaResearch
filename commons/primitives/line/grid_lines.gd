extends Node3D

const DataInstrumentSurface = preload("res://commons/ui/data_instrument_surface.gd")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")


# Spine-corridor contract — see doc/SPINE_HINTS_CONTRACT.md.
# grid_lines reads as "a lattice floating in void" — the cells around it
# should STAY void to preserve that design intent. That signal now lives
# in the registry as `spatial_needs.platform = "sunken"` (step 2a: one
# source of truth). No tag needed here.
func spine_hints() -> Dictionary:
	return {
		"role":         "primary",
		"footprint":    Vector2i(5, 5),     # 5x5 lattice from grid_size default
		"approach":     "any",
		"reading_dist": 1.0,
		"budget_ms":    0.6,
		"tags":         ["visual", "static", "isolated"],
	}


# @identity
# essence: grid = {x=i*step, z=j*step : i,j ∈ ℤ} — the XZ plane made legible as a lattice of lines
# desire: learner experiences space as structured and measurable, not infinite and featureless
# critical_parameter: grid_size — how many cells appear; determines resolution of spatial reference
# triggers: TraceData global signal — saved player traces appear as scaled rotating meshes on grid intersections
# emerges: the grid as a display medium, not just reference — traces replay as spatial memory
# needs: [flat data readout, physical page controls in the museum placement]
# relationships: subscribes to player_trace data; uses line as its primitive unit
# truth: a coordinate grid does not exist in space — it is a social agreement we project onto space

# Script to create a grid of lines on the XZ plane (horizontal ground plane)

@export var grid_size: int = 5  # Number of grid cells (will have grid_size+1 lines in each direction)
@export var cell_spacing: float = 1.0  # Distance between grid lines in meters
@export var trace_scale: float = 5.0 # Scale factor for saved traces
@export var shadow_snap_subdivisions: int = 4 # How many snap points per cell for the shadow trace (higher = smoother)

@export var trace_height: float = 0.5 # Elevation above grid
@export var rotation_speed: float = 10.0 # Degrees per second

# Data Table Display
@export_group("Data Table")
@export var show_data_table: bool = true
@export var data_table_position: Vector3 = Vector3(0, 2.5, 0)  # Above the trace
@export var data_table_color: Color = Color(0.9, 0.95, 1.0, 1.0)
@export var data_table_font_size: int = 20
@export var data_table_page_duration: float = 2.0  # Seconds per page

func apply_grid_config(config: Dictionary) -> void:
	## Map-token dress for the lattice (2026-08-24, Palle: "the grid should
	## not rotate, only the trace, but slower"): the lattice itself never
	## turns — _process spins only the saved-trace instances — and the map
	## slows that turn per placement (#rotation_speed:2, degrees per second).
	if config.has("rotation_speed") and str(config["rotation_speed"]).is_valid_float():
		rotation_speed = clampf(float(str(config["rotation_speed"])), 0.0, 90.0)
	if config.has("trace_height") and str(config["trace_height"]).is_valid_float():
		trace_height = clampf(float(str(config["trace_height"])), 0.0, 3.0)


var _data_panel: Node3D
var _cased_readout: bool = false

var _rotating_instances: Array[Node3D] = []
var _data_table_label: Label
var _trace_data_list: Array[Dictionary] = []  # Store info about each trace
var _data_table_page: int = 0  # Current page of points to display
var _archive_auto := false
var _page_buttons: Array[Node3D] = []
var _data_table_timer: float = 0.0  # Timer for page cycling
var _last_trace_visual: Node3D
var _last_shadow_visual: Node3D
var _trace_serial := 0
var point_selection: Node3D

func _process(delta: float) -> void:
	for i in range(_rotating_instances.size() - 1, -1, -1):
		var instance: Node3D = _rotating_instances[i]
		if is_instance_valid(instance):
			instance.rotate_y(deg_to_rad(rotation_speed * delta))
		else:
			_rotating_instances.remove_at(i)

	# Cycle through data table pages
	if _archive_auto and _data_table_label and _data_table_label.visible:
		_data_table_timer += delta
		if _data_table_timer >= data_table_page_duration:
			_data_table_timer = 0.0
			_data_table_page += 1
			_update_data_table()

func _ready():
	print("GridLines: _ready called")
	_cased_readout = str(get_meta("config_panel", "0")) in ["1", "true"]
	setup_grid()
	_setup_data_table()

	# Setup trace visualization
	var trace_data = get_node_or_null("/root/TraceData")
	print("GridLines: TraceData status: " + str(trace_data))

	if trace_data:
		trace_data.trace_added.connect(_on_trace_added)
		for trace in trace_data.get_all_traces():
			_create_trace_mesh(trace)
			_add_trace_to_data(trace)
		_update_data_table()
	if str(get_meta("config_selection", "0")) in ["1", "true"]:
		point_selection = load("res://commons/artifacts/primitive_encounters/trace_selection.gd").new()
		point_selection.name = "PointSelection"
		add_child(point_selection)

func _on_trace_added(points: Array) -> void:
	_create_trace_mesh(points)
	_add_trace_to_data(points)
	_data_table_page = 0
	_data_table_timer = 0.0
	_update_data_table()

func _display_frame(points: Array) -> Dictionary:
	var lo: Vector3 = points[0]
	var hi: Vector3 = points[0]
	for p: Vector3 in points:
		lo = lo.min(p)
		hi = hi.max(p)
	var span := hi - lo
	var extent := maxf(span.x, maxf(span.y, span.z))
	var factor := trace_scale
	if extent * factor > 5.0 and extent > 0.001:
		factor = 5.0 / extent
	return {"center": (lo + hi) * 0.5, "size": span, "scale": factor}

func _create_trace_mesh(points: Array) -> void:
	if points.is_empty():
		return
		
	var frame := _display_frame(points)
	var center: Vector3 = frame.center
	var size: Vector3 = frame.size
	var final_scale: float = frame.scale
	
	print("GridLines: Creating trace mesh with %d points. Centered at: %s. Size: %s. Final Scale: %.2f" % [points.size(), center, size, final_scale])
	
	_last_shadow_visual = _create_shadow_trace(points, center, final_scale)
	
	var mesh = ImmediateMesh.new()
	var instance = MeshInstance3D.new()
	instance.mesh = mesh
	instance.name = "SavedTrace"
	instance.position.y = trace_height
	add_child(instance)
	_rotating_instances.append(instance)
	_last_trace_visual = instance
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1, 0.4, 0.9, 1) # Same as default trail
	mat.emission_enabled = true
	mat.emission = Color(1, 0.4, 0.9, 1)
	instance.material_override = mat
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in points:
		# Use local coordinates centered on the grid and scaled
		mesh.surface_add_vertex((p - center) * final_scale)
	mesh.surface_end()
	
	# Bubble Animation
	instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(instance, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _create_shadow_trace(points: Array, center: Vector3, scale_factor: float) -> Node3D:
	var shadow_points = []
	var last_snapped = Vector3.INF
	
	for p in points:
		var scaled = (p - center) * scale_factor
		# Snap to grid (with subdivisions)
		var snap_step = cell_spacing / float(max(1, shadow_snap_subdivisions))
		var snapped = scaled.snapped(Vector3.ONE * snap_step)
		
		# Filter duplicates
		if snapped.distance_squared_to(last_snapped) > 0.001:
			shadow_points.append(snapped)
			last_snapped = snapped
			
	if shadow_points.size() < 2:
		return null

	var mesh = ImmediateMesh.new()
	var instance = MeshInstance3D.new()
	instance.name = "ShadowTrace"
	instance.mesh = mesh
	instance.position.y = trace_height
	add_child(instance)
	_rotating_instances.append(instance)
	
	# Green Emissive Material (matching GrabSpherePointSnap)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.2, 1.0, 0.6, 0.8) 
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.2, 1.0, 0.6, 1.0)
	mat.emission_energy_multiplier = 1.5
	instance.material_override = mat
	
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for p in shadow_points:
		# Lift slightly to avoid z-fighting (relative to instance position)
		# Since instance is already at trace_height, we just add a tiny bit more or 0
		mesh.surface_add_vertex(p) 
	mesh.surface_end()
	
	instance.scale = Vector3.ZERO
	var tween = create_tween()
	tween.tween_property(instance, "scale", Vector3.ONE, 1.0).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	return instance

func setup_grid():
	var half_size = (grid_size * cell_spacing) / 2.0
	var line_index = 1

	# Create lines parallel to X axis (going along X, at different Z positions)
	for i in range(grid_size + 1):
		var z_pos = -half_size + (i * cell_spacing)
		var line_node = get_node_or_null("LineX" + str(i + 1) + "/lineContainer")
		if line_node:
			line_node.set_positions(
				Vector3(-half_size, 0, z_pos),
				Vector3(half_size, 0, z_pos)
			)
			# Highlight center lines
			if is_zero_approx(z_pos):
				line_node.set_line_properties(0.01, Color(1.0, 0.3, 0.3, 1.0))  # Red for X axis
			else:
				line_node.set_line_properties(0.006, Color(0.6, 0.6, 0.6, 0.8))

	# Create lines parallel to Z axis (going along Z, at different X positions)
	for i in range(grid_size + 1):
		var x_pos = -half_size + (i * cell_spacing)
		var line_node = get_node_or_null("LineZ" + str(i + 1) + "/lineContainer")
		if line_node:
			line_node.set_positions(
				Vector3(x_pos, 0, -half_size),
				Vector3(x_pos, 0, half_size)
			)
			# Highlight center lines
			if is_zero_approx(x_pos):
				line_node.set_line_properties(0.01, Color(0.3, 0.3, 1.0, 1.0))  # Blue for Z axis
			else:
				line_node.set_line_properties(0.006, Color(0.6, 0.6, 0.6, 0.8))

func _setup_data_table() -> void:
	if not show_data_table: return
	_data_panel = DataInstrumentSurface.new()
	_data_panel.name = "ArchivePanel"
	_data_panel.size_m = Vector2(.92, .78)
	_data_panel.body_color = data_table_color
	_data_panel.preferred_font_size = maxi(26, data_table_font_size)
	# The basin is one metre below the museum deck. Front-right placement
	# keeps the complete case outside the lattice and the controls before it.
	_data_panel.position = Vector3(3.10, 2.2, 3.15) if _cased_readout else data_table_position
	_data_panel.rotation_degrees.x = -35
	add_child(_data_panel)
	_data_panel.heading.text = "RELEASED TRACES"
	_data_table_label = _data_panel.table
	if _cased_readout:
		_build_archive_controls()
	else:
		# Existing unconfigured placements retain automatic paging.
		_archive_auto = true
	_update_data_table()

func _fit_data_panel() -> void:
	if is_instance_valid(_data_panel): _data_panel.refresh()

func _build_archive_controls() -> void:
	# Keep the support upright when the reading plane tilts. This placement
	# belongs to the museum's one-metre-deep basin and stands on its rim.
	for part in [
		["ArchiveFoot",Vector3(.42,.04,.40),Vector3(3.10,1.02,3.08)],
		["ArchiveStem",Vector3(.14,.94,.14),Vector3(3.10,1.47,3.08)],
		["ArchiveBracket",Vector3(.22,.06,.30),Vector3(3.10,1.96,3.21)]]:
		var support := MeshInstance3D.new()
		support.name = part[0]
		support.mesh = BoxMesh.new()
		support.mesh.size = part[1]
		support.position = part[2]
		var finish := StandardMaterial3D.new()
		finish.albedo_color = Color(.14,.17,.19)
		finish.metallic = .45
		finish.roughness = .5
		support.material_override = finish
		add_child(support)
	var strip := MeshInstance3D.new()
	strip.name = "PagingBackplate"
	strip.mesh = BoxMesh.new()
	strip.mesh.size = Vector3(.58, .19, .045)
	strip.position = Vector3(0, -.50, -.025)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(.18, .21, .23)
	material.roughness = .65
	strip.material_override = material
	_data_panel.add_child(strip)
	for index in 3:
		var button: Node3D = load("res://commons/interactables/push_button.tscn").instantiate()
		button.name = ["PreviousPage", "AutoPages", "NextPage"][index]
		button.position = Vector3((index-1)*.18, -.475, .002)
		button.released_color = Color(.25, .30, .32)
		button.selected_color = Color(.35, .80, .66)
		button.released_emission_energy = .05
		_data_panel.add_child(button)
		_page_buttons.append(button)
		var caption := BakedText.make_label_mesh(["PREVIOUS", "AUTO", "NEXT"][index], Color(.92,.95,1), Vector2(.15,.028), 2200, true)
		caption.position = Vector3(button.position.x, -.55, .001)
		_data_panel.add_child(caption)
	_page_buttons[0].pressed.connect(func(): step_archive_page(-1))
	_page_buttons[1].pressed.connect(func(): set_archive_auto(not _archive_auto))
	_page_buttons[2].pressed.connect(func(): step_archive_page(1))

func set_archive_auto(enabled: bool) -> void:
	_archive_auto = enabled
	_data_table_timer = 0.0
	if not _page_buttons.is_empty(): _page_buttons[1].set_selected(enabled)
	if is_instance_valid(_data_panel):
		_data_panel.heading.text = "RELEASED TRACES / AUTO" if enabled else "RELEASED TRACES"
		_data_panel.refresh()

func step_archive_page(direction: int) -> void:
	if is_instance_valid(point_selection):
		point_selection.step_page(direction)
		return
	set_archive_auto(false)
	if _trace_data_list.is_empty(): return
	var pages := maxi(1, ceili(float(_trace_data_list[-1].raw_points.size()) / 10.0))
	_data_table_page = posmod(_data_table_page + direction, pages)
	_update_data_table()

func _add_trace_to_data(points: Array) -> void:
	if points.is_empty():
		return

	# Calculate trace metrics
	var total_length: float = 0.0
	for i in range(1, points.size()):
		total_length += points[i].distance_to(points[i - 1])

	# Calculate bounding box
	var min_p = points[0]
	var max_p = points[0]
	for p in points:
		min_p = min_p.min(p)
		max_p = max_p.max(p)
	var size = max_p - min_p

	var trace_info = {
		"id": _trace_serial,
		"visual": _last_trace_visual,
		"shadow": _last_shadow_visual,
		"points": points.size(),
		"length": total_length,
		"size": size,
		"raw_points": points.duplicate()
	}
	_trace_data_list.append(trace_info)
	_trace_serial += 1

	# Keep only last 10 traces in data list
	while _trace_data_list.size() > 10:
		_trace_data_list.pop_front()

func _update_data_table() -> void:
	if not _data_table_label: return
	if _trace_data_list.is_empty():
		_data_table_label.text = "RELEASED TRACES / THIS SESSION\n\nNo released trace yet.\nDraw with a dot in Trace, then let go.\nThe walking path is a separate recorder."
		_data_table_label.visible = _cased_readout
		_data_panel.visible = _cased_readout
		call_deferred("_fit_data_panel")
		return

	var total_points = 0
	var total_length = 0.0
	for trace in _trace_data_list:
		total_points += trace.points
		total_length += trace.length

	# Get raw points from the most recent trace
	var latest_trace = _trace_data_list[_trace_data_list.size() - 1]
	var raw_pts = latest_trace.raw_points
	var pts_per_page = 10
	var total_pages = max(1, ceili(float(raw_pts.size()) / pts_per_page))

	# Wrap page if needed
	if _data_table_page >= total_pages:
		_data_table_page = 0

	# Build full table with raw data points
	var frame := _display_frame(raw_pts)
	var table_text = "THIS SESSION\n"
	table_text += "Summary: last %d traces / %d points\n" % [_trace_data_list.size(), total_points]
	table_text += "Latest: %d points / %.3f m source length\n" % [raw_pts.size(), latest_trace.length]
	table_text += "Display: centred, x%.3f / pink source shape\n" % frame.scale
	table_text += "Green: %.4f m snap in DISPLAY space\n" % (cell_spacing / max(1,shadow_snap_subdivisions))
	table_text += "Ruling: %.2f m / separate from walking grid\n" % cell_spacing
	table_text += "SOURCE WORLD POSITIONS (m) / %d of %d\n" % [_data_table_page + 1,total_pages]

	# Show 10 points for current page
	var start_idx = _data_table_page * pts_per_page
	var end_idx = min(start_idx + pts_per_page, raw_pts.size())
	for i in range(start_idx, end_idx):
		var pt = raw_pts[i]
		table_text += "%3d: (%.3f, %.3f, %.3f)\n" % [i + 1, pt.x, pt.y, pt.z]

	_data_table_label.text = table_text
	_data_table_label.visible = true
	_data_panel.visible = true
	call_deferred("_fit_data_panel")

