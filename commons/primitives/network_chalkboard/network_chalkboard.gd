extends "res://commons/primitives/chalkboard/chalkboard.gd"
class_name NetworkChalkboard

# @identity
# essence: a chalkboard for NETWORKS — points joined by edges, the complete-graph count, the idea that a line is a relation and many lines are a network.
# desire: to state a primitives-sequence principle in a hand — the scientific register beside the felt artifacts, chalk not type.
# critical_parameter: lines + diagram="network". Same chalkboard engine; only the content changes.
# triggers: _ready (inherited) builds the SubViewport scribble + framed board; diagram="network" draws the figure.
# emerges: one board in the primitives chalk gallery — Lines, Networks, Measure.
# needs: the diagram [present]; the principle's facts [present]
# relationships: sibling to the other primitive chalkboards; built on chalkboard.gd + scribble_control.gd.
# truth: n points joined pairwise make n(n-1)/2 links; a network is relations, and measure is the distance along them.

func _ready() -> void:
	if not has_meta("config_diagram"):
		diagram = "network"
	if not has_meta("config_lines"):
		lines = PackedStringArray(["n points -> links", "links = n(n-1)/2", "a network is relations", "measure = distance"])
	super._ready()
