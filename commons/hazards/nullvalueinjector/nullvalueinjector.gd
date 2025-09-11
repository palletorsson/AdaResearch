# NullInjectorEntity.gd
# Malicious entity that injects null values into the scene to cause chaos
extends Node3D
class_name NullInjectorEntity

# Injection settings
@export var injection_interval: float = 8.0
@export var max_null_injections: int = 20
@export var target_random_nodes: bool = true
@export var target_player_components: bool = true
@export var target_scene_objects: bool = true

# Null injection types
enum InjectionType {
	NULL_REFERENCE,
	EMPTY_STRING,
	ZERO_VECTOR,
	INVALID_RESOURCE,
	BROKEN_SIGNAL,
	CORRUPTED_PROPERTY,
	MISSING_CHILD,
	DELETED_SCENE
}

# Corruption intensity
@export var corruption_level: float = 1.0
@export var enable_cascading_failures: bool = true
@export var enable_error_suppression: bool = false  # Hide errors to make debugging harder

# Visual appearance
@export var entity_color: Color = Color(0.0, 0.0, 0.0, 0.8)  # Dark/void
@export var corruption_color: Color = Color(1.0, 0.0, 1.0, 1.0)  # Magenta error color

# Internal state
var injection_timer: float = 0.0
var injected_nulls: Array = []
var target_nodes: Array = []
var corruption_effects: Array = []
var original_error_handler: Callable

# Entity components
var entity_mesh: MeshInstance3D
var corruption_particles: GPUParticles3D
var void_audio: AudioStreamPlayer3D
var scanning_area: Area3D

# Tracking injected chaos
class NullInjection:
	var target_node: Node
	var property_name: String
	var original_value: Variant
	var injection_type: InjectionType
	var injection_time: float
	var is_active: bool = true
	
	func _init(node: Node, prop: String, original: Variant, type: InjectionType):
		target_node = node
		property_name = prop
		original_value = original
		injection_type = type
		injection_time = Time.get_time_dict_from_system().second

signal null_injected(target_node: Node, property: String, injection_type: InjectionType)
signal corruption_spread(affected_nodes: int)
signal system_destabilized(severity: String)
signal reality_breach_detected()

func _ready():
	# Create entity appearance
	_create_entity_mesh()
	
	# Setup corruption effects
	_create_corruption_effects()
	
	# Setup scanning for targets
	_setup_target_scanning()
	
	# Setup audio
	_setup_audio()
	
	# Hook into error handling if enabled
	if not enable_error_suppression:
		_setup_error_monitoring()
	
	# Start the corruption
	_begin_corruption()
	
	print("NullInjectorEntity: Reality corruption entity initialized")

func _create_entity_mesh():
	entity_mesh = MeshInstance3D.new()
	
	# Create void-like appearance (inverted sphere)
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 1.0
	sphere_mesh.height = 2.0
	entity_mesh.mesh = sphere_mesh
	
	# Create void material
	var void_material = StandardMaterial3D.new()
	void_material.albedo_color = entity_color
	void_material.emission_enabled = true
	void_material.emission = Color(0.1, 0.0, 0.1, 1.0)  # Dark purple glow
	void_material.emission_energy = 1.0
	void_material.metallic = 1.0
	void_material.roughness = 0.0
	void_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	void_material.cull_mode = BaseMaterial3D.CULL_FRONT  # Inside-out rendering
	entity_mesh.material_override = void_material
	
	add_child(entity_mesh)
	
	# Add corruption tendrils
	_create_corruption_tendrils()

func _create_corruption_tendrils():
	# Create writhing tendrils that represent corruption spreading
	for i in range(8):
		var tendril = MeshInstance3D.new()
		var cylinder_mesh = CylinderMesh.new()
		cylinder_mesh.top_radius = 0.05
		cylinder_mesh.bottom_radius = 0.02
		cylinder_mesh.height = 2.0
		tendril.mesh = cylinder_mesh
		
		var tendril_material = StandardMaterial3D.new()
		tendril_material.albedo_color = corruption_color
		tendril_material.emission_enabled = true
		tendril_material.emission = corruption_color
		tendril_material.emission_energy = 2.0
		tendril_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		tendril_material.albedo_color.a = 0.7
		tendril.material_override = tendril_material
		
		# Position tendrils around entity
		var angle = (float(i) / 8.0) * 2.0 * PI
		tendril.position = Vector3(cos(angle) * 1.5, 0, sin(angle) * 1.5)
		tendril.rotation.z = randf() * PI
		
		entity_mesh.add_child(tendril)

