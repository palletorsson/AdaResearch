# MorphoPrimitive.gd — Atomic form generators for the universal morphology engine
#
# Pure geometry library. No DNA dependency. Each static function takes
# parameters and returns a Mesh (ArrayMesh). These are the atoms from which
# all form is composed.
#
# Categories:
#   Surface: tube, bezier_sweep, revolution, sphere, cylinder, box, torus, capsule, prism, quad
#   Parametric: superformula, superformula_body
#   Field:   marching_cubes (interpolated isosurface), sdf_mesh (cheap quad-per-cell)
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
# PARAMETRIC GENERATORS — Gielis superformula
# ═══════════════════════════════════════════════════════════════

## Gielis superformula radius for one angle:
##   r(angle) = pow(pow(abs(cos(m*angle/4)/a), n2)
##            +      pow(abs(sin(m*angle/4)/b), n3), -1/n1)
## A single closed-form polar curve that morphs between circles, polygons,
## stars, and gear-like lobes as m/n1/n2/n3 vary. Guards |a|,|b|,|n1| away
## from zero and clamps the result so degenerate params cannot blow up to inf.
static func superformula(angle: float, m: float, n1: float, n2: float, n3: float,
		a: float = 1.0, b: float = 1.0) -> float:
	var sa: float = maxf(absf(a), 0.0001)
	var sb: float = maxf(absf(b), 0.0001)
	var t: float = m * angle * 0.25
	var c_term: float = pow(absf(cos(t) / sa), n2)
	var s_term: float = pow(absf(sin(t) / sb), n3)
	var inner: float = c_term + s_term
	if inner < 0.00001:
		return 6.0
	var safe_n1: float = maxf(absf(n1), 0.0001)
	var r: float = pow(inner, -1.0 / safe_n1)
	if not is_finite(r):
		return 6.0
	return clampf(r, 0.0, 6.0)


## Build a closed body as the SPHERICAL PRODUCT of two superformulae: one
## drives longitude (theta over [-PI, PI], the u axis), the other latitude
## (phi over [-PI/2, PI/2], the v axis). Yields compound-curved carapaces,
## pods, and shells that primitives cannot express. Poles are welded (the
## longitude ring at each cap collapses to one averaged vertex) and normals
## are generated; UVs come from normalized (u, v).
##
## p is a Dictionary of params. Recognised keys (all optional, sensible
## defaults applied):
##   Longitude formula 1:  m1, n1_1, n2_1, n3_1, a1, b1
##   Latitude  formula 2:  m2, n1_2, n2_2, n3_2, a2, b2
##   scale: Vector3        anisotropic scaling (default Vector3.ONE)
## Mismatched integer symmetries m1 != m2 give asymmetric, biomech forms.
static func superformula_body(p: Dictionary, u_steps: int = 96, v_steps: int = 56) -> Mesh:
	var us: int = maxi(u_steps, 3)
	var vs: int = maxi(v_steps, 2)

	# Resolve params with defaults.
	var m1: float = float(p.get("m1", 5.0))
	var n1_1: float = float(p.get("n1_1", 0.3))
	var n2_1: float = float(p.get("n2_1", 1.0))
	var n3_1: float = float(p.get("n3_1", 1.0))
	var a1: float = float(p.get("a1", 1.0))
	var b1: float = float(p.get("b1", 1.0))
	var m2: float = float(p.get("m2", 4.0))
	var n1_2: float = float(p.get("n1_2", 1.0))
	var n2_2: float = float(p.get("n2_2", 1.0))
	var n3_2: float = float(p.get("n3_2", 1.0))
	var a2: float = float(p.get("a2", 1.0))
	var b2: float = float(p.get("b2", 1.0))
	var scale: Vector3 = p.get("scale", Vector3.ONE) as Vector3

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Precompute the (us+1) x (vs+1) lattice so each shared edge reuses
	# identical vertices (this is what welds the seam and the poles).
	var grid: Array = []
	for ui: int in range(us + 1):
		var u_frac: float = float(ui) / float(us)
		var theta: float = lerpf(-PI, PI, u_frac)
		var r1: float = superformula(theta, m1, n1_1, n2_1, n3_1, a1, b1)
		var row: Array[Vector3] = []
		for vi: int in range(vs + 1):
			var v_frac: float = float(vi) / float(vs)
			var phi: float = lerpf(-PI * 0.5, PI * 0.5, v_frac)
			var r2: float = superformula(phi, m2, n1_2, n2_2, n3_2, a2, b2)

			var cos_phi: float = cos(phi)
			var px: float = r1 * cos(theta) * r2 * cos_phi
			var py: float = r1 * sin(theta) * r2 * cos_phi
			var pz: float = r2 * sin(phi)
			# Superformula z = our up (Y); component-wise scale for anisotropy.
			row.append(Vector3(px, pz, py) * scale)
		grid.append(row)

	# Weld the poles: at vi==0 (phi=-PI/2) and vi==vs (phi=+PI/2) every
	# longitude must collapse to a single averaged vertex, else the cap fans.
	var south: Vector3 = _average_pole(grid, 0, us)
	var north: Vector3 = _average_pole(grid, vs, us)
	for ui: int in range(us + 1):
		(grid[ui] as Array)[0] = south
		(grid[ui] as Array)[vs] = north

	# Two triangles per quad, UV from normalized (theta, phi).
	for ui: int in range(us):
		var u0: float = float(ui) / float(us)
		var u1: float = float(ui + 1) / float(us)
		var row_a: Array = grid[ui] as Array
		var row_b: Array = grid[ui + 1] as Array
		for vi: int in range(vs):
			var w0: float = float(vi) / float(vs)
			var w1: float = float(vi + 1) / float(vs)

			var v00: Vector3 = row_a[vi] as Vector3
			var v01: Vector3 = row_a[vi + 1] as Vector3
			var v10: Vector3 = row_b[vi] as Vector3
			var v11: Vector3 = row_b[vi + 1] as Vector3

			st.set_uv(Vector2(u0, w0)); st.add_vertex(v00)
			st.set_uv(Vector2(u0, w1)); st.add_vertex(v01)
			st.set_uv(Vector2(u1, w0)); st.add_vertex(v10)

			st.set_uv(Vector2(u1, w0)); st.add_vertex(v10)
			st.set_uv(Vector2(u0, w1)); st.add_vertex(v01)
			st.set_uv(Vector2(u1, w1)); st.add_vertex(v11)

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


