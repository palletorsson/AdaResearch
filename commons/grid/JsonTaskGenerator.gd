# JsonTaskGenerator.gd
# Procedural task generator that creates interactive objects from JSON definitions
# This replaces the old scene-based task loading system

extends RefCounted
class_name JsonTaskGenerator

# Registry of procedural generators for different task types
static var generators = {}

# Initialize the generator registry
static func _static_init():
	_register_default_generators()

# Register all default task generators
static func _register_default_generators():
	generators["interactive"] = _generate_interactive_task
	generators["pickup"] = _generate_pickup_task
	generators["button"] = _generate_button_task
	generators["display"] = _generate_display_task
	generators["algorithm"] = _generate_algorithm_task
	generators["art"] = _generate_art_task
	generators["custom"] = _generate_custom_task

# Main function to generate a task from JSON definition
static func generate_task_from_json(task_id: String, definition: Dictionary, parent: Node3D = null) -> Node3D:
	var task_type = definition.get("type", "custom")
	
	if not generators.has(task_type):
		print("JsonTaskGenerator: Unknown task type '%s', falling back to custom generator" % task_type)
		task_type = "custom"
	
	var generator = generators[task_type]
	var task_object = generator.call(task_id, definition, parent)
	
	if task_object:
		# Apply common properties
		_apply_common_properties(task_object, task_id, definition)
		print("JsonTaskGenerator: Generated task '%s' of type '%s'" % [task_id, task_type])
	else:
		print("JsonTaskGenerator: Failed to generate task '%s'" % task_id)
	
	return task_object

# Apply properties common to all tasks
static func _apply_common_properties(task_object: Node3D, task_id: String, definition: Dictionary):
	task_object.name = task_id
	
	# Set metadata
	task_object.set_meta("task_id", task_id)
	task_object.set_meta("task_definition", definition)
	
	# Apply transform properties if specified
	var properties = definition.get("properties", {})
	
	if properties.has("scale"):
		var scale_data = properties["scale"]
		if scale_data is Array and scale_data.size() >= 3:
			task_object.scale = Vector3(scale_data[0], scale_data[1], scale_data[2])
		elif scale_data is float or scale_data is int:
			task_object.scale = Vector3.ONE * scale_data
	
	if properties.has("rotation"):
		var rotation_data = properties["rotation"]
		if rotation_data is Array and rotation_data.size() >= 3:
			task_object.rotation_degrees = Vector3(rotation_data[0], rotation_data[1], rotation_data[2])
	
	# Add interaction capability
	_add_interaction_system(task_object, task_id, definition)

# Add interaction system to task objects
static func _add_interaction_system(task_object: Node3D, task_id: String, definition: Dictionary):
	# Add signals for interaction
	if not task_object.has_signal("task_activated"):
		task_object.add_user_signal("task_activated", [{"name": "task_id", "type": TYPE_STRING}])
	
	if not task_object.has_signal("task_completed"):
		task_object.add_user_signal("task_completed", [{"name": "task_id", "type": TYPE_STRING}])
	
	# Add interaction script
	var script_code = """
extends Node3D

signal task_activated(task_id: String)
signal task_completed(task_id: String)

var task_id: String = ""
var task_definition: Dictionary = {}
var is_active: bool = false

func _ready():
	task_id = get_meta("task_id", "")
	task_definition = get_meta("task_definition", {})

func activate():
	if not is_active:
		is_active = true
		emit_signal("task_activated", task_id)
		_on_task_activated()

func complete():
	if is_active:
		emit_signal("task_completed", task_id)
		_on_task_completed()

func _on_task_activated():
	# Override in specific implementations
	pass

func _on_task_completed():
	# Override in specific implementations  
	pass

func _input_event(camera, event, position, normal, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		activate()
"""
	
	var script = GDScript.new()
	script.source_code = script_code
	task_object.set_script(script)

# Generate interactive task (grabbable objects)
static func _generate_interactive_task(task_id: String, definition: Dictionary, parent: Node3D) -> Node3D:
	var properties = definition.get("properties", {})
	var geometry = properties.get("geometry", {"type": "cube", "size": [1, 1, 1]})
	
	# Create root node
	var task_object = RigidBody3D.new()
	task_object.name = task_id + "_interactive"
	
	# Create mesh
	var mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = _create_mesh_from_geometry(geometry)
	mesh_instance.material_override = _create_material_from_definition(properties.get("material", {}))
	task_object.add_child(mesh_instance)
	
	# Create collision
	var collision = CollisionShape3D.new()
	collision.shape = _create_collision_from_geometry(geometry)
	task_object.add_child(collision)
	
	# Configure RigidBody
	if properties.get("grabbable", true):
		task_object.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		# Add XR grab capability here
	
	return task_object

