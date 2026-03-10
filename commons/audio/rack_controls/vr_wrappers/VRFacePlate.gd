# VRFacePlate.gd
# Face plate overlay for physical VR controls (sliders, knobs, etc.).
# Renders a 2D RackControlBase behind the 3D interactable mechanism.
# The 3D control drives the 2D visual via sync_value().

extends Node3D
class_name VRFacePlate

## Which RackControlBase scene to render as the face plate
@export var control_scene_path: String = ""

## Viewport resolution (2x pixel size for clarity)
@export var viewport_resolution: Vector2i = Vector2i(256, 512)

## Physical size in meters (auto-calculated from tokens if zero)
@export var physical_size: Vector2 = Vector2.ZERO

## How far behind the 3D mechanism the face plate sits
const FACE_PLATE_Z := -0.005

var _viewport: SubViewport
var _face_mesh: MeshInstance3D
var _control_instance: Control


func _ready() -> void:
	_build()


func _build() -> void:
	if control_scene_path.is_empty():
		return

	var scene := load(control_scene_path) as PackedScene
	if not scene:
		push_warning("VRFacePlate: cannot load %s" % control_scene_path)
		return

	_control_instance = scene.instantiate() as Control
	if not _control_instance:
		push_warning("VRFacePlate: %s root is not a Control" % control_scene_path)
		return

	# Determine sizes from the 2D control
	var px_size := _control_instance.custom_minimum_size
	if px_size == Vector2.ZERO:
		px_size = Vector2(80, 80)

	if physical_size == Vector2.ZERO:
		physical_size = px_size / RackDesignTokens.get_layout("pixels_per_meter", 1000.0)

	if viewport_resolution == Vector2i(256, 512):
		viewport_resolution = Vector2i(int(px_size.x * 2), int(px_size.y * 2))

	# SubViewport with transparency
	_viewport = SubViewport.new()
	_viewport.name = "FacePlateViewport"
	_viewport.disable_3d = true
	_viewport.size = viewport_resolution
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.transparent_bg = true

	# 2D control fills viewport
	_control_instance.anchors_preset = Control.PRESET_FULL_RECT
	_control_instance.anchor_right = 1.0
	_control_instance.anchor_bottom = 1.0
	_control_instance.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_control_instance.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_viewport.add_child(_control_instance)
	add_child(_viewport)

	# Face plate quad behind the mechanism
	_face_mesh = MeshInstance3D.new()
	_face_mesh.name = "FacePlateMesh"
	var quad := QuadMesh.new()
	quad.size = Vector2(physical_size.x, physical_size.y)
	_face_mesh.mesh = quad
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = _viewport.get_texture()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission_texture = _viewport.get_texture()
	mat.emission_energy_multiplier = RackDesignTokens.get_emission("subtle")
	_face_mesh.material_override = mat
	_face_mesh.position.z = FACE_PLATE_Z
	add_child(_face_mesh)


## Access the inner 2D control
func get_control() -> Control:
	return _control_instance


## Sync the face plate visual to match the 3D control's value
func sync_value(normalized: float) -> void:
	if _control_instance and "normalized_value" in _control_instance:
		_control_instance.normalized_value = normalized


## Sync Y axis for XY pad / joystick
func sync_value_y(normalized: float) -> void:
	if _control_instance and "normalized_value_y" in _control_instance:
		_control_instance.normalized_value_y = normalized


## Set the label on the face plate control
func set_param_name(text: String) -> void:
	if _control_instance and "control_label" in _control_instance:
		_control_instance.control_label = text
