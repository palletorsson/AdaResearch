# bifurcation_walkway.gd
# Vertical display showing the bifurcation diagram (logistic map)
# VR-enabled with parameter controls

extends Node3D

class_name BifurcationWalkway

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: x_n+1 = r * x_n * (1 - x_n), iterated across r -> period-doubling cascade
# desire: walk along the r axis and feel order shatter into chaos
# critical_parameter: r — the growth rate that drives the system through bifurcations
# triggers: r_min/r_max slider adjustment recomputes entire diagram; preset buttons jump to chaos/bifurcation regions
# emerges: the Feigenbaum constant hiding in the self-similar spacing of bifurcation points
# needs: VR sliders [has], preset buttons [has], zoom via keyboard [has]
# relationships: unlocks understanding of lambda spectrum; depends on iteration concept; contrasts ordered_grid (fixed point vs period doubling)
# truth: deterministic equations produce unpredictable behavior — chaos is not randomness but sensitive dependence

## Display dimensions
@export var display_width: float = 2.0
@export var display_height: float = 1.5

## Diagram parameters
@export_range(0.5, 4.0) var r_min: float = 2.5:
	set(value):
		r_min = clampf(value, 0.5, r_max - 0.1)
		_generate_diagram()
		_sync_r_min_slider()

@export_range(0.5, 4.0) var r_max: float = 4.0:
	set(value):
		r_max = clampf(value, r_min + 0.1, 4.0)
		_generate_diagram()
		_sync_r_max_slider()

@export var samples_per_r: int = 100
@export var r_steps: int = 400
@export var warmup_iterations: int = 200
@export var show_iterations: int = 50

## Colors
@export var point_color: Color = Color(0.2, 0.8, 1.0)
@export var background_color: Color = Color(0.02, 0.02, 0.04)
@export var frame_color: Color = Color(0.15, 0.15, 0.2)

var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _info_root: Node3D
var _info_cache := ""
var _r_tag_min: Node3D
var _r_tag_max: Node3D
var _active_points: int = 0

# VR Controls
var _r_min_slider: Node
var _r_max_slider: Node
var _control_panel: Node3D

# Signal tracking for cleanup
var _signal_connections: Array = []


func _ready():
	_create_frame()
	_create_multimesh()
	_create_labels()
	_create_vr_controls()
	_generate_diagram()

func _create_frame():
	# Background panel
	var bg = MeshInstance3D.new()
	bg.name = "Background"
	
	var bg_mesh = BoxMesh.new()
	bg_mesh.size = Vector3(display_width, display_height, 0.02)
	bg.mesh = bg_mesh
	
	var bg_mat = StandardMaterial3D.new()
	bg_mat.albedo_color = background_color
	bg_mat.metallic = 0.3
	bg_mat.roughness = 0.8
	bg.material_override = bg_mat
	
	bg.position = Vector3(0, display_height / 2, -0.01)
	add_child(bg)
	
	# Frame edges
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = frame_color
	frame_mat.metallic = 0.7
	frame_mat.roughness = 0.3
	
	var thickness = 0.03
	var edges = [
		[Vector3(0, 0, 0), Vector3(display_width + thickness, thickness, thickness)],  # Bottom
		[Vector3(0, display_height, 0), Vector3(display_width + thickness, thickness, thickness)],  # Top
		[Vector3(-display_width/2, display_height/2, 0), Vector3(thickness, display_height, thickness)],  # Left
		[Vector3(display_width/2, display_height/2, 0), Vector3(thickness, display_height, thickness)],   # Right
	]
	
	for edge in edges:
		var e = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = edge[1]
		e.mesh = box
		e.material_override = frame_mat
		e.position = edge[0]
		add_child(e)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	
	var max_points = r_steps * show_iterations
	_multimesh.instance_count = max_points
	_multimesh.visible_instance_count = 0
	
	var sphere = SphereMesh.new()
	sphere.radius = 0.003
	sphere.height = 0.006
	sphere.radial_segments = 8
	sphere.rings = 4
	_multimesh.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.5
	
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "PointsMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)