## Proper marching cubes — the smooth, watertight counterpart to sdf_mesh.
## Where sdf_mesh emits one camera-facing quad per surface-crossing cell (a
## cloud of stair-stepped facets), this runs a full Paul-Bourke pass: per cell
## it samples the 8 corners, looks up edgeTable/triTable, linearly interpolates
## the iso-crossing along each crossed edge (mu = (iso - va) / (vb - va)), and
## emits connected triangles. The result is a single interpolated isosurface.
##
## field: Callable(Vector3) -> float, negative = inside (same convention as the
##   sdf_* combinators, so it composes with sdf_smooth_union / subtract / etc.).
## bounds: AABB sampling volume. resolution: cells per axis.
## color_func (optional): Callable(Vector3) -> Color called per emitted vertex;
##   if valid, set as the vertex colour (enables per-vertex material blends,
##   e.g. a flesh<->metal fusion gradient). If invalid (default), no colours.
## Normals are the normalized field gradient at each vertex (central
## differences) — smoother for an isosurface than face normals.
static func marching_cubes(field: Callable, bounds: AABB,
		resolution: int = 48, color_func: Callable = Callable()) -> Mesh:

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var res: int = maxi(resolution, 1)
	var step: Vector3 = bounds.size / float(res)
	var grad_eps: float = step.x * 0.5
	var iso: float = 0.0
	var use_color: bool = color_func.is_valid()

	# Corner offsets in the canonical marching-cubes order (0..7).
	var corner_off: Array[Vector3] = [
		Vector3(0, 0, 0), Vector3(1, 0, 0), Vector3(1, 1, 0), Vector3(0, 1, 0),
		Vector3(0, 0, 1), Vector3(1, 0, 1), Vector3(1, 1, 1), Vector3(0, 1, 1)]
	# Edge endpoints (which two corners each of the 12 edges connects).
	var edge_corners: Array = [
		[0, 1], [1, 2], [2, 3], [3, 0],
		[4, 5], [5, 6], [6, 7], [7, 4],
		[0, 4], [1, 5], [2, 6], [3, 7]]

	var edge_table: PackedInt32Array = _mc_edge_table()
	var tri_table: Array = _mc_tri_table()

	# Reusable per-cell scratch.
	var cube_val: Array[float] = [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0]
	var cube_pos: Array[Vector3] = [
		Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO,
		Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Vector3.ZERO]
	var vert_list: Array[Vector3] = []
	vert_list.resize(12)

	for xi: int in res:
		for yi: int in res:
			for zi: int in res:
				var base: Vector3 = bounds.position + Vector3(xi, yi, zi) * step
				# Sample 8 corners; build cube index from inside (val < iso) bits.
				var cube_index: int = 0
				for ci: int in 8:
					var cp: Vector3 = base + (corner_off[ci] as Vector3) * step
					cube_pos[ci] = cp
					var val: float = field.call(cp) as float
					cube_val[ci] = val
					if val < iso:
						cube_index |= (1 << ci)

				var edges: int = edge_table[cube_index]
				if edges == 0:
					continue

				# Interpolate the iso-crossing point on each active edge.
				for ei: int in 12:
					if (edges & (1 << ei)) != 0:
						var ec: Array = edge_corners[ei] as Array
						var ca: int = ec[0] as int
						var cb: int = ec[1] as int
						vert_list[ei] = _mc_vertex_interp(iso,
							cube_pos[ca], cube_pos[cb], cube_val[ca], cube_val[cb])

				# Emit triangles from the tri table (-1 terminated).
				var tris: PackedInt32Array = tri_table[cube_index]
				var ti: int = 0
				while ti < tris.size() and tris[ti] != -1:
					var va: Vector3 = vert_list[tris[ti]]
					var vb: Vector3 = vert_list[tris[ti + 1]]
					var vc: Vector3 = vert_list[tris[ti + 2]]
					var na: Vector3 = _sdf_gradient(field, va, grad_eps).normalized()
					var nb: Vector3 = _sdf_gradient(field, vb, grad_eps).normalized()
					var nc: Vector3 = _sdf_gradient(field, vc, grad_eps).normalized()
					if use_color:
						st.set_color(color_func.call(va) as Color)
					st.set_normal(na); st.add_vertex(va)
					if use_color:
						st.set_color(color_func.call(vb) as Color)
					st.set_normal(nb); st.add_vertex(vb)
					if use_color:
						st.set_color(color_func.call(vc) as Color)
					st.set_normal(nc); st.add_vertex(vc)
					ti += 3

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

