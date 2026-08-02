extends Node3D
class_name TentaclePlacer

# @identity
# essence: an off-white animal-robot tentacle anchored on a heavy pedestal. Six FABRIK bones taper like a spine; segmented vertebra rings ring each joint; the tip terminates in a small articulated claw. The Target Marker3D is the one truth — every frame the script smoothly nudges the target toward whatever the cycle's current GOAL is, and a manual FABRIK solver folds the chain so the tip lands on that target. After placing N pyramids the cycle exhausts; the target drifts back to a rest pose and the arm idles, watching.
# desire: replace "predator that paces" with "experimenter that places, then watches". The placement is finite — three pyramids, then stillness. The room ends up with three new objects, the arm rests, the player can now investigate without interruption.
# critical_parameter: place_positions[] — where pyramids land. sky_height — how far up the tip rises between placements. travel_speed — how aggressively the target chases its goal (exponential lerp weight per second; lower = slower, more deliberate). pyramid_size / pyramid_height — shape of the placed primitive.
# triggers: _ready() builds the queue of goals from place_positions + sky waypoints; _physics_process advances the target along the queue and solves the IK chain; placed() / rendered() signals fire at the meaningful beats. After the queue is consumed the arm drifts to rest_target and parks.
# emerges: the visual rhythm is now CONTINUOUS — target always moving toward its current goal, never stopping at exact times. The arm reads as alive and deliberate rather than stop-motion. The three-pyramid finite scope makes the room a small ritual: one cycle, three objects, then quiet.
# needs: Skeleton3D from the .tscn [present]; manual FABRIK solver [present]; goal queue + exponential lerp [present]; finite cycle that idles after placements [present]; signals for downstream lab logic [present]
# relationships: replaces path_builder_foe in Primitives_Polythedra; sibling to robot_arm (static pose) and octapod_crawler (eight-leg gait — its FABRIK3D inspired this artifact, but its built-in solver doesn't work for single chains so we hand-roll FABRIK)
# truth: the tentacle is the lab's gesture that primitives are FETCHED — but only a finite number of them. After the show ends, the arm rests. Volume has been authored; the witness can now contemplate it.

## Continuous-motion FABRIK tentacle that places a finite number of
## pyramids then idles. Pattern adapted from tentacle_test.gd's
## exponential target-chase: the target NEVER stops moving — it
## asymptotically approaches its current goal. When close enough to
## the goal, advance to the next goal in the queue.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Placements")
## Lab-local floor positions where pyramids are placed, in order.
## Y=0 puts the pyramid's BASE flush with the floor; with the default
## pyramid_height of -0.5 (apex below base), the apex sticks DOWN into
## the floor — an inverted-pyramid "fang" half-buried in the ground.
@export var place_positions: PackedVector3Array = PackedVector3Array([
	Vector3(-1.5, 0.0, 0),
	Vector3(0.0, 0.0, 0),
	Vector3(1.5, 0.0, 0),
])
## How far above each place point the tip rises during sky pickups.
@export var sky_height: float = 7.0
## Where the arm drifts to after all placements are done. Tip stands
## roughly straight up at this height — the "idle" pose.
@export var rest_target: Vector3 = Vector3(0.0, 6.0, 0.0)

@export_group("Pacing")
## Lerp weight per second for the target's chase toward its current
## goal. Higher = faster approach; lower = slower, more deliberate.
## tentacle_test.gd uses 3.0 for a brisk follow; 0.6 reads as ritual.
@export var travel_speed: float = 0.6
## Once the target is within this distance of the current goal,
## consider the goal "reached" and advance to the next after dwell.
@export var arrive_threshold: float = 0.15
## Dwell time at each goal before advancing. At the place-position
## goals this is when the pyramid materialises.
@export var dwell_seconds: float = 1.5

@export_group("Placed pyramid")
## Base edge length. Default 1.0 (was 0.6) — larger placed primitives.
@export var pyramid_size: float = 1.0
## Apex Y offset from the base. Default -0.5 — pyramid points DOWN
## into the floor like a stalactite half-buried in the ground, the
## inverse of pyramid_edit's default upward apex. Set positive for a
## normal point-up pyramid.
@export var pyramid_height: float = -0.5
@export var pyramid_color: Color = Color(1.0, 0.8, 0.2)
## If > 0, each pyramid auto-removes after this many seconds. 0 = persist.
@export var pyramid_lifetime: float = 0.0

