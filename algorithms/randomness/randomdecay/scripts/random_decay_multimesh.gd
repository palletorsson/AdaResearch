extends Node3D

# Random decay demo built with MultiMesh-only stacks.
# Two standing 2D stacks are generated:
# - 1m cubes with small gutter spacing
# - 1dm prisms with smaller spacing
# Instances drift, rotate, sink, and darken over time.

@export_category("Simulation")
@export var decay_active: bool = true
@export var random_seed: int = 0
@export var decay_growth_rate: float = 0.16
@export var decay_injection_per_second: float = 0.22
@export var drift_strength: float = 0.6
@export var max_offset: float = 0.35
@export var rotation_jitter_degrees: float = 12.0
@export var sink_distance: float = 0.25
@export_range(0.1, 1.0, 0.01) var minimum_scale: float = 0.45

@export_category("Cube Stack (1m)")
@export var cube_columns: int = 5
@export var cube_rows: int = 4
@export var cube_size: Vector3 = Vector3.ONE
@export var cube_gutter: float = 0.08
@export var cube_origin: Vector3 = Vector3(-4.0, 0.0, 0.0)
@export var cube_base_color: Color = Color(0.35, 0.66, 1.0, 1.0)

@export_category("Prism Stack (1dm)")
@export var prism_columns: int = 12
@export var prism_rows: int = 10
@export var prism_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var prism_gutter: float = 0.02
@export var prism_origin: Vector3 = Vector3(3.2, 0.0, 0.0)
@export var prism_base_color: Color = Color(1.0, 0.72, 0.34, 1.0)

@export_category("Decay Color")
@export var decay_color: Color = Color(0.07, 0.07, 0.07, 0.65)

var _rng := RandomNumberGenerator.new()
var _layers: Array[Dictionary] = []

func _ready() -> void:
	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()
	_create_layers()

func _process(delta: float) -> void:
	if not decay_active:
		return
	for layer in _layers:
		_advance_layer(layer, delta)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		_reset_layers()
	elif event.is_action_pressed("ui_accept"):
		decay_active = not decay_active

func _create_layers() -> void:
	_clear_layers()
	_layers.append(_create_cube_layer())
	_layers.append(_create_prism_layer())

func _clear_layers() -> void:
	for child in get_children():
		if child is MultiMeshInstance3D and String(child.name).begins_with("DecayLayer_"):
			child.queue_free()
	_layers.clear()

func _create_cube_layer() -> Dictionary:
	var cube_mesh := BoxMesh.new()
	cube_mesh.size = cube_size
	return _create_layer(
		"DecayLayer_Cubes",
		cube_mesh,
		cube_columns,
		cube_rows,
		cube_size,
		cube_gutter,
		cube_origin,
		cube_base_color
	)

func _create_prism_layer() -> Dictionary:
	var prism_mesh := PrismMesh.new()
	prism_mesh.size = prism_size
	return _create_layer(
		"DecayLayer_Prisms",
		prism_mesh,
		prism_columns,
		prism_rows,
		prism_size,
		prism_gutter,
		prism_origin,
		prism_base_color
	)

func _create_layer(
	node_name: String,
	mesh: Mesh,
	columns: int,
	rows: int,
	element_size: Vector3,
	gutter: float,
	origin: Vector3,
	base_color: Color
) -> Dictionary:
	var safe_columns := maxi(columns, 1)
	var safe_rows := maxi(rows, 1)
	var instance_count := safe_columns * safe_rows

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.instance_count = instance_count
	multimesh.mesh = mesh

	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = _create_layer_material()
	add_child(instance)

	var base_positions: Array[Vector3] = []
	var offsets: Array[Vector3] = []
	var drift_velocities: Array[Vector3] = []
	var angles: Array[Vector3] = []
	var angular_velocities: Array[Vector3] = []
	var decay_values: Array[float] = []

	var step_x := element_size.x + gutter
	var step_y := element_size.y + gutter
	var half_width := float(safe_columns - 1) * step_x * 0.5
	var index := 0

	for row in range(safe_rows):
		for col in range(safe_columns):
			var initial_position := origin + Vector3(
				float(col) * step_x - half_width,
				element_size.y * 0.5 + float(row) * step_y,
				0.0
			)
			base_positions.append(initial_position)
			offsets.append(Vector3.ZERO)
			drift_velocities.append(Vector3.ZERO)
			angles.append(Vector3.ZERO)
			angular_velocities.append(Vector3.ZERO)
			decay_values.append(0.0)
			multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, initial_position))
			multimesh.set_instance_color(index, base_color)
			index += 1

	return {
		"multimesh": multimesh,
		"base_positions": base_positions,
		"offsets": offsets,
		"drift_velocities": drift_velocities,
		"angles": angles,
		"angular_velocities": angular_velocities,
		"decay_values": decay_values,
		"base_color": base_color,
		"injection_accumulator": 0.0
	}

