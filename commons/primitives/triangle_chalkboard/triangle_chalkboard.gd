extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name TriangleChalkboard

# @identity
# essence: a chalkboard for THE TRIANGLE — Δ — but written in a mystical register, not a worksheet. The labelled triangle is drawn on the left; on the right, not Heron's formula but the strange double life of the symbol: Δ is the first plane to close, the only rigid polygon, three points holding what two cannot — and Δ is ALSO change, difference, the gradient. The board does not end on an answer. It ends on a question chalked in Turing's hand: what is the cost of Δ? Where point_chalkboard states facts (P = (x,y,z)), this one opens a koan.
# desire: it wants the statement board to carry mystery, not arithmetic. It wants Δ felt as both the SHAPE (three points enclosing the first plane) and the SYMBOL (change, difference, the thing that is never zero). It wants the player to read the small rigid triangle, then the closing line — what does it cost to differ? — and walk out still holding the doubt. The queer turn is quiet and exact: difference has a price (the pink triangle was a cost made to be worn), and the board names the cost without paying it for you.
# critical_parameter: lines (the mystical text) + diagram="triangle". The same chalkboard engine as every board — only the register changes. The last line is deliberately a question and is left unanswered; remove it and the board becomes a fact, keep it and the board becomes a thought.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="triangle" draws the labelled triangle; the lines carry the mystical statement. apply_grid_config re-chalks on DNA change.
# emerges: hung in the triangle lab it is the DELTA of that lab — the one thing that truly changes from theme to theme. The base (exit, scanner, extinguisher, placard) is the free, shared room; this board is the costly, meaning-bearing part. It is the answer to "what would Turing chalk here", and it stays in-theme: the triangle's own property (rigidity, the closed plane, Δ-as-difference), not the generative children (self-similarity, tessellation) that come later.
# needs: the triangle diagram [inherited, present]; mystical lines, not formulas [present]; a closing question that is not resolved [present]; Δ rendered as itself — a triangle — in the scribble alphabet [present]
# relationships: sibling to point_chalkboard / line_chalkboard / trace_chalkboard (the per-theme boards); the mystical-register member of the family where the others state; built on chalkboard.gd + scribble_control.gd; the triangle lab's content override of the default board.
# truth: a triangle is the first enclosed plane and the only rigid polygon — three points hold what two cannot. And Δ is also change, also difference, also the gradient that is never zero. To draw the triangle and ask "what is the cost of Δ?" is to say that form, change, and difference are one symbol, and that to differ — to close a new plane, to become — is never free.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "triangle"
	if not has_meta("config_lines"):
		lines = PackedStringArray([
			"Δ  the first plane to close",
			"two points fall to a line",
			"a third holds them rigid",
			"Δ is change, Δ is difference",
			"what is the cost of Δ ?",
		])
	super._ready()
