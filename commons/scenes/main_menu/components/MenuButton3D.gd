extends StaticBody3D

signal clicked

@export var text: String = "Button"
@export var color: Color = Color("ff00ff") # Ada Research Pink
@export var hover_time_required: float = 1.5

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
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
	
	if mesh_instance:
		_original_scale = mesh_instance.scale
		var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("modelColor", color)
		material.set_shader_parameter("wireframeColor", color)
		material.set_shader_parameter("emissionColor", color)
		material.set_shader_parameter("width", 2.0) # Slightly thicker edges
		material.set_shader_parameter("modelOpacity", 0.3) # Transparent
		material.set_shader_parameter("wireframeOpacity", 0.8)
		material.set_shader_parameter("emission_strength", 3.0) # Strong glow
		mesh_instance.material_override = material
		
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
	# We use get_node("/root/SoundBank") to access the singleton safely if it exists
	if has_node("/root/SoundBank"):
		var sound_bank = get_node("/root/SoundBank")
		if sound_bank.has_method("get_sound"):
			_hover_sound = sound_bank.get_sound("SyntheticSoundGenerator.detection_sound")
			_click_sound = sound_bank.get_sound("SyntheticSoundGenerator.lift_start_sound")

func _process(delta: float) -> void:
	if _is_hovering:
		_hover_timer += delta
		
		# Update progress shader
		if progress_indicator:
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
	
	# Play hover sound - REMOVED per user request
	# if _audio_player and _hover_sound:
	# 	_audio_player.stream = _hover_sound
	# 	_audio_player.pitch_scale = 1.2
	# 	_audio_player.play()
		
	# Trigger hover haptic
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.2, 0.05, 0)
	
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", _original_scale * 1.1, 0.1)
		if mesh_instance.material_override:
			# ShaderMaterial update
			mesh_instance.material_override.set_shader_parameter("modelColor", Color.BLACK)
			mesh_instance.material_override.set_shader_parameter("emissionColor", Color.BLACK)
			mesh_instance.material_override.set_shader_parameter("emission_strength", 5.0) # Boost emission for wireframe contrast if needed, or 0 if black

func pointer_exited() -> void:
	_is_hovering = false
	_hover_timer = 0.0
	
	if progress_indicator:
		progress_indicator.visible = false
		if progress_indicator.material_override:
			progress_indicator.material_override.set_shader_parameter("progress", 0.0)
	
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", _original_scale, 0.1)
		if mesh_instance.material_override:
			# ShaderMaterial reset
			mesh_instance.material_override.set_shader_parameter("modelColor", color)
			mesh_instance.material_override.set_shader_parameter("emissionColor", color)
			mesh_instance.material_override.set_shader_parameter("emission_strength", 3.0) # Reset emission strength to 3.0

func _trigger_click() -> void:
	clicked.emit()
	
	# Play click sound - REMOVED per user request
	# if _audio_player and _click_sound:
	# 	_audio_player.stream = _click_sound
	# 	_audio_player.pitch_scale = 1.0
	# 	_audio_player.play()
		
	# Trigger click haptic
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.8, 0.1, 0)
		
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", _original_scale * 0.9, 0.05)
		tween.tween_property(mesh_instance, "scale", _original_scale * 1.1, 0.05)
	
	# Reset progress
	if progress_indicator:
		progress_indicator.visible = false
		if progress_indicator.material_override:
			progress_indicator.material_override.set_shader_parameter("progress", 0.0)

func set_text(new_text: String) -> void:
	text = new_text
	if label:
		label.text = text
