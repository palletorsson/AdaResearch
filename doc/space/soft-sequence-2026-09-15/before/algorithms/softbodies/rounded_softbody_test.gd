# rounded_softbody_test.gd
# The bare harness around the rounded soft body: a floor, a collider to fall onto,
# and the specimen itself. rounded_softbody is the same specimen on a finished
# compression bench; this is the one you can throw things at.

extends Node3D

# --- WHY THIS FILE EXISTS (2026-08-04) ----------------------------------------
# THE DEFECT CAME FIRST, AND IT WAS NOT "NO KNOBS". rounded_softbody_test.tscn's
# root was a bare Node3D carrying no script at all. Every line of behaviour lived
# on the instanced child `RoundedSoftBody`, which runs rounded_softbody.gd. So:
#
#   - the research runner reported "no .gd resolvable from its scene" and stopped,
#   - GridInteractablesComponent, which sets config_* metadata on the ROOT and
#     calls apply_grid_config on the ROOT, fell through to "no configuration
#     method found" for all 8 placements,
#   - and any axis declared on the child would have been declared-but-unreachable
#     from a map token — the documented failure where the .tscn root does not
#     carry the script.
#
# This script is the pass-through that closes it. It owns nothing, builds nothing
# and draws nothing; it forwards config down to the specimen. That shape is the
# NOC forces family's (`forces_demo_root.gd`), and the declaration gate already
# knows how to read an axis through it.
#
# THE AXIS IS ON THE SPECIMEN AND MIRRORED HERE. `measure` = strain | collision |
# volume | none, the three modes rounded_softbody.gd has always had plus the
# unread body. See that file's header for why the word is `measure` and not the
# softbody family's `assay`.
#
# STILL BROKEN, DELIBERATELY LEFT ALONE: the instanced child in the .tscn carries
# eight property overrides from an era when rounded_softbody.tscn's root was a
# SoftBody3D — material_override, a 44 KB baked `mesh`, simulation_precision,
# pressure_coefficient, ray_pickable, size, radius, segments. The root is a
# Node3D now and none of those properties exist on it, so Godot drops them all on
# load. They are inert, and ripping them out is a separate change with its own
# risk; this one is meant to be behaviour-preserving.
# ------------------------------------------------------------------------------

## Kept identical to rounded_softbody.gd's list, character for character. A typo in a
## map token keeps the shipped strain heatmap.
const MEASURES: PackedStringArray = ["strain", "collision", "volume", "none"]

## Which quantity the deformation is read as. `strain` is what the specimen has always
## started in (`var _mode: int = Mode.STRAIN`), so the default forwards nothing at all.
@export_enum("strain", "collision", "volume", "none") var measure: String = "strain"

var _specimen: Node = null


func _ready() -> void:
	_specimen = get_node_or_null("RoundedSoftBody")
	if has_meta("config_measure"):
		var m_in: String = str(get_meta("config_measure")).strip_edges().to_lower()
		if MEASURES.has(m_in):
			measure = m_in
	# GATED BY DATA. Children are ready before their parent, so the specimen has
	# already built itself in STRAIN. At the default this sends nothing, and the 8
	# existing placements run one call lighter than a rebuild — they run none.
	if measure != "strain":
		_forward({"measure": measure})


## Every key rounded_softbody.gd's own apply_grid_config reads. Nothing outside this
## list is forwarded, so a config carrying only placement keys reaches the specimen as
## no call at all rather than as a call that does nothing but reset its running strain
## maximum a frame after spawn.
const SPECIMEN_KEYS: PackedStringArray = [
	"measure", "mode", "stiffness", "pressure", "damping", "mass",
	"squeeze_strength", "volume_correction", "size",
]

## Grid hook. There was none before, so every key a map could carry was silently
## dropped; the specimen's own apply_grid_config (stiffness, pressure, damping, mass,
## squeeze_strength, volume_correction, size) was unreachable from any token too.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("measure"):
		var want: String = str(config_data["measure"]).strip_edges().to_lower()
		if MEASURES.has(want):
			measure = want

	var merged: Dictionary = {}
	for k in SPECIMEN_KEYS:
		if config_data.has(k):
			merged[k] = config_data[k]
	if merged.is_empty():
		return
	merged["measure"] = measure
	_forward(merged)


func _forward(config_data: Dictionary) -> void:
	if _specimen == null or not is_instance_valid(_specimen):
		_specimen = get_node_or_null("RoundedSoftBody")
	if _specimen != null and _specimen.has_method("apply_grid_config"):
		_specimen.call("apply_grid_config", config_data)
