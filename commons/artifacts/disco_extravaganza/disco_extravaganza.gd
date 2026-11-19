extends Node3D
## Floor 33 (Color_Grid_Pallet) Super Extravaganza Disco Stage!
## Transforms "Direction palettes | Walk along X and Z to recolour the central grid"
## into an elevated walkable blinking disco floor with:
## - 0.45 m raised obsidian-and-neon stage with 3 illuminated stairs & center ramp
## - Beat-synced blinking/rippling/strobing GridMultiMesh preserving X/Z direction palettes
## - Super-large 2.40 m faceted mirrored ceiling disco ball + 4 satellite disco balls
## - Chrome lighting truss canopy + 4 corner 3D animated Audio Equalizer towers
## - Sweeping volumetric additive laser cones + 96 orbiting mirror-ball reflection dots
## - Hard 128 / 134 BPM club disco synth music (scoped cleanly to Floor 33)
## - Full-wall illuminated Studio 54 Dance Mirror where Care Unit Model B sees her own
##   live beat-synced disco dance moves (Fever, Hustle, Vogue, Robot)!

const MusicScript := preload("res://commons/artifacts/disco_extravaganza/hard_disco_music.gd")
const MirrorScript := preload("res://commons/artifacts/disco_extravaganza/disco_dance_mirror.gd")
const Controls := preload("res://commons/ui/control_panel.gd")

const STAGE_H := 0.45
const STAGE_W := 9.45
const STAGE_D := 11.45

const DANCE_MODES: Array[String] = ["fever", "hustle", "vogue", "robot", "off"]
const PATTERN_NAMES: Array[String] = ["AUTO", "CHECKER", "RIPPLE", "EQ WAVE", "CHASER", "STROBE"]
const NEON_COLORS: Array[Color] = [
	Color("ff2fa6"), Color("00f5ff"), Color("ffe600"), Color("b84dff"), Color("39ff88"), Color("ff5e2b"),
]
const FALLBACK_PALETTE: Array[Color] = [
	Color("ff2fa6"), Color("00f5ff"), Color("ffe600"), Color("b84dff"), Color("ff5e2b"), Color("22e3cc"),
]

var _owner_floor: Node3D
var _grid_mm: MultiMesh
var _frame: Node3D
var _music: AudioStreamPlayer
var _mirror: Node3D

var _giant_ball: Node3D
var _satellite_balls: Array[Node3D] = []
var _rim_mats: Array[StandardMaterial3D] = []
var _step_trim_mats: Array[StandardMaterial3D] = []
var _eq_bars: Array = []  # 4 towers x 8 MeshInstance3D bars
var _lasers: Array[Dictionary] = []
var _mirror_dots: MultiMeshInstance3D
var _dot_specs: Array[Dictionary] = []
var _club_lights: Array[OmniLight3D] = []
var _turntables: Array[Node3D] = []
var _halo_mat: StandardMaterial3D

var _dance_idx: int = 0
var _pattern_idx: int = 0  # 0 = AUTO cycling all 5 patterns
var _dj_readout: Label
var _cell_coords: Array[Vector2i] = []
var _on_stage: bool = false
var _last_palette_idx: int = -1
var _cached_palette: Array[Color] = []

func setup(owner_floor: Node3D, grid_frame: Node3D, grid_multimesh: MultiMesh) -> void:
	name = "DiscoExtravaganza"
	_owner_floor = owner_floor
	_frame = grid_frame
	_grid_mm = grid_multimesh
	_cached_palette = FALLBACK_PALETTE.duplicate()
	_cache_cell_coords()
	_build_raised_stage_and_stairs()
	_build_grout_grid()
	_build_truss_and_eq_towers()
	_build_giant_disco_ball_and_satellites()
	_build_volumetric_lasers_and_dots()
	_build_dance_mirror()
	_build_dj_booth()
	_build_hard_disco_music()

func _cache_cell_coords() -> void:
	_cell_coords.clear()
	if _owner_floor == null:
		return
	var g: Variant = _owner_floor.get("grid")
	if g == null:
		return
	var positions: Array = g.cube_positions
	for p_var in positions:
		var p: Vector3i = p_var
		_cell_coords.append(Vector2i(p.x, p.z))

