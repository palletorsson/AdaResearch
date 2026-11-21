extends Node3D

# @identity
# essence: A purely static, high-precision monochrome architectural play path
#   wrapping Shaft B on Floor 13 (Trans_Pre) with zero moving platforms or
#   architectural transitions — so every cue of movement, desire, threat, and
#   reward comes exclusively from the three standardized object archetypes
#   (Coin Ty+R, Bomb Txz, Package Ty+R+S).
# desire: Offer a simpler, sharper, transition-free counterpart to the West Shaft A
#   Motion Vocabulary Arena before Floor 14 introduces transforming architecture.
# critical_parameter: 100% static elevated white-with-black-edge Bauhaus path
#   (y = +0.58 m) with smooth 17.8-degree Entry & Exit ramps, NE Package detour
#   alcove, East timing gauntlet overlooking Shaft B, and Finale stage leading
#   straight to the Shaft B descent to Floor 14.
# truth: When the floor refuses to move, three simple object transforms are enough
#   to choreograph every pause, detour, and footstep of a human body.

const DECK_Y := 0.58
const DECK_THICK := 0.12
const RAMP_RUN := 1.80

var _mat_black: StandardMaterial3D
var _mat_slate: StandardMaterial3D
var _mat_white: StandardMaterial3D
var _mat_accent_white: StandardMaterial3D


func _ready() -> void:
	_init_materials()
	_build_entry_and_north_leg()
	_build_ne_package_alcove()
	_build_east_gauntlet_leg()
	_build_south_finale_and_exit()
	_build_entry_portal_arch()


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


func _label(parent: Node3D, text: String, at: Vector3, rot_deg: Vector3, font_sz: int, px_sz: float, col: Color) -> Label3D:
	var lb := Label3D.new()
	lb.text = text
	lb.font_size = font_sz
	lb.pixel_size = px_sz
	lb.modulate = col
	lb.outline_size = 6
	lb.outline_modulate = Color("0c0d10")
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.position = at
	lb.rotation_degrees = rot_deg
	parent.add_child(lb)
	return lb


func _ramp_x(parent: Node3D, node_name: String, center_z: float, width_z: float, x_low: float, x_high: float, y_low: float, y_high: float) -> void:
	# Smooth static wedge rising along the X axis from (x_low, y_low) up to (x_high, y_high).
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
		# Rising toward +X (West-to-East Entry Ramp)
		add_tri.call(p0, p5, p4); add_tri.call(p0, p4, p1) # Top slope
		add_tri.call(p3, p2, p4); add_tri.call(p3, p4, p5) # High back
		add_tri.call(p0, p3, p5) # North cheek
		add_tri.call(p1, p4, p2) # South cheek
		add_tri.call(p0, p1, p2); add_tri.call(p0, p2, p3) # Bottom
	else:
		# Rising toward -X (East-to-West Exit Ramp descending West)
		add_tri.call(p0, p1, p4); add_tri.call(p0, p4, p5) # Top slope
		add_tri.call(p3, p5, p4); add_tri.call(p3, p4, p2) # High back
		add_tri.call(p0, p5, p3) # North cheek
		add_tri.call(p1, p2, p4) # South cheek
		add_tri.call(p0, p2, p1); add_tri.call(p0, p3, p2) # Bottom

	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = st.commit()
	mi.material_override = _mat_white
	parent.add_child(mi)

	# Flush black architectural edge trims hugging both cheeks of the X-ramp
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


func _deck_segment(parent: Node3D, seg_name: String, x0: float, x1: float, z0: float, z1: float, supports_x: Array, supports_z: Array) -> void:
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var wx := absf(x1 - x0)
	var wz := absf(z1 - z0)
	_box(parent, seg_name + "_Deck", Vector3(cx, DECK_Y - DECK_THICK * 0.5, cz), Vector3(wx, DECK_THICK, wz), _mat_white, true)

	# Crisp matte-black perimeter border lines flush on deck top
	_box(parent, seg_name + "_TrimN", Vector3(cx, DECK_Y + 0.008, minf(z0, z1) + 0.03), Vector3(wx, 0.016, 0.06), _mat_black, false)
	_box(parent, seg_name + "_TrimS", Vector3(cx, DECK_Y + 0.008, maxf(z0, z1) - 0.03), Vector3(wx, 0.016, 0.06), _mat_black, false)
	_box(parent, seg_name + "_TrimW", Vector3(minf(x0, x1) + 0.03, DECK_Y + 0.008, cz), Vector3(0.06, 0.016, wz), _mat_black, false)
	_box(parent, seg_name + "_TrimE", Vector3(maxf(x0, x1) - 0.03, DECK_Y + 0.008, cz), Vector3(0.06, 0.016, wz), _mat_black, false)

	# Clean static black scaffold legs underneath
	var leg_h := DECK_Y - DECK_THICK
	for px in supports_x:
		for pz in supports_z:
			_box(parent, seg_name + "_Leg", Vector3(px, leg_h * 0.5, pz), Vector3(0.10, leg_h, 0.10), _mat_black, false)
			_box(parent, seg_name + "_Foot", Vector3(px, 0.02, pz), Vector3(0.20, 0.04, 0.20), _mat_slate, false)


