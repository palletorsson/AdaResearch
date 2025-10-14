extends Node3D

const STEP_COUNT := 96
const TOTAL_TURNS := 2.5
const BASE_RADIUS := 1.6
const WALKWAY_OFFSET := 0.9
const STEP_RISE := 0.32
const STEP_THICKNESS := 0.22
const STEP_WIDTH := 1.6
const MIN_STEP_DEPTH := 0.4
const WAVE_AMPLITUDE := 0.45
const WAVE_FREQUENCY := 2.0
const COLUMN_MARGIN := 2.0

var _step_material: StandardMaterial3D

func _ready():
	_step_material = _create_step_material()
	_create_central_column()
	var step_data = _compute_step_data()
	_create_staircase(step_data)
	_create_start_marker(step_data)
	_create_top_marker(step_data)

func _create_central_column():
	var total_height = float(STEP_COUNT) * STEP_RISE + COLUMN_MARGIN
	var column_mesh = CylinderMesh.new()
	column_mesh.top_radius = BASE_RADIUS
	column_mesh.bottom_radius = BASE_RADIUS
	column_mesh.height = total_height
	column_mesh.radial_segments = 64

	var column_instance = MeshInstance3D.new()
	column_instance.name = "CentralColumn"
	column_instance.mesh = column_mesh
	column_instance.position = Vector3(0, total_height * 0.5, 0)
	add_child(column_instance)

	var column_body = StaticBody3D.new()
	column_body.name = "CentralColumnBody"
	column_body.position = column_instance.position

	var column_shape = CollisionShape3D.new()
	var cylinder_shape = CylinderShape3D.new()
	cylinder_shape.height = total_height
	cylinder_shape.radius = BASE_RADIUS
	column_shape.shape = cylinder_shape
	column_body.add_child(column_shape)
	add_child(column_body)

func _compute_step_data() -> Array:
	var data: Array = []
	var denominator = max(1, STEP_COUNT - 1)
	for i in range(STEP_COUNT):
		var progress = float(i) / float(denominator)
		var angle = progress * TOTAL_TURNS * TAU
		var wave = sin(angle * WAVE_FREQUENCY) * WAVE_AMPLITUDE
		var radius = BASE_RADIUS + WALKWAY_OFFSET + wave
		var step_top = float(i) * STEP_RISE
		var center_y = step_top - STEP_THICKNESS * 0.5
		var position = Vector3(
			cos(angle) * radius,
			center_y,
			sin(angle) * radius
		)
		data.append({
			"angle": angle,
			"position": position,
			"radius": radius,
			"top": step_top
		})
	return data

func _create_staircase(step_data: Array) -> void:
	var steps_root = Node3D.new()
	steps_root.name = "StairSteps"
	add_child(steps_root)

	for i in range(step_data.size()):
		var current = step_data[i]
		var prev = step_data[max(i - 1, 0)]
		var nxt = step_data[min(i + 1, step_data.size() - 1)]

		var current_pos: Vector3 = current["position"]
		var prev_pos: Vector3 = prev["position"]
		var nxt_pos: Vector3 = nxt["position"]

		var root = Node3D.new()
		root.name = "Step_%03d" % i
		root.position = current_pos

		var radial = Vector3(current_pos.x, 0, current_pos.z)
		if radial.length() < 0.001:
			radial = Vector3.FORWARD
		radial = radial.normalized()

		var tangent_vec = (nxt_pos - prev_pos)
		tangent_vec.y = 0.0
		if tangent_vec.length() < 0.001:
			tangent_vec = Vector3(-radial.z, 0, radial.x)
		tangent_vec = tangent_vec.normalized()

		root.basis = Basis(radial, Vector3.UP, tangent_vec).orthonormalized()
		steps_root.add_child(root)

		var forward_span = (nxt_pos - current_pos)
		forward_span.y = 0.0
		var backward_span = (current_pos - prev_pos)
		backward_span.y = 0.0
		var span_length = 0.5 * forward_span.length() + 0.5 * backward_span.length()
		if span_length < MIN_STEP_DEPTH:
			span_length = MIN_STEP_DEPTH

		var box_mesh = BoxMesh.new()
		box_mesh.size = Vector3(STEP_WIDTH, STEP_THICKNESS, span_length * 1.35)

		var step_mesh = MeshInstance3D.new()
		step_mesh.mesh = box_mesh
		step_mesh.material_override = _step_material
		root.add_child(step_mesh)

		var static_body = StaticBody3D.new()
		static_body.name = "StepBody"
		var collision_shape = CollisionShape3D.new()
		var box_shape = BoxShape3D.new()
		box_shape.size = box_mesh.size
		collision_shape.shape = box_shape
		static_body.add_child(collision_shape)
		root.add_child(static_body)

func _create_step_material() -> StandardMaterial3D:
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.9, 0.85, 0.8)
	mat.roughness = 0.6
	mat.metallic = 0.0
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.25, 0.3)
	mat.emission_energy_multiplier = 0.25
	return mat

func _create_start_marker(step_data: Array):
	if step_data.is_empty():
		return
	var first = step_data[0]
	var first_pos: Vector3 = first["position"]
	var radial = Vector3(first_pos.x, 0, first_pos.z)
	if radial.length() < 0.001:
		radial = Vector3.BACK
		radial = radial.normalized()
	var marker = Marker3D.new()
	marker.name = "PlayerStart"
	marker.position = first_pos + Vector3(0, STEP_THICKNESS * 0.5 + 0.05, 0) + radial * 0.6
	add_child(marker)

func _create_top_marker(step_data: Array):
	if step_data.is_empty():
		return
	var last = step_data[step_data.size() - 1]
	var last_pos: Vector3 = last["position"]
	var radial = Vector3(last_pos.x, 0, last_pos.z)
	if radial.length() < 0.001:
		radial = Vector3.FORWARD
		radial = radial.normalized()
	var marker = Marker3D.new()
	marker.name = "Summit"
	marker.position = last_pos + Vector3(0, STEP_THICKNESS * 0.5 + 0.05, 0) + radial * 0.4
	add_child(marker)

