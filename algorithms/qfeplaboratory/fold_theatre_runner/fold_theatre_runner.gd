# FoldTheatreRunner.gd
# F-edge first cycle — a GridSubstrateRunner subclass with all four channels
# enabled by default and pre-configured for the Fold_Theatre map.
#
# Each channel:
#   - Visibility cycles rule_30 -> sierpinski -> menger_sponge (the F-edge
#     fold vocabulary). PATH_GUARANTEE keeps spawn-to-teleporter walkable.
#   - Glyph runs subdivide_by_attention (apparatus-as-phenomenon: detail
#     arrives where the player looks).
#   - Part tags cubes via flower_grammar (concentric anatomy: pistil /
#     stamens / petals / sepals).
#   - Color-by-role paints each role its palette colour after every
#     visibility cycle, so the player sees flower-anatomy under whichever
#     CA pattern is currently active.
#
# @identity
# essence: GridSubstrateRunner with the F-edge presets baked in
# desire: to be the first-cycle proof — same map, three foldings of the
#   same algorithm, the same body walking through, the floor staying
#   walkable, the floor becoming flower-anatomy under each fold
# critical_parameter: the grammar choice (flower vs insect vs bird)
# triggers: _init sets exports before _ready runs; super._ready mounts
#   all four channels via the parent runner
# emerges: a Codex-page floor that re-folds itself; a Haeckel plate
#   the player walks across
# needs: GridSubstrateRunner [✓]; all four channels in commons/grid/mutators/ [✓]
# relationships: extends GridSubstrateRunner; placed in Fold_Theatre map
#   only; future Fold_X variants can subclass with different grammars
# truth: a recipe is a Runner with defaults

extends "res://commons/grid/mutators/grid_substrate_runner.gd"
class_name FoldTheatreRunner


func _init() -> void:
	# Override parent defaults BEFORE _ready fires.

	# Visibility — the fold vocabulary.
	enable_visibility = true
	visibility_expressions = ["rule_30", "sierpinski", "menger_sponge"]
	visibility_cycle_seconds = 6.0
	enable_3d_expressions = true  # menger_sponge needs the 3D registry
	floor_plan_mode = 4  # PATH_GUARANTEE — walkability under every pattern
	floor_plan_layers = 2

	# Glyph — apparatus-as-phenomenon.
	enable_glyph = true
	glyph_policy = "subdivide_by_attention"
	glyph_max_subdivided_cells = 80
	glyph_viewer_radius = 4.5
	glyph_cycle_seconds = 9.0

	# Part — flower-grammar.
	enable_part = true
	part_grammar = "flower_grammar"

	# Colour-by-role — flower palette painted on the floor.
	enable_color_by_role = true
	enable_color = false  # we paint by role, not by palette-cycle
	color_by_role_palette = {
		"pistil": Color(1.0, 0.85, 0.2),
		"stamen": Color(0.95, 0.55, 0.85),
		"petal":  Color(0.65, 0.2, 0.5),
		"sepal":  Color(0.35, 0.6, 0.35),
	}
