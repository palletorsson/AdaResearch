extends Node3D

# @identity
# essence: A pillar-free, West-to-East monochrome architectural arena around
#   Shaft A on Floor 13 (Trans_Pre), pairing two elevated walkable scaffolds
#   (South: 5 stages of Coin / Desire; North: 5 stages of Package / Promise)
#   flanking a sunken Shaft A Bomb Basin (5 stages of Bomb / Threat), crowned
#   at the East threshold by an Alan Warburton / Fairytales of Motion (2019)
#   curatorial monolith opening directly onto the East Static Play Path.
# desire: Align the entire 42-metre floor along one unbroken, pillar-free
#   West-to-East museum axis: Dissect the 3x5 Motion Vocabulary around Shaft A
#   -> read the Politics of Emotional Graphics monolith -> step onto the East
#   Static Play Path -> descend Shaft B into transforming architecture (F14).
# critical_parameter: 100% clear of tower pillars (z = +/-7) and service pipe
#   (-6.5, -4.2); elevated monochrome scaffolds (y = +0.58 m) with smooth 17.8-deg
#   West & East ramps; recessed Shaft A Bomb Basin (y = -0.82 m) clear of the SE
#   Soft Landing Pad with a West walk-out ramp; 15 stage plaques; West portal
#   beam; and centered Warburton monolith facing West down the central axis.
# truth: When the room aligns cleanly with its structure, every stage from Static
#   to Archetype reads in one unobstructed sweep straight into live deployment.

const DECK_Y := 0.58
const DECK_HALF_Z := 1.00 # 2.0 m wide decks -> z in [4.4, 6.4] & [-6.4, -4.4] (100% clear of z=+/-6.6 pillars & z=-4.2 pipe!)
const DECK_X_HALF := 4.60 # x in [-14.6, -5.4] around Shaft A center x = -10.0
const SHAFT_X := -10.0
const RAMP_RUN := 1.80
const SOUTH_Z := 5.40
const NORTH_Z := -5.40
const COIN_Z := 5.96
const PKG_Z := -5.96
const SIDE_XS := [-13.6, -11.8, -10.0, -8.2, -6.4]

const BASIN_Y := -0.82
# West -> East progression inside Shaft A Basin (100% clear of SE Soft Landing Pad x in [-8.57,-7.03], z in [0.80,3.00]!)
const BOMB_CELLS := [
	{"pos": Vector2(-12.0, 1.65), "cap": "01 · STATIC\ninert sphere", "cap_dx": 0.0, "cap_dz": -0.78, "arch": false},
	{"pos": Vector2(-12.1, -1.75), "cap": "02 · TRANSLATE XZ\npatrol sweep", "cap_dx": 0.0, "cap_dz": 0.88, "arch": false},
	{"pos": Vector2(-10.0, 1.65), "cap": "03 · ROTATE Y\nsentry scan", "cap_dx": 0.0, "cap_dz": -0.78, "arch": false},
	{"pos": Vector2(-9.8, -1.75), "cap": "04 · SCALE\nprimed pulse", "cap_dx": 0.0, "cap_dz": 0.84, "arch": false},
	{"pos": Vector2(-8.2, -1.85), "cap": "05 · ARCHETYPE\nTHREAT · AVOID (Txz)", "cap_dx": 0.0, "cap_dz": 0.90, "arch": true},
]

const COIN_CAPS := [
	"01 · STATIC\ninert disc",
	"02 · TRANSLATE Y\ncold lift",
	"03 · ROTATE Y\nrestless turn",
	"04 · SCALE\nuncanny throb",
	"05 · ARCHETYPE\nDESIRE · TAKE ME (Ty+R)",
]

const PKG_CAPS := [
	"01 · STATIC\nplain cargo",
	"02 · TRANSLATE Y\nlevitating box",
	"03 · ROTATE Y\ndisplay turn",
	"04 · SCALE\nalive inside",
	"05 · ARCHETYPE\nPROMISE · OPEN (Ty+R+S)",
]

var _mat_black: StandardMaterial3D
var _mat_slate: StandardMaterial3D
var _mat_white: StandardMaterial3D
var _mat_line: StandardMaterial3D
var _mat_accent_white: StandardMaterial3D


