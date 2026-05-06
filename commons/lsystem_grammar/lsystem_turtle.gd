# lsystem_turtle.gd — Turtle interpreter for L-system strings.
#
# Takes a rewritten string and walks it with a 3D turtle, producing
# segments, nodes, and optional branch/leaf info. Multiple output modes
# are supported because the SAME L-system string is DNA for multiple
# substrates — the turtle is the translation layer.
#
# DNA CONNECTIONS (each mode emits a different substrate's input):
#   lines      → ImmediateMesh (native)
#   tubes      → ArrayMesh of cylinder segments (native mesh)
#   primitives → list of (pos, tag) for primitive_stack to place
#   graph      → nodes + edges for graph_grammar
#   softbody   → particles + springs for soft_body_sim
#
# Alphabet (standard Lindenmayer + some extensions):
#   F   draw forward by current_length
#   f   jump forward (no draw)
#   +   yaw  +angle (rotate around up axis)
#   -   yaw  -angle
#   &   pitch +angle (rotate around right axis)
#   ^   pitch -angle
#   /   roll  +angle (rotate around forward axis)
#   \   roll  -angle
#   |   turn 180°
#   [   push state
#   ]   pop state, shorten new branches
#   !   decrement branch thickness
#   '   increment branch thickness
#   *   emit "leaf" marker at current position
#   ~   small random perturbation of heading

extends RefCounted


## Walk string with turtle. Returns Dictionary:
##   segments: Array of [start, end, depth, width]
##   leaves:   Array of Vector3 (positions of * markers)
##   branch_points: Array of Vector3 (positions of [ — useful for graph/sb)
##   final_length: length after branches shrank
static func walk(s: String, params: Dictionary = {}) -> Dictionary:
	var angle_deg: float = float(params.get("angle_deg", 25.7))
	var base_length: float = float(params.get("step_len", 0.1))
	var step_shrink: float = float(params.get("step_shrink", 0.72))
	var base_width: float = float(params.get("base_width", 0.02))
	var width_shrink: float = float(params.get("width_shrink", 0.75))
	var perturb: float = float(params.get("perturb", 0.0))
	var seed: int = int(params.get("seed", 0))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed

	var angle_rad: float = deg_to_rad(angle_deg)

	var pos := Vector3.ZERO
	var heading := Vector3.UP
	var left := Vector3.LEFT
	var up := Vector3.FORWARD
	var depth: int = 0
	var cur_length: float = base_length
	var cur_width: float = base_width

	var stack: Array = []
	var segments: Array = []
	var leaves: Array = []
	var branch_points: Array = []

	for c in s:
		match c:
			"F":
				var np := pos + heading * cur_length
				segments.append([pos, np, depth, cur_width])
				pos = np
			"f":
				pos = pos + heading * cur_length
			"+":
				var r := _rotate_axes(heading, left, up, up, angle_rad)
				heading = r[0]; left = r[1]
			"-":
				var r2 := _rotate_axes(heading, left, up, up, -angle_rad)
				heading = r2[0]; left = r2[1]
			"&":
				var r3 := _rotate_axes(heading, left, up, left, angle_rad)
				heading = r3[0]; up = r3[2]
			"^":
				var r4 := _rotate_axes(heading, left, up, left, -angle_rad)
				heading = r4[0]; up = r4[2]
			"/":
				var r5 := _rotate_axes(heading, left, up, heading, angle_rad)
				left = r5[1]; up = r5[2]
			"\\":
				var r6 := _rotate_axes(heading, left, up, heading, -angle_rad)
				left = r6[1]; up = r6[2]
			"|":
				heading = -heading
				left = -left
			"[":
				stack.append({
					"pos": pos, "heading": heading, "left": left, "up": up,
					"depth": depth, "len": cur_length, "w": cur_width,
				})
				branch_points.append(pos)
				depth += 1
				cur_length *= step_shrink
				cur_width *= width_shrink
			"]":
				if stack.size() > 0:
					var st: Dictionary = stack.pop_back()
					pos = st["pos"]; heading = st["heading"]
					left = st["left"]; up = st["up"]
					depth = st["depth"]; cur_length = st["len"]; cur_width = st["w"]
			"!":
				cur_width *= 0.75
			"'":
				cur_width /= 0.75
			"*":
				leaves.append(pos)
			"~":
				if perturb > 0.0:
					heading = (heading + Vector3(
						rng.randf_range(-1, 1),
						rng.randf_range(-1, 1),
						rng.randf_range(-1, 1)) * perturb).normalized()

	return {
		"segments": segments,
		"leaves": leaves,
		"branch_points": branch_points,
		"final_length": cur_length,
	}


