extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ReplayCasino

## @identity
## lineage: the randomness SUPER OBJECT — a casino where the house always replays.
##   A brass seed counter presides. Under glass, two dice piles thrown from the SAME
##   seed lie identical to the die, beside a third pile from seed+1 that landed its
##   own way. A Galton board's bins hold the bell that many small accidents added up
##   to. A trail of footprints random-walks off across the floor. A dartboard
##   quarter-circle wears its seeded throws and announces the π they measured. A
##   weather wheel shows Markov's one-step memory as thick and thin ribbons. Two
##   urns wear their entropy in bits. The ceiling carries two star-fields — white
##   noise clumping, blue noise even. A 10 PRINT runner carpets the entrance. And
##   the last vitrine holds a genome ribbon beside the small body it becomes:
##   the deep end, a seed that grows.
## essence: RandomNumberGenerator.seed — the engine's chance is a book, not a storm.
##   Every accident in this room was drawn from seed 4 and will return identically
##   forever; the piles agree because determinism wears chance as a costume. Every
##   number on every placard here was COMPUTED from the seeded draws it describes.
## truth: pseudo-randomness is determinism in disguise — seed it, and every accident
##   comes home.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 4
@export var darts: int = 60

func _ready() -> void:
	_rng.seed = seed
	_build_floor()
	_build_seed_counter()
	_build_dice_vitrine()
	_build_galton()
	_build_walk()
	_build_dartboard()
	_build_markov_wheel()
	_build_urns()
	_build_starfields()
	_build_ten_print()
	_build_genome()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "darts"]:
		if config_data.has(key):
			set(key, config_data[key])

# --- house --------------------------------------------------------------------------

func _build_floor() -> void:
	var base := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(4.6, 0.12, 3.2)
	base.mesh = bm
	base.position = Vector3(0.0, 0.06, 0.0)
	base.material_override = _matte_mat(Color(0.1, 0.08, 0.1), 0.9)
	add_child(base)

func _build_seed_counter() -> void:
	var post := MeshInstance3D.new()
	var pm := CylinderMesh.new()
	pm.top_radius = 0.05
	pm.bottom_radius = 0.08
	pm.height = 1.6
	post.mesh = pm
	post.position = Vector3(0.0, 0.92, -1.35)
	post.material_override = _steel_mat(Color(0.55, 0.46, 0.28))
	add_child(post)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.3
	tag.position = Vector3(0.0, 1.78, -1.35)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("seed = %d" % seed, "the whole casino, replayable")

func _die(at: Vector3, rot: Vector3, tint: Color) -> void:
	var die := MeshInstance3D.new()
	var dm := BoxMesh.new()
	dm.size = Vector3(0.09, 0.09, 0.09)
	die.mesh = dm
	die.position = at
	die.rotation = rot
	die.material_override = _matte_mat(tint, 0.5)
	add_child(die)

func _build_dice_vitrine() -> void:
	# three throws of five dice: A and B from the SAME rng state (identical to the
	# die), C from seed+1. The agreement is the exhibit.
	var glass := StandardMaterial3D.new()
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.albedo_color = Color(0.6, 0.78, 0.82, 0.1)
	var table := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(1.5, 0.65, 0.6)
	table.mesh = tm
	table.position = Vector3(-1.45, 0.445, -1.0)
	table.material_override = _matte_mat(Color(0.13, 0.3, 0.2), 0.85)
	add_child(table)
	var case := MeshInstance3D.new()
	var cm := BoxMesh.new()
	cm.size = Vector3(1.5, 0.4, 0.6)
	case.mesh = cm
	case.position = Vector3(-1.45, 0.97, -1.0)
	case.material_override = glass
	add_child(case)
	for pile in range(3):
		var r := RandomNumberGenerator.new()
		r.seed = seed if pile < 2 else seed + 1
		var cx := -1.9 + 0.45 * float(pile)
		for k in range(5):
			var at := Vector3(cx + r.randf_range(-0.12, 0.12), 0.82, -1.0 + r.randf_range(-0.16, 0.16))
			var rot := Vector3(PI * 0.5 * float(r.randi_range(0, 3)), r.randf_range(0.0, TAU), 0.0)
			var tint := Color(0.92, 0.9, 0.85) if pile < 2 else Color(0.85, 0.45, 0.4)
			_die(at, rot, tint)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.12
		tag.position = Vector3(cx, 0.72, -0.62)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text(["seed", "seed", "seed+1"][pile], "")

