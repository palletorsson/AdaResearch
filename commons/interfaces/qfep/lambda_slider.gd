# lambda_slider.gd
# QFEP Lambda (λ) Parameter Controller
# Controls the entropy drive: how much a system values disorder vs order
# λ = 0: Pure order (crystal, rigidity, dark room)
# λ = 0.3-0.5: Edge of chaos (life, adaptation, creativity)
# λ = 1: Pure entropy (dissolution, noise, dispersal)

extends Node3D

class_name LambdaSlider

# @identity
# essence: slider_position / rail_length -> lambda in [0,1]; color_gradient(blue->green->red)
# desire: grab the entropy drive and feel the system shift from crystal to chaos under your hand
# critical_parameter: lambda — the single number that controls order/chaos balance across the entire QFEP system
# triggers: XR grab moves handle; slider_moved signal propagates to all connected visualizations; broadcasts globally
# emerges: the green zone at 0.3-0.5 where particles and color converge — the sweet spot finds you
# needs: VR XR slider grab [has], visual gradient rail [has], particle feedback [has], global broadcast [has]
# relationships: controls edge_core, qfep_reactor, queer_morphology_specimen; paired with phi_slider; central to every QFEP map
# truth: lambda is the entropy drive — the dial between crystallization and dissolution that every living system must negotiate

## Signal emitted when lambda value changes
signal lambda_changed(value: float)

## Signal emitted when slider is grabbed
signal slider_grabbed()

## Signal emitted when slider is released
signal slider_released()

## Current lambda value (0.0 to 1.0)
@export var lambda: float = 0.4:
	set(v):
		lambda = clamp(v, 0.0, 1.0)
		_update_visuals()
		emit_signal("lambda_changed", lambda)

## Visual size of the slider rail
@export var rail_length: float = 0.5
@export var rail_height: float = 0.02
@export var rail_depth: float = 0.05

## Handle size
@export var handle_radius: float = 0.03

## Show particle effects
@export var show_particles: bool = true

## Show value label
@export var show_label: bool = true

## Connect to global QFEP system
@export var broadcast_globally: bool = true

# Internal references
var _slider: XRToolsInteractableSlider
var _handle: XRToolsInteractableHandle
var _rail_mesh: MeshInstance3D
var _handle_mesh: MeshInstance3D
var _label: Label3D
var _particles: GPUParticles3D
var _rail_material: StandardMaterial3D
var _handle_material: StandardMaterial3D
var _is_grabbed: bool = false

# Glow parameters (like grab_sphere)
const GLOW_EMISSION_ENERGY: float = 2.0

# Color gradient for lambda visualization
const COLOR_ORDER = Color(0.2, 0.4, 0.9, 1.0)      # Blue - pure order (λ=0)
const COLOR_EDGE = Color(0.2, 0.9, 0.4, 1.0)       # Green - edge of chaos (λ≈0.4)
const COLOR_CHAOS = Color(0.9, 0.2, 0.2, 1.0)      # Red - pure chaos (λ=1)

func _ready() -> void:
	_build_slider()
	_build_visuals()
	_update_visuals()
	
	# Register globally
	if broadcast_globally:
		add_to_group("qfep_lambda_controllers")
	
	print("LambdaSlider ready at λ = %.2f" % lambda)

func _build_slider() -> void:
	# Create the XR Tools slider - horizontal along X axis
	_slider = XRToolsInteractableSlider.new()
	_slider.name = "InteractableSlider"
	_slider.slider_limit_min = 0.0
	_slider.slider_limit_max = rail_length
	_slider.slider_position = lambda * rail_length
	_slider.default_position = 0.4 * rail_length
	_slider.default_on_release = false
	_slider.slider_steps = 0.0  # Continuous
	
	# Create HandleOrigin node - this is the reference point for the handle
	# Matches the working slider_horizontal.tscn structure
	var handle_origin = Node3D.new()
	handle_origin.name = "HandleOrigin"
	
	# Create handle for grabbing - make it feel like grab_sphere
	_handle = XRToolsInteractableHandle.new()
	_handle.name = "InteractableHandle"
	
	# CRITICAL: Configure RigidBody3D settings so it doesn't fall!
	_handle.gravity_scale = 0.0
	_handle.collision_layer = 262144  # Bit 18 - XR pickable layer
	_handle.collision_mask = 0  # Don't collide with anything
	_handle.freeze = true  # Freeze until grabbed
	_handle.picked_up_layer = 0  # Match working slider
	
	# Handle collision shape - larger for easier grabbing
	var handle_collision = CollisionShape3D.new()
	handle_collision.name = "CollisionShape3D"
	var handle_shape = SphereShape3D.new()
	handle_shape.radius = handle_radius * 2.0  # Larger collision for easier grab
	handle_collision.shape = handle_shape
	_handle.add_child(handle_collision)
	
	# Add grab point redirects for left and right hands (like working slider)
	var grab_redirect_left = XRToolsGrabPointRedirect.new()
	grab_redirect_left.name = "GrabPointRedirectLeft"
	_handle.add_child(grab_redirect_left)
	
	var grab_redirect_right = XRToolsGrabPointRedirect.new()
	grab_redirect_right.name = "GrabPointRedirectRight"
	_handle.add_child(grab_redirect_right)
	
	# BUILD ENTIRE HIERARCHY BEFORE ADDING TO TREE
	# This ensures _hook_child_handles() finds the handle when slider._ready() runs
	handle_origin.add_child(_handle)
	_slider.add_child(handle_origin)
	
	# NOW add to tree - slider._ready() will find and hook the handle
	add_child(_slider)
	
	# Connect our own signals after hierarchy is set up
	if _slider.has_signal("slider_moved"):
		_slider.slider_moved.connect(_on_slider_moved)
	if _handle.has_signal("grabbed"):
		_handle.grabbed.connect(_on_slider_grabbed)
	if _handle.has_signal("released"):
		_handle.released.connect(_on_slider_released)