# ═══════════════════════════════════════════════════════════════════════════
# 1. RAISED WALKABLE DISCO STAGE + 3 ILLUMINATED STAIRS & CENTER RAMP
# ═══════════════════════════════════════════════════════════════════════════
func _build_raised_stage_and_stairs() -> void:
	var stage_root := Node3D.new()
	stage_root.name = "DiscoStageStructure"
	add_child(stage_root)

	var obsidian := _mat(Color("16131f"), 0.25, 0.55)
	var chrome := _mat(Color("cfd6e6"), 0.18, 0.88)

	# Main solid walkable raised stage deck (top = 0.442 m; GridMultiMesh top = 0.460 m)
	_box(stage_root, "StagePlinth", Vector3(0.0, 0.221, 0.0), Vector3(STAGE_W, 0.442, STAGE_D), obsidian, true)

	# Pulsing neon rim LED strips around all 4 stage edges (top & bottom skirt!)
	for edge_idx in range(4):
		var col: Color = NEON_COLORS[edge_idx % NEON_COLORS.size()]
		var rim_mat := _mat(col, 0.15, 0.2, true, 1.8)
		_rim_mats.append(rim_mat)
		if edge_idx < 2:
			var sz := (STAGE_D * 0.5 + 0.03) * (1.0 if edge_idx == 0 else -1.0)
			_box(stage_root, "RimStripTop_%d" % edge_idx, Vector3(0.0, 0.415, sz), Vector3(STAGE_W + 0.08, 0.055, 0.055), rim_mat)
			_box(stage_root, "RimStripBot_%d" % edge_idx, Vector3(0.0, 0.045, sz), Vector3(STAGE_W + 0.08, 0.050, 0.055), rim_mat)
		else:
			var sx := (STAGE_W * 0.5 + 0.03) * (1.0 if edge_idx == 2 else -1.0)
			_box(stage_root, "RimStripTop_%d" % edge_idx, Vector3(sx, 0.415, 0.0), Vector3(0.055, 0.055, STAGE_D + 0.08), rim_mat)
			_box(stage_root, "RimStripBot_%d" % edge_idx, Vector3(sx, 0.045, 0.0), Vector3(0.055, 0.050, STAGE_D + 0.08), rim_mat)

	# Chrome corner bumper plates
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_box(stage_root, "CornerPlate_%d_%d" % [int(sx + 2), int(sz + 2)],
				Vector3(sx * (STAGE_W * 0.5 + 0.02), 0.225, sz * (STAGE_D * 0.5 + 0.02)),
				Vector3(0.24, 0.46, 0.24), chrome)

	# FRONT SOUTH GRAND ENTRY: smooth center ramp + flanking 3-step glowing disco stairs
	# Centered at x = +0.40, z = +5.72..+6.72 (fits cleanly between AddressPlinth x<=-1.48 and science_screen x=3.0!)
	_build_smooth_ramp(stage_root, "SouthDiscoRamp", Vector3(0.40, 0.0, STAGE_D * 0.5), 1.50, 1.15, STAGE_H, 0.0, obsidian)
	# Flanking neon stairs on left & right of South ramp
	_build_neon_stairs(stage_root, "SouthStairsL", Vector3(-0.75, 0.0, STAGE_D * 0.5), 0.80, 1.05, STAGE_H, Vector3(0, 0, 1), obsidian)
	_build_neon_stairs(stage_root, "SouthStairsR", Vector3(1.55, 0.0, STAGE_D * 0.5), 0.80, 1.05, STAGE_H, Vector3(0, 0, 1), obsidian)

	# WEST & EAST SIDE STAIRS (3 wide glowing steps on both flanks!)
	_build_neon_stairs(stage_root, "WestStairs", Vector3(-STAGE_W * 0.5, 0.0, 0.0), 2.8, 0.96, STAGE_H, Vector3(-1, 0, 0), obsidian)
	_build_neon_stairs(stage_root, "EastStairs", Vector3(STAGE_W * 0.5, 0.0, 0.0), 2.8, 0.96, STAGE_H, Vector3(1, 0, 0), obsidian)

	# Glowing "STEP UP & DANCE" floor arrow stripe leading onto the South ramp
	var arrow_mat := _mat(Color("ff2fa6"), 0.2, 0.2, true, 1.4)
	_step_trim_mats.append(arrow_mat)
	_box(stage_root, "EntryWelcomeBar", Vector3(0.40, 0.015, STAGE_D * 0.5 + 1.25), Vector3(2.8, 0.02, 0.16), arrow_mat)

func _build_neon_stairs(parent: Node3D, label: String, edge_at: Vector3, width: float, run: float, total_h: float, out_dir: Vector3, body_mat: Material) -> void:
	var steps := 3
	var step_d := run / float(steps)
	var step_h := total_h / float(steps)
	var along_z := absf(out_dir.z) > 0.5
	for i in range(steps):
		var h := total_h - float(i) * step_h
		var dist := (float(i) + 0.5) * step_d
		var pos := edge_at + out_dir * dist + Vector3(0.0, h * 0.5, 0.0)
		var sz := Vector3(width, h, step_d) if along_z else Vector3(step_d, h, width)
		_box(parent, "%s_Step_%d" % [label, i], pos, sz, body_mat, true)
		var trim_c: Color = NEON_COLORS[(i * 2) % NEON_COLORS.size()]
		var trim_mat := _mat(trim_c, 0.15, 0.2, true, 1.9)
		_step_trim_mats.append(trim_mat)
		var nose_pos := edge_at + out_dir * (dist + step_d * 0.48) + Vector3(0.0, h - 0.018, 0.0)
		var nose_sz := Vector3(width * 0.96, 0.036, 0.045) if along_z else Vector3(0.045, 0.036, width * 0.96)
		_box(parent, "%s_Neon_%d" % [label, i], nose_pos, nose_sz, trim_mat)

func _build_smooth_ramp(parent: Node3D, label: String, edge_at: Vector3, width: float, run: float, total_h: float, yaw: float, mat: Material) -> void:
	# Clean solid wedge prism ramp (walkable in VR & desktop with zero step snag!)
	var ramp := Node3D.new()
	ramp.name = label
	ramp.position = edge_at
	ramp.rotation.y = yaw
	parent.add_child(ramp)

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := width * 0.5
	var p00 := Vector3(-hw, 0.0, 0.0)
	var p10 := Vector3(hw, 0.0, 0.0)
	var p01 := Vector3(-hw, 0.0, run)
	var p11 := Vector3(hw, 0.0, run)
	var t00 := Vector3(-hw, total_h, 0.0)
	var t10 := Vector3(hw, total_h, 0.0)
	# Sloped top face
	for v: Vector3 in [t00, t10, p11, t00, p11, p01]:
		st.add_vertex(v)
	# Left side
	for v: Vector3 in [p00, p01, t00]:
		st.add_vertex(v)
	# Right side
	for v: Vector3 in [p10, t10, p11]:
		st.add_vertex(v)
	# Back & bottom
	for v: Vector3 in [p00, t00, t10, p00, t10, p10, p00, p10, p11, p00, p11, p01]:
		st.add_vertex(v)
	st.generate_normals()
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = mat
	ramp.add_child(mi)
	mi.create_convex_collision()

	# Glowing neon side rails along the ramp slope
	var rail_mat := _mat(Color("00f5ff"), 0.15, 0.2, true, 1.8)
	_step_trim_mats.append(rail_mat)
	var slope_len := sqrt(run * run + total_h * total_h)
	var slope_pitch := atan2(total_h, run)
	for side in [-1.0, 1.0]:
		var rail := _box(ramp, "RampRail_%d" % int(side + 2),
			Vector3(side * (hw - 0.03), total_h * 0.5 + 0.025, run * 0.5),
			Vector3(0.055, 0.035, slope_len), rail_mat)
		rail.rotation.x = slope_pitch

