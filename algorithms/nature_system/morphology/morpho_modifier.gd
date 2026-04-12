# MorphoModifier.gd — Form transformations for the universal morphology engine
#
# Each static function takes an ArrayMesh and returns a modified ArrayMesh.
# Modifiers compose by chaining: noise_displace(twist(taper(mesh)))
# Order matters — taper-then-twist ≠ twist-then-taper.
#
# Uses MeshDataTool for per-vertex access on committed meshes.

class_name MorphoModifier
extends RefCounted


# ═══════════════════════════════════════════════════════════════
# DEFORMATION MODIFIERS — change vertex positions, preserve topology
# ═══════════════════════════════════════════════════════════════

## Taper: scale vertices toward an axis as a function of distance along it.
## axis: the tapering direction (e.g., Vector3.UP for Y-axis taper)
## taper_func: Callable(float) -> float, maps t (0-1 along axis) to scale factor
static func taper(mesh: Mesh, axis: Vector3 = Vector3.UP,
		taper_func: Callable = func(t: float) -> float: return 1.0 - t * 0.5) -> ArrayMesh:

	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var aabb: AABB = _compute_aabb(mdt)
	axis = axis.normalized()

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var projected: float = (v - aabb.position).dot(axis)
		var t: float = projected / maxf(aabb.size.dot(axis.abs()), 0.001)
		t = clampf(t, 0.0, 1.0)

		var scale_factor: float = taper_func.call(t) as float
		var along_axis: Vector3 = axis * projected
		var perpendicular: Vector3 = v - aabb.position - along_axis
		mdt.set_vertex(i, aabb.position + along_axis + perpendicular * scale_factor)

	return _commit_mdt(mdt)


## Twist: rotate vertices around an axis proportional to distance along it.
## degrees: total twist from bottom to top
static func twist(mesh: Mesh, axis: Vector3 = Vector3.UP,
		degrees: float = 90.0) -> ArrayMesh:

	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var aabb: AABB = _compute_aabb(mdt)
	axis = axis.normalized()

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var projected: float = (v - aabb.position).dot(axis)
		var t: float = projected / maxf(aabb.size.dot(axis.abs()), 0.001)
		t = clampf(t, 0.0, 1.0)

		var angle: float = deg_to_rad(degrees * t)
		var rotated: Vector3 = Basis().rotated(axis, angle) * (v - aabb.get_center())
		mdt.set_vertex(i, aabb.get_center() + rotated)

	return _commit_mdt(mdt)


