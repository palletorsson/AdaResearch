extends Node3D

## Double Pendulum — 3D VR version
## Classic chaotic double pendulum with trail, swinging in the XY plane.

@export var length1: float = 0.15  # Length of the first arm
@export var length2: float = 0.15  # Length of the second arm
@export var mass1: float = 14.0  # Mass of the first pendulum
@export var mass2: float = 10.0  # Mass of the second pendulum
@export var gravity: float = 1.47  # Scaled gravity (9.81 * 0.15 for meter-scale)
@export var damping: float = 1.0001  # Damping factor (>1 means slight energy gain for chaos)

@export var arm_color: Color = Color(1.0, 1.0, 1.0)
@export var mass1_color: Color = Color(1.0, 0.0, 0.0)
@export var mass2_color: Color = Color(0.3, 0.3, 1.0)
@export var trail_color_start: Color = Color(0.0, 1.0, 0.0)  # newest
@export var trail_color_end: Color = Color(0.0, 0.3, 1.0)  # oldest
@export var max_trail_points: int = 500

var angle1: float = PI / 4.0  # Initial angle of the first pendulum
var angle2: float = PI / 2.0  # Initial angle of the second pendulum
var angular_velocity1: float = 0.0
var angular_velocity2: float = 0.0

var pivot := Vector3(0.0, 0.3, 0.0)
var pos1 := Vector3.ZERO
var pos2 := Vector3.ZERO
var trail_points: Array[Vector3] = []

# Scene nodes
var _arm1_instance: MeshInstance3D
var _arm2_instance: MeshInstance3D
var _mass1_instance: MeshInstance3D
var _mass2_instance: MeshInstance3D
var _trail_mesh_instance: MeshInstance3D
var _pivot_instance: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	_calculate_positions()
	_create_pivot()
	_create_arms()
	_create_masses()
	_create_trail()
	_create_label()


func _process(delta: float) -> void:
	_update_pendulum(delta)
	_calculate_positions()

	# Add trail point
	trail_points.append(pos2)
	while trail_points.size() > max_trail_points:
		trail_points.pop_front()

	# Update visuals
	_update_arms()
	_update_masses()
	_update_trail()


func _update_pendulum(delta: float) -> void:
	# Standard double pendulum angular acceleration equations
	var num1 := -gravity * (2.0 * mass1 + mass2) * sin(angle1)
	var num2 := -mass2 * gravity * sin(angle1 - 2.0 * angle2)
	var num3 := -2.0 * sin(angle1 - angle2) * mass2
	var num4 := angular_velocity2 ** 2 * length2 + angular_velocity1 ** 2 * length1 * cos(angle1 - angle2)
	var denom1 := length1 * (2.0 * mass1 + mass2 - mass2 * cos(2.0 * angle1 - 2.0 * angle2))
	var acceleration1 := (num1 + num2 + num3 * num4) / denom1

	var num5 := 2.0 * sin(angle1 - angle2)
	var num6 := angular_velocity1 ** 2 * length1 * (mass1 + mass2)
	var num7 := gravity * (mass1 + mass2) * cos(angle1)
	var num8 := angular_velocity2 ** 2 * length2 * mass2 * cos(angle1 - angle2)
	var denom2 := length2 * (2.0 * mass1 + mass2 - mass2 * cos(2.0 * angle1 - 2.0 * angle2))
	var acceleration2 := (num5 * (num6 + num7 + num8)) / denom2

	angular_velocity1 += acceleration1 * delta
	angular_velocity2 += acceleration2 * delta

	angular_velocity1 *= damping
	angular_velocity2 *= damping

	angle1 += angular_velocity1 * delta
	angle2 += angular_velocity2 * delta


func _calculate_positions() -> void:
	# Pendulum swings in XY plane: x = sin(angle), y = -cos(angle) (hanging down)
	pos1 = pivot + Vector3(length1 * sin(angle1), -length1 * cos(angle1), 0.0)
	pos2 = pos1 + Vector3(length2 * sin(angle2), -length2 * cos(angle2), 0.0)


