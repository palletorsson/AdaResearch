extends Node3D
class_name RainbowFullFloorPlayground
## Full-floor crazy Transformation + Primitive + Colour playground for Floor 31
## (Color_Rainbow). Built as a child of RainbowCelebration when config_full_floor
## is enabled.
##
## Features:
## - Progress Pride interactive '+' Color Crossroad (faithful to segmented rainbow
##   + crisp white zebra crosswalk): stepping on any colour floods the whole world
##   in that colour; stepping on crisp white resets to neutral.
## - Zero explicit flags: Trans, Non-Binary, and Progress Pride palettes are woven
##   directly into playable 3D jump caps, shuttles, carousel, prism portal, and steps.
## - Transformation: translating shuttle bridges over Shaft A (leaving SE arrival
##   pad clear) & Shaft B, rotating Non-Binary Primitive Carousel in East Bay,
##   X/Y/Z rotating Gyroscope Halo, and breathing-scale Platonic polyhedra totems.

const WorldWash := preload("res://commons/artifacts/rainbow_playground/world_color_wash.gd")
const GroundPhysics := preload("res://addons/godot-xr-tools/overrides/ground_physics.gd")
const GroundSettings := preload("res://addons/godot-xr-tools/overrides/ground_physics_settings.gd")
const PartyPickup := preload("res://algorithms/primitives/rainbow/rainbow_party_pickup.tscn")

# Palettes integrated directly into 3D objects (never hung as flat flags)
const TRANS_PALETTE := [
	Color("5bcefa"), Color("f5a9b8"), Color("ffffff"), Color("f5a9b8"), Color("5bcefa"),
]
const NONBINARY_PALETTE := [
	Color("ffc857"), Color("ffffff"), Color("a76ed5"), Color("282032"),
]
const RAINBOW_SIX := [
	Color("e40303"), Color("ff8c00"), Color("ffdd00"),
	Color("009933"), Color("004dff"), Color("750787"),
]

# Progress Pride crosswalk bar segments (faithful to segmented street crosswalk):
# White, Sky Cyan, Trans Pink, Brown, Black, Violet, Blue, Green, Yellow, Orange, Red
const CROSSWALK_SEGMENTS := [
	[Color("f8f9fb"), "Clear White"],
	[Color("5bcefa"), "Sky Cyan"],
	[Color("f5a9b8"), "Trans Pink"],
	[Color("6b3e26"), "Espresso Earth"],
	[Color("1e1b22"), "Obsidian Night"],
	[Color("750787"), "Royal Violet"],
	[Color("004dff"), "Royal Blue"],
	[Color("009933"), "Emerald Green"],
	[Color("ffdd00"), "Solar Yellow"],
	[Color("ff8c00"), "Tangerine"],
	[Color("e40303"), "Crimson Red"],
]

const CROSSROAD_Z := 4.6
const ROAD_Y := 0.032
const STRIPE_Y := 0.072

var _host: Node3D
var _time := 0.0
var _crosswalk_tiles: Array[Dictionary] = []
var _active_tile_idx := -1
var _shuttles: Array[Dictionary] = []
var _spinners: Array[Dictionary] = []
var _breathers: Array[Dictionary] = []
var _carousel: AnimatableBody3D
var _carousel_pods: Array[Dictionary] = []
var _carousel_angle := 0.0
var _gyro_rings: Array[Node3D] = []

func setup(host: Node3D) -> void:
	_host = host
	name = "FullFloorPlayground"
	_ensure_wash.call_deferred()
	_build_color_crossroad()
	_build_prism_finish_portal()
	_build_center_trans_jump_caps()
	_build_shaft_a_shuttle()
	_build_west_bay_primitives()
	_build_shaft_b_playground()
	_build_east_bay_carousel()
	_build_east_bay_primitives_and_caps()
	_build_crossroad_hoop_gateways()
	_build_full_floor_ribbons()
	_build_extra_party_cubes()

func _ensure_wash() -> void:
	if is_inside_tree():
		WorldWash.ensure(self, global_position.y)

