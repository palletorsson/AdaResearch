class_name ModularBuilder
extends RefCounted
## The operators of the modular class system: build a Node3D from an expression.
##
##   {"t": name}                               a term (commons/modular/terms.json)
##   {"p": "point" | "mesh" | "collider" | "body" | "grabbable" | "label" | "light", ...}
##   {"op": "compose",    "parts": [expr…]}    one thing from several; a `body` or
##                                             `grabbable` part makes the thing a body
##   {"op": "associate",  "of": expr, "surface": name, "story": text}
##   {"op": "times",      "of": expr, "n": k, "layout": row|stack|ring|polygon|mirror, …}
##   {"op": "array",      "of": expr, "n": k, "step": m, "dims": 2|3, "y": lift}
##                        times and array also take "palette": [hex…] with "palette_by": index|checker|row|
##                        column|layer (a copy's colour follows its address, not its place) and "profile":
##                        ramp|sin|parabola|gauss|beat (a copy's height follows a function of its index; with
##                        "rise": m the function MOVES the copy up instead — a sampled path)
##   {"op": "recurse",    "of": seed, "rules": [{at, rot, scale}…], "depth": d, "keep": "seed", "stack": [x,y,z]}
##                        a thing made of smaller copies of itself (an iterated function system)
##   {"op": "rewrite",    "axiom": s, "rules": {sym: s}, "depth": d, "angle": deg, "step": m, "of": segment}
##                        an L-system: the sentence rewritten d times, then read by a turtle
##   {"op": "field",      "fn": f, "box": [x,y,z], "res": cells, "collide": true}
##                        a surface where a function of space crosses zero — isosurfaces and booleans
##                        (mod_field.gd: signed distances, unions, cuts, gyroids, metaballs, noise)
##   {"op": "assemblage", "parts": [{"of": expr, "at": [x,y,z], "rot": [°,°,°], "scale": [..]}]}
##   {"op": "engine",     "of": expr, "kind": physics|trace|hand|sine|sine_field|noise|random|logic}
##   {"op": "transform",  "of": expr, "at", "rot", "scale"}
##   {"op": "connect",    "of": expr, "a": i, "b": j, "kind": rope|rod|spring}  or "ties": [[i,j,kind]…]
##                        the strings: a relation between two parts (by index), drawn as a tie
##   {"op": "exhibit",    "of": expr, "text": caption, "light": energy}   the museum's staging as ONE
##                        wrapper: the thing, a label over it, a lamp above it, an area around it that
##                        senses the visitor. Staging is not the principle: it is a branch, not a track step
##   {"op": "sort",       "of": expr, "by": size|height|width|name|type, "gap": m}   measure's first
##                        operator: the parts of a thing in a row by a reading of each
##   {"p": "prefab", "token": name}   an artifact of the registry standing in the grammar as
##                        itself (the net of prefabs) — the scene the spawn lists name for it
##
## Every node a sub-term produced carries meta `term`; every node a primitive
## produced carries meta `primitive`. That is what the scanner, the probe and the
## explode view read: the construction stays legible in the built tree.

const ModMesh := preload("res://commons/modular/mod_mesh.gd")
const ModSurface := preload("res://commons/modular/mod_surface.gd")
const ModBody := preload("res://commons/modular/mod_body.gd")
const ModGrabbable := preload("res://commons/modular/mod_grabbable.gd")
const ModLabel := preload("res://commons/modular/mod_label.gd")
const ModPoint := preload("res://commons/modular/mod_point.gd")
const ModBehaviour := preload("res://commons/modular/mod_behaviour.gd")
const ModField := preload("res://commons/modular/mod_field.gd")

const MAX_DEPTH := 24   # term references only: a term that contains itself trips it, depth of operators does not


