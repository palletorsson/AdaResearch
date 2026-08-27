extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TheBelievingTurtle

## @identity
## lineage: the L-systems SUPER OBJECT — a scriptorium where one sentence becomes
##   three plants. On the lectern, the alphabet: five brass glyphs (F + - [ ]) that
##   mean nothing at all. Beside it the rule board, axiom and productions, and a
##   generation ladder showing the string exploding 1 -> 5 -> 21 -> 89 symbols. Then
##   the argument: THREE turtles read the SAME final string and each believes it
##   differently — 25 degrees, 45 degrees, and one that reads F as a step sideways —
##   growing three unmistakably different plants from one identical sentence. A stack
##   of brass plates beside the bracketed one rises and falls as the turtle pushes and
##   pops, because branching is a stack. And at the end, a stochastic pair: the same
##   rules, two seeds, two siblings that are family but not twins.
## essence: the engine ships nothing for this. A string that rewrites itself is half;
##   a reader that believes it is the other half — and they are INDEPENDENT. Every
##   plant here was rewritten and walked at build time, symbol by symbol.
## truth: a sentence can become a forest. Grammar is generative — and interpretation
##   is a second, separable decision.
##
## The 2026-08-27 super-object pass (Palle: "make one super object for each").

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export var seed: int = 7
@export_range(2, 5) var generations: int = 4
@export var axiom: String = "F"
## The production: F becomes this, every symbol rewritten AT ONCE, each generation.
@export var rule_f: String = "FF+[+F-F-F]-[-F+F+F]"

var _final := ""

func _ready() -> void:
	_rng.seed = seed
	_final = _rewrite(axiom, rule_f, generations)
	_build_lectern()
	_build_alphabet()
	_build_rule_board()
	_build_generation_ladder()
	_build_three_turtles()
	_build_stack_plates()
	_build_stochastic_pair()
	_build_plaque()

func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["seed", "generations", "axiom", "rule_f"]:
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

# --- the string half --------------------------------------------------------------------

## PARALLEL REWRITING: every symbol replaced at once, generation after generation.
func _rewrite(start: String, production: String, gens: int) -> String:
	var s := start
	for g in range(gens):
		var out := ""
		for i in range(s.length()):
			var ch := s[i]
			out += production if ch == "F" else ch
		s = out
	return s

func _build_lectern() -> void:
	_slab(Vector3(-1.9, 0.5, 0.0), Vector3(0.9, 1.0, 0.6), Color(0.14, 0.11, 0.09))
	_slab(Vector3(-1.9, 1.03, 0.0), Vector3(0.85, 0.05, 0.55), Color(0.3, 0.22, 0.14))

func _build_alphabet() -> void:
	# five glyphs that mean NOTHING yet — the marks before any reader
	var glyphs := ["F", "+", "-", "[", "]"]
	for i in range(5):
		var at := Vector3(-2.22 + 0.16 * float(i), 1.09, -0.12)
		_slab(at, Vector3(0.11, 0.02, 0.11), Color(0.75, 0.68, 0.45), 0.4)
		_tag(at + Vector3(0.0, 0.01, 0.14), glyphs[i], "")
	_tag(Vector3(-1.9, 1.06, 0.3), "the alphabet", "marks nobody has interpreted yet")

func _build_rule_board() -> void:
	var board := Vector3(-1.9, 1.55, -0.2)
	_slab(board, Vector3(0.8, 0.5, 0.03), Color(0.12, 0.12, 0.15))
	_tag(board + Vector3(0.0, 0.12, 0.03), "axiom: %s" % axiom, "")
	_tag(board + Vector3(0.0, -0.06, 0.03), "F -> %s" % rule_f.substr(0, 16), "every F, replaced at once")

func _build_generation_ladder() -> void:
	# the string exploding: bar per generation, length = symbol count
	var s := axiom
	for g in range(generations + 1):
		var n := s.length()
		var w: float = clampf(float(n) / 320.0, 0.02, 1.1)
		_slab(Vector3(-1.0 + w * 0.5, 1.35 - 0.11 * float(g), 0.35), Vector3(w, 0.045, 0.05),
			Color.from_hsv(0.32 - 0.05 * float(g), 0.6, 0.9), 0.6)
		_tag(Vector3(-1.12, 1.35 - 0.11 * float(g), 0.42), str(n), "")
		if g < generations:
			s = _rewrite(s, rule_f, 1)
	_tag(Vector3(-0.65, 1.5, 0.42), "generations", "1 symbol, then 5, then 21, then 89...")

# --- the reader half: three turtles, one string ------------------------------------------

