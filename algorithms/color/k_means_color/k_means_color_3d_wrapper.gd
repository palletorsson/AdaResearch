extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var sprite_3d: Sprite3D = $Sprite3D

const EXTRA_MARGIN := Vector2(32, 32)
const DEFAULT_MIN_SIZE := Vector2i(512, 512)

var _minimum_viewport_size: Vector2i
var _initial_sprite_scale: Vector3
var _baseline_sprite_extent: Vector2

func _ready() -> void:
	_minimum_viewport_size = Vector2i(
		max(sub_viewport.size.x, DEFAULT_MIN_SIZE.x),
		max(sub_viewport.size.y, DEFAULT_MIN_SIZE.y)
	)
	_initial_sprite_scale = sprite_3d.scale
	_baseline_sprite_extent = Vector2(
		float(_minimum_viewport_size.x) * _initial_sprite_scale.x,
		float(_minimum_viewport_size.y) * _initial_sprite_scale.y
	)
	sub_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	if sub_viewport.size.x < _minimum_viewport_size.x or sub_viewport.size.y < _minimum_viewport_size.y:
		sub_viewport.size = _minimum_viewport_size
	_rescale_sprite(sub_viewport.size)
	await get_tree().process_frame
	await get_tree().process_frame
	_fit_view_to_contents()

func _fit_view_to_contents() -> void:
	var control := _get_view_content()
	if control:
		if not control.is_connected("resized", Callable(self, "_on_content_resized")):
			control.connect("resized", Callable(self, "_on_content_resized"))
		var desired_size: Vector2 = (control.get_combined_minimum_size() + EXTRA_MARGIN).ceil()
		desired_size.x = max(desired_size.x, float(_minimum_viewport_size.x))
		desired_size.y = max(desired_size.y, float(_minimum_viewport_size.y))
		var new_size := Vector2i(desired_size)
		if new_size != sub_viewport.size:
			sub_viewport.size = new_size
			_rescale_sprite(new_size)

func _on_content_resized() -> void:
	_fit_view_to_contents()

func _get_view_content() -> Control:
	for child in sub_viewport.get_children():
		if child is Control:
			return child
	return null

func _rescale_sprite(new_size: Vector2i) -> void:
	if new_size.x == 0 or new_size.y == 0:
		return
	sprite_3d.scale = Vector3(
		_baseline_sprite_extent.x / float(new_size.x),
		_baseline_sprite_extent.y / float(new_size.y),
		_initial_sprite_scale.z
	)