func _create_corruption_effects():
	# Create particle system showing data corruption
	corruption_particles = GPUParticles3D.new()
	corruption_particles.emitting = true
	corruption_particles.amount = 200
	corruption_particles.lifetime = 4.0
	
	var corruption_material = ParticleProcessMaterial.new()
	corruption_material.direction = Vector3(0, 0, 0)  # Chaotic directions
	corruption_material.spread = 90.0
	corruption_material.initial_velocity_min = 1.0
	corruption_material.initial_velocity_max = 8.0
	corruption_material.gravity = Vector3(0, 0, 0)  # Float in void
	corruption_material.scale_min = 0.05
	corruption_material.scale_max = 0.3
	
	# Error/corruption colors
	var corruption_gradient = Gradient.new()
	corruption_gradient.add_point(0.0, Color.WHITE)  # Data
	corruption_gradient.add_point(0.3, corruption_color)  # Corruption
	corruption_gradient.add_point(0.7, Color.RED)  # Error
	corruption_gradient.add_point(1.0, Color(0, 0, 0, 0))  # Void
	
	var corruption_texture = GradientTexture1D.new()
	corruption_texture.gradient = corruption_gradient
	corruption_material.color_ramp = corruption_texture
	
	corruption_particles.process_material = corruption_material
	corruption_particles.draw_pass_1 = QuadMesh.new()
	add_child(corruption_particles)

func _setup_target_scanning():
	scanning_area = Area3D.new()
	scanning_area.monitoring = true
	scanning_area.body_entered.connect(_on_potential_target_entered)
	
	var scan_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 15.0  # Wide scanning range
	scan_shape.shape = sphere_shape
	scanning_area.add_child(scan_shape)
	
	add_child(scanning_area)

func _setup_audio():
	void_audio = AudioStreamPlayer3D.new()
	# Create an eerie void sound programmatically if no audio assigned
	add_child(void_audio)

func _setup_error_monitoring():
	# Hook into Godot's error reporting (if possible)
	print("NullInjectorEntity: Monitoring system errors...")

func _begin_corruption():
	print("NullInjectorEntity: Beginning reality corruption...")
	_scan_for_targets()

func _process(delta):
	injection_timer += delta
	
	# Animate the entity
	_animate_entity(delta)
	
	# Periodic null injection
	if injection_timer >= injection_interval:
		_perform_null_injection()
		injection_timer = 0.0
	
	# Update existing corruptions
	_update_corruptions(delta)
	
	# Check for cascading failures
	if enable_cascading_failures:
		_check_cascading_failures()

func _animate_entity(delta):
	if entity_mesh:
		# Slowly rotate and pulse
		entity_mesh.rotation.y += delta * 0.5
		entity_mesh.rotation.x += delta * 0.2
		
		# Pulse scale based on corruption level
		var pulse = 1.0 + sin(Time.get_time_dict_from_system().second * 2.0) * 0.2 * corruption_level
		entity_mesh.scale = Vector3.ONE * pulse
		
		# Animate tendrils
		for child in entity_mesh.get_children():
			if child is MeshInstance3D:
				child.rotation.y += delta * randf_range(1.0, 3.0)
				child.rotation.z += delta * randf_range(-2.0, 2.0)

func _scan_for_targets():
	target_nodes.clear()
	
	# Get all nodes in the scene
	var all_nodes = _get_all_scene_nodes(get_tree().current_scene)
	
	for node in all_nodes:
		if _is_valid_target(node):
			target_nodes.append(node)
	
	print("NullInjectorEntity: Found ", target_nodes.size(), " potential targets")

func _get_all_scene_nodes(node: Node) -> Array:
	var nodes = [node]
	for child in node.get_children():
		nodes.append_array(_get_all_scene_nodes(child))
	return nodes