func _ready() -> void:
	_init_materials()
	_build_side_scaffold("SouthCoinScaffold", SOUTH_Z, COIN_Z, 1.0, "A · COIN  (DESIRE)", COIN_CAPS)
	_build_side_scaffold("NorthPackageScaffold", NORTH_Z, PKG_Z, -1.0, "C · PACKAGE  (PROMISE)", PKG_CAPS)
	_build_shaft_a_bomb_basin()
	_build_west_portal_beam()
	_build_curatorial_monolith()
	_build_floor_guides()


func _init_materials() -> void:
	_mat_black = StandardMaterial3D.new()
	_mat_black.albedo_color = Color("131519")
	_mat_black.roughness = 0.72
	_mat_black.metallic = 0.08

	_mat_slate = StandardMaterial3D.new()
	_mat_slate.albedo_color = Color("2b2f37")
	_mat_slate.roughness = 0.65
	_mat_slate.metallic = 0.14

	_mat_white = StandardMaterial3D.new()
	_mat_white.albedo_color = Color("ededeb")
	_mat_white.roughness = 0.56
	_mat_white.metallic = 0.04

	_mat_line = StandardMaterial3D.new()
	_mat_line.albedo_color = Color("f4f4f0")
	_mat_line.roughness = 0.45
	_mat_line.emission_enabled = true
	_mat_line.emission = Color("e8e8e2")
	_mat_line.emission_energy_multiplier = 0.16

	_mat_accent_white = StandardMaterial3D.new()
	_mat_accent_white.albedo_color = Color("fafaf6")
	_mat_accent_white.roughness = 0.35
	_mat_accent_white.emission_enabled = true
	_mat_accent_white.emission = Color("ffffff")
	_mat_accent_white.emission_energy_multiplier = 0.28


func _box(parent: Node3D, node_name: String, at: Vector3, size: Vector3, mat: Material, solid := false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = at
	parent.add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		sb.name = node_name + "_Body"
		sb.position = at
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = size
		cs.shape = bs
		sb.add_child(cs)
		parent.add_child(sb)
	return mi


func _ramp_x(parent: Node3D, node_name: String, center_z: float, width_z: float, x_low: float, x_high: float, y_low: float, y_high: float, mat: Material) -> void:
	var hz := width_z * 0.5
	var p0 := Vector3(x_low, y_low, center_z - hz)
	var p1 := Vector3(x_low, y_low, center_z + hz)
	var p2 := Vector3(x_high, y_low, center_z + hz)
	var p3 := Vector3(x_high, y_low, center_z - hz)
	var p4 := Vector3(x_high, y_high, center_z + hz)
	var p5 := Vector3(x_high, y_high, center_z - hz)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var add_tri := func(a: Vector3, b: Vector3, c: Vector3) -> void:
		var n := (c - a).cross(b - a).normalized()
		st.set_normal(n); st.add_vertex(a)
		st.set_normal(n); st.add_vertex(b)
		st.set_normal(n); st.add_vertex(c)

	if x_low < x_high:
		add_tri.call(p0, p5, p4); add_tri.call(p0, p4, p1)
		add_tri.call(p3, p2, p4); add_tri.call(p3, p4, p5)
		add_tri.call(p0, p3, p5)
		add_tri.call(p1, p4, p2)
		add_tri.call(p0, p1, p2); add_tri.call(p0, p2, p3)
	else:
		add_tri.call(p0, p1, p4); add_tri.call(p0, p4, p5)
		add_tri.call(p3, p5, p4); add_tri.call(p3, p4, p2)
		add_tri.call(p0, p5, p3)
		add_tri.call(p1, p2, p4)
		add_tri.call(p0, p2, p1); add_tri.call(p0, p3, p2)

	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)

	# Flush black architectural edge rails hugging both ramp cheeks
	var run_x := absf(x_high - x_low)
	var rise_y := y_high - y_low
	var slope_len := Vector2(run_x, rise_y).length()
	var mid := Vector3((x_low + x_high) * 0.5, (y_low + y_high) * 0.5 + 0.014, center_z)
	var roll_z := atan2(rise_y, run_x) * (1.0 if x_low < x_high else -1.0)
	for sz in [-hz + 0.03, hz - 0.03]:
		var rail := _box(parent, node_name + "_Edge", Vector3(mid.x, mid.y, mid.z + sz), Vector3(slope_len, 0.024, 0.055), _mat_black, false)
		rail.rotation.z = roll_z

	var sb := StaticBody3D.new()
	sb.name = node_name + "_Body"
	var cs := CollisionShape3D.new()
	var hull := ConvexPolygonShape3D.new()
	hull.points = PackedVector3Array([p0, p1, p2, p3, p4, p5])
	cs.shape = hull
	sb.add_child(cs)
	parent.add_child(sb)


