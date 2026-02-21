# one_leg.gd
# ONE jumping leg — simplest possible FABRIK3D + SpringArm3D test.
# The .tscn defines all nodes (Skeleton3D, bones, FABRIK3D, SpringArm3D, magnet).
# This script only adds: skinned mesh (can't be defined in .tscn without Blender),
# body box mesh, floor, camera, lighting, and WASD movement.
#
# Run one_leg.tscn with F6 to test standalone.
extends MeshInstance3D

func _ready() -> void:
	# Body box mesh
	var box := BoxMesh.new()
	box.size = Vector3(0.8, 0.4, 0.6)
	mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.4, 0.3, 0.5)
	material_override = mat

	# Add skinned mesh to the skeleton
	_add_skinned_mesh()

	# Add foot target debug sphere
	_add_foot_vis()

	# Build scene (floor, camera, lighting)
	_build_scene()

	print("[OneLeg] Ready — body at Y=%.1f" % global_position.y)
	print("[OneLeg] WASD to move. Leg should bend to reach ground.")

func _process(delta: float) -> void:
	# WASD movement (exact beast_controller.gd pattern)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input.length_squared() > 0.01:
		position += -basis.z * input.y * delta * 3.0
		rotation.y += deg_to_rad(-input.x * delta * 40.0)

# ═══════════════════════════════════════════════════════════════════════════
# SKINNED MESH — beast_demo / spine_demo pattern
# ═══════════════════════════════════════════════════════════════════════════

func _add_skinned_mesh() -> void:
	var skeleton: Skeleton3D = $IK_leg/Armature/Skeleton3D

	var skin := Skin.new()
	skin.set_bind_count(6)
	for i in range(6):
		var bname: String = "Bone" if i == 0 else "Bone.%03d" % i
		skin.set_bind_name(i, bname)
		skin.set_bind_bone(i, -1)  # Name-based binding (beast_demo)
		# Bind pose = inverse of cumulative bone position
		# Bone 0 at Y=0 → (0,0,0), Bone 1 at Y=1 → (0,-1,0), etc.
		skin.set_bind_pose(i, Transform3D(Basis.IDENTITY, Vector3(0, -float(i), 0)))

	var leg_mesh: ArrayMesh = _make_tapered_tube(6, 1.0, 0.12, 0.03, 8)

	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.5, 0.2, 0.3)
	leg_mat.roughness = 0.5
	leg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Double-sided (spine_demo)

	var mi := MeshInstance3D.new()
	mi.name = "LegMesh"
	mi.mesh = leg_mesh
	mi.skin = skin
	mi.skeleton = NodePath("..")  # parent = Skeleton3D
	mi.material_override = leg_mat
	skeleton.add_child(mi)

	print("[OneLeg] Skinned mesh: %d bones, bind poses OK" % skin.get_bind_count())

func _make_tapered_tube(bone_count: int, spacing: float, base_r: float, tip_r: float, segs: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var bone_ids := PackedInt32Array()
	var bone_wts := PackedFloat32Array()

	for ring in range(bone_count):
		var y: float = spacing * float(ring)
		var t: float = float(ring) / float(bone_count - 1)
		var r: float = lerp(base_r, tip_r, t)
		for s in range(segs):
			var a: float = TAU * float(s) / float(segs)
			verts.append(Vector3(cos(a) * r, y, sin(a) * r))
			norms.append(Vector3(cos(a), 0, sin(a)))
			bone_ids.append(ring); bone_ids.append(0); bone_ids.append(0); bone_ids.append(0)
			bone_wts.append(1.0); bone_wts.append(0.0); bone_wts.append(0.0); bone_wts.append(0.0)

	var idx := PackedInt32Array()
	for ring in range(bone_count - 1):
		for s in range(segs):
			var c: int = ring * segs + s
			var n: int = ring * segs + (s + 1) % segs
			var a: int = (ring + 1) * segs + s
			var an: int = (ring + 1) * segs + (s + 1) % segs
			idx.append(c); idx.append(a); idx.append(n)
			idx.append(n); idx.append(a); idx.append(an)

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_BONES] = bone_ids
	arrays[Mesh.ARRAY_WEIGHTS] = bone_wts
	arrays[Mesh.ARRAY_INDEX] = idx

	var m := ArrayMesh.new()
	m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return m

func _add_foot_vis() -> void:
	var foot: Marker3D = $SpringArm3D/FootTarget
	var vis := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.15
	sphere.height = 0.3
	vis.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.3, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.2, 0.1)
	mat.emission_energy_multiplier = 2.0
	vis.material_override = mat
	foot.add_child(vis)

# ═══════════════════════════════════════════════════════════════════════════
# SCENE SETUP (only when running standalone)
# ═══════════════════════════════════════════════════════════════════════════

func _build_scene() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	# Only build environment if we're the root scene (standalone test)
	var parent: Node = get_parent()
	if parent != scene_root:
		return

	# Floor with collision (collision_mask = 1 so SpringArm3D hits it)
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	var fm := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(20, 0.1, 20)
	fm.mesh = fb
	fm.position.y = -0.05
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.35, 0.35, 0.38)
	fm.material_override = fmat
	floor_body.add_child(fm)
	var fc := CollisionShape3D.new()
	var fs := BoxShape3D.new()
	fs.size = Vector3(20, 0.1, 20)
	fc.shape = fs
	fc.position.y = -0.05
	floor_body.add_child(fc)
	parent.add_child(floor_body)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.2, 0.22, 0.3)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.5, 0.5, 0.55)
	env.ambient_light_energy = 0.8
	var we := WorldEnvironment.new()
	we.environment = env
	parent.add_child(we)

	# Light
	var light := DirectionalLight3D.new()
	light.shadow_enabled = true
	light.rotation_degrees = Vector3(-45, -30, 0)
	parent.add_child(light)

	# Camera
	if get_viewport().get_camera_3d() == null:
		var cam := Camera3D.new()
		cam.position = Vector3(4, 4, 6)
		cam.look_at(Vector3(0, 1, 0))
		cam.current = true
		parent.add_child(cam)
