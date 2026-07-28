extends Node3D
class_name XYZSliderPlate

# @identity
# essence: three sliders (X, Y, Z) that move a point through a visible coordinate frame — coordinates made tangible, and the axes the point moves along made literal
# desire: learner builds the intuition that position = three independent numbers by moving each axis alone, AND sees the geometric coordinate frame the numbers refer to
# critical_parameter: the live coordinate display — numbers change as sliders move, connecting gesture to math; panel_scale sizes the controls for VR-hand comfort
# triggers: each slider controls one axis; the point moves in real-time inside the embedded CoordinateSystem3M frame; label updates continuously
# emerges: axis independence — moving X doesn't change Y; the three dimensions are orthogonal AND visually distinct (X red, Y green, Z blue)
# needs: slider_horizontal [has]; Label3D [has]; target point [has]; CoordinateSystem3M embedded for visible axes [present, 2026-05-19]; VR-hand-sized controls [present, 2026-05-19]
# relationships: complements interactive_point_origin (grab = all axes at once); embeds CoordinateSystem3M as visual reference frame; this separates the three independent measurements while still showing them in their shared frame
# truth: a coordinate is three independent measurements — the slider plate makes independence visible AND the frame they measure in geometric

## Dieter Rams plate with X, Y, Z sliders that drive a visible point.
## The point is a glowing sphere that moves in world space as you adjust sliders.
## Coordinate label updates live. Uses RackTemplates for the Rams aesthetic.

const HangarKit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")

# ─────────────────────────────────────────────────────────────────────────────
# STAGE-2 DNA PROMOTION (2026-07-27) — THE KIN PAIR AXIS.
# Twin file: commons/primitives/line/line.gd. One vocabulary, two apparatuses.
#
# These two are the project's most basic machines: a plate you drag a point
# around on, and a line you pull between two hands. They are not furniture, so
# the corpus's usual promotion axes (what the housing is made of, which
# institution it belongs to) are the wrong question here — this thing has a
# crank on it. The right question is EPISTEMIC, and both identity blocks
# already ask it out loud:
#
#   xyz_slider_plate  critical_parameter: "the live coordinate display —
#                     numbers change as sliders move, connecting gesture to math"
#   line              critical_parameter: "the glitch/haptic resistance when
#                     length is near an integer — whole numbers resist"
#
# Both name the same thing from two sides: WHAT THE APPARATUS TELLS YOU ABOUT
# THE VALUE YOU ARE SETTING. So the axis is `readout`, and it is one ordered
# ladder, monotone in evidence:
#
#   none  <  numeral (legacy default)  <  gradation  <  lattice
#
#   none       nothing. No reference frame, no tether from the origin, no
#              number: a glowing dot and three handles in an empty room. You
#              move it and the world says nothing back. A coordinate is a
#              feeling in the hand.
#   numeral    the reference frame is standing and the console's lit pocket
#              prints (1.50, 1.50, 1.50) — a number, and you take its word for
#              it. This is what all 35 placements have rendered.
#   gradation  the number, plus a graduated ground to check it against: three
#              ruled rails standing off the X/Y/Z axes, running the whole
#              VISIBLE length of the frame, numbered at every station, with a
#              bright REACH collar at max_value where the sliders actually
#              stop — plus the coordinate STAIRCASE, three axis-parallel legs
#              from the origin to the point whose lengths ARE x, y and z. Two
#              claims: the number is a position on a public scale, and it
#              decomposes exactly the way the truth line says it does.
#   lattice    all of that, plus the privileged set drawn: a node at every
#              whole-number triple across the graduated extent, with the three
#              coordinate-plane grids wired between them. The claim: your
#              continuous point is one dot in a countable set the apparatus
#              treats as clean. This is the LINE's claim ("the privilege of
#              whole numbers") imported into the plate, which is why the pair
#              shares one word.
#
# WHY NOT A RATE. The tempting knob on a machine is always its speed, and this
# file has plenty (update cadence, glitch decay on the twin). A still cannot
# see any of them — info_board was swept across all five of its duration
# exports and produced six identical tiles. Every rung above is FORM: bars,
# teeth, glyphs, nodes, one frame standing or absent.
#
# THE RUNGS ARE SIZED TO THE FRAME, NOT TO THE HAND. Every dimension below is a
# RATIO of the graduated extent rather than a metre. That is not tidiness: this
# artifact is captured whole, and "whole" here means a ~12 m coordinate frame
# (the latent scale bug documented on coord_system_scale), so a 5 mm tick would
# be a third of a pixel and the axis would report inert for reasons that have
# nothing to do with its design. At the honest 4 m workspace the same ratios
# give a 12 cm blade and 40 cm teeth, which is right for a body standing in it.
#
# WHAT IS NOT ROUTED THROUGH IT. No rung RESTYLES the embedded CoordinateSystem3M
# — it is another artifact and it keeps its own look. Rung 0 does SUPPRESS it,
# which is a different act and an argued one: the frame is the apparatus that
# makes a position legible at all, so an instrument committing to nothing cannot
# keep it. Rungs 1-3 leave it exactly as it stands today. Nor does any rung
# change a number the machine computes: the sliders map through the same
# _norm_to_val(), the point lands in the same place, and the printed string is
# character-for-character what it always was.
#
# WHAT IT COST. Rung 0 overrides two older knobs, `line_to_origin` and
# `show_coordinate_system`, so three switches now speak about the same subject.
# That is deliberate: a rod drawn from the origin to the point is a readout (the
# crudest one, a magnitude asserted geometrically) and a labelled axis frame is
# a readout (the most basic one, a reference), and an apparatus that commits to
# nothing can keep neither. The rung wins at `none`; the older bools govern
# rungs 1-3 exactly as before.
# ─────────────────────────────────────────────────────────────────────────────