@export_group("Rendered cube (at sky goal)")
## A small cube materialises at the tip during each sky-grab dwell —
## the "fetched from thin air" object. Removed when the tip touches
## the placement position; the pyramid takes its place.
@export var cube_size: float = 0.32
@export var cube_color: Color = Color(0.55, 0.78, 0.95, 0.85)

@export_group("Tentacle visual")
@export_range(4, 16) var radial_segments: int = 10
@export var base_radius: float = 0.18
@export var tip_radius: float = 0.045
@export var body_color: Color = Color(0.945, 0.940, 0.928)
@export var joint_ring_color: Color = Color(0.18, 0.20, 0.24)
@export var accent_color: Color = Color(0.95, 0.42, 0.10)

@export_group("Pedestal")
@export var show_pedestal: bool = true
@export var pedestal_radius: float = 0.42
@export var pedestal_height: float = 0.32

@export_group("Claw")
@export var show_claw: bool = true
@export var claw_finger_count: int = 3
@export var claw_finger_length: float = 0.22
## How far the hand sits beyond the end of the bone chain, in bone
## segments. 1.0 = one full segment of empty space + thin wrist rod
## between the arm and the hand. 0 = hand flush with the arm tip.
@export var claw_offset_segments: float = 1.0
## Diameter of the thin wrist rod that bridges arm-tip → hand when
## claw_offset_segments > 0.
@export var wrist_rod_radius: float = 0.025

@export_group("Self-avoidance")
## Maximum bend angle (degrees) between consecutive bone segments.
## Lower = stiffer arc, no curling back on itself. 60° is a clean
## tentacle reach; 90° lets the chain bend hard but still avoids
## complete folds; 180° = no constraint (can spiral / self-intersect).
@export_range(10.0, 180.0) var max_joint_angle_deg: float = 60.0

@export_group("Debug")
@export var debug_log: bool = false

@export_group("Measurement")
## NOT AN AXIS — the precondition for ever having one.
##
## This artifact's silhouette is a function of WALL-CLOCK TIME: _physics_process
## exponentially chases the target toward its current goal every frame, so the arm a
## still catches depends on how many physics ticks elapsed between load and shutter.
## A DNA sweep renders each variant in its own process, which means the pose differs
## between variants for reasons that have nothing to do with the axis — the sweep would
## measure the arm's motion and report a confident BITE about the wrong thing. The same
## failure a `randf()` in a build path causes, with the clock as the random source.
##
## With this true the chase and the goal queue are skipped and the target is pinned at
## `rest_target`, so the chain solves to one reproducible pose every run. Default false
## reproduces today's behaviour exactly — nothing placed in a map changes.
@export var static_pose: bool = false

# ── Constants ─────────────────────────────────────────────────────────

const BONE_COUNT: int = 6
const BONE_SPACING: float = 1.0
const FABRIK_ITERATIONS: int = 8
const FABRIK_TOLERANCE: float = 0.001

# ── Signals ───────────────────────────────────────────────────────────

signal rendered(index: int, world_position: Vector3)
signal placed(index: int, world_position: Vector3)
## All placements done; arm has begun drifting to rest_target.
signal cycle_finished()

# ── Goal queue ────────────────────────────────────────────────────────

class Goal:
	var pos: Vector3
	var kind: String           # "sky" or "place" or "rest"
	var place_index: int       # only meaningful when kind == "place" or "sky"
	func _init(p: Vector3, k: String, idx: int = -1) -> void:
		pos = p
		kind = k
		place_index = idx

