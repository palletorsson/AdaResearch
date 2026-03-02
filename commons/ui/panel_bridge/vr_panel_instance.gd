## Wrapper that instances XRToolsViewport2DIn3D and injects
## dynamically-built panel content into its SubViewport.
##
## Usage:
##   var panel = VRPanelInstance.new()
##   add_child(panel)
##   panel.build(panel_def_dict, data_store)
##
## The addon's _process picks up $Viewport.get_child(0) as the
## scene_node when no PackedScene is set (line 548 of the addon).
class_name VRPanelInstance
extends Node3D

const P = preload("res://commons/ui/ada_palette.gd")

## Path to the XRTools Viewport2DIn3D scene.
const V2D_SCENE := preload("res://addons/godot-xr-tools/objects/viewport_2d_in_3d.tscn")

# ── State ───────────────────────────────────────────────────────

var _v2d: XRToolsViewport2DIn3D
var _panel_root: Control

## The panel definition dictionary (from JSON).
var panel_def: Dictionary

## Reference to the overlay_3d tags for this panel's elements.
## Key: element id, Value: { overlay_3d: String, rect: [x, y, w, h] }
var overlay_elements: Array[Dictionary] = []

# ── Build ───────────────────────────────────────────────────────

## Create the Viewport2DIn3D instance and inject panel content.
## [param p_panel_def] — one entry from PanelLayoutJSON.panels[].
## [param data_store] — shared DraftDataStore (null for pattern_maker pages).
func build(p_panel_def: Dictionary, data_store = null) -> void:
	panel_def = p_panel_def

	# Extract panel dimensions
	var width_m: float = panel_def.get("width_m", 0.5)
	var height_m: float = panel_def.get("height_m", 0.5)
	var viewport_px: Array = panel_def.get("viewport_px", [640, 480])
	var vp_w: float = float(viewport_px[0])
	var vp_h: float = float(viewport_px[1])

	# Instance the addon scene
	_v2d = V2D_SCENE.instantiate() as XRToolsViewport2DIn3D
	_v2d.name = panel_def.get("id", "panel")

	# Configure BEFORE adding to tree — setters mark dirty flags
	_v2d.screen_size = Vector2(width_m, height_m)
	_v2d.viewport_size = Vector2(vp_w, vp_h)

	# Opaque, unshaded — matches dark UI, avoids transparency artifacts
	_v2d.transparent = XRToolsViewport2DIn3D.TransparancyMode.OPAQUE
	_v2d.unshaded = true
	_v2d.filter = true

	# Always update (interactive grids)
	_v2d.update_mode = XRToolsViewport2DIn3D.UpdateMode.UPDATE_ALWAYS

	# Don't set `scene` — we inject content directly into $Viewport
	# The addon will pick up our child at line 548.

	add_child(_v2d)

	# Wait one frame for the addon to create its Viewport node,
	# then inject our dynamically-built content.
	await get_tree().process_frame
	_inject_content(data_store)


func _inject_content(data_store = null) -> void:
	# Get the SubViewport from the addon instance
	var viewport: SubViewport = _v2d.get_node_or_null("Viewport") as SubViewport
	if not viewport:
		push_warning("VRPanelInstance: Could not find $Viewport in XRToolsViewport2DIn3D")
		return

	# Build the panel content tree
	_panel_root = PanelContentBuilder.build_panel(panel_def, data_store)

	# Add to viewport — addon's _process will pick this up as scene_node
	viewport.add_child(_panel_root)

	# Collect overlay elements for later 3D overlay spawning
	overlay_elements.clear()
	var elements: Array = panel_def.get("elements", [])
	for elem in elements:
		if elem.has("overlay_3d"):
			overlay_elements.append({
				"id": elem.get("id", ""),
				"overlay_3d": elem.get("overlay_3d", ""),
				"rect": elem.get("rect", [0, 0, 0, 0]),
			})


## Get the XRToolsViewport2DIn3D instance (for advanced access).
func get_v2d() -> XRToolsViewport2DIn3D:
	return _v2d


## Get the injected panel root Control.
func get_panel_root() -> Control:
	return _panel_root