@export_group("Housing")
## Cabinet grammar (vertical dialect, body = "slider lectern"). The slider panel
## used to hang in mid-air at waist height with nothing beneath it; the lectern
## is the body it stands on, so the interface is part of an object rather than a
## floating widget. Set false to recover the old bare-panel behaviour.
@export var console_body: bool = true
@export var finish: String = "terminal"
@export var wear: float = 0.10
@export var unit_code: String = "XY-03"
## The billboard coordinate readout that used to hover above the moving point.
## Off by default: text belongs to the body (G1), and the lectern's own readout
## carries the same numbers. Set true to restore the in-place label.
@export var billboard_coords: bool = false

@export_group("Range")
## Workspace coordinate range. Default 0..4 aligns with CoordinateSystem3M's
## one-sided axes (+X +Y +Z from origin), so the point moves in a 4m cube
## that is exactly bounded by the visible axes. Each axis becomes the
## boundary of its slider's range.
@export var min_value: float = 0.0
@export var max_value: float = 4.0
## Where the point first appears. Default puts it in the visible positive
## octant, well away from the panel where the player's hands are.
@export var start_position: Vector3 = Vector3(1.5, 1.5, 1.5)

@export_group("Point Appearance")
## Larger radius — at 4m range the point can be 2-3m from the player, so it
## must be visible at distance. ~5cm sphere reads cleanly across the workspace.
@export var point_radius: float = 0.06
@export var point_color: Color = Color(0.3, 0.8, 1.0)  # cyan
@export var line_to_origin: bool = true

@export_group("Readout")
## AXIS — what the apparatus commits to about the coordinate you are setting.
## One ordered ladder, monotone in evidence. Rung 0 says nothing; rung 1 says a
## number; rung 2 puts that number on a public scale; rung 3 draws the values
## the apparatus counts as clean. Shared verbatim with the twin primitive,
## commons/primitives/line/line.gd — see the promotion block at the top.
##   none < numeral (legacy default) < gradation < lattice
## Anything unrecognised builds as `numeral`, NOT as `none`: a typo must not
## silently delete the readout from a live room.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "numeral"

@export_group("Display")
@export var panel_tilt: float = -25.0  # degrees, angled toward player
## Default puts the panel at waist height (1.0m) just outside the +Z corner
## of the 4m workspace cube — the player stands further out, reaching toward
## the panel while looking past it into the coordinate frame.
@export var panel_offset: Vector3 = Vector3(0, 1.0, 4.5)
## VR-hand-size scale for the slider panel. 1.0 = standard rack-panel size
## (~4cm controls). 2.0 = chunky for VR hands AND legible against the 4m axes.
@export var panel_scale: float = 2.0

@export_group("Coordinate System")
## Embed a CoordinateSystem3M (X red / Y green / Z blue axes) inside the
## workspace so the point can be seen moving through a visible coordinate frame.
@export var show_coordinate_system: bool = true
## Scale applied to the embedded coordinate system. CoordinateSystem3M is 3m
## native × 0.5 self-scale = 1.5m effective. coord_system_scale = 2.67 gives
## ≈ 4m axes — matching the default workspace range, so each axis is exactly
## the boundary of its slider. The whole frame stands on the ground (artifact
## root at y=0) with the Y axis rising 4m straight up.
##
## LATENT, FOUND 2026-07-27 DURING THE DNA PASS, REPORTED NOT FIXED. The
## paragraph above is no longer true. CoordinateSystem3M.gd:33 now reads
## `@export var display_scale: float = 1.5` — it self-scales to 1.5, not 0.5 —
## so the embedded frame is 3.0 × 1.5 × 2.67 ≈ 12 m, three times the workspace,
## and the point can never leave the innermost third of the visible axes. The
## claim "each axis is exactly the boundary of its slider" is false in every one
## of the 35 rooms this stands in. Left alone on purpose: the correct value is
## coord_system_scale ≈ 0.89, and changing it would move the whole subject in
## every live placement, which is not a DNA promotion's business. The
## `gradation` rung below is drawn at the SLIDERS' range, not the frame's, so it
## quietly shows the discrepancy rather than inheriting it.
@export var coord_system_scale: float = 2.67

# ── the readout vocabulary (canon for the kin pair) ──────────────────────────
#
# This file owns the vocabulary and line.gd parses through readout_name() here,
# so one word means one thing on both primitives and the two lists cannot drift
# apart the way `house`/`regard` and `guard`/`lit` did in the exhibits family.
# The dependency runs one way only: line.gd -> XYZSliderPlate -> HangarKit, and
# HangarKit is a class_name global that the project already parses.

## Spellings the axis answers to. None of these is canon — the canon is the
## @export_enum above — but an author reaching for "ticks" or "bare" should get
## the rung they meant instead of the silent legacy fallback. Also closes the
## whitespace/case hole the exhibits pass found: `#readout: Rule ` parses.
const READOUT_ALIASES := {
	"plain": "none", "bare": "none", "blank": "none", "off": "none",
	"number": "numeral", "figure": "numeral", "digit": "numeral",
	"tick": "gradation", "ticks": "gradation", "rule": "gradation",
	"grid": "lattice", "integer": "lattice", "integers": "lattice",
}

## The pair's one reader for a readout token. Static so line.gd calls THIS,
## rather than keeping a private copy that will eventually disagree.
static func readout_name(raw: String) -> String:
	var v: String = raw.strip_edges().to_lower()
	return str(READOUT_ALIASES.get(v, v))

