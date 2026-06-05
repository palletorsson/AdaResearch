extends RefCounted
class_name BiomeElements

## Single source of truth for the biome paint elements — names, menu labels, the
## bright UI/brush colour, the earthy soil-bleed colour, and the curriculum unlock
## order. Consolidates what the review found duplicated across four files
## (BiomeBrushController, biome_brush_menu_ui, BiomeScrubberDesktop3D, and
## biome_ground_substrate's bleed map) — the "4-way drift" smell.
##
## Reference by PRELOAD const, not the global `BiomeElements` name, to dodge the
## class-cache parse trap (a new class_name referenced by global name can fail to
## resolve at game runtime; editor import masks it).

## Paint order = brush/menu order. ground + shader are the substrate; the rest are
## the living kingdoms.
const NAMES: Array = ["ground", "shader", "tree", "critter", "flower", "mushroom", "large_critter"]

const LABELS: Dictionary = {
	"ground": "Ground", "shader": "Shader", "tree": "Tree", "critter": "Critter",
	"flower": "Flower", "mushroom": "Mushroom", "large_critter": "Big Critter",
}

# Bright selection colour — brush ghost, menu tile, scrubber overlay.
const _UI: Dictionary = {
	"ground": [0.55, 0.45, 0.32], "shader": [0.18, 0.62, 0.55], "tree": [0.45, 0.85, 0.50],
	"critter": [1.0, 0.70, 0.36], "flower": [1.0, 0.55, 0.76], "mushroom": [0.80, 0.55, 0.40],
	"large_critter": [0.95, 0.45, 0.30],
}

# Earthy kingdom colour that bleeds into the ground texture beneath the element.
# Missing entry (e.g. ground) → no bleed. shader bleeds its own painted "color";
# the value here is just its fallback.
const _BLEED: Dictionary = {
	"shader": [0.18, 0.62, 0.55], "tree": [0.24, 0.50, 0.24], "critter": [0.92, 0.62, 0.30],
	"large_critter": [0.92, 0.62, 0.30], "flower": [0.95, 0.45, 0.72], "mushroom": [0.55, 0.30, 0.22],
}

# Earliest stage_order at which the element is curriculum-honest (its spawn layer's
# contribution order in biome_contributions.json). ground/shader are always (0).
# Data only for now — the bleed/menu gate is a separate follow-up.
const UNLOCK_ORDER: Dictionary = {
	"ground": 0, "shader": 0, "tree": 11, "critter": 12, "large_critter": 12,
	"flower": 13, "mushroom": 13,
}


static func label(el: String) -> String:
	return str(LABELS.get(el, el.capitalize()))


## Bright UI/brush colour for `el` (grey fallback for unknown).
static func ui_color(el: String) -> Color:
	var c = _UI.get(el, [0.7, 0.7, 0.7])
	return Color(float(c[0]), float(c[1]), float(c[2]))


## Soil-bleed colour for `el`. alpha 1 = bleeds; alpha 0 = does NOT bleed (ground,
## unknown). Plant kingdoms seep their colour into the ground texture beneath them.
static func bleed_color(el: String) -> Color:
	var c = _BLEED.get(el, null)
	if c == null:
		return Color(0, 0, 0, 0)
	return Color(float(c[0]), float(c[1]), float(c[2]), 1.0)


static func unlock_order(el: String) -> int:
	return int(UNLOCK_ORDER.get(el, 0))