var _skeleton: Skeleton3D = null
var _target: Marker3D = null
var _claw_root: Node3D = null
var _carried_cube: MeshInstance3D = null
var _goals: Array = []
var _goal_idx: int = 0
var _dwell_time: float = 0.0
var _arrived: bool = false
var _rendered_announced: bool = false
var _pyramid_pool: Array = []
var _cycle_done: bool = false

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_skeleton = $Armature/Skeleton3D
	_target = $Target
	if _skeleton == null or _target == null:
		push_warning("TentaclePlacer: scene missing Armature/Skeleton3D or Target")
		return
	_build_pedestal()
	_attach_skinned_mesh()
	if show_claw:
		_build_claw()
	_build_goal_queue()
	# Start the target at the rest pose so the first visible motion is
	# the tip rising toward sky_0.
	_target.position = rest_target
	if debug_log:
		print("[tentacle] _ready() — %d goals queued. travel_speed=%.2f"
			% [_goals.size(), travel_speed])
		for i in range(_goals.size()):
			var g: Goal = _goals[i]
			print("  goal[%d] %s @ %s" % [i, g.kind, g.pos])


func _build_goal_queue() -> void:
	_goals.clear()
	# For each placement, queue sky→place. After all placements, the
	# script drifts to rest_target via the idle behaviour (not in queue).
	for i in range(place_positions.size()):
		var p: Vector3 = place_positions[i]
		_goals.append(Goal.new(Vector3(p.x, p.y + sky_height, p.z), "sky", i))
		_goals.append(Goal.new(p, "place", i))
	_goal_idx = 0
	_dwell_time = 0.0
	_arrived = false
	_rendered_announced = false
	_cycle_done = false


# ── Per-frame: smooth chase + IK solve ───────────────────────────────

func _physics_process(delta: float) -> void:
	if _target == null:
		return
	# Frozen for measurement: one pose, solved from a fixed target, every run.
	if static_pose:
		_target.position = rest_target
		_solve_chain_manual()
		return
	# Determine current goal.
	var goal_pos: Vector3
	var goal_kind: String = "rest"
	if _cycle_done:
		goal_pos = rest_target
	elif _goal_idx < _goals.size():
		var g: Goal = _goals[_goal_idx]
		goal_pos = g.pos
		goal_kind = g.kind
	else:
		# Queue exhausted — drift to rest.
		goal_pos = rest_target
		if not _cycle_done:
			_cycle_done = true
			cycle_finished.emit()
			if debug_log:
				print("[tentacle] cycle_finished — drifting to rest_target")

	# Continuous exponential chase toward goal. Same pattern as
	# tentacle_test.gd. Target never stops moving until distance is
	# numerically negligible.
	var w: float = clampf(travel_speed * delta, 0.0, 0.5)
	_target.position = _target.position.lerp(goal_pos, w)

	# Solve the chain so bones follow the target.
	_solve_chain_manual()

	if _cycle_done:
		return

	# Goal arrival logic. Once near the goal, dwell — at place goals,
	# spawn the pyramid (once per arrival); at sky goals, render the
	# cube (once per arrival). Then advance to next goal.
	var dist: float = _target.position.distance_to(goal_pos)
	if not _arrived:
		if dist < arrive_threshold:
			_arrived = true
			_dwell_time = 0.0
			_rendered_announced = false
			_on_arrived(goal_kind)
	else:
		_dwell_time += delta
		if _dwell_time >= dwell_seconds:
			# Advance to next goal.
			_goal_idx += 1
			_arrived = false
			_dwell_time = 0.0


func _on_arrived(kind: String) -> void:
	var g: Goal = _goals[_goal_idx]
	match kind:
		"sky":
			# Render the cube at the tip — visible "fetched from air".
			_render_cube_at_tip()
			rendered.emit(g.place_index,
				_carried_cube.global_position if _carried_cube else global_position)
			if debug_log:
				print("[tentacle] arrived sky[%d] — cube rendered" % g.place_index)
		"place":
			# Dispose cube, materialise pyramid.
			_dispose_carried_cube()
			_spawn_pyramid_at(g.pos, g.place_index)
			if debug_log:
				print("[tentacle] arrived place[%d] — pyramid placed" % g.place_index)
		_:
			pass


# ── Manual FABRIK ────────────────────────────────────────────────────
# Godot 4.6's built-in FABRIK3D doesn't reliably solve single-chain
# setups (see commit history). This hand-rolled FABRIK runs the same
# backward+forward algorithm in skeleton-local space, deterministic
# and per-frame. Same approach as the classic 2D-game tentacle solver
# popularised by Aristidou & Lasenby (2011).

func _solve_chain_manual() -> void:
	if _skeleton == null or _target == null:
		return
	var target: Vector3 = _skeleton.to_local(_target.global_position)

	# Step 1: read current bone positions in skeleton space.
	var positions: PackedVector3Array = PackedVector3Array()
	var cur_basis: Basis = Basis.IDENTITY
	var cur_pos: Vector3 = Vector3.ZERO
	positions.append(cur_pos)
	for i in range(BONE_COUNT):
		cur_basis = cur_basis * Basis(_skeleton.get_bone_pose_rotation(i))
		cur_pos += cur_basis * Vector3(0, BONE_SPACING, 0)
		positions.append(cur_pos)

	var total_len: float = BONE_SPACING * float(BONE_COUNT)
	var reach: float = target.length()

	if reach > total_len:
		# Unreachable — straighten the chain at the target.
		var dir: Vector3 = target.normalized() if reach > 0.001 else Vector3.UP
		positions[0] = Vector3.ZERO
		for i in range(1, BONE_COUNT + 1):
			positions[i] = positions[i - 1] + dir * BONE_SPACING
	else:
		var max_angle_rad: float = deg_to_rad(max_joint_angle_deg)
		for _iter in range(FABRIK_ITERATIONS):
			positions[BONE_COUNT] = target
			for i in range(BONE_COUNT - 1, -1, -1):
				var d: Vector3 = positions[i] - positions[i + 1]
				if d.length_squared() < 0.000001:
					d = -Vector3.UP
				positions[i] = positions[i + 1] + d.normalized() * BONE_SPACING
			positions[0] = Vector3.ZERO
			for i in range(1, BONE_COUNT + 1):
				var d2: Vector3 = positions[i] - positions[i - 1]
				if d2.length_squared() < 0.000001:
					d2 = Vector3.UP
				positions[i] = positions[i - 1] + d2.normalized() * BONE_SPACING
			# Enforce joint angle limits so consecutive bones can't bend
			# more than max_joint_angle_deg apart — stops the chain from
			# curling back on itself / self-intersecting.
			_apply_joint_angle_limits(positions, max_angle_rad)
			if positions[BONE_COUNT].distance_to(target) < FABRIK_TOLERANCE:
				break

	# Step 3: convert segment directions back to pose rotations.
	var parent_basis: Basis = Basis.IDENTITY
	for i in range(BONE_COUNT):
		var seg_world: Vector3 = positions[i + 1] - positions[i]
		if seg_world.length_squared() < 0.000001:
			_skeleton.set_bone_pose_rotation(i, Quaternion.IDENTITY)
			continue
		var dir_in_parent: Vector3 = parent_basis.inverse() * seg_world.normalized()
		var local_rot: Quaternion = _quat_from_to(Vector3.UP, dir_in_parent)
		_skeleton.set_bone_pose_rotation(i, local_rot)
		parent_basis = parent_basis * Basis(local_rot)


## Clamp the angle between each consecutive segment direction so the
## chain can't fold sharper than `max_angle_rad`. Walks root → tip
## (the order FABRIK's forward pass produces). For each bone except
## the first, computes the angle between (this segment) and (parent
## segment); if it exceeds the limit, rotates the bone i+1 endpoint
## back toward the parent direction.
func _apply_joint_angle_limits(positions: PackedVector3Array, max_angle_rad: float) -> void:
	if max_angle_rad >= PI - 0.001:
		return  # no constraint
	for i in range(1, BONE_COUNT):
		var parent_dir: Vector3 = positions[i] - positions[i - 1]
		var seg_dir: Vector3 = positions[i + 1] - positions[i]
		if parent_dir.length_squared() < 0.000001 or seg_dir.length_squared() < 0.000001:
			continue
		var pn: Vector3 = parent_dir.normalized()
		var sn: Vector3 = seg_dir.normalized()
		var cos_angle: float = clamp(pn.dot(sn), -1.0, 1.0)
		var angle: float = acos(cos_angle)
		if angle <= max_angle_rad:
			continue
		# Rotate the segment direction toward the parent direction so
		# the bend equals exactly max_angle_rad. Axis is perpendicular
		# to both directions (their cross product).
		var axis: Vector3 = sn.cross(pn)
		if axis.length_squared() < 0.000001:
			continue
		var excess: float = angle - max_angle_rad
		var corrected_dir: Vector3 = sn.rotated(axis.normalized(), excess).normalized()
		positions[i + 1] = positions[i] + corrected_dir * BONE_SPACING