# Generate pickup task (simple interactive cubes)
static func _generate_pickup_task(task_id: String, definition: Dictionary, parent: Node3D) -> Node3D:
	var properties = definition.get("properties", {})
	
	# Create StaticBody3D for pickup
	var task_object = StaticBody3D.new()
	task_object.name = task_id + "_pickup"
	
	# Create visual representation
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.8, 0.8, 0.8)  # Slightly smaller than standard cubes
	mesh_instance.mesh = box_mesh
	
	# Create pickup material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.8, 0.3)  # Golden color for pickups
	material.emission_enabled = true
	material.emission = Color(0.2, 0.16, 0.06)
	material.metallic = 0.3
	material.roughness = 0.7
	mesh_instance.material_override = material
	task_object.add_child(mesh_instance)
	
	# Create collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.8, 0.8, 0.8)
	collision.shape = box_shape
	task_object.add_child(collision)
	
	# Add floating animation
	_add_floating_animation(mesh_instance)
	
	return task_object

# Generate button task (activatable elements)
static func _generate_button_task(task_id: String, definition: Dictionary, parent: Node3D) -> Node3D:
	var properties = definition.get("properties", {})
	
	# Create button base
	var task_object = StaticBody3D.new()
	task_object.name = task_id + "_button"
	
	# Create button visual
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.radius_top = 0.3
	cylinder_mesh.radius_bottom = 0.3
	cylinder_mesh.height = 0.2
	mesh_instance.mesh = cylinder_mesh
	
	# Button material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.8, 0.2, 0.2)  # Red button
	material.metallic = 0.8
	material.roughness = 0.2
	mesh_instance.material_override = material
	task_object.add_child(mesh_instance)
	
	# Create collision
	var collision = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.radius = 0.3
	cylinder_shape.height = 0.2
	collision.shape = cylinder_shape
	task_object.add_child(collision)
	
	return task_object

# Generate display task (information panels)
static func _generate_display_task(task_id: String, definition: Dictionary, parent: Node3D) -> Node3D:
	var properties = definition.get("properties", {})
	
	# Create display panel
	var task_object = StaticBody3D.new()
	task_object.name = task_id + "_display"
	
	# Create panel mesh
	var mesh_instance = MeshInstance3D.new()
	var quad_mesh = QuadMesh.new()
	quad_mesh.size = Vector2(2.0, 1.5)
	mesh_instance.mesh = quad_mesh
	
	# Display material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.1, 0.1, 0.2)
	material.emission_enabled = true
	material.emission = Color(0.05, 0.05, 0.1)
	mesh_instance.material_override = material
	task_object.add_child(mesh_instance)
	
	# Add text label
	var label = Label3D.new()
	label.text = definition.get("description", "Information Display")
	label.position = Vector3(0, 0, 0.01)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	task_object.add_child(label)
	
	return task_object

# Generate algorithm task (complex interactive algorithms)
static func _generate_algorithm_task(task_id: String, definition: Dictionary, parent: Node3D) -> Node3D:
	var properties = definition.get("properties", {})
	
	# Create algorithm container
	var task_object = Node3D.new()
	task_object.name = task_id + "_algorithm"
	
	# Create visual container
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.5
	mesh_instance.mesh = sphere_mesh
	
	# Algorithm material (animated)
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.3, 0.7, 1.0)
	material.emission_enabled = true
	material.emission = Color(0.1, 0.2, 0.3)
	material.metallic = 0.0
	material.roughness = 0.3
	mesh_instance.material_override = material
	task_object.add_child(mesh_instance)
	
	# Add interaction area
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.6
	collision.shape = sphere_shape
	area.add_child(collision)
	task_object.add_child(area)
	
	# Add pulsing animation
	_add_pulsing_animation(mesh_instance)
	
	return task_object

