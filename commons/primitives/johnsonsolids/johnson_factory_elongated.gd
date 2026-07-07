# johnson_factory_elongated.gd
# Factory methods for the Johnson solid elongated + gyroelongated pyramid family.
# All solids have unit edge length (1.0) at scale=1.0, centered at their centroid
# in Y (XZ symmetry is around the origin), with counter-clockwise vertex winding
# when viewed from outside (outward normals).
#
# Implemented:
#   J7  — Elongated triangular pyramid    (7 faces, 7 vertices, 12 edges)
#   J8  — Elongated square pyramid        (9 faces, 9 vertices, 16 edges)
#   J9  — Elongated pentagonal pyramid    (11 faces, 11 vertices, 20 edges)
#   J10 — Gyroelongated square pyramid    (13 faces, 9 vertices, 20 edges)
#   J11 — Gyroelongated pentagonal pyramid (16 faces, 11 vertices, 25 edges)
#
# Pedagogical relationship:
#   Each solid is a pyramid cap (J1-style for n=4, J2 for n=5, tetrahedron-cap for n=3)
#   stacked on a prism (elongated, J7/J8/J9) or antiprism (gyroelongated, J10/J11).
#   The interface n-gon between cap and tube exists as vertices only; the face
#   itself disappears into the interior of the resulting Johnson solid.
#
# Construction recipe shared by all five:
#   1. Bottom n-gon at y = y0, circumradius R_n = 1/(2·sin(π/n)).
#   2. Top n-gon at y = y0 + h_tube (prism: same rotation; antiprism: rotated π/n).
#   3. Apex above the top n-gon's centroid at y = y0 + h_tube + h_cap.
#   4. Recentre on the centroid (uniform vertex weight).
#
# Edge-length constraints (with unit edges):
#   Prism side edges      → h_prism = 1
#   Antiprism slant edges → h_anti² = 1 - 2·R_n²·(1 - cos(π/n))
#   Pyramid slant edges   → h_cap² = 1 - R_n²
#   (Tetrahedron cap for n=3 is exactly the square-root form above: sqrt(2/3).)

class_name JohnsonElongatedFactory
extends RefCounted

const PolyhedronFactory = preload("res://commons/primitives/shared/polyhedron_factory.gd")


# ---------------------------------------------------------------------------
# J7 — Elongated Triangular Pyramid
# Tetrahedron stacked on a triangular prism. The shared triangle is internal.
# V = 3 (bottom△) + 3 (top△) + 1 (apex) = 7
# F = 1 (bottom△) + 3 (side rectangles) + 3 (cap triangles) = 7
# E = 12  →  7 - 12 + 7 = 2 ✓
# ---------------------------------------------------------------------------
static func create_elongated_triangular_pyramid(scale := 0.5, color := Color(0.95, 0.7, 0.3)) -> Node3D:
	var n := 3
	var sin_pi_n := sin(PI / float(n))
	var r := 1.0 / (2.0 * sin_pi_n)            # ≈ 0.5774
	var h_prism := 1.0
	var h_cap := sqrt(max(0.0, 1.0 - r * r))   # = sqrt(2/3) ≈ 0.8165

	var vertices: Array[Vector3] = []

	# Bottom triangle at y = 0
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))

	# Top triangle at y = h_prism (same rotation as bottom — prism, not antiprism)
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), h_prism, r * sin(theta)))

	# Apex above top centroid
	vertices.append(Vector3(0.0, h_prism + h_cap, 0.0))

	_recentre_y(vertices)

	# Indices: bottom 0..2, top 3..5, apex 6
	# Bottom triangle viewed from -Y: CCW order 0→2→1 gives -Y normal
	# Side rectangles: top[k] above bottom[k]; side k connects bottom[k]→bottom[k+1]→top[k+1]→top[k]
	# Cap triangles: apex with consecutive top vertices, outward winding
	var faces: Array = [
		# Bottom triangle (1 face)
		[0, 2, 1],

		# 3 side rectangles (each 2 triangles)
		[0, 1, 4], [0, 4, 3],   # side between v0 and v1
		[1, 2, 5], [1, 5, 4],   # side between v1 and v2
		[2, 0, 3], [2, 3, 5],   # side between v2 and v0

		# 3 cap triangles
		[6, 4, 3],
		[6, 5, 4],
		[6, 3, 5],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "ElongatedTriangularPyramid_J7",
		"base_color": color,
		"scale": scale,
	})


