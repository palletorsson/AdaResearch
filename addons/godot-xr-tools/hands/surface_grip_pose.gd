# surface_grip_pose.gd
# Fits the existing XRTools open/closed poses to a held object's collision shapes.
# Forward kinematics are evaluated without moving the live skeleton or modifying
# its authored animations. The caller supplies an isolated physics query space.
extends RefCounted

const FINGERS: Array[String] = ["Thumb", "Index", "Middle", "Ring", "Little"]
const COARSE_STEPS: int = 20
const REFINE_STEPS: int = 6

var _skeleton: Skeleton3D
var _skeleton_to_hand: Transform3D = Transform3D.IDENTITY
var _parents: PackedInt32Array = PackedInt32Array()
var _names: PackedStringArray = PackedStringArray()
var _bone_fingers: PackedStringArray = PackedStringArray()
var _positions: Array[Vector3] = []
var _scales: Array[Vector3] = []
var _open: Array[Quaternion] = []
var _source_open: Array[Quaternion] = []
var _closed: Array[Quaternion] = []
var _tracks: Dictionary = {}
var _finger_bones: Dictionary = {}
var _segments: Dictionary = {}
var _palm: Transform3D = Transform3D.IDENTITY
var _configured: bool = false


## Cache the actual hand rig and authored pose endpoints. Unsupported rigs return
## false so the caller can retain its normal hand animation.
func configure(hand: Node3D) -> bool:
	_configured = false
	_parents.clear()
	_names.clear()
	_bone_fingers.clear()
	_positions.clear()
	_scales.clear()
	_open.clear()
	_source_open.clear()
	_closed.clear()
	_tracks.clear()
	_finger_bones.clear()
	_segments.clear()
	_skeleton = _find_skeleton(hand)
	var settings: XRToolsHandPoseSettings = hand.get("default_pose") as XRToolsHandPoseSettings
	if _skeleton == null or settings == null:
		return false
	if settings.open_pose == null or settings.closed_pose == null:
		return false
	_skeleton_to_hand = hand.global_transform.affine_inverse() * _skeleton.global_transform
	for index in range(_skeleton.get_bone_count()):
		_parents.append(_skeleton.get_bone_parent(index))
		_names.append(_skeleton.get_bone_name(index))
		_bone_fingers.append("")
		_positions.append(_skeleton.get_bone_pose_position(index))
		_scales.append(_skeleton.get_bone_pose_scale(index))
		# Rest rotation is the fallback for bones absent from both animations;
		# controller grip values must not become the next grab's neutral pose.
		var rotation: Quaternion = _skeleton.get_bone_rest(index).basis.get_rotation_quaternion()
		_open.append(rotation)
		_closed.append(rotation)
	_read_rotations(settings.open_pose, _open)
	_read_rotations(settings.closed_pose, _closed)
	_source_open.assign(_open)
	for finger in FINGERS:
		var bones: Array[int] = []
		var segments: Array[Vector2i] = []
		for index in range(_names.size()):
			if not _belongs_to_finger(_names[index], finger):
				continue
			bones.append(index)
			_bone_fingers[index] = finger
			var parent: int = _parents[index]
			if parent >= 0 and _belongs_to_finger(_names[parent], finger):
				# Metacarpal-to-knuckle is inside the palm. Probe phalanges,
				# including intermediate segments, rather than fingertips alone.
				if not _names[parent].contains("Metacarpal"):
					segments.append(Vector2i(parent, index))
		if bones.is_empty() or segments.is_empty():
			return false
		_finger_bones[finger] = bones
		_segments[finger] = segments
	if _tracks.is_empty() or not _calibrate_palm():
		return false
	_configured = true
	return true


## Palm surface in hand-root coordinates. Positive Z points out of the palm
## into the object; positive Y runs from wrist towards the middle knuckle.
func palm_frame() -> Transform3D:
	return _palm


