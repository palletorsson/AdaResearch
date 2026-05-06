extends Node3D

# DIAGNOSTIC TEST - Place one of each primitive directly without using BuildEnv
# This tests if the mesh creation code works at all

func _ready() -> void:
	print("\n=== DIAGNOSTIC TEST ===")
	print("Creating primitives directly to test mesh visibility...")

	# Wait a frame
	await get_tree().process_frame

	# Test 1: Simple box
	print("\n1. Creating simple box...")
	var box = _make_test_box(Vector3(1, 0.5, 1), Vector3(-3, 2, 0))
	add_child(box)
	print("   Box created - Children: %d" % box.get_child_count())
	for i in range(box.get_child_count()):
		print("   - Child %d: %s" % [i, box.get_child(i).get_class()])

	# Test 2: Cylinder
	print("\n2. Creating cylinder...")
	var cyl = _make_test_cylinder(0.3, 1.0, Vector3(0, 2, 0))
	add_child(cyl)
	print("   Cylinder created - Children: %d" % cyl.get_child_count())

	# Test 3: Ground plane
	print("\n3. Creating ground plane...")
	var ground = _make_test_ground()
	add_child(ground)
	print("   Ground created")

	print("\n=== DIAGNOSTIC COMPLETE ===")
	print("If you still see nothing:")
	print("1. Check camera is positioned at (8, 6, 8) looking at origin")
	print("2. Add DirectionalLight3D to scene")
	print("3. Check viewport/display settings")
	print("4. Try running in fullscreen (F11)")

func _make_test_box(size: Vector3, pos: Vector3) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.position = pos

	# Mesh
	var mesh_inst = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = size
	mesh_inst.mesh = box_mesh

	# Material
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0, 0)  # Bright red
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED  # No lighting needed
	mesh_inst.material_override = mat

	sb.add_child(mesh_inst)
	print("   Created box mesh at %s" % pos)
	return sb

func _make_test_cylinder(radius: float, height: float, pos: Vector3) -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.position = pos

	var mesh_inst = MeshInstance3D.new()
	var cyl_mesh = CylinderMesh.new()
	cyl_mesh.top_radius = radius
	cyl_mesh.bottom_radius = radius
	cyl_mesh.height = height
	mesh_inst.mesh = cyl_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0, 1, 0)  # Bright green
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat

	sb.add_child(mesh_inst)
	print("   Created cylinder mesh at %s" % pos)
	return sb

func _make_test_ground() -> StaticBody3D:
	var sb = StaticBody3D.new()
	sb.position = Vector3(0, 0, 0)

	var mesh_inst = MeshInstance3D.new()
	var plane_mesh = BoxMesh.new()
	plane_mesh.size = Vector3(20, 0.2, 20)
	mesh_inst.mesh = plane_mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.2)  # Green
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mesh_inst.material_override = mat

	sb.add_child(mesh_inst)
	print("   Created ground plane")
	return sb

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
