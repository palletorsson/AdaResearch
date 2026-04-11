# MorphoPrimitive.gd — Atomic form generators for the universal morphology engine
#
# Pure geometry library. No DNA dependency. Each static function takes
# parameters and returns a Mesh (ArrayMesh). These are the atoms from which
# all form is composed.
#
# Categories:
#   Surface: tube, bezier_sweep, revolution, sphere, cylinder, box, torus, capsule, prism, quad
#   Field:   marching_cubes, sdf_mesh
#   Instance: multimesh_scatter
#
# The tube() function is extracted from the duplicated code in
# CreatureMorphology._create_tube_mesh and TreeMorphology._add_branch_segment.

class_name MorphoPrimitive
extends RefCounted


# ═══════════════════════════════════════════════════════════════
# SURFACE GENERATORS — produce manifold meshes
# ═══════════════════════════════════════════════════════════════

## Tapered tube between two points. The fundamental building block of
## creature spines, tree branches, flower stems, and fungus stalks.
## Extracted from CreatureMorphology + TreeMorphology (identical code).
static func tube(start: Vector3, end: Vector3,
		start_radius: float, end_radius: float, sides: int = 6) -> Mesh:

	var forward: Vector3 = end - start
	var length: float = forward.length()
	if length < 0.001:
		return null
	forward = forward.normalized()

	var right: Vector3
	if absf(forward.dot(Vector3.UP)) < 0.99:
		right = forward.cross(Vector3.UP).normalized()
	else:
		right = forward.cross(Vector3.RIGHT).normalized()
	var up: Vector3 = right.cross(forward).normalized()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings: int = 2
	var ring_verts: Array = []

	for ri in rings:
		var t: float = float(ri) / float(rings - 1)
		var pos: Vector3 = start.lerp(end, t)
		var radius: float = lerpf(start_radius, end_radius, t)
		var ring: Array = []
		for si in sides:
			var angle: float = TAU * float(si) / float(sides)
			var offset: Vector3 = (right * cos(angle) + up * sin(angle)) * radius
			ring.append(pos + offset)
		ring_verts.append(ring)

	_triangulate_rings(st, ring_verts, sides)
	st.generate_normals()
	return st.commit()


## Multi-ring tube along an array of positions with per-ring radii.
## For segmented bodies, curved branches, or any path-following form.
static func multi_tube(positions: Array, radii: Array, sides: int = 6) -> Mesh:
	if positions.size() < 2 or positions.size() != radii.size():
		return null

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_verts: Array = []

	for ri in positions.size():
		var pos: Vector3 = positions[ri] as Vector3
		var radius: float = radii[ri] as float

		# Compute local frame from forward direction
		var forward: Vector3
		if ri == 0:
			forward = ((positions[1] as Vector3) - pos).normalized()
		elif ri == positions.size() - 1:
			forward = (pos - (positions[ri - 1] as Vector3)).normalized()
		else:
			forward = ((positions[ri + 1] as Vector3) - (positions[ri - 1] as Vector3)).normalized()

		var right: Vector3
		if absf(forward.dot(Vector3.UP)) < 0.99:
			right = forward.cross(Vector3.UP).normalized()
		else:
			right = forward.cross(Vector3.RIGHT).normalized()
		var up: Vector3 = right.cross(forward).normalized()

		var ring: Array = []
		for si in sides:
			var angle: float = TAU * float(si) / float(sides)
			var offset: Vector3 = (right * cos(angle) + up * sin(angle)) * radius
			ring.append(pos + offset)
		ring_verts.append(ring)

	_triangulate_rings(st, ring_verts, sides)
	st.generate_normals()
	return st.commit()


## Surface of revolution: rotate a 2D profile around the Y axis.
## For mushroom caps, vases, domes, bells, and any axially symmetric form.
## profile is an Array of Vector2 where x=radius, y=height.
static func revolution(profile: Array, segments: int = 12) -> Mesh:
	if profile.size() < 2:
		return null

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_verts: Array = []
	for pi in profile.size():
		var p: Vector2 = profile[pi] as Vector2
		var ring: Array = []
		for si in segments:
			var angle: float = TAU * float(si) / float(segments)
			ring.append(Vector3(cos(angle) * p.x, p.y, sin(angle) * p.x))
		ring_verts.append(ring)

	_triangulate_rings(st, ring_verts, segments)
	st.generate_normals()
	return st.commit()


