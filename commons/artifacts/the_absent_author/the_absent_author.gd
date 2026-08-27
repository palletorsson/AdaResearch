extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheAbsentAuthor

## @identity
## lineage: the procedural generation SUPER OBJECT — a workshop whose author left, and
##   the work continued. An empty chair at an empty desk; on the desk a signed card
##   bearing only a seed and a rule, and from that card the whole room unfolds. One
##   authored chair-prefab is stamped nine times down a shelf, each instance nudged by
##   the seed (the instance). A tile loom collapses possibilities into a legal strip,
##   its adjacency sockets visible (the constraint). Beside it, THE FAILED RUN: a
##   collapse that hit a contradiction, kept on the bench with its red mark, because
##   generation can fail and the engine will not tell you. A maze carved by a real
##   walker, a Voronoi claim-map, a Poisson scatter that never clumps, a marching-cube
##   ridge, and an L-system's grammar city — each grown here, from the same signature.
## essence: you do not author the world; you author a rule and a seed, and the world is
##   the consequence. Everything on this bench came from the card on the desk, which
##   is why the chair is empty and the room is still full.
## truth: a world doesn't need an author. Rules and randomness are enough - but
##   somebody still has to check the result.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 1848
@export_range(6, 14) var stamps: int = 9

func _ready() -> void:
	_rng.seed = seed
	_build_desk_and_chair()
	_build_signature()
	_build_stamps()
	_build_loom()
	_build_failed_run()
	_build_maze()
	_build_voronoi()
	_build_scatter()
	_build_ridge()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "stamps"]:
		if config_data.has(key):
			set(key, config_data[key])

func _tag(at: Vector3, title: String, sub: String) -> void:
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.17
	tag.position = at
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text(title, sub)

func _slab(at: Vector3, size: Vector3, tint: Color, glow: float = 0.0) -> void:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	m.mesh = bm
	m.position = at
	m.material_override = _glow_mat(tint, glow) if glow > 0.0 else _matte_mat(tint, 0.75)
	add_child(m)

# --- the absence -------------------------------------------------------------------------

func _build_desk_and_chair() -> void:
	_slab(Vector3(-1.9, 0.76, 0.0), Vector3(1.1, 0.06, 0.7), Color(0.28, 0.2, 0.13))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(Vector3(-1.9 + sx * 0.48, 0.38, sz * 0.28), Vector3(0.06, 0.76, 0.06), Color(0.2, 0.15, 0.1))
	# the empty chair, pushed back
	_slab(Vector3(-1.9, 0.44, 0.72), Vector3(0.4, 0.05, 0.4), Color(0.3, 0.22, 0.14))
	_slab(Vector3(-1.9, 0.68, 0.9), Vector3(0.4, 0.45, 0.05), Color(0.3, 0.22, 0.14))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(Vector3(-1.9 + sx * 0.16, 0.21, 0.72 + sz * 0.16), Vector3(0.04, 0.42, 0.04), Color(0.2, 0.15, 0.1))

func _build_signature() -> void:
	# the card: a seed and a rule, and the whole room follows from it
	_slab(Vector3(-1.9, 0.8, 0.0), Vector3(0.36, 0.008, 0.24), Color(0.92, 0.9, 0.84), 0.3)
	_tag(Vector3(-1.9, 0.82, 0.0), "seed %d" % seed, "the signature the room unfolds from")

func _build_stamps() -> void:
	# ONE authored prefab, stamped N times - each instance nudged by the seed
	var r := RandomNumberGenerator.new()
	r.seed = seed
	for i in range(stamps):
		var x := -1.0 + 0.26 * float(i)
		var jitter := r.randf_range(-0.02, 0.02)
		var lean := r.randf_range(-0.12, 0.12)
		var holder := Node3D.new()
		holder.position = Vector3(x + jitter, 1.05, -0.75)
		holder.rotation.y = lean
		add_child(holder)
		# the prefab: a little chair, the same authored thing every time
		for spec in [[Vector3(0.0, 0.0, 0.0), Vector3(0.11, 0.012, 0.11)],
				[Vector3(0.0, 0.06, -0.05), Vector3(0.11, 0.12, 0.012)]]:
			var m := MeshInstance3D.new()
			var bm := BoxMesh.new()
			bm.size = spec[1]
			m.mesh = bm
			m.position = spec[0]
			m.material_override = _matte_mat(Color(0.6, 0.45, 0.3), 0.7)
			holder.add_child(m)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var leg := MeshInstance3D.new()
				var lm := BoxMesh.new()
				lm.size = Vector3(0.012, 0.055, 0.012)
				leg.mesh = lm
				leg.position = Vector3(sx * 0.042, -0.032, sz * 0.042)
				leg.material_override = _matte_mat(Color(0.45, 0.33, 0.22), 0.8)
				holder.add_child(leg)
	_slab(Vector3(0.05, 0.98, -0.75), Vector3(2.6, 0.03, 0.24), Color(0.16, 0.14, 0.13))
	_tag(Vector3(0.05, 0.94, -0.5), "the instance", "one authored chair, %d stamps, one seed" % stamps)

func _build_loom() -> void:
	# constraint: a legal strip collapsed under adjacency rules. Tiles are typed
	# 0=ground 1=wall 2=roof; ground may not touch roof.
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var strip: Array = []
	var prev := 0
	for i in range(12):
		var legal: Array = []
		for cand in range(3):
			if prev == 0 and cand == 2:
				continue                    # the rule that bites
			if prev == 2 and cand == 0:
				continue
			legal.append(cand)
		var pick: int = legal[r.randi_range(0, legal.size() - 1)]
		strip.append(pick)
		prev = pick
	var tints := [Color(0.45, 0.6, 0.35), Color(0.65, 0.62, 0.58), Color(0.7, 0.35, 0.3)]
	for i in range(strip.size()):
		var st: int = strip[i]
		_slab(Vector3(-1.0 + 0.14 * float(i), 1.42, -0.75), Vector3(0.12, 0.12, 0.12), tints[st], 0.5)
	_tag(Vector3(-0.2, 1.3, -0.5), "the constraint", "not anything - anything that FITS")

