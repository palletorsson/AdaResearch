# boids_aquarium.gd
# Flocking simulation in a glass tank
# VR-enabled with parameter controls

extends Node3D

class_name BoidsAquarium

## Tank dimensions (1m cube)
@export var tank_size: Vector3 = Vector3(1.0, 1.0, 1.0)

## Boid count
@export_range(10, 200) var boid_count: int = 30

## Flocking parameters
@export_group("Flocking")
@export var separation_weight: float = 1.5:
	set(value):
		separation_weight = clampf(value, 0.0, 5.0)
		_update_boid_params()
		_sync_separation_slider()

@export var alignment_weight: float = 1.0:
	set(value):
		alignment_weight = clampf(value, 0.0, 5.0)
		_update_boid_params()
		_sync_alignment_slider()

@export var cohesion_weight: float = 1.5:
	set(value):
		cohesion_weight = clampf(value, 0.0, 5.0)
		_update_boid_params()
		_sync_cohesion_slider()

@export var max_speed: float = 0.5:
	set(value):
		max_speed = clampf(value, 0.1, 1.5)
		_update_boid_params()

@export var perception_radius: float = 0.15

## Visual
@export_group("Visual")
@export var boid_size: Vector3 = Vector3(0.008, 0.008, 0.025)  # Elongated cube
@export var boid_transparency: float = 0.7
@export var tank_transparency: float = 0.15

var _boids: Array = []
var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _info_label: Label3D

# VR Controls
var _separation_slider: Node
var _alignment_slider: Node
var _cohesion_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

class BoidData:
	var position: Vector3
	var velocity: Vector3
	
	func _init(pos: Vector3, vel: Vector3):
		position = pos
		velocity = vel

func _ready():
	_create_tank()
	_create_multimesh()
	_create_labels()
	_create_vr_controls()
	_spawn_boids()

func _create_tank():
	# Glass panels
	var glass_mat = StandardMaterial3D.new()
	glass_mat.albedo_color = Color(0.7, 0.85, 1.0, tank_transparency)
	glass_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass_mat.metallic = 0.2
	glass_mat.roughness = 0.1
	
	# Create panels
	var panels = [
		[Vector3(0, 0, -tank_size.z/2), Vector3(tank_size.x, tank_size.y, 0.005)],  # Back
		[Vector3(0, 0, tank_size.z/2), Vector3(tank_size.x, tank_size.y, 0.005)],   # Front
		[Vector3(-tank_size.x/2, 0, 0), Vector3(0.005, tank_size.y, tank_size.z)],  # Left
		[Vector3(tank_size.x/2, 0, 0), Vector3(0.005, tank_size.y, tank_size.z)],   # Right
		[Vector3(0, -tank_size.y/2, 0), Vector3(tank_size.x, 0.005, tank_size.z)],  # Bottom
	]
	
	for i in range(panels.size()):
		var panel = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = panels[i][1]
		panel.mesh = box
		panel.material_override = glass_mat
		panel.position = panels[i][0]
		add_child(panel)
	
	# Frame
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.2, 0.2, 0.25)
	frame_mat.metallic = 0.7
	frame_mat.roughness = 0.3
	
	var frame_thickness = 0.015
	_create_frame_edge(Vector3(0, -tank_size.y/2, -tank_size.z/2), Vector3(tank_size.x + frame_thickness*2, frame_thickness, frame_thickness), frame_mat)
	_create_frame_edge(Vector3(0, -tank_size.y/2, tank_size.z/2), Vector3(tank_size.x + frame_thickness*2, frame_thickness, frame_thickness), frame_mat)
	_create_frame_edge(Vector3(-tank_size.x/2, -tank_size.y/2, 0), Vector3(frame_thickness, frame_thickness, tank_size.z), frame_mat)
	_create_frame_edge(Vector3(tank_size.x/2, -tank_size.y/2, 0), Vector3(frame_thickness, frame_thickness, tank_size.z), frame_mat)

func _create_frame_edge(pos: Vector3, size: Vector3, mat: StandardMaterial3D):
	var edge = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	edge.mesh = box
	edge.material_override = mat
	edge.position = pos
	add_child(edge)

func _create_multimesh():
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.instance_count = boid_count
	
	# Elongated cube shape
	var mesh = BoxMesh.new()
	mesh.size = boid_size
	_multimesh.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_energy_multiplier = 0.4
	
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "BoidMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = mat
	add_child(_multimesh_instance)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, tank_size.y/2 + 0.08, 0)
	_info_label.text = "BOIDS AQUARIUM\n%d agents" % boid_count
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, -tank_size.y/2 - 0.08, tank_size.z/2 + 0.12)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.15, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Separation slider (0-5)
	_separation_slider = SLIDER_HORIZONTAL.instantiate()
	_separation_slider.name = "SeparationSlider"
	_separation_slider.position = Vector3(-0.14, 0.02, 0)
	_separation_slider.rotation_degrees.x = -30
	var sep_label = _separation_slider.get_node_or_null("Frame/LabelName")
	if sep_label:
		sep_label.text = "SEP"
	_control_panel.add_child(_separation_slider)
	_separation_slider.slider_moved.connect(_on_separation_slider_moved)
	
	# Alignment slider (0-5)
	_alignment_slider = SLIDER_HORIZONTAL.instantiate()
	_alignment_slider.name = "AlignmentSlider"
	_alignment_slider.position = Vector3(0, 0.02, 0)
	_alignment_slider.rotation_degrees.x = -30
	var align_label = _alignment_slider.get_node_or_null("Frame/LabelName")
	if align_label:
		align_label.text = "ALIGN"
	_control_panel.add_child(_alignment_slider)
	_alignment_slider.slider_moved.connect(_on_alignment_slider_moved)
	
	# Cohesion slider (0-5)
	_cohesion_slider = SLIDER_HORIZONTAL.instantiate()
	_cohesion_slider.name = "CohesionSlider"
	_cohesion_slider.position = Vector3(0.14, 0.02, 0)
	_cohesion_slider.rotation_degrees.x = -30
	var coh_label = _cohesion_slider.get_node_or_null("Frame/LabelName")
	if coh_label:
		coh_label.text = "COH"
	_control_panel.add_child(_cohesion_slider)
	_cohesion_slider.slider_moved.connect(_on_cohesion_slider_moved)
	
	# Reset button
	var reset_btn = PUSH_BUTTON.instantiate()
	reset_btn.name = "ResetButton"
	reset_btn.position = Vector3(0, -0.04, 0)
	reset_btn.rotation_degrees.x = -30
	_control_panel.add_child(reset_btn)
	_add_button_label(reset_btn, "RESET")
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_respawn_boids)
	
	call_deferred("_sync_sliders_deferred")

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 10
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _sync_sliders_deferred():
	_sync_separation_slider()
	_sync_alignment_slider()
	_sync_cohesion_slider()

func _sync_separation_slider():
	if _separation_slider and _separation_slider.has_method("set_normalized_value"):
		_separation_slider.set_normalized_value(separation_weight / 5.0)

func _sync_alignment_slider():
	if _alignment_slider and _alignment_slider.has_method("set_normalized_value"):
		_alignment_slider.set_normalized_value(alignment_weight / 5.0)

func _sync_cohesion_slider():
	if _cohesion_slider and _cohesion_slider.has_method("set_normalized_value"):
		_cohesion_slider.set_normalized_value(cohesion_weight / 5.0)

func _on_separation_slider_moved(_position):
	if _separation_slider and _separation_slider.has_method("get_normalized_value"):
		separation_weight = _separation_slider.get_normalized_value() * 5.0

func _on_alignment_slider_moved(_position):
	if _alignment_slider and _alignment_slider.has_method("get_normalized_value"):
		alignment_weight = _alignment_slider.get_normalized_value() * 5.0

func _on_cohesion_slider_moved(_position):
	if _cohesion_slider and _cohesion_slider.has_method("get_normalized_value"):
		cohesion_weight = _cohesion_slider.get_normalized_value() * 5.0

func _update_boid_params():
	# Update info label
	if _info_label:
		_info_label.text = "BOIDS AQUARIUM\nSep:%.1f Align:%.1f Coh:%.1f" % [separation_weight, alignment_weight, cohesion_weight]

func _spawn_boids():
	_boids.clear()
	var half = tank_size * 0.3  # Spawn closer together
	
	# Color palette for variety
	var colors = [
		Color(1.0, 0.3, 0.3),  # Red
		Color(0.3, 1.0, 0.4),  # Green
		Color(0.3, 0.5, 1.0),  # Blue
		Color(1.0, 0.8, 0.2),  # Yellow
		Color(1.0, 0.4, 0.8),  # Pink
		Color(0.4, 1.0, 1.0),  # Cyan
		Color(0.8, 0.5, 1.0),  # Purple
		Color(1.0, 0.6, 0.3),  # Orange
	]
	
	for i in range(boid_count):
		var pos = Vector3(
			randf_range(-half.x, half.x),
			randf_range(-half.y, half.y),
			randf_range(-half.z, half.z)
		)
		var vel = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized() * max_speed * 0.5
		_boids.append(BoidData.new(pos, vel))
		
		# Each boid gets a different color with transparency
		var base_color = colors[i % colors.size()]
		var hue_shift = randf() * 0.05 - 0.025  # Small variation
		base_color.h = fmod(base_color.h + hue_shift + 1.0, 1.0)
		base_color.a = boid_transparency
		_multimesh.set_instance_color(i, base_color)

func _respawn_boids(_button = null):  # Accept optional button arg from signal
	_spawn_boids()

func _process(delta):
	_update_boids(delta)
	_update_multimesh()

func _update_boids(delta):
	var half = tank_size * 0.45
	
	for i in range(_boids.size()):
		var boid = _boids[i]
		var separation = Vector3.ZERO
		var alignment = Vector3.ZERO
		var cohesion = Vector3.ZERO
		var neighbors = 0
		
		# Check neighbors
		for j in range(_boids.size()):
			if i == j:
				continue
			var other = _boids[j]
			var dist = boid.position.distance_to(other.position)
			
			if dist < perception_radius:
				neighbors += 1
				
				# Separation
				if dist > 0.001:
					var diff = boid.position - other.position
					separation += diff / (dist * dist)
				
				# Alignment
				alignment += other.velocity
				
				# Cohesion
				cohesion += other.position
		
		if neighbors > 0:
			alignment /= neighbors
			alignment = (alignment - boid.velocity) * alignment_weight
			
			cohesion /= neighbors
			cohesion = (cohesion - boid.position) * cohesion_weight
			
			separation *= separation_weight
		
		# Apply forces
		var acceleration = separation + alignment + cohesion
		boid.velocity += acceleration * delta
		
		# Limit speed
		if boid.velocity.length() > max_speed:
			boid.velocity = boid.velocity.normalized() * max_speed
		
		# Move
		boid.position += boid.velocity * delta
		
		# Boundary bounce
		if abs(boid.position.x) > half.x:
			boid.position.x = signf(boid.position.x) * half.x
			boid.velocity.x *= -1
		if abs(boid.position.y) > half.y:
			boid.position.y = signf(boid.position.y) * half.y
			boid.velocity.y *= -1
		if abs(boid.position.z) > half.z:
			boid.position.z = signf(boid.position.z) * half.z
			boid.velocity.z *= -1

func _update_multimesh():
	for i in range(_boids.size()):
		var boid = _boids[i]
		var transform = Transform3D()
		transform.origin = boid.position
		
		# Orient to velocity
		if boid.velocity.length() > 0.001:
			var forward = boid.velocity.normalized()
			var up = Vector3.UP
			if abs(forward.dot(up)) > 0.99:
				up = Vector3.FORWARD
			transform = transform.looking_at(boid.position + forward, up)
			transform.basis = transform.basis.rotated(transform.basis.x, -PI/2)
		
		_multimesh.set_instance_transform(i, transform)

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				separation_weight = clampf(separation_weight - 0.2, 0.0, 5.0)
			KEY_2:
				separation_weight = clampf(separation_weight + 0.2, 0.0, 5.0)
			KEY_3:
				alignment_weight = clampf(alignment_weight - 0.2, 0.0, 5.0)
			KEY_4:
				alignment_weight = clampf(alignment_weight + 0.2, 0.0, 5.0)
			KEY_5:
				cohesion_weight = clampf(cohesion_weight - 0.2, 0.0, 5.0)
			KEY_6:
				cohesion_weight = clampf(cohesion_weight + 0.2, 0.0, 5.0)
			KEY_R:
				_respawn_boids()