# ═══════════════════════════════════════════════════════════════════════════
# 1. INTERACTIVE PROGRESS PRIDE COLOR CROSSROAD (+ INTERSECTION)
# ═══════════════════════════════════════════════════════════════════════════
func _build_color_crossroad() -> void:
	var root := Node3D.new()
	root.name = "ColorCrossroad"
	add_child(root)

	var asphalt := _mat(Color("262932"), 0.92, 0.02)
	var curb_mat := _mat(Color("f3f5fa"), 0.55, 0.02)
	var white_mat := _mat(Color("f8f9fb"), 0.48, 0.02)

	# East-West Boulevard roadbed: x in [-13.6, +13.6], z in [3.35, 5.85] (27.2 x 2.55 m)
	_box(root, "RoadEW", Vector3(0.0, ROAD_Y, CROSSROAD_Z), Vector3(27.2, 0.064, 2.55), asphalt, true)
	# Crisp white edge lines along EW roadbed
	for side in [-1.0, 1.0]:
		_box(root, "CurbEW_W", Vector3(-7.6, ROAD_Y + 0.035, CROSSROAD_Z + side * 1.24), Vector3(11.9, 0.010, 0.07), curb_mat)
		_box(root, "CurbEW_E", Vector3(7.6, ROAD_Y + 0.035, CROSSROAD_Z + side * 1.24), Vector3(11.9, 0.010, 0.07), curb_mat)

	# North-South Avenue roadbed: x in [-1.45, +1.45], z in [-5.95, +7.95] (2.9 x 13.9 m)
	_box(root, "RoadNS", Vector3(0.0, ROAD_Y, 1.0), Vector3(2.9, 0.064, 13.9), asphalt, true)
	for side in [-1.0, 1.0]:
		_box(root, "CurbNS_N", Vector3(side * 1.42, ROAD_Y + 0.035, -1.3), Vector3(0.07, 0.010, 9.2), curb_mat)
		_box(root, "CurbNS_S", Vector3(side * 1.42, ROAD_Y + 0.035, 6.95), Vector3(0.07, 0.010, 1.95), curb_mat)

	# East-West striped crosswalk bars: West arm (-13.3 .. -1.85) & East arm (+1.85 .. +13.3)
	var ew_pitch := 1.02
	var bar_w := 0.44
	for dir in [-1, 1]:
		for i in range(11):
			var cx: float = float(dir) * (2.25 + float(i) * ew_pitch)
			if i % 2 == 0:
				# Multi-colour Progress Pride segmented bar across Z (11 crisp blocks)
				_add_segmented_bar_z(root, cx, CROSSROAD_Z, bar_w, 2.28, dir < 0)
			else:
				# Crisp White Zebra Reset Bar
				_add_tile(root, "WhiteZebraEW_%d_%d" % [dir + 2, i], Vector3(cx, STRIPE_Y, CROSSROAD_Z),
					Vector3(bar_w * 0.92, 0.014, 2.28), Color("f8f9fb"), "Clear White", white_mat.duplicate())

	# North-South striped crosswalk bars: North arm (z = +2.95 .. -5.65) & South arm (z = +6.25 .. +7.65)
	var ns_pitch := 0.96
	for i in range(9):
		var cz: float = 2.85 - float(i) * ns_pitch
		if i % 2 == 0:
			_add_segmented_bar_x(root, 0.0, cz, 2.62, 0.44, (i / 2) % 2 == 1)
		else:
			_add_tile(root, "WhiteZebraNS_N_%d" % i, Vector3(0.0, STRIPE_Y, cz),
				Vector3(2.62, 0.014, 0.40), Color("f8f9fb"), "Clear White", white_mat.duplicate())

	# South approach stub (between rose & aqua mushrooms)
	_add_tile(root, "WhiteZebraNS_S_0", Vector3(0.0, STRIPE_Y, 6.28), Vector3(2.62, 0.014, 0.40), Color("f8f9fb"), "Clear White", white_mat.duplicate())
	_add_segmented_bar_x(root, 0.0, 7.12, 2.62, 0.50, false)

	# Central Crossroad Intersection Hub at (0.0, CROSSROAD_Z): bold 6-colour + white centre
	var hub_colours := [
		[Color("e40303"), "Crimson Red"],
		[Color("ff8c00"), "Tangerine"],
		[Color("ffdd00"), "Solar Yellow"],
		[Color("009933"), "Emerald Green"],
		[Color("004dff"), "Royal Blue"],
		[Color("750787"), "Royal Violet"],
		[Color("5bcefa"), "Sky Cyan"],
		[Color("f5a9b8"), "Trans Pink"],
	]
	# 4x2 vivid colour tiles flanking a crisp white central reset diamond!
	var xs := [-1.02, -0.34, 0.34, 1.02]
	var zs := [CROSSROAD_Z - 0.72, CROSSROAD_Z + 0.72]
	var idx := 0
	for zr in zs:
		for xr in xs:
			var pair: Array = hub_colours[idx % hub_colours.size()]
			_add_tile(root, "HubTile_%d" % idx, Vector3(xr, STRIPE_Y, zr),
				Vector3(0.62, 0.015, 0.76), pair[0], str(pair[1]), _mat(pair[0], 0.30, 0.08))
			idx += 1
	_add_tile(root, "HubResetCenter", Vector3(0.0, STRIPE_Y + 0.002, CROSSROAD_Z),
		Vector3(1.15, 0.015, 0.52), Color("f8f9fb"), "Clear White", white_mat.duplicate())

	# Crisp street-sign style plaque on a low colourful bollard at NE corner of crossroad
	var sign_pos := Vector3(1.80, 0.0, CROSSROAD_Z - 1.55)
	for b in range(4):
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.065
		cyl.bottom_radius = 0.075
		cyl.height = 0.24
		_mesh(root, "SignPost_%d" % b, cyl, sign_pos + Vector3(0, 0.12 + float(b) * 0.24, 0), _mat(NONBINARY_PALETTE[b], 0.32))
	_label(root, "COLOR CROSSROAD\nstep on a colour to paint the world\nwhite resets", sign_pos + Vector3(0, 1.28, 0), 34, 0.0018)

func _add_segmented_bar_z(parent: Node3D, cx: float, cz: float, bar_x: float, span_z: float, flip: bool) -> void:
	var n := CROSSWALK_SEGMENTS.size()
	var seg_z := span_z / float(n)
	var z_start := cz - span_z * 0.5
	for k in range(n):
		var src_k := (n - 1 - k) if flip else k
		var pair: Array = CROSSWALK_SEGMENTS[src_k]
		var col: Color = pair[0]
		var cname: String = str(pair[1])
		var sz := z_start + (float(k) + 0.5) * seg_z
		_add_tile(parent, "XWalkEW_%d_%d" % [int(cx * 10), k], Vector3(cx, STRIPE_Y, sz),
			Vector3(bar_x, 0.014, seg_z * 0.96), col, cname, _mat(col, 0.46, 0.02))

func _add_segmented_bar_x(parent: Node3D, cx: float, cz: float, span_x: float, bar_z: float, flip: bool) -> void:
	var n := CROSSWALK_SEGMENTS.size()
	var seg_x := span_x / float(n)
	var x_start := cx - span_x * 0.5
	for k in range(n):
		var src_k := (n - 1 - k) if flip else k
		var pair: Array = CROSSWALK_SEGMENTS[src_k]
		var col: Color = pair[0]
		var cname: String = str(pair[1])
		var sx := x_start + (float(k) + 0.5) * seg_x
		_add_tile(parent, "XWalkNS_%d_%d" % [int(cz * 10), k], Vector3(sx, STRIPE_Y, cz),
			Vector3(seg_x * 0.96, 0.014, bar_z), col, cname, _mat(col, 0.46, 0.02))

func _add_tile(parent: Node3D, label: String, at: Vector3, size: Vector3, col: Color, cname: String, mat: StandardMaterial3D) -> void:
	var mi := _box(parent, label, at, size, mat, false)
	var rect := Rect2(at.x - size.x * 0.5, at.z - size.z * 0.5, size.x, size.z)
	_crosswalk_tiles.append({
		"rect": rect,
		"color": col,
		"name": cname,
		"mesh": mi,
		"base_y": at.y,
		"pos": at,
	})

func sample_crosswalk_point(preferred_local: Vector3) -> Dictionary:
	var best_idx := -1
	var best_d := 1e9
	for i in range(_crosswalk_tiles.size()):
		var t: Dictionary = _crosswalk_tiles[i]
		var c: Color = t["color"]
		# Pick a rich vivid non-white tile (prefer crimson/warm red near preferred point)
		if c.r > 0.8 and c.g < 0.25 and c.b < 0.25:
			var p: Vector3 = t["pos"]
			var d := Vector2(p.x - preferred_local.x, p.z - preferred_local.z).length()
			if d < best_d:
				best_d = d
				best_idx = i
	if best_idx < 0 and not _crosswalk_tiles.is_empty():
		best_idx = 0
	if best_idx < 0:
		return {}
	var chosen: Dictionary = _crosswalk_tiles[best_idx]
	return {
		"pos": Vector3(chosen["pos"].x, 0.12, chosen["pos"].z),
		"color": chosen["color"],
		"name": chosen["name"],
	}

