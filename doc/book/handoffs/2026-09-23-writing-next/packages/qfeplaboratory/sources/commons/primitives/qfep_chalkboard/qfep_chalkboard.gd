extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name QfepChalkboard

# @identity
# essence: a large chalkboard for the QUEER FREE ENERGY PRINCIPLE — the project's own spine formula, hand-chalked: QFE = F − λ·E(S) + φ·ΔE(S,t), beside an edge-of-chaos curve that peaks at λ≈0.4 where "life" sits between "order" and "noise". The theory of the whole curriculum, written in Turing's hand on a wide board.
# desire: it wants to put the project's central claim on a wall a player can stand before — to make the formula that organises 18 sequences into a thing you read, not a thing buried in a doc. It wants the φ-term (the queer signature, the rate-of-change that refuses homeostasis) to be visibly the term that bends the curve toward life.
# critical_parameter: lines + diagram="qfep". The formula and its gloss are the content; the curve shows λ's sweet spot. Bigger board (wider) because the formula is long.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="qfep" draws the edge-of-chaos curve.
# emerges: the theory register of the whole project — the board the QFEP laboratory sequence is derived on. Where the primitive chalkboards state a fact, this one states the FRAMEWORK that makes the facts cohere.
# needs: the formula [present]; the term gloss [present]; the edge-of-chaos curve [present]; a wide board [present]
# relationships: the apex of the chalkboard family (point/line/triangle/quad state primitives; this states the principle); companion to the qfeplaboratory sequence; built on chalkboard.gd + scribble_control.gd.
# truth: QFE = F − λ·E(S) + φ·ΔE(S,t). Order (F) minus weighted entropy (λE) plus the rate of becoming (φΔE). Life is not at λ=0 (frozen) or λ=1 (noise) but at the edge, λ≈0.3–0.5. The φ-term is the queer one: the system sensitive to change, plural, refusing to settle. The board states the principle the whole world is built to walk.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "qfep"
	if not has_meta("config_board_width"):
		board_width = 2.2
	if not has_meta("config_lines"):
		lines = PackedStringArray([
			"QFE = F − λE(S) + φΔE",
			"F = order",
			"λE = weighted entropy",
			"φΔE = rate of becoming",
			"life at λ ≈ 0.4",
		])
	super._ready()