func _build_visuals() -> void:
	# Build the rail
	_rail_mesh = MeshInstance3D.new()
	var rail_box = BoxMesh.new()
	rail_box.size = Vector3(rail_length, rail_height, rail_depth)
	_rail_mesh.mesh = rail_box
	_rail_mesh.position = Vector3(rail_length / 2, 0, 0)
	
	# Rail material with gradient texture
	_rail_material = StandardMaterial3D.new()
	_rail_material.albedo_color = Color(0.3, 0.3, 0.3)
	_rail_material.metallic = 0.3
	_rail_material.roughness = 0.7
	_rail_mesh.material_override = _rail_material
	add_child(_rail_mesh)
	
	# Build gradient overlay on rail
	_build_rail_gradient()
	
	# Build the handle visual - attach to handle so it moves with grab
	_handle_mesh = MeshInstance3D.new()
	var handle_sphere = SphereMesh.new()
	handle_sphere.radius = handle_radius
	handle_sphere.height = handle_radius * 2
	_handle_mesh.mesh = handle_sphere
	
	_handle_material = StandardMaterial3D.new()
	_handle_material.albedo_color = COLOR_EDGE
	_handle_material.emission_enabled = true
	_handle_material.emission = COLOR_EDGE
	_handle_material.emission_energy_multiplier = 0.5
	_handle_mesh.material_override = _handle_material
	# Add mesh to the HANDLE so it follows the grab position
	_handle.add_child(_handle_mesh)
	
	# Build label
	if show_label:
		_label = Label3D.new()
		_label.text = "λ = 0.40"
		_label.font_size = 48
		_label.pixel_size = 0.001
		_label.position = Vector3(rail_length / 2, rail_height + 0.05, 0)
		_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(_label)
		
		# Add sublabels for scale
		_build_scale_labels()
	
	# Build particles
	if show_particles:
		_build_particles()

func _build_rail_gradient() -> void:
	# Create gradient segments on the rail
	var segment_count = 10
	var segment_width = rail_length / segment_count
	
	for i in range(segment_count):
		var segment = MeshInstance3D.new()
		var segment_mesh = BoxMesh.new()
		segment_mesh.size = Vector3(segment_width * 0.9, rail_height * 1.1, rail_depth * 0.5)
		segment.mesh = segment_mesh
		segment.position = Vector3(segment_width * (i + 0.5), 0, rail_depth * 0.3)
		
		var t = float(i) / float(segment_count - 1)
		var color = _get_lambda_color(t)
		
		var mat = StandardMaterial3D.new()
		mat.albedo_color = color
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.3
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.albedo_color.a = 0.6
		segment.material_override = mat
		
		add_child(segment)

func _build_scale_labels() -> void:
	# Order label (λ=0)
	var label_order = Label3D.new()
	label_order.text = "ORDER"
	label_order.font_size = 24
	label_order.pixel_size = 0.001
	label_order.position = Vector3(0, -rail_height - 0.03, 0)
	label_order.modulate = COLOR_ORDER
	add_child(label_order)
	
	# Edge label (λ≈0.4)
	var label_edge = Label3D.new()
	label_edge.text = "EDGE"
	label_edge.font_size = 24
	label_edge.pixel_size = 0.001
	label_edge.position = Vector3(rail_length * 0.4, -rail_height - 0.03, 0)
	label_edge.modulate = COLOR_EDGE
	add_child(label_edge)
	
	# Chaos label (λ=1)
	var label_chaos = Label3D.new()
	label_chaos.text = "CHAOS"
	label_chaos.font_size = 24
	label_chaos.pixel_size = 0.001
	label_chaos.position = Vector3(rail_length, -rail_height - 0.03, 0)
	label_chaos.modulate = COLOR_CHAOS
	add_child(label_chaos)

