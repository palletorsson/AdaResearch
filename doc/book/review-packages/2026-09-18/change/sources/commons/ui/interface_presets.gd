@tool
## InterfacePresets — the PRINCIPAL CONFIG for each interface type.
##
## One source of truth for how each type's board/console is built (housing,
## desktop form, body height, viz host, demo). Targets declare their TYPE and
## get the configured housing from `build()` instead of hand-setting the same
## four exports in every artifact. Change a type's layout here → every target
## of that type updates. See doc/INTERFACE_OVERHAUL.md for the taxonomy.
##
## Usage (the target-change pattern):
##   _console = InterfacePresets.build("workbench", "Shannon Entropy", plate_height)
##   add_child(_console)
##   _readout = _console.add_readout("")
##   _slider  = _console.add_slider("P(1)", "P(1)")
class_name InterfacePresets
extends RefCounted

const ControlConsoleScript := preload("res://commons/ui/control_console.gd")
const ControlPanelScript := preload("res://commons/ui/control_panel.gd")
const InterfaceHousingScript := preload("res://commons/ui/interface_housing.gd")

## Housing kinds handled by InterfaceHousing (a board on a custom stand, plus the
## container/apparatus forms that expose a content() host).
const HOUSING_FORMS := ["pedestal", "table", "tower", "monitor_bank", "grid_board",
	"vitrine", "tank", "dish", "frame", "launcher"]

## Principal config per type. `housing`: "console" = floor cabinet + apparatus
## viz hosts; "board" = bare panel (wall/desk mounted, positioned by caller).
const TYPES := {
	"workbench": {  # sliders + readout + a visualization
		"housing": "console",
		"face_to_origin": true,
		"body_height": 0.40,
		"has_viz": true,
	},
	"machine": {    # mostly buttons / presets / capture
		"housing": "console",
		"face_to_origin": true,
		"body_height": 0.40,
		"has_viz": false,
	},
	"console": {    # game/control surface — keep character, full cabinet
		"housing": "console",
		"face_to_origin": true,
		"body_height": 0.45,
		"has_viz": true,
	},
	"readout": {    # live display only, no controls — on a console (never floats)
		"housing": "console",
	},
	"rack": {       # converged base (Forces/RackTemplates) — on a console
		"housing": "console",
	},
	"plaque": {     # static text/info — a freestanding notice on a pedestal
		"housing": "pedestal",
	},
	"dashboard": {  # many readouts on one surface — a status console
		"housing": "console",
		"body_height": 0.45,
	},
	"pedestal": {   # slim podium, board at chest height (scanner / specimen check)
		"housing": "pedestal",
	},
	"tower": {      # tall vertical LED/display rack, floor-mounted (server_rack)
		"housing": "tower",
	},
	"table": {      # horizontal plan surface on legs (plan / layout)
		"housing": "table",
	},
	"monitor_bank": {  # desk console + pole of angled screens (mission control)
		"housing": "monitor_bank",
	},
	"grid_board": {    # upright panel with an N×N cell grid (placement / pattern)
		"housing": "grid_board",
	},
	"vitrine": {       # enclosed glass display case on a plinth (display case)
		"housing": "vitrine",
	},
	"tank": {          # open glass vessel — liquid / field / layered content
		"housing": "tank",
	},
	"dish": {          # round shallow basin, top-down content (petri / tray)
		"housing": "dish",
	},
	"frame": {         # open gantry suspending mechanical content (cradle/pendulum)
		"housing": "frame",
	},
	"launcher": {      # aimed launch apparatus with a control board (firework)
		"housing": "launcher",
	},
}


