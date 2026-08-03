# BotanicalFlowerArtifact.gd
# Grid-system wrapper for the BotanicalFlower procedural flower generator.
# Instances the core botanical_flower scene and exposes grid config for
# map-driven parameter control (petal count, color, symmetry, etc.).

extends Node3D
class_name BotanicalFlowerArtifact

# @identity
# essence: Grid wrapper instantiating BotanicalFlower — petal count, length, curve, color, symmetry as procedural parameters
# desire: To let players tune flower morphology through grid config, watching small parameter changes produce dramatic form shifts
# critical_parameter: petal_count — the integer that most visibly transforms the flower from tulip to daisy to chrysanthemum
# triggers: Low petal count produces simple bloom; high count produces dense rosette; bilateral symmetry produces orchid-like forms
# emerges: Infinite flower variety from a handful of parameters forwarded to a single procedural generator
# needs: apply_grid_config [has], preset support [has], VR sliders via map config [has]
# relationships: Core artifact across Flower_Anatomy, Flower_Parameters, and Flower_Garden. Consumed by evolving_flowers as phenotype.
# truth: A flower is not its petals — it is the parameters that decided how many petals to grow.

const BOTANICAL_FLOWER := preload("res://commons/flora/botanical_flower.tscn")

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `species`
# ═══════════════════════════════════════════════════════════════════════════
#
# WHETHER THIS FLOWER HAS A NAME.
#
# BotanicalFlower.PRESETS already holds nine real Swedish wildflowers, each a full
# 25-key parameter set drawn from botanical illustrations — bluebell, iris,
# fritillaria, allium, orchid, corydalis, daisy, crown imperial, clover. Every one
# of them is reachable from this wrapper today and NOT ONE map has ever asked for
# one: all nine placements are the bare token, so all nine render DEFAULT_CONFIG,
# the generic five-petal pink thing that is nobody's flower. Nine species sat in the
# source tree that no player has ever met. That is what this axis is for.
#
# It is not a colour swatch. A preset is a claim about what a flower IS: bluebell
# says a raceme of six pendant bells on an arched stem, allium says twenty tiny
# heads on one umbel, daisy says a composite where the "petals" are ray florets
# around a disk. The artifact's own truth statement — a flower is not its petals,
# it is the parameters that decided how many petals to grow — is exactly the
# argument this axis puts on the bench, because `generic` is not the absence of a
# species. It is the position that a flower can be specified without being named.
#
#   generic         preset = "", the shipped build byte for byte: DEFAULT_CONFIG's
#                   single open five-petal bloom, 0.25 m stem, four lanceolate
#                   leaves. The parametric flower that belongs to no genus.
#   bluebell        pendant bell form, six flowers on a raceme, arched stem
#   iris            bilateral symmetry, six wide violet petals on a 0.35 m stem
#   daisy           composite head, thirteen white ray florets, yellow disk, 0.10 m
#   allium          umbel, twenty near-scaleless heads on a single 0.35 m scape
#   crown_imperial  cyme of five pendant orange bells at 0.5 m — the tall one
#
# Six of the nine, chosen to span the space rather than to be pretty: single vs
# inflorescence, radial vs bilateral, open vs bell vs composite, 0.10 m to 0.50 m.
# The other three (fritillaria, orchid, corydalis) still work if a map names them —
# the export hint is an editor affordance, not a gate — they are simply not part of
# the declared sweep because they sit close to values already in it.
@export_enum("generic", "bluebell", "iris", "daisy", "allium", "crown_imperial") var species: String = "generic"

## Allow-list. An unknown word falls back to `generic` rather than stranding a placement
## with an empty pot. Kept in step with the export hint above — the declaration gate reads
## the hint, and this is what the code actually tests against.
const SPECIES: PackedStringArray = ["generic", "bluebell", "iris", "daisy", "allium", "crown_imperial"]

var _flower: BotanicalFlower = null