# Geometry of the graduated ground, every value a RATIO of the graduated extent
# (see _readout_extent). At the frame's real ~12 m that gives a 36 cm blade and
# 1.2 m teeth — coarse in the hand, but this artifact is captured whole and a
# centimetre tick at that framing is a third of a pixel. At a bare 4 m workspace
# the same ratios give a 12 cm blade and 40 cm teeth, which is body scale.
const RAIL_OFFSET_R := 0.028     # how far off-axis the rule stands, clear of the frame's own rods
const RAIL_BLADE_R := 0.030      # the rule's flat width
const RAIL_THICK_R := 0.010
const TOOTH_MINOR_R := 0.045
const TOOTH_MAJOR_R := 0.100     # the numbered stations
const TOOTH_SECTION_R := 0.012
const REACH_R := 0.055           # the collar marking where the sliders actually stop
const STAIR_T_R := 0.015         # the coordinate staircase's square section
const LATTICE_NODE_R := 0.022    # a whole-number station, drawn
const LATTICE_WIRE_R := 0.008
const GLYPH_R := 0.0016          # Label3D pixel_size per unit of extent, at font 48
## Roughly how many numbered stations a rail carries. Six reads as a scale; two
## reads as an accident and twenty reads as noise.
const RAIL_STATIONS := 6
## Per-axis cap on lattice stations. The default 0..4 workspace gives 5 (125
## nodes); a map that sets min_value -50 / max_value 50 would otherwise ask for
## a million boxes, so the lattice thins its step instead of exploding.
const LATTICE_MAX_STATIONS := 7

const AXIS_RED := Color(1.00, 0.30, 0.30)
const AXIS_GREEN := Color(0.30, 1.00, 0.35)
const AXIS_BLUE := Color(0.35, 0.55, 1.00)
const LATTICE_TINT := Color(0.86, 0.92, 1.00)

# Internal
var _gradation: Node3D          # the three ruled rails + their numerals
var _lattice: Node3D            # the integer nodes + the coordinate-plane wires
var _stair_x: MeshInstance3D    # the coordinate staircase: three axis-parallel legs
var _stair_y: MeshInstance3D
var _stair_z: MeshInstance3D
var _stair_knee_a: MeshInstance3D
var _stair_knee_b: MeshInstance3D
var _stair_t: float = 0.07      # leg section, set from the extent at build time
var _panel: Node3D
var _slider_x: Node
var _slider_y: Node
var _slider_z: Node
var _point_mesh: MeshInstance3D
var _point_material: StandardMaterial3D
var _coord_label: Label3D       # billboard above point
var _display_label: Label3D     # Rams text display on panel
var _display_container: Node3D
var _origin_line: MeshInstance3D
var _origin_cylinder: CylinderMesh
var _origin_line_mat: StandardMaterial3D
var _coord_system: Node3D    # embedded CoordinateSystem3M (visual axis frame)
var _current_pos: Vector3


func _ready() -> void:
	_read_readout()
	_current_pos = start_position
	_build_point()
	_build_coord_label()
	# Rung 0 overrides the two older switches. The rod from the origin to the
	# point is a readout (a magnitude asserted geometrically) and the embedded
	# frame is a readout (the reference that makes a position legible at all), so
	# an apparatus that commits to nothing can keep neither. Rungs 1-3 leave both
	# bools in charge exactly as before — `readout != "none"` is true for all 35
	# existing placements, so both lines read as they always did.
	if line_to_origin and readout != "none":
		_build_origin_line()
	if show_coordinate_system and readout != "none":
		_build_coordinate_system()    # embed CoordinateSystem3M visual axes
	_build_panel()
	_build_readout()
	_update_point()


## The token read, and it has to happen HERE rather than in apply_grid_config.
## GridInteractablesComponent sets every `#key:value` as `config_<key>` metadata
## BEFORE the artifact enters the tree (_apply_artifact_config, ~line 1575) and
## only calls apply_grid_config a frame LATER via call_deferred — so a knob that
## SHAPES the build is one frame too late if it is read there. Metadata is also
## how the sibling primitive receives the token, since its scene root carries no
## script at all (see the LATENT note in line.gd).
##
## A value set directly on the @export (the property path the sweep harness
## uses: capture_config_sweep.gd sets exports before add_child) is left alone
## except for normalisation, so both paths land on the same rung.
func _read_readout() -> void:
	var raw: String = readout
	if has_meta("config_readout"):
		raw = str(get_meta("config_readout"))
	elif has_meta("readout"):
		raw = str(get_meta("readout"))
	readout = readout_name(raw)


func _process(_delta: float) -> void:
	_read_sliders()
	_update_point()


# ── Point ────────────────────────────────────────────────────────────

func _build_point() -> void:
	_point_mesh = MeshInstance3D.new()
	_point_mesh.name = "TargetPoint"
	var sphere := SphereMesh.new()
	sphere.radius = point_radius
	sphere.height = point_radius * 2.0
	sphere.radial_segments = 16
	sphere.rings = 8
	_point_mesh.mesh = sphere
	_point_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_point_material = StandardMaterial3D.new()
	_point_material.albedo_color = point_color
	_point_material.emission_enabled = true
	_point_material.emission = point_color
	_point_material.emission_energy_multiplier = 1.5
	_point_mesh.material_override = _point_material
	add_child(_point_mesh)


func _build_coord_label() -> void:
	if not billboard_coords:
		return
	_coord_label = Label3D.new()
	_coord_label.name = "CoordLabel"
	_coord_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_coord_label.font_size = 32
	_coord_label.pixel_size = 0.001
	_coord_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	_coord_label.outline_size = 4
	_coord_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	add_child(_coord_label)


func _build_origin_line() -> void:
	_origin_line = MeshInstance3D.new()
	_origin_line.name = "OriginLine"
	_origin_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	_origin_cylinder = CylinderMesh.new()
	# Thicker line — the workspace is now up to 4m across, a hairline
	# wouldn't be visible at distance.
	_origin_cylinder.top_radius = 0.012
	_origin_cylinder.bottom_radius = 0.012
	_origin_cylinder.radial_segments = 8
	_origin_cylinder.rings = 1
	_origin_line.mesh = _origin_cylinder

	_origin_line_mat = StandardMaterial3D.new()
	_origin_line_mat.albedo_color = Color(point_color, 0.5)
	_origin_line_mat.emission_enabled = true
	_origin_line_mat.emission = point_color
	_origin_line_mat.emission_energy_multiplier = 0.6
	_origin_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_origin_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_origin_line.material_override = _origin_line_mat
	add_child(_origin_line)


