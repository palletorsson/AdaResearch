# ============================================================================
# Convolutional Neural Networks (CNN) Visualization
# Interactive 3D visualization of CNN architecture: input grid, sliding kernel,
# convolution feature maps, max-pooling, dense layer, and data ribbon.
# Uses MultiMesh for efficient rendering of large grids.
# ============================================================================
extends Node3D
class_name ConvolutionalNeuralNetworkShowcase

# --- Network Architecture Controls ---
@export_category("Network Architecture")
@export_range(6, 16, 1) var grid_size: int = 8
@export_range(3, 5, 1) var kernel_size: int = 3
@export_range(2, 4, 1) var pooling_window: int = 2
@export_range(1, 4, 1) var feature_map_count: int = 3

# --- Animation & Visual Controls ---
@export_category("Animation")
@export var animation_speed: float = 0.65
@export var voxel_spacing: float = 0.42
@export var height_scale: float = 0.9
@export var dense_count: int = 6
@export var ribbon_particle_count: int = 24

@onready var _input_root: Node3D = $InputPlane
@onready var _feature_root: Node3D = $FeatureStage
@onready var _pool_root: Node3D = $PoolStage
@onready var _dense_root: Node3D = $DenseStage
@onready var _ribbon_root: Node3D = $RibbonHolder
@onready var _annotation_root: Node3D = $AnnotationBoard

var _time: float = 0.0
var _input_values: PackedFloat32Array
var _input_transforms: Array[Transform3D]
var _input_colors: Array[Color]
var _highlighted: Array[int] = []
var _input_multimesh: MultiMesh
var _kernel_window: MeshInstance3D

var _conv_output_size: int
var _feature_multimeshes: Array[MultiMesh] = []
var _feature_base: Array = []  # Array[Array[Transform3D]] - nested types not supported
var _feature_values: Array[PackedFloat32Array] = []
var _feature_targets: Array[PackedFloat32Array] = []
var _feature_weights: Array[PackedFloat32Array] = []
var _feature_biases: PackedFloat32Array

var _pool_columns: Array[MeshInstance3D] = []
var _dense_orbs: Array[MeshInstance3D] = []
var _dense_weights: Array[PackedFloat32Array] = []
var _dense_biases: PackedFloat32Array

var _curve := Curve3D.new()
var _curve_length: float = 1.0

class RibbonParticle:
	var mesh: MeshInstance3D
	var speed: float
	var offset: float

var _ribbon_particles: Array[RibbonParticle] = []
var _stats_label: Label3D

func _ready() -> void:
	_conv_output_size = grid_size - kernel_size + 1
	_build_input_grid()
	_build_kernel_window()
	_build_feature_maps()
	_build_pool_stage()
	_build_dense_stage()
	_build_ribbon()
	_build_annotations()
	_build_stats_label()

func _process(delta: float) -> void:
	_time += delta * animation_speed
	_update_kernel_path()
	_update_feature_targets()
	_update_feature_maps(delta)
	_update_pool_stage(delta)
	_update_dense_stage(delta)
	_update_ribbon(delta)
	_update_stats_label()

# ============================================================================
# Build Stage — Construct all visual elements
# ============================================================================

