extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name EndlessnessChalkboard

# @identity
# essence: a chalkboard for ENDLESSNESS — the two infinities, hand-chalked: the potential infinite (a process that never stops: 1, 2, 3, → ∞) drawn as an inward spiral that never closes, and the actual infinite (a completed totality) named beside it. Aristotle's distinction, Cantor's cardinals, the limit that is approached but never reached. The concept the wavefunction and fractal sequences keep circling.
# desire: it wants to make infinity a thing you can stand in front of without it collapsing into a number. It wants the spiral to keep turning — the eye following it inward, never arriving — so the player FEELS the difference between counting forever and holding the whole. It wants endlessness to be vertiginous and calm at once.
# critical_parameter: lines + diagram="spiral". The spiral shows the potential infinite (process); the lines name the distinction (potential vs actual, the limit, ℵ).
# triggers: _ready (inherited) builds the board; diagram="spiral" draws the never-closing spiral with an ∞ label.
# emerges: the theory register for the project's recurring encounter with the unbounded — fractals, limits, the horizon, entropy's heat death, the QFEP complexity cost going to infinity. The board that names what the world keeps gesturing at.
# needs: the never-closing spiral [present]; the ∞ symbol [present]; the potential/actual distinction [present]; the limit [present]
# relationships: companion to the fractals, wavefunctions, and foundations-crisis sequences; sibling to qfep_chalkboard and thrownness_chalkboard (the three theory boards); built on chalkboard.gd + scribble_control.gd.
# truth: there are two infinities. The POTENTIAL infinite is a process with no last step — you can always add one (1, 2, 3, →∞). The ACTUAL infinite is the completed whole, the set itself, ℵ. A limit is approached, never reached; reaching it would end the endlessness. The spiral turns inward forever and never closes. The board holds the unbounded still enough to look at.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "spiral"
	if not has_meta("config_board_width"):
		board_width = 2.0
	if not has_meta("config_lines"):
		lines = PackedStringArray([
			"potential ∞",
			"1, 2, 3, → ∞",
			"actual ∞ = the whole",
			"limit: approached,",
			"never reached",
		])
	super._ready()
