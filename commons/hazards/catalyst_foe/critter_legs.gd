# critter_legs.gd
# Plant-and-step leg rig for the pink critter's grounded stages.
#
# The GAIT is ported from octapod_crawler/six_leg_critter.gd — the solved
# walking in this codebase: each foot PLANTS in world space and stays put
# while the body moves; when a foot is stretched past step_threshold from
# its home it lifts and steps (sine arc) toward home + overshoot along the
# body's velocity. Neighbouring legs never step at the same time (the
# hexapod's alternating-stability rule).
#
# The hexapod's FABRIK armature scenes are built at 2.2m demo scale, so
# they are replaced here by analytic two-bone legs (exact-length triangle
# solve, knee bent up-and-out) — no scene dependencies, works at 0.16m
# blob scale, inherits the stage scale from its parent mesh root.
extends Node3D

@export var leg_count: int = 8

@export_group("Gait (local units, scale-free)")
@export var step_threshold: float = 0.15
@export var step_height: float = 0.10
@export var step_duration: float = 0.18
@export var step_overshoot: float = 0.07

const UPPER_LEN := 0.20
const LOWER_LEN := 0.19
const SHOULDER_R := 0.11
const HOME_R := 0.26
const SHOULDER_Y := -0.02

var _uppers: Array[MeshInstance3D] = []
var _lowers: Array[MeshInstance3D] = []
var _shoulders: Array[Vector3] = []      # local
var _homes: Array[Vector3] = []          # local, y at ground
var _planted_w: Array[Vector3] = []      # WORLD — the whole point of the gait
var _stepping: Array[bool] = []
var _step_from_w: Array[Vector3] = []
var _step_to_w: Array[Vector3] = []
var _step_t: Array[float] = []
var _body: CharacterBody3D = null
var _feet_initialized: bool = false


func _ready() -> void:
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.93, 0.28, 0.60).darkened(0.25)
	for i in range(leg_count):
		var ang: float = TAU * float(i) / float(leg_count) + TAU / 16.0
		_shoulders.append(Vector3(cos(ang) * SHOULDER_R, SHOULDER_Y, sin(ang) * SHOULDER_R))
		_homes.append(Vector3(cos(ang) * HOME_R, 0.0, sin(ang) * HOME_R))
		_planted_w.append(Vector3.ZERO)
		_stepping.append(false)
		_step_from_w.append(Vector3.ZERO)
		_step_to_w.append(Vector3.ZERO)
		_step_t.append(0.0)

		# Leg root exists for the name contract (tests count "Leg?" nodes);
		# segments are positioned in THIS node's space each frame.
		var leg_root := Node3D.new()
		leg_root.name = "Leg%d" % i
		add_child(leg_root)
		_uppers.append(_make_segment(leg_root, leg_mat, 0.014, UPPER_LEN))
		_lowers.append(_make_segment(leg_root, leg_mat, 0.011, LOWER_LEN))
	# Walk up to the CharacterBody3D (mesh_root -> CatalystFoe).
	var n: Node = get_parent()
	while n != null and not (n is CharacterBody3D):
		n = n.get_parent()
	_body = n as CharacterBody3D


func _make_segment(parent: Node3D, mat: StandardMaterial3D, radius: float, length: float) -> MeshInstance3D:
	var seg := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = length
	seg.mesh = cap
	seg.set_surface_override_material(0, mat)
	parent.add_child(seg)
	return seg


