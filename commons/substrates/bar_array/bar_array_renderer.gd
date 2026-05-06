extends Node3D
class_name BarArrayRenderer

## MultiMesh renderer for BarArray substrate.
## Each bar = one MultiMesh instance (BoxMesh).
## Per-instance: position, scale (Y=height), color, emission via INSTANCE_CUSTOM.

const BAR_BASE_WIDTH: float = 0.035
const BAR_DEPTH: float = 0.025
const MAX_BAR_HEIGHT: float = 0.3
const MIN_BAR_HEIGHT: float = 0.005
const LERP_SPEED: float = 8.0
const FLASH_DECAY: float = 4.0

var _multimesh: MultiMesh
var _multimesh_instance: MultiMeshInstance3D
var _bar_count: int = 0
var _world_width: float = 0.0
var _bar_spacing: float = 0.0

# Current visual state (for smooth interpolation)
var _current_heights: PackedFloat32Array
var _target_heights: PackedFloat32Array
var _current_colors: PackedColorArray
var _target_colors: PackedColorArray
var _flash_energy: PackedFloat32Array  # per-bar emission boost from events


func setup(count: int) -> void:
	_bar_count = count

	# Calculate spacing — bars fill the width with small gaps
	var gap_fraction = 0.15
	_bar_spacing = BAR_BASE_WIDTH * (1.0 + gap_fraction)
	_world_width = count * _bar_spacing

	# Initialize arrays
	_current_heights = PackedFloat32Array()
	_current_heights.resize(count)
	_target_heights = PackedFloat32Array()
	_target_heights.resize(count)
	_current_colors = PackedColorArray()
	_current_colors.resize(count)
	_target_colors = PackedColorArray()
	_target_colors.resize(count)
	_flash_energy = PackedFloat32Array()
	_flash_energy.resize(count)

	for i in range(count):
		_current_heights[i] = MIN_BAR_HEIGHT
		_target_heights[i] = MIN_BAR_HEIGHT
		_current_colors[i] = Color(0.1, 0.5, 1.0)
		_target_colors[i] = Color(0.1, 0.5, 1.0)
		_flash_energy[i] = 0.0

	# Remove old multimesh if any
	if _multimesh_instance:
		_multimesh_instance.queue_free()
		_multimesh_instance = null

	# Create MultiMesh
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true
	_multimesh.instance_count = count

	var box = BoxMesh.new()
	box.size = Vector3(BAR_BASE_WIDTH, 1.0, BAR_DEPTH)  # Y=1 base, scaled per-instance
	_multimesh.mesh = box

	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "BarMultiMesh"
	_multimesh_instance.multimesh = _multimesh

	# Shader for per-instance emission
	var mat = ShaderMaterial.new()
	mat.shader = preload("res://commons/substrates/bar_array/bar_array_cell.gdshader")
	_multimesh_instance.material_override = mat

	add_child(_multimesh_instance)

	_apply_transforms()


func update_bars(arr: PackedFloat32Array, cartridge: BarArrayCartridge, step_result: Dictionary = {}) -> void:
	if arr.size() != _bar_count:
		return

	for i in range(_bar_count):
		_target_heights[i] = MIN_BAR_HEIGHT + arr[i] * MAX_BAR_HEIGHT
		_target_colors[i] = cartridge.get_bar_color(i, arr[i], _bar_count)

	# Apply comparison highlights (yellow)
	if step_result.has("comparisons"):
		for pair in step_result["comparisons"]:
			if pair.size() >= 2:
				var a = int(pair[0])
				var b = int(pair[1])
				if a >= 0 and a < _bar_count:
					_target_colors[a] = Color(1.0, 1.0, 0.2)
				if b >= 0 and b < _bar_count:
					_target_colors[b] = Color(1.0, 1.0, 0.2)

	# Apply swap flashes (white burst)
	if step_result.has("swaps"):
		for pair in step_result["swaps"]:
			if pair.size() >= 2:
				var a = int(pair[0])
				var b = int(pair[1])
				if a >= 0 and a < _bar_count:
					_flash_energy[a] = 1.5
				if b >= 0 and b < _bar_count:
					_flash_energy[b] = 1.5

	# Apply custom highlights (arbitrary colors)
	if step_result.has("highlights"):
		for idx in step_result["highlights"]:
			var i = int(idx)
			if i >= 0 and i < _bar_count:
				_target_colors[i] = step_result["highlights"][idx]


func interpolate(delta: float) -> void:
	var changed = false
	for i in range(_bar_count):
		# Interpolate height
		var h = lerpf(_current_heights[i], _target_heights[i], LERP_SPEED * delta)
		if absf(h - _current_heights[i]) > 0.0001:
			_current_heights[i] = h
			changed = true

		# Interpolate color
		var c = _current_colors[i].lerp(_target_colors[i], LERP_SPEED * delta)
		if c != _current_colors[i]:
			_current_colors[i] = c
			changed = true

		# Decay flash
		if _flash_energy[i] > 0.0:
			_flash_energy[i] = maxf(0.0, _flash_energy[i] - FLASH_DECAY * delta)
			changed = true

	if changed:
		_apply_transforms()


func _apply_transforms() -> void:
	if not _multimesh:
		return

	var x_start = -_world_width * 0.5

	for i in range(_bar_count):
		var h = _current_heights[i]
		var x = x_start + (i + 0.5) * _bar_spacing

		# Bar grows upward from y=0: position at h/2, scale Y by h
		var t = Transform3D()
		t = t.scaled(Vector3(1.0, h, 1.0))
		t.origin = Vector3(x, h * 0.5, 0.0)
		_multimesh.set_instance_transform(i, t)

		# Color
		_multimesh.set_instance_color(i, _current_colors[i])

		# Custom data: emission in .r
		var base_emission = 0.3
		var total_emission = base_emission + _flash_energy[i]
		_multimesh.set_instance_custom_data(i, Color(total_emission, 0.0, 0.0, 0.0))


func get_world_size() -> Vector2:
	return Vector2(_world_width, MAX_BAR_HEIGHT)


func world_to_bar_index(local_pos: Vector3) -> int:
	var x_start = -_world_width * 0.5
	var idx = int((local_pos.x - x_start) / _bar_spacing)
	if idx >= 0 and idx < _bar_count:
		return idx
	return -1
