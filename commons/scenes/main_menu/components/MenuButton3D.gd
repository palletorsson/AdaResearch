extends StaticBody3D

signal clicked

@export var text: String = "Button"
@export var color: Color = Color("ff00ff") # Ada Research Pink
@export var hover_time_required: float = 1.5

@onready var interaction_cube: MeshInstance3D = $InteractionCube
@onready var label: Label3D = $Label3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var progress_indicator: MeshInstance3D = $ProgressIndicator

var _original_scale: Vector3
var _is_hovering: bool = false
var _hover_timer: float = 0.0

var _audio_player: AudioStreamPlayer3D
var _hover_sound: AudioStream
var _click_sound: AudioStream
var _current_controller: XRController3D

func _ready() -> void:
	if label:
		label.text = text
	
	if interaction_cube:
		_original_scale = interaction_cube.scale
		var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("modelColor", color)
		material.set_shader_parameter("wireframeColor", color)
		material.set_shader_parameter("emissionColor", color)
		material.set_shader_parameter("width", 2.0) # Slightly thicker edges
		material.set_shader_parameter("modelOpacity", 0.8) # More opaque for the small cube
		material.set_shader_parameter("wireframeOpacity", 0.8)
		material.set_shader_parameter("emission_strength", 1.0) # Standard glow
		interaction_cube.material_override = material
		
	if progress_indicator:
		progress_indicator.visible = false
		# Ensure material is unique so we don't share progress state
		if progress_indicator.get_active_material(0):
			# If using mesh material
			progress_indicator.set_surface_override_material(0, progress_indicator.get_active_material(0).duplicate())
		elif progress_indicator.material_override:
			# If using material override
			progress_indicator.material_override = progress_indicator.material_override.duplicate()
			
		# Force reset progress
		if progress_indicator.material_override:
			progress_indicator.material_override.set_shader_parameter("progress", 0.0)
			
	_setup_audio()

func _setup_audio() -> void:
	_audio_player = AudioStreamPlayer3D.new()
	add_child(_audio_player)
	
	# Try to load sounds from SoundBank
	if has_node("/root/SoundBank"):
		var sound_bank = get_node("/root/SoundBank")
		if sound_bank.has_method("get_sound"):
			_hover_sound = sound_bank.get_sound("SyntheticSoundGenerator.detection_sound")
			_click_sound = sound_bank.get_sound("SyntheticSoundGenerator.lift_start_sound")

func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return

	if _is_hovering:
		_hover_timer += delta
		
		# Update progress shader
		if progress_indicator:
			if not progress_indicator.visible:
				progress_indicator.visible = true
				
			if progress_indicator.material_override:
				var progress = clamp(_hover_timer / hover_time_required, 0.0, 1.0)
				progress_indicator.material_override.set_shader_parameter("progress", progress)
			else:
				print("MenuButton3D: Error - Progress indicator missing material override")
		
		if _hover_timer >= hover_time_required:
			_trigger_click()
			_is_hovering = false # Reset to prevent multiple clicks
			_hover_timer = 0.0

func pointer_event(event: XRToolsPointerEvent) -> void:
	if not is_visible_in_tree():
		return

	# Capture controller for haptics
	if event.pointer and event.pointer.get_parent() is XRController3D:
		_current_controller = event.pointer.get_parent()
	
	match event.event_type:
		XRToolsPointerEvent.Type.ENTERED:
			pointer_entered()
		XRToolsPointerEvent.Type.EXITED:
			pointer_exited()
			_current_controller = null # Clear controller on exit
		XRToolsPointerEvent.Type.PRESSED:
			# We handle click via hover, but we can keep this for direct click if needed
			pass

func pointer_entered() -> void:
	_is_hovering = true
	_hover_timer = 0.0
	
	# Trigger hover haptic
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.2, 0.05, 0)
	
	if interaction_cube:
		var tween = create_tween()
		tween.tween_property(interaction_cube, "scale", _original_scale * 1.2, 0.1)
		
		# Change color on hover
		if interaction_cube.material_override:
			# White/Bright on hover
			interaction_cube.material_override.set_shader_parameter("modelColor", Color.WHITE)
			interaction_cube.material_override.set_shader_parameter("emissionColor", Color.WHITE)
			interaction_cube.material_override.set_shader_parameter("emission_strength", 3.0)

func pointer_exited() -> void:
	_is_hovering = false
	_hover_timer = 0.0
	
	if progress_indicator:
		progress_indicator.visible = false
		if progress_indicator.material_override:
			progress_indicator.material_override.set_shader_parameter("progress", 0.0)
	
	if interaction_cube:
		var tween = create_tween()
		tween.tween_property(interaction_cube, "scale", _original_scale, 0.1)
		
		# Reset color
		if interaction_cube.material_override:
			interaction_cube.material_override.set_shader_parameter("modelColor", color)
			interaction_cube.material_override.set_shader_parameter("emissionColor", color)
			interaction_cube.material_override.set_shader_parameter("emission_strength", 1.0)

func _trigger_click() -> void:
	clicked.emit()
	
	# Trigger click haptic
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.8, 0.1, 0)
		
	if interaction_cube:
		var tween = create_tween()
		# Pulse effect
		tween.tween_property(interaction_cube, "scale", _original_scale * 0.8, 0.05)
		tween.tween_property(interaction_cube, "scale", _original_scale * 1.2, 0.05)
		tween.tween_property(interaction_cube, "scale", _original_scale, 0.05)
	
	# Reset progress
	if progress_indicator:
		progress_indicator.visible = false
		if progress_indicator.material_override:
			progress_indicator.material_override.set_shader_parameter("progress", 0.0)

func set_text(new_text: String) -> void:
	text = new_text
	if label:
		label.text = text