## Bézier sweep: sweep a cross-section along a cubic Bézier curve.
## For petals, leaves, tentacles, and any curved ribbon.
## control_points: 4 Vector3 (cubic Bézier), cross_section: Array of Vector2,
## twist_degrees: total twist along the sweep.
static func bezier_sweep(control_points: Array, cross_section: Array,
		segments: int = 10, twist_degrees: float = 0.0) -> Mesh:
	if control_points.size() != 4 or cross_section.size() < 2:
		return null

	var p0: Vector3 = control_points[0] as Vector3
	var p1: Vector3 = control_points[1] as Vector3
	var p2: Vector3 = control_points[2] as Vector3
	var p3: Vector3 = control_points[3] as Vector3

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_verts: Array = []
	var sides: int = cross_section.size()

	for seg_idx in segments:
		var t: float = float(seg_idx) / maxf(segments - 1.0, 1.0)

		# Cubic Bézier evaluation
		var it: float = 1.0 - t
		var point: Vector3 = it * it * it * p0 + 3.0 * it * it * t * p1 + 3.0 * it * t * t * p2 + t * t * t * p3

		# Tangent (derivative of cubic Bézier)
		var tangent: Vector3 = (3.0 * it * it * (p1 - p0) + 6.0 * it * t * (p2 - p1) + 3.0 * t * t * (p3 - p2)).normalized()
		if tangent.length_squared() < 0.001:
			tangent = Vector3.FORWARD

		# Build local frame
		var up_ref: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var normal: Vector3 = tangent.cross(up_ref).normalized()
		var binormal: Vector3 = normal.cross(tangent).normalized()

		# Twist rotation
		var twist_rad: float = deg_to_rad(twist_degrees * t)
		var twist_basis := Basis().rotated(tangent, twist_rad)

		var ring: Array = []
		for si in sides:
			var cs: Vector2 = cross_section[si] as Vector2
			var local_offset: Vector3 = binormal * cs.x + normal * cs.y
			ring.append(point + twist_basis * local_offset)
		ring_verts.append(ring)

	_triangulate_rings(st, ring_verts, sides)
	st.generate_normals()
	return st.commit()


# ═══════════════════════════════════════════════════════════════
# GODOT PRIMITIVE WRAPPERS — named constructors for built-in types
# ═══════════════════════════════════════════════════════════════

static func sphere(radius: float = 0.5, radial_segments: int = 16, rings: int = 8) -> Mesh:
	var m := SphereMesh.new()
	m.radius = radius
	m.height = radius * 2.0
	m.radial_segments = radial_segments
	m.rings = rings
	return m

static func cylinder(top_radius: float = 0.5, bottom_radius: float = 0.5,
		height: float = 1.0, radial_segments: int = 8) -> Mesh:
	var m := CylinderMesh.new()
	m.top_radius = top_radius
	m.bottom_radius = bottom_radius
	m.height = height
	m.radial_segments = radial_segments
	return m

static func cone(radius: float = 0.5, height: float = 1.0, radial_segments: int = 8) -> Mesh:
	return cylinder(0.0, radius, height, radial_segments)

static func box(size: Vector3 = Vector3.ONE) -> Mesh:
	var m := BoxMesh.new()
	m.size = size
	return m

static func torus(inner_radius: float = 0.2, outer_radius: float = 0.5,
		ring_segments: int = 16, rings: int = 32) -> Mesh:
	var m := TorusMesh.new()
	m.inner_radius = inner_radius
	m.outer_radius = outer_radius
	m.ring_segments = ring_segments
	m.rings = rings
	return m

static func capsule(radius: float = 0.5, height: float = 1.0,
		radial_segments: int = 16, rings: int = 8) -> Mesh:
	var m := CapsuleMesh.new()
	m.radius = radius
	m.height = height
	m.radial_segments = radial_segments
	m.rings = rings
	return m

