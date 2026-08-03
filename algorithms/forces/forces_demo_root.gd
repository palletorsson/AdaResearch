extends Node3D
class_name ForcesDemoRoot

# @identity
# essence: A two-line letterbox on the door of a NOC forces scene — it takes the config a map
#   or the sweep hands to the scene ROOT and puts it where the demo script can actually find it
# desire: to end the family's structural deafness; the demos have exports, the callers have
#   values, and until now nothing carried one to the other
# critical_parameter: none — this node has no appearance, no _ready, and no behaviour of its own.
#   Handed an empty dictionary it does exactly nothing, which is what every existing placement hands it
# triggers: apply_grid_config() from GridInteractablesComponent (deferred, after the tree) or from
#   capture_artifact_config.gd (immediate, BEFORE the tree)
# emerges: the same #key:value token now reaches the demo by both routes, so an axis declared on a
#   NOC forces example can be photographed as well as placed
# relationships: attached to the ROOT of the example_2_x_*.tscn scenes; the demo script sits two
#   levels down under [[fish_tank]] and reads what this leaves behind
# truth: a scene shaped root -> FishTank -> Demo puts its brain in the grandchild and its ears on
#   the root. The message was never wrong; there was simply no one at the door.

# ═══════════════════════════════════════════════════════════════════════════
# WHY THIS EXISTS
#
# The whole NOC forces family is shaped
#
#     [Example_2_x]           <- unscripted Node3D, the ROOT
#       └── FishTank          <- fish_tank.gd
#             └── Demo        <- the script with the exports and the axis
#
# Both callers address the ROOT and only the root:
#
#   * commons/grid/GridInteractablesComponent.gd:1615 — set_meta("config_<key>") on the
#     artifact object, then call_deferred("apply_grid_config", …) on it.
#   * commons/testing/capture_artifact_config.gd:107 — art.apply_grid_config(dna) on the
#     instantiated root, immediately, BEFORE the scene enters the tree.
#
# The root had no script, so the second call found no method and evaporated. The first left
# metadata on the root, which a demo could walk up and read — the route example_2_5 documents.
# This node makes both routes land in the same place: metadata on the root, read in _ready.
#
# STRICTLY ADDITIVE. There is no _ready, no _process and no geometry here. A placement that
# passes no config gets a node that does literally nothing.
# ═══════════════════════════════════════════════════════════════════════════


## Take a config dictionary aimed at the scene root and leave it where the demo will look.
##
## Order matters and is the reason this is safe. The sweep calls this BEFORE the scene enters
## the tree, so the demo's _ready() has not run: writing metadata now means the demo's
## _read_grid_config_meta() picks it up on the way in and builds once, correctly. The grid calls
## it AFTER (call_deferred), by which time the demo is already built — so in that case, and only
## that case, the value is also pushed down for a live rebuild.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return

	for key in config.keys():
		var sanitized: String = str(key).replace(":", "_").replace(",", "_").replace(" ", "_").replace("-", "_")
		if not sanitized.is_valid_identifier():
			continue
		set_meta("config_%s" % sanitized, config[key])

	# Before the tree, the demo has not built yet and will read the metadata above on its own.
	# Pushing down here as well would ask a half-constructed node to rebuild itself.
	if not is_inside_tree():
		return

	for node in _descendants():
		if node.has_method("apply_grid_config"):
			node.apply_grid_config(config.duplicate(true))


## Every node under this one, self excluded. Small scenes; a plain walk is enough.
func _descendants() -> Array[Node]:
	var out: Array[Node] = []
	var stack: Array[Node] = []
	stack.append_array(get_children())
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		out.append(n)
		stack.append_array(n.get_children())
	return out
