# @identity
# essence: three Godot-native soft bodies side by side — jelly cube, rubber ball, inflated balloon — same primitive, different parameter family
# desire: see how a single Godot feature (SoftBody3D) covers a wide phenomenology by parameter alone
# critical_parameter: stiffness vs pressure ratio — jelly is high-damping/low-pressure, balloon is high-pressure/low-damping
# triggers: _ready() creates a floor and instantiates each of the three demos at fixed positions
# emerges: a small comparative shelf where three named substances jiggle, bounce, and balloon with different signatures
# needs: per-body parameter sliders [missing]; floor toggle [present]; reset button [missing]
# relationships: Godot-native counterpart to spring_mass_system (manual); placement-companion to particle_body (particle-bound soft); home for softbodies-sequence comparison demos
# truth: A soft body is a parameter family pretending to be three substances. The same equation makes jelly, rubber, and air-pressure — the substance is in the numbers, not in the model.

## Soft Bodies — Multiple SoftBody3D demos with different parameters
## Jelly cube, rubber ball, inflated balloon — all using Godot's native SoftBody3D
extends Node3D

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_floor()
	_create_jelly_cube(Vector3(-2, 2, 0))
	_create_rubber_ball(Vector3(0, 2, 0))
	_create_balloon(Vector3(2, 2, 0))

func _create_floor() -> void:
	var floor_body := StaticBody3D.new()
	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(8, 0.2, 6)
	floor_col.shape = floor_shape
	floor_body.add_child(floor_col)
	floor_body.position = Vector3(0, -0.1, 0)
	add_child(floor_body)

func _create_jelly_cube(pos: Vector3) -> void:
	var sb := SoftBody3D.new()
	sb.name = "JellyCube"

	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.8, 0.8)
	box.subdivide_width = 4
	box.subdivide_height = 4
	box.subdivide_depth = 4
	sb.mesh = box

	sb.simulation_precision = 5
	sb.total_mass = 1.0
	sb.linear_stiffness = 0.3  # Very wobbly
	sb.pressure_coefficient = 2.0  # Keeps volume
	sb.damping_coefficient = 0.02

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 1.0, 0.5, 0.85)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.8, 0.3) * 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sb.material_override = mat

	sb.position = pos
	add_child(sb)

func _create_rubber_ball(pos: Vector3) -> void:
	var sb := SoftBody3D.new()
	sb.name = "RubberBall"

	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 16
	sphere.rings = 8
	sb.mesh = sphere

	sb.simulation_precision = 5
	sb.total_mass = 0.5
	sb.linear_stiffness = 0.6  # Moderately bouncy
	sb.pressure_coefficient = 3.0  # Inflated
	sb.damping_coefficient = 0.01

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.4, 0.7)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.3, 0.5) * 0.3
	mat.metallic = 0.1
	mat.roughness = 0.8
	sb.material_override = mat

	sb.position = pos
	add_child(sb)

func _create_balloon(pos: Vector3) -> void:
	var sb := SoftBody3D.new()
	sb.name = "Balloon"

	var sphere := SphereMesh.new()
	sphere.radius = 0.6
	sphere.height = 1.2
	sphere.radial_segments = 12
	sphere.rings = 6
	sb.mesh = sphere

	sb.simulation_precision = 4
	sb.total_mass = 0.2  # Very light
	sb.linear_stiffness = 0.15  # Very stretchy
	sb.pressure_coefficient = 5.0  # Highly inflated
	sb.damping_coefficient = 0.03

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.3, 1.0, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.6, 0.2, 0.8) * 0.4
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sb.material_override = mat

	sb.position = pos
	add_child(sb)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