func _build_input_grid() -> void:
	var count := grid_size * grid_size
	_input_values = PackedFloat32Array()
	_input_values.resize(count)
	_input_transforms.clear()
	_input_colors.clear()
	_input_transforms.resize(count)
	_input_colors.resize(count)

	var mesh := BoxMesh.new()
	mesh.size = Vector3(voxel_spacing * 0.85, 0.06, voxel_spacing * 0.85)

	_input_multimesh = MultiMesh.new()
	_input_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	_input_multimesh.use_colors = true
	_input_multimesh.instance_count = count

	var index := 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for z in range(grid_size):
		for x in range(grid_size):
			var value := rng.randf_range(0.15, 1.0) * (0.6 + 0.4 * sin(float(x + z) * 0.7))
			_input_values[index] = value
			var offset := Vector3(float(x) - (grid_size - 1) * 0.5, 0.0, float(z) - (grid_size - 1) * 0.5) * voxel_spacing
			var transform := Transform3D(Basis.IDENTITY, offset)
			_input_transforms[index] = transform
			_input_multimesh.set_instance_transform(index, transform)
			var base_color := Color(0.12 + value * 0.45, 0.18 + value * 0.22, 0.32 + value * 0.35, 1.0)
			_input_colors[index] = base_color
			_input_multimesh.set_instance_color(index, base_color)
			index += 1

	_input_multimesh.mesh = mesh
	
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = _input_multimesh
	_input_root.add_child(instance, true)

func _build_kernel_window() -> void:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(kernel_size * voxel_spacing, kernel_size * voxel_spacing)
	_kernel_window = MeshInstance3D.new()
	_kernel_window.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.9, 0.7, 0.2, 0.25)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.6)
	mat.emission_energy_multiplier = 1.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_kernel_window.material_override = mat
	_kernel_window.rotation_degrees.x = -90
	_input_root.add_child(_kernel_window, true)

func _build_feature_maps() -> void:
	_feature_weights.clear()
	_feature_biases = PackedFloat32Array()
	_feature_biases.resize(feature_map_count)
	for map_idx in range(feature_map_count):
		var weights := PackedFloat32Array()
		weights.resize(kernel_size * kernel_size)
		var rng := RandomNumberGenerator.new()
		rng.seed = 1337 + map_idx * 37
		for i in range(weights.size()):
			weights[i] = rng.randf_range(-1.0, 1.0)
		_feature_weights.append(weights)
		_feature_biases[map_idx] = rng.randf_range(-0.25, 0.25)

	_feature_multimeshes.clear()
	_feature_base.clear()
	_feature_values.clear()
	_feature_targets.clear()

	for map_idx in range(feature_map_count):
		var mesh := BoxMesh.new()
		mesh.size = Vector3(voxel_spacing * 0.7, 0.08, voxel_spacing * 0.7)
		var count := _conv_output_size * _conv_output_size
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.instance_count = count

		var bases: Array[Transform3D] = []
		var values := PackedFloat32Array()
		var targets := PackedFloat32Array()
		values.resize(count)
		targets.resize(count)

		var offset_x := float(map_idx - (feature_map_count - 1) * 0.5) * voxel_spacing * 1.4
		var index := 0
		for z in range(_conv_output_size):
			for x in range(_conv_output_size):
				var local := Vector3(float(x) - (_conv_output_size - 1) * 0.5, 0.0, float(z) - (_conv_output_size - 1) * 0.5) * (voxel_spacing * 0.85)
				local.x += offset_x
				var transform := Transform3D(Basis.IDENTITY, local)
				bases.append(transform)
				multimesh.set_instance_transform(index, transform)
				multimesh.set_instance_color(index, Color(0.18, 0.42 + 0.2 * map_idx, 0.58, 1.0))
				values[index] = 0.0
				targets[index] = 0.0
				index += 1

		var instance := MultiMeshInstance3D.new()
		instance.mesh = mesh
		instance.multimesh = multimesh
		_feature_root.add_child(instance, true)
		_feature_multimeshes.append(multimesh)
		_feature_base.append(bases)
		_feature_values.append(values)
		_feature_targets.append(targets)

