extends Node3D

# @identity
# essence: the 3D housing around a Gray-Scott field — the reaction runs one level down inside a
#   SubViewport and paints itself onto a 0.6 m panel you can stand in front of
# desire: to watch two chemicals chase each other into coral, mitosis and mazes at eye height
# critical_parameter: inoculation — WHERE the uniform field is first broken, which is the only
#   thing that differs between two otherwise identical fields
# triggers: inoculation is forwarded to the reaction in _enter_tree, before its _ready sows the
#   field; the preset cycle re-sows every 30 s through the same door
# emerges: structure from a rule that contains no structure — and, at inoculation:dust, structure
#   with no origin to point at
# needs: the reaction instance under SubViewport [has]; VR feed/kill controls [missing];
#   touch-to-seed [missing]
# relationships: the housing for [[turing_pattern]]; contrasts ordered_grid (imposed order) and
#   sits beside [[mirror_cellular_texture_for_3d]] (difference COPIED, not grown)
# truth: identical cells under identical rules stay identical forever. Every pattern here is the
#   descendant of one asymmetry somebody had to introduce — and this artifact says which.

# ── DNA ───────────────────────────────────────────────────────────────────────
# THE AXIS — where the difference comes from.
#
# Gray-Scott begins with a field that is perfectly uniform: A = 1 in every cell, B = 0 in every
# cell, and the same reaction in every cell. That field is a fixed point. It will sit there for
# eternity. The coral and the mazes and the mitosis all depend on _add_random_seeds() — five
# random blots, hardcoded — and the artifact has never admitted that this, not the chemistry, is
# where its patterns come from. So the axis is the inoculation, and the family argues that
# morphogenesis needs no planner but does need a FIRST ASYMMETRY, which somebody chooses.
#
#   blot     the legacy lineage, byte for byte — five discs, random centres, random radii.
#            Reads as an irregular scatter of dark splodges on white.
#   lattice  sixteen identical discs on a regular 4 x 4 grid. Order in the initial condition;
#            reads as a perfect dot matrix, and the pattern still diverges from it.
#   point    one big disc at the centre. Every later structure descends from one origin; reads
#            as a single dark eye.
#   rim      a band down the left edge. Difference arrives at the boundary and invades inward;
#            reads as a black stripe with white ahead of it.
#   seam     a straight diagonal crack corner to corner. One line, no centre.
#   dust     every cell perturbed on its own account, 2% of them. Difference is everywhere and
#            has no origin at all; reads as a fine even speckle.
#
# VISIBLE IN A STILL, AND HONESTLY SO. Reaction-diffusion is a PROCESS, and a capture at ~1.2 s
# gets roughly a second of model time out of the thousands the pattern needs — the frame shows
# the inoculation with the very first blur on it, and nothing else. Rather than dress that up,
# this axis IS the thing the still can hold, and it is also the thing that decides everything
# the still cannot.
#
# NOT TOUCHED: feed_rate, kill_rate, the diffusion constants, the Laplacian stencil, the preset
# ladder. The chemistry is the curriculum. Only the first asymmetry moves.
const INOCULATIONS: PackedStringArray = ["blot", "lattice", "point", "rim", "seam", "dust"]

@export_enum("blot", "lattice", "point", "rim", "seam", "dust") var inoculation: String = "blot"

## Seed for the inoculation draws, forwarded straight through. -1 keeps the legacy behaviour.
## The sweep MUST pin this for `blot` and `dust`: without it, six variants are sown from six
## different random fields and the critic reports the difference between random draws as the
## bite of the axis. The four deterministic values draw nothing and do not care.
@export var field_seed: int = -1

## Path to the reaction inside the SubViewport, as the scene names it.
const REACTION_PATH := "SubViewport/TuringPattern"


## _enter_tree, NOT _ready. Godot notifies ENTER_TREE top-down across the whole subtree before it
## notifies READY bottom-up, so this is the last moment at which the reaction one level down can
## still be configured BEFORE its own _ready() sows the field. Forwarding from _ready() would
## arrive one notification too late and every variant would render the default.
func _enter_tree() -> void:
	_forward()


func _forward() -> void:
	var rd: Node = get_node_or_null(REACTION_PATH)
	if rd == null:
		return
	rd.set("inoculation", inoculation)
	rd.set("field_seed", field_seed)


## A map may set #inoculation: and #field_seed:. GUARDED — a config carrying neither key returns
## before touching anything, so a placement that only wanted a rotation does not re-sow a
## 128 x 128 field mid-reaction.
func apply_grid_config(config: Dictionary) -> void:
	var before_inoculation: String = inoculation
	var before_seed: int = field_seed
	if config.has("inoculation"):
		inoculation = _pick_axis(str(config["inoculation"]), INOCULATIONS, inoculation)
	if config.has("field_seed"):
		field_seed = int(config["field_seed"])
	if inoculation == before_inoculation and field_seed == before_seed:
		return
	_forward()
	var rd: Node = get_node_or_null(REACTION_PATH)
	if rd == null:
		return
	# If _ready has not run down there yet, do NOT re-sow: the grids and the material do not
	# exist, and the values just forwarded are the ones _ready will sow with anyway.
	if not rd.is_node_ready():
		return
	if rd.has_method("_initialize_grids"):
		rd.call("_initialize_grids")
	if rd.has_method("_add_random_seeds"):
		rd.call("_add_random_seeds")
	if rd.has_method("_update_texture"):
		rd.call("_update_texture")


## An unreadable token resolves to the value already in place rather than to silence — a typo
## must not quietly leave the field uniform, which is the one state that never becomes a pattern.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback
