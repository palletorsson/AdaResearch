extends RefCounted
## BAR RIGIDITY - the first thing the playground editor proves (Palle, 2026-11-06: the Triangle stage, "a square sags
## and a diagonal braces it"). The kit read as a framework: every ball a POINT, every rod a BAR that keeps the
## distance between its two points and nothing else (a pin at each end - it does not keep an angle), every ball
## standing on the floor an ANCHOR. A point in space has three ways to move; each bar to it can take away at most one.
## The bars fix a point when no small motion of the free points keeps every bar's length: that is the RIGIDITY
## MATRIX (a row per bar, (p_a - p_b) in a's three columns and (p_b - p_a) in b's) having no motion left in that
## point's columns. The motions that are left - its null space - are the framework's FREE MOTIONS: a square of four
## bars on two floor points has the shear, the brace takes it, and a braced square standing up still tips about its
## floor edge until something holds it from the side. The count is Maxwell's: 3 x free points - independent bars.
## Pure data (positions, anchors, index pairs): the ball's support graph calls it, and the web twin
## (ada_encyclopedia src/lib/kit-graph.ts `rigidity`) runs the same arithmetic.
## Infinitesimal, so exact on the grid: three points in a row with two bars flex (the middle one can move sideways at
## first order), as a pinned chain does.

const EPS := 1e-9
const MODE_EPS := 1e-6

## points: Array[Vector3]; anchored: Array[bool]; bars: Array[Vector2i] (indices into points).
## Returns {flexible: Array[bool], mode: Array[Vector3] (a free motion, largest point move 1), free_motions: int,
## bars_independent: int}.
static func analyse(points: Array, anchored: Array, bars: Array) -> Dictionary:
	var n := points.size()
	var block: Array[int] = []
	var free := 0
	for i in n:
		block.append(-1 if bool(anchored[i]) else free)
		if not bool(anchored[i]):free += 1
	var cols := 3 * free
	var rows: Array[PackedFloat64Array] = []
	for bar: Vector2i in bars:
		var a := bar.x;var b := bar.y
		if block[a] < 0 and block[b] < 0:continue
		var d: Vector3 = points[a] - points[b]
		var row := PackedFloat64Array();row.resize(cols)
		for k in 3:
			if block[a] >= 0:row[3 * block[a] + k] = d[k]
			if block[b] >= 0:row[3 * block[b] + k] = -d[k]
		rows.append(row)
	# reduced row echelon form, partial pivoting
	var pivot_row := {}   # column -> row
	var r := 0
	for c in cols:
		if r >= rows.size():break
		var best := r;var best_v := absf(rows[r][c])
		for i in range(r + 1, rows.size()):
			if absf(rows[i][c]) > best_v:best_v = absf(rows[i][c]);best = i
		if best_v < EPS:continue
		var tmp := rows[r];rows[r] = rows[best];rows[best] = tmp
		var pr := rows[r];var p := pr[c]
		for k in cols:pr[k] /= p
		rows[r] = pr
		for i in rows.size():
			if i == r:continue
			var f := rows[i][c]
			if absf(f) < EPS:continue
			var ri := rows[i]
			for k in cols:ri[k] -= f * pr[k]
			rows[i] = ri
		pivot_row[c] = r;r += 1
	# the null space: one motion per column without a pivot
	var motion := PackedFloat64Array();motion.resize(cols)
	var moves := PackedByteArray();moves.resize(cols)
	for f in cols:
		if pivot_row.has(f):continue
		var v := PackedFloat64Array();v.resize(cols);v[f] = 1.0
		for c in pivot_row:v[c] = -rows[pivot_row[c]][f]
		var norm := 0.0
		for k in cols:norm = maxf(norm, absf(v[k]))
		for k in cols:
			if absf(v[k]) > MODE_EPS:moves[k] = 1
			motion[k] += v[k] / norm
	var flexible: Array[bool] = [];var mode: Array[Vector3] = []
	var biggest := 0.0
	for i in n:
		var j := block[i]
		if j < 0:flexible.append(false);mode.append(Vector3.ZERO);continue
		flexible.append(moves[3 * j] == 1 or moves[3 * j + 1] == 1 or moves[3 * j + 2] == 1)
		var m := Vector3(motion[3 * j], motion[3 * j + 1], motion[3 * j + 2])
		mode.append(m);biggest = maxf(biggest, m.length())
	if biggest > MODE_EPS:
		for i in n:mode[i] = mode[i] / biggest
	return {"flexible": flexible, "mode": mode, "free_motions": cols - r, "bars_independent": r}

## Connected pieces of a framework: Array of Array[int] (point indices), by its bars.
static func components(n: int, bars: Array) -> Array:
	var parent: Array[int] = []
	for i in n:parent.append(i)
	var find := func(x: int) -> int:
		while parent[x] != x:x = parent[x]
		return x
	for bar: Vector2i in bars:
		var ra: int = find.call(bar.x);var rb: int = find.call(bar.y)
		if ra != rb:parent[ra] = rb
	var groups := {}
	for i in n:
		var root: int = find.call(i)
		if not groups.has(root):groups[root] = []
		groups[root].append(i)
	return groups.values()

## The faces of a framework: every triangle of bars, and every square of bars with no bar across it (a crossed
## square is two triangles already). Array of Array[int] (point indices, in order round the face).
static func faces(n: int, bars: Array, points: Array) -> Array:
	var adj := {}
	for i in n:adj[i] = {}
	for bar: Vector2i in bars:adj[bar.x][bar.y] = true;adj[bar.y][bar.x] = true
	var out: Array = [];var seen := {}
	for bar: Vector2i in bars:
		var u := mini(bar.x, bar.y);var v := maxi(bar.x, bar.y)
		for w in adj[u]:
			if w > v and adj[v].has(w):out.append([u, v, w])
	for u in n:
		for w in range(u + 1, n):
			if adj[u].has(w):continue
			var common: Array = []
			for v in adj[u]:
				if adj[w].has(v):common.append(v)
			for i in common.size():
				for j in range(i + 1, common.size()):
					var v: int = common[i];var x: int = common[j]
					if adj[v].has(x):continue   # crossed the other way: two triangles
					var key := [u, v, w, x];key.sort()
					if seen.has(str(key)):continue
					var pu: Vector3 = points[u];var pv: Vector3 = points[v];var pw: Vector3 = points[w];var px: Vector3 = points[x]
					if absf((pv - pu).cross(px - pu).dot(pw - pu)) > 1e-4:continue   # not flat: no face
					seen[str(key)] = true;out.append([u, v, w, x])
	return out
