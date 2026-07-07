# johnson_factory_cupolas.gd - Factory for Johnson solid cupola + rotunda family (J3-J6)
#
# Static methods that build the cupola/rotunda family of Johnson solids:
#   J3 - Triangular cupola (wrapper around PolyhedronFactory.create_triangular_cupola)
#   J4 - Square cupola
#   J5 - Pentagonal cupola
#   J6 - Pentagonal rotunda (half-icosidodecahedron, NOT a cupola)
#
# All solids have unit edge length before scaling.
# Faces are triangulated (PrimitiveMeshBuilder consumes 3-index faces only).
#
# Cupola construction principle (n-cupola Jn+2 for n in {3,4,5}):
#   - Top: regular n-gon at height h, circumradius r_top = 1 / (2*sin(PI/n))
#   - Bottom: regular 2n-gon at y=0, circumradius r_bot = 1 / (2*sin(PI/(2n)))
#   - Top is rotated by PI/(2n) relative to bottom so each top vertex centers
#     over a bottom edge.
#   - Side: n triangles + n squares alternating; for each k in [0, n-1]:
#       Triangle: top[k], bottom[2k+1], bottom[2k]
#       Square:   top[k], bottom[2k+2], bottom[2k+1], top[(k+1) mod n]  -- wait, square uses k+1 next-top
#     Vertex order is chosen so face normals point outward.
#   - Height h derived from requiring slant edge length = 1.
extends RefCounted
class_name JohnsonCupolaFactory

const PolyhedronFactory = preload("res://commons/primitives/shared/polyhedron_factory.gd")


## J3 -- Triangular Cupola (thin wrapper over PolyhedronFactory)
## 8 faces (3 triangles + 3 squares + 1 top triangle + 1 bottom hexagon), 9 vertices, 15 edges
static func create_triangular_cupola(scale := 0.5, color := Color(0.7, 0.9, 1.0)) -> Node3D:
	return PolyhedronFactory.create_triangular_cupola(scale, color)


## J4 -- Square Cupola
## Top: square (4 verts) at height h
## Bottom: octagon (8 verts) at y=0
## Side: 4 triangles + 4 squares alternating
## 10 faces (4 triangles + 4 squares + 1 square top + 1 octagonal bottom)
## 12 vertices, 20 edges
static func create_square_cupola(scale := 0.5, color := Color(0.4, 0.85, 0.95)) -> Node3D:
	return _build_n_cupola(4, "SquareCupola_J4", scale, color)


## J5 -- Pentagonal Cupola
## Top: pentagon (5 verts) at height h
## Bottom: decagon (10 verts) at y=0
## Side: 5 triangles + 5 squares alternating
## 12 faces (5 triangles + 5 squares + 1 pentagonal top + 1 decagonal bottom)
## 15 vertices, 25 edges
static func create_pentagonal_cupola(scale := 0.5, color := Color(0.35, 0.85, 0.85)) -> Node3D:
	return _build_n_cupola(5, "PentagonalCupola_J5", scale, color)


## J6 -- Pentagonal Rotunda (NOT a cupola, half-icosidodecahedron)
## Top: pentagon (5 verts) at h_top
## Mid-upper ring: pentagon (5 verts) at h_mid_upper (offset rotation)
## Mid-lower ring: pentagon (5 verts) at h_mid_lower (offset rotation)
## Bottom: decagon (10 verts) at y=0
## Faces: 10 triangles + 5 pentagons (side) + 1 pentagonal top + 1 decagonal bottom = 17
## 20 vertices, 35 edges
static func create_pentagonal_rotunda(scale := 0.5, color := Color(0.4, 0.85, 0.65)) -> Node3D:
	return _build_pentagonal_rotunda(scale, color)


# ---------------------------------------------------------------------------
# Internal constructors
# ---------------------------------------------------------------------------