# ═══════════════════════════════════════════════════════════════════════════
# 2. KINETIC PRISM FINISH PORTAL (NO EXPLICIT HANGING FLAG!)
# ═══════════════════════════════════════════════════════════════════════════
func _build_prism_finish_portal() -> void:
	var portal := Node3D.new()
	portal.name = "KineticPrismFinishPortal"
	portal.position = Vector3(0.0, 0.0, -6.55)
	add_child(portal)

	# Twin sculptural Progress-coloured Primitive Totem Columns (left & right)
	for side in [-1.0, 1.0]:
		var px: float = side * 3.4
		var stack_colours := [
			Color("e40303"), Color("ff8c00"), Color("ffdd00"),
			Color("009933"), Color("004dff"), Color("750787"),
			Color("5bcefa"), Color("f5a9b8"),
		]
		var y := 0.0
		for k in range(stack_colours.size()):
			var h := 0.50
			if k % 3 == 0:
				var cyl := CylinderMesh.new()
				cyl.top_radius = 0.34 - float(k) * 0.015
				cyl.bottom_radius = 0.38 - float(k) * 0.015
				cyl.height = h
				_mesh(portal, "PortalDrum_%d_%d" % [int(side + 2), k], cyl, Vector3(px, y + h * 0.5, 0), _mat(stack_colours[k], 0.28, 0.15), true)
			elif k % 3 == 1:
				var sph := SphereMesh.new()
				sph.radius = 0.33 - float(k) * 0.012
				sph.height = sph.radius * 2.0
				_mesh(portal, "PortalBall_%d_%d" % [int(side + 2), k], sph, Vector3(px, y + h * 0.5, 0), _mat(stack_colours[k], 0.22, 0.25))
			else:
				var oct := _octahedron_mesh(0.36 - float(k) * 0.01)
				var m := _mesh(portal, "PortalOct_%d_%d" % [int(side + 2), k], oct, Vector3(px, y + h * 0.5, 0), _mat(stack_colours[k], 0.20, 0.30, true))
				_spinners.append({"node": m, "axis": Vector3.UP, "speed": 1.1 * side})
			y += h

		# Crown halo over each portal column
		var crown := TorusMesh.new()
		crown.inner_radius = 0.38
		crown.outer_radius = 0.48
		var cm := _mesh(portal, "PortalCrown_%d" % int(side + 2), crown, Vector3(px, y + 0.22, 0), _mat(Color("ffdc55"), 0.2, 0.4, true))
		_spinners.append({"node": cm, "axis": Vector3(0.4, 1.0, 0.2).normalized(), "speed": 0.9 * side})

	# Overhead rainbow bridge bars joining the twin totem columns into the spinning prism crown
	for k in range(3):
		var bar_y := 4.05 + float(k) * 0.24
		_box(portal, "PortalHeaderBar_%d" % k, Vector3(0.0, bar_y, 0.0), Vector3(6.8, 0.12, 0.14),
			_mat(TRANS_PALETTE[k], 0.22, 0.3, true))

	# Overhead counter-rotating concentric Portal Rings (walk cleanly underneath: bottom 2.18 m, top 4.98 m!)
	var ring_specs := [
		[1.26, 1.40, Color("5bcefa"), Vector3(0, 0, 1), 0.45],
		[0.98, 1.12, Color("f5a9b8"), Vector3(0, 0, 1), -0.62],
		[0.70, 0.84, Color("ffc857"), Vector3(0, 1, 0.35).normalized(), 0.78],
	]
	for i in range(ring_specs.size()):
		var spec: Array = ring_specs[i]
		var ring := TorusMesh.new()
		ring.inner_radius = float(spec[0])
		ring.outer_radius = float(spec[1])
		ring.rings = 36
		ring.ring_segments = 14
		var pivot := Node3D.new()
		pivot.name = "PortalRingPivot_%d" % i
		pivot.position = Vector3(0.0, 3.58, 0.0)
		portal.add_child(pivot)
		var rm := _mesh(pivot, "PortalRing_%d" % i, ring, Vector3.ZERO, _mat(spec[2], 0.22, 0.35, true))
		rm.rotation.x = PI * 0.5
		if i == 0:
			for g in range(6):
				var a := TAU * float(g) / 6.0
				_mesh(pivot, "PortalGem_%d" % g, _octahedron_mesh(0.20),
					Vector3(cos(a) * 1.33, sin(a) * 1.33, 0.0), _mat(RAINBOW_SIX[g], 0.2, 0.35, true))
		_spinners.append({"node": pivot, "axis": spec[3], "speed": float(spec[4])})

	# Marquee cleanly below ceiling soffit (y = 5.14 < 5.64)
	_box(portal, "FinishMarquee", Vector3(0.0, 5.14, 0.0), Vector3(4.2, 0.44, 0.14), _mat(Color("4c1669"), 0.35))
	_label(portal, "EVERY BODY WINS", Vector3(0.0, 5.14, 0.09), 66, 0.003)

# ═══════════════════════════════════════════════════════════════════════════
# 3. TRANS-STRIPED BOUNCY JUMP CAPS (CENTER EAST RUN)
# ═══════════════════════════════════════════════════════════════════════════
func _build_center_trans_jump_caps() -> void:
	var specs := [
		[Vector3(3.85, 0.38, 2.25), 1.05, 6.1],
		[Vector3(3.45, 0.70, 0.05), 1.08, 6.4],
		[Vector3(3.95, 1.02, -2.15), 1.08, 6.6],
		[Vector3(3.45, 0.68, -4.25), 1.02, 6.2],
	]
	for i in range(specs.size()):
		var s: Array = specs[i]
		_build_striped_jump_cap(self, "CenterTransCap_%d" % i, s[0], float(s[1]), TRANS_PALETTE, float(s[2]))
	_label(self, "BOUNCY JUMP CAPS", Vector3(3.85, 1.38, 2.75), 42, 0.0024)