func _create_layer_material() -> Material:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = Color(0.12, 0.12, 0.12, 1.0)
	material.emission_energy_multiplier = 0.6
	material.roughness = 0.62
	material.metallic = 0.0
	return material

func _advance_layer(layer: Dictionary, delta: float) -> void:
	var multimesh: MultiMesh = layer.get("multimesh")
	if multimesh == null:
		return

	var base_positions = layer.get("base_positions", [])
	var offsets = layer.get("offsets", [])
	var drift_velocities = layer.get("drift_velocities", [])
	var angles = layer.get("angles", [])
	var angular_velocities = layer.get("angular_velocities", [])
	var decay_values = layer.get("decay_values", [])
	var base_color: Color = layer.get("base_color", Color.WHITE)
	var instance_count: int = base_positions.size()
	if instance_count == 0:
		return

	var injection_accumulator: float = layer.get("injection_accumulator", 0.0)
	injection_accumulator += float(instance_count) * decay_injection_per_second * delta
	while injection_accumulator >= 1.0:
		injection_accumulator -= 1.0
		var injected_index := _rng.randi_range(0, instance_count - 1)
		decay_values[injected_index] = clampf(
			decay_values[injected_index] + _rng.randf_range(0.08, 0.24),
			0.0,
			1.0
		)
	layer["injection_accumulator"] = injection_accumulator

	var jitter_radians := deg_to_rad(rotation_jitter_degrees)
	for i in range(instance_count):
		var decay: float = float(decay_values[i])
		decay = clampf(decay + decay_growth_rate * delta * (0.2 + decay * 0.8), 0.0, 1.0)
		decay_values[i] = decay

		var drift_velocity: Vector3 = Vector3(drift_velocities[i])
		var drift_noise: Vector3 = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		) * drift_strength * (0.15 + decay * 1.35)
		drift_velocity += drift_noise * delta
		drift_velocity *= lerpf(0.96, 0.88, decay)
		drift_velocities[i] = drift_velocity

		var offset: Vector3 = Vector3(offsets[i]) + drift_velocity
		var offset_limit: float = max_offset * (0.2 + decay * 0.8)
		if offset.length() > offset_limit and offset_limit > 0.0:
			offset = offset.normalized() * offset_limit
		offsets[i] = offset

		var angular_velocity: Vector3 = Vector3(angular_velocities[i])
		var angular_noise: Vector3 = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		) * jitter_radians * (0.12 + decay * 0.9)
		angular_velocity += angular_noise * delta
		angular_velocity *= lerpf(0.965, 0.9, decay)
		angular_velocities[i] = angular_velocity

		var angle: Vector3 = Vector3(angles[i]) + angular_velocity
		angles[i] = angle

		var sink := Vector3(0.0, -sink_distance * decay, 0.0)
		var position: Vector3 = Vector3(base_positions[i]) + offset + sink
		var scale_value := lerpf(1.0, minimum_scale, decay)
		var basis := Basis.from_euler(angle).scaled(Vector3.ONE * scale_value)

		multimesh.set_instance_transform(i, Transform3D(basis, position))
		multimesh.set_instance_color(i, base_color.lerp(decay_color, decay))

func _reset_layers() -> void:
	for layer in _layers:
		var multimesh: MultiMesh = layer.get("multimesh")
		if multimesh == null:
			continue

		var base_positions = layer.get("base_positions", [])
		var offsets = layer.get("offsets", [])
		var drift_velocities = layer.get("drift_velocities", [])
		var angles = layer.get("angles", [])
		var angular_velocities = layer.get("angular_velocities", [])
		var decay_values = layer.get("decay_values", [])
		var base_color: Color = layer.get("base_color", Color.WHITE)

		layer["injection_accumulator"] = 0.0

		for i in range(base_positions.size()):
			offsets[i] = Vector3.ZERO
			drift_velocities[i] = Vector3.ZERO
			angles[i] = Vector3.ZERO
			angular_velocities[i] = Vector3.ZERO
			decay_values[i] = 0.0
			multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, base_positions[i]))
			multimesh.set_instance_color(i, base_color)
