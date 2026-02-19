class_name FacadeElementLibrary
extends RefCounted

## Generic architectural element operations as MeshGrammar rule sequences.
## These are the VERBS (column, opening, band, rustication).
## Study packs provide the ADJECTIVES (proportions, details, order-specific parameters).
##
## Each element is a method returning an Array of MeshRule instances
## that transform tagged faces into the architectural element.

## === COLUMN ELEMENTS ===

## Create a column element: shaft + base + capital.
## Params:
##   column_ratio: float = 8.0   — height/width ratio (Doric=8, Ionic=9, Corinthian=10)
##   capital_height: float = 0.6 — capital height as fraction of column width
##   base_height: float = 0.5    — base height as fraction of column width
##   taper: float = 0.85         — top width / bottom width
##   depth: float = 1.0          — extrusion depth (< 1.0 for pilaster)
##   tag: String = "column"
static func column(p: Dictionary = {}) -> Array[MeshRule]:
	var depth: float = p.get("depth", 0.5)
	var taper: float = p.get("taper", 0.85)
	var tag: String = p.get("tag", "column")
	var rules: Array[MeshRule] = []

	# Step 1: Extrude the face outward to create column depth
	var extrude_rule := ExtrudeFaceOp.new(null, {
		"distance": depth,
		"scale": taper,
		"top_tag": tag + "_top",
		"side_tag": tag + "_shaft"
	})
	rules.append(extrude_rule)

	return rules


## Create a pilaster (flat column, shallow depth).
static func pilaster(p: Dictionary = {}) -> Array[MeshRule]:
	var shallow_p := p.duplicate()
	shallow_p["depth"] = p.get("depth", 0.08)
	shallow_p["taper"] = p.get("taper", 0.95)
	shallow_p["tag"] = p.get("tag", "pilaster")
	return column(shallow_p)


## === OPENING ELEMENTS ===

## Create a rectangular opening (window or door).
## Params:
##   inset: float = 0.03    — frame depth
##   frame_width: float = 0.1 — frame border width as fraction
##   tag: String = "opening"
static func opening_rectangular(p: Dictionary = {}) -> Array[MeshRule]:
	var inset_depth: float = p.get("inset", 0.03)
	var tag: String = p.get("tag", "opening")
	var rules: Array[MeshRule] = []

	# Inset face to create frame
	var inset_rule := InsetFaceOp.new(null, {
		"amount": p.get("frame_width", 0.1),
		"inner_tag": tag + "_void",
		"outer_tag": tag + "_frame"
	})
	rules.append(inset_rule)

	# Extrude the frame inward (recess)
	var recess_rule := ExtrudeFaceOp.new(
		MeshSelector.by_tag(tag + "_void"), {
		"distance": -inset_depth,
		"scale": 1.0,
		"top_tag": tag + "_back",
		"side_tag": tag + "_reveal"
	})
	rules.append(recess_rule)

	return rules


## Create an arched opening.
## The arch is approximated by insetting and then applying a profile extrude.
static func opening_arched(p: Dictionary = {}) -> Array[MeshRule]:
	var inset_depth: float = p.get("inset", 0.05)
	var tag: String = p.get("tag", "arch")
	var rules: Array[MeshRule] = []

	# Inset to create arch frame
	var inset_rule := InsetFaceOp.new(null, {
		"amount": p.get("frame_width", 0.08),
		"inner_tag": tag + "_void",
		"outer_tag": tag + "_frame"
	})
	rules.append(inset_rule)

	# Extrude frame with arch profile
	var arch_rule := ProfileExtrudeOp.new(
		MeshSelector.by_tag(tag + "_frame"), {
		"profile_name": "ovolo",
		"scale": inset_depth * 10.0,
		"tag": tag + "_molding"
	})
	rules.append(arch_rule)

	return rules


## === HORIZONTAL BAND ELEMENTS ===

## Create a cornice / horizontal band.
## Params:
##   profile: String = "cyma_recta"  — profile name from ProfileExtrudeOp
##   scale: float = 1.0
##   tag: String = "cornice"
static func horizontal_band(p: Dictionary = {}) -> Array[MeshRule]:
	var profile_name: String = p.get("profile", "cyma_recta")
	var scale_factor: float = p.get("scale", 1.0)
	var tag: String = p.get("tag", "cornice")
	var rules: Array[MeshRule] = []

	var profile_rule := ProfileExtrudeOp.new(null, {
		"profile_name": profile_name,
		"scale": scale_factor,
		"tag": tag
	})
	rules.append(profile_rule)

	return rules