# ── Coordinate system embed ──────────────────────────────────────────

func _build_coordinate_system() -> void:
	# Load CoordinateSystem3M scene and add it as a child of XYZSliderPlate.
	# It self-scales to 0.5 in its own _ready() — we wrap it in a Node3D so
	# we can apply an additional scale (coord_system_scale) without fighting
	# its self-scale logic.
	var scene := load("res://algorithms/vectors/00_coordinates/CoordinateSystem3M.tscn")
	if not scene:
		push_warning("XYZSliderPlate: CoordinateSystem3M.tscn missing")
		return
	var wrapper := Node3D.new()
	wrapper.name = "CoordinateAxes"
	# THE PHENOMENON, not the interface. Its axis tick labels ("X", "Y", "Z", the
	# unit marks) are pinned to axis geometry 4 m out — they belong to the measured
	# frame, exactly as the dice and balls belong to their own artifacts. Marked so
	# the grammar's no-orphan-text rule measures the interface, not the subject.
	wrapper.set_meta("phenomenon", true)
	wrapper.scale = Vector3.ONE * coord_system_scale
	add_child(wrapper)
	_coord_system = scene.instantiate()
	if _coord_system:
		wrapper.add_child(_coord_system)


# ── Panel ────────────────────────────────────────────────────────────

func _build_panel() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var RackPassive: GDScript = load("res://commons/interactables/RackPassiveElements.gd")
	var x_norm := _val_to_norm(start_position.x)
	var y_norm := _val_to_norm(start_position.y)
	var z_norm := _val_to_norm(start_position.z)

	# Frameless when housed: the lectern's wedge shoulder IS the faceplate, and the
	# cap's sign band already says COORDINATES. RackTemplates' _add_panel ships a
	# cream plate and a copper accent strip (0.75,0.38,0.13) that reads as a second
	# manufacturer once the panel sits inside this body (G4).
	_panel = RackTpl.create_panel("" if console_body else "COORDINATES", [
		[{"type": "slider_h", "label": "X", "default": x_norm}],
		[{"type": "slider_h", "label": "Y", "default": y_norm}],
		[{"type": "slider_h", "label": "Z", "default": z_norm}],
	], console_body)
	# Scale up for VR-hand-comfortable controls
	_panel.scale = Vector3.ONE * panel_scale

	if console_body:
		# The panel is seated on a lectern that stands on the floor; the readout
		# is seated in the lectern's backboard. _build_console() parents both.
		_build_console(RackPassive)
	else:
		_panel.position = panel_offset
		_panel.rotation_degrees.x = panel_tilt
		add_child(_panel)
		# rung 0 gets no strip at all — a bare-panel plate with three handles and
		# nothing that says what they mean
		if readout != "none":
			_display_container = Node3D.new()
			_display_container.name = "CoordDisplay"
			_display_container.position = Vector3(0, 0.16, 0.006)
			_panel.add_child(_display_container)
			RackPassive.build_text_display_static(_display_container, 1, "(0.00, 0.00, 0.00)")
			_display_label = _display_container.find_child("TextContent", true, false) as Label3D

	# Find sliders by child index (Param_0, Param_1, Param_2)
	_slider_x = _panel.find_child("Param_0", true, false)
	_slider_y = _panel.find_child("Param_1", true, false)
	_slider_z = _panel.find_child("Param_2", true, false)

	# Connect signals
	if _slider_x and _slider_x.has_signal("slider_moved"):
		_slider_x.slider_moved.connect(_on_slider_changed)
	if _slider_y and _slider_y.has_signal("slider_moved"):
		_slider_y.slider_moved.connect(_on_slider_changed)
	if _slider_z and _slider_z.has_signal("slider_moved"):
		_slider_z.slider_moved.connect(_on_slider_changed)

	# Color the slider labels to match axis colors
	_color_slider_label(_slider_x, Color(1.0, 0.3, 0.3))  # X = red
	_color_slider_label(_slider_y, Color(0.3, 1.0, 0.3))  # Y = green
	_color_slider_label(_slider_z, Color(0.3, 0.5, 1.0))  # Z = blue