## Solve each finger once at grab time. radius is the finger padding in query
## space units. The supplied space contains only the target, on layer 1.
## The returned open/closed animations are the same frozen, generated pose.
## initial_blocked lists fingers still intersecting after bounded extension;
## callers should retry their placement or decline that pose when nonempty.
func solve(hand_to_query: Transform3D, space: PhysicsDirectSpaceState3D, radius: float) -> Dictionary:
	if not _configured or space == null:
		return {}
	# An authored relaxed pose can already intersect a broad surface. Each
	# solve starts from the original endpoint, then extends only affected
	# fingers away from that surface before searching their closing arc.
	_open.assign(_source_open)
	var probe_radius: float = maxf(radius, 0.001)
	var sphere: SphereShape3D = SphereShape3D.new()
	sphere.radius = probe_radius
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.collision_mask = 1
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.margin = 0.0001
	var curls: Dictionary = {}
	var initial_blocked: Array[String] = []
	for finger in FINGERS:
		var low: float = 0.0
		var high: float = 1.0
		var blocked: bool = _finger_blocked(finger, 0.0, hand_to_query, space, query, probe_radius)
		if blocked:
			blocked = not _extend_clear(finger, hand_to_query, space, query, probe_radius)
			if blocked:
				# Report this rather than presenting a penetrating pose as a
				# solved contact. The caller can retry with a small backoff.
				initial_blocked.append(finger)
				curls[finger] = 0.0
				continue
		for step in range(1, COARSE_STEPS + 1):
			var candidate: float = float(step) / float(COARSE_STEPS)
			if _finger_blocked(finger, candidate, hand_to_query, space, query, probe_radius):
				high = candidate
				blocked = true
				break
			low = candidate
		if blocked:
			for refinement in range(REFINE_STEPS):
				var middle: float = (low + high) * 0.5
				if _finger_blocked(finger, middle, hand_to_query, space, query, probe_radius):
					high = middle
				else:
					low = middle
		curls[finger] = low
	var animation: Animation = _make_animation(curls)
	var settings: XRToolsHandPoseSettings = XRToolsHandPoseSettings.new()
	settings.open_pose = animation
	settings.closed_pose = animation
	return {"pose": settings, "curls": curls, "initial_blocked": initial_blocked}


## Bone positions in hand-root coordinates, useful for calibration and tests.
## Missing finger keys mean open; values are normalized curls in [0, 1].
## After solve(), open includes any procedural extension for that encounter.
func bone_positions(curls: Dictionary = {}) -> Dictionary:
	var transforms: Array[Transform3D] = _forward_kinematics(curls)
	var result: Dictionary = {}
	for index in range(_names.size()):
		result[_names[index]] = transforms[index].origin
	return result


## Probe centers in hand-root space. Exposed for test/debug visualization only.
func finger_probe_positions(finger: String, curl: float, radius: float = 0.008) -> PackedVector3Array:
	return _probe_positions(finger, curl, Transform3D.IDENTITY, maxf(radius, 0.001))


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found: Skeleton3D = _find_skeleton(child)
		if found != null:
			return found
	return null


func _read_rotations(animation: Animation, rotations: Array[Quaternion]) -> void:
	for track in range(animation.get_track_count()):
		if animation.track_get_type(track) != Animation.TYPE_ROTATION_3D:
			continue
		var path: NodePath = animation.track_get_path(track)
		if path.get_subname_count() == 0 or animation.track_get_key_count(track) == 0:
			continue
		var index: int = _skeleton.find_bone(String(path.get_subname(0)))
		if index < 0:
			continue
		rotations[index] = animation.rotation_track_interpolate(track, 0.0).normalized()
		_tracks[index] = path


func _belongs_to_finger(bone_name: String, finger: String) -> bool:
	return bone_name.begins_with(finger + "_") or (finger == "Little" and bone_name.begins_with("Pinky_"))


func _bone_curl(index: int, curls: Dictionary) -> float:
	return clampf(float(curls.get(_bone_fingers[index], 0.0)), 0.0, 1.0)


func _forward_kinematics(curls: Dictionary) -> Array[Transform3D]:
	var transforms: Array[Transform3D] = []
	var cache: Dictionary = {}
	for index in range(_names.size()):
		transforms.append(_bone_transform(index, curls, cache))
	return transforms


func _bone_transform(index: int, curls: Dictionary, cache: Dictionary) -> Transform3D:
	if cache.has(index):
		return cache[index]
	var rotation: Quaternion = _open[index].slerp(_closed[index], _bone_curl(index, curls))
	var local: Transform3D = Transform3D(Basis(rotation).scaled_local(_scales[index]), _positions[index])
	var parent: int = _parents[index]
	var result: Transform3D = _skeleton_to_hand * local
	if parent >= 0:
		result = _bone_transform(parent, curls, cache) * local
	cache[index] = result
	return result