func _build_striped_jump_cap(parent: Node3D, label: String, top_at: Vector3, radius: float, stripes: Array, jump_v: float) -> void:
	var holder := Node3D.new()
	holder.name = label
	holder.position = Vector3(top_at.x, 0.0, top_at.z)
	parent.add_child(holder)

	# Pearl fluted stem
	var stem_h := maxf(0.14, top_at.y - 0.24)
	var stem := CylinderMesh.new()
	stem.top_radius = radius * 0.34
	stem.bottom_radius = radius * 0.50
	stem.height = stem_h
	stem.radial_segments = 24
	_mesh(holder, "Stalk", stem, Vector3(0, stem_h * 0.5, 0), _mat(Color("f4d8ee"), 0.32, 0.12))

	# 5-layer striped bouncy cylinder cap (flag palette integrated into 3D volume!)
	var cap_h := 0.26
	var layer_h := cap_h / float(stripes.size())
	var cap_bottom := top_at.y - cap_h
	for i in range(stripes.size()):
		var cyl := CylinderMesh.new()
		var t0 := float(i) / float(stripes.size())
		var r := radius * (1.06 - 0.10 * t0)
		cyl.top_radius = r * 0.98
		cyl.bottom_radius = r
		cyl.height = layer_h
		cyl.radial_segments = 32
		_mesh(holder, "CapBand_%d" % i, cyl, Vector3(0, cap_bottom + (float(i) + 0.5) * layer_h, 0), _mat(stripes[i], 0.26, 0.18))

	# Concentric striped top rings so the palette reads from above too!
	for i in range(stripes.size()):
		var r_top := radius * (0.94 - float(i) * (0.76 / float(stripes.size())))
		var disc := CylinderMesh.new()
		disc.top_radius = r_top
		disc.bottom_radius = r_top
		disc.height = 0.012
		disc.radial_segments = 32
		_mesh(holder, "CapRing_%d" % i, disc, Vector3(0, top_at.y + 0.004 + float(i) * 0.002, 0), _mat(stripes[i], 0.24, 0.15))

	# Single clean solid collider + XRTools GroundPhysics jump booster
	var body := StaticBody3D.new()
	body.name = "BounceCollider"
	body.position = Vector3(0, top_at.y - cap_h * 0.5, 0)
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.radius = radius
	cshape.height = cap_h
	col.shape = cshape
	body.add_child(col)
	var ground := GroundPhysics.new()
	ground.name = "GroundPhysics"
	ground.physics = GroundSettings.new()
	ground.physics.flags = GroundSettings.GroundPhysicsFlags.JUMP_VELOCITY
	ground.physics.jump_velocity = jump_v
	body.add_child(ground)
	holder.add_child(body)

# ═══════════════════════════════════════════════════════════════════════════
# 4. SHAFT A NORTH TRANSLATING NON-BINARY SHUTTLE (SE LANDING KEPT 100% OPEN!)
# ═══════════════════════════════════════════════════════════════════════════
func _build_shaft_a_shuttle() -> void:
	# Shaft A is x in [-13, -7], z in [-3, +3].
	# Arrival CornerLanding pad is SE corner: x in [-8.6, -7.0], z in [+0.8, +3.0].
	# Our solid shuttle glides cleanly on the NORTH side (z = -1.65, width 2.0 m -> z in [-2.65, -0.65]).
	var shuttle := _make_shuttle_platform("ShaftA_NonBinaryShuttle", Vector3(2.6, 0.24, 2.0), NONBINARY_PALETTE)
	shuttle.position = Vector3(-10.0, 0.02, -1.65)
	add_child(shuttle)
	_shuttles.append({
		"body": shuttle,
		"origin": Vector3(-10.0, 0.02, -1.65),
		"axis": Vector3(1.0, 0.0, 0.0),
		"amp": 1.65,
		"speed": 0.65,
		"phase": 0.0,
	})

	# Guide rail bars along the north side of Shaft A so the translation reads clearly
	for side in [-1.0, 1.0]:
		_box(self, "ShaftARail_%d" % int(side + 2), Vector3(-10.0, -0.14, -1.65 + side * 0.85),
			Vector3(6.1, 0.07, 0.07), _mat(Color("a76ed5"), 0.3, 0.3))

	# Overhead spinning Trans halo high above Shaft A north side (never over arrival pad!)
	var halo_pivot := Node3D.new()
	halo_pivot.name = "ShaftAHalo"
	halo_pivot.position = Vector3(-10.0, 3.65, -1.65)
	add_child(halo_pivot)
	for i in range(2):
		var t := TorusMesh.new()
		t.inner_radius = 1.15 + float(i) * 0.35
		t.outer_radius = 1.28 + float(i) * 0.35
		var m := _mesh(halo_pivot, "HaloRing_%d" % i, t, Vector3.ZERO, _mat(TRANS_PALETTE[i], 0.24, 0.3, true))
		m.rotation.x = PI * 0.32 * (1.0 if i == 0 else -1.0)
	_spinners.append({"node": halo_pivot, "axis": Vector3.UP, "speed": 0.72})

# ═══════════════════════════════════════════════════════════════════════════
# 5. WEST BAY: BREATHING POLYHEDRA GARDEN & LOOKOUT BOOSTER CAP
# ═══════════════════════════════════════════════════════════════════════════
func _build_west_bay_primitives() -> void:
	# Respects rainbow-lookout deck (-18.75..-14.75, -2.75..+1.25) & ramp south (+1.25..+4.25),
	# plus structural columns at (-20, +/-7) and (-14, +/-7).
	var west := Node3D.new()
	west.name = "WestBayPlayground"
	add_child(west)

	# Bouncy Trans booster jump cap right at NE corner of rainbow-lookout so you can bounce up!
	_build_striped_jump_cap(west, "WestLookoutBoosterCap", Vector3(-14.6, 0.72, -3.75), 1.05, TRANS_PALETTE, 6.4)

	# Breathing-Scale Octahedron Totem (-18.2, 0, -5.4)
	_build_breathing_primitive_totem(west, "WestBreathingOctaTotem", Vector3(-18.2, 0.0, -5.4),
		[Color("e40303"), Color("ffdd00"), Color("5bcefa"), Color("f5a9b8")], 0.0)

	# Twisting Stacked Primitives Spire (-16.1, 0, -6.1)
	_build_breathing_primitive_totem(west, "WestPrimitivesSpire", Vector3(-16.1, 0.0, -6.1),
		[Color("750787"), Color("004dff"), Color("009933"), Color("ff8c00")], 2.1)

	# Low walkable colourful primitive stepping drums linking SW side to Crossroad
	var sw_steps := [
		[Vector3(-11.2, 0.26, 7.15), 0.72, Color("ff8c00")],
		[Vector3(-9.5, 0.44, 7.35), 0.76, Color("ffdd00")],
		[Vector3(-7.8, 0.28, 7.05), 0.72, Color("009933")],
	]
	for i in range(sw_steps.size()):
		var st: Array = sw_steps[i]
		var p: Vector3 = st[0]
		var cyl := CylinderMesh.new()
		cyl.top_radius = float(st[1])
		cyl.bottom_radius = float(st[1]) * 1.08
		cyl.height = p.y
		cyl.radial_segments = 24
		var m := _mesh(west, "SWPrimStep_%d" % i, cyl, Vector3(p.x, p.y * 0.5, p.z), _mat(st[2], 0.28, 0.14), true)
		var g := GroundPhysics.new()
		g.physics = GroundSettings.new()
		g.physics.flags = GroundSettings.GroundPhysicsFlags.JUMP_VELOCITY
		g.physics.jump_velocity = 5.6
		m.get_child(0).add_child(g)