# ═══════════════════════════════════════════════════════════════════════════
# 2. BACKLIT DISCO FLOOR GROUT GRID (REAL 70s ACRYLIC DANCE-FLOOR PANELS!)
# ═══════════════════════════════════════════════════════════════════════════
func _build_grout_grid() -> void:
	var grout_root := Node3D.new()
	grout_root.name = "DiscoTileGrout"
	add_child(grout_root)
	var grout_mat := _mat(Color("0c0a14"), 0.35, 0.5)
	var y := STAGE_H + 0.014
	# 10 dividers along X (x = -4.5 .. +4.5)
	for ix in range(10):
		var gx := -4.5 + float(ix)
		_box(grout_root, "GroutX_%d" % ix, Vector3(gx, y, 0.0), Vector3(0.065, 0.014, 11.08), grout_mat)
	# 12 dividers along Z (z = -5.5 .. +5.5)
	for iz in range(12):
		var gz := -5.5 + float(iz)
		_box(grout_root, "GroutZ_%d" % iz, Vector3(0.0, y, gz), Vector3(9.08, 0.014, 0.065), grout_mat)

# ═══════════════════════════════════════════════════════════════════════════
# 3. CHROME STAGE LIGHTING TRUSS CANOPY + 4 CORNER 3D AUDIO EQUALIZER TOWERS
# ═══════════════════════════════════════════════════════════════════════════
func _build_truss_and_eq_towers() -> void:
	var truss := Node3D.new()
	truss.name = "DiscoTrussCanopy"
	add_child(truss)

	var chrome := _mat(Color("d6ddeb"), 0.16, 0.90)
	var dark_steel := _mat(Color("242030"), 0.40, 0.72)

	var tx := 4.68
	var tz_n := -5.55
	var tz_s := 4.85
	var tz_mid := (tz_n + tz_s) * 0.5
	var tz_span := tz_s - tz_n
	var top_y := 5.28
	var col_h := top_y - STAGE_H

	# 4 Towering Chrome Corner Trusses + 8-Band 3D Equalizer Stacks!
	var corners: Array[Vector3] = [
		Vector3(-tx, 0.0, tz_n), Vector3(tx, 0.0, tz_n),
		Vector3(-tx, 0.0, tz_s), Vector3(tx, 0.0, tz_s),
	]
	for c_idx in range(corners.size()):
		var c: Vector3 = corners[c_idx]
		var tower := Node3D.new()
		tower.name = "TrussTower_%d" % c_idx
		tower.position = Vector3(c.x, STAGE_H, c.z)
		truss.add_child(tower)
		# 4 chrome vertical truss tubes per corner column
		for ox in [-0.14, 0.14]:
			for oz in [-0.14, 0.14]:
				var tube := CylinderMesh.new()
				tube.top_radius = 0.028
				tube.bottom_radius = 0.028
				tube.height = col_h
				_mesh(tower, "Tube", tube, Vector3(ox, col_h * 0.5, oz), chrome)
		# Horizontal collar rings every 0.85 m
		for r in range(6):
			_box(tower, "Collar_%d" % r, Vector3(0.0, 0.25 + float(r) * 0.85, 0.0), Vector3(0.36, 0.045, 0.36), dark_steel)
		# Solid collision box for tower
		var col_body := StaticBody3D.new()
		var cs := CollisionShape3D.new()
		var bs := BoxShape3D.new()
		bs.size = Vector3(0.38, col_h, 0.38)
		cs.shape = bs
		cs.position = Vector3(0.0, col_h * 0.5, 0.0)
		col_body.add_child(cs)
		tower.add_child(col_body)

		# 8 Animated 3D Equalizer LED Bars climbing the inward face of each corner tower!
		var inward := Vector3(-signf(c.x), 0.0, -signf(c.z)).normalized()
		var bars: Array[MeshInstance3D] = []
		for b in range(8):
			var bar_col: Color = Color.from_hsv(fposmod(0.86 - float(b) * 0.11, 1.0), 0.92, 1.0)
			var bar_mat := _mat(bar_col, 0.18, 0.2, true, 1.9)
			var by := 0.55 + float(b) * 0.48
			var bar := _box(tower, "EQBar_%d" % b, inward * 0.24 + Vector3(0.0, by, 0.0), Vector3(0.36, 0.28, 0.16), bar_mat)
			bar.rotation.y = atan2(inward.x, inward.z)
			bars.append(bar)
		_eq_bars.append(bars)

	# Overhead Chrome Perimeter Beams at y = 5.28 m (strictly below 5.64 m ceiling!)
	for sz in [tz_n, tz_s]:
		_box(truss, "TopBeamEW_%d" % int(sz * 10), Vector3(0.0, top_y, sz), Vector3(tx * 2.0 + 0.3, 0.16, 0.18), chrome)
	for sx in [-tx, tx]:
		_box(truss, "TopBeamNS_%d" % int(sx * 10), Vector3(sx, top_y, tz_mid), Vector3(0.18, 0.16, tz_span + 0.3), chrome)

	# Overhead X-Diagonal Chrome Beams meeting at the giant disco ball ceiling mount!
	var diag_len := sqrt((tx * 2.0) * (tx * 2.0) + tz_span * tz_span)
	var diag_angle := atan2(tx * 2.0, tz_span)
	for sign_a in [-1.0, 1.0]:
		var dbeam := _box(truss, "DiagTruss_%d" % int(sign_a + 2), Vector3(0.0, top_y, tz_mid),
			Vector3(0.16, 0.16, diag_len), chrome)
		dbeam.rotation.y = sign_a * diag_angle

	# Glowing Overhead Neon Sign hanging above South entrance edge ("DISCO EXTRAVAGANZA")
	var banner_mat := _mat(Color("220938"), 0.25, 0.4, true, 0.3)
	_box(truss, "DiscoMarqueeBack", Vector3(0.0, 4.92, tz_s), Vector3(5.6, 0.52, 0.14), banner_mat)
	_label(truss, "✦  DISCO GRID EXTRAVAGANZA  ✦", Vector3(0.0, 4.92, tz_s + 0.09), 64, 0.0029, Color("ffdf6b"))
	var back_lbl := _label(truss, "✦  DISCO GRID EXTRAVAGANZA  ✦", Vector3(0.0, 4.92, tz_s - 0.09), 64, 0.0029, Color("ffdf6b"))
	back_lbl.rotation.y = PI