func _quat_from_to(from: Vector3, to: Vector3) -> Quaternion:
	var f: Vector3 = from.normalized()
	var t: Vector3 = to.normalized()
	var d: float = f.dot(t)
	if d > 0.9999:
		return Quaternion.IDENTITY
	if d < -0.9999:
		var axis: Vector3 = f.cross(Vector3.RIGHT)
		if axis.length_squared() < 0.0001:
			axis = f.cross(Vector3.FORWARD)
		return Quaternion(axis.normalized(), PI)
	var axis2: Vector3 = f.cross(t).normalized()
	var angle: float = acos(clamp(d, -1.0, 1.0))
	return Quaternion(axis2, angle)


# ── Cube + pyramid spawners ──────────────────────────────────────────

func _render_cube_at_tip() -> void:
	if _carried_cube != null and is_instance_valid(_carried_cube):
		return
	var cube := MeshInstance3D.new()
	cube.name = "RenderedCube"
	var bm := BoxMesh.new()
	bm.size = Vector3.ONE * cube_size
	cube.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cube_color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if cube_color.a < 1.0 else BaseMaterial3D.TRANSPARENCY_DISABLED
	mat.emission_enabled = true
	mat.emission = cube_color
	mat.emission_energy_multiplier = 0.6
	mat.roughness = 0.3
	mat.metallic = 0.0
	cube.material_override = mat
	_target.add_child(cube)
	cube.position = Vector3.ZERO
	_carried_cube = cube


func _dispose_carried_cube() -> void:
	if _carried_cube and is_instance_valid(_carried_cube):
		_carried_cube.queue_free()
	_carried_cube = null


func _spawn_pyramid_at(local_pos: Vector3, place_index: int) -> void:
	var pyramid := MeshInstance3D.new()
	pyramid.name = "Pyramid_%d_%d" % [place_index, _pyramid_pool.size()]
	pyramid.mesh = _build_pyramid_mesh()
	var mat := StandardMaterial3D.new()
	mat.albedo_color = pyramid_color
	mat.emission_enabled = true
	mat.emission = pyramid_color * 0.3
	mat.roughness = 0.5
	mat.metallic = 0.1
	pyramid.material_override = mat
	pyramid.position = local_pos
	add_child(pyramid)
	_pyramid_pool.append(pyramid)
	if pyramid_lifetime > 0.0:
		var timer := get_tree().create_timer(pyramid_lifetime)
		timer.timeout.connect(func ():
			if is_instance_valid(pyramid):
				pyramid.queue_free()
			_pyramid_pool.erase(pyramid))
	placed.emit(place_index, pyramid.global_position)


func _build_pyramid_mesh() -> ArrayMesh:
	# 5 verts (4 base corners + apex). Same winding as pyramid_edit so
	# the placed pyramid is visually identical to the editable one.
	var h: float = pyramid_size * 0.5
	var b0 := Vector3(-h, 0, -h)
	var b1 := Vector3( h, 0, -h)
	var b2 := Vector3( h, 0,  h)
	var b3 := Vector3(-h, 0,  h)
	var apex := Vector3(0, pyramid_height, 0)
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var add_tri := func (a: Vector3, b: Vector3, c: Vector3) -> void:
		var n: Vector3 = (b - a).cross(c - a).normalized()
		verts.append(a); normals.append(n)
		verts.append(b); normals.append(n)
		verts.append(c); normals.append(n)
	# Base — wind so the visible side depends on apex sign.
	if pyramid_height >= 0.0:
		add_tri.call(b0, b2, b1); add_tri.call(b0, b3, b2)
	else:
		add_tri.call(b0, b1, b2); add_tri.call(b0, b2, b3)
	# Sides
	add_tri.call(b0, b1, apex); add_tri.call(b1, b2, apex)
	add_tri.call(b2, b3, apex); add_tri.call(b3, b0, apex)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# ── Pedestal ──────────────────────────────────────────────────────────