# ═══════════════════════════════════════════════════════════════════════════
# 6. SHAFT B: TWIN COUNTER-SLIDING SHUTTLES + TRANS BOUNCE DRUM + X/Y/Z GYRO
# ═══════════════════════════════════════════════════════════════════════════
func _build_shaft_b_playground() -> void:
	# Shaft B is x in [+7, +13], z in [-3, +3]. Completely open void on Floor 31!
	var sb := Node3D.new()
	sb.name = "ShaftBPlayground"
	add_child(sb)

	# Two sweeping colourful arch support ribs anchored cleanly to N/S concrete edges
	for side in [-1.0, 1.0]:
		_box(sb, "ShaftBBridgeBeam_%d" % int(side + 2), Vector3(10.0 + side * 0.72, 0.08, 0.0),
			Vector3(0.18, 0.18, 6.24), _mat(Color("5bcefa") if side < 0 else Color("f5a9b8"), 0.28, 0.2), true)

	# Central Suspended 5-band Trans Bouncy Jump Drum right over the heart of Shaft B!
	_build_striped_jump_cap(sb, "ShaftBCentralBounceDrum", Vector3(10.0, 0.42, 0.0), 1.22, TRANS_PALETTE, 6.8)

	# Twin Counter-Translating Rainbow Shuttle Bridges (North & South lanes across Shaft B)
	var shuttle_n := _make_shuttle_platform("ShaftB_NorthShuttle", Vector3(2.35, 0.22, 1.65),
		[Color("e40303"), Color("ff8c00"), Color("ffdd00"), Color("009933")])
	shuttle_n.position = Vector3(10.0, 0.02, -1.95)
	sb.add_child(shuttle_n)
	_shuttles.append({
		"body": shuttle_n,
		"origin": Vector3(10.0, 0.02, -1.95),
		"axis": Vector3(1.0, 0.0, 0.0),
		"amp": 1.65,
		"speed": 0.72,
		"phase": 0.0,
	})

	var shuttle_s := _make_shuttle_platform("ShaftB_SouthShuttle", Vector3(2.35, 0.22, 1.65),
		[Color("009933"), Color("004dff"), Color("750787"), Color("f5a9b8")])
	shuttle_s.position = Vector3(10.0, 0.02, 1.95)
	sb.add_child(shuttle_s)
	_shuttles.append({
		"body": shuttle_s,
		"origin": Vector3(10.0, 0.02, 1.95),
		"axis": Vector3(1.0, 0.0, 0.0),
		"amp": 1.65,
		"speed": 0.72,
		"phase": PI,
	})

	# Guide tracks along Shaft B
	for zlane in [-1.95, 1.95]:
		_box(sb, "ShaftBTrack_%d" % int(zlane * 10), Vector3(10.0, -0.14, zlane),
			Vector3(6.1, 0.07, 0.14), _mat(Color("ffdd00"), 0.3, 0.25))

	# Overhead Kinetic X/Y/Z Gyroscope Halo hovering high above Shaft B (Trans_Rotation homage!)
	var gyro := Node3D.new()
	gyro.name = "ShaftBGyroscope"
	gyro.position = Vector3(10.0, 3.35, 0.0)
	sb.add_child(gyro)
	var gyro_specs := [
		[1.95, 2.12, Color("ff4fa3")],
		[1.48, 1.65, Color("5bcefa")],
		[1.02, 1.18, Color("ffc857")],
	]
	for i in range(gyro_specs.size()):
		var gs: Array = gyro_specs[i]
		var rmesh := TorusMesh.new()
		rmesh.inner_radius = float(gs[0])
		rmesh.outer_radius = float(gs[1])
		rmesh.rings = 36
		rmesh.ring_segments = 12
		var node := _mesh(gyro, "GyroRing_%d" % i, rmesh, Vector3.ZERO, _mat(gs[2], 0.20, 0.35, true))
		_gyro_rings.append(node)
	# Glowing octahedron core inside the gyroscope
	var core := _mesh(gyro, "GyroCore", _octahedron_mesh(0.45), Vector3.ZERO, _mat(Color("ffffff"), 0.15, 0.4, true))
	_spinners.append({"node": core, "axis": Vector3(1, 1, 0).normalized(), "speed": 1.6})