func _matching_bone(prefix: String) -> int:
	for index in range(_names.size()):
		if _names[index].begins_with(prefix):
			return index
	return -1


func _calibrate_palm() -> bool:
	var wrist: int = _matching_bone("Wrist_")
	var index_base: int = _matching_bone("Index_Proximal_")
	var middle_base: int = _matching_bone("Middle_Proximal_")
	var little_base: int = _matching_bone("Little_Proximal_")
	if little_base < 0:
		little_base = _matching_bone("Pinky_Proximal_")
	if mini(mini(wrist, index_base), mini(middle_base, little_base)) < 0:
		return false
	var opened: Array[Transform3D] = _forward_kinematics({})
	var along: Vector3 = opened[middle_base].origin - opened[wrist].origin
	var across: Vector3 = opened[index_base].origin - opened[little_base].origin
	var normal: Vector3 = across.cross(along).normalized()
	if normal.length_squared() < 0.9 or along.length_squared() < 0.000001:
		return false
	var center: Vector3 = opened[wrist].origin.lerp(opened[middle_base].origin, 0.65)
	var marker: int = _matching_bone("Palm_")
	if marker >= 0:
		# These rigs have an authored Palm_L/R surface marker. Its offset
		# determines which side of the bone plane is the palmar surface.
		if normal.dot(opened[marker].origin - center) < 0.0:
			normal = -normal
	else:
		var middle_tip: int = _matching_bone("Middle_Tip_")
		if middle_tip < 0:
			return false
		# A fully closed finger has already curled back towards the wrist;
		# use the beginning of closure to disambiguate the palm side.
		var closing: Array[Transform3D] = _forward_kinematics({"Middle": 0.15})
		if normal.dot(closing[middle_tip].origin - opened[middle_tip].origin) < 0.0:
			normal = -normal
	# The bundled Palm markers sit towards the heel/little side and outside
	# the visible central palm. Use them for handedness, then intersect the
	# actual skinned surface along the wrist-to-middle-knuckle centreline.
	var surface: Dictionary = _palm_surface(center, normal, opened)
	if surface.has("point"):
		center = surface["point"]
	elif marker >= 0:
		# Retain the marker depth when a custom mesh cannot be sampled, but
		# remove its tangential offset so the grip stays centred on the palm.
		center += normal * normal.dot(opened[marker].origin - center)
	else:
		center += normal * 0.012
	var forward: Vector3 = (along - normal * along.dot(normal)).normalized()
	var right: Vector3 = forward.cross(normal).normalized()
	_palm = Transform3D(Basis(right, normal.cross(right).normalized(), normal), center)
	return true


# CPU skinning is used only during configuration (the bundled hand has about
# 2,000 vertices). These are the same bind transforms and weights as the mesh,
# not an AABB or an assumed palm thickness.
func _palm_surface(center: Vector3, normal: Vector3, transforms: Array[Transform3D]) -> Dictionary:
	var meshes: Array[MeshInstance3D] = []
	_find_meshes(_skeleton, meshes)
	var ray_origin: Vector3 = center + normal * 0.2
	var nearest_distance: float = INF
	var result: Dictionary = {}
	for instance in meshes:
		if instance.mesh == null or instance.skin == null:
			continue
		if instance.get_node_or_null(instance.skeleton) != _skeleton:
			continue
		var skin: Skin = instance.skin
		var bind_transforms: Array[Transform3D] = []
		var supported: bool = true
		for bind in range(skin.get_bind_count()):
			var bone: int = skin.get_bind_bone(bind)
			if bone < 0:
				bone = _skeleton.find_bone(String(skin.get_bind_name(bind)))
			if bone < 0 or bone >= transforms.size():
				supported = false
				break
			bind_transforms.append(transforms[bone] * skin.get_bind_pose(bind))
		if not supported:
			continue
		for surface in range(instance.mesh.get_surface_count()):
			if instance.mesh.surface_get_primitive_type(surface) != Mesh.PRIMITIVE_TRIANGLES:
				continue
			var arrays: Array = instance.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if vertices.is_empty() or bones.is_empty() or weights.size() != bones.size():
				continue
			var influences: int = bones.size() / vertices.size()
			var posed: PackedVector3Array = PackedVector3Array()
			posed.resize(vertices.size())
			for vertex in range(vertices.size()):
				var point: Vector3 = Vector3.ZERO
				for influence in range(influences):
					var entry: int = vertex * influences + influence
					if weights[entry] > 0.0:
						point += (bind_transforms[bones[entry]] * vertices[vertex]) * weights[entry]
				posed[vertex] = point
			var triangle_count: int = indices.size() / 3 if not indices.is_empty() else posed.size() / 3
			for triangle in range(triangle_count):
				var offset: int = triangle * 3
				var a: int = indices[offset] if not indices.is_empty() else offset
				var b: int = indices[offset + 1] if not indices.is_empty() else offset + 1
				var c: int = indices[offset + 2] if not indices.is_empty() else offset + 2
				var hit: Variant = Geometry3D.ray_intersects_triangle(ray_origin, -normal, posed[a], posed[b], posed[c])
				if hit is Vector3:
					var distance: float = ray_origin.distance_to(hit)
					if distance < nearest_distance:
						nearest_distance = distance
						result["point"] = hit
	return result