## THE LECTERN. A body for the sliders to stand on: a column from the floor up to
## the working height, a wedge shoulder the panel is seated on, and a backboard
## carrying the coordinate readout in a milled pocket under a sign band. Built at
## panel_offset's x/z so the console stands where the panel used to hover, and the
## player still reads past it into the coordinate frame.
func _build_console(RackPassive: GDScript) -> void:
	var pal: Dictionary = HangarKit.finish_palette(finish)
	var col_body: Color = pal["body"]
	var col_accent: Color = pal["accent"]
	var shell: StandardMaterial3D = HangarKit.finish_body(finish, col_body, wear)
	var steel: StandardMaterial3D = HangarKit.worn_metal(col_body.lightened(0.10))
	var dark: StandardMaterial3D = HangarKit.painted_metal(
		Color(0.07, 0.075, 0.09), wear, 0.35, 0.55)
	var accent: StandardMaterial3D = HangarKit.emissive(col_accent, 2.2)

	# Panel footprint in world metres (RackTemplates records its own size).
	var pw: float = float(_panel.get_meta("panel_w", 0.22)) * panel_scale
	var ph: float = float(_panel.get_meta("panel_h", 0.30)) * panel_scale
	var body_w: float = pw + 0.10
	var body_d: float = maxf(ph * 0.55, 0.30)
	var work_h: float = maxf(panel_offset.y, 0.80)   # slider height above floor

	var cab := Node3D.new()
	cab.name = "Cabinet"
	cab.set_meta("housing", true)
	cab.position = Vector3(panel_offset.x, 0.0, panel_offset.z)
	add_child(cab)

	var face_z: float = body_d * 0.5

	# column — the mass that reaches the floor (G2)
	cab.add_child(HangarKit.box(
		Vector3(0, work_h * 0.5, 0), Vector3(body_w, work_h, body_d), shell))
	# recessed toe kick + grime where it meets the floor
	cab.add_child(HangarKit.box(
		Vector3(0, 0.028, 0), Vector3(body_w - 0.10, 0.056, body_d - 0.10), dark))
	var gb: MeshInstance3D = HangarKit.grime_band(body_w * 0.88, 0.05, face_z + 0.003, col_body)
	if gb:
		gb.position.y = 0.072
		cab.add_child(gb)
	# side flanks
	for sx in [-1.0, 1.0]:
		cab.add_child(HangarKit.box(
			Vector3(sx * (body_w * 0.5 + 0.016), work_h * 0.5, 0.0),
			Vector3(0.032, work_h, body_d + 0.018), steel))
	# ember line under the working lip (G7)
	cab.add_child(HangarKit.box(
		Vector3(0, work_h - 0.012, face_z + 0.004),
		Vector3(body_w * 0.98, 0.007, 0.006), accent))
	# asset code stencilled on the column
	var code: MeshInstance3D = HangarKit.stencil(
		unit_code, Vector2(0.10, 0.026), col_accent.lightened(0.25))
	if code:
		code.position = Vector3(-body_w * 0.5 + 0.09, work_h - 0.10, face_z + 0.004)
		cab.add_child(code)

	# wedge shoulder — the sloped shelf the slider panel rests on, so the
	# controls meet the body instead of hanging in air
	var shoulder: MeshInstance3D = HangarKit.wedge(
		body_w * 0.94, 0.10, body_d * 0.92, body_d * 0.30, steel)
	if shoulder:
		shoulder.position = Vector3(0.0, work_h + 0.04, -body_d * 0.42)
		cab.add_child(shoulder)

	# seat the panel on the shoulder, keeping its authored rake. Imported panels
	# ship Braun cream + copper; harmonize before seating so the controls speak
	# this body's palette (the X/Y/Z label colours are saturated and survive).
	_panel.position = Vector3(0.0, work_h + 0.10, face_z * 0.10)
	_panel.rotation_degrees.x = panel_tilt
	HangarKit.harmonize(_panel, finish)
	cab.add_child(_panel)

	# Backboard rising behind the sliders — carries the readout and the sign. It
	# must CLEAR the seated panel, which is panel_scale times its authored size:
	# sized from the panel's real height, or the sliders hide the readout.
	var clear: float = ph * 0.55 + 0.06
	var back_h: float = clear + 0.30
	var back_y: float = work_h + back_h * 0.5
	var back_z: float = -body_d * 0.5 + 0.035
	cab.add_child(HangarKit.box(
		Vector3(0, back_y, back_z), Vector3(body_w, back_h, 0.07), shell))
	# cap + sign band baked flush into it (G1: the title is part of the body)
	cab.add_child(HangarKit.box(
		Vector3(0, work_h + back_h + 0.026, back_z),
		Vector3(body_w + 0.04, 0.052, 0.10), steel))
	var sign: MeshInstance3D = HangarKit.stencil(
		"COORDINATES", Vector2(body_w * 0.80, 0.028), col_accent.lightened(0.35))
	if sign:
		sign.position = Vector3(0, work_h + back_h + 0.026, back_z + 0.052)
		cab.add_child(sign)

	# readout seated in a milled pocket on the backboard: pocket, lit face,
	# canonical glass, ember lip — then the live Label3D reads against it.
	#
	# AXIS `readout`, rung 0: at `none` the pocket is never milled. The backboard
	# and its COORDINATES sign band stay (that is the body naming itself, G1, not
	# a readout), but the console's one emissive feature goes out and the machine
	# stops telling you what you set. That single unlit rectangle is the whole
	# difference between an instrument and a handle.
	if readout != "none":
		var scr_w: float = body_w * 0.78
		var scr_h: float = 0.15
		var scr_y: float = work_h + clear + 0.14      # above the panel it reports on
		var scr_z: float = back_z + 0.035
		cab.add_child(HangarKit.box(
			Vector3(0, scr_y, scr_z + 0.002), Vector3(scr_w + 0.026, scr_h + 0.030, 0.014), dark))
		cab.add_child(HangarKit.box(
			Vector3(0, scr_y, scr_z + 0.009),
			Vector3(scr_w, scr_h, 0.005), HangarKit.emissive(pal["screen"], 0.45)))
		var glass := StandardMaterial3D.new()
		glass.albedo_color = Color(0.04, 0.05, 0.08)
		glass.roughness = 0.15
		glass.emission_enabled = true
		glass.emission = Color(0.05, 0.08, 0.12)
		glass.emission_energy_multiplier = 0.5
		cab.add_child(HangarKit.box(
			Vector3(0, scr_y, scr_z + 0.0135), Vector3(scr_w, scr_h, 0.004), glass))
		cab.add_child(HangarKit.box(
			Vector3(0, scr_y + scr_h * 0.5 + 0.010, scr_z + 0.011),
			Vector3(scr_w + 0.026, 0.005, 0.005), accent))

		_display_container = Node3D.new()
		_display_container.name = "CoordDisplay"
		_display_container.position = Vector3(0, scr_y, scr_z + 0.020)
		cab.add_child(_display_container)
		RackPassive.build_text_display_static(_display_container, 1, "(0.00, 0.00, 0.00)")
		_display_label = _display_container.find_child("TextContent", true, false) as Label3D