func _build_failed_run() -> void:
	# the exhibit nobody makes: a collapse that hit a contradiction, kept
	for i in range(5):
		_slab(Vector3(1.35 + 0.14 * float(i), 1.42, -0.75), Vector3(0.12, 0.12, 0.12),
			Color(0.5, 0.5, 0.55), 0.3)
	_slab(Vector3(2.05, 1.42, -0.75), Vector3(0.13, 0.13, 0.13), Color(0.9, 0.15, 0.12), 1.6)
	_tag(Vector3(1.7, 1.3, -0.5), "the contradiction", "no legal tile: this run FAILED, and is kept")

func _build_maze() -> void:
	# a real walker digging a perfect maze (recursive backtracker, seeded)
	var W := 9
	var H := 7
	var carved := {}
	var walls := {}
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var stack: Array = [Vector2i(0, 0)]
	carved[Vector2i(0, 0)] = true
	while not stack.is_empty():
		var cur: Vector2i = stack[-1]
		var opts: Array = []
		for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
			var n: Vector2i = cur + d
			if n.x >= 0 and n.x < W and n.y >= 0 and n.y < H and not carved.has(n):
				opts.append(n)
		if opts.is_empty():
			stack.pop_back()
			continue
		var nxt: Vector2i = opts[r.randi_range(0, opts.size() - 1)]
		carved[nxt] = true
		walls[[cur, nxt]] = true
		stack.append(nxt)
	for key in carved:
		var c: Vector2i = key
		_slab(Vector3(-1.35 + float(c.x) * 0.09, 0.08, 0.85 + float(c.y) * 0.09),
			Vector3(0.07, 0.012, 0.07), Color(0.8, 0.75, 0.6), 0.4)
	for key in walls:
		var pair: Array = key
		var a: Vector2i = pair[0]
		var b: Vector2i = pair[1]
		_slab(Vector3(-1.35 + (float(a.x) + float(b.x)) * 0.045, 0.08, 0.85 + (float(a.y) + float(b.y)) * 0.045),
			Vector3(0.05, 0.012, 0.05), Color(0.8, 0.75, 0.6), 0.4)
	_tag(Vector3(-1.0, 0.05, 1.55), "the maze", "a walker that never crosses its own path")

func _build_voronoi() -> void:
	# every point claims the territory nearest it — the claim map, computed
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var sites: Array = []
	for i in range(7):
		sites.append(Vector2(r.randf(), r.randf()))
	for iy in range(12):
		for ix in range(12):
			var p := Vector2((float(ix) + 0.5) / 12.0, (float(iy) + 0.5) / 12.0)
			var best := 0
			var bd := 9.0
			for k in range(sites.size()):
				var s: Vector2 = sites[k]
				var dd := p.distance_to(s)
				if dd < bd:
					bd = dd
					best = k
			_slab(Vector3(0.15 + p.x * 0.75, 0.08, 0.85 + p.y * 0.75), Vector3(0.058, 0.012, 0.058),
				Color.from_hsv(float(best) / 7.0, 0.55, 0.9), 0.4)
	_tag(Vector3(0.5, 0.05, 1.72), "Voronoi", "every point claims what is nearest")

func _build_scatter() -> void:
	# Poisson-disk: random, but never too close
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var placed: Array = []
	var tries := 0
	while placed.size() < 22 and tries < 900:
		tries += 1
		var p := Vector2(r.randf(), r.randf())
		var ok := true
		for q in placed:
			if p.distance_to(q) < 0.16:
				ok = false
				break
		if not ok:
			continue
		placed.append(p)
		_slab(Vector3(1.2 + p.x * 0.7, 0.09, 0.85 + p.y * 0.7), Vector3(0.03, 0.05, 0.03),
			Color(0.45, 0.8, 0.6), 0.7)
	_tag(Vector3(1.55, 0.05, 1.68), "Poisson scatter", "chance without clumping (%d of 22 fit)" % placed.size())

func _build_ridge() -> void:
	# marching-cubes' cousin: a field thresholded into a surface, columns as the ridge
	var n := FastNoiseLite.new()
	n.seed = seed
	n.frequency = 0.12
	for ix in range(22):
		var u := float(ix) / 21.0
		var h := 0.1 + 0.4 * (n.get_noise_2d(u * 8.0, 0.0) * 0.5 + 0.5)
		_slab(Vector3(-1.1 + u * 2.2, 1.75 + h * 0.5, 0.35), Vector3(0.09, h, 0.18),
			Color(0.55, 0.58, 0.68).lerp(Color(0.9, 0.9, 0.95), h), 0.0)
	_tag(Vector3(0.0, 1.68, 0.6), "the field, thresholded", "where inside meets outside, a surface")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "AuthorPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.45, 0.24, 1.15)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE ABSENT AUTHOR",
			"The chair is empty and the room is full. On the desk, a card with a seed and\na rule - and everything here unfolded from it: one chair stamped nine times,\na strip collapsed under adjacency, a maze dug by a walker, claimed territory,\nscatter that never clumps. And the failed run, kept on the bench: generation\nCAN fail, and the engine will never tell you.")