func _is_valid_target(node: Node) -> bool:
	# Don't target ourselves or critical system nodes
	if node == self or node.is_ancestor_of(self):
		return false
	
	# Don't target the main scene
	if node == get_tree().current_scene:
		return false
	
	# Target specific node types based on settings
	if target_player_components and ("player" in node.name.to_lower() or node.is_in_group("player")):
		return true
	
	if target_scene_objects and (node is MeshInstance3D or node is RigidBody3D or node is CharacterBody3D):
		return true
	
	if target_random_nodes and randf() < 0.1:  # 10% chance for random nodes
		return true
	
	return false

func _perform_null_injection():
	if injected_nulls.size() >= max_null_injections:
		print("NullInjectorEntity: Maximum corruption reached")
		emit_signal("system_destabilized", "critical")
		return
	
	if target_nodes.is_empty():
		_scan_for_targets()
		if target_nodes.is_empty():
			return
	
	# Select random target
	var target = target_nodes[randi() % target_nodes.size()]
	if not is_instance_valid(target):
		target_nodes.erase(target)
		return
	
	# Choose injection type
	var injection_type = InjectionType.values()[randi() % InjectionType.size()]
	
	# Perform the injection
	_inject_null_into_target(target, injection_type)

func _inject_null_into_target(target: Node, injection_type: InjectionType):
	if not is_instance_valid(target):
		return
	
	match injection_type:
		InjectionType.NULL_REFERENCE:
			_inject_null_reference(target)
		InjectionType.EMPTY_STRING:
			_inject_empty_string(target)
		InjectionType.ZERO_VECTOR:
			_inject_zero_vector(target)
		InjectionType.INVALID_RESOURCE:
			_inject_invalid_resource(target)
		InjectionType.BROKEN_SIGNAL:
			_inject_broken_signal(target)
		InjectionType.CORRUPTED_PROPERTY:
			_inject_corrupted_property(target)
		InjectionType.MISSING_CHILD:
			_inject_missing_child(target)
		InjectionType.DELETED_SCENE:
			_inject_deleted_scene(target)

func _inject_null_reference(target: Node):
	# Try to find and nullify object references
	var property_list = target.get_property_list()
	var candidate_properties = []
	
	for prop in property_list:
		if prop.type == TYPE_OBJECT and prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			candidate_properties.append(prop.name)
	
	if candidate_properties.size() > 0:
		var prop_name = candidate_properties[randi() % candidate_properties.size()]
		var original_value = target.get(prop_name)
		
		# Store the injection
		var injection = NullInjection.new(target, prop_name, original_value, InjectionType.NULL_REFERENCE)
		injected_nulls.append(injection)
		
		# Apply the null
		target.set(prop_name, null)
		
		_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
		emit_signal("null_injected", target, prop_name, InjectionType.NULL_REFERENCE)
		print("NullInjectorEntity: Nullified reference '", prop_name, "' in ", target.name)

func _inject_empty_string(target: Node):
	# Find string properties and empty them
	var property_list = target.get_property_list()
	for prop in property_list:
		if prop.type == TYPE_STRING and prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var original_value = target.get(prop.name)
			if original_value != "":
				var injection = NullInjection.new(target, prop.name, original_value, InjectionType.EMPTY_STRING)
				injected_nulls.append(injection)
				
				target.set(prop.name, "")
				_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
				emit_signal("null_injected", target, prop.name, InjectionType.EMPTY_STRING)
				print("NullInjectorEntity: Emptied string '", prop.name, "' in ", target.name)
				break

func _inject_zero_vector(target: Node):
	# Find Vector3/Vector2 properties and zero them
	var property_list = target.get_property_list()
	for prop in property_list:
		if (prop.type == TYPE_VECTOR3 or prop.type == TYPE_VECTOR2) and prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var original_value = target.get(prop.name)
			var injection = NullInjection.new(target, prop.name, original_value, InjectionType.ZERO_VECTOR)
			injected_nulls.append(injection)
			
			var zero_value = Vector3.ZERO if prop.type == TYPE_VECTOR3 else Vector2.ZERO
			target.set(prop.name, zero_value)
			_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
			emit_signal("null_injected", target, prop.name, InjectionType.ZERO_VECTOR)
			print("NullInjectorEntity: Zeroed vector '", prop.name, "' in ", target.name)
			break

