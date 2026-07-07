extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name ThrownnessChalkboard

# @identity
# essence: a chalkboard for THROWNNESS — Heidegger's Geworfenheit, hand-chalked: a figure dropped along an arrow into a bounded grid it did not choose, beside the concept's words. You wake already in a world, at coordinates not of your choosing, among things already meaning something. Made literal by Ada: the player is thrown into the lab at a spawn point they did not pick, into a grid already built.
# desire: it wants the player to recognise their own arrival in the diagram — to see that "thrown into the grid" is not just a game mechanic but the structure of being anywhere at all. It wants the arrow to feel like a fall you didn't authorise, and the grid to feel like a world that was already here.
# critical_parameter: lines + diagram="thrown". The arrow-into-the-box shows Geworfenheit; the lines name it (thrown into a world, not chosen, already meaning). The grid lines inside the box tie it to Ada's own grid.
# triggers: _ready (inherited) builds the board; diagram="thrown" draws the throw-arrow landing a "you" dot in the grid.
# emerges: the theory register for the player's condition — the board that names what the spawn point already does to them. Where qfep states the principle and endlessness states the unbounded, this states the SITUATION: you are here, thrown, and the here was not your decision.
# needs: a bounded world/grid [present]; an arrow from outside [present]; the landed "you" dot [present]; the concept's words [present]
# relationships: companion to the primitives spawn / "you are here" decal (the indexical here) and the lab_room (the world you are thrown into); sibling to qfep_chalkboard and endlessness_chalkboard; built on chalkboard.gd + scribble_control.gd; the most directly Heideggerian object in the project.
# truth: Geworfenheit — thrownness. You do not begin at a neutral origin and then choose a world; you wake already IN one, at a place, in a time, among things already laden with meaning, none of it authorised by you. Dasein is being-thrown. Ada makes it literal: spawn is a throw. The grid was here before you. You are here — and "here" was not your decision. The board names the condition of being anywhere.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "thrown"
	if not has_meta("config_board_width"):
		board_width = 2.0
	if not has_meta("config_lines"):
		lines = PackedStringArray([
			"Geworfenheit",
			"thrown into a world",
			"not chosen, already here",
			"spawn = a throw",
			"you are here",
		])
	super._ready()