# Generate art task (creative/aesthetic elements)
static func _generate_art_task(task_id: String, definition: Dictionary, parent: Node3D) -> Node3D:
	var properties = definition.get("properties", {})
	
	# Create art object
	var task_object = StaticBody3D.new()
	task_object.name = task_id + "_art"
	
	# Create artistic mesh (torus for interesting shape)
	var mesh_instance = MeshInstance3D.new()
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = 0.3
	torus_mesh.outer_radius = 0.7
	mesh_instance.mesh = torus_mesh
	
	# Artistic material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.from_hsv(randf(), 0.8, 0.9)  # Random hue
	material.metallic = 0.5
	material.roughness = 0.4
	material.emission_enabled = true
	material.emission = material.albedo_color * 0.2
	mesh_instance.material_override = material
	task_object.add_child(mesh_instance)
	
	# Add rotation animation
	_add_rotation_animation(mesh_instance)
	
	return task_object

# Generate custom task (fallback for unknown types)
static func _generate_custom_task(task_id: String, definition: Dictionary, parent: Node3D) -> Node3D:
	# Create basic interactive object
	var task_object = StaticBody3D.new()
	task_object.name = task_id + "_custom"
	
	# Create basic mesh
	var mesh_instance = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	mesh_instance.mesh = box_mesh
	
	# Default material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0.7, 0.7, 0.7)
	mesh_instance.material_override = material
	task_object.add_child(mesh_instance)
	
	# Create collision
	var collision = CollisionShape3D.new()
	var box_shape = BoxShape3D.new()
	collision.shape = box_shape
	task_object.add_child(collision)
	
	return task_object

# Helper functions for mesh generation
static func _create_mesh_from_geometry(geometry: Dictionary) -> Mesh:
	var mesh_type = geometry.get("type", "cube")
	var size = geometry.get("size", [1, 1, 1])
	
	match mesh_type:
		"cube":
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(size[0], size[1], size[2])
			return box_mesh
		"sphere":
			var sphere_mesh = SphereMesh.new()
			sphere_mesh.radius = size[0] if size.size() > 0 else 0.5
			return sphere_mesh
		"cylinder":
			var cylinder_mesh = CylinderMesh.new()
			cylinder_mesh.radius_top = size[0] if size.size() > 0 else 0.5
			cylinder_mesh.radius_bottom = size[0] if size.size() > 0 else 0.5
			cylinder_mesh.height = size[1] if size.size() > 1 else 1.0
			return cylinder_mesh
		_:
			var box_mesh = BoxMesh.new()
			return box_mesh

# Helper functions for material generation
static func _create_material_from_definition(material_def: Dictionary) -> Material:
	var material = StandardMaterial3D.new()
	
	var color = material_def.get("color", [0.7, 0.7, 0.7])
	material.albedo_color = Color(color[0], color[1], color[2])
	
	material.metallic = material_def.get("metallic", 0.0)
	material.roughness = material_def.get("roughness", 1.0)
	
	if material_def.get("emission", false):
		material.emission_enabled = true
		var emission_color = material_def.get("emission_color", color)
		material.emission = Color(emission_color[0], emission_color[1], emission_color[2]) * 0.2
	
	return material

# Helper functions for collision generation
static func _create_collision_from_geometry(geometry: Dictionary) -> Shape3D:
	var mesh_type = geometry.get("type", "cube")
	var size = geometry.get("size", [1, 1, 1])
	
	match mesh_type:
		"cube":
			var box_shape = BoxShape3D.new()
			box_shape.size = Vector3(size[0], size[1], size[2])
			return box_shape
		"sphere":
			var sphere_shape = SphereShape3D.new()
			sphere_shape.radius = size[0] if size.size() > 0 else 0.5
			return sphere_shape
		"cylinder":
			var cylinder_shape = CylinderShape3D.new()
			cylinder_shape.radius = size[0] if size.size() > 0 else 0.5
			cylinder_shape.height = size[1] if size.size() > 1 else 1.0
			return cylinder_shape
		_:
			var box_shape = BoxShape3D.new()
			return box_shape

# Animation helpers
static func _add_floating_animation(node: Node3D):
	var tween = node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "position:y", 0.2, 2.0)
	tween.tween_property(node, "position:y", -0.2, 2.0)

static func _add_pulsing_animation(node: MeshInstance3D):
	var tween = node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "scale", Vector3.ONE * 1.2, 1.0)
	tween.tween_property(node, "scale", Vector3.ONE * 0.8, 1.0)

static func _add_rotation_animation(node: Node3D):
	var tween = node.create_tween()
	tween.set_loops()
	tween.tween_property(node, "rotation_degrees", Vector3(0, 360, 0), 5.0) 