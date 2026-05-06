extends StaticBody3D

signal triggered(sound_id: String)

@export var sound_id: String = "SyntheticSoundGenerator.detection_sound"
@export var text: String = "Sound"
@export var color: Color = Color("ff00ff")
@export var hover_time_required: float = 0.2 # Fast trigger for jamming

@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var label: Label3D = $Label3D
@onready var progress_indicator: MeshInstance3D = $ProgressIndicator

var _original_scale: Vector3
var _is_hovering: bool = false
var _hover_timer: float = 0.0
var _current_controller: XRController3D

func _ready() -> void:
	_update_visuals()

func setup(p_sound_id: String, p_text: String, p_color: Color) -> void:
	sound_id = p_sound_id
	text = p_text
	color = p_color
	_update_visuals()

func _update_visuals() -> void:
	if label:
		label.text = text
	
	if mesh_instance:
		_original_scale = mesh_instance.get_parent().scale if mesh_instance.get_parent() is Node3D else Vector3.ONE
		# In many cases the script is on the StaticBody3D, and mesh_instance is a child.
		# But let's use the local scale of the mesh_instance if it's not setup yet.
		if _original_scale == Vector3.ONE:
			_original_scale = mesh_instance.scale

		var shader = load("res://commons/resourses/shaders/SimpleGrid.gdshader")
		var material = ShaderMaterial.new()
		material.shader = shader
		material.set_shader_parameter("modelColor", color)
		material.set_shader_parameter("wireframeColor", color)
		material.set_shader_parameter("emissionColor", color)
		material.set_shader_parameter("width", 2.0)
		material.set_shader_parameter("modelOpacity", 0.8)
		material.set_shader_parameter("wireframeOpacity", 1.0)
		mesh_instance.material_override = material
		
	if progress_indicator:
		progress_indicator.visible = false
		if progress_indicator.get_active_material(0):
			progress_indicator.set_surface_override_material(0, progress_indicator.get_active_material(0).duplicate())
		elif progress_indicator.material_override:
			progress_indicator.material_override = progress_indicator.material_override.duplicate()
			
		if progress_indicator.material_override:
			progress_indicator.material_override.set_shader_parameter("progress", 0.0)
			progress_indicator.material_override.set_shader_parameter("color", Color(1, 0, 1, 0.5))

func _process(delta: float) -> void:
	if _is_hovering:
		_hover_timer += delta
		
		if progress_indicator:
			progress_indicator.visible = true
			if progress_indicator.material_override:
				var progress = clamp(_hover_timer / hover_time_required, 0.0, 1.0)
				progress_indicator.material_override.set_shader_parameter("progress", progress)
		
		if _hover_timer >= hover_time_required:
			_trigger_sound()
			_is_hovering = false
			_hover_timer = 0.0

func pointer_event(event: XRToolsPointerEvent) -> void:
	if event.pointer and event.pointer.get_parent() is XRController3D:
		_current_controller = event.pointer.get_parent()
	
	match event.event_type:
		XRToolsPointerEvent.Type.ENTERED:
			pointer_entered()
		XRToolsPointerEvent.Type.EXITED:
			pointer_exited()
			_current_controller = null

func pointer_entered() -> void:
	_is_hovering = true
	_hover_timer = 0.0
	
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.1, 0.05, 0)
	
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", _original_scale * 1.1, 0.05)
		if mesh_instance.material_override:
			mesh_instance.material_override.set_shader_parameter("modelColor", Color.BLACK)
			mesh_instance.material_override.set_shader_parameter("emissionColor", Color.BLACK)
			mesh_instance.material_override.set_shader_parameter("emission_strength", 5.0)

func pointer_exited() -> void:
	_is_hovering = false
	_hover_timer = 0.0
	
	if progress_indicator:
		progress_indicator.visible = false
		if progress_indicator.material_override:
			progress_indicator.material_override.set_shader_parameter("progress", 0.0)
	
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", _original_scale, 0.05)
		if mesh_instance.material_override:
			mesh_instance.material_override.set_shader_parameter("modelColor", color)
			mesh_instance.material_override.set_shader_parameter("emissionColor", color)
			mesh_instance.material_override.set_shader_parameter("emission_strength", 2.0)

func _trigger_sound() -> void:
	triggered.emit(sound_id)
	
	if _current_controller:
		_current_controller.trigger_haptic_pulse("haptic", 100.0, 0.5, 0.1, 0)
		
	if mesh_instance:
		var tween = create_tween()
		tween.tween_property(mesh_instance, "scale", _original_scale * 0.9, 0.05)
		tween.tween_property(mesh_instance, "scale", _original_scale * 1.1, 0.05)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