func _build_pedestal() -> void:
	if not show_pedestal:
		return
	var neck_h: float = pedestal_height * 0.55
	var flange_h: float = pedestal_height * 0.45
	var neck := MeshInstance3D.new()
	neck.name = "PedestalNeck"
	var nm := CylinderMesh.new()
	nm.top_radius = pedestal_radius * 0.62
	nm.bottom_radius = pedestal_radius * 0.85
	nm.height = neck_h
	neck.mesh = nm
	var neck_mat := StandardMaterial3D.new()
	neck_mat.albedo_color = Color(0.18, 0.18, 0.22)
	neck_mat.roughness = 0.5
	neck_mat.metallic = 0.65
	neck.material_override = neck_mat
	neck.position = Vector3(0.0, -neck_h * 0.5, 0.0)
	add_child(neck)
	var flange := MeshInstance3D.new()
	flange.name = "PedestalFlange"
	var fm := CylinderMesh.new()
	fm.top_radius = pedestal_radius
	fm.bottom_radius = pedestal_radius * 1.20
	fm.height = flange_h
	flange.mesh = fm
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.12, 0.13, 0.16)
	dark_mat.roughness = 0.55
	dark_mat.metallic = 0.7
	flange.material_override = dark_mat
	flange.position = Vector3(0.0, -neck_h - flange_h * 0.5, 0.0)
	add_child(flange)
	for i in range(3):
		var ring := MeshInstance3D.new()
		ring.name = "PedestalRib_%d" % i
		var rm := CylinderMesh.new()
		var rr: float = pedestal_radius * (1.05 + 0.06 * float(i))
		rm.top_radius = rr
		rm.bottom_radius = rr
		rm.height = 0.012
		ring.mesh = rm
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = accent_color
		rmat.emission_enabled = true
		rmat.emission = accent_color
		rmat.emission_energy_multiplier = 1.6
		ring.material_override = rmat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ring.position = Vector3(0.0, -neck_h - flange_h + 0.08 * float(i), 0.0)
		add_child(ring)


# ── Skinned tentacle mesh + joint rings ──────────────────────────────

func _attach_skinned_mesh() -> void:
	var skin: Skin = _build_skin()
	var mesh: ArrayMesh = _build_tentacle_mesh()
	var mat: StandardMaterial3D = _build_tentacle_material()
	var mi := MeshInstance3D.new()
	mi.name = "TentacleMesh"
	mi.mesh = mesh
	mi.skin = skin
	mi.skeleton = NodePath("..")
	mi.material_override = mat
	mi.position = Vector3.ZERO
	_skeleton.add_child(mi)

	# Joint rings — ride the IK solve via BoneAttachment3D.
	for i in range(1, BONE_COUNT):
		var att := BoneAttachment3D.new()
		att.bone_idx = i
		att.bone_name = "Bone" if i == 0 else "Bone.%03d" % i
		_skeleton.add_child(att)
		var ring := MeshInstance3D.new()
		ring.name = "JointRing_%d" % i
		var t: float = float(i) / float(BONE_COUNT - 1)
		var rr: float = lerp(base_radius * 1.18, tip_radius * 1.30, t)
		var tm := TorusMesh.new()
		tm.inner_radius = rr * 0.85
		tm.outer_radius = rr
		ring.mesh = tm
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = joint_ring_color
		rmat.emission_enabled = true
		rmat.emission = joint_ring_color
		rmat.emission_energy_multiplier = 1.4
		ring.material_override = rmat
		ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		att.add_child(ring)


