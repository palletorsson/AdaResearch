## MeshSelector — Composable predicates for selecting faces, edges, or vertices.
## Used by MeshRule to determine which elements an operation applies to.
extends RefCounted
class_name MeshSelector

enum TargetType { FACE, EDGE, VERTEX }

var target_type: TargetType = TargetType.FACE
var _predicate: Callable = Callable()

# ---------------------------------------------------------------------------
# Core evaluation
# ---------------------------------------------------------------------------

## Returns indices of all elements matching this selector.
func select(mesh: MeshData) -> PackedInt32Array:
	var result := PackedInt32Array()
	if not _predicate.is_valid():
		return result

	var count: int = 0
	match target_type:
		TargetType.FACE:
			count = mesh.faces.size()
		TargetType.VERTEX:
			count = mesh.vertices.size()
		TargetType.EDGE:
			mesh._ensure_adjacency()
			# For edges, return face indices that contain matching edges
			count = mesh.faces.size()

	for i in range(count):
		if _predicate.call(mesh, i):
			result.append(i)
	return result

# ---------------------------------------------------------------------------
# Factory constructors
# ---------------------------------------------------------------------------

## Select all faces.
static func all_faces() -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	s._predicate = func(_mesh: MeshData, _idx: int) -> bool: return true
	return s

## Select faces with a specific tag.
static func by_tag(tag: String) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		return mesh.face_has_tag(idx, tag)
	return s

## Select faces whose normal points in a given direction (within tolerance).
static func by_normal_direction(direction: Vector3, tolerance_degrees: float = 45.0) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	var dir_normalized := direction.normalized()
	var cos_tolerance := cos(deg_to_rad(tolerance_degrees))
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		var normal := mesh.get_face_normal(idx)
		return normal.dot(dir_normalized) >= cos_tolerance
	return s

## Select faces within an area range.
static func by_area_range(min_area: float, max_area: float) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		var area := mesh.get_face_area(idx)
		return area >= min_area and area <= max_area
	return s

## Select faces at a specific grammar depth range.
static func by_depth(min_depth: int, max_depth: int = -1) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		if idx >= mesh.face_depth.size():
			return false
		var d: int = mesh.face_depth[idx]
		if d < min_depth:
			return false
		if max_depth >= 0 and d > max_depth:
			return false
		return true
	return s

## Select faces randomly with a given probability.
static func by_random(probability: float, seed_value: int = -1) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	var rng := RandomNumberGenerator.new()
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()
	s._predicate = func(_mesh: MeshData, _idx: int) -> bool:
		return rng.randf() < probability
	return s

## Select specific face indices.
static func by_index(indices: PackedInt32Array) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	var idx_set: Dictionary = {}
	for i in indices:
		idx_set[i] = true
	s._predicate = func(_mesh: MeshData, idx: int) -> bool:
		return idx_set.has(idx)
	return s

## Select faces on the mesh boundary (have an edge with only one face).
static func by_boundary() -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		var edges := mesh.get_face_edges(idx)
		for edge in edges:
			var ef := mesh.get_edge_faces(edge)
			if ef.size() == 1:
				return true
		return false
	return s

## Select faces by a custom callable: func(mesh: MeshData, idx: int) -> bool.
static func by_callable(predicate: Callable) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.FACE
	s._predicate = predicate
	return s

## Select vertices (target_type = VERTEX).
static func all_vertices() -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = TargetType.VERTEX
	s._predicate = func(_mesh: MeshData, _idx: int) -> bool: return true
	return s

# ---------------------------------------------------------------------------
# Composition
# ---------------------------------------------------------------------------

## AND — both selectors must match.
func and_also(other: MeshSelector) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = target_type
	var pred_a := _predicate
	var pred_b := other._predicate
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		return pred_a.call(mesh, idx) and pred_b.call(mesh, idx)
	return s

## OR — either selector matches.
func or_else(other: MeshSelector) -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = target_type
	var pred_a := _predicate
	var pred_b := other._predicate
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		return pred_a.call(mesh, idx) or pred_b.call(mesh, idx)
	return s

## NOT — invert the selector.
func not_matching() -> MeshSelector:
	var s := MeshSelector.new()
	s.target_type = target_type
	var pred := _predicate
	s._predicate = func(mesh: MeshData, idx: int) -> bool:
		return not pred.call(mesh, idx)
	return s