func _build_entry_and_north_leg() -> void:
	var root := Node3D.new()
	root.name = "NorthInvitationLeg"
	add_child(root)

	# Smooth static ramp rising West-to-East (x = -1.2 -> +0.6, z = -6.5..-4.5, clear of service pipe at z = -4.2 & North columns at z = -6.6!)
	_ramp_x(root, "EntryRamp", -5.5, 2.0, -1.2, 0.6, 0.0, DECK_Y)
	_label(root, "STATIC PLAY PATH\nENTER ->", Vector3(-1.85, 0.025, -5.5), Vector3(-90, 0, 0), 30, 0.0038, Color("f6f6f2"))

	# North Invitation Promenade (x = +0.6 -> +14.0, z = -6.5..-4.5)
	_deck_segment(root, "NorthLeg", 0.6, 14.0, -6.5, -4.5, [1.0, 4.2, 7.4, 10.6, 13.6], [-6.35, -4.65])

	# Clean matte-black center leading stripe guiding the player along the 3 Coins (Ty + R) into Package 1!
	_box(root, "LeadingLineN", Vector3(7.5, DECK_Y + 0.006, -5.5), Vector3(11.4, 0.008, 0.045), _mat_black, false)
	for cx in [3.4, 6.8, 10.2]:
		_box(root, "CoinMarker", Vector3(cx, DECK_Y + 0.007, -5.5), Vector3(0.54, 0.008, 0.54), _mat_black, false)
		_box(root, "CoinMarkerIn", Vector3(cx, DECK_Y + 0.009, -5.5), Vector3(0.42, 0.008, 0.42), _mat_white, false)
	# Matte-black stage square under Pre-Bomb Random Supply Package at [12.6, -5.5]
	_box(root, "PreBombPkgStage", Vector3(12.6, DECK_Y + 0.007, -5.5), Vector3(1.15, 0.010, 1.35), _mat_black, false)
	_label(root, "PACKAGE -> RANDOM OBJECT\nGRAB (RMB) · THROW (LMB) AT BOMBS",
		Vector3(12.6, DECK_Y + 0.024, -6.02), Vector3(-90, 0, 0), 20, 0.0028, Color("f6f6f2"))

	_label(root, "01 / DESIRE  ·  FOLLOW THE COINS  (TRANSLATE Y + ROTATE)",
		Vector3(6.8, DECK_Y + 0.022, -4.82), Vector3(-90, 0, 0), 24, 0.0032, Color("14161a"))


func _build_ne_package_alcove() -> void:
	var root := Node3D.new()
	root.name = "NEPackageAlcove"
	add_child(root)

	# Corner + NE Detour Balcony (x = +14.0 -> +19.2, z = -6.5..-4.5)
	_deck_segment(root, "AlcoveDeck", 14.0, 19.2, -6.5, -4.5, [14.2, 16.6, 18.9], [-6.35, -4.65])

	# Bomb sweep slot line across balcony neck at x = 16.0
	_box(root, "BombSlotNE", Vector3(16.0, DECK_Y + 0.007, -5.5), Vector3(0.06, 0.008, 1.72), _mat_black, false)

	# Matte-black spotlight stage square under Package 1 (rubberball reward) at [18.1, -5.5]
	_box(root, "PackageStage1", Vector3(18.1, DECK_Y + 0.007, -5.5), Vector3(1.45, 0.010, 1.50), _mat_black, false)
	_label(root, "02 / PROMISE & RISK\nTIME BOMB (Txz) · CLAIM PACKAGE (Ty+R+S)",
		Vector3(18.1, DECK_Y + 0.024, -6.08), Vector3(-90, 0, 0), 21, 0.0029, Color("f6f6f2"))


