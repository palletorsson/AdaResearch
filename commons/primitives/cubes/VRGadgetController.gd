# VRGadgetController.gd
# Chapter 6: The VR Gadget Cube
# Extends PickupController with UI and touch interactions

extends "res://commons/scenes/mapobjects/PickupController.gd"

@export var ui_show_distance: float = 1.5
@export var haptic_intensity: float = 0.3
@export var info_text: String = "VR Interactive Cube"

var ui_3d: Node3D
var info_panel_mesh: MeshInstance3D
var info_control: Control
var touch_area: Area3D
var ui_visible: bool = false
var player_camera: Camera3D

# Additional signals for gadget functionality
signal gadget_touched(position: Vector3)
signal gadget_examined(duration: float)

func _ready():
	# Call parent ready first
	super()
	
	# Find UI components
	ui_3d = find_child("UI3D", false, false)
	info_panel_mesh = find_child("InfoPanel", true, false)
	info_control = find_child("UIControl", true, false)
	touch_area = find_child("TouchArea", true, false)
	
	# Hide UI initially
	if ui_3d:
		ui_3d.visible = false
	
	# Connect touch area signals
	if touch_area:
		touch_area.area_entered.connect(_on_touch_area_entered)
		touch_area.area_exited.connect(_on_touch_area_exited)
	
	# Find player camera for UI orientation
	_find_player_camera()
	
	print("VRGadgetController: VR gadget ready with UI system")

func _process(delta):
	# Update UI visibility based on player proximity
	_update_ui_visibility()
	
	# Keep UI facing the player
	if ui_visible and ui_3d and player_camera:
		ui_3d.look_at(player_camera.global_position, Vector3.UP)

func _find_player_camera():
	# Look for VR camera in the scene
	var xr_origin = get_tree().get_first_node_in_group("xr_origin")
	if xr_origin:
		player_camera = xr_origin.find_child("XRCamera3D", true, false)
	
	if not player_camera:
		# Fallback to any camera
		player_camera = get_viewport().get_camera_3d()

func _update_ui_visibility():
	if not player_camera or not ui_3d:
		return
	
	var distance = global_position.distance_to(player_camera.global_position)
	var should_show = distance <= ui_show_distance and not is_grabbed
	
	if should_show != ui_visible:
		ui_visible = should_show
		ui_3d.visible = ui_visible
		
		if ui_visible:
			_animate_ui_show()
		else:
			_animate_ui_hide()

func _animate_ui_show():
	if ui_3d:
		var tween = create_tween()
		ui_3d.scale = Vector3.ZERO
		tween.tween_property(ui_3d, "scale", Vector3.ONE, 0.3)
		tween.tween_property(ui_3d, "position", Vector3(0, 1.5, 0), 0.3)

func _animate_ui_hide():
	if ui_3d:
		var tween = create_tween()
		tween.tween_property(ui_3d, "scale", Vector3.ZERO, 0.2)

func _on_touch_area_entered(area: Area3D):
	# Handle finger/controller touch
	if "finger" in area.name.to_lower() or "hand" in area.name.to_lower():
		_trigger_touch_interaction(area.global_position)
		_provide_haptic_feedback(area)

func _on_touch_area_exited(area: Area3D):
	print("VRGadgetController: Touch area exited")

func _trigger_touch_interaction(touch_position: Vector3):
	print("VRGadgetController: Gadget touched at: %s" % touch_position)
	
	# Visual feedback
	_flash_touch_indicator()
	
	# Emit signal for external systems
	gadget_touched.emit(touch_position)
	
	# Update info panel if available
	_update_info_display()

func _provide_haptic_feedback(area: Area3D):
	# Try to trigger haptic feedback on VR controller
	var controller = area.get_parent()
	if controller and controller.has_method("pulse"):
		controller.pulse(haptic_intensity, 0.1)

func _flash_touch_indicator():
	# Quick flash effect on touch
	if mesh_instance and mesh_instance.material_override:
		var material = mesh_instance.material_override as ShaderMaterial
		if material:
			var original_emission = material.get_shader_parameter("emissionColor")
			material.set_shader_parameter("emissionColor", Color.WHITE)
			
			# Restore after brief flash
			var timer = Timer.new()
			timer.wait_time = 0.1
			timer.one_shot = true
			timer.timeout.connect(func(): material.set_shader_parameter("emissionColor", original_emission))
			add_child(timer)
			timer.start()

func _update_info_display():
	if info_control:
		# Update text or trigger info animation
		var info_label = info_control.find_child("InfoLabel")
		if info_label:
			info_label.text = info_text
		print("VRGadgetController: Updating info display")

# Override grab behavior to hide UI
func grabbed(grabber):
	super.grabbed(grabber)
	if ui_3d:
		ui_3d.visible = false
		ui_visible = false

func released(grabber):
	super.released(grabber)
	# UI visibility will be handled by _update_ui_visibility in _process

# Public API for external configuration
func set_info_text(text: String):
	info_text = text
	_update_info_display()

func trigger_examination_mode():
	print("VRGadgetController: Entering examination mode")
	gadget_examined.emit(1.0)  # Duration placeholder
