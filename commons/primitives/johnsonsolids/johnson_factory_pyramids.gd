# johnson_factory_pyramids.gd
# Factory methods for the Johnson solid pyramid + bipyramid family.
# All solids have unit edge length (1.0) at scale=1.0, centered at their centroid,
# with counter-clockwise vertex winding when viewed from outside (outward normals).
#
# Implemented:
#   J1  — Square pyramid       (thin wrapper around PolyhedronFactory)
#   J2  — Pentagonal pyramid   (6 faces, 6 vertices, 10 edges)
#   J12 — Triangular bipyramid (6 faces, 5 vertices, 9 edges)
#   J13 — Pentagonal bipyramid (10 faces, 7 vertices, 15 edges)
#
# Pedagogical relationship: J13 is the bipyramid (gyroelongated apex pair) sharing
# the pentagonal base of J2 — glue two J2 pyramids base-to-base and the equatorial
# pentagon disappears into the interior.

class_name JohnsonPyramidFactory
extends RefCounted

const PolyhedronFactory = preload("res://commons/primitives/shared/polyhedron_factory.gd")

# ---------------------------------------------------------------------------
# J1 — Square Pyramid (thin wrapper for API uniformity)
# 5 faces: 4 triangles + 1 square base
# V=5, E=8, F=5  →  5 - 8 + 5 = 2 ✓
# ---------------------------------------------------------------------------
static func create_j1_square_pyramid(scale := 0.5, color := Color(0.95, 0.6, 0.25)) -> Node3D:
	return PolyhedronFactory.create_square_pyramid(scale, color)


# ---------------------------------------------------------------------------
# J2 — Pentagonal Pyramid
# Pentagonal base on the XZ plane, apex on +Y.
# Base circumradius R = 1 / (2·sin(π/5)) ≈ 0.8507
# Apex height (above base plane) h = sqrt(1 - 1/(4·sin²(π/5))) ≈ 0.5257
# Centroid is at y = h * 1/6 (apex weighted with 5 base verts);
# we recenter by shifting all vertices so the centroid sits at origin.
# V=6, E=10, F=6  →  6 - 10 + 6 = 2 ✓
# ---------------------------------------------------------------------------
static func create_pentagonal_pyramid(scale := 0.5, color := Color(0.95, 0.55, 0.45)) -> Node3D:
	var sin_pi5 := sin(PI / 5.0)
	var r := 1.0 / (2.0 * sin_pi5)
	var h := sqrt(1.0 - 1.0 / (4.0 * sin_pi5 * sin_pi5))

	# Centroid in Y for 5 base verts at y=0 + 1 apex at y=h: y_c = h / 6
	var y_c := h / 6.0

	var vertices: Array[Vector3] = []
	for k in range(5):
		var theta: float = float(k) * TAU / 5.0
		vertices.append(Vector3(r * cos(theta), -y_c, r * sin(theta)))
	vertices.append(Vector3(0.0, h - y_c, 0.0))  # apex (index 5)

	# CCW from outside:
	#   Base pentagon viewed from -Y: fan from vertex 0 going 0→1→2→... gives -Y normal
	#   Side triangles: [apex, base[k+1], base[k]] — outward normal
	var faces: Array = [
		# Pentagonal base (fan triangulation)
		[0, 1, 2],
		[0, 2, 3],
		[0, 3, 4],
		# 5 triangular side faces
		[5, 1, 0],
		[5, 2, 1],
		[5, 3, 2],
		[5, 4, 3],
		[5, 0, 4],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "PentagonalPyramid_J2",
		"base_color": color,
		"scale": scale,
	})


# ---------------------------------------------------------------------------
# J12 — Triangular Bipyramid
# Two tetrahedra joined base-to-base. Equilateral triangle equator at y=0
# with circumradius R = 1/√3 ≈ 0.5774 (edge length 1).
# Apex height h = sqrt(2/3) ≈ 0.8165 above/below the equator.
# Already centered at origin by symmetry.
# V=5, E=9, F=6  →  5 - 9 + 6 = 2 ✓
# ---------------------------------------------------------------------------
static func create_triangular_bipyramid(scale := 0.5, color := Color(0.55, 0.35, 0.85)) -> Node3D:
	var r := 1.0 / sqrt(3.0)
	var h := sqrt(2.0 / 3.0)

	var vertices: Array[Vector3] = []
	for k in range(3):
		var theta: float = float(k) * TAU / 3.0
		vertices.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))
	vertices.append(Vector3(0.0, h, 0.0))   # north apex (index 3)
	vertices.append(Vector3(0.0, -h, 0.0))  # south apex (index 4)

	# Upper half: [north_apex, base[k+1], base[k]]  → outward normal
	# Lower half: [south_apex, base[k],   base[k+1]] → outward normal (reversed)
	var faces: Array = [
		# Upper 3 triangles
		[3, 1, 0],
		[3, 2, 1],
		[3, 0, 2],
		# Lower 3 triangles
		[4, 0, 1],
		[4, 1, 2],
		[4, 2, 0],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "TriangularBipyramid_J12",
		"base_color": color,
		"scale": scale,
	})


# ---------------------------------------------------------------------------
# J13 — Pentagonal Bipyramid
# Two pentagonal pyramids (J2) joined base-to-base. Pentagonal equator at y=0
# with R = 1/(2·sin(π/5)), apex height h = sqrt(1 - 1/(4·sin²(π/5))).
# Already centered at origin by symmetry.
# V=7, E=15, F=10  →  7 - 15 + 10 = 2 ✓
# ---------------------------------------------------------------------------
static func create_pentagonal_bipyramid(scale := 0.5, color := Color(0.75, 0.35, 0.85)) -> Node3D:
	var sin_pi5 := sin(PI / 5.0)
	var r := 1.0 / (2.0 * sin_pi5)
	var h := sqrt(1.0 - 1.0 / (4.0 * sin_pi5 * sin_pi5))

	var vertices: Array[Vector3] = []
	for k in range(5):
		var theta: float = float(k) * TAU / 5.0
		vertices.append(Vector3(r * cos(theta), 0.0, r * sin(theta)))
	vertices.append(Vector3(0.0, h, 0.0))   # north apex (index 5)
	vertices.append(Vector3(0.0, -h, 0.0))  # south apex (index 6)

	# Upper 5: [north_apex, base[k+1], base[k]]  → outward normal
	# Lower 5: [south_apex, base[k],   base[k+1]] → outward normal (reversed)
	var faces: Array = [
		# Upper 5 triangles
		[5, 1, 0],
		[5, 2, 1],
		[5, 3, 2],
		[5, 4, 3],
		[5, 0, 4],
		# Lower 5 triangles
		[6, 0, 1],
		[6, 1, 2],
		[6, 2, 3],
		[6, 3, 4],
		[6, 4, 0],
	]

	return PolyhedronFactory.create_polyhedron(vertices, faces, {
		"name": "PentagonalBipyramid_J13",
		"base_color": color,
		"scale": scale,
	})
