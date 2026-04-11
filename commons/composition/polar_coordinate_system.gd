## PolarCS — Polar/radial coordinate system using (ring, sector) pairs
## Creates concentric rings divided into sectors (wedge shapes).
## Natural for rose windows, mandalas, Aztec calendars, radial designs.
##
## Ring 0 is a solid disc (no degenerate sliver). Outer rings are annular wedges
## with smooth arc subdivisions that scale with radius.
##
## grid_width = num_rings (from center outward)
## grid_height = base_sectors (angular divisions for outermost ring)
##
## Variable sectors: inner rings automatically use fewer sectors so that cells
## stay roughly proportional in area. Override via use_variable_sectors flag.

extends "res://commons/composition/coordinate_system.gd"

var outer_radius: float = 10.0

## When true, inner rings use fewer sectors (proportional to circumference).
## When false, all rings share grid_height sectors (original behavior).
var use_variable_sectors: bool = false

## Minimum sectors any ring can have (only relevant when use_variable_sectors=true).
var min_sectors: int = 4

## World-space gap between cells in units. Kept constant so inner cells don't
## become entirely consumed by gaps.
var gap_world: float = 0.04

# Cache: sectors_for_ring[ring_index] -> int
var _ring_sectors: PackedInt32Array = PackedInt32Array()

func _init(num_rings: int = 8, sectors: int = 12, cs: float = 1.0) -> void:
	type = Type.POLAR
	grid_width = num_rings    # rings
	grid_height = sectors     # base sectors (used for outermost ring)
	cell_size = cs
	outer_radius = float(num_rings) * cs
	gap_world = cs * 0.04
	_rebuild_ring_sectors()

## Rebuild the per-ring sector count cache.
func _rebuild_ring_sectors() -> void:
	_ring_sectors.resize(grid_width)
	for ring in grid_width:
		if not use_variable_sectors:
			_ring_sectors[ring] = grid_height
		else:
			# Scale sectors proportional to ring mid-radius.
			# Outermost ring (grid_width-1) gets grid_height sectors.
			# Inner rings scale down but never below min_sectors.
			if ring == 0:
				# Center disc: use min_sectors for the pie slices
				_ring_sectors[ring] = maxi(min_sectors, grid_height / grid_width)
			else:
				var mid_r = float(ring) + 0.5
				var outer_mid = float(grid_width) - 0.5
				var ratio = mid_r / outer_mid
				var s = maxi(min_sectors, int(round(float(grid_height) * ratio)))
				# Ensure it divides evenly or at least stays reasonable
				_ring_sectors[ring] = s

## Get sector count for a specific ring.
func sectors_for_ring(ring: int) -> int:
	if ring < 0 or ring >= _ring_sectors.size():
		return grid_height
	return _ring_sectors[ring]

func iterate_cells() -> Array:
	var cells: Array = []
	for ring in grid_width:
		var s_count = sectors_for_ring(ring)
		for sector in s_count:
			cells.append(Vector2i(ring, sector))
	return cells

func cell_to_world(cell_key) -> Vector3:
	var ring: int = cell_key.x
	var sector: int = cell_key.y
	var s_count = sectors_for_ring(ring)
	if ring == 0:
		# Center disc: place at centroid of the pie slice (at 2/3 radius)
		var mid_r = cell_size * 0.5
		var mid_angle = (float(sector) + 0.5) * TAU / float(s_count)
		return Vector3(mid_r * cos(mid_angle), 0.0, mid_r * sin(mid_angle))
	# Annular wedge: mid-radius, mid-angle
	var mid_r = (float(ring) + 0.5) * cell_size
	var mid_angle = (float(sector) + 0.5) * TAU / float(s_count)
	return Vector3(mid_r * cos(mid_angle), 0.0, mid_r * sin(mid_angle))

func create_cell_mesh(cell_key) -> Mesh:
	var ring: int = cell_key.x
	var sector: int = cell_key.y
	if ring == 0:
		return _build_disc_sector_mesh(sector)
	return _build_wedge_mesh(ring, sector)

func cell_to_normalized(cell_key) -> Vector2:
	var ring: int = cell_key.x
	var sector: int = cell_key.y
	var s_count = sectors_for_ring(ring)
	# Ring maps to radial distance (0=center, 1=edge)
	# Sector maps to angular position (0..1)
	return Vector2(
		(float(ring) + 0.5) / float(grid_width),
		(float(sector) + 0.5) / float(s_count)
	)

func get_world_width() -> float:
	return outer_radius * 2.0

func get_world_height() -> float:
	return outer_radius * 2.0


# ═══════════════════════════════════════════════════════════════════
# DISC SECTOR MESH — ring 0 is a solid pie slice (triangle fan)
# ═══════════════════════════════════════════════════════════════════

