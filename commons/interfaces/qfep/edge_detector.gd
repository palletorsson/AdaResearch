# edge_detector.gd
# Handheld tool that detects edge of chaos
# Beeps and glows when lambda is in the sweet spot (0.3-0.5)

extends Node3D
class_name EdgeDetector

# XR Tools integration
@export var pickable := true

# State
var current_lambda := 0.0
var is_at_edge := false
var detection_strength := 0.0

# Components
var body_mesh: MeshInstance3D
var indicator_light: OmniLight3D
var antenna_mesh: MeshInstance3D
var beep_player: AudioStreamPlayer3D

# Animation
var pulse_time := 0.0
var beep_timer := 0.0
const BEEP_INTERVAL_EDGE := 0.2
const BEEP_INTERVAL_FAR := 1.0

# Colors
const COLOR_OFF := Color(0.2, 0.2, 0.2)
const COLOR_FAR := Color(0.3, 0.3, 0.8)
const COLOR_CLOSE := Color(0.8, 0.8, 0.2)
const COLOR_EDGE := Color(0.2, 1.0, 0.4)

signal edge_detected(strength: float)

func _ready():
	_create_body()
	_create_antenna()
	_create_indicator()
	_create_audio()
	
	add_to_group("qfep_reactive")
	add_to_group("interactable")
	
	_connect_to_lambda()

func _create_body():
	body_mesh = MeshInstance3D.new()
	body_mesh.name = "Body"
	
	# Handle shape
	var box := BoxMesh.new()
	box.size = Vector3(0.06, 0.15, 0.04)
	body_mesh.mesh = box
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.15, 0.2)
	mat.metallic = 0.7
	mat.roughness = 0.3
	body_mesh.material_override = mat
	
	add_child(body_mesh)

func _create_antenna():
	antenna_mesh = MeshInstance3D.new()
	antenna_mesh.name = "Antenna"
	
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.008
	cylinder.height = 0.12
	antenna_mesh.mesh = cylinder
	
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.6, 0.6)
	mat.metallic = 0.9
	antenna_mesh.material_override = mat
	
	antenna_mesh.position = Vector3(0, 0.135, 0)
	add_child(antenna_mesh)
	
	# Antenna tip (the sensing element)
	var tip := MeshInstance3D.new()
	tip.name = "AntennaTip"
	var sphere := SphereMesh.new()
	sphere.radius = 0.015
	sphere.height = 0.03
	tip.mesh = sphere
	
	var tip_mat := StandardMaterial3D.new()
	tip_mat.albedo_color = COLOR_OFF
	tip_mat.emission_enabled = true
	tip_mat.emission = COLOR_OFF
	tip_mat.emission_energy_multiplier = 0.0
	tip.material_override = tip_mat
	
	tip.position = Vector3(0, 0.06, 0)
	antenna_mesh.add_child(tip)

func _create_indicator():
	indicator_light = OmniLight3D.new()
	indicator_light.name = "IndicatorLight"
	indicator_light.light_color = COLOR_OFF
	indicator_light.light_energy = 0.0
	indicator_light.omni_range = 0.5
	indicator_light.position = Vector3(0, 0.2, 0)
	add_child(indicator_light)

func _create_audio():
	beep_player = AudioStreamPlayer3D.new()
	beep_player.name = "BeepPlayer"
	beep_player.max_distance = 5.0
	beep_player.unit_size = 1.0
	add_child(beep_player)
	
	# Create a simple beep sound procedurally
	# In a real implementation, you'd load an audio file

func _process(delta):
	pulse_time += delta
	beep_timer += delta
	
	_update_detection()
	_update_visuals(delta)
	_update_audio()

func _update_detection():
	# Calculate how close we are to edge of chaos (0.3-0.5)
	var edge_center: float = 0.4
	var edge_width: float = 0.1
	
	var distance_from_edge: float = abs(current_lambda - edge_center)
	
	if distance_from_edge < edge_width:
		is_at_edge = true
		detection_strength = 1.0 - (distance_from_edge / edge_width)
	else:
		is_at_edge = false
		# Gradual falloff outside edge
		detection_strength = max(0, 1.0 - (distance_from_edge / 0.5))
	
	edge_detected.emit(detection_strength)

func _update_visuals(delta):
	var color: Color
	var energy: float
	
	if is_at_edge:
		color = COLOR_EDGE
		energy = 2.0 + sin(pulse_time * 10) * 1.0  # Fast pulse at edge
	elif detection_strength > 0.5:
		color = COLOR_CLOSE
		energy = 1.0 + sin(pulse_time * 5) * 0.5
	elif detection_strength > 0.1:
		color = COLOR_FAR
		energy = 0.5 + sin(pulse_time * 2) * 0.2
	else:
		color = COLOR_OFF
		energy = 0.0
	
	# Update antenna tip
	var tip = antenna_mesh.get_node_or_null("AntennaTip")
	if tip:
		var tip_mat = tip.material_override as StandardMaterial3D
		if tip_mat:
			tip_mat.albedo_color = color
			tip_mat.emission = color
			tip_mat.emission_energy_multiplier = energy
	
	# Update light
	indicator_light.light_color = color
	indicator_light.light_energy = energy * 0.5
	
	# Antenna vibrates at edge
	if is_at_edge:
		var vibrate: float = sin(pulse_time * 30) * 0.002 * detection_strength
		antenna_mesh.position.x = vibrate
	else:
		antenna_mesh.position.x = 0

func _update_audio():
	# Beep rate depends on proximity to edge
	var beep_interval: float
	if is_at_edge:
		beep_interval = BEEP_INTERVAL_EDGE
	else:
		beep_interval = BEEP_INTERVAL_FAR / max(0.1, detection_strength)
	
	if beep_timer > beep_interval and detection_strength > 0.1:
		_play_beep()
		beep_timer = 0.0

func _play_beep():
	# In a full implementation, play actual audio
	# For now, just flash the light
	if indicator_light:
		indicator_light.light_energy = 3.0

func on_lambda_changed(lambda: float):
	current_lambda = lambda

func _connect_to_lambda():
	await get_tree().process_frame
	
	var sliders = get_tree().get_nodes_in_group("qfep_slider")
	for slider in sliders:
		if slider.has_signal("lambda_changed"):
			slider.lambda_changed.connect(on_lambda_changed)
			print("EdgeDetector: Connected to lambda slider")
