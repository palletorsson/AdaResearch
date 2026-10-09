# VRRackControl.gd
# Generic VR wrapper for non-physical RackControlBase 2D controls.
# Creates: chassis box + SubViewport with 2D control + screen quad.
# Pattern matches VRSimpleWaveform.tscn but is fully procedural.

extends Node3D
class_name VRRackControl

## Which RackControlBase scene to embed
@export var control_scene_path: String = ""

## Viewport resolution (higher = sharper, heavier)
@export var viewport_resolution: Vector2i = Vector2i(256, 512)

## Physical size in meters (auto-calculated from tokens if zero)
@export var physical_size: Vector2 = Vector2.ZERO

## Bezel depth
const BEZEL_DEPTH := 0.02
const SCREEN_OFFSET := 0.011

## Meter level property — UVAC checks "level" in control before assigning
var level: float = 0.0:
	set(val):
		level = val
		if _control_instance and "level" in _control_instance:
			_control_instance.level = val

var _viewport: SubViewport
var _screen_mesh: MeshInstance3D
var _control_instance: Control
var _pending_style_variant: String = ""
var _pending_step_count: int = 0


func _ready() -> void:
	_build()


func _build() -> void:
	if control_scene_path.is_empty():
		return

	var scene := load(control_scene_path) as PackedScene
	if not scene:
		push_warning("VRRackControl: cannot load %s" % control_scene_path)
		return

	_control_instance = scene.instantiate() as Control
	if not _control_instance:
		push_warning("VRRackControl: %s root is not a Control" % control_scene_path)
		return

	_apply_pending_properties()

	# Determine sizes
	var px_size := _control_instance.custom_minimum_size
	if px_size == Vector2.ZERO:
		px_size = Vector2(80, 80)

	if physical_size == Vector2.ZERO:
		physical_size = px_size / RackDesignTokens.get_layout("pixels_per_meter", 1000.0)

	# Viewport resolution proportional to pixel size
	if viewport_resolution == Vector2i(256, 512):
		viewport_resolution = Vector2i(int(px_size.x * 2), int(px_size.y * 2))

	# Chassis (bezel box)
	var chassis := MeshInstance3D.new()
	chassis.name = "Chassis"
	var chassis_mesh := BoxMesh.new()
	chassis_mesh.size = Vector3(physical_size.x, physical_size.y, BEZEL_DEPTH)
	chassis.mesh = chassis_mesh
	var bezel_mat := StandardMaterial3D.new()
	bezel_mat.albedo_color = RackDesignTokens.get_color("screen_bezel")
	chassis.material_override = bezel_mat
	add_child(chassis)

	# SubViewport
	_viewport = SubViewport.new()
	_viewport.name = "ControlViewport"
	_viewport.disable_3d = true
	_viewport.size = viewport_resolution
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS

	# 2D control inside viewport (fills it)
	_control_instance.anchors_preset = Control.PRESET_FULL_RECT
	_control_instance.anchor_right = 1.0
	_control_instance.anchor_bottom = 1.0
	_control_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_control_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewport.add_child(_control_instance)
	add_child(_viewport)

	# Screen quad (displays viewport texture)
	_screen_mesh = MeshInstance3D.new()
	_screen_mesh.name = "ScreenMesh"
	var quad := QuadMesh.new()
	quad.size = Vector2(physical_size.x * 0.92, physical_size.y * 0.92)
	_screen_mesh.mesh = quad
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_texture = _viewport.get_texture()
	screen_mat.emission_enabled = true
	screen_mat.emission_texture = _viewport.get_texture()
	screen_mat.emission_energy_multiplier = RackDesignTokens.get_emission("subtle")
	_screen_mesh.material_override = screen_mat
	_screen_mesh.position.z = SCREEN_OFFSET
	add_child(_screen_mesh)


## Access the inner 2D control for property changes
func get_control() -> Control:
	return _control_instance


## Convenience: set label on the inner control
func set_param_name(text: String) -> void:
	if _control_instance and _control_instance.has_method("set_control_label"):
		_control_instance.set("control_label", text)
	elif _control_instance and "control_label" in _control_instance:
		_control_instance.control_label = text


## Convenience: set normalized value
func set_normalized_value(val: float) -> void:
	if _control_instance and "normalized_value" in _control_instance:
		_control_instance.normalized_value = val


func set_style_variant(value: String) -> void:
	_pending_style_variant = value
	if _control_instance and "style_variant" in _control_instance:
		_control_instance.style_variant = value


func set_step_count(value: int) -> void:
	_pending_step_count = maxi(value, 0)
	if not _control_instance:
		return
	if "step_count" in _control_instance:
		_control_instance.step_count = _pending_step_count
	elif "steps" in _control_instance:
		_control_instance.steps = _pending_step_count


## Convenience: get normalized value
func get_normalized_value() -> float:
	if _control_instance and "normalized_value" in _control_instance:
		return _control_instance.normalized_value
	return 0.0


## For meters: set level (delegates to property setter)
func set_level(val: float) -> void:
	level = val


## For labels: set text directly
func set_text(text: String) -> void:
	if _control_instance and "text" in _control_instance:
		_control_instance.text = text


## For labels: set subtitle
func set_subtitle(text: String) -> void:
	if _control_instance and "subtitle" in _control_instance:
		_control_instance.subtitle = text


## For groups: set group title
func set_group_title(text: String) -> void:
	if _control_instance and "group_title" in _control_instance:
		_control_instance.group_title = text


func _apply_pending_properties() -> void:
	if not _control_instance:
		return
	if not _pending_style_variant.is_empty() and "style_variant" in _control_instance:
		_control_instance.style_variant = _pending_style_variant
	if _pending_step_count > 0:
		if "step_count" in _control_instance:
			_control_instance.step_count = _pending_step_count
		elif "steps" in _control_instance:
			_control_instance.steps = _pending_step_count