## Per-key overrides a map sent through apply_grid_config (petal_count, color_hue, …).
## Held here rather than only inside the flower because changing species wipes the flower's
## config back to the preset baseline, and a map that asked for both should not lose one.
var _overrides: Dictionary = {}


func _ready() -> void:
	_flower = BOTANICAL_FLOWER.instantiate() as BotanicalFlower
	if _flower == null:
		return
	# BEFORE add_child, deliberately. BotanicalFlower._ready() reads `preset` and calls
	# build() exactly once; setting it afterwards is why a `preset:` token used to do
	# nothing at all unless some other key happened to ride along with it.
	_flower.preset = _preset_for(species)
	add_child(_flower)


## The species name as the generator wants it. `generic` is spelled "" down there — the
## empty string is what makes BotanicalFlower._ready() skip the preset merge and build
## straight from DEFAULT_CONFIG, which is the shipped behaviour this default preserves.
func _preset_for(species_name: String) -> String:
	var want: String = species_name.strip_edges().to_lower()
	if not SPECIES.has(want):
		# Not in the declared six, but the generator may still know it (fritillaria,
		# orchid, corydalis). Only fall back to generic if nothing knows the word.
		if BotanicalFlower.PRESETS.has(want):
			return want
		return ""
	if want == "generic":
		return ""
	return want


## Rebuild the flower from `species` plus whatever overrides a map has sent.
##
## Wipes config first: the generator MERGES a preset into whatever is already there, so
## going daisy → generic without a reset would leave the daisy's thirteen ray florets
## standing on a generic stem — a chimera of two species and a fact about neither.
func _rebuild_flower() -> void:
	if not is_instance_valid(_flower):
		return

	_flower.config = {}
	_flower.preset = _preset_for(species)
	if _flower.preset != "" and BotanicalFlower.PRESETS.has(_flower.preset):
		_flower.configure(BotanicalFlower.PRESETS[_flower.preset])
	if _overrides.size() > 0:
		_flower.configure(_overrides)
	_flower.rebuild()


func apply_grid_config(config_data: Dictionary) -> void:
	if not _flower:
		return

	var was_species: String = species

	# Forward recognized keys to BotanicalFlower.configure()
	var config := {}

	if config_data.has("petal_count"):
		config["petal_count"] = int(config_data["petal_count"])
	if config_data.has("petal_length"):
		config["petal_length"] = float(config_data["petal_length"])
	if config_data.has("petal_width"):
		config["petal_width"] = float(config_data["petal_width"])
	if config_data.has("petal_curve"):
		config["petal_curve"] = float(config_data["petal_curve"])
	if config_data.has("stem_height"):
		config["stem_height"] = float(config_data["stem_height"])
	if config_data.has("leaf_count"):
		config["leaf_count"] = int(config_data["leaf_count"])
	if config_data.has("color_hue"):
		var hue := float(config_data["color_hue"])
		config["petal_color"] = Color.from_hsv(hue, 0.75, 0.85)
	if config_data.has("symmetry"):
		var sym = config_data["symmetry"]
		if sym is String:
			config["symmetry"] = BotanicalFlower.Symmetry.BILATERAL if sym.to_lower() == "bilateral" else BotanicalFlower.Symmetry.RADIAL
		else:
			config["symmetry"] = BotanicalFlower.Symmetry.RADIAL if int(sym) == 0 else BotanicalFlower.Symmetry.BILATERAL

	# `species` is the declared axis; `preset` is the key nine months of map tokens and
	# the generator's own apply_grid_config already use. Same knob, so accept both.
	if config_data.has("preset"):
		species = str(config_data["preset"])
	if config_data.has("species"):
		species = str(config_data["species"])

	for key in config:
		_overrides[key] = config[key]

	# GUARDED. The grid reaches this more than once per placement, and a placement carrying
	# neither a species nor an override arrives with nothing to do. Rebuilding on those
	# would tear down and re-grow every shipped flower for no visible change.
	if species == was_species and config.size() == 0:
		return

	_rebuild_flower()