func _build_particles() -> void:
	_particles = GPUParticles3D.new()
	_particles.amount = 50
	_particles.lifetime = 2.0
	_particles.position = Vector3(rail_length / 2, rail_height + 0.1, 0)
	
	var particle_mat = ParticleProcessMaterial.new()
	particle_mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	particle_mat.emission_box_extents = Vector3(rail_length / 2, 0.05, 0.05)
	particle_mat.direction = Vector3(0, 1, 0)
	particle_mat.spread = 30.0
	particle_mat.initial_velocity_min = 0.05
	particle_mat.initial_velocity_max = 0.15
	particle_mat.gravity = Vector3(0, -0.1, 0)
	particle_mat.scale_min = 0.5
	particle_mat.scale_max = 1.5
	_particles.process_material = particle_mat
	
	# Particle mesh
	var particle_mesh = SphereMesh.new()
	particle_mesh.radius = 0.005
	particle_mesh.height = 0.01
	_particles.draw_pass_1 = particle_mesh
	
	add_child(_particles)

func _on_slider_moved(position: float) -> void:
	# Convert slider position to lambda value
	lambda = position / rail_length
	
func _on_slider_grabbed(_interactable) -> void:
	_is_grabbed = true
	emit_signal("slider_grabbed")
	# Apply glow effect like grab_sphere
	if _handle_material:
		_handle_material.emission_energy_multiplier = GLOW_EMISSION_ENERGY
		# Scale up slightly when grabbed
		if _handle_mesh:
			var tween = create_tween()
			tween.tween_property(_handle_mesh, "scale", Vector3(1.3, 1.3, 1.3), 0.1)
	
func _on_slider_released(_interactable) -> void:
	_is_grabbed = false
	emit_signal("slider_released")
	# Reset glow effect
	if _handle_material:
		_handle_material.emission_energy_multiplier = 0.5
		# Scale back to normal
		if _handle_mesh:
			var tween = create_tween()
			tween.tween_property(_handle_mesh, "scale", Vector3.ONE, 0.1)

func _update_visuals() -> void:
	# Update handle position
	if _slider:
		_slider.slider_position = lambda * rail_length
	
	# Update handle color
	var color = _get_lambda_color(lambda)
	if _handle_material:
		_handle_material.albedo_color = color
		_handle_material.emission = color
	
	# Update label
	if _label:
		_label.text = "λ = %.2f" % lambda
		_label.modulate = color
	
	# Update particles based on lambda
	if _particles and _particles.process_material:
		var particle_mat = _particles.process_material as ParticleProcessMaterial
		# More particles at higher lambda (more chaos)
		_particles.amount = int(lerp(10.0, 100.0, lambda))
		# Faster at higher lambda
		particle_mat.initial_velocity_max = lerp(0.05, 0.3, lambda)
		# More spread at higher lambda
		particle_mat.spread = lerp(10.0, 60.0, lambda)

func _get_lambda_color(value: float) -> Color:
	# Gradient: Blue (order) → Green (edge) → Red (chaos)
	if value < 0.4:
		# Order to Edge
		var t = value / 0.4
		return COLOR_ORDER.lerp(COLOR_EDGE, t)
	else:
		# Edge to Chaos
		var t = (value - 0.4) / 0.6
		return COLOR_EDGE.lerp(COLOR_CHAOS, t)

# Public API

## Set lambda value programmatically
func set_lambda(value: float) -> void:
	lambda = value

## Get current lambda value
func get_lambda() -> float:
	return lambda

## Move slider to specific lambda value
func move_to(value: float) -> void:
	if _slider:
		_slider.move_slider(value * rail_length)

## Get description of current lambda state
func get_state_description() -> String:
	if lambda < 0.2:
		return "Crystal (pure order)"
	elif lambda < 0.35:
		return "Stable (low entropy)"
	elif lambda < 0.5:
		return "Edge of Chaos (adaptive)"
	elif lambda < 0.7:
		return "Creative (high entropy)"
	else:
		return "Dissolution (chaos)"

## Check if at edge of chaos
func is_at_edge() -> bool:
	return lambda >= 0.3 and lambda <= 0.5

## Static method to find all lambda sliders in scene
static func get_all_sliders() -> Array:
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		return tree.get_nodes_in_group("qfep_lambda_controllers")
	return []

## Static method to get global lambda value (average of all sliders)
static func get_global_lambda() -> float:
	var sliders = get_all_sliders()
	if sliders.is_empty():
		return 0.4  # Default
	
	var total = 0.0
	for slider in sliders:
		if slider.has_method("get_lambda"):
			total += slider.get_lambda()
	
	return total / sliders.size()
