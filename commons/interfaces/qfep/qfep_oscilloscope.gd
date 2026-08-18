# qfep_oscilloscope.gd
# Real-time visualization of QFEP oscillation
# Shows the dance between F and E(S) over time

extends Node3D
class_name QFEPOscilloscope

# State history
var history_length := 200
var f_history: Array[float] = []
var e_history: Array[float] = []
var time_history: Array[float] = []

# Current values
var current_lambda := 0.4
var current_phi := 0.0
var current_f := 0.5
var current_e := 0.5

# Display dimensions
const DISPLAY_WIDTH := 0.8
const DISPLAY_HEIGHT := 0.4
const DISPLAY_DEPTH := 0.05

# Components
var frame_mesh: MeshInstance3D
var screen_mesh: MeshInstance3D
var f_line: ImmediateMesh
var e_line: ImmediateMesh
var f_line_instance: MeshInstance3D
var e_line_instance: MeshInstance3D
var labels: Dictionary = {}

# Animation
var time := 0.0
var sample_interval := 0.05
var sample_timer := 0.0

# Colors
const COLOR_F := Color(0.3, 0.5, 1.0)      # Blue - Free Energy
const COLOR_E := Color(1.0, 0.4, 0.3)      # Red - Entropy
const COLOR_FRAME := Color(0.2, 0.2, 0.25)
const COLOR_SCREEN := Color(0.05, 0.08, 0.1)
const COLOR_GRID := Color(0.15, 0.2, 0.25)

func _ready():
	_create_frame()
	_create_screen()
	_create_lines()
	_create_labels()
	_initialize_history()
	
	add_to_group("qfep_reactive")
	add_to_group("interactable")
	
	_connect_to_sliders()

func _create_frame():
	frame_mesh = MeshInstance3D.new()
	frame_mesh.name = "Frame"
	
	var box := BoxMesh.new()
	box.size = Vector3(DISPLAY_WIDTH + 0.04, DISPLAY_HEIGHT + 0.04, DISPLAY_DEPTH)
	frame_mesh.mesh = box
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_FRAME
	mat.metallic = 0.8
	mat.roughness = 0.3
	frame_mesh.material_override = mat
	
	add_child(frame_mesh)

func _create_screen():
	screen_mesh = MeshInstance3D.new()
	screen_mesh.name = "Screen"
	
	var box := BoxMesh.new()
	box.size = Vector3(DISPLAY_WIDTH, DISPLAY_HEIGHT, 0.01)
	screen_mesh.mesh = box
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_SCREEN
	mat.emission_enabled = true
	mat.emission = COLOR_SCREEN
	mat.emission_energy_multiplier = 0.2
	screen_mesh.material_override = mat
	
	screen_mesh.position = Vector3(0, 0, DISPLAY_DEPTH / 2 + 0.005)
	add_child(screen_mesh)

func _create_lines():
	# F line (blue)
	f_line = ImmediateMesh.new()
	f_line_instance = MeshInstance3D.new()
	f_line_instance.name = "FLine"
	f_line_instance.mesh = f_line
	
	var f_mat := StandardMaterial3D.new()
	f_mat.albedo_color = COLOR_F
	f_mat.emission_enabled = true
	f_mat.emission = COLOR_F
	f_mat.emission_energy_multiplier = 1.0
	f_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	f_line_instance.material_override = f_mat
	
	f_line_instance.position.z = DISPLAY_DEPTH / 2 + 0.01
	add_child(f_line_instance)
	
	# E line (red)
	e_line = ImmediateMesh.new()
	e_line_instance = MeshInstance3D.new()
	e_line_instance.name = "ELine"
	e_line_instance.mesh = e_line
	
	var e_mat := StandardMaterial3D.new()
	e_mat.albedo_color = COLOR_E
	e_mat.emission_enabled = true
	e_mat.emission = COLOR_E
	e_mat.emission_energy_multiplier = 1.0
	e_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	e_line_instance.material_override = e_mat
	
	e_line_instance.position.z = DISPLAY_DEPTH / 2 + 0.01
	add_child(e_line_instance)