## Smooth subtraction (carve b out of a) with blending factor k.
## The polynomial smooth-max counterpart to sdf_subtract — softens the
## cut so the carved cavity meets the body across a fillet instead of a
## hard crease. Composes with marching_cubes / sdf_smooth_union.
static func sdf_smooth_subtract(a: Callable, b: Callable, k: float = 0.1) -> Callable:
	return func(p: Vector3) -> float:
		var da: float = a.call(p) as float
		var db: float = b.call(p) as float
		var h: float = clampf(0.5 - 0.5 * (da + db) / k, 0.0, 1.0)
		return lerpf(da, -db, h) + k * h * (1.0 - h)

## Smooth intersection with blending factor k. The polynomial smooth-max
## counterpart to sdf_intersect — rounds the shared edge where the two
## solids overlap into a fillet. Composes with the other sdf combinators.
static func sdf_smooth_intersect(a: Callable, b: Callable, k: float = 0.1) -> Callable:
	return func(p: Vector3) -> float:
		var da: float = a.call(p) as float
		var db: float = b.call(p) as float
		var h: float = clampf(0.5 - 0.5 * (db - da) / k, 0.0, 1.0)
		return lerpf(db, da, h) + k * h * (1.0 - h)


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


## Average every longitude sample at a given latitude row into one point.
## Collapses a superformula_body cap to a single welded vertex (no fan).
static func _average_pole(grid: Array, vi: int, u_steps: int) -> Vector3:
	var acc := Vector3.ZERO
	for ui: int in range(u_steps + 1):
		acc += (grid[ui] as Array)[vi] as Vector3
	return acc / float(u_steps + 1)


## Linear interpolation of the iso-crossing between two cube corners.
## mu = (iso - v1) / (v2 - v1); guards near-equal values against div-by-zero.
static func _mc_vertex_interp(iso: float, p1: Vector3, p2: Vector3,
		v1: float, v2: float) -> Vector3:
	if absf(iso - v1) < 0.00001:
		return p1
	if absf(iso - v2) < 0.00001:
		return p2
	if absf(v1 - v2) < 0.00001:
		return p1
	var mu: float = (iso - v1) / (v2 - v1)
	return p1 + (p2 - p1) * mu


# ═══════════════════════════════════════════════════════════════
# PAUL BOURKE MARCHING CUBES TABLES
# edgeTable[256], triTable[256][16] (-1 terminated).
# Verbatim from http://paulbourke.net/geometry/polygonise/
# ═══════════════════════════════════════════════════════════════