static func prism(left_to_right: float = 1.0, size: Vector3 = Vector3.ONE) -> Mesh:
	var m := PrismMesh.new()
	m.left_to_right = left_to_right
	m.size = size
	return m

static func quad(size: Vector2 = Vector2.ONE) -> Mesh:
	var m := QuadMesh.new()
	m.size = size
	return m

static func plane(size: Vector2 = Vector2(2.0, 2.0), subdivide_w: int = 0, subdivide_d: int = 0) -> Mesh:
	var m := PlaneMesh.new()
	m.size = size
	m.subdivide_width = subdivide_w
	m.subdivide_depth = subdivide_d
	return m


# ═══════════════════════════════════════════════════════════════
# INSTANCE GENERATORS — produce MultiMeshInstance3D
# ═══════════════════════════════════════════════════════════════

## Create a MultiMeshInstance3D from a template mesh and per-instance data.
## transforms: Array of Transform3D
## colors: Array of Color (optional, same length as transforms)
## custom_data: Array of Color (optional, for shader INSTANCE_CUSTOM)
static func multimesh_scatter(template_mesh: Mesh, transforms: Array,
		colors: Array = [], custom_data: Array = []) -> MultiMeshInstance3D:

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = template_mesh
	mm.use_colors = colors.size() > 0
	mm.use_custom_data = custom_data.size() > 0
	mm.instance_count = transforms.size()

	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i] as Transform3D)
		if colors.size() > i:
			mm.set_instance_color(i, colors[i] as Color)
		if custom_data.size() > i:
			mm.set_instance_custom_data(i, custom_data[i] as Color)

	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	return mmi


# ═══════════════════════════════════════════════════════════════
# FIELD GENERATORS — produce mesh from scalar fields
# ═══════════════════════════════════════════════════════════════

## Generate mesh from a signed distance field function.
## distance_func: Callable(Vector3) -> float (negative = inside)
## bounds: AABB defining the sampling volume
## resolution: voxels per axis
static func sdf_mesh(distance_func: Callable, bounds: AABB,
		resolution: int = 20) -> Mesh:

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var step: Vector3 = bounds.size / float(resolution)
	var iso_value: float = 0.0

	for xi in resolution:
		for yi in resolution:
			for zi in resolution:
				var corner: Vector3 = bounds.position + Vector3(xi, yi, zi) * step
				# Sample 8 corners of the cube
				var values: Array = []
				for dx in [0, 1]:
					for dy in [0, 1]:
						for dz in [0, 1]:
							var p: Vector3 = corner + Vector3(dx, dy, dz) * step
							values.append(distance_func.call(p))

				# Simple marching: if any corner crosses the surface, add a quad
				var inside_count: int = 0
				for v in values:
					if (v as float) < iso_value:
						inside_count += 1
				if inside_count == 0 or inside_count == 8:
					continue

				# Surface crossing — add a face at the center
				var center: Vector3 = corner + step * 0.5
				var normal: Vector3 = _sdf_gradient(distance_func, center, step.x * 0.1).normalized()

				var right: Vector3
				if absf(normal.dot(Vector3.UP)) < 0.99:
					right = normal.cross(Vector3.UP).normalized()
				else:
					right = normal.cross(Vector3.RIGHT).normalized()
				var up: Vector3 = right.cross(normal).normalized()

				var half: float = step.x * 0.4
				var v0: Vector3 = center + (-right - up) * half
				var v1: Vector3 = center + (right - up) * half
				var v2: Vector3 = center + (right + up) * half
				var v3: Vector3 = center + (-right + up) * half

				st.set_normal(normal); st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
				st.set_normal(normal); st.set_uv(Vector2(1, 0)); st.add_vertex(v1)
				st.set_normal(normal); st.set_uv(Vector2(1, 1)); st.add_vertex(v2)

				st.set_normal(normal); st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
				st.set_normal(normal); st.set_uv(Vector2(1, 1)); st.add_vertex(v2)
				st.set_normal(normal); st.set_uv(Vector2(0, 1)); st.add_vertex(v3)

	st.generate_normals()
	return st.commit()


# ═══════════════════════════════════════════════════════════════
# SDF COMBINATORS — composable distance functions
# ═══════════════════════════════════════════════════════════════

