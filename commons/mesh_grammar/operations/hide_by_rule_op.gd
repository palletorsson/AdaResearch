## HideByRuleOp — Delete faces whose centroid coords fail a substrate rule.
##
## Encodes the substrate's visibility-channel expressions (rule_30,
## sierpinski, checkerboard, rings, sphere_shell) as mesh-grammar
## predicates. For each selected face, computes its discrete (col, row)
## position from its centroid relative to the AABB of selected faces,
## evaluates the named rule, and deletes the face if the rule returns
## "hidden".
##
## Pairs cleanly with tag_by_grammar + paint_by_tag: tag and paint first,
## then carve the algorithmic pattern through the painted anatomy.
##
## Params:
##   rule: String — "rule_30" / "sierpinski" / "checkerboard" / "rings" / "sphere_shell"
##   cols: int = 16     — grid resolution along x for discrete-rule mapping
##   rows: int = 16     — grid resolution along z
##   invert: bool = false  — flip the predicate (delete visible instead)
##   seed_col: int = -1 — for rule_30, single-cell seed column. -1 = centre.
extends MeshRule
class_name HideByRuleOp


# Pre-computed Rule 30 board, per (rule, cols, rows, seed) signature.
var _rule_30_board: PackedByteArray = PackedByteArray()
var _rule_30_signature: String = ""


func _execute(mesh: MeshData, selected: PackedInt32Array) -> void:
	var rule: String = String(params.get("rule", "checkerboard")).to_lower()
	var cols: int = max(int(params.get("cols", 16)), 2)
	var rows: int = max(int(params.get("rows", 16)), 2)
	var invert: bool = bool(params.get("invert", false))
	var seed_col: int = int(params.get("seed_col", -1))

	# Compute centroid AABB to map continuous → discrete grid.
	var centroids: Array[Vector3] = []
	for fi in selected:
		if fi >= mesh.faces.size():
			centroids.append(Vector3.ZERO)
			continue
		var f := mesh.faces[fi]
		var c := (mesh.vertices[f[0]] + mesh.vertices[f[1]] + mesh.vertices[f[2]]) / 3.0
		centroids.append(c)
	if centroids.is_empty():
		return
	var minp := centroids[0]
	var maxp := centroids[0]
	for c in centroids:
		minp.x = min(minp.x, c.x); minp.y = min(minp.y, c.y); minp.z = min(minp.z, c.z)
		maxp.x = max(maxp.x, c.x); maxp.y = max(maxp.y, c.y); maxp.z = max(maxp.z, c.z)
	var span := maxp - minp
	if span.x < 0.001: span.x = 1.0
	if span.z < 0.001: span.z = 1.0

	# Pre-compute Rule 30 board if needed (single seed at centre by default).
	if rule == "rule_30":
		var sig := "%d_%d_%d" % [cols, rows, seed_col]
		if sig != _rule_30_signature:
			_evolve_rule_30(cols, rows, seed_col)
			_rule_30_signature = sig

	# Decide deletion per face.
	var to_delete: PackedInt32Array = PackedInt32Array()
	for i in range(selected.size()):
		var fi: int = selected[i]
		if fi >= mesh.faces.size():
			continue
		var c: Vector3 = centroids[i]
		var col: int = clamp(int((c.x - minp.x) / span.x * float(cols - 1)), 0, cols - 1)
		var row: int = clamp(int((c.z - minp.z) / span.z * float(rows - 1)), 0, rows - 1)
		var visible: bool = _rule_visible(rule, col, row, cols, rows, c, minp, maxp)
		if invert:
			visible = not visible
		if not visible:
			to_delete.append(fi)

	# Delete in descending order via mesh.remove_faces helper.
	if to_delete.size() > 0:
		var sorted := Array(to_delete)
		sorted.sort()
		sorted.reverse()
		var sorted_packed := PackedInt32Array(sorted)
		mesh.remove_faces(sorted_packed)


func _rule_visible(rule: String, col: int, row: int, cols: int, rows: int,
		c: Vector3, minp: Vector3, maxp: Vector3) -> bool:
	match rule:
		"rule_30":
			var idx: int = row * cols + col
			if idx < 0 or idx >= _rule_30_board.size():
				return false
			return _rule_30_board[idx] != 0
		"sierpinski":
			# (row AND col) == 0 — Pascal's triangle mod 2 / Sierpinski gasket.
			return (row & col) == 0
		"checkerboard":
			return ((row + col) % 2) == 0
		"rings":
			# Concentric Chebyshev bands.
			var cr: float = (rows - 1) * 0.5
			var cc: float = (cols - 1) * 0.5
			var dr: float = abs(float(row) - cr)
			var dc: float = abs(float(col) - cc)
			var d: int = int(max(dr, dc))
			return (d % 2) == 0
		"sphere_shell":
			# 3D rule: visible iff distance from centre is in a narrow band.
			var centre := (minp + maxp) * 0.5
			var pos := c
			var dist: float = pos.distance_to(centre)
			var span_min: float = min(maxp.x - minp.x, min(maxp.y - minp.y, maxp.z - minp.z))
			var radius: float = span_min * 0.4
			var width: float = span_min * 0.08
			return abs(dist - radius) <= width
	return true


func _evolve_rule_30(cols: int, rows: int, seed_col: int) -> void:
	# Classical 1D CA Rule 30 evolved row-by-row from a single seed cell.
	# Lookup of Rule 30: 0b00011110 = 30. (left, centre, right) → next centre.
	_rule_30_board = PackedByteArray()
	_rule_30_board.resize(cols * rows)
	for n in range(_rule_30_board.size()):
		_rule_30_board[n] = 0
	var seed: int = seed_col if seed_col >= 0 else cols / 2
	if seed < 0 or seed >= cols:
		seed = cols / 2
	_rule_30_board[seed] = 1
	for r in range(1, rows):
		for c in range(cols):
			var lc: int = (c - 1 + cols) % cols
			var rc: int = (c + 1) % cols
			var pattern: int = (_rule_30_board[(r - 1) * cols + lc] << 2) \
				| (_rule_30_board[(r - 1) * cols + c] << 1) \
				| _rule_30_board[(r - 1) * cols + rc]
			_rule_30_board[r * cols + c] = (30 >> pattern) & 1