func _create_label() -> void:
	_label = Label3D.new()
	_label.text = "Double Pendulum"
	_label.font_size = 32
	_label.position = Vector3(0.0, -0.05, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.modulate = Color(1.0, 1.0, 1.0)
	add_child(_label)


func _create_pivot() -> void:
	_pivot_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.008
	sphere.height = 0.016
	sphere.radial_segments = 8
	sphere.rings = 4
	_pivot_instance.mesh = sphere
	_pivot_instance.position = pivot

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = arm_color
	mat.emission_enabled = true
	mat.emission = arm_color
	_pivot_instance.material_override = mat

	add_child(_pivot_instance)


func _create_arms() -> void:
	# Arm 1
	_arm1_instance = MeshInstance3D.new()
	var cyl1 := CylinderMesh.new()
	cyl1.top_radius = 0.005
	cyl1.bottom_radius = 0.005
	cyl1.height = length1
	cyl1.radial_segments = 8
	_arm1_instance.mesh = cyl1

	var mat1 := StandardMaterial3D.new()
	mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat1.albedo_color = arm_color
	mat1.emission_enabled = true
	mat1.emission = arm_color
	_arm1_instance.material_override = mat1
	add_child(_arm1_instance)

	# Arm 2
	_arm2_instance = MeshInstance3D.new()
	var cyl2 := CylinderMesh.new()
	cyl2.top_radius = 0.005
	cyl2.bottom_radius = 0.005
	cyl2.height = length2
	cyl2.radial_segments = 8
	_arm2_instance.mesh = cyl2

	var mat2 := StandardMaterial3D.new()
	mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat2.albedo_color = arm_color
	mat2.emission_enabled = true
	mat2.emission = arm_color
	_arm2_instance.material_override = mat2
	add_child(_arm2_instance)


func _update_arms() -> void:
	# Position arm1 at midpoint between pivot and pos1, oriented along the connection
	var mid1 := (pivot + pos1) / 2.0
	_arm1_instance.position = mid1
	_arm1_instance.rotation = Vector3.ZERO
	# CylinderMesh is along Y by default; rotate to align with pivot→pos1
	var dir1 := (pos1 - pivot).normalized()
	_arm1_instance.rotation.z = atan2(dir1.x, -dir1.y) * -1.0
	# Correct: use look rotation for XY plane
	_arm1_instance.rotation = Vector3(0.0, 0.0, -atan2(dir1.x, dir1.y))

	var mid2 := (pos1 + pos2) / 2.0
	_arm2_instance.position = mid2
	var dir2 := (pos2 - pos1).normalized()
	_arm2_instance.rotation = Vector3(0.0, 0.0, -atan2(dir2.x, dir2.y))


func _create_masses() -> void:
	# Mass 1
	_mass1_instance = MeshInstance3D.new()
	var sphere1 := SphereMesh.new()
	sphere1.radius = 0.02
	sphere1.height = 0.04
	sphere1.radial_segments = 12
	sphere1.rings = 6
	_mass1_instance.mesh = sphere1

	var mat1 := StandardMaterial3D.new()
	mat1.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat1.albedo_color = mass1_color
	mat1.emission_enabled = true
	mat1.emission = mass1_color
	_mass1_instance.material_override = mat1
	add_child(_mass1_instance)

	# Mass 2
	_mass2_instance = MeshInstance3D.new()
	var sphere2 := SphereMesh.new()
	sphere2.radius = 0.015
	sphere2.height = 0.03
	sphere2.radial_segments = 12
	sphere2.rings = 6
	_mass2_instance.mesh = sphere2

	var mat2 := StandardMaterial3D.new()
	mat2.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat2.albedo_color = mass2_color
	mat2.emission_enabled = true
	mat2.emission = mass2_color
	_mass2_instance.material_override = mat2
	add_child(_mass2_instance)


func _update_masses() -> void:
	_mass1_instance.position = pos1
	_mass2_instance.position = pos2


func _create_trail() -> void:
	_trail_mesh_instance = MeshInstance3D.new()
	_trail_mesh_instance.mesh = ImmediateMesh.new()

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = trail_color_start
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_trail_mesh_instance.material_override = mat

	add_child(_trail_mesh_instance)


func _update_trail() -> void:
	var mesh: ImmediateMesh = _trail_mesh_instance.mesh
	mesh.clear_surfaces()

	if trail_points.size() < 2:
		return

	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var count := trail_points.size()
	for i in range(count - 1):
		var t := float(i) / float(count - 1)  # 0 = oldest, 1 = newest
		var c := trail_color_end.lerp(trail_color_start, t)
		c.a = t  # Fade oldest to transparent
		mesh.surface_set_color(c)
		mesh.surface_add_vertex(trail_points[i])
		mesh.surface_set_color(c)
		mesh.surface_add_vertex(trail_points[i + 1])

	mesh.surface_end()


func _exit_tree() -> void:
	for child in get_children():
		child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