static func build(expr: Dictionary, terms: Dictionary, depth: int = 0) -> Node3D:
	if depth > MAX_DEPTH:
		push_error("modular: expression deeper than %d (a term that contains itself?)" % MAX_DEPTH)
		return Node3D.new()
	if expr.has("t"):
		var name: String = str(expr["t"])
		var t: Variant = terms.get(name, null)
		if not (t is Dictionary) or not ((t as Dictionary).get("build", null) is Dictionary):
			push_error("modular: unknown term " + name)
			var missing := Node3D.new()
			missing.name = "missing_" + name
			return missing
		var n: Node3D = build((t as Dictionary)["build"], terms, depth + 1)   # the one place depth grows
		n.name = name
		n.set_meta("term", name)
		# a point is white on its own and black once it belongs to something
		if name == "point" and depth > 0:
			_tint(n, Color("2b1d14"))
		if bool(expr.get("scaffold", false)):
			n.set_meta("scaffold", true)
		return n
	if expr.has("p"):
		return _primitive(expr)
	match str(expr.get("op", "")):
		"compose":
			return _compose(expr, terms, depth)
		"associate":
			var n: Node3D = build(expr.get("of", {}), terms, depth)
			var surface: String = str(expr.get("surface", ""))
			if surface != "":
				ModSurface.apply(n, surface)
			var story: String = str(expr.get("story", ""))
			if story != "":
				var l: Label3D = ModLabel.make(story, 0.0045)
				l.position = Vector3(0, _top_of(n) + 0.18, 0)
				n.add_child(l)
			n.set_meta("associate", {"surface": surface, "story": story})
			return n
		"times":
			return _times(expr, terms, depth)
		"array":
			return _array(expr, terms, depth)
		"recurse":
			return _recurse(expr, terms, depth)
		"rewrite":
			return _rewrite(expr, terms, depth)
		"field":
			return ModField.build(expr)
		"assemblage":
			var root := Node3D.new()
			root.name = "assemblage"
			for part_v in expr.get("parts", []):
				var part: Dictionary = part_v
				var n: Node3D = build(part.get("of", {}), terms, depth)
				_place(n, part)
				if bool(part.get("scaffold", false)):
					n.set_meta("scaffold", true)
				root.add_child(n)
			return root
		"engine":
			var n: Node3D = build(expr.get("of", {}), terms, depth)
			var root := Node3D.new()
			root.name = "engine_" + str(expr.get("kind", ""))
			root.add_child(n)
			ModBehaviour.attach(root, expr)
			return root
		"sort":
			return _sort(expr, terms, depth)
		"connect":
			return _connect(expr, terms, depth)
		"exhibit":
			return _exhibit(expr, terms, depth)
		"transform":
			var n: Node3D = build(expr.get("of", {}), terms, depth)
			_place(n, expr)
			return n
		_:
			push_error("modular: unknown operator in " + JSON.stringify(expr))
			return Node3D.new()


static func _primitive(expr: Dictionary) -> Node3D:
	var kind: String = str(expr.get("p", ""))
	var n: Node3D
	match kind:
		"point":
			n = ModPoint.make(expr)
		"mesh":
			n = ModMesh.make(expr)
		"collider":
			n = ModBody.collider(expr)
		"body":
			n = Node3D.new()
			n.name = "__body"
			n.set_meta("body_kind", str(expr.get("kind", "static")))
		"grabbable":
			n = Node3D.new()
			n.name = "__grabbable"
		"label":
			n = ModLabel.make(str(expr.get("text", "")), float(expr.get("pixel_size", 0.005)))
		"prefab":
			n = _prefab(expr)
		"light":
			var l := OmniLight3D.new()
			l.light_energy = float(expr.get("energy", 1.0))
			l.omni_range = float(expr.get("range", 3.0))
			l.light_color = Color(str(expr.get("color", "ffffff")))
			n = l
		_:
			push_error("modular: unknown primitive " + kind)
			n = Node3D.new()
	n.set_meta("primitive", kind)
	_place(n, expr)
	return n


