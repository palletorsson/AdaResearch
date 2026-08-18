# entropy_meter.gd
# Visual entropy gauge - shows current E(S) as a filling meter
# Grabbable lab instrument

extends Node3D
class_name EntropyMeter

# State
var current_entropy := 0.5
var target_entropy := 0.5
var smoothing := 5.0

# Visual components
var tube_mesh: MeshInstance3D
var fill_mesh: MeshInstance3D
var scale_labels: Array[Label3D] = []
var value_label: Label3D

# Dimensions
const TUBE_HEIGHT := 0.6
const TUBE_RADIUS := 0.08
const FILL_RADIUS := 0.06

# Colors
const COLOR_LOW := Color(0.2, 0.3, 0.8)     # Blue - low entropy
const COLOR_MID := Color(0.2, 0.8, 0.4)     # Green - medium
const COLOR_HIGH := Color(0.9, 0.3, 0.2)    # Red - high entropy

signal entropy_changed(value: float)

func _ready():
	_create_tube()
	_create_fill()
	_create_scale()
	_create_labels()
	
	add_to_group("qfep_reactive")
	add_to_group("interactable")
	
	# Connect to lambda slider
	_connect_to_lambda()

func _create_tube():
	tube_mesh = MeshInstance3D.new()
	tube_mesh.name = "Tube"
	
	var tube := CylinderMesh.new()
	tube.top_radius = TUBE_RADIUS
	tube.bottom_radius = TUBE_RADIUS
	tube.height = TUBE_HEIGHT
	tube.radial_segments = 16
	tube_mesh.mesh = tube
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.9, 0.95, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.1
	mat.metallic = 0.2
	tube_mesh.material_override = mat
	
	tube_mesh.position = Vector3(0, TUBE_HEIGHT / 2, 0)
	add_child(tube_mesh)

func _create_fill():
	fill_mesh = MeshInstance3D.new()
	fill_mesh.name = "Fill"
	
	var fill := CylinderMesh.new()
	fill.top_radius = FILL_RADIUS
	fill.bottom_radius = FILL_RADIUS
	fill.height = TUBE_HEIGHT * current_entropy
	fill.radial_segments = 16
	fill_mesh.mesh = fill
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = COLOR_MID
	mat.emission_enabled = true
	mat.emission = COLOR_MID
	mat.emission_energy_multiplier = 0.5
	fill_mesh.material_override = mat
	
	_update_fill_position()
	add_child(fill_mesh)

func _create_scale():
	# Create tick marks on the side
	for i in range(11):  # 0.0 to 1.0 in 0.1 steps
		var tick := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.02, 0.002, 0.01)
		tick.mesh = box
		
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.3, 0.3)
		tick.material_override = mat
		
		var y_pos: float = (float(i) / 10.0) * TUBE_HEIGHT
		tick.position = Vector3(TUBE_RADIUS + 0.01, y_pos, 0)
		add_child(tick)

func _create_labels():
	# Bottom label: 0
	var label_0 := Label3D.new()
	label_0.text = "0"
	label_0.font_size = 24
	label_0.position = Vector3(TUBE_RADIUS + 0.05, 0, 0)
	label_0.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label_0)
	
	# Top label: 1
	var label_1 := Label3D.new()
	label_1.text = "1"
	label_1.font_size = 24
	label_1.position = Vector3(TUBE_RADIUS + 0.05, TUBE_HEIGHT, 0)
	label_1.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label_1)
	
	# Title
	var title := Label3D.new()
	title.text = "E(S)"
	title.font_size = 32
	title.position = Vector3(0, TUBE_HEIGHT + 0.1, 0)
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(title)
	
	# Value label
	value_label = Label3D.new()
	value_label.name = "ValueLabel"
	value_label.text = "0.50"
	value_label.font_size = 28
	value_label.position = Vector3(-TUBE_RADIUS - 0.08, TUBE_HEIGHT / 2, 0)
	value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(value_label)

func _process(delta):
	# Smooth approach to target
	current_entropy = lerp(current_entropy, target_entropy, delta * smoothing)
	
	_update_fill()
	_update_color()

func _update_fill():
	var fill := fill_mesh.mesh as CylinderMesh
	if fill:
		fill.height = max(0.01, TUBE_HEIGHT * current_entropy)
	_update_fill_position()
	
	if value_label:
		value_label.text = "%.2f" % current_entropy

func _update_fill_position():
	var height: float = TUBE_HEIGHT * current_entropy
	fill_mesh.position = Vector3(0, height / 2, 0)

func _update_color():
	var color: Color
	if current_entropy < 0.4:
		color = COLOR_LOW.lerp(COLOR_MID, current_entropy / 0.4)
	else:
		color = COLOR_MID.lerp(COLOR_HIGH, (current_entropy - 0.4) / 0.6)
	
	var mat = fill_mesh.material_override as StandardMaterial3D
	if mat:
		mat.albedo_color = color
		mat.emission = color
	
	if value_label:
		value_label.modulate = color

func set_entropy(value: float):
	target_entropy = clamp(value, 0.0, 1.0)
	entropy_changed.emit(target_entropy)

# Lambda directly maps to entropy for visualization
func on_lambda_changed(lambda: float):
	set_entropy(lambda)

func _connect_to_lambda():
	await get_tree().process_frame
	
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		return
	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(on_lambda_changed)
			print("EntropyMeter: Connected to lambda slider")
