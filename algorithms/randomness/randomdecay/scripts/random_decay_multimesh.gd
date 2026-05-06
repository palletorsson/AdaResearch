# @identity
# essence: d(decay)/dt = growth_rate · (0.2 + decay · 0.8) — autocatalytic decay
# desire: watch two pristine stacks slowly crumble — drift, darken, sink — and feel entropy win
# critical_parameter: decay_growth_rate — controls how fast decay accelerates once seeded
# triggers: injection_accumulator randomly seeds decay into instances; decay_start_delay gates the onset
# emerges: each instance decays at its own rate — the grid becomes a ruin uniquely every time
# needs: VR push buttons for TOGGLE/RESET [has]; Grid.gdshader for wireframe overlay [has]
# relationships: contrasts with Random_Rotate_Random_XYZ (rotation without destruction); feeds hardware_entropy_decay
# truth: Decay is not failure — it is matter remembering that arrangement is improbable.

extends Node3D

# Random decay demo built with MultiMesh-only stacks.
# Two standing 2D stacks are generated:
# - 1m cubes with small gutter spacing
# - 1dm prisms with smaller spacing
# Instances drift, rotate, sink, and darken over time.

@export_category("Simulation")
@export var decay_active: bool = true
@export var random_seed: int = 0
@export var decay_growth_rate: float = 0.06
@export var decay_injection_per_second: float = 0.08
@export var drift_strength: float = 0.18
@export var max_offset: float = 0.35
@export var rotation_jitter_degrees: float = 5.0
@export var sink_distance: float = 0.18
@export_range(0.1, 1.0, 0.01) var minimum_scale: float = 0.45
@export var movement_xy_only: bool = true
@export var rotation_xy_plane_only: bool = true
@export var snap_to_grid_on_spawn: bool = true
@export var decay_start_delay: float = 4.0
@export var decay_ramp_seconds: float = 10.0
@export var force_uniform_item_size: bool = true

@export_category("Cube Stack (1m)")
@export var cube_columns: int = 5
@export var cube_rows: int = 4
@export var cube_size: Vector3 = Vector3.ONE
@export var cube_gutter: float = 0.08
@export var cube_origin: Vector3 = Vector3(-4.0, 0.0, 0.0)
@export var cube_base_color: Color = Color(0.35, 0.66, 1.0, 1.0)
@export_range(0.02, 2.0, 0.01) var cube_decay_speed_scale: float = 0.32
@export_range(0.0, 1.0, 0.01) var cube_color_decay_mix: float = 0.42

@export_category("Prism Stack (1dm)")
@export var prism_columns: int = 12
@export var prism_rows: int = 10
@export var prism_size: Vector3 = Vector3(0.1, 0.1, 0.1)
@export var prism_gutter: float = 0.02
@export var prism_origin: Vector3 = Vector3(3.2, 0.0, 0.0)
@export var prism_base_color: Color = Color(0.62, 0.72, 0.86, 1.0)
@export_range(0.02, 2.0, 0.01) var prism_decay_speed_scale: float = 0.14
@export_range(0.0, 1.0, 0.01) var prism_color_decay_mix: float = 0.2

@export_category("Decay Color")
@export var decay_color: Color = Color(0.07, 0.07, 0.07, 0.65)

@export_category("Sources")
@export var cube_scene_template: PackedScene = preload("res://commons/primitives/cubes/cube_scene.tscn")
@export var grid_shader: Shader = preload("res://commons/resourses/shaders/Grid.gdshader")

var _rng := RandomNumberGenerator.new()
var _layers: Array[Dictionary] = []
var _decay_elapsed: float = 0.0


func _ready() -> void:
	if random_seed != 0:
		_rng.seed = random_seed
	else:
		_rng.randomize()
	_decay_elapsed = 0.0
	_create_layers()
	_create_vr_controls()

func _process(delta: float) -> void:
	if not decay_active:
		return
	_decay_elapsed += delta
	var start_factor: float = _compute_decay_start_factor()
	if start_factor <= 0.0:
		return
	for layer in _layers:
		_advance_layer(layer, delta, start_factor)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_home"):
		_reset_layers()
	elif event.is_action_pressed("ui_accept"):
		decay_active = not decay_active
		if decay_active:
			_decay_elapsed = 0.0

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("DECAY", [
		[{"type": "button", "label": "TOGGLE"}, {"type": "button", "label": "RESET"}],
	])
	var mid_x := (cube_origin.x + prism_origin.x) / 2.0
	panel.position = Vector3(mid_x, 0.85, 1.2)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	var toggle_btn: Node = panel.find_child("Btn_0", true, false)
	if toggle_btn:
		var area: Node = toggle_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b):
				decay_active = not decay_active
				if decay_active:
					_decay_elapsed = 0.0
			)

	var reset_btn: Node = panel.find_child("Btn_1", true, false)
	if reset_btn:
		var area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b):
				_reset_layers()
			)

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
	var cube_resources: Dictionary = _resolve_cube_scene_resources()
	var cube_mesh: Mesh = cube_resources.get("mesh") as Mesh
	var cube_material: Material = cube_resources.get("material") as Material
	if cube_mesh == null:
		var fallback_cube := BoxMesh.new()
		fallback_cube.size = cube_size
		cube_mesh = fallback_cube
	if cube_material == null:
		cube_material = _create_grid_layer_material(
			cube_base_color,
			Color(1.0, 0.0, 1.0, 1.0),
			cube_base_color.lightened(0.35),
			3.4,
			0.6,
			0.42
		)

	return _create_layer(
		"DecayLayer_Cubes",
		cube_mesh,
		cube_columns,
		cube_rows,
		cube_size,
		cube_gutter,
		cube_origin,
		cube_base_color,
		cube_material,
		cube_decay_speed_scale,
		cube_color_decay_mix
	)

func _create_prism_layer() -> Dictionary:
	var resolved_prism_size: Vector3 = cube_size if force_uniform_item_size else prism_size
	var prism_mesh := PrismMesh.new()
	prism_mesh.size = resolved_prism_size

	var prism_material: Material = _create_grid_layer_material(
		prism_base_color,
		Color(0.55, 0.85, 1.0, 1.0),
		prism_base_color.lightened(0.2),
		2.9,
		0.95,
		0.32
	)

	return _create_layer(
		"DecayLayer_Prisms",
		prism_mesh,
		prism_columns,
		prism_rows,
		resolved_prism_size,
		prism_gutter,
		prism_origin,
		prism_base_color,
		prism_material,
		prism_decay_speed_scale,
		prism_color_decay_mix
	)

func _create_layer(
	node_name: String,
	mesh: Mesh,
	columns: int,
	rows: int,
	element_size: Vector3,
	gutter: float,
	origin: Vector3,
	base_color: Color,
	material_override: Material,
	speed_scale: float,
	color_decay_mix: float
) -> Dictionary:
	var safe_columns := maxi(columns, 1)
	var safe_rows := maxi(rows, 1)
	var instance_count := safe_columns * safe_rows

	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true
	multimesh.use_custom_data = true
	multimesh.instance_count = instance_count
	multimesh.mesh = mesh

	var instance := MultiMeshInstance3D.new()
	instance.name = node_name
	instance.multimesh = multimesh
	instance.material_override = material_override
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
			var local_x: float = float(col) * step_x - half_width
			var local_y: float = element_size.y * 0.5 + float(row) * step_y
			if snap_to_grid_on_spawn:
				local_x = _snap_to_step(local_x, step_x)
				local_y = _snap_to_step(local_y, step_y)
			var initial_position := origin + Vector3(local_x, local_y, 0.0)
			base_positions.append(initial_position)
			offsets.append(Vector3.ZERO)
			drift_velocities.append(Vector3.ZERO)
			angles.append(Vector3.ZERO)
			angular_velocities.append(Vector3.ZERO)
			decay_values.append(0.0)
			multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, initial_position))
			multimesh.set_instance_color(index, base_color)
			multimesh.set_instance_custom_data(index, _build_custom_emission(base_color, 0.0))
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
		"injection_accumulator": 0.0,
		"speed_scale": maxf(speed_scale, 0.02),
		"color_decay_mix": clampf(color_decay_mix, 0.0, 1.0)
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

func _advance_layer(layer: Dictionary, delta: float, start_factor: float) -> void:
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
	var speed_scale: float = float(layer.get("speed_scale", 1.0))
	var color_mix_scale: float = float(layer.get("color_decay_mix", 1.0))
	var effective_speed: float = speed_scale * clampf(start_factor, 0.0, 1.0)
	var instance_count: int = base_positions.size()
	if instance_count == 0:
		return

	var injection_accumulator: float = layer.get("injection_accumulator", 0.0)
	injection_accumulator += float(instance_count) * decay_injection_per_second * effective_speed * delta
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
		decay = clampf(decay + decay_growth_rate * effective_speed * delta * (0.2 + decay * 0.8), 0.0, 1.0)
		decay_values[i] = decay

		var drift_velocity: Vector3 = Vector3(drift_velocities[i])
		var drift_noise: Vector3 = Vector3(
			_rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0),
			0.0 if movement_xy_only else _rng.randf_range(-1.0, 1.0)
		) * drift_strength * (0.15 + decay * 1.35) * effective_speed
		drift_velocity += drift_noise * delta
		drift_velocity *= lerpf(0.96, 0.88, decay)
		if movement_xy_only:
			drift_velocity.z = 0.0
		drift_velocities[i] = drift_velocity

		var offset: Vector3 = Vector3(offsets[i]) + drift_velocity
		var offset_limit: float = max_offset * (0.2 + decay * 0.8)
		if movement_xy_only:
			var offset_xy := Vector2(offset.x, offset.y)
			if offset_xy.length() > offset_limit and offset_limit > 0.0:
				offset_xy = offset_xy.normalized() * offset_limit
			offset = Vector3(offset_xy.x, offset_xy.y, 0.0)
		elif offset.length() > offset_limit and offset_limit > 0.0:
			offset = offset.normalized() * offset_limit
		offsets[i] = offset

		var angular_velocity: Vector3 = Vector3(angular_velocities[i])
		var angular_noise: Vector3 = Vector3(
			0.0 if rotation_xy_plane_only else _rng.randf_range(-1.0, 1.0),
			0.0 if rotation_xy_plane_only else _rng.randf_range(-1.0, 1.0),
			_rng.randf_range(-1.0, 1.0)
		) * jitter_radians * (0.12 + decay * 0.9) * effective_speed
		angular_velocity += angular_noise * delta
		angular_velocity *= lerpf(0.965, 0.9, decay)
		angular_velocities[i] = angular_velocity

		var angle: Vector3 = Vector3(angles[i]) + angular_velocity
		angles[i] = angle

		var sink := Vector3(0.0, -sink_distance * decay, 0.0)
		var position: Vector3 = Vector3(base_positions[i]) + offset + sink
		if movement_xy_only:
			position.z = float(Vector3(base_positions[i]).z)
		var scale_value: float = 1.0 if force_uniform_item_size else lerpf(1.0, minimum_scale, decay)
		var basis := Basis.from_euler(angle).scaled(Vector3.ONE * scale_value)

		var color_decay: float = clampf(decay * color_mix_scale, 0.0, 1.0)
		multimesh.set_instance_transform(i, Transform3D(basis, position))
		multimesh.set_instance_color(i, base_color.lerp(decay_color, color_decay))
		multimesh.set_instance_custom_data(i, _build_custom_emission(base_color, color_decay))

func _reset_layers() -> void:
	_decay_elapsed = 0.0
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
			multimesh.set_instance_custom_data(i, _build_custom_emission(base_color, 0.0))

func _compute_decay_start_factor() -> float:
	if decay_start_delay <= 0.0 and decay_ramp_seconds <= 0.0:
		return 1.0

	if _decay_elapsed < decay_start_delay:
		return 0.0

	var ramp_duration: float = maxf(decay_ramp_seconds, 0.001)
	var t: float = clampf((_decay_elapsed - decay_start_delay) / ramp_duration, 0.0, 1.0)
	# Smoothstep easing for a gentle startup.
	return t * t * (3.0 - 2.0 * t)

func _snap_to_step(value: float, step: float) -> float:
	var safe_step: float = maxf(step, 0.0001)
	return round(value / safe_step) * safe_step

func _resolve_cube_scene_resources() -> Dictionary:
	if cube_scene_template == null:
		return {}

	var scene_instance: Node = cube_scene_template.instantiate()
	var mesh_instance: MeshInstance3D = scene_instance.get_node_or_null("CubeBaseStaticBody3D/CubeBaseMesh") as MeshInstance3D
	if mesh_instance == null:
		mesh_instance = _find_first_mesh_instance(scene_instance)

	if mesh_instance == null or mesh_instance.mesh == null:
		scene_instance.free()
		return {}

	var copied_mesh: Mesh = mesh_instance.mesh.duplicate(true) as Mesh
	var copied_material: Material = null
	if mesh_instance.material_override != null:
		copied_material = mesh_instance.material_override.duplicate(true) as Material

	scene_instance.free()
	return {
		"mesh": copied_mesh,
		"material": copied_material
	}

func _find_first_mesh_instance(root: Node) -> MeshInstance3D:
	if root is MeshInstance3D:
		return root as MeshInstance3D

	for child in root.get_children():
		var child_node: Node = child as Node
		if child_node == null:
			continue
		var found: MeshInstance3D = _find_first_mesh_instance(child_node)
		if found != null:
			return found
	return null

func _create_grid_layer_material(
	model_color: Color,
	wireframe_color: Color,
	emission_color: Color,
	width: float,
	blur: float,
	emission_strength: float
) -> Material:
	if grid_shader == null:
		return _create_layer_material()

	var material := ShaderMaterial.new()
	material.shader = grid_shader
	material.set_shader_parameter("modelColor", model_color)
	material.set_shader_parameter("wireframeColor", wireframe_color)
	material.set_shader_parameter("emissionColor", emission_color)
	material.set_shader_parameter("width", width)
	material.set_shader_parameter("blur", blur)
	material.set_shader_parameter("emission_strength", emission_strength)
	material.set_shader_parameter("show_interior", true)
	return material

func _build_custom_emission(base_color: Color, decay_amount: float) -> Color:
	var t: float = clampf(decay_amount, 0.0, 1.0)
	var emission: Color = base_color.lerp(decay_color.darkened(0.2), t).lightened(0.08)
	return Color(emission.r, emission.g, emission.b, 1.0)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