# ═══════════════════════════════════════════════════════════════════════════
# 7. EAST BAY: GIANT WALKABLE NON-BINARY PRIMITIVE CAROUSEL
# ═══════════════════════════════════════════════════════════════════════════
func _build_east_bay_carousel() -> void:
	# Center at (+16.9, 0.02, 0.0), radius 3.15 m -> x in [13.75, 20.05], z in [-3.15, +3.15]
	# Completely clear of Shaft B (x <= 13) and all 4 East columns (x=14/20, z=+/-7)!
	_carousel = AnimatableBody3D.new()
	_carousel.name = "NonBinaryPrimitiveCarousel"
	_carousel.sync_to_physics = true
	_carousel.position = Vector3(16.9, 0.02, 0.0)
	add_child(_carousel)

	# Solid walkable turntable cylinder collider
	var col := CollisionShape3D.new()
	var cshape := CylinderShape3D.new()
	cshape.radius = 3.18
	cshape.height = 0.24
	col.shape = cshape
	col.position = Vector3(0, 0.12, 0)
	_carousel.add_child(col)

	# 4 concentric Non-Binary striped rings built directly into the turntable floor!
	var ring_radii := [3.18, 2.46, 1.74, 1.02]
	for i in range(NONBINARY_PALETTE.size()):
		var disc := CylinderMesh.new()
		disc.top_radius = ring_radii[i]
		disc.bottom_radius = ring_radii[i] + (0.04 if i == 0 else 0.0)
		disc.height = 0.24 + float(i) * 0.006
		disc.radial_segments = 48
		_mesh(_carousel, "CarouselBand_%d" % i, disc, Vector3(0, disc.height * 0.5, 0), _mat(NONBINARY_PALETTE[i], 0.28, 0.14))

	# 8 radial rainbow spokes accenting the rotation clearly
	for i in range(8):
		var a := TAU * float(i) / 8.0
		var spoke := _box(_carousel, "CarouselSpoke_%d" % i,
			Vector3(cos(a) * 1.95, 0.268, sin(a) * 1.95), Vector3(1.9, 0.016, 0.12), _mat(RAINBOW_SIX[i % RAINBOW_SIX.size()], 0.25, 0.2))
		spoke.rotation.y = -a

	# Central towering Rainbow Spindle (height 4.55 m < 5.64 m ceiling!)
	var sp_col := CollisionShape3D.new()
	var sp_shape := CylinderShape3D.new()
	sp_shape.radius = 0.44
	sp_shape.height = 4.0
	sp_col.shape = sp_shape
	sp_col.position = Vector3(0, 2.2, 0)
	_carousel.add_child(sp_col)
	for k in range(6):
		var drum := CylinderMesh.new()
		drum.top_radius = 0.42 - float(k) * 0.03
		drum.bottom_radius = 0.45 - float(k) * 0.03
		drum.height = 0.62
		_mesh(_carousel, "SpindleDrum_%d" % k, drum, Vector3(0, 0.55 + float(k) * 0.62, 0), _mat(RAINBOW_SIX[k], 0.25, 0.2), false)

	# Crown canopy torus + 6 colourful canopy cones
	var canopy := TorusMesh.new()
	canopy.inner_radius = 2.65
	canopy.outer_radius = 2.95
	canopy.rings = 40
	canopy.ring_segments = 14
	_mesh(_carousel, "CarouselCanopyRing", canopy, Vector3(0, 4.35, 0), _mat(Color("ffc857"), 0.22, 0.35, true))
	var canopy_inner := TorusMesh.new()
	canopy_inner.inner_radius = 1.65
	canopy_inner.outer_radius = 1.85
	_mesh(_carousel, "CarouselCanopyInner", canopy_inner, Vector3(0, 4.55, 0), _mat(Color("a76ed5"), 0.22, 0.35, true))

	# 6 Orbiting Primitive Ride Pods at alternating radii ("same turn, different distance"!)
	for i in range(6):
		var a := TAU * float(i) / 6.0
		var r := 2.48 if i % 2 == 0 else 1.56
		var pod_x := cos(a) * r
		var pod_z := sin(a) * r
		# Pole connecting deck to canopy ring
		var pole := CylinderMesh.new()
		pole.top_radius = 0.045
		pole.bottom_radius = 0.045
		pole.height = 4.1
		_mesh(_carousel, "CarouselPole_%d" % i, pole, Vector3(pod_x, 2.3, pod_z), _mat(Color("fff0d9"), 0.25, 0.5))

		# Bobbing primitive ride pod (alternating Sphere, Octahedron, Cone-Top Cylinder)
		var pod := Node3D.new()
		pod.name = "CarouselPod_%d" % i
		pod.position = Vector3(pod_x, 1.05, pod_z)
		_carousel.add_child(pod)
		var col_c: Color = RAINBOW_SIX[i]
		if i % 3 == 0:
			var seat := SphereMesh.new()
			seat.radius = 0.44
			seat.height = 0.88
			_mesh(pod, "PodSphere", seat, Vector3.ZERO, _mat(col_c, 0.22, 0.25, true))
		elif i % 3 == 1:
			_mesh(pod, "PodOcta", _octahedron_mesh(0.50), Vector3.ZERO, _mat(col_c, 0.20, 0.32, true))
		else:
			var cone := CylinderMesh.new()
			cone.top_radius = 0.04
			cone.bottom_radius = 0.46
			cone.height = 0.84
			_mesh(pod, "PodCone", cone, Vector3.ZERO, _mat(col_c, 0.24, 0.22, true))
		_carousel_pods.append({"node": pod, "base_y": 1.08, "phase": float(i) * 1.05})

	_label(self, "PRIMITIVE CAROUSEL", Vector3(16.9, 4.95, 3.05), 50, 0.0028)

# ═══════════════════════════════════════════════════════════════════════════
# 8. EAST BAY NORTH BREATHING TOTEMS & SOUTH-EAST JUMP CAP TRAMPOLINE RUN
# ═══════════════════════════════════════════════════════════════════════════
func _build_east_bay_primitives_and_caps() -> void:
	var east := Node3D.new()
	east.name = "EastBayParks"
	add_child(east)

	# North-East Breathing-Scale Primitive Totem Trio (clear of columns at 14/-7 and 20/-7)
	_build_breathing_primitive_totem(east, "EastTotem_A", Vector3(15.7, 0.0, -5.65),
		[Color("e40303"), Color("ff8c00"), Color("ffdd00"), Color("ffffff")], 0.5)
	_build_breathing_primitive_totem(east, "EastTotem_B", Vector3(17.4, 0.0, -6.35),
		[Color("009933"), Color("5bcefa"), Color("004dff"), Color("f5a9b8")], 2.4)
	_build_breathing_primitive_totem(east, "EastTotem_C", Vector3(19.0, 0.0, -5.35),
		[Color("750787"), Color("a76ed5"), Color("ffc857"), Color("5bcefa")], 4.1)

	# South-East Rainbow & Progress Jump-Cap Trampoline Run (clear of columns at 14/+7 and 20/+7)
	var se_caps := [
		[Vector3(15.25, 0.38, 5.25), 0.96, TRANS_PALETTE, 6.2],
		[Vector3(16.75, 0.74, 6.25), 1.02, NONBINARY_PALETTE, 6.5],
		[Vector3(18.35, 1.06, 5.20), 1.05, RAINBOW_SIX.slice(0, 5), 6.8],
		[Vector3(19.10, 0.62, 3.85), 0.92, TRANS_PALETTE, 6.3],
	]
	for i in range(se_caps.size()):
		var c: Array = se_caps[i]
		_build_striped_jump_cap(east, "EastJumpCap_%d" % i, c[0], float(c[1]), c[2], float(c[3]))

# ═══════════════════════════════════════════════════════════════════════════
# 9. SPINNING CROSSROAD HOOP GATEWAYS + 39 m OVERHEAD RIBBONS + PARTY CUBES
# ═══════════════════════════════════════════════════════════════════════════
func _build_crossroad_hoop_gateways() -> void:
	# West Crossroad Trans Hoop Gateway at (-13.4, 0, +4.6)
	_build_hoop_gateway("WestCrossroadGate", Vector3(-13.4, 0.0, CROSSROAD_Z), TRANS_PALETTE, 1.0)
	# East Crossroad Progress Hoop Gateway at (+13.4, 0, +4.6)
	_build_hoop_gateway("EastCrossroadGate", Vector3(13.4, 0.0, CROSSROAD_Z), RAINBOW_SIX, -1.0)