static func _rotate_axes(h: Vector3, l: Vector3, u: Vector3,
		axis: Vector3, ang: float) -> Array:
	var ax := axis.normalized()
	return [
		h.rotated(ax, ang).normalized(),
		l.rotated(ax, ang).normalized(),
		u.rotated(ax, ang).normalized(),
	]


# ─── Rendering modes — each a bridge to another substrate ─────

## Mode: lines — classical L-system rendering. ImmediateMesh with depth-gradient.
static func to_lines(walk_result: Dictionary, color_trunk: Color,
		color_tip: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mi.material_override = mat
	mi.mesh = im

	var segments: Array = walk_result["segments"]
	if segments.is_empty(): return mi
	var max_depth := 1
	for seg in segments:
		max_depth = max(max_depth, int(seg[2]))

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for seg in segments:
		var p1: Vector3 = seg[0]
		var p2: Vector3 = seg[1]
		var d: int = int(seg[2])
		var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
		var col := color_trunk.lerp(color_tip, t)
		im.surface_set_color(col)
		im.surface_add_vertex(p1)
		im.surface_set_color(col)
		im.surface_add_vertex(p2)
	im.surface_end()
	return mi


## Mode: tubes — emit a cylinder per segment with width from turtle. Native mesh DNA.
static func to_tubes(walk_result: Dictionary, color_trunk: Color,
		color_tip: Color, sides: int = 6) -> MultiMeshInstance3D:
	var segments: Array = walk_result["segments"]
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = sides
	cm.rings = 1
	mm.mesh = cm
	mm.instance_count = segments.size()

	var max_depth := 1
	for seg in segments:
		max_depth = max(max_depth, int(seg[2]))

	for i in segments.size():
		var seg = segments[i]
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var w: float = max(float(seg[3]), 0.003)
		var mid: Vector3 = (a + b) * 0.5
		var v: Vector3 = b - a
		var h: float = v.length()
		if h < 1e-6: continue
		var axis: Vector3 = v / h
		# CylinderMesh default axis is Y. Rotate Y → axis.
		var y := Vector3.UP
		var basis := Basis()
		var dot = y.dot(axis)
		if dot > 0.9999:
			basis = Basis.IDENTITY
		elif dot < -0.9999:
			basis = Basis(Vector3.RIGHT, PI)
		else:
			var rot_axis := y.cross(axis).normalized()
			var ang := acos(clampf(dot, -1.0, 1.0))
			basis = Basis(rot_axis, ang)
		basis = basis.scaled(Vector3(w, h, w))
		var t := Transform3D(basis, mid)
		mm.set_instance_transform(i, t)
		var d: int = int(seg[2])
		var tt: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
		mm.set_instance_color(i, color_trunk.lerp(color_tip, tt))

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.6
	mmi.material_override = mat
	mmi.multimesh = mm
	return mmi


## Mode: graph — convert walk into a graph structure (nodes + edges).
## Returns Dictionary with positions: Array[Vector3] and edges: Array[[a,b]].
## This is the DNA bridge to graph_grammar: the same L-system string can
## seed a graph then be post-processed with CA-prune, hull-shell, Modulor-fold.
static func to_graph(walk_result: Dictionary) -> Dictionary:
	var segments: Array = walk_result["segments"]
	var positions := PackedVector3Array()
	var edges: Array = []
	# Dedupe positions with small epsilon tolerance
	var key_to_idx := {}
	var eps := 1e-4
	var _key := func(v: Vector3) -> String:
		return "%d_%d_%d" % [roundi(v.x / eps), roundi(v.y / eps), roundi(v.z / eps)]
	for seg in segments:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var ka: String = _key.call(a)
		var kb: String = _key.call(b)
		if not key_to_idx.has(ka):
			key_to_idx[ka] = positions.size()
			positions.append(a)
		if not key_to_idx.has(kb):
			key_to_idx[kb] = positions.size()
			positions.append(b)
		edges.append([key_to_idx[ka], key_to_idx[kb]])
	return {"positions": positions, "edges": edges}


## Mode: softbody — turtle-traced springs as soft-body topology.
## Returns {positions, springs} that soft_body_sim.gd can consume directly.
## DNA bridge: L-system string → physical skeleton that can be dropped + simulated.
static func to_softbody_topology(walk_result: Dictionary) -> Dictionary:
	var g: Dictionary = to_graph(walk_result)
	return {
		"positions": g["positions"],
		"springs": g["edges"],
	}