func _label(parent: Node3D, text: String, at: Vector3, rot_deg: Vector3, font_sz: int, px_sz: float, col: Color, width_px := 0.0) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = font_sz
	lb.pixel_size = px_sz
	lb.modulate = col
	lb.outline_size = 6
	lb.outline_modulate = Color("0c0d10")
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if width_px > 0.0:
		lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lb.width = width_px
	lb.position = at
	lb.rotation_degrees = rot_deg
	parent.add_child(lb)
	return lb


func _build_side_scaffold(scaffold_name: String, center_z: float, plinth_z: float, outer_sign: float, title: String, captions: Array) -> void:
	var root := Node3D.new()
	root.name = scaffold_name
	add_child(root)

	var deck_len_x := DECK_X_HALF * 2.0
	var deck_w_z := DECK_HALF_Z * 2.0
	var deck_thick := 0.12

	# Main elevated white scaffold deck running West -> East (x = -14.6..-5.4, top at y = +0.58 m)
	_box(root, "MainDeck", Vector3(SHAFT_X, DECK_Y - deck_thick * 0.5, center_z), Vector3(deck_len_x, deck_thick, deck_w_z), _mat_white, true)
	for sz in [-DECK_HALF_Z + 0.03, DECK_HALF_Z - 0.03]:
		_box(root, "DeckSideTrim", Vector3(SHAFT_X, DECK_Y + 0.008, center_z + sz), Vector3(deck_len_x, 0.018, 0.06), _mat_black, false)
	for x_div in [-12.7, -10.9, -9.1, -7.3]:
		_box(root, "StageDivider", Vector3(x_div, DECK_Y + 0.006, center_z), Vector3(0.035, 0.008, deck_w_z - 0.12), _mat_black, false)
	# Matte-black highlight bay under Stage 05 (ARCHETYPE, East end x = -6.4)
	_box(root, "ArchetypeDeckBay", Vector3(-6.4, DECK_Y + 0.005, center_z), Vector3(1.72, 0.008, deck_w_z - 0.14), _mat_black, false)

	# Low black safety curb along the inner Shaft-A viewing edge
	var inner_edge_z := center_z - outer_sign * (DECK_HALF_Z - 0.05)
	_box(root, "InnerCurb", Vector3(SHAFT_X, DECK_Y + 0.045, inner_edge_z), Vector3(deck_len_x, 0.09, 0.09), _mat_black, false)

	# Matte-black scaffold legs & transverse beams underneath
	var leg_h := DECK_Y - deck_thick
	for lx in [-14.4, -12.2, -10.0, -7.8, -5.6]:
		for sz in [-DECK_HALF_Z + 0.12, DECK_HALF_Z - 0.12]:
			_box(root, "ScaffoldPost", Vector3(lx, leg_h * 0.5, center_z + sz), Vector3(0.10, leg_h, 0.10), _mat_black, false)
			_box(root, "ScaffoldFoot", Vector3(lx, 0.02, center_z + sz), Vector3(0.20, 0.04, 0.20), _mat_slate, false)
		_box(root, "CrossBeam", Vector3(lx, leg_h - 0.05, center_z), Vector3(0.08, 0.08, deck_w_z - 0.2), _mat_slate, false)
	for sz in [-DECK_HALF_Z + 0.12, DECK_HALF_Z - 0.12]:
		_box(root, "LongRail", Vector3(SHAFT_X, leg_h * 0.45, center_z + sz), Vector3(deck_len_x - 0.2, 0.07, 0.07), _mat_slate, false)

	# Smooth walkable monochrome ramps at BOTH West (entry) & East (exit) ends — 100% pillar-free!
	_ramp_x(root, "WestRamp", center_z, deck_w_z, SHAFT_X - DECK_X_HALF - RAMP_RUN, SHAFT_X - DECK_X_HALF, 0.0, DECK_Y, _mat_white)
	_ramp_x(root, "EastRamp", center_z, deck_w_z, SHAFT_X + DECK_X_HALF + RAMP_RUN, SHAFT_X + DECK_X_HALF, 0.0, DECK_Y, _mat_white)

	# Floor titles just off the West entrance ramp toe (facing East)
	_label(root, title + "\nWALK UP ->", Vector3(SHAFT_X - DECK_X_HALF - RAMP_RUN - 0.55, 0.025, center_z), Vector3(-90, -90, 0), 28, 0.0036, Color("f6f6f2"))

	# 5 Specimen Plinths along the outer rail of the scaffold, plaques angled INWARD toward the walkway
	var inward_yaw := 180.0 if outer_sign > 0.0 else 0.0
	for i in SIDE_XS.size():
		var x: float = SIDE_XS[i]
		var is_arch := (i == 4)
		var cell := Node3D.new()
		cell.name = "Cell_%s_%d" % [scaffold_name, i]
		cell.position = Vector3(x, DECK_Y, plinth_z)
		root.add_child(cell)

		var body_mat := _mat_white if is_arch else _mat_black
		var cap_mat := _mat_black if is_arch else _mat_white
		_box(cell, "PlinthShaft", Vector3(0, 0.16, 0), Vector3(0.54, 0.32, 0.54), body_mat, true)
		_box(cell, "PlinthCap", Vector3(0, 0.335, 0), Vector3(0.60, 0.03, 0.60), cap_mat, false)

		var plaque_z := -outer_sign * 0.32
		var plaque := _box(cell, "Plaque", Vector3(0.0, 0.22, plaque_z), Vector3(0.58, 0.22, 0.025), _mat_black, false)
		plaque.rotation_degrees.x = -outer_sign * 30.0
		_label(cell, captions[i], Vector3(0.0, 0.24, plaque_z - outer_sign * 0.025), Vector3(-30.0, inward_yaw, 0.0),
			24, 0.0025, Color("ffffff") if is_arch else Color("e4e4e0"))


func _build_shaft_a_bomb_basin() -> void:
	var root := Node3D.new()
	root.name = "ShaftABombBasin"
	add_child(root)

	# Sunken matte-obsidian basin suspended cleanly inside Shaft A (x = -13..-7, z = -3..+3, floor at y = -0.82 m)
	_box(root, "BasinFloor", Vector3(SHAFT_X, BASIN_Y - 0.08, 0.0), Vector3(6.0, 0.16, 6.0), _mat_black, true)
	var floor_body := root.get_node_or_null("BasinFloor_Body")
	if floor_body != null:
		floor_body.set_meta("void_floor_index", 13)

	var wall_h := absf(BASIN_Y)
	var wall_mid_y := BASIN_Y * 0.5
	_box(root, "BasinWallWest", Vector3(-12.96, wall_mid_y, 0.0), Vector3(0.08, wall_h, 6.0), _mat_slate, true)
	_box(root, "BasinWallEast", Vector3(-7.04, wall_mid_y, 0.0), Vector3(0.08, wall_h, 6.0), _mat_slate, true)
	_box(root, "BasinWallNorth", Vector3(SHAFT_X, wall_mid_y, -2.96), Vector3(6.0, wall_h, 0.08), _mat_slate, true)
	_box(root, "BasinWallSouth", Vector3(SHAFT_X, wall_mid_y, 2.96), Vector3(6.0, wall_h, 0.08), _mat_slate, true)

	# Alabaster architectural rim curb around Shaft A (leaves SE Soft Landing Pad completely unobstructed!)
	_box(root, "RimWest", Vector3(-13.06, 0.025, 0.0), Vector3(0.14, 0.05, 6.24), _mat_accent_white, false)
	_box(root, "RimNorth", Vector3(SHAFT_X, 0.025, -3.06), Vector3(6.24, 0.05, 0.14), _mat_accent_white, false)
	_box(root, "RimEastNorth", Vector3(-6.94, 0.025, -1.15), Vector3(0.14, 0.05, 3.94), _mat_accent_white, false)
	_box(root, "RimSouthWest", Vector3(-10.85, 0.025, 3.06), Vector3(4.54, 0.05, 0.14), _mat_accent_white, false)

	# Hairline white geometric grid etched across the sunken basin floor (West -> East bands)
	_box(root, "BasinCrossX", Vector3(SHAFT_X, BASIN_Y + 0.008, 0.0), Vector3(5.8, 0.006, 0.03), _mat_line, false)
	for gx in [-11.0, -9.0]:
		_box(root, "BasinColLine", Vector3(gx, BASIN_Y + 0.008, 0.0), Vector3(0.03, 0.006, 5.8), _mat_line, false)

	# Compact recessed white walk-out ramp on the WEST wall of the basin (x = -11.2 -> -12.92, z = -0.45..+0.45)
	_ramp_x(root, "BasinWalkoutRamp", 0.0, 0.92, -11.2, -12.92, BASIN_Y, 0.0, _mat_white)

	# 5 Bomb stage discs & crisp floor captions reading West -> East
	for i in BOMB_CELLS.size():
		var info: Dictionary = BOMB_CELLS[i]
		var pt: Vector2 = info.pos
		var is_arch: bool = bool(info.arch)
		var cell := Node3D.new()
		cell.name = "BasinBombCell_%d" % i
		cell.position = Vector3(pt.x, BASIN_Y, pt.y)
		root.add_child(cell)

		var disc := CylinderMesh.new()
		disc.top_radius = 0.54
		disc.bottom_radius = 0.56
		disc.height = 0.016
		disc.radial_segments = 28
		var dmi := MeshInstance3D.new()
		dmi.name = "StageDisc"
		dmi.mesh = disc
		dmi.material_override = _mat_white if is_arch else _mat_slate
		dmi.position = Vector3(0, 0.01, 0)
		cell.add_child(dmi)

		_label(cell, str(info.cap), Vector3(float(info.cap_dx), 0.028, float(info.cap_dz)), Vector3(-90, -90, 0),
			24, 0.0034, Color("ffffff") if is_arch else Color("e0e2e6"))

	# West rim title facing East down the Shaft A Bomb Basin
	_label(root, "B · BOMB BASIN  (THREAT · SHAFT A)\n01 STATIC -> 02 TRANSLATE XZ -> 03 ROTATE -> 04 SCALE -> 05 ARCHETYPE",
		Vector3(-13.85, 0.025, 0.0), Vector3(-90, -90, 0), 26, 0.0036, Color("f6f6f2"))