func _build_hoop_gateway(label: String, at: Vector3, palette: Array, spin_dir: float) -> void:
	var g := Node3D.new()
	g.name = label
	g.position = at
	add_child(g)
	# Twin candy posts flanking the 2.5 m wide crossroad
	for side in [-1.0, 1.0]:
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.10
		cyl.bottom_radius = 0.13
		cyl.height = 2.6
		_mesh(g, "GatePost_%d" % int(side + 2), cyl, Vector3(0.0, 1.3, side * 1.55), _mat(palette[0 if side < 0 else 1], 0.25, 0.25), true)
	# Spinning ring framing the East-West boulevard (spans across Z!)
	var pivot := Node3D.new()
	pivot.name = "HoopPivot"
	pivot.position = Vector3(0.0, 2.55, 0.0)
	g.add_child(pivot)
	for i in range(2):
		var ring := TorusMesh.new()
		ring.inner_radius = 1.50 + float(i) * 0.28
		ring.outer_radius = 1.66 + float(i) * 0.28
		ring.rings = 36
		ring.ring_segments = 12
		var rm := _mesh(pivot, "Hoop_%d" % i, ring, Vector3.ZERO, _mat(palette[(i * 2) % palette.size()], 0.22, 0.35, true))
		rm.rotation.z = PI * 0.5
		if i == 1:
			rm.rotation.x = 0.28
	_spinners.append({"node": pivot, "axis": Vector3(1, 0, 0), "speed": 0.45 * spin_dir})

func _build_full_floor_ribbons() -> void:
	# 6 sweeping colourful undulating ribbons spanning all 39 m East-West (-19.5 .. +19.5)!
	var colours := [
		Color("5bcefa"), Color("f5a9b8"), Color("ffdd00"),
		Color("a76ed5"), Color("00d4b8"), Color("ff5e99"),
	]
	var z_lanes: Array[float] = [-4.8, -3.2, 0.8, 2.3, 3.8, 5.2]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps := 72
	for r in range(z_lanes.size()):
		st.set_color(colours[r % colours.size()])
		for s in range(steps):
			var x0: float = lerpf(-19.4, 19.4, float(s) / float(steps))
			var x1: float = lerpf(-19.4, 19.4, float(s + 1) / float(steps))
			var verts: Array[Vector2] = [
				Vector2(x0, 0.0), Vector2(x0, 1.0), Vector2(x1, 1.0),
				Vector2(x0, 0.0), Vector2(x1, 1.0), Vector2(x1, 0.0),
			]
			for v: Vector2 in verts:
				var phase: float = v.x * 0.42 + float(r) * 0.95
				var z_pos: float = z_lanes[r] + sin(phase) * 0.45 + v.y * 0.28
				var y_pos: float = 4.96 + cos(phase * 1.15) * 0.22
				st.add_vertex(Vector3(v.x, y_pos, z_pos))
	var mat := _mat(Color.WHITE, 0.4)
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_mesh(self, "FullFloorFestivalRibbons", st.commit(), Vector3.ZERO, mat)

func _build_extra_party_cubes() -> void:
	if _host == null or _host.get("walk_pickups") == null:
		return
	var extra_positions := [
		Vector3(-16.5, 1.15, -0.75),  # On rainbow-lookout deck
		Vector3(-10.0, 0.65, -1.65),  # Above Shaft A shuttle
		Vector3(10.0, 0.95, 0.0),     # Above Shaft B central jump drum
		Vector3(16.9, 0.75, 2.2),     # On East Bay Carousel
		Vector3(18.35, 1.55, 5.20),   # Over South-East Jump Cap
	]
	var pickups: Node3D = _host.walk_pickups
	for i in range(extra_positions.size()):
		var cube: Node3D = PartyPickup.instantiate()
		cube.name = "FloorWideCube_%d" % (i + 1)
		cube.position = extra_positions[i]
		if _host.has_method("_cube_collected"):
			cube.party_collected.connect(_host._cube_collected)
		pickups.add_child(cube)

# ═══════════════════════════════════════════════════════════════════════════
# REUSABLE PRIMITIVE & TRANSFORMATION BUILDERS
# ═══════════════════════════════════════════════════════════════════════════
func _build_breathing_primitive_totem(parent: Node3D, label: String, at: Vector3, colours: Array, phase: float) -> void:
	var totem := Node3D.new()
	totem.name = label
	totem.position = at
	parent.add_child(totem)

	# Solid wide coloured drum plinth (y: 0..0.75)
	var base := CylinderMesh.new()
	base.top_radius = 0.68
	base.bottom_radius = 0.78
	base.height = 0.72
	base.radial_segments = 24
	_mesh(totem, "BaseDrum", base, Vector3(0, 0.36, 0), _mat(colours[0], 0.3, 0.14), true)

	# Middle tapered prism/cone pedestal (y: 0.72..1.72)
	var mid := CylinderMesh.new()
	mid.top_radius = 0.32
	mid.bottom_radius = 0.58
	mid.height = 1.0
	mid.radial_segments = 6
	_mesh(totem, "HexCone", mid, Vector3(0, 1.22, 0), _mat(colours[1], 0.25, 0.2), true)

	# Upper Breathing-Scale Polyhedron (scales smoothly 0.82x..1.20x & rotates!)
	var breather := Node3D.new()
	breather.name = "BreathingCrown"
	breather.position = Vector3(0, 2.55, 0)
	totem.add_child(breather)
	_mesh(breather, "PolyCore", _octahedron_mesh(0.76), Vector3.ZERO, _mat(colours[2], 0.18, 0.35, true))
	var halo := TorusMesh.new()
	halo.inner_radius = 0.82
	halo.outer_radius = 0.96
	var hm := _mesh(breather, "PolyHalo", halo, Vector3.ZERO, _mat(colours[3 % colours.size()], 0.20, 0.35, true))
	hm.rotation.x = 0.55
	_breathers.append({"node": breather, "phase": phase, "base_y": 2.55})

	# Top floating sphere finial (y: 3.95)
	var finial := SphereMesh.new()
	finial.radius = 0.34
	finial.height = 0.68
	var fm := _mesh(totem, "TopSphere", finial, Vector3(0, 3.95, 0), _mat(colours[0], 0.22, 0.3, true))
	_spinners.append({"node": fm, "axis": Vector3.UP, "speed": 0.9})

func _make_shuttle_platform(label: String, size: Vector3, palette: Array) -> AnimatableBody3D:
	var body := AnimatableBody3D.new()
	body.name = label
	body.sync_to_physics = true
	var col := CollisionShape3D.new()
	var bshape := BoxShape3D.new()
	bshape.size = size
	col.shape = bshape
	body.add_child(col)

	var stripe_w := size.x / float(palette.size())
	for i in range(palette.size()):
		var sx := -size.x * 0.5 + (float(i) + 0.5) * stripe_w
		_box(body, "Stripe_%d" % i, Vector3(sx, 0.0, 0.0), Vector3(stripe_w * 0.98, size.y, size.z), _mat(palette[i], 0.28, 0.16))
	# Crisp white safety edge bumpers on +/-Z
	for side in [-1.0, 1.0]:
		_box(body, "Edge_%d" % int(side + 2), Vector3(0.0, size.y * 0.42, side * (size.z * 0.5 - 0.04)),
			Vector3(size.x, 0.05, 0.07), _mat(Color("fffaf2"), 0.3))
	return body