func _build_skin() -> Skin:
	var skin := Skin.new()
	skin.set_bind_count(BONE_COUNT)
	for i in range(BONE_COUNT):
		var bname: String = "Bone" if i == 0 else "Bone.%03d" % i
		skin.set_bind_name(i, bname)
		skin.set_bind_bone(i, -1)
		var cum_y: float = -BONE_SPACING * float(i)
		skin.set_bind_pose(i, Transform3D(Basis.IDENTITY, Vector3(0, cum_y, 0)))
	return skin


func _build_tentacle_mesh() -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var bones_arr := PackedInt32Array()
	var weights_arr := PackedFloat32Array()
	for ring in range(BONE_COUNT):
		var y: float = BONE_SPACING * float(ring)
		var t: float = float(ring) / float(BONE_COUNT - 1)
		var radius: float = lerp(base_radius, tip_radius, t)
		for seg in range(radial_segments):
			var angle: float = TAU * float(seg) / float(radial_segments)
			verts.append(Vector3(cos(angle) * radius, y, sin(angle) * radius))
			normals.append(Vector3(cos(angle), 0, sin(angle)).normalized())
			bones_arr.append(ring); bones_arr.append(0); bones_arr.append(0); bones_arr.append(0)
			weights_arr.append(1.0); weights_arr.append(0.0); weights_arr.append(0.0); weights_arr.append(0.0)
	var indices := PackedInt32Array()
	for ring in range(BONE_COUNT - 1):
		for seg in range(radial_segments):
			var curr: int = ring * radial_segments + seg
			var next_s: int = ring * radial_segments + (seg + 1) % radial_segments
			var above: int = (ring + 1) * radial_segments + seg
			var above_next: int = (ring + 1) * radial_segments + (seg + 1) % radial_segments
			indices.append(curr); indices.append(above); indices.append(next_s)
			indices.append(next_s); indices.append(above); indices.append(above_next)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_BONES] = bones_arr
	arrays[Mesh.ARRAY_WEIGHTS] = weights_arr
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _build_tentacle_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = body_color
	mat.roughness = 0.55
	mat.metallic = 0.18
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


# ── Claw ──────────────────────────────────────────────────────────────

func _build_claw() -> void:
	var att := BoneAttachment3D.new()
	att.bone_idx = BONE_COUNT - 1
	att.bone_name = "Bone.%03d" % (BONE_COUNT - 1)
	_skeleton.add_child(att)

	# Hand sits one segment (or `claw_offset_segments`) beyond the arm
	# tip. With a positive offset, the gap is bridged by a thin wrist
	# rod so the hand visually connects to the arm.
	var arm_tip_local: Vector3 = Vector3(0.0, BONE_SPACING, 0.0)
	var hand_local: Vector3 = Vector3(0.0, BONE_SPACING * (1.0 + claw_offset_segments), 0.0)
	if claw_offset_segments > 0.001:
		var rod := MeshInstance3D.new()
		rod.name = "WristRod"
		var rm := CylinderMesh.new()
		rm.top_radius = wrist_rod_radius
		rm.bottom_radius = wrist_rod_radius
		rm.height = BONE_SPACING * claw_offset_segments
		rod.mesh = rm
		var rmat := StandardMaterial3D.new()
		rmat.albedo_color = Color(0.20, 0.21, 0.25)
		rmat.roughness = 0.35
		rmat.metallic = 0.7
		rod.material_override = rmat
		# Cylinder default axis is +Y already.
		rod.position = (arm_tip_local + hand_local) * 0.5
		att.add_child(rod)

	_claw_root = Node3D.new()
	_claw_root.name = "Claw"
	_claw_root.position = hand_local
	att.add_child(_claw_root)
	var hub := MeshInstance3D.new()
	hub.name = "Wrist"
	var hm := SphereMesh.new()
	hm.radius = tip_radius * 1.6
	hm.height = tip_radius * 3.2
	hub.mesh = hm
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.20, 0.21, 0.25)
	hmat.roughness = 0.35
	hmat.metallic = 0.75
	hub.material_override = hmat
	_claw_root.add_child(hub)
	var finger_mat := StandardMaterial3D.new()
	finger_mat.albedo_color = body_color
	finger_mat.roughness = 0.45
	finger_mat.metallic = 0.55
	for i in range(maxi(2, claw_finger_count)):
		var angle: float = TAU * float(i) / float(maxi(2, claw_finger_count))
		var finger := Node3D.new()
		finger.name = "Finger_%d" % i
		var outward_axis := Vector3(cos(angle), 0, sin(angle))
		finger.transform.basis = Basis(outward_axis.cross(Vector3.UP).normalized(), deg_to_rad(30.0))
		_claw_root.add_child(finger)
		var seg_len: float = claw_finger_length * 0.5
		var seg_thick: float = tip_radius * 0.6
		var k1 := MeshInstance3D.new()
		var k1m := BoxMesh.new()
		k1m.size = Vector3(seg_thick, seg_len, seg_thick)
		k1.mesh = k1m
		k1.material_override = finger_mat
		k1.position = Vector3(0, seg_len * 0.5, 0)
		finger.add_child(k1)
		var k2 := MeshInstance3D.new()
		var k2m := BoxMesh.new()
		k2m.size = Vector3(seg_thick * 0.85, seg_len, seg_thick * 0.85)
		k2.mesh = k2m
		k2.material_override = finger_mat
		k2.position = Vector3(0, seg_len * 1.5, 0)
		finger.add_child(k2)