func _build_east_gauntlet_leg() -> void:
	var root := Node3D.new()
	root.name = "EastGauntletLeg"
	add_child(root)

	# Wide static East promenade overlooking Shaft B (x = +14.0..+16.8, z = -4.5..+3.6)
	_deck_segment(root, "EastLeg", 14.0, 16.8, -4.5, 3.6, [14.2, 16.6], [-4.2, -1.5, 1.1, 3.2])

	# Low black safety curb along the West edge facing Shaft B (x = 14.05)
	_box(root, "ShaftBCurbE", Vector3(14.05, DECK_Y + 0.045, -0.45), Vector3(0.09, 0.09, 8.1), _mat_black, false)

	# Two crisp black sweep-rail channels marking the opposing Bomb (Translate XZ) corridors
	for bz in [-1.5, 1.6]:
		_box(root, "BombRailE", Vector3(15.4, DECK_Y + 0.007, bz), Vector3(2.2, 0.008, 0.07), _mat_black, false)

	# Safe pocket square between the two sweeps holding Coin 4
	_box(root, "SafePocket", Vector3(15.4, DECK_Y + 0.007, 0.05), Vector3(0.70, 0.008, 0.70), _mat_black, false)
	_box(root, "SafePocketIn", Vector3(15.4, DECK_Y + 0.009, 0.05), Vector3(0.56, 0.008, 0.56), _mat_white, false)

	_label(root, "03 / THREAT  ·  TIME THE LINEAR SWEEP  (TRANSLATE XZ)",
		Vector3(16.42, DECK_Y + 0.022, 0.05), Vector3(-90, -90, 0), 26, 0.0033, Color("14161a"))


func _build_south_finale_and_exit() -> void:
	var root := Node3D.new()
	root.name = "SouthFinaleLeg"
	add_child(root)

	# South Promenade (x = +6.4 -> +16.8, z = +3.6..+6.0)
	_deck_segment(root, "SouthLeg", 6.4, 16.8, 3.6, 6.0, [6.6, 9.8, 13.0, 16.6], [3.75, 5.85])

	# Low black safety curb facing Shaft B North edge (z = +3.65)
	_box(root, "ShaftBCurbS", Vector3(10.2, DECK_Y + 0.045, 3.65), Vector3(7.6, 0.09, 0.09), _mat_black, false)

	# Coin 5 corner marker + Coin 6 marker leading straight to Finale Package stage
	for pt in [Vector2(15.4, 4.8), Vector2(12.2, 4.8)]:
		_box(root, "CoinSouthMark", Vector3(pt.x, DECK_Y + 0.007, pt.y), Vector3(0.54, 0.008, 0.54), _mat_black, false)
		_box(root, "CoinSouthMarkIn", Vector3(pt.x, DECK_Y + 0.009, pt.y), Vector3(0.42, 0.008, 0.42), _mat_white, false)

	# Finale Matte-Black Crown Stage under Package 2 at [8.8, 4.8]
	_box(root, "FinaleStage", Vector3(8.8, DECK_Y + 0.008, 4.8), Vector3(2.2, 0.012, 1.9), _mat_black, false)
	_label(root, "04 / CROWN REWARD  ·  PACKAGE (Ty+R+S)",
		Vector3(8.8, DECK_Y + 0.024, 5.50), Vector3(-90, 0, 0), 24, 0.0032, Color("f6f6f2"))

	# Smooth static exit ramp descending West (x = +6.4 -> +4.6, z = 3.6..6.0) right onto open floor beside Shaft B!
	_ramp_x(root, "ExitRamp", 4.8, 2.4, 4.6, 6.4, 0.0, DECK_Y)

	# Crisp floor transition plaque right beside Shaft B pointing to Floor 14
	_label(root, "STATIC ARCHITECTURE ENDS HERE\nDROP DOWN SHAFT B  ->  FLOOR 14: THE ARCHITECTURE ITSELF TRANSFORMS",
		Vector3(2.6, 0.025, 4.8), Vector3(-90, 0, 0), 26, 0.0036, Color("f4f4f0"))


func _build_entry_portal_arch() -> void:
	var root := Node3D.new()
	root.name = "PlayPathPortal"
	add_child(root)

	# Sleek minimal monochrome entry portal framing the North-West entrance at x = 0.6, z = -5.5
	var h := 3.15
	_box(root, "ArchPostN", Vector3(0.6, h * 0.5, -6.48), Vector3(0.14, h, 0.14), _mat_black, true)
	_box(root, "ArchPostS", Vector3(0.6, h * 0.5, -4.52), Vector3(0.14, h, 0.14), _mat_black, true)
	_box(root, "ArchBeam", Vector3(0.6, h + 0.22, -5.5), Vector3(0.18, 0.44, 2.30), _mat_black, false)
	_box(root, "ArchTrimTop", Vector3(0.6, h + 0.46, -5.5), Vector3(0.20, 0.04, 2.36), _mat_accent_white, false)
	_box(root, "ArchTrimBot", Vector3(0.6, h - 0.01, -5.5), Vector3(0.20, 0.04, 2.36), _mat_white, false)

	_label(root, "STATIC PLAY PATH\nONLY OBJECTS MOVE",
		Vector3(0.49, h + 0.22, -5.5), Vector3(0, -90, 0), 28, 0.0031, Color("ffffff"))
	_label(root, "STATIC ARCHITECTURE\nZERO TRANSITIONS",
		Vector3(0.71, h + 0.22, -5.5), Vector3(0, 90, 0), 28, 0.0031, Color("ffffff"))