# ---------------------------------------------------------------------------
# J8 — Elongated Square Pyramid
# Square pyramid (J1) stacked on a cube. The shared square is internal.
# V = 4 + 4 + 1 = 9
# F = 1 (square base) + 4 (square sides) + 4 (cap triangles) = 9
# E = 16  →  9 - 16 + 9 = 2 ✓
# ---------------------------------------------------------------------------
static func create_elongated_square_pyramid(scale := 0.5, color := Color(0.95, 0.5, 0.35)) -> Node3D:
	var n := 4
	var sin_pi_n := sin(PI / float(n))
	var r := 1.0 / (2.0 * sin_pi_n)            # = sqrt(2)/2 ≈ 0.7071
	var h_prism := 1.0
	var h_cap := sqrt(max(0.0, 1.0 - r * r))   # = sqrt(2)/2 ≈ 0.7071

	var vertices: Array[Vector3] = []

	# Bottom square at y = 0
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))

	# Top square at y = h_prism (same rotation — prism)
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), h_prism, r * sin(theta)))

	# Apex
	vertices.append(Vector3(0.0, h_prism + h_cap, 0.0))

	_recentre_y(vertices)

	# Indices: bottom 0..3, top 4..7, apex 8
	var faces: Array = [
		# Bottom square (fan triangulation) viewed from -Y → CCW is 0→3→2→1 order
		[0, 3, 2],
		[0, 2, 1],

		# 4 side rectangles (each 2 triangles)
		[0, 1, 5], [0, 5, 4],
		[1, 2, 6], [1, 6, 5],
		[2, 3, 7], [2, 7, 6],
		[3, 0, 4], [3, 4, 7],

		# 4 cap triangles
		[8, 5, 4],
		[8, 6, 5],
		[8, 7, 6],
		[8, 4, 7],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "ElongatedSquarePyramid_J8",
		"base_color": color,
		"scale": scale,
	})


# ---------------------------------------------------------------------------
# J9 — Elongated Pentagonal Pyramid
# Pentagonal pyramid (J2) stacked on a pentagonal prism.
# V = 5 + 5 + 1 = 11
# F = 1 (pentagon base) + 5 (side rectangles) + 5 (cap triangles) = 11
# E = 20  →  11 - 20 + 11 = 2 ✓
# ---------------------------------------------------------------------------
static func create_elongated_pentagonal_pyramid(scale := 0.5, color := Color(0.95, 0.45, 0.55)) -> Node3D:
	var n := 5
	var sin_pi_n := sin(PI / float(n))
	var r := 1.0 / (2.0 * sin_pi_n)            # ≈ 0.8507
	var h_prism := 1.0
	var h_cap := sqrt(max(0.0, 1.0 - r * r))   # ≈ 0.5257

	var vertices: Array[Vector3] = []

	# Bottom pentagon
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))

	# Top pentagon (same rotation)
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), h_prism, r * sin(theta)))

	# Apex
	vertices.append(Vector3(0.0, h_prism + h_cap, 0.0))

	_recentre_y(vertices)

	# Indices: bottom 0..4, top 5..9, apex 10
	var faces: Array = [
		# Bottom pentagon (fan from v0, viewed from -Y → CCW is reverse order)
		[0, 4, 3],
		[0, 3, 2],
		[0, 2, 1],

		# 5 side rectangles
		[0, 1, 6], [0, 6, 5],
		[1, 2, 7], [1, 7, 6],
		[2, 3, 8], [2, 8, 7],
		[3, 4, 9], [3, 9, 8],
		[4, 0, 5], [4, 5, 9],

		# 5 cap triangles
		[10, 6, 5],
		[10, 7, 6],
		[10, 8, 7],
		[10, 9, 8],
		[10, 5, 9],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "ElongatedPentagonalPyramid_J9",
		"base_color": color,
		"scale": scale,
	})