# ═══════════════════════════════════════════════════════════════════════════
# LIVE ANIMATION & CROSSWALK FOOT-STEP INTERACTION
# ═══════════════════════════════════════════════════════════════════════════
func _physics_process(delta: float) -> void:
	_time += delta

	# Translating shuttle bridges (native Jolt AnimatableBody3D motion)
	for s in _shuttles:
		var body: AnimatableBody3D = s["body"]
		var origin: Vector3 = s["origin"]
		var axis: Vector3 = s["axis"]
		var offset: float = sin(_time * float(s["speed"]) + float(s["phase"])) * float(s["amp"])
		body.position = origin + axis * offset

	# Rotating East Bay Non-Binary Primitive Carousel
	if is_instance_valid(_carousel):
		_carousel_angle += delta * 0.42
		_carousel.rotation.y = _carousel_angle
		for pod in _carousel_pods:
			var n: Node3D = pod["node"]
			n.position.y = float(pod["base_y"]) + sin(_time * 1.9 + float(pod["phase"])) * 0.24
			n.rotation.y += delta * 0.9

func _process(delta: float) -> void:
	# Pure visual spinners, gyroscope rings, and breathing-scale polyhedra
	for sp in _spinners:
		var n: Node3D = sp["node"]
		if is_instance_valid(n):
			n.rotate(sp["axis"], delta * float(sp["speed"]))

	for i in range(_gyro_rings.size()):
		var ring: Node3D = _gyro_rings[i]
		if not is_instance_valid(ring):
			continue
		if i == 0:
			ring.rotation.x += delta * 0.65
			ring.rotation.y += delta * 0.35
		elif i == 1:
			ring.rotation.y -= delta * 0.85
			ring.rotation.z += delta * 0.45
		else:
			ring.rotation.z -= delta * 1.05
			ring.rotation.x += delta * 0.55

	for br in _breathers:
		var n: Node3D = br["node"]
		if is_instance_valid(n):
			var ph := float(br["phase"])
			var s := 1.0 + sin(_time * 1.55 + ph) * 0.18
			n.scale = Vector3.ONE * s
			n.rotation.y += delta * 0.8
			n.position.y = float(br["base_y"]) + sin(_time * 1.2 + ph) * 0.14

	_update_crosswalk_stepping(delta)

func _update_crosswalk_stepping(delta: float) -> void:
	var game := get_tree().get_first_node_in_group("void_game")
	if not is_instance_valid(game) or game.get("body") == null:
		return
	var visitor_world: Vector3 = (game.body as Node3D).global_position
	var local_pt := to_local(visitor_world)

	var hit_idx := -1
	if local_pt.y > -0.6 and local_pt.y < 1.15:
		var pt2 := Vector2(local_pt.x, local_pt.z)
		for i in range(_crosswalk_tiles.size()):
			var rect: Rect2 = _crosswalk_tiles[i]["rect"]
			if rect.has_point(pt2):
				hit_idx = i
				break

	if hit_idx != _active_tile_idx:
		if _active_tile_idx >= 0 and _active_tile_idx < _crosswalk_tiles.size():
			var prev: Dictionary = _crosswalk_tiles[_active_tile_idx]
			var pmat := (prev["mesh"] as MeshInstance3D).material_override as StandardMaterial3D
			if pmat != null:
				pmat.emission_enabled = false
		_active_tile_idx = hit_idx
		if hit_idx >= 0:
			var tile: Dictionary = _crosswalk_tiles[hit_idx]
			var c: Color = tile["color"]
			var cname: String = str(tile["name"])
			var tmat := (tile["mesh"] as MeshInstance3D).material_override as StandardMaterial3D
			if tmat != null:
				tmat.emission_enabled = true
				tmat.emission = c
				tmat.emission_energy_multiplier = 0.75
			var wash: Node3D = WorldWash.ensure(self, global_position.y)
			if wash != null and wash.has_method("tint_from_crosswalk"):
				wash.call("tint_from_crosswalk", c, cname)

	# Subtle bouncy height pop on the currently stepped crosswalk tile
	for i in range(_crosswalk_tiles.size()):
		var t: Dictionary = _crosswalk_tiles[i]
		var mi: MeshInstance3D = t["mesh"]
		var target_y := float(t["base_y"]) + (0.022 if i == _active_tile_idx else 0.0)
		mi.position.y = move_toward(mi.position.y, target_y, delta * 0.24)

# ═══════════════════════════════════════════════════════════════════════════
# MESH / MATERIAL HELPERS
# ═══════════════════════════════════════════════════════════════════════════
func _mat(c: Color, roughness: float = 0.30, metallic: float = 0.08, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	m.metallic = metallic
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.22
	return m

func _mesh(parent: Node3D, label: String, mesh: Mesh, at: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	n.mesh = mesh
	n.material_override = mat
	n.position = at
	parent.add_child(n)
	if solid:
		n.create_convex_collision()
	return n

func _box(parent: Node3D, label: String, at: Vector3, size: Vector3, mat: Material, solid: bool = false) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return _mesh(parent, label, b, at, mat, solid)

func _label(parent: Node3D, text: String, at: Vector3, font_size: int = 48, pixel_size: float = 0.0025) -> void:
	var l := Label3D.new()
	l.text = text
	l.position = at
	l.font_size = font_size
	l.pixel_size = pixel_size
	l.outline_size = 6
	l.modulate = Color("fffdf8")
	parent.add_child(l)

func _octahedron_mesh(radius: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := Vector3(0, radius, 0)
	var bot := Vector3(0, -radius, 0)
	var ring := [
		Vector3(radius, 0, 0),
		Vector3(0, 0, radius),
		Vector3(-radius, 0, 0),
		Vector3(0, 0, -radius),
	]
	for i in range(4):
		var a: Vector3 = ring[i]
		var b: Vector3 = ring[(i + 1) % 4]
		# Upper pyramid face
		st.add_vertex(top)
		st.add_vertex(b)
		st.add_vertex(a)
		# Lower pyramid face
		st.add_vertex(bot)
		st.add_vertex(a)
		st.add_vertex(b)
	st.generate_normals()
	return st.commit()