## LOOK / SKIN axis — a named material dialect applied across any type. `body`/
## `trim` skin the housing geometry; `panel`/`frame`/`title`/`label`/`accent`
## skin the board; `dark` recolours dark sub-panels (screens, grid backings).
const SKINS := {
	"braun": {        # Dieter Rams — warm light grey, charcoal text, one orange
		"body": Color(0.56, 0.57, 0.60), "trim": Color(0.30, 0.31, 0.34),
		"panel": Color(0.81, 0.80, 0.76), "frame": Color(0.62, 0.61, 0.57),
		"title": Color(0.17, 0.17, 0.18), "label": Color(0.26, 0.26, 0.27),
		"accent": Color(0.88, 0.42, 0.12), "dark": Color(0.12, 0.13, 0.15),
	},
	"black_mesa": {   # dark industrial lab, amber CRT
		"body": Color(0.20, 0.21, 0.23), "trim": Color(0.10, 0.10, 0.12),
		"panel": Color(0.16, 0.17, 0.18), "frame": Color(0.07, 0.07, 0.08),
		"title": Color(0.82, 0.85, 0.82), "label": Color(0.62, 0.68, 0.62),
		"accent": Color(0.95, 0.62, 0.14), "dark": Color(0.05, 0.06, 0.06),
	},
	"sci_fi": {       # dark + neon cyan
		"body": Color(0.17, 0.18, 0.21), "trim": Color(0.09, 0.10, 0.12),
		"panel": Color(0.11, 0.13, 0.16), "frame": Color(0.18, 0.52, 0.62),
		"title": Color(0.70, 0.92, 1.0), "label": Color(0.50, 0.80, 0.92),
		"accent": Color(0.0, 0.85, 0.95), "dark": Color(0.04, 0.06, 0.08),
	},
	"civic": {        # warm sand public kiosk, civic blue accent
		"body": Color(0.57, 0.51, 0.41), "trim": Color(0.34, 0.30, 0.24),
		"panel": Color(0.87, 0.83, 0.74), "frame": Color(0.55, 0.50, 0.42),
		"title": Color(0.20, 0.17, 0.13), "label": Color(0.32, 0.28, 0.22),
		"accent": Color(0.20, 0.45, 0.72), "dark": Color(0.14, 0.13, 0.11),
	},
	"warm_wood": {    # walnut + brass
		"body": Color(0.42, 0.30, 0.20), "trim": Color(0.26, 0.18, 0.11),
		"panel": Color(0.83, 0.77, 0.65), "frame": Color(0.46, 0.34, 0.21),
		"title": Color(0.20, 0.14, 0.08), "label": Color(0.33, 0.24, 0.15),
		"accent": Color(0.74, 0.53, 0.18), "dark": Color(0.16, 0.12, 0.08),
	},
}

# Reference colours of the default (braun) housing geometry — used to remap
# InterfaceHousing meshes when skinning (matches what _box/_mat produce).
const _DEF_BODY := Color(0.56, 0.57, 0.60)
const _DEF_TRIM := Color(0.30, 0.31, 0.34)
const _DEF_DARK := Color(0.12, 0.13, 0.15)


## Build the configured housing for `type`, in the named `skin`. `plate_height`
## = the world Y the board sits at. Returns ControlConsole / InterfaceHousing.
static func build(type: String, title: String, plate_height: float = 1.0, skin: String = "braun") -> Node3D:
	var cfg: Dictionary = config_for(type)
	var housing: String = cfg.get("housing", "console")
	var sc: Dictionary = SKINS[skin] if SKINS.has(skin) else SKINS["braun"]
	if housing in HOUSING_FORMS:
		var h: Node3D = InterfaceHousingScript.new()
		h.call("setup", housing, title)
		_style_panel(h.call("board"), sc)
		_recolor_geometry(h, sc)
		return h
	if housing == "board":
		var board: Node3D = ControlPanelScript.new()
		board.name = "Board"
		if "title" in board:
			board.set("title", title)
		_style_panel(board, sc)
		return board
	var console: Node3D = ControlConsoleScript.new()
	console.name = "Console"
	console.set("auto_demo", false)
	console.set("face_to_origin", cfg.get("face_to_origin", true))
	console.set("body_height", cfg.get("body_height", 0.40))
	console.set("viz_floor", -plate_height)
	console.set("body_color", sc["body"])
	console.set("trim_color", sc["trim"])
	console.call("set_title", title)
	_style_panel(console.call("panel"), sc)
	return console


## Apply a skin's colours to a ControlPanel board (set before its _ready).
static func _style_panel(panel, sc: Dictionary) -> void:
	if panel == null:
		return
	for k in [["panel", "panel_color"], ["frame", "frame_color"], ["title", "title_color"],
			["label", "label_color"], ["accent", "accent_color"]]:
		if sc.has(k[0]) and (k[1] in panel):
			panel.set(k[1], sc[k[0]])


## Recolour an InterfaceHousing's opaque geometry meshes from the skin (skips the
## board + content subtrees, glass, and emissive LEDs by matching the defaults).
static func _recolor_geometry(root: Node3D, sc: Dictionary) -> void:
	var skip_a = root.call("board") if root.has_method("board") else null
	var skip_b = root.call("content") if root.has_method("content") else null
	var stack: Array = [root]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n == skip_a or n == skip_b:
			continue
		if n is MeshInstance3D and n.material_override is StandardMaterial3D:
			var m: StandardMaterial3D = n.material_override
			if m.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED and not m.emission_enabled:
				var a: Color = m.albedo_color
				if a.is_equal_approx(_DEF_BODY): m.albedo_color = sc["body"]
				elif a.is_equal_approx(_DEF_TRIM): m.albedo_color = sc["trim"]
				elif a.is_equal_approx(_DEF_DARK): m.albedo_color = sc.get("dark", _DEF_DARK)
		for c in n.get_children():
			stack.append(c)


## The principal config dict for a type (copy, safe to mutate).
static func config_for(type: String) -> Dictionary:
	return (TYPES[type] if TYPES.has(type) else TYPES["workbench"]).duplicate()


## Does this type's principal config include a visualization apparatus?
static func has_viz(type: String) -> bool:
	return bool(config_for(type).get("has_viz", false))