## Build an n-cupola for n in {3, 4, 5}.
## Returns Node3D containing the assembled mesh.
static func _build_n_cupola(n: int, solid_name: String, scale: float, color: Color) -> Node3D:
	# Geometry: unit edge length
	var r_top: float = 1.0 / (2.0 * sin(PI / float(n)))
	var r_bot: float = 1.0 / (2.0 * sin(PI / float(2 * n)))

	# Choose angular offsets so top vertex k lies centered over bottom edge (2k, 2k+1):
	#   bottom vertex j angle:  j * PI / n
	#   top    vertex k angle:  (2k + 1) * PI / n  =  midpoint of bottom[2k] and bottom[2k+1]
	# The slant edge connects top[k] -> bottom[2k] and top[k] -> bottom[2k+1] symmetrically.
	#
	# Distance from top vertex (in XZ) to bottom vertex (2k):
	#   top  XZ = (r_top cos a_top,  r_top sin a_top)
	#   bot  XZ = (r_bot cos a_bot,  r_bot sin a_bot)
	#   where a_top - a_bot = PI/(2n)
	# So dx,dz = r_top*(cos a_top - 0) etc. Working it out, the planar distance is:
	#   d_xz^2 = r_top^2 + r_bot^2 - 2*r_top*r_bot*cos(PI/(2n))
	# And slant edge length 1 = sqrt(h^2 + d_xz^2)  =>  h = sqrt(1 - d_xz^2)
	var d_xz_sq: float = r_top * r_top + r_bot * r_bot - 2.0 * r_top * r_bot * cos(PI / float(2 * n))
	var h: float = sqrt(max(0.0, 1.0 - d_xz_sq))

	var vertices: Array[Vector3] = []

	# Bottom 2n-gon at y=0. Indices [0 .. 2n-1].
	for j in range(2 * n):
		var a: float = float(j) * PI / float(n)
		vertices.append(Vector3(r_bot * cos(a), 0.0, r_bot * sin(a)))

	# Top n-gon at y=h. Indices [2n .. 3n-1].
	var top_offset: int = 2 * n
	for k in range(n):
		var a2: float = (2.0 * float(k) + 1.0) * PI / float(n)
		vertices.append(Vector3(r_top * cos(a2), h, r_top * sin(a2)))

	var faces: Array = []

	# Outer-facing winding convention:
	#   For a face to have an outward normal, list vertices counter-clockwise
	#   when viewed from outside the solid.
	#
	# Side triangles: top[k], bottom[2k], bottom[2k+1]
	#   Viewed from outside (radially outward), going CCW means top -> left-bottom -> right-bottom.
	#   We pick top[k], bot[2k+1], bot[2k] so the cross product points outward (radially).
	for k in range(n):
		var t_k: int = top_offset + k
		var b_2k: int = (2 * k) % (2 * n)
		var b_2k1: int = (2 * k + 1) % (2 * n)
		faces.append([t_k, b_2k1, b_2k])

	# Side squares between top[k] and top[k+1], spanning bottom[2k+1] -> bottom[2k+2]
	# Quad order (CCW from outside): top[k], bottom[2k+1], bottom[2k+2], top[k+1]
	# Triangulate as: (top[k], bot[2k+1], bot[2k+2]) and (top[k], bot[2k+2], top[k+1])
	for k in range(n):
		var t_k: int = top_offset + k
		var t_k1: int = top_offset + ((k + 1) % n)
		var b_2k1: int = (2 * k + 1) % (2 * n)
		var b_2k2: int = (2 * k + 2) % (2 * n)
		faces.append([t_k, b_2k1, b_2k2])
		faces.append([t_k, b_2k2, t_k1])

	# Top n-gon cap (normal +Y). Triangulate as fan from vertex 0 of the cap.
	# Going CCW when viewed from above (+Y looking down to origin) requires reversing winding
	# because our top angles increase counter-clockwise in XZ (right-handed; standard).
	# For a +Y normal in a right-handed system with XZ on the floor, we need CCW in the
	# Z-flipped view, which corresponds to clockwise in (x, z). So we fan in reverse order.
	for k in range(1, n - 1):
		faces.append([top_offset, top_offset + k + 1, top_offset + k])

	# Bottom 2n-gon cap (normal -Y). Fan from vertex 0, forward winding for downward normal.
	for j in range(1, 2 * n - 1):
		faces.append([0, j, j + 1])

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": solid_name,
		"base_color": color,
		"scale": scale,
		"double_sided": true  # Robustness: catches any winding mismatch without visual hole
	})