## Bend: curve the mesh around a pivot point along an axis.
## angle: total bend in degrees
## pivot: the center of curvature
static func bend(mesh: Mesh, axis: Vector3 = Vector3.FORWARD,
		angle: float = 45.0, pivot: Vector3 = Vector3.ZERO) -> ArrayMesh:

	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var aabb: AABB = _compute_aabb(mdt)
	var bend_axis: Vector3 = axis.normalized()
	# Bend around the perpendicular to both bend_axis and UP
	var up: Vector3 = Vector3.UP if absf(bend_axis.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
	var right: Vector3 = bend_axis.cross(up).normalized()

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var height: float = (v - aabb.position).dot(up)
		var t: float = height / maxf(aabb.size.dot(up.abs()), 0.001)
		t = clampf(t, 0.0, 1.0)

		var bend_angle: float = deg_to_rad(angle * t)
		var rotated: Vector3 = Basis().rotated(bend_axis, bend_angle) * (v - pivot)
		mdt.set_vertex(i, pivot + rotated)

	return _commit_mdt(mdt)


## Noise displacement: push vertices along their normals by noise values.
## noise: FastNoiseLite instance
## strength: displacement magnitude
static func noise_displace(mesh: Mesh, noise: FastNoiseLite,
		strength: float = 0.1, time_offset: float = 0.0) -> ArrayMesh:

	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var n: Vector3 = mdt.get_vertex_normal(i)
		var displacement: float = noise.get_noise_3d(
			v.x + time_offset, v.y + time_offset, v.z) * strength
		mdt.set_vertex(i, v + n * displacement)

	return _commit_mdt(mdt)


## Inflate: push all vertices outward along their normals by a fixed amount.
static func inflate(mesh: Mesh, amount: float = 0.05) -> ArrayMesh:
	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var n: Vector3 = mdt.get_vertex_normal(i)
		mdt.set_vertex(i, v + n * amount)

	return _commit_mdt(mdt)


## Scale along a single axis (stretch/squash).
static func axis_scale(mesh: Mesh, axis: Vector3 = Vector3.UP,
		scale_factor: float = 2.0) -> ArrayMesh:

	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var center: Vector3 = _compute_aabb(mdt).get_center()
	axis = axis.normalized()

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var offset: Vector3 = v - center
		var along: float = offset.dot(axis)
		var perpendicular: Vector3 = offset - axis * along
		mdt.set_vertex(i, center + perpendicular + axis * along * scale_factor)

	return _commit_mdt(mdt)


## Spherize: pull vertices toward a sphere centered at the AABB center.
## factor: 0.0 = no change, 1.0 = perfect sphere
static func spherize(mesh: Mesh, factor: float = 0.5) -> ArrayMesh:
	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var center: Vector3 = _compute_aabb(mdt).get_center()
	var aabb: AABB = _compute_aabb(mdt)
	var avg_radius: float = (aabb.size.x + aabb.size.y + aabb.size.z) / 6.0

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var dir: Vector3 = (v - center)
		if dir.length_squared() < 0.0001:
			continue
		var sphere_pos: Vector3 = center + dir.normalized() * avg_radius
		mdt.set_vertex(i, v.lerp(sphere_pos, factor))

	return _commit_mdt(mdt)


## Wave: sinusoidal displacement along an axis.
## frequency: waves per unit length, amplitude: max displacement
static func wave(mesh: Mesh, wave_axis: Vector3 = Vector3.RIGHT,
		displace_axis: Vector3 = Vector3.UP,
		frequency: float = 3.0, amplitude: float = 0.1,
		phase: float = 0.0) -> ArrayMesh:

	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	wave_axis = wave_axis.normalized()
	displace_axis = displace_axis.normalized()

	for i in mdt.get_vertex_count():
		var v: Vector3 = mdt.get_vertex(i)
		var t: float = v.dot(wave_axis)
		var displacement: float = sin(t * TAU * frequency + phase) * amplitude
		mdt.set_vertex(i, v + displace_axis * displacement)

	return _commit_mdt(mdt)


# ═══════════════════════════════════════════════════════════════
# BLENDER-STYLE MODIFIERS
# ═══════════════════════════════════════════════════════════════

## Laplacian Smooth: iteratively average each vertex toward its neighbors.
## iterations: number of smooth passes. factor: blend strength per pass.
static func smooth(mesh: Mesh, iterations: int = 1, factor: float = 0.5) -> ArrayMesh:
	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	for _iter in iterations:
		# Build adjacency: for each vertex, find neighbors via shared faces
		var vert_count: int = mdt.get_vertex_count()
		var new_positions: PackedVector3Array = PackedVector3Array()
		new_positions.resize(vert_count)

		for vi in vert_count:
			var pos: Vector3 = mdt.get_vertex(vi)
			var neighbors: Dictionary = {}
			# Find faces containing this vertex
			for fi in mdt.get_face_count():
				for fvi in 3:
					if mdt.get_face_vertex(fi, fvi) == vi:
						for fvi2 in 3:
							var nvi: int = mdt.get_face_vertex(fi, fvi2)
							if nvi != vi:
								neighbors[nvi] = true
						break

			if neighbors.is_empty():
				new_positions[vi] = pos
				continue

			var avg := Vector3.ZERO
			for nvi: int in neighbors:
				avg += mdt.get_vertex(nvi)
			avg /= float(neighbors.size())
			new_positions[vi] = pos.lerp(avg, factor)

		for vi in vert_count:
			mdt.set_vertex(vi, new_positions[vi])

	return _commit_mdt(mdt)


## Mirror: reflect mesh across a plane (axis: 0=X, 1=Y, 2=Z).
## merge_distance: vertices within this distance from the mirror plane are welded.
static func mirror(mesh: Mesh, axis: int = 0, merge_distance: float = 0.001) -> ArrayMesh:
	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var vert_count: int = mdt.get_vertex_count()
	var face_count: int = mdt.get_face_count()

	# Build new mesh with original + mirrored geometry
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Copy original faces
	for fi in face_count:
		for fvi in 3:
			var vi: int = mdt.get_face_vertex(fi, fvi)
			var v: Vector3 = mdt.get_vertex(vi)
			var n: Vector3 = mdt.get_vertex_normal(vi)
			st.set_normal(n)
			st.add_vertex(v)

	# Add mirrored faces (reversed winding for correct normals)
	for fi in face_count:
		for fvi_idx in [0, 2, 1]:  # Reverse winding
			var vi: int = mdt.get_face_vertex(fi, fvi_idx)
			var v: Vector3 = mdt.get_vertex(vi)
			# Mirror the position
			match axis:
				0: v.x = -v.x
				1: v.y = -v.y
				2: v.z = -v.z
			var n: Vector3 = mdt.get_vertex_normal(vi)
			match axis:
				0: n.x = -n.x
				1: n.y = -n.y
				2: n.z = -n.z
			st.set_normal(n)
			st.add_vertex(v)

	st.generate_normals()
	return st.commit()


## Solidify: give a surface thickness by duplicating it inward/outward.
## thickness: distance between inner and outer shells.
static func solidify(mesh: Mesh, thickness: float = 0.05) -> ArrayMesh:
	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var vert_count: int = mdt.get_vertex_count()
	var face_count: int = mdt.get_face_count()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half: float = thickness * 0.5

	# Outer shell (original, pushed outward)
	for fi in face_count:
		for fvi in 3:
			var vi: int = mdt.get_face_vertex(fi, fvi)
			var v: Vector3 = mdt.get_vertex(vi)
			var n: Vector3 = mdt.get_vertex_normal(vi)
			st.set_normal(n)
			st.add_vertex(v + n * half)

	# Inner shell (reversed winding, pushed inward)
	for fi in face_count:
		for fvi_idx in [0, 2, 1]:
			var vi: int = mdt.get_face_vertex(fi, fvi_idx)
			var v: Vector3 = mdt.get_vertex(vi)
			var n: Vector3 = mdt.get_vertex_normal(vi)
			st.set_normal(-n)
			st.add_vertex(v - n * half)

	st.generate_normals()
	return st.commit()


## Array: duplicate mesh along a direction with count and offset.
## Returns a mesh containing all copies merged together.
static func array_modifier(mesh: Mesh, count: int = 3,
		offset: Vector3 = Vector3(1.0, 0.0, 0.0),
		rotation_per_copy: float = 0.0, scale_per_copy: float = 1.0) -> ArrayMesh:
	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var vert_count: int = mdt.get_vertex_count()
	var face_count: int = mdt.get_face_count()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for copy_idx in count:
		var t: float = float(copy_idx)
		var copy_offset: Vector3 = offset * t
		var copy_scale: float = pow(scale_per_copy, t)
		var copy_rotation: float = rotation_per_copy * t

		var basis := Basis.IDENTITY
		if absf(copy_rotation) > 0.001:
			basis = basis.rotated(offset.normalized(), deg_to_rad(copy_rotation))
		basis = basis.scaled(Vector3.ONE * copy_scale)

		for fi in face_count:
			for fvi in 3:
				var vi: int = mdt.get_face_vertex(fi, fvi)
				var v: Vector3 = mdt.get_vertex(vi)
				var n: Vector3 = mdt.get_vertex_normal(vi)
				var transformed: Vector3 = basis * v + copy_offset
				st.set_normal(basis * n)
				st.add_vertex(transformed)

	st.generate_normals()
	return st.commit()


## Screw: revolve mesh around an axis, creating rotational geometry.
## Like Blender's Screw modifier.
static func screw(mesh: Mesh, axis: Vector3 = Vector3.UP,
		steps: int = 12, angle_degrees: float = 360.0,
		height: float = 0.0) -> ArrayMesh:
	var mdt := _get_mdt(mesh)
	if mdt == null:
		return null

	var vert_count: int = mdt.get_vertex_count()
	var face_count: int = mdt.get_face_count()
	axis = axis.normalized()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for step in steps:
		var t: float = float(step) / float(steps)
		var angle: float = deg_to_rad(angle_degrees * t)
		var y_offset: float = height * t
		var basis := Basis().rotated(axis, angle)

		for fi in face_count:
			for fvi in 3:
				var vi: int = mdt.get_face_vertex(fi, fvi)
				var v: Vector3 = mdt.get_vertex(vi)
				var n: Vector3 = mdt.get_vertex_normal(vi)
				var transformed: Vector3 = basis * v + axis * y_offset
				st.set_normal(basis * n)
				st.add_vertex(transformed)

	st.generate_normals()
	return st.commit()


# ═══════════════════════════════════════════════════════════════
# MODIFIER PIPELINE — chain multiple modifiers
# ═══════════════════════════════════════════════════════════════

## Apply a sequence of modifiers to a mesh.
## Each entry is a Callable that takes Mesh and returns ArrayMesh.
static func chain(mesh: Mesh, modifiers: Array) -> ArrayMesh:
	var current: Mesh = mesh
	for modifier in modifiers:
		if current == null:
			return null
		var m: Callable = modifier as Callable
		current = m.call(current) as Mesh
	return current as ArrayMesh


# ═══════════════════════════════════════════════════════════════
# INTERNAL UTILITIES
# ═══════════════════════════════════════════════════════════════

## Convert any Mesh to a MeshDataTool for per-vertex access.
static func _get_mdt(mesh: Mesh) -> MeshDataTool:
	if mesh == null:
		return null

	# Ensure we have an ArrayMesh
	var array_mesh: ArrayMesh
	if mesh is ArrayMesh:
		array_mesh = mesh as ArrayMesh
	else:
		# Convert primitive mesh to ArrayMesh via SurfaceTool
		var st := SurfaceTool.new()
		st.create_from(mesh, 0)
		array_mesh = st.commit()

	if array_mesh.get_surface_count() == 0:
		return null

	var mdt := MeshDataTool.new()
	if mdt.create_from_surface(array_mesh, 0) != OK:
		return null
	return mdt


## Commit modified MeshDataTool back to an ArrayMesh.
static func _commit_mdt(mdt: MeshDataTool) -> ArrayMesh:
	var result := ArrayMesh.new()
	mdt.commit_to_surface(result)
	# Regenerate normals for the modified mesh
	var st := SurfaceTool.new()
	st.create_from(result, 0)
	st.generate_normals()
	return st.commit()


## Compute AABB from MeshDataTool vertices.
static func _compute_aabb(mdt: MeshDataTool) -> AABB:
	if mdt.get_vertex_count() == 0:
		return AABB()
	var min_v: Vector3 = mdt.get_vertex(0)
	var max_v: Vector3 = min_v
	for i in range(1, mdt.get_vertex_count()):
		var v: Vector3 = mdt.get_vertex(i)
		min_v = Vector3(minf(min_v.x, v.x), minf(min_v.y, v.y), minf(min_v.z, v.z))
		max_v = Vector3(maxf(max_v.x, v.x), maxf(max_v.y, v.y), maxf(max_v.z, v.z))
	return AABB(min_v, max_v - min_v)
