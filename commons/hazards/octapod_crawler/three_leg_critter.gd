# @identity
# essence: tripod_stable(t) = triangle(foot_A, foot_B, foot_C) -- the first statically stable polygon
# desire: three legs forming a triangle of support -- minimum number for static stability
# critical_parameter: tripod foot positions -- three contacts define support triangle; mass must stay inside
# triggers: patrol_timer drives movement; tripod gait lifts one leg while two maintain stability
# emerges: the triangle IS stability -- three legs is where gait becomes geometrically solvable
# needs: MeshInstance3D [has]; triple IK chains [has]; tripod gait [has]; patrol [has]; VR interaction [missing]
# relationships: third in leg progression; first stable polygon -- two legs fall, three stand
# truth: three points define a plane -- the first polygon that does not need to negotiate with falling.

# three_leg_critter.gd
# Three-legged critter with STEPPING GAIT.
# Each leg plants on the ground, stays planted while body moves,
# then lifts and steps forward when stretched too far. Legs take turns.
#
# Architecture:
#   - FABRIK3D still solves bone chain to foot target (unchanged)
#   - We override the foot target positions each frame with gait logic
#   - SpringArm3D is still used to find where the ground IS (raycast down)
#   - But we don't let the foot just slide — we plant and step
#
# Legs at 120deg intervals:
#   Leg 0: 0deg (+X), Leg 1: 120deg (back-left), Leg 2: 240deg (back-right)
extends "res://commons/hazards/octapod_crawler/leg_walker_base.gd"



# Foot targets (Marker3Ds that FABRIK3D points at)
var _feet: Array[Marker3D] = []

# Per-leg stepping state
# "planted" = foot is on ground, not moving
# "stepping" = foot is in the air, moving to new position
var _leg_planted: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _leg_stepping: Array[bool] = [false, false, false]
var _leg_step_from: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _leg_step_to: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
var _leg_step_time: Array[float] = [0.0, 0.0, 0.0]

# Shoulder offsets (where each leg "wants" its foot, relative to body)
# These are in body-local space — the "home" position for each foot
# Leg 0: 0deg   → X=2.2, Z=0
# Leg 1: 120deg → X=-1.1, Z=1.905
# Leg 2: 240deg → X=-1.1, Z=-1.905
var _shoulders: Array[Vector3] = [
	Vector3(2.2, -2.2, 0),
	Vector3(-1.1, -2.2, 1.905),
	Vector3(-1.1, -2.2, -1.905),
]

func _ready() -> void:
	super._ready()

	# Body mesh
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.3, 0.4)
	mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.35, 0.25)
	material_override = mat

	# Skinned meshes
	_add_skinned_mesh($IK_leg_0/Armature/Skeleton3D, "LegMesh_0")
	_add_skinned_mesh($IK_leg_1/Armature/Skeleton3D, "LegMesh_1")
	_add_skinned_mesh($IK_leg_2/Armature/Skeleton3D, "LegMesh_2")

	# Get foot target references
	_feet = [
		$SpringArm3D_0/FootTarget_0,
		$SpringArm3D_1/FootTarget_1,
		$SpringArm3D_2/FootTarget_2,
	]

	# Debug spheres on feet
	for foot in _feet:
		_add_foot_vis(foot)

	# Initialize planted positions (feet start directly below shoulders)
	for i in range(3):
		_leg_planted[i] = global_transform * _shoulders[i]
		_leg_planted[i].y = _ground()  # on ground

	# Scene setup
	_build_scene()

	print("[ThreeLegCritter] Stepping gait ready — step_threshold=%.1f, step_duration=%.2f" % [
		step_threshold, step_duration])

func _process(delta: float) -> void:
	# ── Movement ──────────────────────────────────────────────────────────
	_walk(delta)

	# ── Step Gait ─────────────────────────────────────────────────────────
	_update_gait(delta)

# ═══════════════════════════════════════════════════════════════════════════
# STEPPING GAIT
# ═══════════════════════════════════════════════════════════════════════════