# ── Readout ──────────────────────────────────────────────────────────────────
#
#   none  <  numeral  <  gradation  <  lattice
#
# Rungs 0 and 1 are decided upstream: rung 0 skips the frame (_ready), the
# origin rod (_ready) and the console's lit pocket (_build_console); rung 1 is
# the lineage. Rungs 2 and 3 ADD to the workspace and are built here. Nothing
# below this line executes on the legacy path — the match falls straight
# through for "numeral" and every handle stays null.

func _build_readout() -> void:
	match readout:
		"none":
			pass                      # rung 0 — subtractions only, all made upstream
		"numeral":
			pass                      # rung 1 — the legacy lineage, 35 rooms
		"gradation":
			_build_gradation()
		"lattice":
			_build_gradation()
			_build_lattice()
		_:
			pass                      # an unrecognised word reads as the legacy numeral


## How far the graduated ground runs. A rule should graduate the space the
## player can SEE, not only the interval the sliders can reach — and on this
## artifact those two are not the same: the embedded frame draws ~12 m of axis
## while the sliders stop at 4 (the latent scale bug documented on
## coord_system_scale). Rather than hide that, the rails run the whole visible
## axis and plant a REACH collar where the instrument actually stops, so the gap
## between what is shown and what can be set becomes a thing you can point at.
## With no frame embedded the rails simply end at max_value, which is the honest
## answer in that case too.
func _readout_extent() -> float:
	var hi: float = maxf(min_value, max_value)
	if _coord_system == null:
		return hi
	var axis_len: float = 0.0
	var self_scale: float = 1.0
	var a: Variant = _coord_system.get("axis_length")
	if a is float or a is int:
		axis_len = float(a)
	var s: Variant = _coord_system.get("display_scale")
	if s is float or s is int:
		self_scale = float(s)
	if axis_len <= 0.0 or self_scale <= 0.0:
		return hi
	return maxf(hi, axis_len * self_scale * coord_system_scale)


## A step that lands on 1, 2 or 5 times a power of ten, so the numbered stations
## read as a scale a person would draw rather than as span/6.
func _nice_step(span: float, target: int) -> float:
	var raw: float = maxf(span / float(maxi(target, 1)), 0.0001)
	var mag: float = pow(10.0, floor(log(raw) / log(10.0)))
	var n: float = raw / mag
	var mult: float = 1.0
	if n > 5.0:
		mult = 10.0
	elif n > 2.0:
		mult = 5.0
	elif n > 1.0:
		mult = 2.0
	return mult * mag


## RUNG 2 — the number put on a public scale. Three ruled rails standing off the
## X, Y and Z axes across the whole graduated extent, numbered at roughly six
## stations each, with a bright collar at max_value marking where the sliders
## stop; plus the coordinate staircase.
func _build_gradation() -> void:
	var lo: float = minf(min_value, max_value)
	var hi: float = maxf(min_value, max_value)
	var outer: float = _readout_extent()
	if outer - lo < 0.01:
		return                        # a zero-width scale has nothing to graduate
	_gradation = Node3D.new()
	_gradation.name = "Gradation"
	# The rails and their numerals belong to the MEASURED FRAME, like the embedded
	# coordinate axes — not to the console. Marked so the cabinet grammar's
	# no-orphan-text rule keeps measuring the interface, not the subject.
	_gradation.set_meta("phenomenon", true)
	add_child(_gradation)
	var off: float = outer * RAIL_OFFSET_R
	_build_rail(Vector3.RIGHT, Vector3(0.0, outer * 0.002, -off), Vector3.BACK,
			AXIS_RED, lo, hi, outer)
	_build_rail(Vector3.UP, Vector3(-off, 0.0, -off), Vector3.RIGHT,
			AXIS_GREEN, lo, hi, outer)
	_build_rail(Vector3.BACK, Vector3(-off, outer * 0.002, 0.0), Vector3.RIGHT,
			AXIS_BLUE, lo, hi, outer)
	_build_stair(outer)


## One graduated rail: a blade running `along` the axis, standing off it at
## `base`, with teeth growing back toward the axis in `teeth`. Short tooth at
## every half-station, long tooth plus a numeral at every station, and a fat
## emissive collar at `reach` — the last value the sliders can produce.
func _build_rail(along: Vector3, base: Vector3, teeth: Vector3, tint: Color,
		lo: float, reach: float, outer: float) -> void:
	var span: float = outer - lo
	var blade_w: float = outer * RAIL_BLADE_R
	var blade_t: float = outer * RAIL_THICK_R
	var sect: float = outer * TOOTH_SECTION_R
	var blade: StandardMaterial3D = _readout_mat(tint.darkened(0.45), 0.55)
	var mark: StandardMaterial3D = _readout_mat(tint, 1.8)
	_readout_box(_gradation, _section(along, span, teeth, blade_w, blade_t),
			base + along * (lo + span * 0.5), blade)
	var major: float = _nice_step(span, RAIL_STATIONS)
	var minor: float = major * 0.5
	var steps: int = int(floor(span / minor + 0.0001))
	for i in range(steps + 1):
		var d: float = lo + float(i) * minor
		var numbered: bool = absf(d / major - round(d / major)) < 0.001
		var length: float = outer * (TOOTH_MAJOR_R if numbered else TOOTH_MINOR_R)
		_readout_box(_gradation,
				_section(teeth, length, along, sect, sect * 0.5),
				base + along * d + teeth * (blade_w * 0.5 + length * 0.5), mark)
		if not numbered:
			continue
		var glyph := Label3D.new()
		glyph.text = ("%d" % int(round(d))) if absf(d - round(d)) < 0.001 else ("%.1f" % d)
		glyph.modulate = tint
		glyph.font_size = 48
		glyph.pixel_size = outer * GLYPH_R
		glyph.outline_size = 8
		glyph.outline_modulate = Color(0.0, 0.0, 0.0, 0.85)
		glyph.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		glyph.position = base + along * d - teeth * (blade_w * 0.5 + outer * 0.02)
		_gradation.add_child(glyph)
	# THE REACH COLLAR. Everything past this point on the rail is space the frame
	# draws and the sliders cannot enter — the single most useful fact this rung
	# has to report, and one no number on the console has ever said.
	if reach <= lo + 0.001 or reach >= outer - 0.001:
		return
	_readout_box(_gradation,
			_section(along, outer * REACH_R, teeth, blade_w * 1.9, blade_t * 2.2),
			base + along * reach, _readout_mat(tint.lightened(0.25), 3.0))