## THE SECOND HALF. Walk `_final` as a turtle and draw it. `angle` and `side` are the
## reader's beliefs; the string is identical in all three cases.
func _walk(origin: Vector3, angle_deg: float, step: float, tint: Color, sideways: bool) -> void:
	var stack: Array = []
	var pos := origin
	var heading := PI * 0.5              # up
	var ang := deg_to_rad(angle_deg)
	var drawn := 0
	for i in range(_final.length()):
		if drawn > 260:
			break
		var ch := _final[i]
		match ch:
			"F":
				var dir := Vector2(cos(heading), sin(heading))
				if sideways:
					dir = Vector2(dir.y, dir.x)   # this turtle believes F means "sidle"
				var nxt := pos + Vector3(dir.x, dir.y, 0.0) * step
				var seg := MeshInstance3D.new()
				var sm := CylinderMesh.new()
				sm.top_radius = 0.006
				sm.bottom_radius = 0.006
				sm.height = step
				seg.mesh = sm
				seg.position = (pos + nxt) * 0.5
				seg.rotation.z = atan2(nxt.y - pos.y, nxt.x - pos.x) - PI * 0.5
				seg.material_override = _glow_mat(tint, 0.8)
				add_child(seg)
				pos = nxt
				drawn += 1
			"+":
				heading += ang
			"-":
				heading -= ang
			"[":
				stack.append([pos, heading])          # PUSH
			"]":
				if not stack.is_empty():
					var st: Array = stack.pop_back()  # POP
					pos = st[0]
					heading = st[1]

func _build_three_turtles() -> void:
	_walk(Vector3(-0.55, 1.0, 0.0), 25.0, 0.055, Color(0.45, 0.85, 0.5), false)
	_tag(Vector3(-0.55, 0.94, 0.2), "25 degrees", "same sentence")
	_walk(Vector3(0.35, 1.0, 0.0), 45.0, 0.05, Color(0.95, 0.7, 0.3), false)
	_tag(Vector3(0.35, 0.94, 0.2), "45 degrees", "same sentence")
	_walk(Vector3(1.25, 1.0, 0.0), 25.0, 0.05, Color(0.5, 0.7, 0.95), true)
	_tag(Vector3(1.25, 0.94, 0.2), "F means sidle", "same sentence, a different reader")
	_tag(Vector3(0.35, 0.86, 0.5), "the two halves", "the string knows no geometry")

func _build_stack_plates() -> void:
	# the bracket made physical: a column of plates, one per open bracket depth
	var depth := 0
	var peak := 0
	for i in range(_final.length()):
		var ch := _final[i]
		if ch == "[":
			depth += 1
			peak = maxi(peak, depth)
		elif ch == "]":
			depth = maxi(depth - 1, 0)
	for k in range(peak):
		_slab(Vector3(2.05, 1.02 + 0.07 * float(k), 0.0), Vector3(0.22 - 0.02 * float(k), 0.035, 0.22 - 0.02 * float(k)),
			Color(0.55, 0.46, 0.28), 0.5)
	_tag(Vector3(2.05, 0.94, 0.2), "the stack", "[ pushes, ] pops - branching IS a stack (depth %d)" % peak)

func _build_stochastic_pair() -> void:
	# same rules, two seeds: family, not twins
	for i in range(2):
		var r := RandomNumberGenerator.new()
		r.seed = seed + i
		var s := "F"
		for g in range(3):
			var out := ""
			for k in range(s.length()):
				var ch := s[k]
				if ch == "F":
					out += "F[+F]F[-F]F" if r.randf() < 0.5 else "F[-F][+F]F"
				else:
					out += ch
			s = out
		var pos := Vector3(-1.35 + 0.55 * float(i), 0.12, 0.55)
		var stack: Array = []
		var heading := PI * 0.5
		var drawn := 0
		for k in range(s.length()):
			if drawn > 90:
				break
			var ch := s[k]
			match ch:
				"F":
					var nxt := pos + Vector3(cos(heading), sin(heading), 0.0) * 0.038
					var seg := MeshInstance3D.new()
					var sm := CylinderMesh.new()
					sm.top_radius = 0.005
					sm.bottom_radius = 0.005
					sm.height = 0.038
					seg.mesh = sm
					seg.position = (pos + nxt) * 0.5
					seg.rotation.z = atan2(nxt.y - pos.y, nxt.x - pos.x) - PI * 0.5
					seg.material_override = _glow_mat(Color(0.75, 0.55, 0.85), 0.7)
					add_child(seg)
					pos = nxt
					drawn += 1
				"+":
					heading += deg_to_rad(28.0)
				"-":
					heading -= deg_to_rad(28.0)
				"[":
					stack.append([pos, heading])
				"]":
					if not stack.is_empty():
						var st: Array = stack.pop_back()
						pos = st[0]
						heading = st[1]
	_tag(Vector3(-1.08, 0.08, 0.78), "stochastic", "same rules, two seeds: family, not twins")

func _build_plaque() -> void:
	var ts := TextScreenScript.new()
	ts.name = "TurtlePlate"
	ts.mode = 2
	ts.width_m = 0.44
	ts.position = Vector3(-2.5, 0.24, 0.75)
	ts.rotation.y = deg_to_rad(38.0)
	add_child(ts)
	if ts.has_method("set_text"):
		ts.set_text("THE BELIEVING TURTLE",
			"The engine ships nothing for this. Half is a string that rewrites itself -\nfive glyphs, one rule, %d symbols by generation %d. The other half is a reader,\nand they are INDEPENDENT: three turtles believe the SAME sentence at 25 degrees,\n45 degrees, and sideways, and grow three different plants. The brass column is\nthe bracket stack, because branching is a data structure." % [_final.length(), generations])