## Build J6 -- Pentagonal Rotunda.
##
## Construction: take the upper half of an icosidodecahedron (y >= 0 vertices),
## use its inherited face structure (those faces with all vertices in y >= 0),
## and seal the equatorial decagon as the bottom cap.
##
## The icosidodecahedron vertices used (edge length 1) are:
##   Group A (6):  axis-aligned (0,0,+-phi) and cyclic permutations
##   Group B (24): (+-1/2, +-phi/2, +-phi^2/2) and cyclic permutations
##
## With our orientation (phi-axis = y), the half with y >= 0 contains 20 vertices:
##   - 5 at y = phi^2/2 (top pentagon)
##   - 5 at y = phi/2    (upper ring)
##   - 10 at y = 0       (equatorial decagon)
##
## Faces are discovered algorithmically:
##   - Edges: vertex pairs with distance ~ 1.0
##   - Triangle faces: every 3-cycle in the edge graph that is coplanar and
##     not contained in a larger face cycle
##   - Pentagon faces: every 5-cycle in the edge graph that is coplanar
##   - Decagon bottom cap: the 10 equatorial vertices, fan-triangulated
static func _build_pentagonal_rotunda(scale: float, color: Color) -> Node3D:
	# Step 1: generate the 30 icosidodecahedron vertices via icosahedron edge midpoints.
	# This naturally yields edge length 1 and (0, 1, phi) as a 5-fold axis.
	#
	# Icosahedron in this orientation has 12 vertices: cyclic perms of (0, ±1, ±phi).
	# Edge length = 2. Each of its 30 edges' midpoint is an icosidodec vertex (edge length 1).
	var phi: float = (1.0 + sqrt(5.0)) / 2.0

	var icos_verts: Array[Vector3] = []
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			icos_verts.append(Vector3(0.0, sy, sz * phi))
			icos_verts.append(Vector3(sy, sz * phi, 0.0))
			icos_verts.append(Vector3(sy * phi, 0.0, sz))

	var raw_verts: Array[Vector3] = []
	for i in range(icos_verts.size()):
		for j in range(i + 1, icos_verts.size()):
			var d: float = icos_verts[i].distance_to(icos_verts[j])
			if abs(d - 2.0) < 0.01:
				raw_verts.append((icos_verts[i] + icos_verts[j]) * 0.5)
	if raw_verts.size() != 30:
		push_warning("JohnsonCupolaFactory: icosidodec midpoint generation produced %d verts (expected 30)." % raw_verts.size())

	# Step 1b: rotate so 5-fold axis (0, 1, phi) aligns with +Y.
	var axis5: Vector3 = Vector3(0.0, 1.0, phi).normalized()
	var target: Vector3 = Vector3(0.0, 1.0, 0.0)
	var rot_axis: Vector3 = axis5.cross(target)
	var rot_basis: Basis
	if rot_axis.length() < 1e-6:
		rot_basis = Basis.IDENTITY
	else:
		var rot_angle: float = acos(clamp(axis5.dot(target), -1.0, 1.0))
		rot_basis = Basis(rot_axis.normalized(), rot_angle)

	var all_verts: Array[Vector3] = []
	for v in raw_verts:
		all_verts.append(rot_basis * v)

	# Step 2: keep only y > -eps (rotunda upper half = top pentagon + upper ring + equator).
	# After rotating onto a 5-fold axis, latitudes should be:
	#   y = max (top pentagon, 5 verts)
	#   y = upper level (upper ring, 5 verts)
	#   y = 0 (equatorial decagon, 10 verts)
	#   y = lower level (mirror)
	#   y = min (bottom pentagon)
	# Total upper-half vertex count = 20.
	var eps: float = 0.001
	var upper_half: Array[Vector3] = []
	for v in all_verts:
		if v.y >= -eps:
			upper_half.append(v)
	if upper_half.size() != 20:
		push_warning("JohnsonCupolaFactory: J6 upper half has %d verts (expected 20); J6 may be malformed." % upper_half.size())

	# Step 3: build an adjacency map via distance-1 threshold.
	# Edge length = 1, so use threshold band [0.95, 1.05].
	var n: int = upper_half.size()
	var adjacency := []  # adjacency[i] = Array[int]
	for i in range(n):
		adjacency.append([])
	for i in range(n):
		for j in range(i + 1, n):
			var d: float = upper_half[i].distance_to(upper_half[j])
			if d > 0.95 and d < 1.05:
				adjacency[i].append(j)
				adjacency[j].append(i)

	# Step 4: discover faces from the adjacency graph.
	# Algorithm: for each ordered pair (a, b) where b is adjacent to a, walk
	# the "leftmost turn" cycle until returning to a. This gives the planar face
	# on that side of the edge.
	#
	# To define "leftmost", we need a consistent angular ordering of each vertex's
	# neighbors. We use the projection onto the tangent plane (perpendicular to the
	# vertex's outward normal, which we approximate as the vertex's own position
	# direction from origin) and sort neighbors by angle.

	# Precompute neighbor angular orderings.
	var neighbor_order: Array = []  # neighbor_order[i] = Array[int] sorted CCW around outward normal
	for i in range(n):
		var center: Vector3 = upper_half[i]
		var outward: Vector3 = center.normalized()
		# Build local frame: e1 perpendicular to outward, e2 = outward x e1
		var temp: Vector3 = Vector3.UP
		if abs(outward.dot(Vector3.UP)) > 0.95:
			temp = Vector3.RIGHT
		var e1: Vector3 = (temp - outward * temp.dot(outward)).normalized()
		var e2: Vector3 = outward.cross(e1)
		var neigh_with_angle: Array = []
		for nb in adjacency[i]:
			var to_neigh: Vector3 = upper_half[nb] - center
			var x: float = to_neigh.dot(e1)
			var y: float = to_neigh.dot(e2)
			var ang: float = atan2(y, x)
			neigh_with_angle.append([nb, ang])
		neigh_with_angle.sort_custom(func(a, b): return a[1] < b[1])
		var ordered: Array = []
		for entry in neigh_with_angle:
			ordered.append(entry[0])
		neighbor_order.append(ordered)

	# For each directed edge (u, v), the next vertex in the face on the LEFT of the edge
	# is the neighbor of v that comes IMMEDIATELY BEFORE u in v's CCW neighbor order.
	# (Standard "previous in cyclic order" trick for planar embeddings.)
	#
	# Each directed edge appears in exactly ONE face. We collect cycles by walking
	# until we return to the starting directed edge.
	var face_cycles: Array = []
	var visited_directed := {}  # key "u,v" -> bool
	for start_u in range(n):
		for start_v in adjacency[start_u]:
			var start_key: String = str(start_u) + "," + str(start_v)
			if visited_directed.has(start_key):
				continue
			# Walk this face.
			var cycle: Array = [start_u]
			var cur_u: int = start_u
			var cur_v: int = start_v
			var max_steps: int = 12
			var step: int = 0
			var closed: bool = false
			while step < max_steps:
				visited_directed[str(cur_u) + "," + str(cur_v)] = true
				cycle.append(cur_v)
				# Compute next vertex via "predecessor of cur_u in cur_v's CCW order".
				var v_neighbors: Array = neighbor_order[cur_v]
				var idx_u_in_v: int = v_neighbors.find(cur_u)
				if idx_u_in_v < 0:
					break
				var next_w: int = v_neighbors[(idx_u_in_v - 1 + v_neighbors.size()) % v_neighbors.size()]
				# Closure check: if next_w == start_u, the closing directed edge is
				# (cur_v, start_u), which completes the cycle. Mark it visited and stop.
				if next_w == start_u:
					visited_directed[str(cur_v) + "," + str(start_u)] = true
					closed = true
					break
				cur_u = cur_v
				cur_v = next_w
				step += 1
			# The cycle ends with the LAST distinct vertex (not the starting vertex again).
			# Cycle list contains each face vertex once, in CCW order around outward normal.
			if closed and cycle.size() >= 3 and cycle.size() <= 5:
				face_cycles.append(cycle.duplicate())

	# Step 5: identify the equatorial decagon (vertices with y ~ 0) for the bottom cap.
	var bottom_indices_raw: Array = []
	for i in range(n):
		if abs(upper_half[i].y) < eps:
			bottom_indices_raw.append(i)
	if bottom_indices_raw.size() != 10:
		push_warning("JohnsonCupolaFactory: J6 equatorial decagon has %d verts (expected 10)." % bottom_indices_raw.size())

	# Sort bottom indices CCW around the y-axis (viewed from +Y looking down).
	# We sort by angle = atan2(z, x).
	var bottom_sorted: Array = bottom_indices_raw.duplicate()
	var verts_ref := upper_half
	bottom_sorted.sort_custom(func(a, b):
		var va: Vector3 = verts_ref[a]
		var vb: Vector3 = verts_ref[b]
		return atan2(va.z, va.x) < atan2(vb.z, vb.x))

	# Step 6: triangulate all discovered faces and add the bottom decagon cap.
	# Each face is a polygon (3, 4, or 5 verts). For non-triangles we fan-triangulate.
	# Face winding from the leftmost-turn algorithm above is CCW around the OUTWARD normal,
	# which is what PrimitiveMeshBuilder expects for visible front faces.
	var triangulated_faces: Array = []
	for poly in face_cycles:
		var sz: int = poly.size()
		if sz == 3:
			triangulated_faces.append([poly[0], poly[1], poly[2]])
		elif sz == 4:
			triangulated_faces.append([poly[0], poly[1], poly[2]])
			triangulated_faces.append([poly[0], poly[2], poly[3]])
		elif sz == 5:
			triangulated_faces.append([poly[0], poly[1], poly[2]])
			triangulated_faces.append([poly[0], poly[2], poly[3]])
			triangulated_faces.append([poly[0], poly[3], poly[4]])

	# Bottom decagon cap (normal -Y). Fan from sorted bottom[0].
	# When viewed from -Y (below), CCW means winding goes the opposite way as from +Y.
	# bottom_sorted is CCW from +Y; for a -Y normal we reverse the fan order.
	for k in range(1, bottom_sorted.size() - 1):
		triangulated_faces.append([
			bottom_sorted[0],
			bottom_sorted[k + 1],
			bottom_sorted[k]
		])

	# Optional: orient the model so the top pentagon faces +Y (it already does:
	# top verts have y = phi^2/2, bottom decagon has y = 0).
	# Scale done by create_polyhedron via the scale param.

	return PolyhedronFactory.create_polyhedron(upper_half, triangulated_faces, {
		"name": "PentagonalRotunda_J6",
		"base_color": color,
		"scale": scale,
		"double_sided": true  # Robustness: face-discovery winding can be inconsistent
	})
