extends Node3D

# @identity
# essence: the presentation rig around a mirrored CA — SubViewport -> ViewportTexture -> a flat
#   plate on the floor, with the automaton itself living one level down inside the viewport
# desire: to stand over a living mandala on the floor and see that it is a rule, not a picture
# critical_parameter: stencil — how much of the field is actually DRAWN before the mirror copies
#   the rest (a quarter, an eighth, a 5x5 motif, or all of it)
# triggers: stencil is forwarded to the automaton in _enter_tree, before its _ready lays the field
# emerges: a mandala nobody designed — and, at stencil:none, the same rules with no mandala at all
# needs: the automaton instance under SubViewport [has]; VR stencil selector [missing]
# relationships: the wrapper for [[mirrored_cellular_automata]]; contrasts persian_rug (a symmetry
#   that was drawn) with this one (a symmetry that was ENFORCED after the fact)
# truth: the mandala is not emergent. A fragment is computed and the rest is copied — and this
#   artifact will tell you exactly how big the fragment was.

# ── DNA ───────────────────────────────────────────────────────────────────────
# THE AXIS — how much of this pattern was actually drawn, and how much was copied.
#
# The automaton's own identity says "symmetry is not decoration — it is a second rule system
# layered on the first". Read the code and that second rule system turns out to be a copier:
# generate_quadrant_pattern draws over a quarter of the grid and stamps it four times;
# generate_octant_pattern draws over a triangle one eighth the size and stamps it eight times;
# generate_rotational_pattern draws a 5x5 motif — twenty-five cells — and tiles it across ten
# thousand. The mandala is not emergent. A stencil is cut, and the rest is repetition.
#
# So the axis is the stencil, named for the size of the piece that was really drawn:
#
#   motif     the legacy lineage, byte for byte (the scene has always set symmetry_type = 2).
#             25 cells, tiled 400 times: a crisp, regular, wallpaper-fine weave, every 5x5
#             patch identical to every other.
#   quadrant  2,500 cells drawn, mirrored into four. A speckled field with two clean axes of
#             reflection through the centre — obviously symmetric, obviously not repetitive.
#   octant    1,250 cells drawn, mirrored into eight. The same speckle folded twice more; the
#             diagonals become mirror lines too and the figure reads as a snowflake.
#   none      all 10,000 cells drawn, nothing copied. The stochastic rule with the second rule
#             system REMOVED: an even grey static with no centre and no axis. This is the
#             control, and it is what the artifact is arguing against.
#
# VISIBLE IN A STILL — and only just, so read the framing note. The wrapper instance sets
# update_interval = 5.0, so at a ~1.2 s capture the automaton has evolved ZERO generations and
# the frame shows the initial lay exactly. That is the honest subject: every value of this axis
# is a different initial condition, and the still holds initial conditions perfectly.
#
# WHAT IS NOT THE AXIS. update_interval and auto_evolve are the tempo of the thing and a still
# cannot hold tempo. random_fill_percent is a density dial — five tiles of the same field at
# five loudnesses. Neither is a claim.
const STENCILS: PackedStringArray = ["motif", "quadrant", "octant", "none"]

## The word -> symmetry_type table. The automaton keeps the int enum it always had; this
## wrapper owns the vocabulary, so there is exactly ONE place a stencil name is spelled.
const STENCIL_MODES := {
	"quadrant": 0,   # draw a quarter, mirror into four
	"octant": 1,     # draw an eighth, mirror into eight
	"motif": 2,      # draw 5x5, tile the whole grid          <- legacy default
	"none": 3,       # draw everything, copy nothing
}

@export_enum("motif", "quadrant", "octant", "none") var stencil: String = "motif"

## Seed for the automaton's fill draws, forwarded straight through. -1 keeps the legacy
## behaviour (randomize() per build). The sweep MUST pin this: without it, four stencils are
## laid from four different random fields and the critic reports the difference between random
## draws as the bite of the axis — a confident number about nothing.
@export var pattern_seed: int = -1

## Path to the automaton inside the SubViewport, as the scene names it.
const AUTOMATON_PATH := "SubViewport/MirroredCellularAutomata"


## _enter_tree, NOT _ready. Godot notifies ENTER_TREE top-down over the whole subtree before it
## notifies READY bottom-up, so this is the last moment at which the automaton one level down
## can still be configured BEFORE its own _ready() lays the field. Forwarding from _ready()
## would arrive one notification too late and every variant would render the default.
func _enter_tree() -> void:
	_forward()


func _forward() -> void:
	var ca: Node = get_node_or_null(AUTOMATON_PATH)
	if ca == null:
		return
	ca.set("symmetry_type", int(STENCIL_MODES.get(stencil, 2)))
	ca.set("pattern_seed", pattern_seed)


## A map may set #stencil: and #pattern_seed:. GUARDED — a config carrying neither key returns
## before touching anything, so a placement that only wanted a rotation does not re-lay ten
## thousand cells.
func apply_grid_config(config: Dictionary) -> void:
	var before_stencil: String = stencil
	var before_seed: int = pattern_seed
	if config.has("stencil"):
		stencil = _pick_axis(str(config["stencil"]), STENCILS, stencil)
	if config.has("pattern_seed"):
		pattern_seed = int(config["pattern_seed"])
	if stencil == before_stencil and pattern_seed == before_seed:
		return
	_forward()
	var ca: Node = get_node_or_null(AUTOMATON_PATH)
	if ca != null and ca.has_method("regenerate_pattern"):
		ca.call("regenerate_pattern")


## An unreadable token resolves to the value already in place rather than to silence — a typo
## must not quietly blank a floor that rooms expect to be patterned.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback
