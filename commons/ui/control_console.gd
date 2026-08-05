@tool
extends Node3D
class_name ControlConsole
## A small Dieter-Rams CONSOLE — a grey-metal CSG cabinet with a Braun ControlPanel
## recessed flush in its slanted face. Built like the pattern machines' console
## (commons/artifacts/pattern_tunnel/display_console): a CSGCombiner3D block, minus
## a reclined wedge (the angled screen face), minus a shallow pocket (the bezel) —
## so the plate sits INSIDE the metal, framed, not floating in space.
##
## The plate gives the controls a home; the console gives the whole instrument one.
## add_* calls forward to the inner ControlPanel; the body sizes itself to the plate.
##
## --- DNA (stage 2, promoted 2026-08-05) ---
##
## STAGE-2 DNA PROMOTION. This file was full of knobs and had no ARGUMENT: twenty-one
## exports, every one of them a dimension, a colour or a nudge (board_drop, board_out,
## board_slide, board_face_drop — four separate ways to move the same plate a centimetre).
## A size is not a claim. The two constants that carry one were:
##
##   mounting        HOW the controls meet the room they are controls FOR
##   demo_apparatus  WHAT machine the console is the operator station OF
##
## mounting was not a constant so much as an assumption. The cabinet grammar
## (commons/data/cabinet_grammar.json) opens by asking which plane an interface is read
## on, and this file answered "a floor-standing cabinet" before the question was put — so
## every workbench that composes this console inherited a full metal body with a door and
## a vent grille, whether the room wanted an appliance or a reading stand. The word and
## its three answers are taken CHARACTER FOR CHARACTER from soft_stage_dashboard, which
## asks the same question of a readout, and the two measure alike: wall takes the body
## away and leaves the face, lectern puts the face on legs, kiosk gives it a standing
## body. Only the DEFAULT differs, and it differs because the shipped objects differ —
## the dashboard shipped as a bare quad, this shipped as a cabinet.
##
## demo_apparatus was already an export and had never been declared, so the sweep could
## not reach it: five values, a match block, and nothing in any registry saying so.
##
## mounting=kiosk + demo_apparatus=none is the shipped build, node for node — the CSG
## base, the plinth, the door, the vent and no apparatus at all — so the four map
## placements AND the fourteen workbench artifacts that compose this script
## (shannon_workbench, halting_workbench, stretch_bench, …) are untouched.
##
## Usage in map_data.json:
##   "control_console#mounting:lectern"
##   "control_console#mounting:wall#demo_apparatus:monitor"

const ControlPanelScript = preload("res://commons/ui/control_panel.gd")

@export var body_color: Color = Color(0.56, 0.57, 0.60)   # brushed grey metal
@export var trim_color: Color = Color(0.30, 0.31, 0.34)   # dark trim
@export var tilt_deg: float = 38.0                         # reclined screen face — HCI sweet spot ~35-45° for read+touch in VR
@export var bezel: float = 0.04                            # metal frame margin around the board
## A floor-standing console: a solid body rises to `body_height`, then the slant
## begins; the (smaller) board is mounted on the slanted top.
@export var board_width: float = 0.62                      # the control board on the slant — smaller than the body
@export var body_height: float = 1.0                       # solid body up to here; the slant starts at this height
@export var body_depth: float = 0.4                        # base footprint depth (~0.3–0.5 m)
## DNA gene: how the console meets the room. "kiosk" is the shipped floor cabinet —
## a solid body with a door and a vent, mass all the way down. "lectern" keeps the
## same reading head and takes the cabinet away, leaving splayed legs and a foot: a
## stand you walk up to, with nothing to store inside. "wall" removes the body
## entirely and leaves the head as a fitting set into the architecture.
@export_enum("kiosk", "lectern", "wall") var mounting: String = "kiosk"
## Desktop form: put the reading face at the node origin (short stand below) so
## the console drops into a table-height slot like the old flat plate.
@export var face_to_origin: bool = false
## Small decoration on the body — a cabinet door + pull handle on the front, and
## a vent grille on the side. Toggleable DNA genes.
@export var has_door: bool = true
@export var has_vent: bool = true
@export var board_drop: float = 0.10                       # lower the reading head down the console (vertical)
@export var board_out: float = 0.03                        # bring the board forward, proud over the body front
@export var board_slide: float = 0.06                      # slide the head DOWN THE SLANT (out + down together)
@export var board_face_drop: float = 0.05                  # slide the board DOWN the faceplate (metal shows above it)
## When true (and no controls were added by code), the console builds a small
## demo instrument so the bare .tscn renders something when placed in a map.
@export var auto_demo: bool = true
@export var demo_title: String = "Console"
## DNA gene: which demo viz APPARATUS the console drives — "none" | "monitor" |
## "cube" | "plan" | "jar" (placeholder content; desktop form assumed).
@export var demo_apparatus: String = "none"