## Sphere SDF: returns distance from point to sphere surface
static func sdf_sphere(center: Vector3, radius: float) -> Callable:
	return func(p: Vector3) -> float: return (p - center).length() - radius

## Box SDF: returns distance from point to box surface
static func sdf_box(center: Vector3, half_extents: Vector3) -> Callable:
	return func(p: Vector3) -> float:
		var d: Vector3 = (p - center).abs() - half_extents
		return Vector3(maxf(d.x, 0), maxf(d.y, 0), maxf(d.z, 0)).length() + minf(maxf(d.x, maxf(d.y, d.z)), 0.0)

## Torus SDF
static func sdf_torus(center: Vector3, major_r: float, minor_r: float) -> Callable:
	return func(p: Vector3) -> float:
		var q: Vector3 = p - center
		var q2: Vector2 = Vector2(Vector2(q.x, q.z).length() - major_r, q.y)
		return q2.length() - minor_r

## Union: min(a, b)
static func sdf_union(a: Callable, b: Callable) -> Callable:
	return func(p: Vector3) -> float: return minf(a.call(p) as float, b.call(p) as float)

## Subtraction: max(a, -b)
static func sdf_subtract(a: Callable, b: Callable) -> Callable:
	return func(p: Vector3) -> float: return maxf(a.call(p) as float, -(b.call(p) as float))

## Intersection: max(a, b)
static func sdf_intersect(a: Callable, b: Callable) -> Callable:
	return func(p: Vector3) -> float: return maxf(a.call(p) as float, b.call(p) as float)

## Smooth union with blending factor k
static func sdf_smooth_union(a: Callable, b: Callable, k: float = 0.1) -> Callable:
	return func(p: Vector3) -> float:
		var da: float = a.call(p) as float
		var db: float = b.call(p) as float
		var h: float = clampf(0.5 + 0.5 * (db - da) / k, 0.0, 1.0)
		return lerpf(db, da, h) - k * h * (1.0 - h)


# ═══════════════════════════════════════════════════════════════
# INTERNAL UTILITIES
# ═══════════════════════════════════════════════════════════════

## Triangulate between consecutive rings of vertices.
## Shared by tube, multi_tube, revolution, bezier_sweep.
static func _triangulate_rings(st: SurfaceTool, ring_verts: Array, sides: int) -> void:
	for ri in range(ring_verts.size() - 1):
		var ring_a: Array = ring_verts[ri] as Array
		var ring_b: Array = ring_verts[ri + 1] as Array
		var total_rings: int = ring_verts.size()

		for si in range(sides):
			var si_next: int = (si + 1) % sides

			var v00: Vector3 = ring_a[si] as Vector3
			var v01: Vector3 = ring_a[si_next] as Vector3
			var v10: Vector3 = ring_b[si] as Vector3
			var v11: Vector3 = ring_b[si_next] as Vector3

			var t0: float = float(ri) / maxf(total_rings - 1.0, 1.0)
			var t1: float = float(ri + 1) / maxf(total_rings - 1.0, 1.0)
			var s0: float = float(si) / float(sides)
			var s1: float = float(si + 1) / float(sides)

			var n1: Vector3 = (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n1); st.set_uv(Vector2(s0, t0)); st.add_vertex(v00)
			st.set_normal(n1); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n1); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)

			var n2: Vector3 = (v11 - v01).cross(v10 - v01).normalized()
			st.set_normal(n2); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)
			st.set_normal(n2); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n2); st.set_uv(Vector2(s1, t1)); st.add_vertex(v11)


## Compute gradient of an SDF at a point (for normal estimation).
static func _sdf_gradient(distance_func: Callable, p: Vector3, eps: float) -> Vector3:
	var dx: float = (distance_func.call(p + Vector3(eps, 0, 0)) as float) - (distance_func.call(p - Vector3(eps, 0, 0)) as float)
	var dy: float = (distance_func.call(p + Vector3(0, eps, 0)) as float) - (distance_func.call(p - Vector3(0, eps, 0)) as float)
	var dz: float = (distance_func.call(p + Vector3(0, 0, eps)) as float) - (distance_func.call(p - Vector3(0, 0, eps)) as float)
	return Vector3(dx, dy, dz)