# ---------------------------------------------------------------------------
# J10 — Gyroelongated Square Pyramid
# Square pyramid (J1) stacked on a square antiprism. The shared square is internal.
# The top square is rotated by π/n = π/4 relative to the bottom; the side of the
# tube is triangulated with 2n = 8 triangles (no rectangles).
# V = 4 + 4 + 1 = 9
# F = 1 (square base) + 8 (side triangles) + 4 (cap triangles) = 13
# E = 20  →  9 - 20 + 13 = 2 ✓
# Antiprism height: h_anti² = 1 - 2·R²·(1 - cos(π/n))
#   For n=4: R² = 1/2, 1-cos(π/4) = 1 - √2/2 ≈ 0.2929; h_anti² ≈ 0.7071, h_anti ≈ 0.8409.
# ---------------------------------------------------------------------------
static func create_gyroelongated_square_pyramid(scale := 0.5, color := Color(0.65, 0.45, 0.95)) -> Node3D:
	var n := 4
	var sin_pi_n := sin(PI / float(n))
	var cos_pi_n := cos(PI / float(n))
	var r := 1.0 / (2.0 * sin_pi_n)
	var h_anti := sqrt(max(0.0, 1.0 - 2.0 * r * r * (1.0 - cos_pi_n)))
	var h_cap := sqrt(max(0.0, 1.0 - r * r))

	var twist := PI / float(n)  # π/4 for square antiprism

	var vertices: Array[Vector3] = []

	# Bottom square
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))

	# Top square — rotated by twist
	for k in range(n):
		var theta: float = float(k) * TAU / float(n) + twist
		vertices.append(Vector3(r * cos(theta), h_anti, r * sin(theta)))

	# Apex above top centroid
	vertices.append(Vector3(0.0, h_anti + h_cap, 0.0))

	_recentre_y(vertices)

	# Indices: bottom 0..3, top 4..7, apex 8
	# Antiprism side triangulation: for each bottom vertex k,
	#   downward triangle: [bottom[k], bottom[k+1], top[k]]    (vertex top[k] at angle k+0.5)
	#   upward triangle:   [bottom[k+1], top[(k+1) mod n], top[k]]
	# Outward normals require careful ordering — verified by hand:
	#   Triangle A: bottom[k] → bottom[k+1] → top[k]    is CCW from outside
	#   Triangle B: bottom[k+1] → top[(k+1)%n] → top[k] is CCW from outside
	var faces: Array = [
		# Bottom square viewed from -Y → CCW is reverse fan
		[0, 3, 2],
		[0, 2, 1],

		# 8 side triangles (2 per bottom-edge)
		[0, 1, 4], [1, 5, 4],
		[1, 2, 5], [2, 6, 5],
		[2, 3, 6], [3, 7, 6],
		[3, 0, 7], [0, 4, 7],

		# 4 cap triangles (top square is rotated, but topology is identical to J8 cap)
		[8, 5, 4],
		[8, 6, 5],
		[8, 7, 6],
		[8, 4, 7],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "GyroelongatedSquarePyramid_J10",
		"base_color": color,
		"scale": scale,
	})


# ---------------------------------------------------------------------------
# J11 — Gyroelongated Pentagonal Pyramid
# Pentagonal pyramid (J2) stacked on a pentagonal antiprism.
# Top pentagon rotated by π/5 = 36° relative to the bottom; 2n = 10 side triangles.
# V = 5 + 5 + 1 = 11
# F = 1 (pentagon base) + 10 (side triangles) + 5 (cap triangles) = 16
# E = 25  →  11 - 25 + 16 = 2 ✓
# Antiprism height: h_anti² = 1 - 2·R²·(1 - cos(π/n))
#   For n=5: R² ≈ 0.7236, 1-cos(π/5) ≈ 0.1910; h_anti² ≈ 0.7236, h_anti ≈ 0.8507.
# ---------------------------------------------------------------------------
static func create_gyroelongated_pentagonal_pyramid(scale := 0.5, color := Color(0.45, 0.5, 0.95)) -> Node3D:
	var n := 5
	var sin_pi_n := sin(PI / float(n))
	var cos_pi_n := cos(PI / float(n))
	var r := 1.0 / (2.0 * sin_pi_n)
	var h_anti := sqrt(max(0.0, 1.0 - 2.0 * r * r * (1.0 - cos_pi_n)))
	var h_cap := sqrt(max(0.0, 1.0 - r * r))

	var twist := PI / float(n)  # π/5 for pentagonal antiprism

	var vertices: Array[Vector3] = []

	# Bottom pentagon
	for k in range(n):
		var theta: float = float(k) * TAU / float(n)
		vertices.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))

	# Top pentagon — rotated by twist
	for k in range(n):
		var theta: float = float(k) * TAU / float(n) + twist
		vertices.append(Vector3(r * cos(theta), h_anti, r * sin(theta)))

	# Apex
	vertices.append(Vector3(0.0, h_anti + h_cap, 0.0))

	_recentre_y(vertices)

	# Indices: bottom 0..4, top 5..9, apex 10
	var faces: Array = [
		# Bottom pentagon (fan from v0, CCW from -Y is reverse order)
		[0, 4, 3],
		[0, 3, 2],
		[0, 2, 1],

		# 10 side triangles (2 per bottom edge) — antiprism triangulation
		[0, 1, 5], [1, 6, 5],
		[1, 2, 6], [2, 7, 6],
		[2, 3, 7], [3, 8, 7],
		[3, 4, 8], [4, 9, 8],
		[4, 0, 9], [0, 5, 9],

		# 5 cap triangles
		[10, 6, 5],
		[10, 7, 6],
		[10, 8, 7],
		[10, 9, 8],
		[10, 5, 9],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "GyroelongatedPentagonalPyramid_J11",
		"base_color": color,
		"scale": scale,
	})


# ---------------------------------------------------------------------------
# Helper — shift all vertices so the centroid sits at y = 0.
# (X and Z are already symmetric around the origin by construction.)
# ---------------------------------------------------------------------------
static func _recentre_y(vertices: Array[Vector3]) -> void:
	if vertices.is_empty():
		return
	var sum_y := 0.0
	for v in vertices:
		sum_y += v.y
	var y_c := sum_y / float(vertices.size())
	for i in range(vertices.size()):
		vertices[i] = Vector3(vertices[i].x, vertices[i].y - y_c, vertices[i].z)