# ═══════════════════════════════════════════════════════════════════════════
# 4. SUPER LARGE 2.40 m FACETED CEILING DISCO BALL + 4 SATELLITE BALLS!
# ═══════════════════════════════════════════════════════════════════════════
func _build_giant_disco_ball_and_satellites() -> void:
	# Motor hub & chrome suspension shaft from truss (y=5.28) down to ball center (y=3.88)
	var chrome := _mat(Color("e6eeff"), 0.08, 0.96)
	var motor := CylinderMesh.new()
	motor.top_radius = 0.42
	motor.bottom_radius = 0.32
	motor.height = 0.28
	_mesh(self, "DiscoMotorHub", motor, Vector3(0.0, 5.22, 0.0), _mat(Color("251d33"), 0.25, 0.8))
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.065
	shaft.bottom_radius = 0.065
	shaft.height = 0.55
	_mesh(self, "DiscoMotorShaft", shaft, Vector3(0.0, 4.95, 0.0), chrome)

	# Neon halo ring spinning around the ceiling mount above the giant ball!
	var halo := TorusMesh.new()
	halo.inner_radius = 1.48
	halo.outer_radius = 1.62
	halo.rings = 40
	halo.ring_segments = 14
	_halo_mat = _mat(Color("ff2fa6"), 0.15, 0.3, true, 1.9)
	_mesh(self, "DiscoCeilingHalo", halo, Vector3(0.0, 5.06, 0.0), _halo_mat)

	# SUPER LARGE 2.40 m DIAMETER FACETED MIRROR DISCO BALL! (radius = 1.20 m -> 2.68..5.08 m!)
	_giant_ball = _create_faceted_disco_ball("GiantDiscoBall", 1.20, 15, 0.175)
	_giant_ball.position = Vector3(0.0, 3.88, 0.0)
	add_child(_giant_ball)

	# 4 Satellite Mini Disco Balls (0.72 m diameter!) hanging around the canopy
	var sat_positions: Array[Vector3] = [
		Vector3(-3.35, 4.45, -3.75), Vector3(3.35, 4.45, -3.75),
		Vector3(-3.35, 4.45, 3.75), Vector3(3.35, 4.45, 3.75),
	]
	for i in range(sat_positions.size()):
		var p: Vector3 = sat_positions[i]
		var rod := CylinderMesh.new()
		rod.top_radius = 0.025
		rod.bottom_radius = 0.025
		rod.height = 0.85
		_mesh(self, "SatRod_%d" % i, rod, Vector3(p.x, 4.88, p.z), chrome)
		var sat := _create_faceted_disco_ball("SatelliteDiscoBall_%d" % i, 0.36, 7, 0.115)
		sat.position = p
		add_child(sat)
		_satellite_balls.append(sat)

func _create_faceted_disco_ball(label: String, radius: float, rings: int, tile_size: float) -> Node3D:
	var ball := Node3D.new()
	ball.name = label

	# Dark gleaming mirror-grout inner sphere
	var core_mesh := SphereMesh.new()
	core_mesh.radius = radius * 0.975
	core_mesh.height = radius * 1.95
	core_mesh.radial_segments = 28
	core_mesh.rings = 16
	_mesh(ball, "BallCore", core_mesh, Vector3.ZERO, _mat(Color("222436"), 0.15, 0.92))

	# Collect facet transforms across latitude rings (true mosaic mirror facets!)
	var xforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var glint_palette: Array[Color] = [
		Color("ffffff"), Color("e8f4ff"), Color("d2dcff"),
		Color("ffd2f2"), Color("fff2c4"), Color("c4fbff"), Color("e0c4ff"),
	]
	for r in range(rings):
		var v := (float(r) + 0.5) / float(rings)
		var phi := lerpf(0.14, PI - 0.14, v)
		var ring_r := sin(phi) * radius
		var y := cos(phi) * radius
		var cols := maxi(6, int(roundf((TAU * ring_r) / (tile_size * 1.12))))
		for c in range(cols):
			var theta := TAU * (float(c) + (0.5 if r % 2 == 1 else 0.0)) / float(cols)
			var normal := Vector3(sin(phi) * cos(theta), cos(phi), sin(phi) * sin(theta)).normalized()
			var pos := normal * radius
			var up_ref := Vector3.UP if absf(normal.y) < 0.95 else Vector3.RIGHT
			var right := up_ref.cross(normal).normalized()
			var up := normal.cross(right).normalized()
			var basis := Basis(right, up, normal)
			xforms.append(Transform3D(basis, pos))
			# Shimmering mirrored glass tint with occasional neon disco reflection facet!
			var h_idx := (r * 7 + c * 3) % glint_palette.size()
			var col: Color = glint_palette[h_idx]
			if (r * 13 + c * 5) % 9 == 0:
				col = NEON_COLORS[(r + c) % NEON_COLORS.size()].lightened(0.45)
			colors.append(col)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var tile_box := BoxMesh.new()
	tile_box.size = Vector3(tile_size, tile_size, 0.028)
	mm.mesh = tile_box
	mm.instance_count = xforms.size()
	for i in range(xforms.size()):
		mm.set_instance_transform(i, xforms[i])
		mm.set_instance_color(i, colors[i])

	var mmi := MultiMeshInstance3D.new()
	mmi.name = "MirrorFacets"
	mmi.multimesh = mm
	var facet_mat := StandardMaterial3D.new()
	facet_mat.vertex_color_use_as_albedo = true
	facet_mat.metallic = 0.92
	facet_mat.roughness = 0.06
	facet_mat.emission_enabled = true
	facet_mat.emission = Color("eef4ff")
	facet_mat.emission_energy_multiplier = 0.55
	mmi.material_override = facet_mat
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ball.add_child(mmi)
	return ball