## The coordinate staircase: origin -> (x,0,0) -> (x,y,0) -> (x,y,z). Three
## axis-parallel legs, colour-matched to the rails, so each leg's LENGTH is one
## of the three numbers and can be read straight off the rail beside it. This is
## the file's truth line drawn — "a coordinate is three independent
## measurements" — and it is why the origin line stays: the diagonal is |p|, the
## staircase is its components, and having both on screen is the lesson.
func _build_stair(outer: float) -> void:
	var t: float = outer * STAIR_T_R
	_stair_t = t
	_stair_x = _readout_box(_gradation, Vector3.ONE * 0.001, Vector3.ZERO,
			_readout_mat(AXIS_RED, 1.6))
	_stair_y = _readout_box(_gradation, Vector3.ONE * 0.001, Vector3.ZERO,
			_readout_mat(AXIS_GREEN, 1.6))
	_stair_z = _readout_box(_gradation, Vector3.ONE * 0.001, Vector3.ZERO,
			_readout_mat(AXIS_BLUE, 1.6))
	var knee: StandardMaterial3D = _readout_mat(Color(1.0, 0.95, 0.85), 1.2)
	_stair_knee_a = _readout_box(_gradation, Vector3.ONE * (t * 1.55),
			Vector3.ZERO, knee)
	_stair_knee_b = _readout_box(_gradation, Vector3.ONE * (t * 1.55),
			Vector3.ZERO, knee)


func _update_stair() -> void:
	var p: Vector3 = _current_pos
	var t: float = _stair_t
	_leg(_stair_x, Vector3(absf(p.x), t, t), Vector3(p.x * 0.5, 0.0, 0.0))
	_leg(_stair_y, Vector3(t, absf(p.y), t), Vector3(p.x, p.y * 0.5, 0.0))
	_leg(_stair_z, Vector3(t, t, absf(p.z)), Vector3(p.x, p.y, p.z * 0.5))
	if _stair_knee_a:
		_stair_knee_a.position = Vector3(p.x, 0.0, 0.0)
	if _stair_knee_b:
		_stair_knee_b.position = Vector3(p.x, p.y, 0.0)


func _leg(mi: MeshInstance3D, size: Vector3, pos: Vector3) -> void:
	if mi == null:
		return
	var bm: BoxMesh = mi.mesh as BoxMesh
	if bm == null:
		return
	bm.size = Vector3(maxf(size.x, 0.001), maxf(size.y, 0.001), maxf(size.z, 0.001))
	mi.position = pos


## RUNG 3 — the privileged set drawn. A node at every whole-number triple across
## the graduated extent, with the three coordinate-plane grids wired between
## them, so the continuous point you are dragging is visibly ONE dot inside a
## countable set. This is the twin primitive's claim — "the privilege of whole
## numbers" — said in the plate's own geometry; on line.gd the same rung paints
## the zones where a length physically resists.
##
## COST, stated rather than discovered: this is the family's only heavy rung.
## Seven stations cubed is 343 node boxes plus 42 wires, each its own
## MeshInstance3D, all sharing two materials. Fine for a still and for a desktop
## room; think before putting `readout: lattice` on more than one plate in a map
## a headset has to hold at 90 Hz.
func _build_lattice() -> void:
	var lo: float = minf(min_value, max_value)
	var outer: float = _readout_extent()
	var first: float = ceilf(lo)
	var last: float = floorf(outer)
	if last < first:
		return                        # a range containing no whole number has no lattice
	var count: int = int(last - first) + 1
	var step: int = 1
	# Thin the lattice rather than let it explode: at the frame's real 12 m this
	# settles on every second whole number, and min -50 / max 50 would otherwise
	# ask for a million boxes.
	while count > LATTICE_MAX_STATIONS and step < 64:
		step += 1
		count = int((last - first) / float(step)) + 1
	var stations: Array = []
	for i in range(count):
		stations.append(first + float(i * step))
	_lattice = Node3D.new()
	_lattice.name = "Lattice"
	_lattice.set_meta("phenomenon", true)
	add_child(_lattice)
	var node_size: float = outer * LATTICE_NODE_R
	var wire: float = outer * LATTICE_WIRE_R
	var node_mat: StandardMaterial3D = _readout_mat(LATTICE_TINT, 1.5)
	var wire_mat: StandardMaterial3D = _readout_mat(LATTICE_TINT.darkened(0.55), 0.5)
	for sx in stations:
		for sy in stations:
			for sz in stations:
				_readout_box(_lattice, Vector3.ONE * node_size,
						Vector3(float(sx), float(sy), float(sz)), node_mat)
	var floor_v: float = float(stations[0])
	var top_v: float = float(stations[count - 1])
	var span: float = top_v - floor_v
	if span < 0.01:
		return
	var mid: float = (floor_v + top_v) * 0.5
	# graph paper on the three walls of the octant — the grid the nodes sit on
	for s in stations:
		var v: float = float(s)
		_readout_box(_lattice, Vector3(wire, span, wire),
				Vector3(v, mid, floor_v), wire_mat)
		_readout_box(_lattice, Vector3(span, wire, wire),
				Vector3(mid, v, floor_v), wire_mat)
		_readout_box(_lattice, Vector3(wire, span, wire),
				Vector3(floor_v, mid, v), wire_mat)
		_readout_box(_lattice, Vector3(wire, wire, span),
				Vector3(floor_v, v, mid), wire_mat)
		_readout_box(_lattice, Vector3(span, wire, wire),
				Vector3(mid, floor_v, v), wire_mat)
		_readout_box(_lattice, Vector3(wire, wire, span),
				Vector3(v, floor_v, mid), wire_mat)


