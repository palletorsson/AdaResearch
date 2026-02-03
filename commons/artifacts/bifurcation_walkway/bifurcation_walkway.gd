# bifurcation_walkway.gd
# Vertical display showing the bifurcation diagram (logistic map)
# VR-enabled with parameter controls

extends Node3D

class_name BifurcationWalkway

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
var _info_label: Label3D
var _active_points: int = 0

# VR Controls
var _r_min_slider: Node
var _r_max_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

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
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.003
	_info_label.font_size = 24
	_info_label.position = Vector3(0, display_height + 0.15, 0)
	add_child(_info_label)
	
	# R axis labels
	var r_label_min = Label3D.new()
	r_label_min.pixel_size = 0.002
	r_label_min.font_size = 16
	r_label_min.position = Vector3(-display_width/2, -0.08, 0)
	r_label_min.modulate = Color(0.6, 0.6, 0.6)
	add_child(r_label_min)
	
	var r_label_max = Label3D.new()
	r_label_max.pixel_size = 0.002
	r_label_max.font_size = 16
	r_label_max.position = Vector3(display_width/2, -0.08, 0)
	r_label_max.modulate = Color(0.6, 0.6, 0.6)
	add_child(r_label_max)
	
	# X axis labels
	var x_label_0 = Label3D.new()
	x_label_0.text = "0"
	x_label_0.pixel_size = 0.002
	x_label_0.font_size = 14
	x_label_0.position = Vector3(-display_width/2 - 0.06, 0, 0)
	x_label_0.modulate = Color(0.5, 0.5, 0.5)
	add_child(x_label_0)
	
	var x_label_1 = Label3D.new()
	x_label_1.text = "1"
	x_label_1.pixel_size = 0.002
	x_label_1.font_size = 14
	x_label_1.position = Vector3(-display_width/2 - 0.06, display_height, 0)
	x_label_1.modulate = Color(0.5, 0.5, 0.5)
	add_child(x_label_1)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -0.15, 0.12)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	_control_panel.add_child(panel_back)
	
	# R min slider (0.5 to r_max)
	_r_min_slider = SLIDER_HORIZONTAL.instantiate()
	_r_min_slider.name = "RMinSlider"
	_r_min_slider.position = Vector3(-0.12, 0.01, 0.01)
	var min_label = _r_min_slider.get_node_or_null("Frame/LabelName")
	if min_label:
		min_label.text = "R MIN"
	_control_panel.add_child(_r_min_slider)
	_r_min_slider.slider_moved.connect(_on_r_min_slider_moved)
	
	# R max slider (r_min to 4.0)
	_r_max_slider = SLIDER_HORIZONTAL.instantiate()
	_r_max_slider.name = "RMaxSlider"
	_r_max_slider.position = Vector3(0.12, 0.01, 0.01)
	var max_label = _r_max_slider.get_node_or_null("Frame/LabelName")
	if max_label:
		max_label.text = "R MAX"
	_control_panel.add_child(_r_max_slider)
	_r_max_slider.slider_moved.connect(_on_r_max_slider_moved)
	
	# Preset buttons
	var preset_btn1 = PUSH_BUTTON.instantiate()
	preset_btn1.name = "PresetFull"
	preset_btn1.position = Vector3(-0.1, -0.035, 0.01)
	preset_btn1.scale = Vector3(0.8, 0.8, 0.8)
	_control_panel.add_child(preset_btn1)
	_add_button_label(preset_btn1, "FULL")
	var area1 = preset_btn1.get_node_or_null("InteractableAreaButton")
	if area1:
		area1.button_pressed.connect(func(): _set_r_range(0.5, 4.0))
	
	var preset_btn2 = PUSH_BUTTON.instantiate()
	preset_btn2.name = "PresetChaos"
	preset_btn2.position = Vector3(0, -0.035, 0.01)
	preset_btn2.scale = Vector3(0.8, 0.8, 0.8)
	_control_panel.add_child(preset_btn2)
	_add_button_label(preset_btn2, "CHAOS")
	var area2 = preset_btn2.get_node_or_null("InteractableAreaButton")
	if area2:
		area2.button_pressed.connect(func(): _set_r_range(3.5, 4.0))
	
	var preset_btn3 = PUSH_BUTTON.instantiate()
	preset_btn3.name = "PresetBifurc"
	preset_btn3.position = Vector3(0.1, -0.035, 0.01)
	preset_btn3.scale = Vector3(0.8, 0.8, 0.8)
	_control_panel.add_child(preset_btn3)
	_add_button_label(preset_btn3, "BIFUR")
	var area3 = preset_btn3.get_node_or_null("InteractableAreaButton")
	if area3:
		area3.button_pressed.connect(func(): _set_r_range(2.8, 3.6))
	
	call_deferred("_sync_sliders_deferred")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 9
	lbl.position = Vector3(0, -0.03, 0.012)
	btn.add_child(lbl)

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
	
	_info_label.text = "BIFURCATION DIAGRAM\nr ∈ [%.2f, %.2f]" % [r_min, r_max]
	
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
			var brightness = 0.5 + smoothstep(3.0, 4.0, r) * 0.5
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

func smoothstep(edge0: float, edge1: float, x: float) -> float:
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