# ═══════════════════════════════════════════════════════════════════════════
# 5. SWEEPING VOLUMETRIC LASER CONES + 96 ORBITING MIRROR-BALL LIGHT DOTS
# ═══════════════════════════════════════════════════════════════════════════
func _build_volumetric_lasers_and_dots() -> void:
	var fx := Node3D.new()
	fx.name = "DiscoLightShow"
	add_child(fx)

	# 8 Sweeping translucent additive volumetric disco laser cones!
	var origins: Array[Vector3] = [
		Vector3(-4.2, 5.15, -4.9), Vector3(4.2, 5.15, -4.9),
		Vector3(-4.2, 5.15, 4.9), Vector3(4.2, 5.15, 4.9),
		Vector3(-1.3, 4.65, 0.0), Vector3(1.3, 4.65, 0.0),
		Vector3(0.0, 4.65, -1.3), Vector3(0.0, 4.65, 1.3),
	]
	for i in range(origins.size()):
		var pivot := Node3D.new()
		pivot.name = "LaserPivot_%d" % i
		pivot.position = origins[i]
		fx.add_child(pivot)

		var cone := CylinderMesh.new()
		cone.top_radius = 0.04
		cone.bottom_radius = 0.85 if i < 4 else 0.58
		cone.height = 6.2 if i < 4 else 4.9
		cone.radial_segments = 16
		cone.cap_top = false
		cone.cap_bottom = false

		var col: Color = NEON_COLORS[i % NEON_COLORS.size()]
		var lmat := StandardMaterial3D.new()
		lmat.albedo_color = Color(col.r, col.g, col.b, 0.16)
		lmat.emission_enabled = true
		lmat.emission = col
		lmat.emission_energy_multiplier = 1.4
		lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		lmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		lmat.cull_mode = BaseMaterial3D.CULL_DISABLED
		lmat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED

		var mi := _mesh(pivot, "BeamCone", cone, Vector3(0.0, -cone.height * 0.5, 0.0), lmat)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_lasers.append({
			"pivot": pivot,
			"mat": lmat,
			"base_color": col,
			"phase": float(i) * 0.85,
			"inner": i >= 4,
		})

	# 96 Sparkling Orbiting Mirror-Ball Reflection Dots across the room!
	var dot_mm := MultiMesh.new()
	dot_mm.transform_format = MultiMesh.TRANSFORM_3D
	dot_mm.use_colors = true
	var disc := SphereMesh.new()
	disc.radius = 0.075
	disc.height = 0.15
	disc.radial_segments = 8
	disc.rings = 4
	dot_mm.mesh = disc
	dot_mm.instance_count = 96
	for i in range(96):
		var a := float(i) * 2.39996
		var r := 2.4 + fmod(float(i) * 0.61, 4.4)
		var mode := i % 3  # 0 = dance floor sparkle, 1 = ceiling/upper sparkle, 2 = perimeter sparkle
		var y := STAGE_H + 0.06 if mode == 0 else (5.45 if mode == 1 else (1.2 + fmod(float(i) * 0.37, 3.6)))
		var col: Color = NEON_COLORS[i % NEON_COLORS.size()].lightened(0.45)
		if i % 3 == 0:
			col = Color("ffffff")
		_dot_specs.append({"angle": a, "radius": r, "y": y, "mode": mode, "color": col})
		dot_mm.set_instance_color(i, col)

	_mirror_dots = MultiMeshInstance3D.new()
	_mirror_dots.name = "DiscoBallSparkleDots"
	_mirror_dots.multimesh = dot_mm
	var dmat := StandardMaterial3D.new()
	dmat.vertex_color_use_as_albedo = true
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_mirror_dots.material_override = dmat
	_mirror_dots.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.add_child(_mirror_dots)

	# 2 Pulsing Club OmniLights bathing the dancers & mirror in lively disco glow
	for i in range(2):
		var lamp := OmniLight3D.new()
		lamp.name = "ClubStrobeLight_%d" % i
		lamp.position = Vector3(-2.4 if i == 0 else 2.4, 3.5, -1.2 if i == 0 else 1.8)
		lamp.light_color = NEON_COLORS[i]
		lamp.light_energy = 1.6
		lamp.omni_range = 11.5
		lamp.shadow_enabled = false
		lamp.distance_fade_enabled = true
		lamp.distance_fade_begin = 15.0
		lamp.distance_fade_length = 4.0
		fx.add_child(lamp)
		_club_lights.append(lamp)

# ═══════════════════════════════════════════════════════════════════════════
# 6. MASSIVE FULL-WALL DANCE MIRROR FOR CARE UNIT MODEL B
# ═══════════════════════════════════════════════════════════════════════════
func _build_dance_mirror() -> void:
	_mirror = MirrorScript.new()
	_mirror.position = Vector3(0.0, STAGE_H, -5.25)
	add_child(_mirror)