func _create_labels():
	# Header + r-axis readouts live on framed 2D-in-3D boards (R-027);
	# their content is rebuilt by _rebuild_info() whenever the range changes.
	# X axis marks — framed tags, not bare Label3D
	var x_tag_0: Node3D = BakedText.make_tag("0", Color(0.5, 0.5, 0.5), 0.035)
	if x_tag_0:
		x_tag_0.position = Vector3(-display_width/2 - 0.06, 0, 0)
		add_child(x_tag_0)

	var x_tag_1: Node3D = BakedText.make_tag("1", Color(0.5, 0.5, 0.5), 0.035)
	if x_tag_1:
		x_tag_1.position = Vector3(-display_width/2 - 0.06, display_height, 0)
		add_child(x_tag_1)

func _rebuild_info() -> void:
	var range_text := "r ∈ [%.2f, %.2f]" % [r_min, r_max]
	if range_text == _info_cache:
		return
	_info_cache = range_text
	if is_instance_valid(_info_root):
		_info_root.queue_free()

	# Header board: title + current r range on one framed dark panel
	_info_root = Node3D.new()
	_info_root.name = "InfoBoard"
	_info_root.position = Vector3(0, display_height + 0.15, 0)
	add_child(_info_root)
	_info_root.add_child(_plate(Vector3(0.9, 0.22, 0.035)))
	var t: MeshInstance3D = BakedText.make_label_mesh("BIFURCATION DIAGRAM", Color(0.92, 0.95, 1.0), Vector2(0.8, 0.07), 1300, true)
	if t:
		t.position = Vector3(0, 0.045, 0.024)
		_info_root.add_child(t)
	var rr: MeshInstance3D = BakedText.make_label_mesh(range_text, Color(0.9, 0.9, 0.5), Vector2(0.7, 0.06), 1300, true)
	if rr:
		rr.position = Vector3(0, -0.045, 0.024)
		_info_root.add_child(rr)

	# R axis value tags at the diagram's bottom corners
	if is_instance_valid(_r_tag_min):
		_r_tag_min.queue_free()
	_r_tag_min = BakedText.make_tag("%.2f" % r_min, Color(0.6, 0.6, 0.6), 0.035)
	if _r_tag_min:
		_r_tag_min.position = Vector3(-display_width/2, -0.08, 0)
		add_child(_r_tag_min)
	if is_instance_valid(_r_tag_max):
		_r_tag_max.queue_free()
	_r_tag_max = BakedText.make_tag("%.2f" % r_max, Color(0.6, 0.6, 0.6), 0.035)
	if _r_tag_max:
		_r_tag_max.position = Vector3(display_width/2, -0.08, 0)
		add_child(_r_tag_max)

func _plate(size: Vector3) -> Node3D:
	var g := Node3D.new()
	var frame := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = size + Vector3(0.05, 0.05, -0.01)
	frame.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.62, 0.60, 0.56)
	fmat.roughness = 0.7
	frame.material_override = fmat
	frame.position = Vector3(0, 0, -0.006)
	g.add_child(frame)
	var face := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	face.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.10, 0.11, 0.14)
	mat.emission_enabled = true
	mat.emission = Color(0.10, 0.11, 0.14)
	mat.emission_energy_multiplier = 0.25
	face.material_override = mat
	g.add_child(face)
	return g

