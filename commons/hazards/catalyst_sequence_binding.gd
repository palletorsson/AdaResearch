# CatalystSequenceBinding.gd
# The canonical statement of the catalyst <-> counterpart relation.
#
# One sequence binds three things that were previously only implicitly
# related across three files:
#   mode         — the catalyst's projectile mode  (mirrors BecomingCatalyst.MODE_DEFS "sequence" column)
#   foe_kind     — the counterpart's friend kind   (mirrors CatalystFoe.MODE_BY_ID, primitives -> goo)
#   friend_power — the lasting player ability      (mirrors CatalystCapabilityManager.FRIEND_POWERS)
#
# The catalyst and its counterpart are the same becoming seen from two
# sides: the catalyst is the hand that gives color, the foe is the grey
# body missing it. Binding both to the SAME sequence name is what makes
# them a pair rather than two independent systems.
#
# Who wins on conflict: a vent may seed its brood's kind, but the first
# catalyst hit on a creature still in "foe" re-locks the lineage to the
# projectile's mode (CatalystFoe.hit_by_catalyst_mode). The vent's seed
# only survives on creatures pre-warmed past "foe". The catalyst is the
# stronger namer — the counterpart remembers who touched it first.
#
# No class_name on purpose — consumers preload this file so it parses in
# isolation during headless checks.
extends RefCounted

# sequence id (spine) -> the bound triple. Sequences absent from this
# table have NO catalyst binding: a catalyst told to bind there keeps
# its default behavior (knowledge only), a vent falls back to GOO.
const BINDINGS: Dictionary = {
	"primitives":        {"mode": "primitives",     "foe_kind": "goo",         "friend_power": "shield"},
	"transformation":    {"mode": "transformation", "foe_kind": "transport",   "friend_power": "porter"},
	"color":             {"mode": "chromatic",      "foe_kind": "chroma",      "friend_power": "neutralizer"},
	"forces":            {"mode": "forces",         "foe_kind": "swarm",       "friend_power": "launcher"},
	"wavefunctions":     {"mode": "waveform",       "foe_kind": "wave",        "friend_power": "calmer"},
	"randomness":        {"mode": "chaos",          "foe_kind": "swarm",       "friend_power": "decoy"},
	"cellularautomata":  {"mode": "cellular",       "foe_kind": "drainfriend", "friend_power": "replicator"},
	"fractals":          {"mode": "fractal",        "foe_kind": "fractal",     "friend_power": "splitter"},
	"lsystems":          {"mode": "branching",      "foe_kind": "branch",      "friend_power": "bridger"},
	"swarmintelligence": {"mode": "swarm",          "foe_kind": "swarm",       "friend_power": "escort"},
}


static func binding_for_sequence(sequence_name: String) -> Dictionary:
	return BINDINGS.get(sequence_name, {})


static func mode_for_sequence(sequence_name: String) -> String:
	return String(binding_for_sequence(sequence_name).get("mode", ""))


static func foe_kind_for_sequence(sequence_name: String) -> String:
	return String(binding_for_sequence(sequence_name).get("foe_kind", ""))


static func friend_power_for_sequence(sequence_name: String) -> String:
	return String(binding_for_sequence(sequence_name).get("friend_power", ""))


static func sequence_for_mode(mode_id: String) -> String:
	for seq in BINDINGS:
		if String(BINDINGS[seq]["mode"]) == mode_id:
			return String(seq)
	return ""


## The sequence currently running, from AdaSceneManager. Empty string when
## no sequence is active (standalone map load, headless tests).
static func current_sequence(tree: SceneTree) -> String:
	if tree == null:
		return ""
	var mgr: Node = tree.root.get_node_or_null("AdaSceneManager")
	if mgr == null:
		return ""
	var data: Dictionary = {}
	if mgr.has_method("get_current_sequence_data"):
		data = mgr.get_current_sequence_data()
	return String(data.get("sequence_name", ""))


## Resolve a `sequence:` config token: "auto" (or "") asks the running
## scene manager; anything else is taken as an explicit sequence name.
static func resolve(sequence_token: String, tree: SceneTree) -> String:
	var tok: String = sequence_token.strip_edges().to_lower()
	if tok.is_empty() or tok == "auto":
		return current_sequence(tree)
	return tok


# ── Which substrate channel each mode WRITES when it hits the grid ─────────
#
# The mutator family (commons/grid/mutators/) is five channels on one
# MultiMesh, and each one already declares what it exists for. This table
# says which mode speaks through which — so the colour gun recolours the
# cubes, transformation scales and spins them, cellular flips them on and
# off. The mode's algorithm is performed ON the world, not merely near it.
#
# The pairings follow each mutator's own stated desire, not taste:
#   color       "colour is a function of position"        -> chromatic, chaos
#   transform   rotate / scale / translate deltas         -> transformation,
#                                                            forces, waveform
#   visibility  "a place for cellular automata, fractals  -> cellular, fractal
#                and walker trails to write"
#   glyph       "lets the world UNFOLD — start blocky,    -> primitives,
#                specifics arrive"                           branching
#   part        "positions with names" (role tagging)     -> swarm
#
# Consumed by GridBiomeComponent when a map opts in with
# `layers.biome._meta.catalyst_mutates: true`. No opt-in, no routing.
const MUTATE_CHANNEL: Dictionary = {
	"primitives":     "glyph",
	"transformation": "transform",
	"chromatic":      "color",
	"forces":         "transform",
	"waveform":       "transform",
	"chaos":          "color",
	"cellular":       "visibility",
	"fractal":        "visibility",
	"branching":      "glyph",
	"swarm":          "part",
}


## The substrate channel a mode writes, or "" for editor tools / unknown ids.
static func mutate_channel_for_mode(mode_id: String) -> String:
	return String(MUTATE_CHANNEL.get(mode_id.strip_edges().to_lower(), ""))
