extends "res://algorithms/joint/shared/joint_demo_base.gd"

## FABRIK inverse kinematics on a 4-segment arm.
## The target orbits slowly; the arm solves backward from tip to base,
## then forward from base to tip, iterating until convergence.

var segments: Array[Node3D] = []
var segment_lengths: Array[float] = []
var joint_spheres: Array[MeshInstance3D] = []
var target_marker: MeshInstance3D
var line_mesh: ImmediateMesh
var line_instance: MeshInstance3D
var line_material: StandardMaterial3D

const NUM_SEGMENTS := 4
const SEGMENT_LENGTH := 1.8
const BASE_POS := Vector3(0.0, 1.0, 0.0)
const ITERATIONS := 10
const TOLERANCE := 0.01

func _build_demo() -> void:
	# Build arm segments as visual-only nodes (no physics — pure IK)
	var colors := [
		Color(0.9, 0.35, 0.25),
		Color(0.85, 0.55, 0.2),
		Color(0.3, 0.7, 0.5),
		Color(0.3, 0.5, 0.85),
	]

	for i in NUM_SEGMENTS:
		var seg := Node3D.new()
		seg.name = "Segment_%d" % i
		seg.position = BASE_POS + Vector3(0.0, i * SEGMENT_LENGTH, 0.0)
		add_child(seg)

		# Segment bar mesh
		var bar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.25, SEGMENT_LENGTH, 0.25)
		bar.mesh = box
		bar.position = Vector3(0.0, SEGMENT_LENGTH * 0.5, 0.0)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		mat.roughness = 0.35
		bar.material_override = mat
		seg.add_child(bar)

		segments.append(seg)
		segment_lengths.append(SEGMENT_LENGTH)

		# Joint sphere at base of each segment
		var sphere := MeshInstance3D.new()
		var smesh := SphereMesh.new()
		smesh.radius = 0.18
		sphere.mesh = smesh
		var smat := StandardMaterial3D.new()
		smat.albedo_color = Color(1.0, 1.0, 1.0, 0.8)
		smat.roughness = 0.2
		sphere.material_override = smat
		sphere.position = seg.position
		add_child(sphere)
		joint_spheres.append(sphere)

	# End effector sphere
	var end_sphere := MeshInstance3D.new()
	var esmesh := SphereMesh.new()
	esmesh.radius = 0.18
	end_sphere.mesh = esmesh
	var esmat := StandardMaterial3D.new()
	esmat.albedo_color = Color(1.0, 0.9, 0.3)
	esmat.roughness = 0.2
	end_sphere.material_override = esmat
	add_child(end_sphere)
	joint_spheres.append(end_sphere)

	# Target marker
	target_marker = MeshInstance3D.new()
	var tmesh := SphereMesh.new()
	tmesh.radius = 0.3
	target_marker.mesh = tmesh
	var tmat := StandardMaterial3D.new()
	tmat.albedo_color = Color(1.0, 0.2, 0.4, 0.7)
	tmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	tmat.roughness = 0.1
	target_marker.material_override = tmat
	add_child(target_marker)

	# Line drawing for the chain
	line_mesh = ImmediateMesh.new()
	line_instance = MeshInstance3D.new()
	line_instance.mesh = line_mesh
	line_material = StandardMaterial3D.new()
	line_material.albedo_color = Color(1.0, 1.0, 1.0, 0.4)
	line_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	line_material.no_depth_test = true
	line_instance.material_override = line_material
	add_child(line_instance)

	add_label("FABRIK Inverse Kinematics", Vector3(0.0, 10.0, 3.0))
	add_label("target", Vector3(0.0, 5.0, 4.0))

	set_process(true)


func _process(_delta: float) -> void:
	var t := Time.get_ticks_msec() * 0.001

	# Target orbits in a tilted circle
	var target := Vector3(
		3.5 * sin(t * 0.7),
		4.0 + 2.5 * sin(t * 0.5),
		3.5 * cos(t * 0.7)
	)
	target_marker.position = target

	# Collect joint positions (base of each segment + tip of last)
	var positions: Array[Vector3] = []
	positions.append(BASE_POS)
	for i in NUM_SEGMENTS:
		positions.append(BASE_POS + Vector3(0.0, (i + 1) * SEGMENT_LENGTH, 0.0))

	# FABRIK solver
	positions = _solve_fabrik(positions, target)

	# Apply solved positions back to segments
	for i in NUM_SEGMENTS:
		segments[i].position = positions[i]
		# Orient segment to point toward next joint
		var dir := (positions[i + 1] - positions[i]).normalized()
		if dir.length_squared() > 0.001:
			segments[i].look_at(positions[i] + dir, _up_for_direction(dir))
			segments[i].rotate_object_local(Vector3.RIGHT, deg_to_rad(90.0))

	# Update joint spheres
	for i in positions.size():
		if i < joint_spheres.size():
			joint_spheres[i].position = positions[i]

	# Draw chain lines
	_draw_chain(positions, target)


func _solve_fabrik(positions: Array[Vector3], target: Vector3) -> Array[Vector3]:
	var n := positions.size()
	var total_length := 0.0
	for l in segment_lengths:
		total_length += l

	var dist_to_target := BASE_POS.distance_to(target)

	# If target is unreachable, stretch toward it
	if dist_to_target > total_length:
		var dir := (target - BASE_POS).normalized()
		for i in range(1, n):
			positions[i] = positions[i - 1] + dir * segment_lengths[i - 1]
		return positions

	# Iterative FABRIK
	for _iter in ITERATIONS:
		# Check convergence
		if positions[n - 1].distance_to(target) < TOLERANCE:
			break

		# Backward pass: move tip to target, adjust joints
		positions[n - 1] = target
		for i in range(n - 2, -1, -1):
			var dir := (positions[i] - positions[i + 1]).normalized()
			positions[i] = positions[i + 1] + dir * segment_lengths[i]

		# Forward pass: fix base, adjust joints
		positions[0] = BASE_POS
		for i in range(1, n):
			var dir := (positions[i] - positions[i - 1]).normalized()
			positions[i] = positions[i - 1] + dir * segment_lengths[i - 1]

	return positions


func _up_for_direction(dir: Vector3) -> Vector3:
	if abs(dir.dot(Vector3.UP)) > 0.99:
		return Vector3.FORWARD
	return Vector3.UP


func _draw_chain(positions: Array[Vector3], target: Vector3) -> void:
	line_mesh.clear_surfaces()
	line_mesh.surface_begin(Mesh.PRIMITIVE_LINES, line_material)

	# Chain segments
	for i in range(positions.size() - 1):
		line_mesh.surface_add_vertex(positions[i])
		line_mesh.surface_add_vertex(positions[i + 1])

	# Line from tip to target
	line_mesh.surface_add_vertex(positions[positions.size() - 1])
	line_mesh.surface_add_vertex(target)

	line_mesh.surface_end()


func apply_grid_config(config: Dictionary) -> void:
	pass