func _update_gait(delta: float) -> void:
	# Compute where each foot's "home" position is (in world space)
	# Home = directly below the shoulder, on the ground (Y=0)
	var homes: Array[Vector3] = []
	for i in range(3):
		var h: Vector3 = global_transform * _shoulders[i]
		h.y = _ground()
		homes.append(h)

	# Update any legs that are mid-step (animate the arc)
	for i in range(3):
		if _leg_stepping[i]:
			_leg_step_time[i] += delta / step_duration
			if _leg_step_time[i] >= 1.0:
				# Step complete — plant the foot
				_leg_step_time[i] = 1.0
				_leg_stepping[i] = false
				_leg_planted[i] = _leg_step_to[i]

	# Check if any planted leg needs to step (too far from home)
	# Only one leg steps at a time — the others stay planted
	var any_stepping: bool = _leg_stepping[0] or _leg_stepping[1] or _leg_stepping[2]

	if not any_stepping:
		# Find the leg furthest past the threshold
		var worst_idx: int = -1
		var worst_dist: float = step_threshold
		for i in range(3):
			var dist: float = _leg_planted[i].distance_to(homes[i])
			if dist > worst_dist:
				worst_dist = dist
				worst_idx = i
		if worst_idx >= 0:
			_begin_step(worst_idx, homes[worst_idx])

	# Position the foot targets
	for i in range(3):
		_position_foot(i, _feet[i], homes[i])

func _begin_step(leg_index: int, home: Vector3) -> void:
	_leg_stepping[leg_index] = true
	_leg_step_time[leg_index] = 0.0
	_leg_step_from[leg_index] = _leg_planted[leg_index]

	# Step target: home position + overshoot in the body's forward direction
	var forward: Vector3 = -global_transform.basis.z.normalized()
	_leg_step_to[leg_index] = home + forward * step_overshoot
	_leg_step_to[leg_index].y = _ground()  # plant on ground

func _position_foot(leg_index: int, foot_target: Marker3D, _home: Vector3) -> void:
	if not is_instance_valid(foot_target):
		return

	var pos: Vector3
	if _leg_stepping[leg_index]:
		# Interpolate from old position to new position along an arc
		var t: float = _leg_step_time[leg_index]
		# Smooth step for nicer motion
		var smooth_t: float = t * t * (3.0 - 2.0 * t)
		pos = _leg_step_from[leg_index].lerp(_leg_step_to[leg_index], smooth_t)
		# Add vertical arc (parabola: peaks at t=0.5)
		var arc: float = 4.0 * t * (1.0 - t)  # 0 at t=0 and t=1, 1 at t=0.5
		pos.y += step_height * arc
	else:
		# Planted — foot stays at planted position
		pos = _leg_planted[leg_index]

	foot_target.global_position = pos

# ═══════════════════════════════════════════════════════════════════════════
# SKINNED MESH
# ═══════════════════════════════════════════════════════════════════════════

func _add_skinned_mesh(skeleton: Skeleton3D, mesh_name: String) -> void:
	var skin := Skin.new()
	skin.set_bind_count(6)
	for i in range(6):
		var bname: String = "Bone" if i == 0 else "Bone.%03d" % i
		skin.set_bind_name(i, bname)
		skin.set_bind_bone(i, -1)
		skin.set_bind_pose(i, Transform3D(Basis.IDENTITY, Vector3(0, -float(i), 0)))

	var leg_mesh: ArrayMesh = _make_tapered_tube(6, 1.0, 0.10, 0.025, 8)

	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.5, 0.2, 0.3)
	leg_mat.roughness = 0.5
	leg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED

	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = leg_mesh
	mi.skin = skin
	mi.skeleton = NodePath("..")
	mi.material_override = leg_mat
	skeleton.add_child(mi)

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

func _add_foot_vis(foot: Marker3D) -> void:
	var vis := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	vis.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1, 0.3, 0.1)
	mat.emission_enabled = true
	mat.emission = Color(1, 0.2, 0.1)
	mat.emission_energy_multiplier = 2.0
	vis.material_override = mat
	foot.add_child(vis)

# ═══════════════════════════════════════════════════════════════════════════
# SCENE SETUP
# ═══════════════════════════════════════════════════════════════════════════

func _build_scene() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return
	var parent: Node = get_parent()
	if parent != scene_root:
		return

	# Floor
	var floor_body := StaticBody3D.new()
	floor_body.name = "Floor"
	floor_body.collision_layer = 1
	var fm := MeshInstance3D.new()
	var fb := BoxMesh.new()
	fb.size = Vector3(30, 0.1, 30)
	fm.mesh = fb
	fm.position.y = -0.05
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.35, 0.35, 0.38)
	fm.material_override = fmat
	floor_body.add_child(fm)
	var fc := CollisionShape3D.new()
	var fs := BoxShape3D.new()
	fs.size = Vector3(30, 0.1, 30)
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
		cam.position = Vector3(5, 5, 8)
		cam.look_at(Vector3(0, 1, 0))
		cam.current = true
		parent.add_child(cam)
