# @identity
# essence: bipedal_balance(t) = alternate(foot_L, foot_R) -- constant negotiation with falling
# desire: two legs in perpetual controlled falling -- the human gait's instability made visible
# critical_parameter: _foot_L / _foot_R IK targets -- alternating support creates the bipedal problem
# triggers: gait cycle alternates feet; patrol_timer drives direction; each step is a caught fall
# emerges: bipedal locomotion as managed instability -- walking is falling and catching yourself
# needs: MeshInstance3D [has]; dual IK chains [has]; alternating gait [has]; patrol [has]; VR interaction [missing]
# relationships: second in leg progression; introduces bilateral symmetry
# truth: two legs means constant falling -- every step is a crisis of balance resolved just in time.

# two_leg_critter.gd
# Two-legged critter with STEPPING GAIT.
# Each leg plants on the ground, stays planted while body moves,
# then lifts and steps forward when stretched too far. Legs alternate.
#
# Architecture:
#   - FABRIK3D still solves bone chain to foot target (unchanged)
#   - We override the foot target positions each frame with gait logic
#   - SpringArm3D is still used to find where the ground IS (raycast down)
#   - But we don't let the foot just slide — we plant and step
extends MeshInstance3D

@export var move_speed: float = 2.0
@export var turn_speed: float = 40.0
@export var patrol_speed: float = 1.0

## Step gait parameters
@export_group("Gait")
@export var step_threshold: float = 1.5   ## How far foot can be from "home" before stepping
@export var step_height: float = 1.0      ## How high the foot lifts during a step
@export var step_duration: float = 0.25   ## How long a step takes (seconds)
@export var step_overshoot: float = 0.5   ## How far ahead of home to place foot

var _patrol_timer: float = 0.0
var _patrol_angle: float = 0.0
var _rng := RandomNumberGenerator.new()

# Foot targets (Marker3Ds that FABRIK3D points at)
var _foot_L: Marker3D = null
var _foot_R: Marker3D = null

# Per-leg stepping state
# "planted" = foot is on ground, not moving
# "stepping" = foot is in the air, moving to new position
var _leg_planted: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]  # [L, R] planted world positions
var _leg_stepping: Array[bool] = [false, false]  # is this leg mid-step?
var _leg_step_from: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]  # step start pos
var _leg_step_to: Array[Vector3] = [Vector3.ZERO, Vector3.ZERO]    # step end pos
var _leg_step_time: Array[float] = [0.0, 0.0]  # progress 0→1

# Shoulder offsets (where each leg "wants" its foot, relative to body)
# These are in body-local space — the "home" position for each foot
var _shoulder_L: Vector3 = Vector3(2.2, -2.2, 0)   # +X side, down to ground
var _shoulder_R: Vector3 = Vector3(-2.2, -2.2, 0)   # -X side, down to ground

func _ready() -> void:
	_rng.randomize()
	_patrol_angle = _rng.randf_range(0, TAU)

	# Body mesh
	var box := BoxMesh.new()
	box.size = Vector3(0.6, 0.3, 0.4)
	mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.25, 0.35)
	material_override = mat

	# Skinned meshes
	_add_skinned_mesh($IK_leg_L/Armature/Skeleton3D, "LegMesh_L")
	_add_skinned_mesh($IK_leg_R/Armature/Skeleton3D, "LegMesh_R")

	# Get foot target references
	_foot_L = $SpringArm3D_L/FootTarget_L
	_foot_R = $SpringArm3D_R/FootTarget_R

	# Debug spheres on feet
	_add_foot_vis(_foot_L)
	_add_foot_vis(_foot_R)

	# Initialize planted positions (feet start directly below shoulders)
	_leg_planted[0] = global_transform * _shoulder_L
	_leg_planted[0].y = 0.0  # on ground
	_leg_planted[1] = global_transform * _shoulder_R
	_leg_planted[1].y = 0.0

	# Scene setup
	_build_scene()

	print("[TwoLegCritter] Stepping gait ready — step_threshold=%.1f, step_duration=%.2f" % [
		step_threshold, step_duration])

func _process(delta: float) -> void:
	# ── Movement ──────────────────────────────────────────────────────────
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input.length_squared() > 0.01:
		position += -basis.z * input.y * delta * move_speed
		rotation.y += deg_to_rad(-input.x * delta * turn_speed)
	else:
		_patrol_timer += delta
		if _patrol_timer >= 3.0:
			_patrol_timer = 0.0
			_patrol_angle += _rng.randf_range(-PI * 0.5, PI * 0.5)
		rotation.y = lerp_angle(rotation.y, _patrol_angle, 1.0 * delta)
		position += -basis.z * delta * patrol_speed

	# ── Step Gait ─────────────────────────────────────────────────────────
	_update_gait(delta)

# ═══════════════════════════════════════════════════════════════════════════
# STEPPING GAIT
# ═══════════════════════════════════════════════════════════════════════════

func _update_gait(delta: float) -> void:
	# Compute where each foot's "home" position is (in world space)
	# Home = directly below the shoulder, on the ground (Y=0)
	var home_L: Vector3 = global_transform * _shoulder_L
	home_L.y = 0.0
	var home_R: Vector3 = global_transform * _shoulder_R
	home_R.y = 0.0

	# Update any legs that are mid-step (animate the arc)
	for i in range(2):
		if _leg_stepping[i]:
			_leg_step_time[i] += delta / step_duration
			if _leg_step_time[i] >= 1.0:
				# Step complete — plant the foot
				_leg_step_time[i] = 1.0
				_leg_stepping[i] = false
				_leg_planted[i] = _leg_step_to[i]

	# Check if any planted leg needs to step (too far from home)
	# Only one leg steps at a time — the other stays planted
	var any_stepping: bool = _leg_stepping[0] or _leg_stepping[1]

	if not any_stepping:
		# Check which leg is furthest from home
		var dist_L: float = _leg_planted[0].distance_to(home_L)
		var dist_R: float = _leg_planted[1].distance_to(home_R)

		# Step the leg that's furthest past the threshold
		if dist_L > step_threshold and dist_L >= dist_R:
			_begin_step(0, home_L)
		elif dist_R > step_threshold:
			_begin_step(1, home_R)

	# Position the foot targets
	_position_foot(0, _foot_L, home_L)
	_position_foot(1, _foot_R, home_R)

func _begin_step(leg_index: int, home: Vector3) -> void:
	_leg_stepping[leg_index] = true
	_leg_step_time[leg_index] = 0.0
	_leg_step_from[leg_index] = _leg_planted[leg_index]

	# Step target: home position + overshoot in the body's forward direction
	var forward: Vector3 = -global_transform.basis.z.normalized()
	_leg_step_to[leg_index] = home + forward * step_overshoot
	_leg_step_to[leg_index].y = 0.0  # plant on ground

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