## Create a string course (thin horizontal dividing band).
static func string_course(p: Dictionary = {}) -> Array[MeshRule]:
	var depth: float = p.get("depth", 0.02)
	var tag: String = p.get("tag", "string_course")
	var rules: Array[MeshRule] = []

	var extrude_rule := ExtrudeFaceOp.new(null, {
		"distance": depth,
		"scale": 1.0,
		"top_tag": tag + "_face",
		"side_tag": tag + "_side"
	})
	rules.append(extrude_rule)

	return rules


## === SURFACE TREATMENTS ===

## Create rustication (split face into grid, offset alternates).
## Params:
##   rows: int = 4
##   cols: int = 1
##   depth: float = 0.02     — rustication depth
##   gap: float = 0.005      — gap between blocks
##   tag: String = "rustication"
static func rustication(p: Dictionary = {}) -> Array[MeshRule]:
	var rows: int = p.get("rows", 4)
	var cols: int = p.get("cols", 1)
	var depth: float = p.get("depth", 0.02)
	var tag: String = p.get("tag", "rustication")
	var rules: Array[MeshRule] = []

	# Step 1: Split into grid
	var split_rule := GridSplitOp.new(null, {
		"rows": rows,
		"cols": cols,
		"tag_prefix": tag
	})
	rules.append(split_rule)

	# Step 2: Extrude alternating cells
	var extrude_rule := ExtrudeFaceOp.new(
		MeshSelector.by_tag(tag).and_also(
			MeshSelector.by_random(0.5, 42)
		), {
		"distance": depth,
		"scale": 0.95,
		"top_tag": tag + "_block",
		"side_tag": tag + "_joint"
	})
	rules.append(extrude_rule)

	return rules


## Create a balustrade (alternating solid/void rhythm).
static func balustrade(p: Dictionary = {}) -> Array[MeshRule]:
	var count: int = p.get("count", 6)
	var tag: String = p.get("tag", "balustrade")
	var rules: Array[MeshRule] = []

	# Split into vertical columns
	var split_rule := GridSplitOp.new(null, {
		"rows": 1,
		"cols": count,
		"tag_prefix": tag
	})
	rules.append(split_rule)

	# Inset alternating columns (to create balusters)
	var inset_rule := InsetFaceOp.new(
		MeshSelector.by_tag(tag).and_also(
			MeshSelector.by_random(0.5, 7)
		), {
		"amount": 0.2,
		"inner_tag": tag + "_baluster",
		"outer_tag": tag + "_void"
	})
	rules.append(inset_rule)

	return rules


## Create a pediment (triangular or curved crown).
## Params:
##   height: float = 0.3     — pediment height relative to width
##   type: String = "triangular"  — "triangular" or "curved"
##   tag: String = "pediment"
static func pediment(p: Dictionary = {}) -> Array[MeshRule]:
	var height_ratio: float = p.get("height", 0.3)
	var tag: String = p.get("tag", "pediment")
	var rules: Array[MeshRule] = []

	# Extrude upward with taper to create triangular form
	var extrude_rule := ExtrudeFaceOp.new(null, {
		"distance": 0.02,
		"scale": 0.0,  # Taper to a point (triangle)
		"top_tag": tag + "_peak",
		"side_tag": tag + "_slope"
	})
	rules.append(extrude_rule)

	return rules


## === ELEMENT FACTORY ===

## Get element rules by name with parameters.
## This is the main entry point for the facade grammar.
static func get_element(name: String, p: Dictionary = {}) -> Array[MeshRule]:
	match name:
		"column":
			return column(p)
		"pilaster":
			return pilaster(p)
		"opening_rectangular", "window":
			return opening_rectangular(p)
		"opening_arched", "arch":
			return opening_arched(p)
		"horizontal_band", "cornice":
			return horizontal_band(p)
		"string_course":
			return string_course(p)
		"rustication":
			return rustication(p)
		"balustrade":
			return balustrade(p)
		"pediment":
			return pediment(p)
		_:
			push_warning("FacadeElementLibrary: Unknown element '%s'" % name)
			return []


## Get all available element names.
static func get_element_names() -> Array[String]:
	return [
		"column", "pilaster",
		"opening_rectangular", "opening_arched",
		"horizontal_band", "string_course",
		"rustication", "balustrade", "pediment"
	]
