@tool
extends RefCounted
class_name PackagingResolver

## Pure decision layer for the packaging family: given an artifact's spatial_needs + its measured
## AABB + its name, decide which packaging props to spawn around it and how. Returns a list of specs
## the placement hook instantiates. No nodes, no side effects — trivially testable headless.
##
## A spec = {
##   "scene":     res:// path to a packaging .tscn,
##   "dna":       Dictionary passed to the packaging's apply_grid_config,
##   "pos_offset":Vector3 offset from the artifact's cell origin (local, pre-rotation),
##   "raise_to":  float — if >= 0, the ARTIFACT's base is lifted to this height (it sits ON the
##                packaging top); -1 = don't move the artifact (wall/readout sit beside/behind it).
## }

const PODIUM := "res://commons/artifacts/hangar_podium/hangar_podium.tscn"
const STEP := "res://commons/artifacts/hangar_step_base/hangar_step_base.tscn"
const TABLE := "res://commons/artifacts/hangar_worktable/hangar_worktable.tscn"
const WALL := "res://commons/artifacts/hangar_wall_panel/hangar_wall_panel.tscn"
const READOUT := "res://commons/artifacts/artifact_readout_screen/artifact_readout_screen.tscn"

const REACH_HEIGHT := 1.0      # podium top — lifts a small artifact to hand height
const TABLE_HEIGHT := 0.95
const STEP_HEIGHT := 0.25


static func resolve(spatial_needs: Dictionary, aabb_size: Vector3, artifact_name: String,
		with_readout: bool = true) -> Array:
	var specs: Array = []
	var platform := str(spatial_needs.get("platform", "none")).to_lower()
	var fp := int(spatial_needs.get("footprint_cells", 1))
	var wall := bool(spatial_needs.get("wall_backing", false))
	var w: float = maxf(aabb_size.x, 0.3)
	var d: float = maxf(aabb_size.z, 0.3)
	var h: float = maxf(aabb_size.y, 0.2)
	var big: bool = fp >= 6 or maxf(w, d) >= 2.4

	# ── grounding: how the artifact meets the floor (mutually exclusive) ──
	if platform == "sunken":
		pass  # void around it by design — no packaging under it
	elif platform == "pedestal":
		specs.append({
			"scene": PODIUM,
			"dna": {"top_height": REACH_HEIGHT, "top_size": maxf(maxf(w, d) + 0.22, 0.4),
				"top_style": "tray", "stencil_text": _stencil_id(artifact_name)},
			"pos_offset": Vector3.ZERO, "raise_to": REACH_HEIGHT,
		})
	elif platform == "table":
		specs.append({
			"scene": TABLE,
			"dna": {"width": maxf(w + 0.6, 1.2), "depth": maxf(d + 0.3, 0.7),
				"top_height": TABLE_HEIGHT, "with_screen": false, "with_tools": false, "drawers": false},
			"pos_offset": Vector3.ZERO, "raise_to": TABLE_HEIGHT,
		})
	elif big:
		# a large artifact you step up to / stand on
		specs.append({
			"scene": STEP,
			"dna": {"width": maxf(w + 0.8, 2.0), "depth": maxf(d + 0.8, 2.0),
				"step_height": STEP_HEIGHT, "hazard_edge": true, "stencil_text": _stencil_id(artifact_name)},
			"pos_offset": Vector3.ZERO, "raise_to": STEP_HEIGHT,
		})

	# ── wall backing: a panel behind the artifact ──
	if wall:
		specs.append({
			"scene": WALL,
			"dna": {"width": maxf(w + 0.8, 2.0), "height": maxf(h + 0.8, 2.4), "panel_style": "greebled"},
			"pos_offset": Vector3(0, 0, -(d * 0.5 + 0.18)), "raise_to": -1.0,
		})

	# ── caption: a framed readout beside the artifact, replacing a floating label ──
	if with_readout and artifact_name.strip_edges() != "":
		specs.append({
			"scene": READOUT,
			"dna": {"header": _header(artifact_name), "body": "", "mount": "stalk"},
			"pos_offset": Vector3(w * 0.5 + 0.7, 0, d * 0.2), "raise_to": -1.0,
		})

	return specs


## A short stencil ID from a name, e.g. "Reaction Diffusion" -> "REACTION".
static func _stencil_id(name: String) -> String:
	var clean := name.strip_edges().to_upper()
	if clean.length() <= 8:
		return clean
	return clean.substr(0, 8)


## A readout header from a name — uppercased, trimmed to a sane width.
static func _header(name: String) -> String:
	var clean := name.strip_edges().to_upper()
	if clean.length() <= 22:
		return clean
	return clean.substr(0, 22)
