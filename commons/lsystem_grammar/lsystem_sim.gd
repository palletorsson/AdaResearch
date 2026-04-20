# lsystem_sim.gd — L-system string rewriter.
# The DNA of every L-system artifact: axiom + production rules + iterations.
#
# Supports:
#   - Deterministic rules: "F" -> "F[+F]F[-F]F"
#   - Stochastic rules:    "F" -> [["F[+F]", 0.4], ["F[-F]", 0.4], ["FF", 0.2]]
#   - Any single-char symbol — interpretation is left to the turtle/renderer
#
# This module ONLY does string rewriting. Interpretation (turtle, graph,
# softbody topology, primitive placement) is deferred to lsystem_turtle.gd
# and the downstream substrates it can feed into.
#
# Why separate the rewriter from the interpreter?
# Because the same string can be DNA for multiple substrates — a single
# L-system expansion can render as lines (classical), tubes (mesh grammar),
# primitives (primitive stack), spring-mass topology (soft body), or
# a graph (graph grammar). Encoding the work in the DNA connection means
# the rewriter is shared; only the interpretation changes.

extends RefCounted


## Rewrite axiom by applying rules N times. Deterministic.
## rules = { "F": "F[+F]F[-F]F", ... }
static func rewrite(axiom: String, rules: Dictionary, iterations: int,
		max_length: int = 200000) -> String:
	var s := axiom
	for _i in iterations:
		var next := ""
		for c in s:
			if rules.has(c):
				var repl = rules[c]
				if repl is String:
					next += repl
				else:
					next += c
			else:
				next += c
		s = next
		if s.length() > max_length:
			break
	return s


## Stochastic rewrite — rules can be either a string (deterministic) or
## an array of [replacement, weight] pairs. Seed for reproducibility.
static func rewrite_stochastic(axiom: String, rules: Dictionary,
		iterations: int, seed: int = 0, max_length: int = 200000) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var s := axiom
	for _i in iterations:
		var next := ""
		for c in s:
			if rules.has(c):
				var repl = rules[c]
				if repl is String:
					next += repl
				elif repl is Array:
					next += _pick_weighted(repl, rng)
				else:
					next += c
			else:
				next += c
		s = next
		if s.length() > max_length:
			break
	return s


static func _pick_weighted(options: Array, rng: RandomNumberGenerator) -> String:
	# options = [[replacement:String, weight:float], ...]
	var total: float = 0.0
	for o in options:
		total += float(o[1])
	if total <= 0.0:
		return options[0][0]
	var r: float = rng.randf() * total
	var acc: float = 0.0
	for o in options:
		acc += float(o[1])
		if r <= acc:
			return String(o[0])
	return String(options[-1][0])


## Report stats on a rewritten string — useful for DNA fingerprinting.
static func fingerprint(s: String) -> Dictionary:
	var counts := {}
	for c in s:
		counts[c] = int(counts.get(c, 0)) + 1
	return {
		"length": s.length(),
		"symbols": counts,
		"max_depth": _max_bracket_depth(s),
	}


static func _max_bracket_depth(s: String) -> int:
	var d := 0
	var mx := 0
	for c in s:
		if c == "[":
			d += 1
			if d > mx: mx = d
		elif c == "]":
			d -= 1
	return mx