func _build_west_portal_beam() -> void:
	var root := Node3D.new()
	root.name = "OverheadRowHeader"
	add_child(root)

	# Monumental 12.6 m monochrome portal beam framing the West entrance (x = -16.6, z = -6.3..+6.3, 100% clear of pillars!)
	_box(root, "HeaderBeam", Vector3(-16.6, 3.55, 0.0), Vector3(0.16, 0.52, 12.6), _mat_black, false)
	_box(root, "HeaderTopTrim", Vector3(-16.6, 3.83, 0.0), Vector3(0.18, 0.045, 12.66), _mat_accent_white, false)
	_box(root, "HeaderBotTrim", Vector3(-16.6, 3.27, 0.0), Vector3(0.18, 0.045, 12.66), _mat_white, false)
	for hz in [-5.8, 0.0, 5.8]:
		_box(root, "Hanger", Vector3(-16.6, 4.72, hz), Vector3(0.055, 1.85, 0.055), _mat_slate, false)

	# West-facing header text (readable immediately from West arrival spawn [-18.2, 0])
	_label(root, "MOTION VOCABULARY ARENA  ·  STATIC  ->  TRANSLATE  ->  ROTATE  ->  SCALE  ->  ARCHETYPE",
		Vector3(-16.70, 3.68, 0.0), Vector3(0, -90, 0), 32, 0.0034, Color("f6f6f2"))
	_label(root, "C · PACKAGE  (WALK UP)", Vector3(-16.70, 3.43, -4.4), Vector3(0, -90, 0), 28, 0.0033, Color("ffffff"))
	_label(root, "B · BOMB BASIN  (IN SHAFT A)", Vector3(-16.70, 3.43, 0.0), Vector3(0, -90, 0), 28, 0.0033, Color("ffffff"))
	_label(root, "A · COIN  (WALK UP)", Vector3(-16.70, 3.43, 4.4), Vector3(0, -90, 0), 28, 0.0033, Color("ffffff"))