func _build_galton() -> void:
	# pegs, a few balls frozen mid-fall, and bins filled with the bell the seeded
	# throws actually made
	var back := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.0, 1.3, 0.05)
	back.mesh = bm
	back.position = Vector3(1.55, 1.05, -1.15)
	back.material_override = _matte_mat(Color(0.14, 0.13, 0.16), 0.85)
	add_child(back)
	for row in range(5):
		for k in range(row + 3):
			var peg := MeshInstance3D.new()
			var pm := CylinderMesh.new()
			pm.top_radius = 0.014
			pm.bottom_radius = 0.014
			pm.height = 0.06
			peg.mesh = pm
			peg.rotation.x = PI * 0.5
			peg.position = Vector3(1.55 + (float(k) - float(row + 2) * 0.5) * 0.11, 1.5 - 0.13 * float(row), -1.11)
			peg.material_override = _steel_mat(Color(0.6, 0.6, 0.65))
			add_child(peg)
	# 200 seeded balls into 8 bins, drawn as bar heights: the bell, computed
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var bins := [0, 0, 0, 0, 0, 0, 0, 0]
	for i in range(200):
		var pos := 0
		for step in range(7):
			pos += 1 if r.randf() < 0.5 else 0
		bins[pos] += 1
	for b in range(8):
		var bar := MeshInstance3D.new()
		var brm := BoxMesh.new()
		var h: float = 0.5 * float(bins[b]) / 60.0
		brm.size = Vector3(0.09, maxf(h, 0.01), 0.05)
		bar.mesh = brm
		bar.position = Vector3(1.55 + (float(b) - 3.5) * 0.11, 0.42 + h * 0.5, -1.11)
		bar.material_override = _glow_mat(Color(0.95, 0.75, 0.3), 0.8)
		add_child(bar)
	for i in range(3):
		var ball := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.022
		sm.height = 0.044
		ball.mesh = sm
		ball.position = Vector3(1.55 + _rng.randf_range(-0.2, 0.2), 1.35 - 0.3 * float(i), -1.11)
		ball.material_override = _glow_mat(Color(0.95, 0.75, 0.3), 1.4)
		add_child(ball)

func _build_walk() -> void:
	# footprints random-walking across the floor, each step a fresh seeded coin
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var at := Vector3(-0.3, 0.13, 0.2)
	var heading := 0.0
	for step in range(14):
		heading += r.randf_range(-0.9, 0.9)
		at += Vector3(cos(heading), 0.0, sin(heading)) * 0.16
		at.x = clampf(at.x, -2.1, 2.1)
		at.z = clampf(at.z, -1.3, 1.4)
		var side := 0.03 if step % 2 == 0 else -0.03
		var foot := MeshInstance3D.new()
		var fm := CylinderMesh.new()
		fm.top_radius = 0.028
		fm.bottom_radius = 0.028
		fm.height = 0.008
		foot.mesh = fm
		foot.scale = Vector3(1.0, 1.0, 1.6)
		foot.position = at + Vector3(cos(heading + PI * 0.5), 0.0, sin(heading + PI * 0.5)) * side
		foot.rotation.y = -heading
		foot.material_override = _glow_mat(Color(0.5, 0.85, 0.75), 0.6)
		add_child(foot)

func _build_dartboard() -> void:
	# the quarter circle: seeded darts, and pi computed from where they landed
	var board := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.7, 0.7, 0.04)
	board.mesh = bm
	board.position = Vector3(-2.0, 1.15, 0.6)
	board.rotation.y = PI * 0.5
	board.material_override = _matte_mat(Color(0.9, 0.88, 0.82), 0.7)
	add_child(board)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var inside := 0
	for i in range(darts):
		var u := r.randf()
		var v := r.randf()
		var hit := u * u + v * v <= 1.0
		if hit:
			inside += 1
		var dart := MeshInstance3D.new()
		var dm := SphereMesh.new()
		dm.radius = 0.011
		dm.height = 0.022
		dart.mesh = dm
		dart.position = Vector3(-1.975, 0.83 + v * 0.62, 0.28 + u * 0.62)
		dart.material_override = _glow_mat(Color(0.2, 0.5, 0.9) if hit else Color(0.85, 0.3, 0.25), 1.1)
		add_child(dart)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.26
	tag.position = Vector3(-1.95, 0.6, 0.6)
	tag.rotation.y = PI * 0.5
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("pi ~ 4 x %d/%d = %.3f" % [inside, darts, 4.0 * float(inside) / float(darts)],
			"measured by throwing - Monte Carlo")