func _build_pool_stage() -> void:
	_pool_columns.clear()
	var pool_mesh := CylinderMesh.new()
	pool_mesh.top_radius = 0.26
	pool_mesh.bottom_radius = 0.26
	pool_mesh.height = 0.2
	var pool_size: int = max(1, _conv_output_size / pooling_window)
	var spacing := voxel_spacing * pooling_window * 0.75
	for z in range(pool_size):
		for x in range(pool_size):
			var column := MeshInstance3D.new()
			column.mesh = pool_mesh
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color(0.4, 0.2 + 0.15 * z, 0.72, 1.0)
			mat.emission_enabled = true
			mat.emission = mat.albedo_color * 0.6
			column.material_override = mat
			var pos := Vector3(float(x) - (pool_size - 1) * 0.5, 0.0, float(z) - (pool_size - 1) * 0.5) * spacing
			column.position = pos
			column.scale = Vector3(1, 0.1, 1)
			_pool_root.add_child(column, true)
			_pool_columns.append(column)

func _build_dense_stage() -> void:
	_dense_orbs.clear()
	_dense_weights.clear()
	var orb_mesh := SphereMesh.new()
	orb_mesh.radius = 0.32
	orb_mesh.height = 0.64
	_dense_biases = PackedFloat32Array()
	_dense_biases.resize(dense_count)

	var rng := RandomNumberGenerator.new()
	rng.seed = 9001
	for i in range(dense_count):
		var orb := MeshInstance3D.new()
		orb.mesh = orb_mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.88, 0.36 + 0.04 * i, 0.26 + 0.05 * i, 1.0)
		mat.emission_enabled = true
		mat.emission = mat.albedo_color * 0.8
		orb.material_override = mat
		var angle: float = lerp(-0.9, 0.9, float(i) / max(1, dense_count - 1))
		var radius := 2.2
		orb.position = Vector3(cos(angle) * radius, (float(i) - (dense_count - 1) * 0.5) * 0.4, sin(angle) * radius * 0.5)
		orb.scale = Vector3.ONE * 0.7
		_dense_root.add_child(orb, true)
		_dense_orbs.append(orb)

		var weights := PackedFloat32Array()
		weights.resize(max(1, _pool_columns.size()))
		for w in range(weights.size()):
			weights[w] = rng.randf_range(-1.0, 1.0)
		_dense_weights.append(weights)
		_dense_biases[i] = rng.randf_range(-0.2, 0.2)

func _build_ribbon() -> void:
	_curve.clear_points()
	_curve.add_point(Vector3(-5.5, 0.3, 0.0))
	_curve.add_point(Vector3(-3.2, 0.9, 0.6))
	_curve.add_point(Vector3(0.2, 1.2, -0.4))
	_curve.add_point(Vector3(3.6, 0.8, -0.3))
	_curve.add_point(Vector3(8.3, 0.45, 0.0))
	_curve.bake_interval = 0.2
	_curve_length = max(0.1, _curve.get_baked_length())

	_ribbon_particles.clear()
	var particle_mesh := SphereMesh.new()
	particle_mesh.radius = 0.12
	particle_mesh.height = 0.24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.95, 0.92, 0.5, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.9, 0.6)
	mat.emission_energy_multiplier = 2.0

	for i in range(ribbon_particle_count):
		var particle := RibbonParticle.new()
		particle.mesh = MeshInstance3D.new()
		particle.mesh.mesh = particle_mesh
		particle.mesh.material_override = mat
		particle.speed = 0.25 + float(i % 5) * 0.08
		particle.offset = randf()
		_ribbon_root.add_child(particle.mesh, true)
		_ribbon_particles.append(particle)

