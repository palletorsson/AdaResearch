class_name Grid2DRenderer
extends Node3D

## Renders a 2D grid as MultiMesh instances with per-cell color and emission.
## Petri dish variant: rounded cubes on a dark glass base.

## --- Configuration ---

@export var cell_mesh_size: float = 0.038  ## Cell cube side length (meters)
@export var cell_height: float = 0.008     ## Cell cube thickness
@export var cell_gap: float = 0.002        ## Gap between cells
@export var cell_bevel: float = 0.001      ## Corner bevel (via subdivisions)

## --- Internal ---

var _multimesh_instance: MultiMeshInstance3D
var _multimesh: MultiMesh
var _shader_material: ShaderMaterial
var _width: int = 0
var _height: int = 0
var _cell_stride: float = 0.0

## Color/emission cache for smooth transitions
var _target_colors: PackedColorArray
var _current_colors: PackedColorArray
var _target_emissions: PackedFloat32Array
var _current_emissions: PackedFloat32Array
var _cell_ages: PackedFloat32Array

## Transition speed
const COLOR_LERP_SPEED: float = 8.0
const EMISSION_LERP_SPEED: float = 10.0
const BIRTH_FLASH_ENERGY: float = 1.5
const ALIVE_ENERGY: float = 0.8
const DEATH_FADE_SPEED: float = 4.0
const AGE_SPEED: float = 0.5


func setup(width: int, height: int) -> void:
	_width = width
	_height = height
	_cell_stride = cell_mesh_size + cell_gap
	var total = width * height

	# Create MultiMesh
	_multimesh = MultiMesh.new()
	_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_multimesh.use_colors = true
	_multimesh.use_custom_data = true

	# Rounded cube mesh — BoxMesh with subdivision for soft edges
	var box = BoxMesh.new()
	box.size = Vector3(cell_mesh_size, cell_height, cell_mesh_size)
	box.subdivide_depth = 1
	box.subdivide_height = 0
	box.subdivide_width = 1
	_multimesh.mesh = box

	_multimesh.instance_count = total

	# Load cell shader
	var shader = load("res://commons/substrates/grid2d/grid2d_cell.gdshader") as Shader
	_shader_material = ShaderMaterial.new()
	_shader_material.shader = shader

	# Create MultiMeshInstance3D
	if _multimesh_instance:
		_multimesh_instance.queue_free()
	_multimesh_instance = MultiMeshInstance3D.new()
	_multimesh_instance.name = "CellMultiMesh"
	_multimesh_instance.multimesh = _multimesh
	_multimesh_instance.material_override = _shader_material
	_multimesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_multimesh_instance)

	# Initialize caches
	_target_colors = PackedColorArray()
	_target_colors.resize(total)
	_current_colors = PackedColorArray()
	_current_colors.resize(total)
	_target_emissions = PackedFloat32Array()
	_target_emissions.resize(total)
	_current_emissions = PackedFloat32Array()
	_current_emissions.resize(total)
	_cell_ages = PackedFloat32Array()
	_cell_ages.resize(total)

	var dead_color = Color(0.03, 0.03, 0.04)

	# Position all instances
	var offset_x = (_width - 1) * _cell_stride * 0.5
	var offset_z = (_height - 1) * _cell_stride * 0.5

	for i in range(total):
		var x = i % _width
		var y = i / _width
		var t = Transform3D()
		t.origin = Vector3(
			x * _cell_stride - offset_x,
			cell_height * 0.5,
			y * _cell_stride - offset_z
		)
		_multimesh.set_instance_transform(i, t)
		_multimesh.set_instance_color(i, dead_color)
		_multimesh.set_instance_custom_data(i, Color(0.0, 0.0, 0.0, 0.0))

		_target_colors[i] = dead_color
		_current_colors[i] = dead_color
		_target_emissions[i] = 0.0
		_current_emissions[i] = 0.0
		_cell_ages[i] = 0.0


## Push new grid state from cartridge. Triggers smooth transitions.
func update_grid(grid: PackedInt32Array, cartridge: Grid2DCartridge, prev_grid: PackedInt32Array) -> void:
	var total = _width * _height
	for i in range(total):
		var state = grid[i]
		var prev_state = prev_grid[i] if prev_grid.size() > 0 else 0

		var new_color = cartridge.get_state_color(state)
		var new_emission = cartridge.get_state_emission(state)

		_target_colors[i] = new_color
		_target_emissions[i] = new_emission

		# Birth flash — cell was dead, now alive
		if prev_state == 0 and state != 0:
			_current_emissions[i] = BIRTH_FLASH_ENERGY
			_cell_ages[i] = 0.0

		# Death — reset age
		if state == 0:
			_cell_ages[i] = 0.0


## Smooth interpolation — call every frame.
func interpolate(delta: float) -> void:
	if not _multimesh:
		return

	var total = _width * _height
	for i in range(total):
		# Lerp color
		_current_colors[i] = _current_colors[i].lerp(_target_colors[i], clamp(COLOR_LERP_SPEED * delta, 0.0, 1.0))

		# Lerp emission
		var target_e = _target_emissions[i]
		var current_e = _current_emissions[i]
		if current_e > target_e:
			# Decaying (birth flash fading, or death)
			_current_emissions[i] = move_toward(current_e, target_e, DEATH_FADE_SPEED * delta)
		else:
			_current_emissions[i] = move_toward(current_e, target_e, EMISSION_LERP_SPEED * delta)

		# Age living cells
		if _target_emissions[i] > 0.0:
			_cell_ages[i] += AGE_SPEED * delta

		# Push to MultiMesh
		_multimesh.set_instance_color(i, _current_colors[i])
		_multimesh.set_instance_custom_data(i, Color(
			_current_emissions[i],  # .r = emission
			_cell_ages[i],          # .g = age
			0.0,                    # .b = spare
			0.0                     # .a = spare
		))


## Get grid size in world units.
func get_world_size() -> Vector2:
	return Vector2(_width * _cell_stride, _height * _cell_stride)


## Convert world position (local to renderer) to grid coords. Returns Vector2i(-1,-1) if out of bounds.
func world_to_grid(local_pos: Vector3) -> Vector2i:
	var offset_x = (_width - 1) * _cell_stride * 0.5
	var offset_z = (_height - 1) * _cell_stride * 0.5

	var gx = roundi((local_pos.x + offset_x) / _cell_stride)
	var gy = roundi((local_pos.z + offset_z) / _cell_stride)

	if gx < 0 or gx >= _width or gy < 0 or gy >= _height:
		return Vector2i(-1, -1)
	return Vector2i(gx, gy)