func _inject_invalid_resource(target: Node):
	# Try to break resource references
	if target.has_method("set_texture") and randf() < 0.5:
		var injection = NullInjection.new(target, "texture", null, InjectionType.INVALID_RESOURCE)
		injected_nulls.append(injection)
		target.set("texture", null)
		_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
		emit_signal("null_injected", target, "texture", InjectionType.INVALID_RESOURCE)
		print("NullInjectorEntity: Corrupted texture resource in ", target.name)

func _inject_broken_signal(target: Node):
	# Disconnect random signals
	var signal_list = target.get_signal_list()
	if signal_list.size() > 0:
		var signal_info = signal_list[randi() % signal_list.size()]
		var signal_name = signal_info.name
		
		# Get connections for this signal
		var connections = target.get_signal_connection_list(signal_name)
		if connections.size() > 0:
			var connection = connections[0]
			target.disconnect(signal_name, connection.callable)
			
			var injection = NullInjection.new(target, signal_name, connection, InjectionType.BROKEN_SIGNAL)
			injected_nulls.append(injection)
			
			_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
			emit_signal("null_injected", target, signal_name, InjectionType.BROKEN_SIGNAL)
			print("NullInjectorEntity: Broke signal connection '", signal_name, "' in ", target.name)

func _inject_corrupted_property(target: Node):
	# Corrupt numeric properties with invalid values
	var property_list = target.get_property_list()
	for prop in property_list:
		if (prop.type == TYPE_FLOAT or prop.type == TYPE_INT) and prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			var original_value = target.get(prop.name)
			var injection = NullInjection.new(target, prop.name, original_value, InjectionType.CORRUPTED_PROPERTY)
			injected_nulls.append(injection)
			
			# Inject NaN or infinity
			var corrupt_value = NAN if prop.type == TYPE_FLOAT else 2147483647  # Max int
			target.set(prop.name, corrupt_value)
			_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
			emit_signal("null_injected", target, prop.name, InjectionType.CORRUPTED_PROPERTY)
			print("NullInjectorEntity: Corrupted property '", prop.name, "' in ", target.name)
			break

func _inject_missing_child(target: Node):
	# Randomly remove child nodes
	if target.get_child_count() > 0:
		var child_to_remove = target.get_child(randi() % target.get_child_count())
		var injection = NullInjection.new(target, "missing_child_" + child_to_remove.name, child_to_remove, InjectionType.MISSING_CHILD)
		injected_nulls.append(injection)
		
		target.remove_child(child_to_remove)
		_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
		emit_signal("null_injected", target, "child_node", InjectionType.MISSING_CHILD)
		print("NullInjectorEntity: Removed child '", child_to_remove.name, "' from ", target.name)

func _inject_deleted_scene(target: Node):
	# Mark entire nodes for deletion (most destructive)
	if randf() < 0.1 * corruption_level:  # Rare but devastating
		var injection = NullInjection.new(target, "deleted_scene", target, InjectionType.DELETED_SCENE)
		injected_nulls.append(injection)
		
		_create_corruption_effect(target.global_position if target.has_method("get_global_position") else global_position)
		emit_signal("null_injected", target, "entire_node", InjectionType.DELETED_SCENE)
		print("NullInjectorEntity: Marking node for deletion: ", target.name)
		
		# Delay the deletion to make it more chaotic
		var delete_timer = Timer.new()
		delete_timer.wait_time = randf_range(2.0, 10.0)
		delete_timer.one_shot = true
		delete_timer.timeout.connect(target.queue_free)
		add_child(delete_timer)
		delete_timer.start()