func _process(delta: float) -> void:
	if not is_inside_tree():
		return
	var inv: Transform3D = global_transform.affine_inverse()
	var ground_y_w: float = _find_ground_y()

	# Home positions in world, feet on the ground plane.
	if not _feet_initialized:
		for i in range(leg_count):
			var h0: Vector3 = to_global(_homes[i])
			h0.y = ground_y_w
			_planted_w[i] = h0
		_feet_initialized = true

	# Velocity direction (local) for the step overshoot.
	var vel_local := Vector3.ZERO
	if is_instance_valid(_body) and _body.velocity.length_squared() > 0.001:
		vel_local = (inv.basis * _body.velocity)
		vel_local.y = 0.0
		if vel_local.length() > 0.001:
			vel_local = vel_local.normalized()

	for i in range(leg_count):
		var home_w: Vector3 = to_global(_homes[i] + vel_local * step_overshoot)
		home_w.y = ground_y_w

		if _stepping[i]:
			_step_t[i] = min(_step_t[i] + delta / max(step_duration, 0.01), 1.0)
			var t: float = _step_t[i]
			var foot: Vector3 = _step_from_w[i].lerp(_step_to_w[i], t)
			foot.y = ground_y_w + sin(t * PI) * step_height * _world_scale()
			_planted_w[i] = foot
			if t >= 1.0:
				_stepping[i] = false
				_planted_w[i].y = ground_y_w
		else:
			# Compare stretch in LOCAL units so stage scale is free.
			var stretch: float = (inv * _planted_w[i]).distance_to(inv * home_w)
			if stretch > step_threshold and _neighbors_grounded(i):
				_stepping[i] = true
				_step_t[i] = 0.0
				_step_from_w[i] = _planted_w[i]
				_step_to_w[i] = home_w

		_pose_leg(i, inv * _planted_w[i])


## The hexapod's stability rule: a leg may lift only while both ring
## neighbours are planted.
func _neighbors_grounded(i: int) -> bool:
	var prev: int = (i - 1 + leg_count) % leg_count
	var next: int = (i + 1) % leg_count
	return not _stepping[prev] and not _stepping[next]


## Analytic two-bone solve in local space: shoulder -> knee -> foot with
## exact segment lengths; knee bends up-and-outward from the body.
func _pose_leg(i: int, foot_local: Vector3) -> void:
	var s: Vector3 = _shoulders[i]
	var f: Vector3 = foot_local
	var d: float = clamp(s.distance_to(f), 0.05, UPPER_LEN + LOWER_LEN - 0.01)
	var axis: Vector3 = (f - s).normalized()
	# Bend plane: up + radially outward, orthogonal to the shoulder-foot axis.
	var out: Vector3 = Vector3(_shoulders[i].x, 0.0, _shoulders[i].z).normalized()
	var bend: Vector3 = (Vector3.UP + out * 0.8)
	bend = (bend - axis * bend.dot(axis))
	bend = bend.normalized() if bend.length() > 0.001 else Vector3.UP
	var along: float = (UPPER_LEN * UPPER_LEN - LOWER_LEN * LOWER_LEN + d * d) / (2.0 * d)
	var lift: float = sqrt(max(UPPER_LEN * UPPER_LEN - along * along, 0.0))
	var knee: Vector3 = s + axis * along + bend * lift
	_place_segment(_uppers[i], s, knee)
	_place_segment(_lowers[i], knee, f)


## Position a capsule (Y-axis aligned) between two local-space points.
func _place_segment(seg: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	var y: Vector3 = b - a
	var len: float = y.length()
	if len < 0.001:
		return
	y = y / len
	var x: Vector3 = y.cross(Vector3.FORWARD)
	if x.length() < 0.001:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z: Vector3 = x.cross(y)
	seg.transform = Transform3D(Basis(x, y, z), (a + b) * 0.5)


func _world_scale() -> float:
	return global_transform.basis.get_scale().x


## Where the floor actually is — the hexapod used SpringArm3D raycasts for
## this. One ray from the body straight down; foes hover their node above
## the floor, so falling back to a fixed drop keeps the stance plausible
## in collision-free capture scenes.
func _find_ground_y() -> float:
	var base: Vector3 = _body.global_position if is_instance_valid(_body) else global_position
	var world := get_world_3d()
	if world != null:
		var space := world.direct_space_state
		if space != null:
			var q := PhysicsRayQueryParameters3D.create(
				base + Vector3.UP * 0.2, base + Vector3.DOWN * 2.5, 1)
			if is_instance_valid(_body):
				q.exclude = [_body.get_rid()]
			var hit: Dictionary = space.intersect_ray(q)
			if not hit.is_empty():
				return float(hit["position"].y)
	return base.y - 0.33 * _world_scale()
