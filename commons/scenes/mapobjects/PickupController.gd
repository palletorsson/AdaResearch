# PickupController.gd
# Chapter 4: The Interactive Pickup Cube
# Handles VR pickup interactions and visual feedback

extends Node3D

@export var hover_color: Color = Color.YELLOW
@export var grab_color: Color = Color.GREEN
@export var hover_scale_boost: float = 1.1

var original_material: Material
var mesh_instance: MeshInstance3D
var interaction_area: Area3D
var animator: Node3D
var is_grabbed: bool = false
var is_hovered: bool = false

# Signals for external systems
signal cube_grabbed(cube: Node3D)
signal cube_released(cube: Node3D)
signal cube_hovered(cube: Node3D)
signal cube_unhovered(cube: Node3D)

func _ready():
	# Find components
	mesh_instance = find_child("CubeBaseMesh", true, false)
	interaction_area = find_child("InteractionArea", false, false)
	animator = find_child("CubeAnimator", false, false)
	
	# Store original material
	if mesh_instance:
		original_material = mesh_instance.material_override
	
	# Connect interaction signals
	if interaction_area:
		interaction_area.area_entered.connect(_on_hand_entered)
		interaction_area.area_exited.connect(_on_hand_exited)
		interaction_area.body_entered.connect(_on_body_entered)
		print("PickupController: Interaction area connected")

func _on_hand_entered(area: Area3D):
	# Check if it's a hand/controller area
	if "hand" in area.name.to_lower() or "controller" in area.name.to_lower():
		_start_hover()

func _on_hand_exited(area: Area3D):
	if "hand" in area.name.to_lower() or "controller" in area.name.to_lower():
		_end_hover()

func _on_body_entered(body: Node3D):
	# Handle VR controller collision
	if "controller" in body.name.to_lower():
		_start_hover()

func _start_hover():
	if is_grabbed:
		return
		
	is_hovered = true
	_apply_hover_effect()
	cube_hovered.emit(self)
	print("PickupController: Cube hovered")

func _end_hover():
	if is_grabbed:
		return
		
	is_hovered = false
	_remove_hover_effect()
	cube_unhovered.emit(self)

func _apply_hover_effect():
	# Visual feedback for hover
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", hover_color)
	
	# Scale boost
	if animator:
		animator.scale *= hover_scale_boost

func _remove_hover_effect():
	# Restore original appearance
	if mesh_instance:
		mesh_instance.material_override = original_material
	
	# Restore original scale
	if animator:
		animator.scale /= hover_scale_boost

# Called by XR-Tools when grabbed
func grabbed(grabber):
	is_grabbed = true
	_apply_grab_effect()
	cube_grabbed.emit(self)
	print("PickupController: Cube grabbed by: %s" % grabber.name)

# Called by XR-Tools when released
func released(grabber):
	is_grabbed = false
	_remove_grab_effect()
	cube_released.emit(self)
	print("PickupController: Cube released")

func _apply_grab_effect():
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			material.set_shader_parameter("emissionColor", grab_color)

func _remove_grab_effect():
	_remove_hover_effect()  # Reset to normal state