func _find_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	for child in node.get_children():
		if child is MeshInstance3D:
			result.append(child as MeshInstance3D)
		_find_meshes(child, result)


func _probe_positions(finger: String, curl: float, hand_to_query: Transform3D, radius: float) -> PackedVector3Array:
	var result: PackedVector3Array = PackedVector3Array()
	if not _segments.has(finger):
		return result
	var curls: Dictionary = {finger: curl}
	var cache: Dictionary = {}
	var segments: Array[Vector2i] = _segments[finger]
	for segment in segments:
		var start: Vector3 = hand_to_query * _bone_transform(segment.x, curls, cache).origin
		var end: Vector3 = hand_to_query * _bone_transform(segment.y, curls, cache).origin
		# Overlapping spheres cover each phalanx instead of leaving gaps
		# between the named joints; the explicit Tip bone covers the nail end.
		var count: int = maxi(1, ceili(start.distance_to(end) / radius))
		for sample in range(count + 1):
			result.append(start.lerp(end, float(sample) / float(count)))
	return result


func _finger_blocked(finger: String, curl: float, hand_to_query: Transform3D, space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D, radius: float) -> bool:
	var points: PackedVector3Array = _probe_positions(finger, curl, hand_to_query, radius)
	for point in points:
		query.transform = Transform3D(Basis.IDENTITY, point)
		if not space.intersect_shape(query, 1).is_empty():
			return true
	return false


# Extend at the knuckle, not by moving the palm away from the object. The
# original Grip 5 pose is partly closed, so the first few degrees undo that
# bend. Limit the search and report failures for awkward/concave geometry.
func _extend_clear(finger: String, hand_to_query: Transform3D, space: PhysicsDirectSpaceState3D, query: PhysicsShapeQueryParameters3D, radius: float) -> bool:
	var root_prefix: String = finger + ("_Metacarpal_" if finger == "Thumb" else "_Proximal_")
	var root_bone: int = _matching_bone(root_prefix)
	if root_bone < 0 and finger == "Little":
		root_bone = _matching_bone("Pinky_Proximal_")
	if root_bone < 0:
		return false
	var parent: int = _parents[root_bone]
	var parent_transform: Transform3D = _skeleton_to_hand
	if parent >= 0:
		parent_transform = _bone_transform(parent, {}, {})
	var axis: Vector3 = (parent_transform.basis.inverse() * _palm.basis.x).normalized()
	var source: Quaternion = _open[root_bone]
	for step in range(1, 21):
		var angle: float = -deg_to_rad(float(step) * 3.0)
		_open[root_bone] = (Quaternion(axis, angle) * source).normalized()
		if not _finger_blocked(finger, 0.0, hand_to_query, space, query, radius):
			return true
	# Keep the bounded extended endpoint so a caller's backoff has a chance
	# to resolve contact; authored pose resources remain unchanged.
	return false


func _make_animation(curls: Dictionary) -> Animation:
	var animation: Animation = Animation.new()
	animation.resource_name = "surface_grip_pose"
	animation.length = 1.0
	for key in _tracks:
		var bone: int = int(key)
		var track: int = animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, _tracks[key])
		var rotation: Quaternion = _open[bone].slerp(_closed[bone], _bone_curl(bone, curls))
		animation.rotation_track_insert_key(track, 0.0, rotation)
	return animation