## A box size for a bar that runs `length` along one basis vector and is `width`
## wide across a second; the remaining direction takes `thick`. Only meaningful
## for axis-aligned unit vectors, which is all this file ever passes.
func _section(along: Vector3, length: float, across: Vector3, width: float,
		thick: float) -> Vector3:
	var third: Vector3 = along.cross(across).abs()
	return along.abs() * length + across.abs() * width + third * thick


func _readout_mat(c: Color, energy: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.42
	m.emission_enabled = true
	m.emission = Color(c.r, c.g, c.b)
	m.emission_energy_multiplier = energy
	return m


func _readout_box(host: Node3D, size: Vector3, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	host.add_child(mi)
	return mi


## apply_grid_config lands a frame AFTER _ready(), so the body is already built
## when it arrives. Rather than pretend otherwise, this re-does what can be
## re-done: the workspace additions are torn down and rebuilt, and what rung 0
## suppresses is hidden rather than un-built. It is deliberately NOT identical to
## reading the token at _ready — the console's pocket hardware stays milled,
## merely dark and empty — which is precisely why _read_readout() exists.
func _apply_readout_late() -> void:
	if _gradation:
		remove_child(_gradation)
		_gradation.queue_free()
		_gradation = null
	if _lattice:
		remove_child(_lattice)
		_lattice.queue_free()
		_lattice = null
	_stair_x = null
	_stair_y = null
	_stair_z = null
	_stair_knee_a = null
	_stair_knee_b = null
	var silent: bool = readout == "none"
	if _display_container:
		_display_container.visible = not silent
	if _origin_line:
		_origin_line.visible = not silent
	if _coord_system:
		_coord_system.visible = not silent
	_build_readout()


func _color_slider_label(slider: Node, color: Color) -> void:
	if not slider:
		return
	var label := slider.get_node_or_null("Frame/LabelName") as Label3D
	if label:
		label.modulate = color


# ── Slider Reading ───────────────────────────────────────────────────

func _on_slider_changed(_position) -> void:
	_read_sliders()


func _read_sliders() -> void:
	if _slider_x and _slider_x.has_method("get_normalized_value"):
		_current_pos.x = _norm_to_val(_slider_x.get_normalized_value())
	if _slider_y and _slider_y.has_method("get_normalized_value"):
		_current_pos.y = _norm_to_val(_slider_y.get_normalized_value())
	if _slider_z and _slider_z.has_method("get_normalized_value"):
		_current_pos.z = _norm_to_val(_slider_z.get_normalized_value())


func _val_to_norm(val: float) -> float:
	return clampf((val - min_value) / (max_value - min_value), 0.0, 1.0)


func _norm_to_val(norm: float) -> float:
	return min_value + norm * (max_value - min_value)


# ── Update ───────────────────────────────────────────────────────────

func _update_point() -> void:
	# Move point
	if _point_mesh:
		_point_mesh.position = _current_pos

	# Update billboard label above point
	var coord_text := "(%.2f, %.2f, %.2f)" % [_current_pos.x, _current_pos.y, _current_pos.z]
	if _coord_label:
		_coord_label.text = coord_text
		_coord_label.position = _current_pos + Vector3(0, point_radius + 0.04, 0)

	# Update Rams text display on panel
	if _display_label:
		_display_label.text = coord_text

	# Update line to origin
	if _origin_line and _origin_cylinder:
		var dist := _current_pos.length()
		if dist < 0.001:
			_origin_line.visible = false
		else:
			# `readout != "none"` is TRUE on every legacy path, so this reads
			# `visible = true` for all 35 existing placements. It only bites when
			# apply_grid_config drops the rung AFTER the rod was already built.
			_origin_line.visible = readout != "none"
			_origin_cylinder.height = dist
			var midpoint := _current_pos / 2.0
			_origin_line.position = midpoint
			var direction := _current_pos.normalized()
			var up := Vector3.UP
			if absf(direction.dot(up)) > 0.99:
				up = Vector3.RIGHT
			_origin_line.look_at(_current_pos, up)
			_origin_line.rotate_object_local(Vector3.RIGHT, PI / 2.0)

	# Coordinate staircase — null on the legacy path, so this is one null test
	# per frame for the 35 rooms that never asked for it.
	if _stair_x:
		_update_stair()


# ── Grid Config ──────────────────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("min_value"):
		min_value = config_data["min_value"]
	if config_data.has("max_value"):
		max_value = config_data["max_value"]
	if config_data.has("start_position"):
		var sp = config_data["start_position"]
		if sp is Array and sp.size() == 3:
			start_position = Vector3(sp[0], sp[1], sp[2])
	if config_data.has("line_to_origin"):
		line_to_origin = config_data["line_to_origin"]
	if config_data.has("panel_scale"):
		panel_scale = float(config_data["panel_scale"])
	if config_data.has("show_coordinate_system"):
		show_coordinate_system = bool(config_data["show_coordinate_system"])
	if config_data.has("coord_system_scale"):
		coord_system_scale = float(config_data["coord_system_scale"])
	if config_data.has("console_body"):
		console_body = bool(config_data["console_body"])
	if config_data.has("finish"):
		finish = str(config_data["finish"])
	if config_data.has("billboard_coords"):
		billboard_coords = bool(config_data["billboard_coords"])
	# AXIS `readout`. Also read from metadata in _read_readout() at _ready time,
	# which is the path a map token actually takes; this branch serves callers
	# that hand the dictionary over directly (cluster_resolver, the dwell pass).
	if config_data.has("readout"):
		var want: String = readout_name(str(config_data["readout"]))
		if want != readout:
			readout = want
			_apply_readout_late()
