## Verlet Integration Cloth — Uses Godot's SoftBody3D (C++ Verlet internally)
## The engine does the same Verlet integration but ~100x faster in native code
extends Node3D

@export var cloth_size: float = 2.0
@export var cloth_resolution: int = 12
@export var simulation_precision: int = 5
@export var stiffness: float = 0.5

var cloth: SoftBody3D
var obstacle_sphere: StaticBody3D

func _ready() -> void:
	scale = Vector3(0.8, 0.8, 0.8)
	_create_cloth()
	_create_obstacle()

func _create_cloth() -> void:
	cloth = SoftBody3D.new()
	cloth.name = "VerletCloth"

	# Create plane mesh for the cloth
	var plane := PlaneMesh.new()
	plane.size = Vector2(cloth_size, cloth_size)
	plane.subdivide_width = cloth_resolution
	plane.subdivide_depth = cloth_resolution
	cloth.mesh = plane

	# Soft body settings
	cloth.simulation_precision = simulation_precision
	cloth.total_mass = 1.0
	cloth.linear_stiffness = stiffness
	cloth.pressure_coefficient = 0.0  # Flat cloth, no inflation
	cloth.damping_coefficient = 0.01
	cloth.drag_coefficient = 0.0

	# Material
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.3, 1.0, 0.9)  # Purple, slightly transparent
	mat.emission_enabled = true
	mat.emission = Color(0.5, 0.2, 0.8) * 0.3
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # See both sides
	cloth.material_override = mat

	cloth.position = Vector3(0, 2.5, 0)
	add_child(cloth)

	# Pin the four corners after adding to tree
	# Corner indices depend on mesh subdivision
	# For a (res+1)x(res+1) grid:
	var cols: int = cloth_resolution + 2  # PlaneMesh subdivide creates +2 verts per axis
	var rows: int = cloth_resolution + 2
	call_deferred("_pin_corners", cols, rows)

func _pin_corners(cols: int, rows: int) -> void:
	# Pin top-left and top-right corners
	cloth.set_point_pinned(0, true)                    # Top-left
	cloth.set_point_pinned(cols - 1, true)             # Top-right
	# Optionally pin back corners for a "hanging sheet" look:
	# cloth.set_point_pinned((rows - 1) * cols, true)       # Bottom-left
	# cloth.set_point_pinned(rows * cols - 1, true)          # Bottom-right

func _create_obstacle() -> void:
	# Sphere underneath the cloth for it to drape over
	obstacle_sphere = StaticBody3D.new()
	obstacle_sphere.name = "ObstacleSphere"

	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.5
	col.shape = shape
	obstacle_sphere.add_child(col)

	var mesh_inst := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	mesh_inst.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.9, 0.9)
	mat.metallic = 0.5
	mesh_inst.material_override = mat
	obstacle_sphere.add_child(mesh_inst)

	obstacle_sphere.position = Vector3(0, 1.5, 0)
	add_child(obstacle_sphere)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