# ═══════════════════════════════════════════════════════════════════════════
# 7. GLOWING DJ BOOTH & LIVE DANCE / PATTERN / MUSIC CONTROLS
# ═══════════════════════════════════════════════════════════════════════════
func _build_dj_booth() -> void:
	var dj := Node3D.new()
	dj.name = "DiscoDJBooth"
	dj.position = Vector3(3.45, STAGE_H, -4.15)
	dj.rotation_degrees.y = -28.0
	add_child(dj)

	var body_mat := _mat(Color("1c152b"), 0.25, 0.55)
	var trim_mat := _mat(Color("00f5ff"), 0.15, 0.2, true, 1.8)
	_rim_mats.append(trim_mat)
	_box(dj, "DJDesk", Vector3(0.0, 0.50, 0.0), Vector3(1.65, 1.00, 0.72), body_mat, true)
	_box(dj, "DJFrontNeon", Vector3(0.0, 0.96, 0.37), Vector3(1.60, 0.06, 0.04), trim_mat)
	_box(dj, "DJBaseNeon", Vector3(0.0, 0.05, 0.37), Vector3(1.60, 0.06, 0.04), _mat(Color("ff2fa6"), 0.15, 0.2, true, 1.8))

	# Twin Spinning Vinyl Turntables on top of the DJ booth!
	for side in [-0.46, 0.46]:
		var deck := Node3D.new()
		deck.position = Vector3(side, 1.03, 0.0)
		dj.add_child(deck)
		var platter := CylinderMesh.new()
		platter.top_radius = 0.23
		platter.bottom_radius = 0.24
		platter.height = 0.035
		_mesh(deck, "Vinyl", platter, Vector3.ZERO, _mat(Color("12101a"), 0.12, 0.4))
		var lbl := CylinderMesh.new()
		lbl.top_radius = 0.085
		lbl.bottom_radius = 0.085
		lbl.height = 0.042
		_mesh(deck, "Label", lbl, Vector3.ZERO, _mat(Color("ff2fa6") if side < 0 else Color("00f5ff"), 0.2, 0.2, true, 1.0))
		_box(deck, "SpinnerTick", Vector3(0.14, 0.025, 0.0), Vector3(0.10, 0.012, 0.025), _mat(Color("ffe600"), 0.2, 0.2, true, 1.2))
		_turntables.append(deck)

	_label(dj, "DJ BOOTH • 128 BPM", Vector3(0.0, 0.62, 0.38), 38, 0.0022, Color("fff3b0"))

	# Interactive Dance & Disco Control Panel right on the DJ booth!
	var panel := Controls.new()
	panel.name = "DiscoControlPanel"
	panel.title = "DISCO & CARE UNIT DANCE"
	panel.position = Vector3(0.0, 1.24, 0.28)
	panel.spacing = 0.34
	panel.tilt_degrees = -18.0
	dj.add_child(panel)
	_dj_readout = panel.add_readout("DANCE: FEVER • 128 BPM")
	var b_dance: Node3D = panel.add_button("DANCE MOVE")
	b_dance.pressed.connect(cycle_dance_move)
	var b_pat: Node3D = panel.add_button("FLOOR FX")
	b_pat.pressed.connect(cycle_pattern)
	var b_bpm: Node3D = panel.add_button("HARD/HYPER")
	b_bpm.pressed.connect(_toggle_bpm)
	var b_mute: Node3D = panel.add_button("MUSIC")
	b_mute.pressed.connect(_toggle_music)

func cycle_dance_move() -> void:
	_dance_idx = (_dance_idx + 1) % DANCE_MODES.size()
	_sync_care_unit_dance(true)
	_refresh_dj_readout()

func set_dance_move(mode_name: String) -> void:
	var idx := DANCE_MODES.find(mode_name.to_lower())
	if idx >= 0:
		_dance_idx = idx
	_sync_care_unit_dance(true)
	_refresh_dj_readout()

func cycle_pattern() -> void:
	_pattern_idx = (_pattern_idx + 1) % PATTERN_NAMES.size()
	_refresh_dj_readout()

func _toggle_bpm() -> void:
	if _music != null and _music.has_method("toggle_mode"):
		_music.call("toggle_mode")
	_sync_care_unit_dance(_on_stage)
	_refresh_dj_readout()

func _toggle_music() -> void:
	if _music != null and _music.has_method("toggle_mute"):
		_music.call("toggle_mute")
	_refresh_dj_readout()

func _refresh_dj_readout() -> void:
	if _dj_readout == null:
		return
	var dm: String = DANCE_MODES[_dance_idx].to_upper()
	var bpm_val: int = int(roundf(float(_music.get("bpm")))) if _music != null else 128
	var mstate := "MUTE" if (_music != null and bool(_music.get("muted"))) else ("%d BPM" % bpm_val)
	_dj_readout.text = "%s • %s • %s" % [dm, PATTERN_NAMES[_pattern_idx], mstate]

# ═══════════════════════════════════════════════════════════════════════════
# 8. HARD DISCO MUSIC PLAYER (FLOOR 33 SCOPED)
# ═══════════════════════════════════════════════════════════════════════════
func _build_hard_disco_music() -> void:
	_music = MusicScript.new()
	_music.set("floor_y", global_position.y)
	add_child(_music)