func _build_curatorial_monolith() -> void:
	var root := Node3D.new()
	root.name = "WarburtonCuratorialWall"
	# Centered directly on the East axis of Shaft A facing West toward the Arena, leaving wide 2.1m aisles on North & South!
	root.position = Vector3(-1.6, 0.0, 0.0)
	root.rotation_degrees.y = -90.0
	add_child(root)

	_box(root, "FootLeft", Vector3(-1.85, 0.18, 0), Vector3(0.32, 0.36, 0.44), _mat_slate, true)
	_box(root, "FootRight", Vector3(1.85, 0.18, 0), Vector3(0.32, 0.36, 0.44), _mat_slate, true)
	_box(root, "WallSlab", Vector3(0, 1.62, 0), Vector3(4.6, 2.58, 0.16), _mat_black, true)
	_box(root, "FrameTop", Vector3(0, 2.93, 0), Vector3(4.68, 0.05, 0.20), _mat_accent_white, false)
	_box(root, "FrameBot", Vector3(0, 0.32, 0), Vector3(4.68, 0.05, 0.20), _mat_white, false)
	_box(root, "FrameLeft", Vector3(-2.32, 1.62, 0), Vector3(0.05, 2.66, 0.20), _mat_white, false)
	_box(root, "FrameRight", Vector3(2.32, 1.62, 0), Vector3(0.05, 2.66, 0.20), _mat_white, false)
	_box(root, "RuleUpper", Vector3(0, 2.34, 0.088), Vector3(4.15, 0.015, 0.01), _mat_white, false)
	_box(root, "RuleLower", Vector3(0, 0.86, 0.088), Vector3(4.15, 0.015, 0.01), _mat_white, false)

	_label(root, "THE POLITICS OF EMOTIONAL GRAPHICS & AI",
		Vector3(0, 2.66, 0.095), Vector3(0, 0, 0), 42, 0.0034, Color("ffffff"))
	_label(root, "REF. ALAN WARBURTON · FAIRYTALES OF MOTION (2019, 7'18\", TATE BRITAIN)",
		Vector3(0, 2.46, 0.095), Vector3(0, 0, 0), 26, 0.0029, Color("d8dadf"))

	var essay := (
		"Before color or text exists, standardized libraries of movement already code\n" +
		"what we reach for (Coin: Ty + R), what we avoid (Bomb: Txz), and what promises\n" +
		"reward (Package: Ty + R + S). Pragmatic conventions of cartoon animation hardened\n" +
		"into reproducible motion vocabularies — the same codifications that now underpin\n" +
		"motion capture, gait analysis, surveillance, and AI behavioral profiling."
	)
	_label(root, essay, Vector3(0, 1.62, 0.095), Vector3(0, 0, 0), 30, 0.0030, Color("f0f0ec"))

	_label(root, "CARTOON CODES -> GAME AFFORDANCES -> MOCAP & GAIT ANALYSIS -> AI PROFILING",
		Vector3(0, 0.68, 0.095), Vector3(0, 0, 0), 23, 0.0028, Color("ffffff"))
	_label(root, "CONTINUE EAST ONTO THE STATIC PLAY PATH -> WATCH THESE CODES STEER YOUR BODY",
		Vector3(0, 0.48, 0.095), Vector3(0, 0, 0), 23, 0.0027, Color("d4d8df"))


func _build_floor_guides() -> void:
	var root := Node3D.new()
	root.name = "FloorGuides"
	add_child(root)

	# Straight crisp connector line from North Package Scaffold East Ramp (-3.6, -5.4) directly into Static Play Path Entry Ramp (-1.2, -5.5)!
	_box(root, "BridgeLineNE", Vector3(-2.4, 0.010, -5.45), Vector3(2.4, 0.006, 0.055), _mat_accent_white, false)
	_label(root, "STATIC PLAY PATH ->", Vector3(-2.4, 0.025, -4.95), Vector3(-90, -90, 0), 24, 0.0034, Color("f2f2ec"))