var _panel: Node3D
var _built := false
var _content_added := false


func _ready() -> void:
	# The grid stamps `config_<key>` metadata BEFORE _ready and only calls
	# apply_grid_config on a DEFERRED frame — which is after the demo has already
	# been built. Both DNA genes are consumed during _ready, so a map token can
	# only reach them from the metadata. Absent metadata leaves the exports alone.
	if has_meta("config_mounting"):
		mounting = str(get_meta("config_mounting")).to_lower()
	if has_meta("config_demo_apparatus"):
		demo_apparatus = str(get_meta("config_demo_apparatus")).to_lower()
	_ensure_panel()
	if auto_demo and not _content_added:
		_build_demo()
	if not _built:
		call_deferred("_build_body")


## A self-contained reference instrument so the placeable console is never empty:
## title + one slider + SNAP button + a LIVE readout (the slider drives it, so
## the demo proves interactivity in VR). Mirrors the stretch bench's control set.
func _build_demo() -> void:
	set_title(demo_title)
	var s := add_slider("SCALE k")
	add_button("SNAP")
	var r := add_readout("k = 1.00\n|k*v| = 1.48")
	if s and s.has_method("set_normalized_value"):
		s.call("set_normalized_value", 0.5)   # k = 1.0
	if s and s.has_signal("slider_moved"):
		s.connect("slider_moved", func(_v):
			var k: float = 2.0 * float(s.call("get_normalized_value"))
			if r:
				r.text = "k = %.2f\n|k*v| = %.2f" % [k, absf(k) * 1.48])
	if demo_apparatus != "none":
		_build_demo_apparatus()


## Placeholder content for the demo_apparatus gene — proves each host type in
## the DNA gallery (bars on the monitor, sphere in the cube, dots on the plan,
## a specimen in the jar).
func _build_demo_apparatus() -> void:
	# viz_floor defaults to -1.0, which is the DESKTOP assumption: a console dropped
	# into a table-height slot has the room's floor a metre below its origin. A
	# floor-standing console (face_to_origin off, the shipped form) already stands ON
	# that floor at y=0, so the same -1.0 sinks every apparatus base a metre under it —
	# the machine and its operator station would not share a ground. Derive it only
	# when the caller has not said otherwise; capture_props_dna_gallery and
	# interface_presets both set viz_floor explicitly and are unaffected.
	if not face_to_origin and absf(viz_floor + 1.0) < 0.0001:
		viz_floor = 0.0
	match demo_apparatus:
		"monitor":
			var c := add_monitor(Vector2(0.7, 0.45))
			var heights := [0.14, 0.24, 0.18, 0.30, 0.22, 0.34]
			for i in heights.size():
				c.add_child(_box(Vector3(-0.25 + i * 0.10, -0.18 + heights[i] * 0.5, 0.0), Vector3(0.055, heights[i], 0.006), _emissive(viz_accent)))
		"cube":
			var c := add_cube_space(0.8)
			var s := MeshInstance3D.new()
			var sm := SphereMesh.new(); sm.radius = 0.12; sm.height = 0.24
			s.mesh = sm; s.material_override = _emissive(Color(1.0, 0.55, 0.2))
			c.add_child(s)
		"plan":
			var c := add_plan(Vector2(0.7, 0.55))
			for p in [Vector3(-0.22, 0, -0.12), Vector3(0.0, 0, 0.10), Vector3(0.24, 0, -0.04)]:
				var d := MeshInstance3D.new()
				var dm := SphereMesh.new(); dm.radius = 0.025; dm.height = 0.05
				d.mesh = dm; d.position = p; d.material_override = _emissive(Color(1.0, 0.8, 0.3))
				c.add_child(d)
		"jar":
			var c := add_specimen_jar(0.16, 0.46)
			var t := MeshInstance3D.new()
			var tm := TorusMesh.new(); tm.inner_radius = 0.045; tm.outer_radius = 0.10
			t.mesh = tm; t.rotation_degrees = Vector3(35, 0, 15)
			t.material_override = _emissive(Color(0.6, 1.0, 0.5))
			c.add_child(t)