## compose: build the parts; a `body` / `grabbable` marker among them decides what
## the root is (StaticBody3D, RigidBody3D, Area3D or an XR Tools pickable), so that
## the colliders among the parts are the body's direct children and work.
static func _compose(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var parts: Array = []
	var body_kind := ""
	var grabbable := false
	for p_v in expr.get("parts", []):
		var n: Node3D = build(p_v, terms, depth)
		if p_v is Dictionary and bool((p_v as Dictionary).get("scaffold", false)):
			n.set_meta("scaffold", true)
		if n.name == "__grabbable" or n.get_meta("term", "") == "grabbable":
			grabbable = true
			n.free()
			continue
		if n.name == "__body":
			body_kind = str(n.get_meta("body_kind", "static"))
			n.free()
			continue
		parts.append(n)
	var root: Node3D
	if grabbable:
		root = ModGrabbable.make()
	elif body_kind != "":
		root = ModBody.make(body_kind)
	else:
		root = Node3D.new()
	root.name = "compose"
	for n in parts:
		# a collider term / primitive must be a DIRECT child of the body
		if n is CollisionShape3D and n.get_parent() != null:
			n.get_parent().remove_child(n)
		root.add_child(n)
	if grabbable and not _has_collider(root):
		root.add_child(ModBody.collider_for(root))
	return root


static func _times(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var root := Node3D.new()
	root.name = "times"
	var n: int = int(expr.get("n", 2))
	var layout: String = str(expr.get("layout", "row"))
	var gap: float = float(expr.get("gap", 0.3))
	var axis: String = str(expr.get("axis", "x"))
	var phase: float = deg_to_rad(float(expr.get("phase", 0.0)))
	for i in range(n):
		var c: Node3D = build(expr.get("of", {}), terms, depth)
		match layout:
			"row":
				var off: float = (i - (n - 1) / 2.0) * gap
				c.position = Vector3(off, 0, 0) if axis == "x" else Vector3(0, 0, off)
			"stack":
				c.position = Vector3(0, i * gap, 0)
			"ring":
				c.rotation.y = phase + PI * i / n
			"polygon":
				# n copies of a unit-length edge laid as a regular n-gon in the XZ plane
				var r: float = 1.0 / (2.0 * sin(PI / n))
				var a0: float = TAU * i / n
				var a1: float = TAU * (i + 1) / n
				var v0 := Vector3(r * cos(a0), 0, r * sin(a0))
				var v1 := Vector3(r * cos(a1), 0, r * sin(a1))
				var d: Vector3 = v1 - v0
				c.position = (v0 + v1) * 0.5
				c.rotation.y = -atan2(d.z, d.x)
				c.scale.x = d.length()
			"mirror":
				c.rotation.y = PI * i
			"circle":
				# round a circle in the vertical plane: the height of each is the sine of its angle
				var rad: float = float(expr.get("radius", 0.5))
				c.position = Vector3(rad * cos(TAU * i / n), rad * sin(TAU * i / n), 0)
			"phyllotaxis":
				# the golden angle: each turned 137.5 degrees from the last, pushed out by the root of its count
				var a: float = deg_to_rad(137.508) * i
				var rr: float = gap * sqrt(float(i))
				c.position = Vector3(rr * cos(a), 0, rr * sin(a))
			_:
				c.position = Vector3(i * gap, 0, 0)
		_dress(c, expr, i, Vector3i(0, 0, i), float(i) / maxf(1.0, n - 1.0))
		root.add_child(c)
	return root


static func _array(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var root := Node3D.new()
	root.name = "array"
	var n: int = int(expr.get("n", 3))
	var step: float = float(expr.get("step", 0.3))
	var dims: int = int(expr.get("dims", 2))
	var lift: float = float(expr.get("y", 0.0))
	var ny: int = n if dims == 3 else 1
	# a 1d array is a ROW along z, so planks (long in x) lie side by side. Until 25 Oct dims 1 built
	# a square: eu_pallet's "plank * 3" was nine boards and its "plank * 5" twenty-five
	var nx: int = 1 if dims == 1 else n
	var lin := 0
	for i in range(nx):
		for j in range(ny):
			for k in range(n):
				var c: Node3D = build(expr.get("of", {}), terms, depth)
				c.position = Vector3((i - (nx - 1) / 2.0) * step, lift + j * step, (k - (n - 1) / 2.0) * step)
				c.set_meta("cell", Vector3i(i, j, k))
				_dress(c, expr, lin, Vector3i(i, j, k), float(k) / maxf(1.0, n - 1.0))
				lin += 1
				root.add_child(c)
	return root


## A repeat's copy dressed by its address (Palle, 26 Oct: "then arrays, color, and all things that
## happen there"): "palette" gives it the colour at its index — by linear index, checker parity, row,
## column or layer — so colour is assigned independently of placement; "profile" scales its height by a
## function of its index (ramp, sin, parabola: the samples of change and accumulation). Additive: a
## repeat without these keys is built exactly as before.
static func _dress(c: Node3D, expr: Dictionary, lin: int, cell: Vector3i, u: float) -> void:
	var pal: Array = expr.get("palette", [])
	if not pal.is_empty():
		var idx: int = lin
		match str(expr.get("palette_by", "index")):
			"checker":
				idx = cell.x + cell.y + cell.z
			"row":
				idx = cell.z
			"column":
				idx = cell.x
			"layer":
				idx = cell.y
		_tint(c, Color(str(pal[idx % pal.size()])))
	var prof: String = str(expr.get("profile", ""))
	if prof != "":
		var h: float = u
		match prof:
			"sin":
				h = 0.5 + 0.5 * sin(TAU * u)
			"parabola":
				h = 1.0 - pow(2.0 * u - 1.0, 2.0)
			"gauss":
				h = exp(-0.5 * pow((u - 0.5) / 0.17, 2.0))
			"beat":
				h = 0.5 + 0.25 * (sin(TAU * 7.0 * u) + sin(TAU * 8.0 * u))
		if expr.has("rise"):
			c.position.y += float(expr.get("rise", 0.0)) * h   # the function moves the copy: a sampled path
		else:
			c.scale.y *= maxf(0.08, h)


## recurse — a thing made of smaller copies of itself (Palle, 26 Oct: "and the recursion"). Generation
## n+1 is the rules' transforms applied to generation n: an iterated function system. "keep": "seed"
## puts a fresh seed in every generation (a tree carries its trunk); "stack": [x, y, z] shows every
## generation, each offset (predict one before seeing the next). Depth is capped so the copies of the
## seed stay under 3000.
static func _recurse(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var rules: Array = expr.get("rules", [])
	var keep_seed: bool = str(expr.get("keep", "")) == "seed"
	var levels: int = int(expr.get("depth", 3))
	var per: int = maxi(1, rules.size())
	while levels > 0 and pow(per, levels) > 3000:
		levels -= 1
	var gen: Node3D = build(expr.get("of", {}), terms, depth)
	gen.set_meta("seed", true)
	var shown: Array = [gen]
	for d in range(levels):
		var g := Node3D.new()
		g.name = "generation_%d" % (d + 1)
		if keep_seed:
			var s: Node3D = build(expr.get("of", {}), terms, depth)
			s.set_meta("seed", true)
			g.add_child(s)
		for r in rules:
			var c: Node3D = gen.duplicate()
			_place(c, r)
			g.add_child(c)
		gen = g
		shown.append(gen)
	var root := Node3D.new()
	root.name = "recurse"
	var stack: Variant = expr.get("stack", null)
	if stack is Array and (stack as Array).size() >= 3:
		var off := Vector3(float(stack[0]), float(stack[1]), float(stack[2]))
		for i in shown.size():
			(shown[i] as Node3D).position += off * i
			root.add_child(shown[i])
	else:
		root.add_child(gen)
		for i in shown.size() - 1:
			(shown[i] as Node3D).free()   # the earlier generations live on only as copies inside the last
	return root


## rewrite — an L-system: the axiom rewritten by its rules "depth" times, then read by a turtle in the
## vertical plane: F and G draw a segment and move, f moves, + and - turn by "angle", [ and ] keep a
## place and return to it. Each segment is a copy of "of" (a unit stroke along x by default) scaled to
## "step". Capped at 4000 segments.
static func _rewrite(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var s: String = str(expr.get("axiom", "F"))
	var rules: Dictionary = expr.get("rules", {})
	for i in range(int(expr.get("depth", 3))):
		var out := ""
		for ch in s:
			out += str(rules.get(ch, ch))
		if out.count("F") + out.count("G") > 4000:
			break
		s = out
	var angle: float = deg_to_rad(float(expr.get("angle", 25.0)))
	var step: float = float(expr.get("step", 0.1))
	var head: float = deg_to_rad(float(expr.get("heading", 90.0)))
	var seg: Dictionary = expr.get("of", {"p": "mesh", "shape": "box", "size": [1.0, 0.012, 0.012], "color": "2b1d14"})
	var root := Node3D.new()
	root.name = "rewrite"
	root.set_meta("sentence", s.length())
	var pos := Vector3.ZERO
	var saved: Array = []
	for ch in s:
		match ch:
			"F", "G":
				var nxt: Vector3 = pos + Vector3(cos(head), sin(head), 0) * step
				var c: Node3D = build(seg, terms, depth)
				c.position = (pos + nxt) * 0.5
				c.rotation.z = head
				c.scale.x = step
				root.add_child(c)
				pos = nxt
			"f":
				pos += Vector3(cos(head), sin(head), 0) * step
			"+":
				head += angle
			"-":
				head -= angle
			"[":
				saved.append([pos, head])
			"]":
				if not saved.is_empty():
					var st: Array = saved.pop_back()
					pos = st[0]
					head = st[1]
	return root


static func _place(n: Node3D, spec: Dictionary) -> void:
	var at: Variant = spec.get("at", null)
	if at is Array and (at as Array).size() >= 3:
		n.position += Vector3(float(at[0]), float(at[1]), float(at[2]))
	var rot: Variant = spec.get("rot", null)
	if rot is Array and (rot as Array).size() >= 3:
		n.rotation_degrees += Vector3(float(rot[0]), float(rot[1]), float(rot[2]))
	var s: Variant = spec.get("scale", null)
	if s is Array and (s as Array).size() >= 3:
		n.scale = Vector3(float(s[0]), float(s[1]), float(s[2]))
	elif s is float or s is int:
		n.scale = Vector3.ONE * float(s)


static func _tint(n: Node, color: Color) -> void:
	if n is MeshInstance3D and (n as MeshInstance3D).material_override is StandardMaterial3D:
		((n as MeshInstance3D).material_override as StandardMaterial3D).albedo_color = color
		if color.a < 1.0:   # a palette entry with alpha (#rrggbbaa) must be seen through
			((n as MeshInstance3D).material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	for c in n.get_children():
		_tint(c, color)


## The scaffold: parts shown while a thing is built, gone when it is done.
static func scaffold_of(n: Node) -> Array:
	var out: Array = []
	if n.get_meta("scaffold", false):
		out.append(n)
		return out
	for c in n.get_children():
		out.append_array(scaffold_of(c))
	return out


static func _has_collider(n: Node) -> bool:
	for c in n.get_children():
		if c is CollisionShape3D:
			return true
	return false


## The net of prefabs: the spawn lists know every registry token's scene; a prefab leaf
## instantiates it, or stands a named box of its footprint when the scene is not on disk.
static var _prefab_catalog: Dictionary = {}

static func _prefab(expr: Dictionary) -> Node3D:
	var token: String = str(expr.get("token", ""))
	if _prefab_catalog.is_empty():
		var f := FileAccess.open("res://commons/data/void_spawnlists.json", FileAccess.READ)
		if f != null:
			var d: Variant = JSON.parse_string(f.get_as_text())
			if d is Dictionary:
				_prefab_catalog = (d as Dictionary).get("items", {})
	var info: Dictionary = _prefab_catalog.get(token, _prefab_catalog.get("kit:" + token, _prefab_catalog.get("prop:" + token, {})))
	var scene_path: String = str(info.get("scene", ""))
	var n: Node3D
	if scene_path != "" and ResourceLoader.exists(scene_path):
		var inst: Node = (load(scene_path) as PackedScene).instantiate()
		if inst is Node3D:
			n = inst
		else:
			n = Node3D.new()
			n.add_child(inst)
	else:
		var fp: Array = info.get("footprint", null) if info.get("footprint", null) is Array else [0.6, 0.6, 0.6]
		n = Node3D.new()
		var box := ModMesh.make({"shape": "box", "size": [float(fp[0]), float(fp[1]), float(fp[2])], "color": "f7f2e6", "at": [0, float(fp[1]) / 2.0, 0]})
		n.add_child(box)
		var l := ModLabel.make(token, 0.005)
		l.position.y = float(fp[1]) + 0.12
		n.add_child(l)
	n.name = "prefab_" + token
	n.set_meta("prefab", token)
	return n


## sort: build `of`, read each direct part (size, height, width or name), lay them in a row
## in that order. The reading is kept on the part as meta "reading"; the row as "measure".
static func _sort(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var inner: Node3D = build(expr.get("of", {}), terms, depth)
	var by: String = str(expr.get("by", "size"))
	var gap: float = float(expr.get("gap", 0.08))
	var rows: Array = []
	for c in inner.get_children():
		if c is Node3D and not (c is Label3D):
			var box: AABB = _aabb_of(c)
			var key: Variant
			match by:
				"height": key = box.size.y
				"width": key = box.size.x
				"name": key = String(c.name)
				"type": key = str(c.get_meta("term", c.get_meta("prefab", c.get_meta("primitive", String(c.name)))))
				_: key = box.size.length()
			rows.append({"node": c, "key": key, "w": box.size.x})
	rows.sort_custom(func(a, b): return (a["key"] < b["key"]) if typeof(a["key"]) == typeof(b["key"]) else (str(a["key"]) < str(b["key"])))
	var total: float = gap * max(0, rows.size() - 1)
	for r in rows:
		total += float(r["w"])
	var x: float = -total / 2.0
	var readings: Array = []
	for i in range(rows.size()):
		var r: Dictionary = rows[i]
		var c: Node3D = r["node"]
		c.position.x = x + float(r["w"]) / 2.0
		c.position.z = 0.0
		c.set_meta("reading", r["key"])
		c.set_meta("rank", i)
		readings.append(r["key"])
		x += float(r["w"]) + gap
	inner.name = "sort_by_" + by
	inner.set_meta("measure", {"by": by, "readings": readings})
	return inner


## connect: the strings. Build `of`, tie two of its parts (by index) with a rope, a rod or a
## spring drawn between their centres; meta "tie" on the tie, "connect" on the thing. The
## physics joint behind a tie is the step engine's business, not the builder's.
static func _connect(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var inner: Node3D = build(expr.get("of", {}), terms, depth)
	var kids: Array = []
	for c in inner.get_children():
		if c is Node3D and not (c is Label3D) and not c.has_meta("tie"):
			kids.append(c)
	var ties: Array = expr.get("ties", [[int(expr.get("a", 0)), int(expr.get("b", 1)), str(expr.get("kind", "rope"))]])
	for t in ties:
		if not (t is Array) or (t as Array).size() < 2:
			continue
		var ia: int = int(t[0])
		var ib: int = int(t[1])
		var kind: String = str(t[2]) if (t as Array).size() > 2 else "rope"
		if ia < 0 or ib < 0 or ia >= kids.size() or ib >= kids.size():
			continue
		var pa: Vector3 = _aabb_of(kids[ia]).get_center()
		var pb: Vector3 = _aabb_of(kids[ib]).get_center()
		var d: Vector3 = pb - pa
		var length: float = d.length()
		if length < 0.0001:
			continue
		var r: float = 0.012 if kind == "rod" else (0.02 if kind == "spring" else 0.006)
		var tie: MeshInstance3D = ModMesh.make({"shape": "cylinder", "size": [r, length], "color": "c9a978" if kind == "rod" else "2b1d14"})
		if kind == "spring":
			tie.material_override = ModSurface.material("stripes")
		tie.position = (pa + pb) * 0.5
		var up: Vector3 = Vector3.UP
		var dir: Vector3 = d.normalized()
		if abs(up.dot(dir)) < 0.999:
			var axis: Vector3 = up.cross(dir).normalized()
			tie.rotation = Quaternion(axis, acos(clamp(up.dot(dir), -1.0, 1.0))).get_euler()
		elif up.dot(dir) < 0:
			tie.rotation = Vector3(PI, 0, 0)
		tie.name = "tie_%s_%d_%d" % [kind, ia, ib]
		tie.set_meta("tie", {"a": ia, "b": ib, "kind": kind})
		inner.add_child(tie)
	inner.set_meta("connect", ties)
	return inner


## exhibit: the staging most spine artifacts carry around their object — a label, a lamp, a
## trigger area — written once. Measured 25 Oct: of 1015 artifacts, 387 lack only a label, 316 a
## sensor and 315 a lamp to be one step from a term; this wrapper is that step.
static func _exhibit(expr: Dictionary, terms: Dictionary, depth: int) -> Node3D:
	var root := Node3D.new()
	root.name = "exhibit"
	var thing: Node3D = build(expr.get("of", {}), terms, depth)
	root.add_child(thing)
	var box: AABB = _aabb_of(thing)
	var top: float = box.position.y + box.size.y
	var centre: Vector3 = box.get_center()
	var text: String = str(expr.get("text", thing.get_meta("term", "")))
	if text != "":
		var l := ModLabel.make(text, 0.004)
		l.position = Vector3(centre.x, top + 0.18, centre.z)
		l.set_meta("construction_mark", true)
		root.add_child(l)
	var lamp := OmniLight3D.new()
	lamp.name = "lamp"
	lamp.light_energy = float(expr.get("light", 1.2))
	lamp.light_color = Color(str(expr.get("light_color", "fff1d8")))
	lamp.omni_range = max(2.0, box.size.length() * 2.0)
	lamp.position = Vector3(centre.x, top + 0.9, centre.z)
	root.add_child(lamp)
	var area := Area3D.new()
	area.name = "sense"
	area.set_meta("modular_body", "area")
	area.set_meta("exhibit_sense", true)
	var cs := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size + Vector3(1.2, 0.6, 1.2)   # the visitor is sensed within 60 cm of the thing
	cs.shape = shape
	cs.position = centre
	area.add_child(cs)
	root.add_child(area)
	root.set_meta("exhibit", {"text": text})
	return root


## The local bounds of a node and its meshes, before it is in the tree.
static func _aabb_of(n: Node3D, xform: Transform3D = Transform3D.IDENTITY) -> AABB:
	var t: Transform3D = xform * n.transform
	var box: AABB
	var has := false
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		box = t * (n as MeshInstance3D).mesh.get_aabb()
		has = true
	for c in n.get_children():
		if c is Node3D:
			var cb: AABB = _aabb_of(c, t)
			if cb.size != Vector3.ZERO or cb.position != Vector3.ZERO:
				box = cb if not has else box.merge(cb)
				has = true
	if not has:
		box = AABB(t.origin, Vector3.ZERO)
	return box


static func _top_of(n: Node3D) -> float:
	var top := 0.0
	for m in _meshes(n):
		var aabb: AABB = m.get_aabb()
		var t: float = (m.transform * aabb).end.y
		top = maxf(top, t)
	return top


static func _meshes(n: Node) -> Array:
	var out: Array = []
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		out.append_array(_meshes(c))
	return out