func _build_markov_wheel() -> void:
	# sun / cloud / rain, ribbons thick by transition probability: memory of one step
	var states := [["sun", Color(0.95, 0.8, 0.3)], ["cloud", Color(0.7, 0.72, 0.78)], ["rain", Color(0.35, 0.55, 0.9)]]
	var centers: Array = []
	for i in range(3):
		var ang := TAU * float(i) / 3.0 - PI * 0.5
		var at := Vector3(2.0 + cos(ang) * 0.32, 1.25 + sin(ang) * 0.32, 0.6)
		centers.append(at)
		var orb := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = 0.07
		sm.height = 0.14
		orb.mesh = sm
		orb.position = at
		orb.material_override = _glow_mat(states[i][1], 1.3)
		add_child(orb)
	var thick := [[0.55, 0.3, 0.15], [0.25, 0.5, 0.25], [0.1, 0.45, 0.45]]
	for i in range(3):
		for j in range(3):
			if i == j:
				continue
			var a: Vector3 = centers[i]
			var b: Vector3 = centers[j]
			var rib := MeshInstance3D.new()
			var rm := CylinderMesh.new()
			var w: float = 0.004 + 0.02 * thick[i][j]
			rm.top_radius = w
			rm.bottom_radius = w
			rm.height = a.distance_to(b) * 0.8
			rib.mesh = rm
			rib.position = (a + b) * 0.5 + Vector3(0.0, 0.0, -0.03 * float(i - j))
			var dir := (b - a).normalized()
			var axis := Vector3.UP.cross(dir)
			if axis.length() > 0.001:
				rib.rotate(axis.normalized(), acos(clampf(Vector3.UP.dot(dir), -1.0, 1.0)))
			rib.material_override = _glow_mat(states[i][1], 0.5)
			add_child(rib)

func _build_urns() -> void:
	# two urns of 12 marbles: sorted (H = 0) and mixed (H computed) - entropy in bits
	for u in range(2):
		var cx := 0.75 + 0.6 * float(u)
		var urn := MeshInstance3D.new()
		var um := CylinderMesh.new()
		um.top_radius = 0.16
		um.bottom_radius = 0.12
		um.height = 0.3
		urn.mesh = um
		urn.position = Vector3(cx, 0.28, 1.05)
		urn.material_override = _matte_mat(Color(0.2, 0.2, 0.24), 0.7)
		add_child(urn)
		var r := RandomNumberGenerator.new()
		r.seed = seed + u
		var counts := {}
		for k in range(12):
			var hue: float
			if u == 0:
				hue = 0.6
			else:
				hue = [0.0, 0.15, 0.35, 0.6][r.randi_range(0, 3)]
			counts[hue] = counts.get(hue, 0) + 1
			var marble := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.028
			sm.height = 0.056
			marble.mesh = sm
			marble.position = Vector3(cx + r.randf_range(-0.08, 0.08), 0.46 + 0.05 * float(k / 4), 1.05 + r.randf_range(-0.08, 0.08))
			marble.material_override = _glow_mat(Color.from_hsv(hue, 0.75, 0.9), 0.9)
			add_child(marble)
		var H := 0.0
		for hue in counts:
			var pr: float = float(counts[hue]) / 12.0
			H -= pr * log(pr) / log(2.0)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.18
		tag.position = Vector3(cx, 0.14, 1.42)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text("H = %.2f bits" % H, "sorted" if u == 0 else "mixed")