func _create_vr_controls():
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("BIFURCATION", [
		[
			{"type": "slider_h", "label": "R MIN", "default": (r_min - 0.5) / 3.5},
			{"type": "slider_h", "label": "R MAX", "default": (r_max - 0.5) / 3.5},
		],
		[
			{"type": "button", "label": "FULL"},
			{"type": "button", "label": "CHAOS"},
			{"type": "button", "label": "BIFUR"},
		],
	])
	_control_panel.position = Vector3(0, -0.15, 0.12)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)

	# R min slider (Param_0)
	_r_min_slider = _control_panel.find_child("Param_0", true, false)
	if _r_min_slider and _r_min_slider.has_signal("slider_moved"):
		_r_min_slider.slider_moved.connect(_on_r_min_slider_moved)
		_signal_connections.append([_r_min_slider, &"slider_moved", _on_r_min_slider_moved])

	# R max slider (Param_1)
	_r_max_slider = _control_panel.find_child("Param_1", true, false)
	if _r_max_slider and _r_max_slider.has_signal("slider_moved"):
		_r_max_slider.slider_moved.connect(_on_r_max_slider_moved)
		_signal_connections.append([_r_max_slider, &"slider_moved", _on_r_max_slider_moved])

	# Preset buttons: FULL (Btn_0), CHAOS (Btn_1), BIFUR (Btn_2)
	var preset_ranges := [[0.5, 4.0], [3.5, 4.0], [2.8, 3.6]]
	for i in range(preset_ranges.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				var rng: Array = preset_ranges[i]
				var cb := func(_b): _set_r_range(rng[0], rng[1])
				area.button_pressed.connect(cb)
				_signal_connections.append([area, &"button_pressed", cb])

	call_deferred("_sync_sliders_deferred")

func _exit_tree() -> void:
	for conn in _signal_connections:
		if is_instance_valid(conn[0]) and conn[0].is_connected(conn[1], conn[2]):
			conn[0].disconnect(conn[1], conn[2])
	_signal_connections.clear()

func _sync_sliders_deferred():
	_sync_r_min_slider()
	_sync_r_max_slider()

func _sync_r_min_slider():
	if _r_min_slider and _r_min_slider.has_method("set_normalized_value"):
		_r_min_slider.set_normalized_value((r_min - 0.5) / 3.5)

func _sync_r_max_slider():
	if _r_max_slider and _r_max_slider.has_method("set_normalized_value"):
		_r_max_slider.set_normalized_value((r_max - 0.5) / 3.5)

func _on_r_min_slider_moved(_position):
	if _r_min_slider and _r_min_slider.has_method("get_normalized_value"):
		var norm = _r_min_slider.get_normalized_value()
		r_min = 0.5 + norm * 3.5

func _on_r_max_slider_moved(_position):
	if _r_max_slider and _r_max_slider.has_method("get_normalized_value"):
		var norm = _r_max_slider.get_normalized_value()
		r_max = 0.5 + norm * 3.5

func _set_r_range(new_min: float, new_max: float):
	r_min = new_min
	r_max = new_max

func _generate_diagram():
	var idx = 0
	var half_w = display_width / 2.0

	_rebuild_info()
	
	for i in range(r_steps):
		var r = r_min + (r_max - r_min) * (float(i) / r_steps)
		var x = 0.5  # Initial population
		
		# Warmup
		for _w in range(warmup_iterations):
			x = r * x * (1.0 - x)
		
		# Record points
		for _s in range(show_iterations):
			x = r * x * (1.0 - x)
			
			var screen_x = (float(i) / r_steps - 0.5) * display_width
			var screen_y = x * display_height
			
			var transform = Transform3D()
			transform.origin = Vector3(screen_x, screen_y, 0.01)
			_multimesh.set_instance_transform(idx, transform)
			
			# Color based on r value (chaos regions brighter)
			var brightness = 0.5 + _smoothstep(3.0, 4.0, r) * 0.5
			var color = point_color
			color.v = brightness
			_multimesh.set_instance_color(idx, color)
			
			idx += 1
			if idx >= _multimesh.instance_count:
				break
		
		if idx >= _multimesh.instance_count:
			break
	
	_active_points = idx
	_multimesh.visible_instance_count = idx

func _smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t = clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_set_r_range(0.5, 4.0)
			KEY_2:
				_set_r_range(2.5, 4.0)
			KEY_3:
				_set_r_range(3.5, 4.0)
			KEY_4:
				_set_r_range(3.8, 3.9)
			KEY_LEFT:
				var shift = (r_max - r_min) * 0.1
				r_min -= shift
				r_max -= shift
			KEY_RIGHT:
				var shift = (r_max - r_min) * 0.1
				r_min += shift
				r_max += shift
			KEY_UP:  # Zoom in
				var center = (r_min + r_max) / 2.0
				var half_range = (r_max - r_min) / 2.0 * 0.8
				r_min = center - half_range
				r_max = center + half_range
			KEY_DOWN:  # Zoom out
				var center = (r_min + r_max) / 2.0
				var half_range = (r_max - r_min) / 2.0 * 1.25
				r_min = center - half_range
				r_max = center + half_range

func set_range(new_min: float, new_max: float):
	_set_r_range(new_min, new_max)

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