func _emissive(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.emission_enabled = true; m.emission = c; m.emission_energy_multiplier = 0.6
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


## DNA / map config — drive the console's full gene set (geometry + colour + form)
## from a config dict (map_data.json, editor, or the DNA sweep). Colours accept a
## Color or an "r,g,b,a" string (the props-dna-gallery format).
func apply_grid_config(config_data: Dictionary) -> void:
	for key in ["title", "demo_title"]:
		if config_data.has(key):
			demo_title = str(config_data[key]); set_title(demo_title)
	if config_data.has("tilt_deg"): tilt_deg = float(config_data["tilt_deg"])
	if config_data.has("body_height"): body_height = float(config_data["body_height"])
	if config_data.has("body_depth"): body_depth = float(config_data["body_depth"])
	if config_data.has("board_width"): board_width = float(config_data["board_width"])
	if config_data.has("board_drop"): board_drop = float(config_data["board_drop"])
	if config_data.has("board_out"): board_out = float(config_data["board_out"])
	if config_data.has("board_slide"): board_slide = float(config_data["board_slide"])
	if config_data.has("board_face_drop"): board_face_drop = float(config_data["board_face_drop"])
	if config_data.has("bezel"): bezel = float(config_data["bezel"])
	if config_data.has("mounting"): mounting = str(config_data["mounting"]).to_lower()
	if config_data.has("face_to_origin"): face_to_origin = bool(config_data["face_to_origin"])
	if config_data.has("has_door"): has_door = bool(config_data["has_door"])
	if config_data.has("has_vent"): has_vent = bool(config_data["has_vent"])
	if config_data.has("demo_apparatus"): demo_apparatus = str(config_data["demo_apparatus"])
	if config_data.has("viz_dist"): viz_dist = float(config_data["viz_dist"])
	if config_data.has("viz_floor"): viz_floor = float(config_data["viz_floor"])
	if config_data.has("auto_demo"): auto_demo = bool(config_data["auto_demo"])
	if config_data.has("body_color"): body_color = _dna_color(config_data["body_color"], body_color)
	if config_data.has("trim_color"): trim_color = _dna_color(config_data["trim_color"], trim_color)


## Parse a DNA colour value — a Color, or an "r,g,b[,a]" string.
func _dna_color(v: Variant, fallback: Color) -> Color:
	if v is Color:
		return v
	if v is String:
		var p: PackedStringArray = (v as String).split(",")
		if p.size() >= 3:
			var a: float = 1.0 if p.size() < 4 else float(p[3])
			return Color(float(p[0]), float(p[1]), float(p[2]), a)
	return fallback


func _ensure_panel() -> Node3D:
	if _panel == null or not is_instance_valid(_panel):
		_panel = ControlPanelScript.new()
		_panel.name = "Panel"
		_panel.tilt_degrees = 0.0   # the CONSOLE provides the reading tilt
		_panel.label_mesh = true    # black TextMesh labels (engraved look, exports as geometry)
		add_child(_panel)
	return _panel


# ── Forwarders to the recessed ControlPanel ───────────────────────────────
func add_slider(label: String, param := "") -> Node3D: _content_added = true; return _ensure_panel().add_slider(label, param)
func add_button(label: String) -> Node3D: _content_added = true; return _ensure_panel().add_button(label)
func add_dial(label: String, param := "") -> Node3D: _content_added = true; return _ensure_panel().add_dial(label, param)
func add_joystick(label: String, param := "") -> Node3D: _content_added = true; return _ensure_panel().add_joystick(label, param)
func add_readout(text := "") -> Label: _content_added = true; return _ensure_panel().add_readout(text)
func set_title(t: String) -> void: _ensure_panel().title = t
func panel() -> Node3D: return _ensure_panel()


# ══════════════════════════════════════════════════════════════════════════
# VISUALIZATION HOSTS — the canonical DISPLAY side of the console.
#
# The visualization is its own floor-standing APPARATUS standing IN FRONT of
# the console — the console is the operator station; the player looks over
# the board at the machine (scanner-bed-before-the-gantry arrangement; see
# /surreal-lab-gallery for the apparatus language: heavy base, struts, frame
# cradling glowing content). Each host builds a machine on the apparatus axis
# and returns a CONTENT ROOT the artifact fills. Cables run hidden inside the
# bridge duct + the machine's own structure — never floating wires.
# ══════════════════════════════════════════════════════════════════════════

## viz_dist = how far beyond the console the apparatus axis stands.
## viz_floor = console-local y of the floor it stands on (a desktop console
## placed at table height ~1.0 → -1.0).
@export var viz_dist: float = 0.95
@export var viz_floor: float = -1.0
@export var screen_bg: Color = Color(0.04, 0.05, 0.06)
@export var viz_accent: Color = Color(0.35, 0.75, 0.95)

var _viz_anchor: Node3D


## The apparatus axis — at board height, viz_dist beyond the console, with a
## BRIDGE DUCT running from the console's underside to the apparatus base
## (the console↔machine cables live inside it).
func viz_anchor() -> Node3D:
	if _viz_anchor == null or not is_instance_valid(_viz_anchor):
		_viz_anchor = Node3D.new()
		_viz_anchor.name = "VizAnchor"
		_viz_anchor.position = Vector3(0.0, 0.0, -viz_dist)
		add_child(_viz_anchor)
		var z0 := viz_dist - 0.30          # console end (under the body)
		var blen := z0 + 0.10              # …through to the apparatus axis
		var bridge := _box(Vector3(0, -0.50, z0 - blen * 0.5), Vector3(0.12, 0.07, blen), _mat(body_color, 0.45, 0.35))
		bridge.name = "BridgeDuct"; _viz_anchor.add_child(bridge)
		var bspine := _box(Vector3(0, -0.462, z0 - blen * 0.5), Vector3(0.05, 0.012, blen * 0.92), _mat(Color(0.10, 0.10, 0.11), 0.7, 0.1))
		bspine.name = "BridgeSpine"; _viz_anchor.add_child(bspine)
	return _viz_anchor


## A heavy floor base plate under an apparatus (the surreal-lab look).
func _apparatus_base(parent: Node3D, w: float, d: float, y_floor: float) -> void:
	var base := _box(Vector3(0, y_floor + 0.035, 0), Vector3(w, 0.07, d), _mat(trim_color, 0.55, 0.25))
	base.name = "ApparatusBase"
	parent.add_child(base)


## A load-bearing support column with a darker conduit SPINE down its back —
## the display's cables run hidden inside the structure (never floating wires).
## Every host's support must connect continuously console body → display.
func _support_column(parent: Node3D, x: float, z: float, y_top: float, y_bottom: float, w: float, d: float) -> void:
	var h := y_top - y_bottom
	var cy := (y_top + y_bottom) * 0.5
	var col := _box(Vector3(x, cy, z), Vector3(w, h, d), _mat(body_color, 0.45, 0.35))
	col.name = "Support"
	parent.add_child(col)
	var spine := _box(Vector3(x, cy, z - d * 0.5 - 0.004), Vector3(w * 0.4, h * 0.92, 0.01), _mat(Color(0.10, 0.10, 0.11), 0.7, 0.1))
	spine.name = "CableSpine"
	parent.add_child(spine)


## MONITOR — a flat 2D-in-3D screen for plots/grids/graphs. Content root is on
## the screen FACE: place 2D-in-3D elements in its X-Y plane (origin centred,
## ±size/2), Z proud toward the player.
## `stack` mounts a SECOND monitor relative to the primary one (e.g.
## Vector3(0, 0.74, 0) stacks it above) — it links to the apparatus below with
## a short column instead of building its own floor totem.
func add_monitor(size: Vector2 = Vector2(0.9, 0.55), stack: Vector3 = Vector3.ZERO) -> Node3D:
	var host := Node3D.new(); host.name = "Monitor"
	viz_anchor().add_child(host)
	host.position = Vector3(0.0, 0.45, 0.0) + stack   # screen centre above the board top
	var frame := _box(Vector3(0, 0, -0.018), Vector3(size.x + 0.05, size.y + 0.05, 0.03), _mat(body_color, 0.5, 0.3))
	frame.name = "Bezel"; host.add_child(frame)
	var screen := _box(Vector3(0, 0, 0.0), Vector3(size.x, size.y, 0.012), _mat(screen_bg, 0.25, 0.0))
	screen.name = "Screen"; host.add_child(screen)
	# HOOD / visor over the screen (the housed-display look).
	var hd := 0.15
	var hood := _box(Vector3(0, size.y * 0.5 + 0.04, hd * 0.45), Vector3(size.x + 0.07, 0.014, hd), _mat(body_color, 0.5, 0.3))
	hood.rotation_degrees.x = 16.0; hood.name = "Hood"; host.add_child(hood)
	for sx in [-1.0, 1.0]:
		var side := _box(Vector3(sx * (size.x * 0.5 + 0.024), size.y * 0.28, hd * 0.4), Vector3(0.014, size.y * 0.62, hd), _mat(body_color, 0.5, 0.3))
		side.name = "HoodSide"; host.add_child(side)
	if stack == Vector3.ZERO:
		# TOTEM — the monitor stands on its own floor column in front of the
		# console (cables ride the bridge duct, then hidden inside the column).
		_support_column(host, 0.0, -0.03, -size.y * 0.5 + 0.10, viz_floor - host.position.y, 0.10, 0.08)
		_apparatus_base(host, 0.5, 0.42, viz_floor - host.position.y)
	else:
		# LINK — a column tying the stacked monitor to the apparatus below. Runs
		# BEHIND the screens (z=-0.075, welded to the bezel backs) so it never
		# crosses the display below — visible only in the gap between monitors.
		_support_column(host, 0.0, -0.075, -size.y * 0.5 + 0.10, -size.y * 0.5 - stack.length() * 0.7, 0.10, 0.08)
	var content := Node3D.new(); content.name = "Content"
	content.position = Vector3(0, 0, 0.009)
	host.add_child(content)
	return content


## CUBE SPACE — a wireframe volume (default 1 m) for 3D content. Content root is
## at the cube CENTRE; place meshes within [-size/2, +size/2] on each axis.
func add_cube_space(size: float = 1.0) -> Node3D:
	var host := Node3D.new(); host.name = "CubeSpace"
	viz_anchor().add_child(host)
	host.position = Vector3(0.0, 0.35, 0.0)   # cube centre over the apparatus axis
	_wire_cube(host, size, viz_accent)
	var glass_floor := _box(Vector3(0, -size * 0.5 + 0.002, 0), Vector3(size, 0.004, size), _mat(Color(0.5, 0.6, 0.7, 0.10), 0.4, 0.0))
	(glass_floor.material_override as StandardMaterial3D).transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass_floor.name = "GlassFloor"; host.add_child(glass_floor)
	# FLOOR-STANDING PORTAL GANTRY — two pillars rise from the floor base past
	# the cube to a top beam (scanner-arch / spectrometer-frame form); a bottom
	# beam carries the volume. Cables ride the bridge duct into the pillars.
	var px := size * 0.5 + 0.045
	var y_floor := viz_floor - host.position.y
	for sx in [-1.0, 1.0]:
		_support_column(host, sx * px, 0.0, size * 0.5 + 0.06, y_floor, 0.08, 0.08)
	var frame_mat := _mat(body_color, 0.45, 0.35)
	var top_beam := _box(Vector3(0, size * 0.5 + 0.025, 0), Vector3(px * 2.0 + 0.08, 0.07, 0.08), frame_mat)
	top_beam.name = "GantryTopBeam"; host.add_child(top_beam)
	var bottom_beam := _box(Vector3(0, -size * 0.5 - 0.025, 0), Vector3(px * 2.0 + 0.08, 0.07, 0.08), frame_mat)
	bottom_beam.name = "GantryBottomBeam"; host.add_child(bottom_beam)
	_apparatus_base(host, px * 2.0 + 0.24, 0.5, y_floor)
	var content := Node3D.new(); content.name = "Content"
	host.add_child(content)
	return content


## 2D PLAN — a horizontal X-Z panel (top-down) for plan/layout content. Content
## root sits just above the panel; place things in its X-Z plane (origin centred,
## ±size/2), Y small.
func add_plan(size: Vector2 = Vector2(0.9, 0.7)) -> Node3D:
	var host := Node3D.new(); host.name = "PlanView"
	viz_anchor().add_child(host)
	host.position = Vector3(0.0, -0.05, 0.0)   # table height — you look down on it over the board
	var frame := _box(Vector3(0, -0.004, 0), Vector3(size.x + 0.03, 0.006, size.y + 0.03), _mat(body_color, 0.5, 0.3))
	frame.name = "PlanFrame"; host.add_child(frame)
	var pnl := _box(Vector3(0, 0, 0), Vector3(size.x, 0.01, size.y), _mat(screen_bg, 0.6, 0.0))
	pnl.name = "PlanPanel"; host.add_child(pnl)
	# PLAN TABLE — a floor pedestal carries the surface (cables ride the bridge
	# duct up the pedestal), with a rib spreading the load under the panel.
	_support_column(host, 0.0, 0.0, -0.01, viz_floor - host.position.y, 0.11, 0.09)
	var rib := _box(Vector3(0, -0.024, 0), Vector3(0.08, 0.026, size.y * 0.7), _mat(body_color, 0.5, 0.3))
	rib.name = "PlanRib"; host.add_child(rib)
	_apparatus_base(host, 0.5, 0.46, viz_floor - host.position.y)
	var content := Node3D.new(); content.name = "Content"
	content.position = Vector3(0, 0.008, 0)
	host.add_child(content)
	return content


## SPECIMEN JAR — a glass cylinder for a single specimen. Content root is the jar
## interior (origin at vertical centre); place a mesh within radius and ±height/2.
func add_specimen_jar(radius: float = 0.18, height: float = 0.5) -> Node3D:
	var host := Node3D.new(); host.name = "SpecimenJar"
	viz_anchor().add_child(host)
	host.position = Vector3(0.0, 0.25, 0.0)   # jar centre above the board top
	host.add_child(_cyl(Vector3(0, -height * 0.5 - 0.015, 0), radius * 1.15, 0.03, _mat(trim_color, 0.6, 0.2)))
	host.add_child(_cyl(Vector3(0, height * 0.5 + 0.012, 0), radius * 1.08, 0.025, _mat(trim_color, 0.5, 0.3)))
	var glass := _cyl(Vector3(0, 0, 0), radius, height, _mat(Color(0.62, 0.72, 0.82, 0.16), 0.1, 0.0))
	var gm := glass.material_override as StandardMaterial3D
	gm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	gm.cull_mode = BaseMaterial3D.CULL_DISABLED
	glass.name = "Glass"; host.add_child(glass)
	# SPECIMEN TANK — the surreal-lab form: a floor pedestal column carries a
	# platform disc, the glass tank on top (feed lines hidden inside the column).
	var plat := _cyl(Vector3(0, -height * 0.5 - 0.042, 0), radius * 1.35, 0.028, _mat(body_color, 0.5, 0.3))
	plat.name = "JarPlatform"; host.add_child(plat)
	var ped_top := -height * 0.5 - 0.05
	var ped_bottom := viz_floor - host.position.y
	var ped := _cyl(Vector3(0, (ped_top + ped_bottom) * 0.5, 0), 0.07, ped_top - ped_bottom, _mat(body_color, 0.45, 0.35))
	ped.name = "JarPedestal"; host.add_child(ped)
	_apparatus_base(host, 0.46, 0.46, ped_bottom)
	var content := Node3D.new(); content.name = "Content"
	host.add_child(content)
	return content


## 12 wireframe edges of a cube of side `size`, centred on `parent`.
func _wire_cube(parent: Node3D, size: float, col: Color) -> void:
	var h := size * 0.5
	var t := 0.008
	var mat := _mat(col, 0.4, 0.2)
	var signs := [-h, h]
	for sx in signs:
		for sz in signs:
			parent.add_child(_box(Vector3(sx, 0, sz), Vector3(t, size, t), mat))
	for sy in signs:
		for sz in signs:
			parent.add_child(_box(Vector3(0, sy, sz), Vector3(size, t, t), mat))
	for sy in signs:
		for sx in signs:
			parent.add_child(_box(Vector3(sx, sy, 0), Vector3(t, t, size), mat))


## CylinderMesh helper (like _box but cylindrical).
func _cyl(pos: Vector3, radius: float, height: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var c := CylinderMesh.new()
	c.top_radius = radius; c.bottom_radius = radius; c.height = height
	c.radial_segments = 32
	mi.mesh = c
	mi.position = pos
	mi.material_override = mat
	return mi


# ── The CSG cabinet: a floor-standing body with a slanted reading head ─────
func _build_body() -> void:
	if _built:
		return
	_built = true
	await get_tree().process_frame   # let the plate build + cell-fit settle
	await get_tree().process_frame

	# Measure the plate, then scale it DOWN to the (smaller) board that sits on
	# the slant. Absolute metres now — no whole-console rescale.
	var box := _local_aabb(_panel)
	var pw: float = maxf(0.001, box.size.x)
	var ph: float = maxf(0.001, box.size.y)
	var s: float = board_width / pw
	_panel.scale = Vector3.ONE * s
	var board_h: float = ph * s

	var t := deg_to_rad(tilt_deg)
	var face_n := Vector3(0.0, sin(t), cos(t))           # board face normal (reclined, faces up-forward)

	var head_w := board_width + bezel * 2.0
	# Extra length so the faceplate extends above the (downward-slid) board.
	var head_l := board_h + bezel * 2.0 + board_face_drop * 2.0   # length up the slant
	var head_t := 0.06

	# The head leans back from the top-front edge of the body at (0, body_height, 0).
	# Derived so the head's lower-front edge meets that point.
	var u_up := Vector3(0.0, cos(t), -sin(t))            # up-along-the-slant-face
	var head_c := Vector3(
		0.0,
		body_height + (head_l * 0.5) * cos(t) - (head_t * 0.5) * sin(t),
		-(head_l * 0.5) * sin(t) - (head_t * 0.5) * cos(t)
	)
	# Drop the head down the console + jut it forward, then slide it DOWN THE SLANT
	# (down-the-slope = down + forward, so the board moves "out a bit and then down").
	head_c += Vector3(0.0, -board_drop, board_out)
	head_c += -u_up * board_slide

	# The head's lower-front edge — the body rises to meet exactly this point, so the
	# metal stays continuous behind the board no matter how the head is offset.
	var lf := head_c + (head_t * 0.5) * face_n - (head_l * 0.5) * u_up

	# ── CSG cabinet: solid body welded (union) to the slanted reading head ──
	var body := CSGCombiner3D.new()
	body.name = "Body"
	add_child(body)

	# Body rises to meet the head's lower-front edge (lf) so the metal is continuous
	# behind the board — no float / notch — for any drop/out/slide. +0.02 overlaps
	# up into the head for a solid CSG seam.
	# Body rises exactly to the board's lower-front edge. Small 0.02 floor only to
	# avoid a degenerate/inverted box — NOT a 0.2 clamp, which used to over-grow a
	# short desktop body up over the board and swallow the controls.
	var body_top: float = maxf(0.02, lf.y)
	# mounting=kiosk is the shipped cabinet. lectern and wall build the same reading
	# head and simply do not raise the mass under it.
	if mounting == "kiosk":
		var base := CSGBox3D.new()
		base.name = "Base"
		base.size = Vector3(head_w, body_top + 0.02, body_depth)
		base.position = Vector3(0.0, (body_top + 0.02) * 0.5, lf.z - body_depth * 0.5)
		base.material = _mat(body_color, 0.5, 0.3)
		body.add_child(base)

	var head := CSGBox3D.new()
	head.name = "Head"
	head.size = Vector3(head_w, head_l, head_t)
	head.rotation_degrees = Vector3(-tilt_deg, 0.0, 0.0)
	head.position = head_c
	head.material = _mat(body_color, 0.45, 0.35)
	body.add_child(head)

	# Base plinth lip at the floor (dark trim) — aligned to the body's front.
	# The plinth closes a STANDING body's silhouette; a lectern closes its own with a
	# foot and a wall fitting never reaches the floor at all.
	var plinth: MeshInstance3D = null
	if mounting == "kiosk":
		plinth = _box(Vector3(0.0, 0.025, lf.z - body_depth * 0.5), Vector3(head_w + 0.08, 0.05, body_depth + 0.06), _mat(trim_color, 0.6, 0.2))
		plinth.name = "ConsolePlinth"
		add_child(plinth)

	# LECTERN — the reading head on splayed legs with a foot under it. Same face, same
	# board, same reach band; what is gone is the cabinet, and with it the claim that an
	# interface must also be a container. Legs go on `body` so they ride face_to_origin.
	if mounting == "lectern":
		var leg_mat := _mat(body_color, 0.5, 0.3)
		for sgn in [-1.0, 1.0]:
			var lx: float = float(sgn) * head_w * 0.34
			var leg := _box(Vector3(lx, body_top * 0.5, lf.z - body_depth * 0.34), Vector3(0.05, body_top, 0.05), leg_mat)
			leg.name = "LecternLeg"
			body.add_child(leg)
		var brace := _box(Vector3(0.0, body_top * 0.22, lf.z - body_depth * 0.34), Vector3(head_w * 0.62, 0.035, 0.035), leg_mat)
		brace.name = "LecternBrace"
		body.add_child(brace)
		var foot := _box(Vector3(0.0, 0.02, lf.z - body_depth * 0.34), Vector3(head_w * 0.82, 0.04, body_depth * 0.66), _mat(trim_color, 0.6, 0.2))
		foot.name = "LecternFoot"
		body.add_child(foot)

	# WALL — no body. A backplate flush behind the head, so the fitting reads as set
	# INTO a surface rather than hovering in front of one.
	if mounting == "wall":
		var backplate := _box(Vector3.ZERO, Vector3(head_w + 0.06, head_l + 0.06, 0.02), _mat(trim_color, 0.6, 0.2))
		backplate.name = "WallPlate"
		backplate.position = head_c - face_n * (head_t * 0.5 + 0.011)
		backplate.rotation_degrees = Vector3(-tilt_deg, 0.0, 0.0)
		body.add_child(backplate)

	# ── Small decoration: a cabinet door (+ pull handle) on the front, and a
	#    vent grille on the +X side. Added to `body` so they ride the face_to_origin
	#    shift. Scaled by body_top so they fit a short desk OR a tall floor cabinet.
	#    Both belong to the cabinet: there is nothing behind a lectern's legs to
	#    service, and nothing behind a wall fitting to open.
	if mounting == "kiosk" and has_door and body_top > 0.12:
		var dw: float = head_w * 0.66
		var dh: float = maxf(0.08, body_top * 0.72)
		var dcy: float = body_top * 0.47
		var door := _box(Vector3(0.0, dcy, lf.z + 0.006), Vector3(dw, dh, 0.012), _mat(body_color.darkened(0.07), 0.6, 0.25))
		door.name = "CabinetDoor"
		body.add_child(door)
		var handle := _box(Vector3(dw * 0.42, dcy, lf.z + 0.017), Vector3(0.012, dh * 0.5, 0.022), _mat(trim_color, 0.35, 0.45))
		handle.name = "DoorHandle"
		body.add_child(handle)
	if mounting == "kiosk" and has_vent and body_top > 0.12:
		var vx: float = head_w * 0.5 + 0.002
		var vcy: float = body_top * 0.74
		var vz: float = lf.z - body_depth * 0.42
		var vlen: float = body_depth * 0.34
		var recess := _box(Vector3(vx, vcy, vz), Vector3(0.006, 0.072, vlen), _mat(Color(0.05, 0.05, 0.06), 0.95, 0.0))
		recess.name = "VentRecess"
		body.add_child(recess)
		for i in 4:
			var sy: float = vcy - 0.024 + float(i) * 0.016
			var slat := _box(Vector3(vx + 0.004, sy, vz), Vector3(0.004, 0.006, vlen * 0.86), _mat(body_color, 0.5, 0.3))
			slat.name = "VentSlat_%d" % i
			body.add_child(slat)

	# ── Mount the (scaled) board on the slanted face, slid down so the faceplate
	#    shows metal above it (nestled into the body, not perched on top). ──────
	_panel.rotation_degrees = Vector3(-tilt_deg, 0.0, 0.0)
	_panel.position = head_c + face_n * (head_t * 0.5 + 0.012) - u_up * board_face_drop

	# DESKTOP form: shift the whole console down so the reading FACE sits at the
	# node origin. Then an artifact can place it at table height (like the old
	# flat plate) without raising its visualization — the body becomes a short
	# stand below. (Floor-standing form leaves face_to_origin off.)
	if face_to_origin:
		var dy: float = head_c.y
		body.position.y -= dy
		if plinth != null:
			plinth.position.y -= dy
		_panel.position.y -= dy


func _local_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var inv := node.global_transform.affine_inverse()
	var stack: Array = [node]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is VisualInstance3D:
			var ab: AABB = (n as VisualInstance3D).get_aabb()
			var xf: Transform3D = inv * (n as Node3D).global_transform
			for j in 8:
				var p: Vector3 = xf * ab.get_endpoint(j)
				if first:
					box = AABB(p, Vector3.ZERO); first = false
				else:
					box = box.expand(p)
		for c in n.get_children():
			stack.append(c)
	return box


func _box(pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = size
	mi.mesh = b
	mi.position = pos
	mi.material_override = mat
	return mi


func _mat(c: Color, rough: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = metal
	m.roughness = rough
	return m