# ── Config metadata ──────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	_build_goal_queue()


func _read_metadata_overrides() -> void:
	if has_meta("config_sky_height"):
		sky_height = float(str(get_meta("config_sky_height")))
	if has_meta("config_travel_speed"):
		travel_speed = float(str(get_meta("config_travel_speed")))
	if has_meta("config_arrive_threshold"):
		arrive_threshold = float(str(get_meta("config_arrive_threshold")))
	if has_meta("config_dwell_seconds"):
		dwell_seconds = float(str(get_meta("config_dwell_seconds")))
	if has_meta("config_pyramid_size"):
		pyramid_size = float(str(get_meta("config_pyramid_size")))
	if has_meta("config_pyramid_height"):
		pyramid_height = float(str(get_meta("config_pyramid_height")))
	if has_meta("config_pyramid_color"):
		pyramid_color = _parse_color(str(get_meta("config_pyramid_color")), pyramid_color)
	if has_meta("config_pyramid_lifetime"):
		pyramid_lifetime = float(str(get_meta("config_pyramid_lifetime")))
	if has_meta("config_body_color"):
		body_color = _parse_color(str(get_meta("config_body_color")), body_color)
	if has_meta("config_accent_color"):
		accent_color = _parse_color(str(get_meta("config_accent_color")), accent_color)
	if has_meta("config_debug_log"):
		var d: String = str(get_meta("config_debug_log")).to_lower()
		debug_log = d in ["true", "1", "yes", "on"]
	if has_meta("config_static_pose"):
		var sp: String = str(get_meta("config_static_pose")).to_lower()
		static_pose = sp in ["true", "1", "yes", "on"]
	if has_meta("config_show_pedestal"):
		var p: String = str(get_meta("config_show_pedestal")).to_lower()
		show_pedestal = p in ["true", "1", "yes", "on"]
	if has_meta("config_show_claw"):
		var c: String = str(get_meta("config_show_claw")).to_lower()
		show_claw = c in ["true", "1", "yes", "on"]
	if has_meta("config_claw_offset_segments"):
		claw_offset_segments = float(str(get_meta("config_claw_offset_segments")))
	if has_meta("config_wrist_rod_radius"):
		wrist_rod_radius = float(str(get_meta("config_wrist_rod_radius")))
	if has_meta("config_max_joint_angle_deg"):
		max_joint_angle_deg = float(str(get_meta("config_max_joint_angle_deg")))
	if has_meta("config_place_positions"):
		var raw: String = str(get_meta("config_place_positions"))
		var pts := PackedVector3Array()
		for trip in raw.split(";"):
			var s: String = trip.strip_edges()
			if s.is_empty():
				continue
			var parts := s.split(",")
			if parts.size() < 3:
				continue
			pts.append(Vector3(float(parts[0]), float(parts[1]), float(parts[2])))
		if pts.size() > 0:
			place_positions = pts


func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