func _build_starfields() -> void:
	# the ceiling: white noise clumps, blue noise breathes evenly
	for field in range(2):
		var cx := -0.75 + 1.5 * float(field)
		var panel := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(1.3, 0.03, 0.9)
		panel.mesh = pm
		panel.position = Vector3(cx, 2.35, 0.0)
		panel.material_override = _matte_mat(Color(0.05, 0.05, 0.09), 0.95)
		add_child(panel)
		var r := RandomNumberGenerator.new()
		r.seed = seed
		var placed: Array = []
		var tries := 0
		while placed.size() < 26 and tries < 800:
			tries += 1
			var p := Vector3(cx + r.randf_range(-0.6, 0.6), 2.32, r.randf_range(-0.4, 0.4))
			if field == 1:
				var ok := true
				for q in placed:
					if p.distance_to(q) < 0.14:
						ok = false
						break
				if not ok:
					continue
			placed.append(p)
			var star := MeshInstance3D.new()
			var sm := SphereMesh.new()
			sm.radius = 0.014
			sm.height = 0.028
			star.mesh = sm
			star.position = p
			star.material_override = _glow_mat(Color(0.95, 0.95, 0.85), 1.6)
			add_child(star)
		var tag := TextScreenScript.new()
		tag.mode = 2
		tag.width_m = 0.16
		tag.position = Vector3(cx, 2.3, 0.55)
		add_child(tag)
		if tag.has_method("set_text"):
			tag.set_text("white" if field == 0 else "blue", "clumps" if field == 0 else "evenly spaced chance")

func _build_ten_print() -> void:
	# the entrance runner: one seeded coin per cell, / or \
	var r := RandomNumberGenerator.new()
	r.seed = seed
	for row in range(4):
		for col in range(14):
			var slash := MeshInstance3D.new()
			var sm := BoxMesh.new()
			sm.size = Vector3(0.11, 0.008, 0.02)
			slash.mesh = sm
			slash.position = Vector3(-0.91 + 0.14 * float(col), 0.125, 1.05 + 0.14 * float(row) * 0.5 - 0.6 - 0.9)
			slash.rotation.y = PI * 0.25 if r.randf() < 0.5 else -PI * 0.25
			slash.material_override = _glow_mat(Color(0.55, 0.85, 0.65), 0.7)
			add_child(slash)

func _build_genome() -> void:
	# the deep end: a genome ribbon and the small body it becomes
	var plinth := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.5, 0.7, 0.4)
	plinth.mesh = pm
	plinth.position = Vector3(2.05, 0.35, -0.35)
	plinth.material_override = _matte_mat(Color(0.12, 0.12, 0.14), 0.9)
	add_child(plinth)
	var r := RandomNumberGenerator.new()
	r.seed = seed
	for k in range(10):
		var bead := MeshInstance3D.new()
		var sm := BoxMesh.new()
		sm.size = Vector3(0.035, 0.035, 0.035)
		bead.mesh = sm
		bead.position = Vector3(1.9, 0.76 + 0.045 * float(k), -0.42 + 0.03 * sin(float(k) * 1.2))
		bead.rotation.y = float(k) * 0.5
		bead.material_override = _glow_mat(Color.from_hsv([0.0, 0.3, 0.6, 0.13][r.randi_range(0, 3)], 0.8, 0.9), 0.9)
		add_child(bead)
	# the body the ribbon becomes: a tiny seeded critter silhouette
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.05 + r.randf_range(0.0, 0.03)
	bm.height = 0.16 + r.randf_range(0.0, 0.08)
	body.mesh = bm
	body.position = Vector3(2.2, 0.82, -0.28)
	body.rotation.z = PI * 0.5
	body.material_override = _matte_mat(Color.from_hsv(r.randf(), 0.6, 0.8), 0.6)
	add_child(body)
	for leg in range(r.randi_range(2, 4)):
		var l := MeshInstance3D.new()
		var lm := CylinderMesh.new()
		lm.top_radius = 0.008
		lm.bottom_radius = 0.008
		lm.height = 0.08
		l.mesh = lm
		l.position = Vector3(2.14 + 0.05 * float(leg), 0.74, -0.28)
		l.material_override = _matte_mat(Color(0.2, 0.2, 0.22), 0.8)
		add_child(l)
	var tag := TextScreenScript.new()
	tag.mode = 2
	tag.width_m = 0.2
	tag.position = Vector3(2.05, 0.14, -0.05)
	add_child(tag)
	if tag.has_method("set_text"):
		tag.set_text("the deep end", "a seed that becomes a body")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "CasinoPlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.25, 0.24, 1.35)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("REPLAY CASINO",
			"The engine's chance is a book, not a storm: every accident here was drawn\nfrom seed %d and returns identically forever. Twin dice piles agree; the\nGalton bins hold their bell; the darts announce the pi they measured; the\nurns wear their entropy in bits. Determinism, wearing chance as a costume." % seed)