# ═══════════════════════════════════════════════════════════════════════════
# LIVE BEAT-SYNCED ANIMATION: BLINKING TILES, DISCO BALL, LASERS, EQ, DANCE!
# ═══════════════════════════════════════════════════════════════════════════
func _process(delta: float) -> void:
	var beat: float = float(_music.call("get_beat_phase")) if _music != null and _music.has_method("get_beat_phase") else 0.0
	var kick: float = float(_music.call("get_kick_pulse")) if _music != null and _music.has_method("get_kick_pulse") else 0.0
	var bands: Array = _music.call("get_band_energies") if _music != null and _music.has_method("get_band_energies") else [0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]

	# 1. Spin the SUPER LARGE ceiling disco ball & 4 satellite balls!
	if is_instance_valid(_giant_ball):
		_giant_ball.rotation.y += delta * (0.58 + kick * 0.25)
		_giant_ball.rotation.z = sin(beat * 0.35) * 0.04
	for i in range(_satellite_balls.size()):
		var sb: Node3D = _satellite_balls[i]
		if is_instance_valid(sb):
			sb.rotation.y += delta * (-1.15 if i % 2 == 0 else 1.15)

	if _halo_mat != null:
		var hc: Color = NEON_COLORS[int(floor(beat * 0.5)) % NEON_COLORS.size()]
		_halo_mat.albedo_color = hc
		_halo_mat.emission = hc
		_halo_mat.emission_energy_multiplier = 1.4 + kick * 1.6

	# 2. Spin DJ turntables
	for t in _turntables:
		if is_instance_valid(t):
			t.rotation.y -= delta * 3.4

	# 3. Pulse stage rim LEDs & glowing stairs on the 128 BPM kick
	var color_shift := int(floor(beat))
	for i in range(_rim_mats.size()):
		var col: Color = NEON_COLORS[(i + color_shift) % NEON_COLORS.size()]
		_rim_mats[i].albedo_color = col
		_rim_mats[i].emission = col
		_rim_mats[i].emission_energy_multiplier = 1.1 + kick * 1.9
	for i in range(_step_trim_mats.size()):
		_step_trim_mats[i].emission_energy_multiplier = 1.0 + kick * 1.7

	# 4. Animate 4 Corner 3D Audio Equalizer Towers
	for t_idx in range(_eq_bars.size()):
		var bars: Array = _eq_bars[t_idx]
		for b in range(bars.size()):
			var bar: MeshInstance3D = bars[b]
			var e: float = bands[(b + t_idx) % bands.size()]
			var lit := float(b) / 8.0 <= e + 0.12
			bar.scale.x = 0.55 + e * 0.95
			var bm := bar.material_override as StandardMaterial3D
			if bm != null:
				bm.emission_energy_multiplier = (2.2 + kick * 1.4) if lit else 0.18

	# 5. Sweep Volumetric Laser Cones & Orbit 96 Mirror-Ball Reflection Dots
	for l in _lasers:
		var piv: Node3D = l["pivot"]
		var ph: float = float(l["phase"])
		var inner: bool = bool(l["inner"])
		piv.rotation.x = sin(beat * (0.9 if inner else 0.55) + ph) * (0.68 if inner else 0.52)
		piv.rotation.z = cos(beat * (0.75 if inner else 0.48) + ph * 1.3) * (0.68 if inner else 0.52)
		var lmat: StandardMaterial3D = l["mat"]
		var bc: Color = l["base_color"]
		lmat.albedo_color = Color(bc.r, bc.g, bc.b, 0.11 + kick * 0.14)
		lmat.emission_energy_multiplier = 1.0 + kick * 1.5

	if is_instance_valid(_mirror_dots) and _mirror_dots.multimesh != null:
		var dmm := _mirror_dots.multimesh
		for i in range(_dot_specs.size()):
			var ds: Dictionary = _dot_specs[i]
			var a: float = float(ds["angle"]) + beat * (0.34 if i % 2 == 0 else -0.26)
			var r: float = float(ds["radius"]) + sin(beat * 0.8 + float(i)) * 0.45
			var p := Vector3(cos(a) * r, float(ds["y"]), sin(a) * r * 1.15)
			var sc := 0.55 + 0.85 * absf(sin(beat * 2.0 + float(i) * 0.7))
			dmm.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * sc), p))

	# 6. Pulse Club OmniLights & Mirror Vanity Bulbs
	for i in range(_club_lights.size()):
		var lc: Color = NEON_COLORS[(color_shift + i * 2) % NEON_COLORS.size()]
		_club_lights[i].light_color = lc
		_club_lights[i].light_energy = 1.1 + kick * 1.35

	if is_instance_valid(_mirror) and _mirror.has_method("pulse_bulbs"):
		_mirror.call("pulse_bulbs", beat, kick)

	# 7. Animate the Blinking Disco Floor Tiles (preserving active X/Z Direction Palette!)
	_animate_blinking_disco_floor(beat, kick, bands)

	# 8. Engage Care Unit Model B Live Disco Dance Moves whenever she's on the stage!
	_update_care_unit_stage_dance()

func _refresh_active_palette() -> void:
	if _owner_floor == null:
		return
	var src: Variant = _owner_floor.get("source")
	if not is_instance_valid(src):
		return
	var lesson: Variant = src.get("address_lesson")
	if not is_instance_valid(lesson):
		return
	var p_idx: int = int(lesson.get("palette_index"))
	if p_idx == _last_palette_idx and not _cached_palette.is_empty():
		return
	_last_palette_idx = p_idx
	var pnames: Array[String] = ["stonewall_freedom", "starry_night", "mondrian_grid", "desert_sunset"]
	var pname: String = pnames[clampi(p_idx, 0, pnames.size() - 1)]
	if src.has_method("_get_palette_colors"):
		var cols: Variant = src.call("_get_palette_colors", pname)
		if cols is Array and not (cols as Array).is_empty():
			_cached_palette.clear()
			for c_var in (cols as Array):
				if c_var is Color:
					var c: Color = c_var
					# Boost saturation slightly so every direction palette pops like backlit disco glass!
					_cached_palette.append(Color.from_hsv(c.h, maxf(c.s, 0.72), maxf(c.v, 0.85)))

