class_name LSystem
extends RefCounted

## L-System (Lindenmayer System) Generator
## Chapter 08: Fractals

var axiom: String = "F"
var rules: Dictionary = {}
var current_generation: String = ""
var generation_count: int = 0

func _init(start_axiom: String = "F"):
	axiom = start_axiom
	current_generation = axiom

func add_rule(symbol: String, replacement: String):
	"""Add a production rule"""
	rules[symbol] = replacement

func generate():
	"""Generate next generation"""
	var next_generation = ""

	for i in range(current_generation.length()):
		var char = current_generation[i]
		if rules.has(char):
			next_generation += rules[char]
		else:
			next_generation += char

	current_generation = next_generation
	generation_count += 1

func generate_n(n: int):
	"""Generate n generations"""
	for i in range(n):
		generate()

func get_sentence() -> String:
	"""Get current generation string"""
	return current_generation

func reset():
	"""Reset to axiom"""
	current_generation = axiom
	generation_count = 0

func get_generation() -> int:
	"""Get current generation number"""
	return generation_count

# --- Preset L-Systems ---

static func create_koch_curve() -> LSystem:
	"""Koch curve L-System"""
	var lsys = LSystem.new("F")
	lsys.add_rule("F", "F+F-F-F+F")
	return lsys

static func create_sierpinski_triangle() -> LSystem:
	"""Sierpinski triangle L-System"""
	var lsys = LSystem.new("F-G-G")
	lsys.add_rule("F", "F-G+F+G-F")
	lsys.add_rule("G", "GG")
	return lsys

static func create_dragon_curve() -> LSystem:
	"""Dragon curve L-System"""
	var lsys = LSystem.new("FX")
	lsys.add_rule("X", "X+YF+")
	lsys.add_rule("Y", "-FX-Y")
	return lsys

static func create_plant() -> LSystem:
	"""Simple plant L-System"""
	var lsys = LSystem.new("X")
	lsys.add_rule("X", "F+[[X]-X]-F[-FX]+X")
	lsys.add_rule("F", "FF")
	return lsys

static func create_tree() -> LSystem:
	"""Binary tree L-System"""
	var lsys = LSystem.new("F")
	lsys.add_rule("F", "FF+[+F-F-F]-[-F+F+F]")
	return lsys

static func create_algae() -> LSystem:
	"""Algae growth L-System (Lindenmayer's original)"""
	var lsys = LSystem.new("A")
	lsys.add_rule("A", "AB")
	lsys.add_rule("B", "A")
	return lsys

static func create_fractal_plant() -> LSystem:
	"""Fractal plant with leaves"""
	var lsys = LSystem.new("X")
	lsys.add_rule("X", "F-[[X]+X]+F[+FX]-X")
	lsys.add_rule("F", "FF")
	return lsys

static func create_bush() -> LSystem:
	"""Bushy plant L-System"""
	var lsys = LSystem.new("F")
	lsys.add_rule("F", "F[+F]F[-F]F")
	return lsys

static func create_3d_hilbert() -> LSystem:
	"""3D Hilbert curve"""
	var lsys = LSystem.new("X")
	lsys.add_rule("X", "^<XF^<XFX-F^>>XFX&F+>>XFX-F>X->")
	return lsys

static func create_3d_tree() -> LSystem:
	"""3D branching tree"""
	var lsys = LSystem.new("A")
	lsys.add_rule("A", "[&FL!A]/////'[&FL!A]///////'[&FL!A]")
	lsys.add_rule("F", "S/////F")
	lsys.add_rule("S", "FL")
	lsys.add_rule("L", "['''^^{-f+f+f-|-f+f+f}]")
	return lsys