## edgeTable[256]: for each of the 256 corner-inside masks, a 12-bit mask of
## which cube edges the isosurface crosses.
static func _mc_edge_table() -> PackedInt32Array:
	return PackedInt32Array([
		0x0  , 0x109, 0x203, 0x30a, 0x406, 0x50f, 0x605, 0x70c,
		0x80c, 0x905, 0xa0f, 0xb06, 0xc0a, 0xd03, 0xe09, 0xf00,
		0x190, 0x99 , 0x393, 0x29a, 0x596, 0x49f, 0x795, 0x69c,
		0x99c, 0x895, 0xb9f, 0xa96, 0xd9a, 0xc93, 0xf99, 0xe90,
		0x230, 0x339, 0x33 , 0x13a, 0x636, 0x73f, 0x435, 0x53c,
		0xa3c, 0xb35, 0x83f, 0x936, 0xe3a, 0xf33, 0xc39, 0xd30,
		0x3a0, 0x2a9, 0x1a3, 0xaa , 0x7a6, 0x6af, 0x5a5, 0x4ac,
		0xbac, 0xaa5, 0x9af, 0x8a6, 0xfaa, 0xea3, 0xda9, 0xca0,
		0x460, 0x569, 0x663, 0x76a, 0x66 , 0x16f, 0x265, 0x36c,
		0xc6c, 0xd65, 0xe6f, 0xf66, 0x86a, 0x963, 0xa69, 0xb60,
		0x5f0, 0x4f9, 0x7f3, 0x6fa, 0x1f6, 0xff , 0x3f5, 0x2fc,
		0xdfc, 0xcf5, 0xfff, 0xef6, 0x9fa, 0x8f3, 0xbf9, 0xaf0,
		0x650, 0x759, 0x453, 0x55a, 0x256, 0x35f, 0x55 , 0x15c,
		0xe5c, 0xf55, 0xc5f, 0xd56, 0xa5a, 0xb53, 0x859, 0x950,
		0x7c0, 0x6c9, 0x5c3, 0x4ca, 0x3c6, 0x2cf, 0x1c5, 0xcc ,
		0xfcc, 0xec5, 0xdcf, 0xcc6, 0xbca, 0xac3, 0x9c9, 0x8c0,
		0x8c0, 0x9c9, 0xac3, 0xbca, 0xcc6, 0xdcf, 0xec5, 0xfcc,
		0xcc , 0x1c5, 0x2cf, 0x3c6, 0x4ca, 0x5c3, 0x6c9, 0x7c0,
		0x950, 0x859, 0xb53, 0xa5a, 0xd56, 0xc5f, 0xf55, 0xe5c,
		0x15c, 0x55 , 0x35f, 0x256, 0x55a, 0x453, 0x759, 0x650,
		0xaf0, 0xbf9, 0x8f3, 0x9fa, 0xef6, 0xfff, 0xcf5, 0xdfc,
		0x2fc, 0x3f5, 0xff , 0x1f6, 0x6fa, 0x7f3, 0x4f9, 0x5f0,
		0xb60, 0xa69, 0x963, 0x86a, 0xf66, 0xe6f, 0xd65, 0xc6c,
		0x36c, 0x265, 0x16f, 0x66 , 0x76a, 0x663, 0x569, 0x460,
		0xca0, 0xda9, 0xea3, 0xfaa, 0x8a6, 0x9af, 0xaa5, 0xbac,
		0x4ac, 0x5a5, 0x6af, 0x7a6, 0xaa , 0x1a3, 0x2a9, 0x3a0,
		0xd30, 0xc39, 0xf33, 0xe3a, 0x936, 0x83f, 0xb35, 0xa3c,
		0x53c, 0x435, 0x73f, 0x636, 0x13a, 0x33 , 0x339, 0x230,
		0xe90, 0xf99, 0xc93, 0xd9a, 0xa96, 0xb9f, 0x895, 0x99c,
		0x69c, 0x795, 0x49f, 0x596, 0x29a, 0x393, 0x99 , 0x190,
		0xf00, 0xe09, 0xd03, 0xc0a, 0xb06, 0xa0f, 0x905, 0x80c,
		0x70c, 0x605, 0x50f, 0x406, 0x30a, 0x203, 0x109, 0x0
	])