func _build_disc_sector_mesh(sector: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	var s_count = sectors_for_ring(0)
	var sector_angle = TAU / float(s_count)

	# Angular gap: convert world-space gap to angular gap at the outer edge
	var disc_r = cell_size
	var angular_gap = gap_world / maxf(disc_r, 0.001)
	angular_gap = minf(angular_gap, sector_angle * 0.15)  # Cap at 15% of sector

	var angle_start = float(sector) * sector_angle + angular_gap * 0.5
	var angle_end = float(sector + 1) * sector_angle - angular_gap * 0.5

	# Radial gap at outer edge only
	var outer_r = disc_r - gap_world * 0.5

	# Subdivisions for smooth outer arc
	var subdivs = _arc_subdivisions(0, s_count)

	# Center vertex (index 0)
	vertices.append(Vector3.ZERO)
	normals.append(Vector3.UP)
	uvs.append(Vector2(0.5, 0.5))  # Center of UV space

	# Arc vertices
	var angle_step = (angle_end - angle_start) / float(subdivs)
	for i in (subdivs + 1):
		var angle = angle_start + float(i) * angle_step
		var ca = cos(angle)
		var sa = sin(angle)

		vertices.append(Vector3(outer_r * ca, 0.0, outer_r * sa))
		normals.append(Vector3.UP)

		# Polar UV: map angle and radius to UV space
		var u_polar = 0.5 + 0.5 * ca  # 0..1 across disc
		var v_polar = 0.5 + 0.5 * sa
		uvs.append(Vector2(u_polar, v_polar))

	# Triangle fan from center
	for i in subdivs:
		indices.append(0)         # center
		indices.append(i + 1)     # arc vertex i
		indices.append(i + 2)     # arc vertex i+1

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# ═══════════════════════════════════════════════════════════════════
# WEDGE MESH — annular sector for rings 1+ with smooth arcs
# ═══════════════════════════════════════════════════════════════════

func _build_wedge_mesh(ring: int, sector: int) -> ArrayMesh:
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var normals = PackedVector3Array()
	var uvs = PackedVector2Array()
	var indices = PackedInt32Array()

	var s_count = sectors_for_ring(ring)
	var sector_angle = TAU / float(s_count)

	var inner_r = float(ring) * cell_size
	var outer_r = float(ring + 1) * cell_size

	# Radial gaps: constant world-space gap
	inner_r += gap_world * 0.5
	outer_r -= gap_world * 0.5

	# Angular gaps: convert constant world-space gap to angular offset at each radius
	# Use the mid-radius for a balanced look
	var mid_r = (inner_r + outer_r) * 0.5
	var angular_gap = gap_world / maxf(mid_r, 0.001)
	angular_gap = minf(angular_gap, sector_angle * 0.15)  # Cap gap at 15% of sector

	var angle_start = float(sector) * sector_angle + angular_gap * 0.5
	var angle_end = float(sector + 1) * sector_angle - angular_gap * 0.5

	# Subdivisions scale with ring radius for smooth arcs
	var subdivs = _arc_subdivisions(ring, s_count)
	var angle_step = (angle_end - angle_start) / float(subdivs)

	# Normalized radii for UV mapping (0 = center of layout, 1 = outer edge)
	var inner_r_norm = inner_r / maxf(outer_radius, 0.001)
	var outer_r_norm = outer_r / maxf(outer_radius, 0.001)

	# Build vertices: inner arc then outer arc
	for i in (subdivs + 1):
		var angle = angle_start + float(i) * angle_step
		var ca = cos(angle)
		var sa = sin(angle)
		var u = float(i) / float(subdivs)

		# Inner vertex
		vertices.append(Vector3(inner_r * ca, 0.0, inner_r * sa))
		normals.append(Vector3.UP)
		uvs.append(Vector2(u, inner_r_norm))

		# Outer vertex
		vertices.append(Vector3(outer_r * ca, 0.0, outer_r * sa))
		normals.append(Vector3.UP)
		uvs.append(Vector2(u, outer_r_norm))

	# Build triangles as quad strip
	for i in subdivs:
		var base = i * 2
		# Triangle 1
		indices.append(base)
		indices.append(base + 1)
		indices.append(base + 2)
		# Triangle 2
		indices.append(base + 1)
		indices.append(base + 3)
		indices.append(base + 2)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


# ═══════════════════════════════════════════════════════════════════
# HELPERS
# ═══════════════════════════════════════════════════════════════════

## Calculate arc subdivisions for a given ring.
## Outer rings need more subdivisions because their arcs are longer.
## Minimum 6 subdivisions for acceptable smoothness; scales up with radius.
func _arc_subdivisions(ring: int, s_count: int) -> int:
	# Arc length at outer edge of this ring in cell_size units
	var r = float(ring + 1) * cell_size
	var arc_length = r * TAU / float(s_count)
	# Target: ~1 subdivision per 0.3 world units of arc, minimum 6, max 32
	var target = int(ceil(arc_length / 0.3))
	return clampi(target, 6, 32)