func _create_corruption_effect(position: Vector3):
	# Visual effect at corruption site
	var effect_particles = GPUParticles3D.new()
	effect_particles.global_position = position
	effect_particles.emitting = true
	effect_particles.amount = 20
	effect_particles.lifetime = 1.0
	effect_particles.one_shot = true
	
	var effect_material = ParticleProcessMaterial.new()
	effect_material.direction = Vector3(0, 1, 0)
	effect_material.spread = 45.0
	effect_material.initial_velocity_min = 3.0
	effect_material.initial_velocity_max = 8.0
	effect_material.gravity = Vector3(0, 0, 0)
	effect_material.scale_min = 0.1
	effect_material.scale_max = 0.4
	
	var effect_gradient = Gradient.new()
	effect_gradient.add_point(0.0, corruption_color)
	effect_gradient.add_point(1.0, Color(corruption_color.r, corruption_color.g, corruption_color.b, 0))
	
	var effect_texture = GradientTexture1D.new()
	effect_texture.gradient = effect_gradient
	effect_material.color_ramp = effect_texture
	
	effect_particles.process_material = effect_material
	effect_particles.draw_pass_1 = QuadMesh.new()
	get_tree().current_scene.add_child(effect_particles)
	
	# Auto cleanup
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 2.0
	cleanup_timer.one_shot = true
	cleanup_timer.timeout.connect(effect_particles.queue_free)
	get_tree().current_scene.add_child(cleanup_timer)
	cleanup_timer.start()

func _update_corruptions(delta):
	# Monitor and manage active corruptions
	var active_corruptions = 0
	for injection in injected_nulls:
		if injection.is_active and is_instance_valid(injection.target_node):
			active_corruptions += 1
	
	if active_corruptions != injected_nulls.size():
		print("NullInjectorEntity: ", active_corruptions, " active corruptions detected")

func _check_cascading_failures():
	# Look for nodes that might be failing due to our corruptions
	var affected_count = 0
	for injection in injected_nulls:
		if injection.is_active and not is_instance_valid(injection.target_node):
			affected_count += 1
	
	if affected_count > 5:
		emit_signal("corruption_spread", affected_count)
		print("NullInjectorEntity: Cascading failures detected!")
		
	if affected_count > 15:
		emit_signal("reality_breach_detected")
		print("NullInjectorEntity: REALITY BREACH - System critically destabilized!")

func _on_potential_target_entered(body):
	if _is_valid_target(body) and not body in target_nodes:
		target_nodes.append(body)
		print("NullInjectorEntity: New target acquired: ", body.name)

# Public API
func set_corruption_level(level: float):
	corruption_level = clamp(level, 0.1, 5.0)
	injection_interval = max(1.0, 8.0 / corruption_level)  # Faster corruption at higher levels

func restore_all_corruptions():
	print("NullInjectorEntity: Attempting to restore all corruptions...")
	var restored_count = 0
	
	for injection in injected_nulls:
		if injection.is_active and is_instance_valid(injection.target_node):
			match injection.injection_type:
				InjectionType.NULL_REFERENCE, InjectionType.EMPTY_STRING, InjectionType.ZERO_VECTOR, InjectionType.CORRUPTED_PROPERTY:
					injection.target_node.set(injection.property_name, injection.original_value)
				InjectionType.BROKEN_SIGNAL:
					# Reconnect signal if possible
					var connection_info = injection.original_value
					if connection_info and connection_info.has("callable"):
						injection.target_node.connect(injection.property_name, connection_info.callable)
				InjectionType.MISSING_CHILD:
					# Re-add child if still valid
					if is_instance_valid(injection.original_value):
						injection.target_node.add_child(injection.original_value)
			
			injection.is_active = false
			restored_count += 1
	
	print("NullInjectorEntity: Restored ", restored_count, " corruptions")

func get_corruption_stats() -> Dictionary:
	var active_count = 0
	var by_type = {}
	
	for injection in injected_nulls:
		if injection.is_active:
			active_count += 1
			var type_name = InjectionType.keys()[injection.injection_type]
			by_type[type_name] = by_type.get(type_name, 0) + 1
	
	return {
		"total_injections": injected_nulls.size(),
		"active_corruptions": active_count,
		"corruption_level": corruption_level,
		"target_count": target_nodes.size(),
		"corruptions_by_type": by_type
	}

func destroy_entity():
	restore_all_corruptions()
	queue_free()
	print("NullInjectorEntity: Entity destroyed, attempting to restore reality...")