## triTable[256]: for each corner-inside mask, the edge-index triples (-1
## terminated) describing the triangles to emit. Each entry is a typed
## PackedInt32Array so the marching-cubes loop indexes it without warnings.
static func _mc_tri_table() -> Array:
	var raw: Array = [
		[-1],
		[0, 8, 3, -1],
		[0, 1, 9, -1],
		[1, 8, 3, 9, 8, 1, -1],
		[1, 2, 10, -1],
		[0, 8, 3, 1, 2, 10, -1],
		[9, 2, 10, 0, 2, 9, -1],
		[2, 8, 3, 2, 10, 8, 10, 9, 8, -1],
		[3, 11, 2, -1],
		[0, 11, 2, 8, 11, 0, -1],
		[1, 9, 0, 2, 3, 11, -1],
		[1, 11, 2, 1, 9, 11, 9, 8, 11, -1],
		[3, 10, 1, 11, 10, 3, -1],
		[0, 10, 1, 0, 8, 10, 8, 11, 10, -1],
		[3, 9, 0, 3, 11, 9, 11, 10, 9, -1],
		[9, 8, 10, 10, 8, 11, -1],
		[4, 7, 8, -1],
		[4, 3, 0, 7, 3, 4, -1],
		[0, 1, 9, 8, 4, 7, -1],
		[4, 1, 9, 4, 7, 1, 7, 3, 1, -1],
		[1, 2, 10, 8, 4, 7, -1],
		[3, 4, 7, 3, 0, 4, 1, 2, 10, -1],
		[9, 2, 10, 9, 0, 2, 8, 4, 7, -1],
		[2, 10, 9, 2, 9, 7, 2, 7, 3, 7, 9, 4, -1],
		[8, 4, 7, 3, 11, 2, -1],
		[11, 4, 7, 11, 2, 4, 2, 0, 4, -1],
		[9, 0, 1, 8, 4, 7, 2, 3, 11, -1],
		[4, 7, 11, 9, 4, 11, 9, 11, 2, 9, 2, 1, -1],
		[3, 10, 1, 3, 11, 10, 7, 8, 4, -1],
		[1, 11, 10, 1, 4, 11, 1, 0, 4, 7, 11, 4, -1],
		[4, 7, 8, 9, 0, 11, 9, 11, 10, 11, 0, 3, -1],
		[4, 7, 11, 4, 11, 9, 9, 11, 10, -1],
		[9, 5, 4, -1],
		[9, 5, 4, 0, 8, 3, -1],
		[0, 5, 4, 1, 5, 0, -1],
		[8, 5, 4, 8, 3, 5, 3, 1, 5, -1],
		[1, 2, 10, 9, 5, 4, -1],
		[3, 0, 8, 1, 2, 10, 4, 9, 5, -1],
		[5, 2, 10, 5, 4, 2, 4, 0, 2, -1],
		[2, 10, 5, 3, 2, 5, 3, 5, 4, 3, 4, 8, -1],
		[9, 5, 4, 2, 3, 11, -1],
		[0, 11, 2, 0, 8, 11, 4, 9, 5, -1],
		[0, 5, 4, 0, 1, 5, 2, 3, 11, -1],
		[2, 1, 5, 2, 5, 8, 2, 8, 11, 4, 8, 5, -1],
		[10, 3, 11, 10, 1, 3, 9, 5, 4, -1],
		[4, 9, 5, 0, 8, 1, 8, 10, 1, 8, 11, 10, -1],
		[5, 4, 0, 5, 0, 11, 5, 11, 10, 11, 0, 3, -1],
		[5, 4, 8, 5, 8, 10, 10, 8, 11, -1],
		[9, 7, 8, 5, 7, 9, -1],
		[9, 3, 0, 9, 5, 3, 5, 7, 3, -1],
		[0, 7, 8, 0, 1, 7, 1, 5, 7, -1],
		[1, 5, 3, 3, 5, 7, -1],
		[9, 7, 8, 9, 5, 7, 10, 1, 2, -1],
		[10, 1, 2, 9, 5, 0, 5, 3, 0, 5, 7, 3, -1],
		[8, 0, 2, 8, 2, 5, 8, 5, 7, 10, 5, 2, -1],
		[2, 10, 5, 2, 5, 3, 3, 5, 7, -1],
		[7, 9, 5, 7, 8, 9, 3, 11, 2, -1],
		[9, 5, 7, 9, 7, 2, 9, 2, 0, 2, 7, 11, -1],
		[2, 3, 11, 0, 1, 8, 1, 7, 8, 1, 5, 7, -1],
		[11, 2, 1, 11, 1, 7, 7, 1, 5, -1],
		[9, 5, 8, 8, 5, 7, 10, 1, 3, 10, 3, 11, -1],
		[5, 7, 0, 5, 0, 9, 7, 11, 0, 1, 0, 10, 11, 10, 0, -1],
		[11, 10, 0, 11, 0, 3, 10, 5, 0, 8, 0, 7, 5, 7, 0, -1],
		[11, 10, 5, 7, 11, 5, -1],
		[10, 6, 5, -1],
		[0, 8, 3, 5, 10, 6, -1],
		[9, 0, 1, 5, 10, 6, -1],
		[1, 8, 3, 1, 9, 8, 5, 10, 6, -1],
		[1, 6, 5, 2, 6, 1, -1],
		[1, 6, 5, 1, 2, 6, 3, 0, 8, -1],
		[9, 6, 5, 9, 0, 6, 0, 2, 6, -1],
		[5, 9, 8, 5, 8, 2, 5, 2, 6, 3, 2, 8, -1],
		[2, 3, 11, 10, 6, 5, -1],
		[11, 0, 8, 11, 2, 0, 10, 6, 5, -1],
		[0, 1, 9, 2, 3, 11, 5, 10, 6, -1],
		[5, 10, 6, 1, 9, 2, 9, 11, 2, 9, 8, 11, -1],
		[6, 3, 11, 6, 5, 3, 5, 1, 3, -1],
		[0, 8, 11, 0, 11, 5, 0, 5, 1, 5, 11, 6, -1],
		[3, 11, 6, 0, 3, 6, 0, 6, 5, 0, 5, 9, -1],
		[6, 5, 9, 6, 9, 11, 11, 9, 8, -1],
		[5, 10, 6, 4, 7, 8, -1],
		[4, 3, 0, 4, 7, 3, 6, 5, 10, -1],
		[1, 9, 0, 5, 10, 6, 8, 4, 7, -1],
		[10, 6, 5, 1, 9, 7, 1, 7, 3, 7, 9, 4, -1],
		[6, 1, 2, 6, 5, 1, 4, 7, 8, -1],
		[1, 2, 5, 5, 2, 6, 3, 0, 4, 3, 4, 7, -1],
		[8, 4, 7, 9, 0, 5, 0, 6, 5, 0, 2, 6, -1],
		[7, 3, 9, 7, 9, 4, 3, 2, 9, 5, 9, 6, 2, 6, 9, -1],
		[3, 11, 2, 7, 8, 4, 10, 6, 5, -1],
		[5, 10, 6, 4, 7, 2, 4, 2, 0, 2, 7, 11, -1],
		[0, 1, 9, 4, 7, 8, 2, 3, 11, 5, 10, 6, -1],
		[9, 2, 1, 9, 11, 2, 9, 4, 11, 7, 11, 4, 5, 10, 6, -1],
		[8, 4, 7, 3, 11, 5, 3, 5, 1, 5, 11, 6, -1],
		[5, 1, 11, 5, 11, 6, 1, 0, 11, 7, 11, 4, 0, 4, 11, -1],
		[0, 5, 9, 0, 6, 5, 0, 3, 6, 11, 6, 3, 8, 4, 7, -1],
		[6, 5, 9, 6, 9, 11, 4, 7, 9, 7, 11, 9, -1],
		[10, 4, 9, 6, 4, 10, -1],
		[4, 10, 6, 4, 9, 10, 0, 8, 3, -1],
		[10, 0, 1, 10, 6, 0, 6, 4, 0, -1],
		[8, 3, 1, 8, 1, 6, 8, 6, 4, 6, 1, 10, -1],
		[1, 4, 9, 1, 2, 4, 2, 6, 4, -1],
		[3, 0, 8, 1, 2, 9, 2, 4, 9, 2, 6, 4, -1],
		[0, 2, 4, 4, 2, 6, -1],
		[8, 3, 2, 8, 2, 4, 4, 2, 6, -1],
		[10, 4, 9, 10, 6, 4, 11, 2, 3, -1],
		[0, 8, 2, 2, 8, 11, 4, 9, 10, 4, 10, 6, -1],
		[3, 11, 2, 0, 1, 6, 0, 6, 4, 6, 1, 10, -1],
		[6, 4, 1, 6, 1, 10, 4, 8, 1, 2, 1, 11, 8, 11, 1, -1],
		[9, 6, 4, 9, 3, 6, 9, 1, 3, 11, 6, 3, -1],
		[8, 11, 1, 8, 1, 0, 11, 6, 1, 9, 1, 4, 6, 4, 1, -1],
		[3, 11, 6, 3, 6, 0, 0, 6, 4, -1],
		[6, 4, 8, 11, 6, 8, -1],
		[7, 10, 6, 7, 8, 10, 8, 9, 10, -1],
		[0, 7, 3, 0, 10, 7, 0, 9, 10, 6, 7, 10, -1],
		[10, 6, 7, 1, 10, 7, 1, 7, 8, 1, 8, 0, -1],
		[10, 6, 7, 10, 7, 1, 1, 7, 3, -1],
		[1, 2, 6, 1, 6, 8, 1, 8, 9, 8, 6, 7, -1],
		[2, 6, 9, 2, 9, 1, 6, 7, 9, 0, 9, 3, 7, 3, 9, -1],
		[7, 8, 0, 7, 0, 6, 6, 0, 2, -1],
		[7, 3, 2, 6, 7, 2, -1],
		[2, 3, 11, 10, 6, 8, 10, 8, 9, 8, 6, 7, -1],
		[2, 0, 7, 2, 7, 11, 0, 9, 7, 6, 7, 10, 9, 10, 7, -1],
		[1, 8, 0, 1, 7, 8, 1, 10, 7, 6, 7, 10, 2, 3, 11, -1],
		[11, 2, 1, 11, 1, 7, 10, 6, 1, 6, 7, 1, -1],
		[8, 9, 6, 8, 6, 7, 9, 1, 6, 11, 6, 3, 1, 3, 6, -1],
		[0, 9, 1, 11, 6, 7, -1],
		[7, 8, 0, 7, 0, 6, 3, 11, 0, 11, 6, 0, -1],
		[7, 11, 6, -1],
		[7, 6, 11, -1],
		[3, 0, 8, 11, 7, 6, -1],
		[0, 1, 9, 11, 7, 6, -1],
		[8, 1, 9, 8, 3, 1, 11, 7, 6, -1],
		[10, 1, 2, 6, 11, 7, -1],
		[1, 2, 10, 3, 0, 8, 6, 11, 7, -1],
		[2, 9, 0, 2, 10, 9, 6, 11, 7, -1],
		[6, 11, 7, 2, 10, 3, 10, 8, 3, 10, 9, 8, -1],
		[7, 2, 3, 6, 2, 7, -1],
		[7, 0, 8, 7, 6, 0, 6, 2, 0, -1],
		[2, 7, 6, 2, 3, 7, 0, 1, 9, -1],
		[1, 6, 2, 1, 8, 6, 1, 9, 8, 8, 7, 6, -1],
		[10, 7, 6, 10, 1, 7, 1, 3, 7, -1],
		[10, 7, 6, 1, 7, 10, 1, 8, 7, 1, 0, 8, -1],
		[0, 3, 7, 0, 7, 10, 0, 10, 9, 6, 10, 7, -1],
		[7, 6, 10, 7, 10, 8, 8, 10, 9, -1],
		[6, 8, 4, 11, 8, 6, -1],
		[3, 6, 11, 3, 0, 6, 0, 4, 6, -1],
		[8, 6, 11, 8, 4, 6, 9, 0, 1, -1],
		[9, 4, 6, 9, 6, 3, 9, 3, 1, 11, 3, 6, -1],
		[6, 8, 4, 6, 11, 8, 2, 10, 1, -1],
		[1, 2, 10, 3, 0, 11, 0, 6, 11, 0, 4, 6, -1],
		[4, 11, 8, 4, 6, 11, 0, 2, 9, 2, 10, 9, -1],
		[10, 9, 3, 10, 3, 2, 9, 4, 3, 11, 3, 6, 4, 6, 3, -1],
		[8, 2, 3, 8, 4, 2, 4, 6, 2, -1],
		[0, 4, 2, 4, 6, 2, -1],
		[1, 9, 0, 2, 3, 4, 2, 4, 6, 4, 3, 8, -1],
		[1, 9, 4, 1, 4, 2, 2, 4, 6, -1],
		[8, 1, 3, 8, 6, 1, 8, 4, 6, 6, 10, 1, -1],
		[10, 1, 0, 10, 0, 6, 6, 0, 4, -1],
		[4, 6, 3, 4, 3, 8, 6, 10, 3, 0, 3, 9, 10, 9, 3, -1],
		[10, 9, 4, 6, 10, 4, -1],
		[4, 9, 5, 7, 6, 11, -1],
		[0, 8, 3, 4, 9, 5, 11, 7, 6, -1],
		[5, 0, 1, 5, 4, 0, 7, 6, 11, -1],
		[11, 7, 6, 8, 3, 4, 3, 5, 4, 3, 1, 5, -1],
		[9, 5, 4, 10, 1, 2, 7, 6, 11, -1],
		[6, 11, 7, 1, 2, 10, 0, 8, 3, 4, 9, 5, -1],
		[7, 6, 11, 5, 4, 10, 4, 2, 10, 4, 0, 2, -1],
		[3, 4, 8, 3, 5, 4, 3, 2, 5, 10, 5, 2, 11, 7, 6, -1],
		[7, 2, 3, 7, 6, 2, 5, 4, 9, -1],
		[9, 5, 4, 0, 8, 6, 0, 6, 2, 6, 8, 7, -1],
		[3, 6, 2, 3, 7, 6, 1, 5, 0, 5, 4, 0, -1],
		[6, 2, 8, 6, 8, 7, 2, 1, 8, 4, 8, 5, 1, 5, 8, -1],
		[9, 5, 4, 10, 1, 6, 1, 7, 6, 1, 3, 7, -1],
		[1, 6, 10, 1, 7, 6, 1, 0, 7, 8, 7, 0, 9, 5, 4, -1],
		[4, 0, 10, 4, 10, 5, 0, 3, 10, 6, 10, 7, 3, 7, 10, -1],
		[7, 6, 10, 7, 10, 8, 5, 4, 10, 4, 8, 10, -1],
		[6, 9, 5, 6, 11, 9, 11, 8, 9, -1],
		[3, 6, 11, 0, 6, 3, 0, 5, 6, 0, 9, 5, -1],
		[0, 11, 8, 0, 5, 11, 0, 1, 5, 5, 6, 11, -1],
		[6, 11, 3, 6, 3, 5, 5, 3, 1, -1],
		[1, 2, 10, 9, 5, 11, 9, 11, 8, 11, 5, 6, -1],
		[0, 11, 3, 0, 6, 11, 0, 9, 6, 5, 6, 9, 1, 2, 10, -1],
		[11, 8, 5, 11, 5, 6, 8, 0, 5, 10, 5, 2, 0, 2, 5, -1],
		[6, 11, 3, 6, 3, 5, 2, 10, 3, 10, 5, 3, -1],
		[5, 8, 9, 5, 2, 8, 5, 6, 2, 3, 8, 2, -1],
		[9, 5, 6, 9, 6, 0, 0, 6, 2, -1],
		[1, 5, 8, 1, 8, 0, 5, 6, 8, 3, 8, 2, 6, 2, 8, -1],
		[1, 5, 6, 2, 1, 6, -1],
		[1, 3, 6, 1, 6, 10, 3, 8, 6, 5, 6, 9, 8, 9, 6, -1],
		[10, 1, 0, 10, 0, 6, 9, 5, 0, 5, 6, 0, -1],
		[0, 3, 8, 5, 6, 10, -1],
		[10, 5, 6, -1],
		[11, 5, 10, 7, 5, 11, -1],
		[11, 5, 10, 11, 7, 5, 8, 3, 0, -1],
		[5, 11, 7, 5, 10, 11, 1, 9, 0, -1],
		[10, 7, 5, 10, 11, 7, 9, 8, 1, 8, 3, 1, -1],
		[11, 1, 2, 11, 7, 1, 7, 5, 1, -1],
		[0, 8, 3, 1, 2, 7, 1, 7, 5, 7, 2, 11, -1],
		[9, 7, 5, 9, 2, 7, 9, 0, 2, 2, 11, 7, -1],
		[7, 5, 2, 7, 2, 11, 5, 9, 2, 3, 2, 8, 9, 8, 2, -1],
		[2, 5, 10, 2, 3, 5, 3, 7, 5, -1],
		[8, 2, 0, 8, 5, 2, 8, 7, 5, 10, 2, 5, -1],
		[9, 0, 1, 5, 10, 3, 5, 3, 7, 3, 10, 2, -1],
		[9, 8, 2, 9, 2, 1, 8, 7, 2, 10, 2, 5, 7, 5, 2, -1],
		[1, 3, 5, 3, 7, 5, -1],
		[0, 8, 7, 0, 7, 1, 1, 7, 5, -1],
		[9, 0, 3, 9, 3, 5, 5, 3, 7, -1],
		[9, 8, 7, 5, 9, 7, -1],
		[5, 8, 4, 5, 10, 8, 10, 11, 8, -1],
		[5, 0, 4, 5, 11, 0, 5, 10, 11, 11, 3, 0, -1],
		[0, 1, 9, 8, 4, 10, 8, 10, 11, 10, 4, 5, -1],
		[10, 11, 4, 10, 4, 5, 11, 3, 4, 9, 4, 1, 3, 1, 4, -1],
		[2, 5, 1, 2, 8, 5, 2, 11, 8, 4, 5, 8, -1],
		[0, 4, 11, 0, 11, 3, 4, 5, 11, 2, 11, 1, 5, 1, 11, -1],
		[0, 2, 5, 0, 5, 9, 2, 11, 5, 4, 5, 8, 11, 8, 5, -1],
		[9, 4, 5, 2, 11, 3, -1],
		[2, 5, 10, 3, 5, 2, 3, 4, 5, 3, 8, 4, -1],
		[5, 10, 2, 5, 2, 4, 4, 2, 0, -1],
		[3, 10, 2, 3, 5, 10, 3, 8, 5, 4, 5, 8, 0, 1, 9, -1],
		[5, 10, 2, 5, 2, 4, 1, 9, 2, 9, 4, 2, -1],
		[8, 4, 5, 8, 5, 3, 3, 5, 1, -1],
		[0, 4, 5, 1, 0, 5, -1],
		[8, 4, 5, 8, 5, 3, 9, 0, 5, 0, 3, 5, -1],
		[9, 4, 5, -1],
		[4, 11, 7, 4, 9, 11, 9, 10, 11, -1],
		[0, 8, 3, 4, 9, 7, 9, 11, 7, 9, 10, 11, -1],
		[1, 10, 11, 1, 11, 4, 1, 4, 0, 7, 4, 11, -1],
		[3, 1, 4, 3, 4, 8, 1, 10, 4, 7, 4, 11, 10, 11, 4, -1],
		[4, 11, 7, 9, 11, 4, 9, 2, 11, 9, 1, 2, -1],
		[9, 7, 4, 9, 11, 7, 9, 1, 11, 2, 11, 1, 0, 8, 3, -1],
		[11, 7, 4, 11, 4, 2, 2, 4, 0, -1],
		[11, 7, 4, 11, 4, 2, 8, 3, 4, 3, 2, 4, -1],
		[2, 9, 10, 2, 7, 9, 2, 3, 7, 7, 4, 9, -1],
		[9, 10, 7, 9, 7, 4, 10, 2, 7, 8, 7, 0, 2, 0, 7, -1],
		[3, 7, 10, 3, 10, 2, 7, 4, 10, 1, 10, 0, 4, 0, 10, -1],
		[1, 10, 2, 8, 7, 4, -1],
		[4, 9, 1, 4, 1, 7, 7, 1, 3, -1],
		[4, 9, 1, 4, 1, 7, 0, 8, 1, 8, 7, 1, -1],
		[4, 0, 3, 7, 4, 3, -1],
		[4, 8, 7, -1],
		[9, 10, 8, 10, 11, 8, -1],
		[3, 0, 9, 3, 9, 11, 11, 9, 10, -1],
		[0, 1, 10, 0, 10, 8, 8, 10, 11, -1],
		[3, 1, 10, 11, 3, 10, -1],
		[1, 2, 11, 1, 11, 9, 9, 11, 8, -1],
		[3, 0, 9, 3, 9, 11, 1, 2, 9, 2, 11, 9, -1],
		[0, 2, 11, 8, 0, 11, -1],
		[3, 2, 11, -1],
		[2, 3, 8, 2, 8, 10, 10, 8, 9, -1],
		[9, 10, 2, 0, 9, 2, -1],
		[2, 3, 8, 2, 8, 10, 0, 1, 8, 1, 10, 8, -1],
		[1, 10, 2, -1],
		[1, 3, 8, 9, 1, 8, -1],
		[0, 9, 1, -1],
		[0, 3, 8, -1],
		[-1]
	]
	var out: Array = []
	for entry: Array in raw:
		out.append(PackedInt32Array(entry))
	return out