func _build_annotations() -> void:
	_clear_children(_annotation_root)
	var entries := [
		{"label": "Input Channels", "position": Vector3(-5.5, 1.2, -1.4)},
		{"label": "Convolution Feature Stacks", "position": Vector3(-1.2, 1.4, -1.5)},
		{"label": "Pooling Basin", "position": Vector3(3.6, 1.2, -1.2)},
		{"label": "Fully Connected Spiral", "position": Vector3(8.3, 1.8, -1.0)}
	]
	for entry in entries:
		var label := Label3D.new()
		label.text = entry["label"]
		label.modulate = Color(0.95, 0.95, 1.0, 1.0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.font_size = 32
		label.position = entry["position"]
		_annotation_root.add_child(label, true)

# ============================================================================
# Update Stage — Per-frame animation and data propagation
# ============================================================================

func _update_kernel_path() -> void:
	for idx in _highlighted:
		_input_multimesh.set_instance_transform(idx, _input_transforms[idx])
		_input_multimesh.set_instance_color(idx, _input_colors[idx])
	_highlighted.clear()

	var slots := _conv_output_size * _conv_output_size
	if slots <= 0:
		return
	var travel := int(fmod(_time * float(slots), float(slots)))
	var top := travel / _conv_output_size
	var left := travel % _conv_output_size

	var center := Vector3(float(left) + kernel_size * 0.5 - (grid_size - 1) * 0.5, 0.04, float(top) + kernel_size * 0.5 - (grid_size - 1) * 0.5) * voxel_spacing
	_kernel_window.position = center

	for ky in range(kernel_size):
		for kx in range(kernel_size):
			var xi := left + kx
			var zi := top + ky
			var idx := zi * grid_size + xi
			var highlight := _input_transforms[idx]
			highlight.origin.y += 0.06
			highlight.basis = Basis.IDENTITY.scaled(Vector3(1.18, 1.0, 1.18))
			highlight.origin = _input_transforms[idx].origin + Vector3(0, 0.06, 0)
			_input_multimesh.set_instance_transform(idx, highlight)
			var color := _input_colors[idx].lightened(0.3)
			_input_multimesh.set_instance_color(idx, color)
			_highlighted.append(idx)

func _update_feature_targets() -> void:
	var slots := _conv_output_size * _conv_output_size
	if slots <= 0:
		return
	var travel := int(fmod(_time * float(slots), float(slots)))
	var top := travel / _conv_output_size
	var left := travel % _conv_output_size
	var index := top * _conv_output_size + left

	for map_idx in range(feature_map_count):
		var weights := _feature_weights[map_idx]
		var accum := 0.0
		for ky in range(kernel_size):
			for kx in range(kernel_size):
				var xi := left + kx
				var zi := top + ky
				var sample_idx := zi * grid_size + xi
				var weight := weights[ky * kernel_size + kx]
				accum += weight * _input_values[sample_idx]
		var bias := _feature_biases[map_idx]
		var activation: float = clamp(0.5 + 0.5 * tanh(accum * 0.6 + bias), 0.0, 1.0)
		_feature_targets[map_idx][index] = activation

func _update_feature_maps(delta: float) -> void:
	for map_idx in range(feature_map_count):
		var multimesh := _feature_multimeshes[map_idx]
		var bases: Array[Transform3D] = _feature_base[map_idx] as Array[Transform3D]
		var values: PackedFloat32Array = _feature_values[map_idx]
		var targets: PackedFloat32Array = _feature_targets[map_idx]
		for i in range(values.size()):
			var current := values[i]
			var target := targets[i]
			var updated: float = lerp(current, target, delta * 3.5)
			values[i] = updated
			var scale_y: float = 0.18 + updated * height_scale
			var transform: Transform3D = bases[i]
			var basis := Basis.IDENTITY.scaled(Vector3(1.0, scale_y, 1.0))
			transform.basis = basis
			transform.origin = bases[i].origin + Vector3(0, scale_y * 0.5, 0)
			multimesh.set_instance_transform(i, transform)
			var base_color := Color(0.18, 0.42 + 0.2 * map_idx, 0.58, 1.0)
			multimesh.set_instance_color(i, base_color.lightened(updated * 0.6))

func _update_pool_stage(delta: float) -> void:
	if _pool_columns.is_empty():
		return
	var pool_size := int(sqrt(float(_pool_columns.size())))
	pool_size = max(pool_size, 1)
	var source_map := 0
	var values: PackedFloat32Array = _feature_values[source_map]
	for z in range(pool_size):
		for x in range(pool_size):
			var accum := 0.0
			for ky in range(pooling_window):
				for kx in range(pooling_window):
					var in_x := x * pooling_window + kx
					var in_z := z * pooling_window + ky
					if in_x < _conv_output_size and in_z < _conv_output_size:
						var idx := in_z * _conv_output_size + in_x
						accum = max(accum, values[idx])
			var column: MeshInstance3D = _pool_columns[z * pool_size + x]
			var current_scale := column.scale
			var target_height := 0.2 + accum * 1.4
			var new_height = lerp(current_scale.y, target_height, delta * 2.4)
			column.scale = Vector3(1, new_height, 1)
			column.position.y = new_height * 0.5
			var mat: StandardMaterial3D = column.material_override as StandardMaterial3D
			if mat:
				mat.emission = mat.albedo_color * (0.4 + accum * 1.1)

func _update_dense_stage(delta: float) -> void:
	if _dense_orbs.is_empty():
		return
	var pool_values := PackedFloat32Array()
	pool_values.resize(_pool_columns.size())
	for i in range(_pool_columns.size()):
		pool_values[i] = _pool_columns[i].scale.y

	for i in range(_dense_orbs.size()):
		var activation := _dense_biases[i]
		var weights := _dense_weights[i]
		for j in range(min(weights.size(), pool_values.size())):
			activation += weights[j] * pool_values[j]
		activation = clamp(0.5 + 0.5 * tanh(activation * 0.5), 0.0, 1.0)
		var orb := _dense_orbs[i]
		var current_scale := orb.scale
		var target_scale := Vector3.ONE * (0.6 + activation * 0.5)
		orb.scale = current_scale.lerp(target_scale, delta * 3.0)
		var mat := orb.material_override
		if mat:
			mat.emission = mat.albedo_color * (0.6 + activation * 1.3)
		orb.rotate_y(delta * (0.5 + activation))

func _update_ribbon(_delta: float) -> void:
	if _ribbon_particles.is_empty():
		return
	for particle in _ribbon_particles:
		var t := fposmod(particle.offset + _time * particle.speed, 1.0)
		var distance := t * _curve_length
		var pos: Vector3 = _curve.interpolate_baked(distance)
		particle.mesh.position = pos
		var ahead: Vector3 = _curve.interpolate_baked(min(distance + 0.2, _curve_length))
		particle.mesh.look_at(ahead, Vector3.UP)
		var flicker := 0.9 + 0.2 * sin((t + _time) * TAU)
		particle.mesh.scale = Vector3.ONE * (0.1 * flicker)

# ============================================================================
# Stats Label — Live HUD showing kernel position and activation stats
# ============================================================================

func _build_stats_label() -> void:
	_stats_label = Label3D.new()
	_stats_label.text = "CNN Pipeline Active"
	_stats_label.font_size = 28
	_stats_label.outline_size = 4
	_stats_label.modulate = Color(0.95, 0.95, 1.0)
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.position = Vector3(0, 3.0, -2.5)
	add_child(_stats_label)

func _update_stats_label() -> void:
	if not _stats_label:
		return
	# Show kernel position and average pool/dense activation
	var avg_pool := 0.0
	for col in _pool_columns:
		avg_pool += col.scale.y
	if _pool_columns.size() > 0:
		avg_pool /= _pool_columns.size()
	
	var avg_dense := 0.0
	for orb in _dense_orbs:
		avg_dense += orb.scale.x
	if _dense_orbs.size() > 0:
		avg_dense /= _dense_orbs.size()
	
	_stats_label.text = "Grid: %dx%d | Kernel: %dx%d | Pool: %.2f | Dense: %.2f" % [
		grid_size, grid_size, kernel_size, kernel_size, avg_pool, avg_dense
	]

# ============================================================================
# Utility
# ============================================================================

func _clear_children(node: Node) -> void:
	for child in node.get_children():
		child.queue_free()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