func _create_labels():
	# Title
	var title := Label3D.new()
	title.text = "QFEP OSCILLOSCOPE"
	title.font_size = 24
	title.position = Vector3(0, DISPLAY_HEIGHT / 2 + 0.05, DISPLAY_DEPTH / 2)
	title.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	add_child(title)
	
	# F label
	var f_label := Label3D.new()
	f_label.text = "F"
	f_label.font_size = 20
	f_label.modulate = COLOR_F
	f_label.position = Vector3(-DISPLAY_WIDTH / 2 - 0.05, DISPLAY_HEIGHT / 4, DISPLAY_DEPTH / 2)
	add_child(f_label)
	labels["F"] = f_label
	
	# E label
	var e_label := Label3D.new()
	e_label.text = "E(S)"
	e_label.font_size = 20
	e_label.modulate = COLOR_E
	e_label.position = Vector3(-DISPLAY_WIDTH / 2 - 0.05, -DISPLAY_HEIGHT / 4, DISPLAY_DEPTH / 2)
	add_child(e_label)
	labels["E"] = e_label
	
	# Lambda display
	var lambda_label := Label3D.new()
	lambda_label.name = "LambdaLabel"
	lambda_label.text = "λ=0.40"
	lambda_label.font_size = 18
	lambda_label.position = Vector3(DISPLAY_WIDTH / 2 - 0.1, DISPLAY_HEIGHT / 2 + 0.05, DISPLAY_DEPTH / 2)
	add_child(lambda_label)
	labels["lambda"] = lambda_label

func _initialize_history():
	for i in range(history_length):
		f_history.append(0.5)
		e_history.append(0.5)
		time_history.append(float(i) / float(history_length))

func _process(delta):
	time += delta
	sample_timer += delta
	
	# Sample at fixed interval
	if sample_timer >= sample_interval:
		_sample_values()
		sample_timer = 0.0
	
	_update_lines()
	_update_labels()

func _sample_values():
	# Calculate current F and E based on lambda and phi
	# F decreases as entropy increases
	current_f = 1.0 - current_lambda * 0.8
	# E increases with lambda
	current_e = current_lambda * 0.9
	
	# Add some oscillation based on phi
	var oscillation: float = sin(time * 3.0) * 0.1 * abs(current_phi)
	current_f += oscillation
	current_e -= oscillation
	
	# Add to history
	f_history.pop_front()
	f_history.append(current_f)
	e_history.pop_front()
	e_history.append(current_e)

func _update_lines():
	# Clear and redraw F line
	f_line.clear_surfaces()
	f_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(history_length):
		var x: float = (float(i) / float(history_length) - 0.5) * DISPLAY_WIDTH
		var y: float = (f_history[i] - 0.5) * DISPLAY_HEIGHT
		f_line.surface_add_vertex(Vector3(x, y, 0))
	
	f_line.surface_end()
	
	# Clear and redraw E line
	e_line.clear_surfaces()
	e_line.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	for i in range(history_length):
		var x: float = (float(i) / float(history_length) - 0.5) * DISPLAY_WIDTH
		var y: float = (e_history[i] - 0.5) * DISPLAY_HEIGHT
		e_line.surface_add_vertex(Vector3(x, y, 0))
	
	e_line.surface_end()

func _update_labels():
	if labels.has("lambda"):
		labels["lambda"].text = "λ=%.2f" % current_lambda

func on_lambda_changed(lambda: float):
	current_lambda = lambda

func on_phi_changed(phi: float):
	current_phi = phi

func _connect_to_sliders():
	await get_tree().process_frame
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(on_lambda_changed)
		if slider.has_signal("phi_changed"):
			slider.phi_changed.connect(on_phi_changed)
	print("QFEPOscilloscope: Connected to sliders")