func _animate_blinking_disco_floor(beat: float, kick: float, bands: Array) -> void:
	if _grid_mm == null or _cell_coords.is_empty():
		return
	_refresh_active_palette()
	var pal: Array[Color] = _cached_palette if not _cached_palette.is_empty() else FALLBACK_PALETTE
	var pal_n := pal.size()

	# Determine visitor foot cell on the dance floor for live footstep ripple!
	var foot_cell := Vector2(-99.0, -99.0)
	var game := get_tree().get_first_node_in_group("void_game")
	if is_instance_valid(game) and game.get("body") != null and is_instance_valid(_frame):
		var local_f := _frame.to_local((game.body as Node3D).global_position)
		if absf(local_f.y) < 0.65:
			foot_cell = Vector2(local_f.x, local_f.z)

	# Active pattern: AUTO cycles smoothly every 8 beats through all 5 patterns!
	var pat := ((int(floor(beat / 8.0)) % 5) + 1) if _pattern_idx == 0 else _pattern_idx
	var beat_int := int(floor(beat))
	var step8 := int(floor(beat * 2.0))

	for i in range(mini(_cell_coords.size(), _grid_mm.instance_count)):
		var cell: Vector2i = _cell_coords[i]
		var cx := float(cell.x) - 10.0
		var cz := float(cell.y) - 10.0
		var base_col: Color = pal[posmod(cell.x + cell.y + beat_int / 2, pal_n)]
		var bright := 0.35

		match pat:
			1:  # CHECKER FLASH: crisp alternating Studio 54 checkerboard strobe on the beat!
				var parity := (cell.x + cell.y + beat_int) % 2 == 0
				bright = (1.15 + kick * 0.45) if parity else (0.20 + kick * 0.12)
				base_col = pal[posmod(cell.x * 2 + cell.y + beat_int, pal_n)]
			2:  # RADIAL RIPPLE: neon rings pulsing outward from stage center!
				var dist := sqrt(cx * cx + cz * cz)
				var wave := 0.5 + 0.5 * sin(dist * 1.35 - beat * TAU * 0.75)
				bright = 0.22 + pow(wave, 2.2) * (1.05 + kick * 0.40)
				base_col = pal[posmod(int(floor(dist)) + beat_int, pal_n)]
			3:  # EQ SPECTRUM WAVES: bouncing equalizer bars racing across X & Z!
				var band_e: float = bands[posmod(cell.x, bands.size())]
				var norm_z := absf(cz) / 5.2
				var lit := norm_z <= band_e
				bright = (1.12 + kick * 0.38) if lit else 0.16
				base_col = pal[posmod(cell.x + int(floor(norm_z * 4.0)), pal_n)]
			4:  # DIAGONAL CHASER: sweeping neon rainbow diagonals!
				var diag := posmod(cell.x + cell.y - step8, 6)
				bright = 1.25 if diag == 0 else (0.72 if diag == 1 else 0.24)
				base_col = pal[posmod(cell.x - cell.y + beat_int, pal_n)]
			_:  # SPARKLE STROBE PARTY: twinkling disco tiles popping bright gold/white on 8ths!
				var h := posmod(cell.x * 37 + cell.y * 17 + step8 * 29, 11)
				if h == 0:
					base_col = Color("fff6c4")
					bright = 1.35
				elif h <= 3:
					bright = 1.05 + kick * 0.35
				else:
					bright = 0.22

		# White-hot footstep halo right underneath Care Unit Model B's dancing feet!
		var fd := Vector2(float(cell.x), float(cell.y)).distance_to(foot_cell)
		if fd < 0.75:
			base_col = base_col.lerp(Color("fff8dc"), 0.55)
			bright = 1.40
		elif fd < 1.65:
			bright = maxf(bright, 0.92 + kick * 0.35)

		_grid_mm.set_instance_color(i, Color(
			clampf(base_col.r * bright, 0.0, 1.35),
			clampf(base_col.g * bright, 0.0, 1.35),
			clampf(base_col.b * bright, 0.0, 1.35),
			1.0
		))

func _update_care_unit_stage_dance() -> void:
	var game := get_tree().get_first_node_in_group("void_game")
	if not is_instance_valid(game) or game.get("body") == null:
		return
	var local_p := to_local((game.body as Node3D).global_position)
	var now_on_stage := absf(local_p.x) <= (STAGE_W * 0.5 + 0.15) and absf(local_p.z) <= (STAGE_D * 0.5 + 0.15) and local_p.y >= 0.20 and local_p.y <= 2.4
	if now_on_stage != _on_stage:
		_on_stage = now_on_stage
		_sync_care_unit_dance(_on_stage)
	if _on_stage:
		_push_outfit_dance_beat(true)

func _sync_care_unit_dance(active: bool) -> void:
	var dm: String = "" if (not active or DANCE_MODES[_dance_idx] == "off") else DANCE_MODES[_dance_idx]
	var bpm_val: float = float(_music.get("bpm")) if _music != null else 128.0
	for cb in get_tree().get_nodes_in_group("void_care_bodies"):
		if cb.has_method("set_dance_mode"):
			cb.call("set_dance_mode", dm, bpm_val)
	_push_outfit_dance_beat(active)

func _push_outfit_dance_beat(active: bool) -> void:
	var dm: String = "" if (not active or DANCE_MODES[_dance_idx] == "off") else DANCE_MODES[_dance_idx]
	var beat: float = float(_music.call("get_beat_phase")) if _music != null and _music.has_method("get_beat_phase") else 0.0
	for w in get_tree().get_nodes_in_group("costume_wardrobes"):
		var costume: Variant = w.get("costume")
		if is_instance_valid(costume):
			for child in (costume as Node).find_children("*", "Node3D", true, false):
				if "dance_mode" in child:
					child.set("dance_mode", dm)
					child.set("dance_beat", beat)

func _exit_tree() -> void:
	if get_tree() != null:
		for cb in get_tree().get_nodes_in_group("void_care_bodies"):
			if cb.has_method("set_dance_mode"):
				cb.call("set_dance_mode", "", 128.0)
		_push_outfit_dance_beat(false)

# ═══════════════════════════════════════════════════════════════════════════
# MESH / MATERIAL HELPERS
# ═══════════════════════════════════════════════════════════════════════════
func _mat(c: Color, roughness: float = 0.3, metallic: float = 0.1, glow: bool = false, glow_energy: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	m.metallic = metallic
	if glow:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = glow_energy
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

func _label(parent: Node3D, text: String, at: Vector3, font_size: int = 48, pixel_size: float = 0.0025, col: Color = Color.WHITE) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.position = at
	l.font_size = font_size
	l.pixel_size = pixel_size
	l.outline_size = 6
	l.modulate = col
	parent.add_child(l)
	return l
