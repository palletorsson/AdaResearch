extends Node3D
class_name SurrealLab

# @identity
# essence: a multi-mode generative SCI-FI LAB INSTRUMENT standing where laboratory
#   apparatus tips over into the uncanny — one floor-resting machine that, depending
#   on its `mode` DNA, speaks eight surreal-science vocabularies. Four are bench
#   apparatus: specimen (a glowing containment tank cradling a biomorphic alien
#   embryo), reactor (a plasma core caged in gimbal rings and helical coils), scanner
#   (an articulated analysis arm lowering a glowing sensor head over a sample), and
#   chemrig (a cluster of alien glassware — retort, condenser spiral, graduated
#   cylinder — bubbling over a burner). Four more are BLACK-MESA / COMBINE
#   installation machines: spectrometer (the anti-mass spectrometer — a ringed
#   emitter barrel firing a teal beam into a green Xen crystal on a gantry, with a
#   CRT oscilloscope and hazard stripes), teleporter (a Combine pad with tilted
#   gimbal rings and a portal light column), gravgun (a zero-point manipulator
#   cradling a glowing core in three splayed prongs, resting in a lab cradle), and
#   darkreactor (a captured dark-energy column caged in angular Combine claw struts
#   on an armoured octagonal base). It is the bench instrument made strange: every
#   part still LOOKS like it does something, but what it does is not nameable.
# desire: it wants to be READ AS FUNCTIONAL while remaining impossible — to wear the
#   full grammar of real lab gear (dials, indicator LEDs, clamps, cables, seals,
#   readout screens) so convincingly that the viewer believes it could be switched
#   on, and yet to contain a process that belongs to no science: an embryo that is
#   not a foetus, a plasma that obeys no reactor, a scan with no specimen, a
#   reaction whose fluids never settle. It desires the trust we extend to instruments.
# critical_parameter: mode + seed + the colour triad (color_a / color_b / accent) —
#   mode picks the apparatus lineage and silhouette; seed varies the individual
#   specimen deterministically (bubble drift, embryo tendrils, arc jitter) so each
#   build is a sibling not a clone; color_a drives the primary glow/fluid/energy
#   (fluid / plasma / teal aperture+beam / portal column / gun core / reactor
#   column), color_b the secondary (flesh / accelerator nodes / sensor pods / 2nd
#   fluid / Xen crystal / ring energy / supercharged core / Combine armour tint),
#   accent the indicator LEDs / probe / glints / hazard stripes / CRT / arcs. One
#   genome, eight instruments, infinite individuals.
# triggers: _ready() seeds the RNG from `seed`, reads DNA metadata overrides, and
#   branches on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config
#   metas, clears children (remove BEFORE free), and rebuilds when DNA changes.
# emerges: dropped into an auto-research lab, a row of these reads as a CABINET OF
#   IMPOSSIBLE INSTRUMENTS — four ways a bench machine can promise an operation it
#   can never deliver. Switch one mode and the whole room's idea of "what the lab
#   measures" shifts; reseed and the instrument persists while its living interior
#   mutates. The piece is the laboratory confessing that instrumentation is a
#   rhetoric — that the look of function is separable from function itself.
# needs: a seeded RNG for deterministic individuals [present]; four build branches
#   each with a strong instrument silhouette [present]; a dark-metal material with an
#   emission FLOOR so nothing renders black under flat capture light [present]; a
#   glass material (alpha + double-sided + faint rim) for the vessels [present]; a
#   colour triad that re-registers the same apparatus [present]; bottom-centre floor
#   origin reading from +Z [present]
# relationships: cousin to prefab_sculpture (both are mode-switchboards of one
#   genome, but the sculpture asks "what is art-from-matter?" while surreal_lab asks
#   "what is an instrument?"); sibling to the real bench props (bunsen_burner,
#   chemistry_flask, fume_hood) — where those are honest tools, surreal_lab is their
#   dreamed double; kin to the nature_system creatures (both blur living/manufactured,
#   but the creatures grow over time while the instrument freezes one impossible state).
# truth: the uncanny made functional. An instrument earns belief through its surface
#   — the dial that could be read, the LED that could mean ready, the clamp that
#   could grip — and that belief survives the discovery that the interior is
#   impossible. surreal_lab holds four such surfaces in one genome and lets a single
#   parameter choose which impossible operation the viewer is invited to trust. The
#   border between a working machine and a prop is not in the mechanism — it is in
#   the look, and the look is always already enough.

## A multi-mode generative sci-fi lab instrument — the uncanny made functional.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of the
## piece (floor-resting, Y up); it reads from +Z. The `mode` export selects one
## of EIGHT surreal-science vocabularies, each ported from a standalone trial:
## specimen (glowing containment tank + alien embryo), reactor (plasma core +
## ring cage), scanner (articulated analysis arm), chemrig (alien glassware +
## condenser coil + burner), spectrometer (Black Mesa anti-mass spectrometer —
## ringed emitter barrel + teal beam + Xen crystal + gantry + CRT), teleporter
## (Combine pad + tilted gimbal rings + portal light column + consoles), gravgun
## (zero-point manipulator — splayed prongs cradling a glowing core, on a lab
## cradle), darkreactor (Combine dark-energy column caged in angular claw struts).
## A seeded RNG makes every individual deterministic from its `seed`. The colour
## triad (color_a / color_b / accent) re-registers the same apparatus between
## palettes.
##
## Shared material + geometry helpers are consolidated under the `_sl_` prefix
## and reused by every mode. NO dependency on any other artifact script.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## specimen | reactor | scanner | chemrig | spectrometer | teleporter | gravgun | darkreactor
@export var mode: String = "specimen"
## Deterministic seed — same seed always yields the same form.
@export var seed: int = 7
## Detail / element count (bubbles, tendrils, arcs, coil turns scale with this).
@export var complexity: int = 5
## Overall height in meters (nominal full height of the instrument).
@export var sculpt_height: float = 1.8
## Footprint width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## Primary glow / fluid / plasma-core tint.
@export var color_a: Color = Color(0.16, 0.92, 0.62)
## Secondary tint — specimen flesh / accelerator nodes / sensor pods / 2nd fluid.
@export var color_b: Color = Color(0.95, 0.45, 0.62)
## Accent — indicator LEDs / probe beam / glints / hot tips.
@export var accent: Color = Color(1.0, 0.78, 0.20)
@export var metallic_amt: float = 0.85
@export var rough_amt: float = 0.35
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()

# Cool-steel emission-floor tint shared by all dark metal so it never reads black.
const _STEEL_TINT: Color = Color(0.16, 0.20, 0.235)


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_mode"):
		mode = str(get_meta("config_mode")).to_lower().strip_edges()
	if has_meta("config_seed"):
		seed = int(str(get_meta("config_seed")))
	if has_meta("config_complexity"):
		complexity = int(str(get_meta("config_complexity")))
	if has_meta("config_sculpt_height"):
		sculpt_height = float(str(get_meta("config_sculpt_height")))
	if has_meta("config_sculpt_width"):
		sculpt_width = float(str(get_meta("config_sculpt_width")))
	if has_meta("config_color_a"):
		color_a = _parse_color(str(get_meta("config_color_a")), color_a)
	if has_meta("config_color_b"):
		color_b = _parse_color(str(get_meta("config_color_b")), color_b)
	if has_meta("config_accent"):
		accent = _parse_color(str(get_meta("config_accent")), accent)
	if has_meta("config_metallic_amt"):
		metallic_amt = float(str(get_meta("config_metallic_amt")))
	if has_meta("config_rough_amt"):
		rough_amt = float(str(get_meta("config_rough_amt")))
	if has_meta("config_emissive"):
		emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


## Accepts an "r,g,b" / "r,g,b,a" string OR a colour name ("red", "cyan", …).
func _parse_color(raw: String, fallback: Color) -> Color:
	var s := raw.strip_edges()
	var parts := s.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	# Try a named colour (Godot's Color(name) constructor handles HTML + names).
	var named := Color(s.to_lower())
	if named != Color(0, 0, 0, 1) or s.to_lower() in ["black", "#000000", "000000"]:
		return named
	return fallback


# ── Build dispatch ─────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_rng.seed = seed
	match mode:
		"specimen":
			_build_specimen()
		"reactor":
			_build_reactor()
		"scanner":
			_build_scanner()
		"chemrig":
			_build_chemrig()
		"spectrometer":
			_build_spectrometer()
		"teleporter":
			_build_teleporter()
		"gravgun":
			_build_gravgun()
		"darkreactor":
			_build_darkreactor()
		_:
			# Unknown mode falls back to the specimen vocabulary.
			_build_specimen()


# ── Shared `_sl_` material helpers ─────────────────────────────────────

## Energy multiplier for emissive elements, lifted when `emissive` is on.
func _sl_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## Dark polished metal with a faint emission FLOOR of its tint + a rim, so it
## never renders pure black under flat / unlit capture lighting. Every mode
## relies on this floor.
func _sl_metal_mat(tint: Color, emit_tint: Color = _STEEL_TINT,
		energy: float = 0.24) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = tint
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.roughness = clampf(rough_amt, 0.02, 1.0)
	m.emission_enabled = true
	m.emission = emit_tint
	m.emission_energy_multiplier = energy
	m.rim_enabled = true
	m.rim = 0.5
	m.rim_tint = 0.3
	return m


## Translucent glass: alpha, double-sided, faint tint, a touch of rim emission so
## the silhouette of the glassware reads even where nothing glows behind it.
func _sl_glass_mat(tint: Color, alpha: float = 0.16) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.metallic = 0.0
	m.roughness = 0.05
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = _sl_glow_energy(0.12)
	m.rim_enabled = true
	m.rim = 0.7
	return m


## A glowing emissive material. Alpha < 1.0 turns on alpha transparency.
func _sl_emissive_mat(tint: Color, alpha: float = 1.0, energy: float = 3.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = _sl_glow_energy(energy)
	return m


## Additive translucent flame / beam / light-pool material.
func _sl_flame_mat(tint: Color, alpha: float = 0.5, energy: float = 2.6) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(tint.r, tint.g, tint.b, alpha)
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = _sl_glow_energy(energy)
	return m


## Procedural diagonal hazard-stripe material (warning band) — `accent` × black,
## ported from the spectrometer/teleporter trials. The band has a faint emission
## floor of its own texture so it stays legible in the dark.
func _sl_hazard_mat(stripes: int = 10) -> StandardMaterial3D:
	var hazard_black := Color(0.07, 0.07, 0.08)
	var sz: int = 64
	var img := Image.create(sz, sz, false, Image.FORMAT_RGB8)
	for y in range(sz):
		for x in range(sz):
			# Diagonal bands: shift x by y so stripes run at 45 degrees.
			var band: int = int(floor(float(x + y) / float(sz) * float(stripes)))
			var col: Color = accent if (band % 2 == 0) else hazard_black
			img.set_pixel(x, y, col)
	var tex := ImageTexture.create_from_image(img)
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.roughness = 0.6
	m.metallic = 0.25
	m.uv1_scale = Vector3(3.0, 1.0, 3.0)
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission_energy_multiplier = _sl_glow_energy(0.10)
	return m


## Oscilloscope-style CRT texture: an `accent`-tinted sine trace over a green grid.
## Ported from the spectrometer trial; deterministic (no RNG).
func _sl_crt_texture() -> ImageTexture:
	var w: int = 128
	var h: int = 96
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	img.fill(Color(0.02, 0.08, 0.04))
	var grid := Color(0.05, 0.22, 0.10)
	for gx in range(0, w, 16):
		for y in range(h):
			img.set_pixel(gx, y, grid)
	for gy in range(0, h, 16):
		for x in range(w):
			img.set_pixel(x, gy, grid)
	var trace := accent
	for x in range(w):
		var t: float = float(x) / float(w) * TAU * 2.0
		var v: float = sin(t) * 0.55 + sin(t * 3.0 + 0.6) * 0.22
		var yy: int = clampi(int(float(h) * 0.5 - v * float(h) * 0.40), 0, h - 1)
		img.set_pixel(x, yy, trace)
		if yy + 1 < h:
			img.set_pixel(x, yy + 1, trace.darkened(0.25))
		if yy - 1 >= 0:
			img.set_pixel(x, yy - 1, trace.darkened(0.25))
	return ImageTexture.create_from_image(img)


## A standard CRT screen material wrapping `_sl_crt_texture()` (unshaded, emissive).
func _sl_crt_mat() -> StandardMaterial3D:
	var tex := _sl_crt_texture()
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	m.emission_enabled = true
	m.emission_texture = tex
	m.emission_energy_multiplier = _sl_glow_energy(2.6)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m


# ── Shared `_sl_` mesh helpers ─────────────────────────────────────────

func _sl_cylinder(parent: Node3D, top_r: float, bot_r: float, height: float,
		pos: Vector3, mat: Material, radial: int = 24) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = height
	cyl.radial_segments = radial
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sl_sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material,
		rings: int = 14, segs: int = 20) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = segs
	sph.rings = rings
	mi.mesh = sph
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sl_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _sl_torus(parent: Node3D, inner_r: float, outer_r: float, pos: Vector3,
		mat: Material, rings: int = 28, ring_segs: int = 14) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = inner_r
	tm.outer_radius = outer_r
	tm.rings = rings
	tm.ring_segments = ring_segs
	mi.mesh = tm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## Oriented cylinder spanning a→b. Uses a Basis (no out-of-tree look_at).
func _sl_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float,
		mat: Material, radial: int = 10) -> MeshInstance3D:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		return null
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = radial
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = (a + b) * 0.5
	# Orient the cylinder's +Y axis along dir via a Basis.
	var up := Vector3.UP
	var ndir := dir / length
	var dot := clampf(up.dot(ndir), -1.0, 1.0)
	if dot < 0.99995 and dot > -0.99995:
		var axis := up.cross(ndir).normalized()
		mi.basis = Basis(axis, acos(dot))
	elif dot <= -0.99995:
		mi.basis = Basis(Vector3.RIGHT, PI)
	parent.add_child(mi)
	return mi


## Capsule variant of _sl_segment (for arm links that want rounded ends).
func _sl_capsule_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float,
		mat: Material) -> void:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		return
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = maxf(length, radius * 2.0 + 0.001)
	cap.radial_segments = 14
	cap.rings = 4
	mi.mesh = cap
	mi.material_override = mat
	mi.position = (a + b) * 0.5
	var up := Vector3.UP
	var ndir := dir / length
	var dot := clampf(up.dot(ndir), -1.0, 1.0)
	if dot < 0.99995 and dot > -0.99995:
		var axis := up.cross(ndir).normalized()
		mi.basis = Basis(axis, acos(dot))
	elif dot <= -0.99995:
		mi.basis = Basis(Vector3.RIGHT, PI)
	parent.add_child(mi)


## A tube following a list of points: oriented cylinder segments + joint beads.
func _sl_tube_path(parent: Node3D, pts: Array[Vector3], radius: float,
		mat: Material, radial: int = 9) -> void:
	for i in range(pts.size() - 1):
		_sl_segment(parent, pts[i], pts[i + 1], radius, mat, radial)
	for i in range(1, pts.size() - 1):
		_sl_sphere(parent, radius * 1.02, pts[i], mat, 7, 9)


# =============================================================================
# MODE: specimen — glowing containment tank + biomorphic alien embryo (v1)
# =============================================================================

func _build_specimen() -> void:
	# Vertical layout (metres), scaled by sculpt_width on the horizontal axis.
	var w := maxf(sculpt_width, 0.2)
	var base_h := 0.26
	var base_r := 0.46 * w
	var tank_bottom := 0.26
	var tank_h := 1.30
	var tank_r := 0.34 * w
	var cap_h := 0.22
	var fluid_inset := 0.045 * w
	var fluid_top_gap := 0.12
	# Honour overall height: scale the vertical layout so total ~= sculpt_height.
	var native_total := tank_bottom + tank_h + cap_h + 0.12
	var vscale := maxf(sculpt_height, 0.4) / native_total
	base_h *= vscale
	tank_bottom *= vscale
	tank_h *= vscale
	cap_h *= vscale
	fluid_top_gap *= vscale

	_specimen_base(base_r, base_h, tank_r)
	_specimen_readout(base_r, base_h)
	_specimen_cables(base_r, base_h, tank_r, tank_bottom, tank_h, cap_h)
	_specimen_glass(tank_r, tank_bottom, tank_h)
	_specimen_fluid(tank_r, tank_bottom, tank_h, fluid_inset, fluid_top_gap)
	_specimen_embryo(tank_r, tank_bottom, tank_h)
	_specimen_bubbles(tank_r, tank_bottom, tank_h, fluid_inset, fluid_top_gap)
	_specimen_cap(tank_r, tank_bottom, tank_h, cap_h)
	_specimen_rim_lights(base_r, base_h)


func _specimen_base(base_r: float, base_h: float, tank_r: float) -> void:
	var dark := Color(0.10, 0.12, 0.14)
	var mid := Color(0.16, 0.18, 0.21)
	_sl_cylinder(self, base_r * 0.96, base_r, base_h, Vector3(0, base_h * 0.5, 0),
		_sl_metal_mat(dark), 36)
	_sl_cylinder(self, tank_r + 0.04, base_r * 0.86, 0.07, Vector3(0, base_h + 0.035, 0),
		_sl_metal_mat(mid), 36)
	# Glowing seal ring at the glass/metal join — driven by color_a.
	var seal := _sl_emissive_mat(color_a, 1.0, 3.0)
	_sl_torus(self, tank_r - 0.02, tank_r + 0.05, Vector3(0, base_h + 0.07, 0), seal)
	# Three stubby feet.
	var foot_mat := _sl_metal_mat(Color(0.07, 0.08, 0.10))
	for i in range(3):
		var ang := TAU * (float(i) / 3.0) + 0.4
		var fp := Vector3(cos(ang) * (base_r * 0.82), 0.03, sin(ang) * (base_r * 0.82))
		_sl_cylinder(self, 0.06, 0.075, 0.06, fp, foot_mat, 14)


func _specimen_readout(base_r: float, base_h: float) -> void:
	var panel := Node3D.new()
	panel.name = "Readout"
	add_child(panel)
	panel.position = Vector3(0.0, base_h * 0.55, base_r - 0.01)
	panel.rotation_degrees = Vector3(-22.0, 0.0, 0.0)

	var housing := _sl_metal_mat(Color(0.08, 0.09, 0.11))
	_sl_box(panel, Vector3(0.30, 0.135, 0.025), Vector3.ZERO, housing)
	# Dark screen inset tinted by color_a.
	var screen := _sl_emissive_mat(color_a.darkened(0.25), 0.95, 1.3)
	_sl_box(panel, Vector3(0.20, 0.075, 0.006), Vector3(0.0, 0.022, 0.016), screen)
	# Row of indicator lights — accent + a couple of distinct sci-fi tints.
	var light_cols: Array[Color] = [
		accent,
		Color(1.00, 0.78, 0.20),
		Color(0.30, 0.70, 1.00),
		Color(1.00, 0.30, 0.40),
	]
	for i in range(light_cols.size()):
		var lx := -0.105 + 0.07 * float(i)
		var lmat := _sl_emissive_mat(light_cols[i], 1.0, 5.5)
		_sl_sphere(panel, 0.012, Vector3(lx, -0.045, 0.018), lmat, 8, 12)


func _specimen_cables(base_r: float, base_h: float, tank_r: float,
		tank_bottom: float, tank_h: float, cap_h: float) -> void:
	var cable_mat := _sl_metal_mat(Color(0.05, 0.06, 0.07))
	cable_mat.roughness = 0.7
	var top_y := tank_bottom + tank_h + cap_h * 0.4
	var anchors: Array[float] = [0.7, 2.45]
	for a in anchors:
		var top := Vector3(cos(a) * (tank_r + 0.02), top_y, sin(a) * (tank_r + 0.02))
		var bot := Vector3(cos(a) * (base_r - 0.05), base_h + 0.02, sin(a) * (base_r - 0.05))
		_specimen_cable_arc(top, bot, 0.022, cable_mat)


func _specimen_cable_arc(p_top: Vector3, p_bot: Vector3, radius: float, mat: Material) -> void:
	var segs := 7
	var bow := (p_top + p_bot) * 0.5
	bow += Vector3(bow.x, 0.0, bow.z).normalized() * 0.14
	bow.y -= 0.06
	var prev := p_top
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var omt := 1.0 - t
		var pt := omt * omt * p_top + 2.0 * omt * t * bow + t * t * p_bot
		_sl_segment(self, prev, pt, radius, mat, 10)
		prev = pt
	_sl_sphere(self, radius * 1.7, p_top, mat, 8, 12)
	_sl_sphere(self, radius * 1.7, p_bot, mat, 8, 12)


func _specimen_glass(tank_r: float, tank_bottom: float, tank_h: float) -> void:
	var glass := _sl_glass_mat(color_a.lerp(Color(0.45, 0.95, 0.85), 0.5))
	var y_centre := tank_bottom + tank_h * 0.5
	_sl_cylinder(self, tank_r, tank_r * 0.99, tank_h, Vector3(0, y_centre, 0), glass, 40)
	var inner := _sl_glass_mat(color_a.darkened(0.15), 0.07)
	_sl_cylinder(self, tank_r - 0.02, tank_r - 0.02, tank_h - 0.01, Vector3(0, y_centre, 0), inner, 40)


func _specimen_fluid(tank_r: float, tank_bottom: float, tank_h: float,
		fluid_inset: float, fluid_top_gap: float) -> void:
	var fluid_h := tank_h - fluid_top_gap
	var y_centre := tank_bottom + fluid_h * 0.5 + 0.01
	var r := tank_r - fluid_inset
	# Main glowing fluid volume — color_a.
	var fluid := _sl_emissive_mat(color_a, 0.30, 1.7)
	_sl_cylinder(self, r, r, fluid_h, Vector3(0, y_centre, 0), fluid, 36)
	# Brighter denser core glow.
	var core := _sl_emissive_mat(color_a.lightened(0.25), 0.16, 2.6)
	_sl_cylinder(self, r * 0.55, r * 0.55, fluid_h * 0.92, Vector3(0, y_centre, 0), core, 28)
	# Meniscus disc at the fluid surface.
	var surf := _sl_emissive_mat(color_a.lightened(0.3), 0.55, 2.2)
	_sl_cylinder(self, r, r, 0.012, Vector3(0, tank_bottom + fluid_h + 0.01, 0), surf, 36)
	# Soft fill light inside the tank.
	var lamp := OmniLight3D.new()
	lamp.light_color = color_a
	lamp.light_energy = _sl_glow_energy(2.4)
	lamp.omni_range = tank_r * 4.0
	lamp.position = Vector3(0.0, tank_bottom + tank_h * 0.5, 0.0)
	add_child(lamp)


func _specimen_embryo(tank_r: float, tank_bottom: float, tank_h: float) -> void:
	var centre := Vector3(0.0, tank_bottom + tank_h * 0.52, 0.0)
	var body := Node3D.new()
	body.name = "Specimen"
	body.position = centre
	body.rotation_degrees = Vector3(8.0, -24.0, 12.0)
	add_child(body)

	# Flesh driven by color_b (secondary tint).
	var flesh := _specimen_flesh_mat(color_b)
	var flesh_pale := _specimen_flesh_mat(color_b.lightened(0.18))
	var vein := _sl_emissive_mat(color_b.lightened(0.1), 0.9, 1.6)

	var lobes: Array = [
		[Vector3(0.0, 0.0, 0.0), 0.135, Vector3(1.0, 1.15, 1.0)],
		[Vector3(0.07, 0.06, 0.02), 0.10, Vector3(1.0, 1.0, 1.0)],
		[Vector3(-0.06, 0.09, -0.03), 0.085, Vector3(1.1, 0.9, 1.0)],
		[Vector3(0.02, -0.10, 0.05), 0.095, Vector3(1.0, 1.0, 1.2)],
		[Vector3(-0.04, -0.04, 0.08), 0.075, Vector3(1.0, 1.0, 1.0)],
		[Vector3(0.09, -0.02, -0.05), 0.07, Vector3(0.9, 1.0, 1.0)],
	]
	for i in range(lobes.size()):
		var pos: Vector3 = lobes[i][0]
		var rad: float = lobes[i][1]
		var scl: Vector3 = lobes[i][2]
		var mat: Material = flesh if i % 2 == 0 else flesh_pale
		var mi := _sl_sphere(body, rad, pos, mat, 16, 24)
		mi.scale = scl

	# Off-centre emissive "eye" nucleus — accent.
	var eye_mat := _sl_emissive_mat(accent, 0.95, 3.2)
	_sl_sphere(body, 0.05, Vector3(0.06, 0.07, 0.105), eye_mat, 12, 18)
	var pupil := _sl_emissive_mat(Color(0.15, 0.05, 0.10), 1.0, 0.4)
	_sl_sphere(body, 0.022, Vector3(0.07, 0.075, 0.14), pupil, 8, 12)

	_specimen_umbilical(body, Vector3(0.0, -0.12, 0.0), vein)

	# Radiating tendrils — count scales with complexity, jitter from _rng.
	var tendril_mat := _specimen_flesh_mat(color_b.darkened(0.1))
	var n_tendrils := clampi(complexity + 1, 3, 12)
	for i in range(n_tendrils):
		var ang := TAU * (float(i) / float(n_tendrils)) + 0.5
		var tilt := lerpf(-0.5, 0.6, _rng.randf())
		var origin := Vector3(cos(ang) * 0.11, 0.02 + tilt * 0.12, sin(ang) * 0.11)
		var dir := Vector3(cos(ang), tilt, sin(ang)).normalized()
		_specimen_tendril(body, origin, dir, tendril_mat)


func _specimen_flesh_mat(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.albedo_color = Color(tint.r, tint.g, tint.b, 0.92)
	m.metallic = 0.0
	m.roughness = 0.55
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = _sl_glow_energy(0.55)
	m.rim_enabled = true
	m.rim = 0.9
	m.rim_tint = 0.4
	return m


func _specimen_tendril(parent: Node3D, origin: Vector3, dir: Vector3, mat: Material) -> void:
	var segs := 6
	var pos := origin
	var step := 0.045
	var rad := 0.028
	var d := dir
	var curl := d.cross(Vector3.UP).normalized()
	if curl.length() < 0.001:
		curl = Vector3.RIGHT
	for i in range(segs):
		_sl_sphere(parent, rad, pos, mat, 8, 12)
		var bend := 0.5 + 0.12 * float(i)
		d = (d + curl * 0.18 * bend).normalized()
		pos += d * step
		rad = maxf(rad * 0.78, 0.006)
		step *= 0.95


func _specimen_umbilical(parent: Node3D, start: Vector3, mat: Material) -> void:
	var turns := 2.4
	var steps := 26
	var height := 0.42
	var coil_r := 0.07
	for i in range(steps + 1):
		var t := float(i) / float(steps)
		var ang := t * turns * TAU
		var shrink := 1.0 - 0.4 * t
		var p := start + Vector3(
			cos(ang) * coil_r * shrink,
			-height * t,
			sin(ang) * coil_r * shrink)
		_sl_sphere(parent, 0.018 * (1.0 - 0.4 * t) + 0.006, p, mat, 8, 12)


func _specimen_bubbles(tank_r: float, tank_bottom: float, tank_h: float,
		fluid_inset: float, fluid_top_gap: float) -> void:
	var bubble := _sl_emissive_mat(color_a.lightened(0.4), 0.42, 1.4)
	var fluid_top := tank_bottom + (tank_h - fluid_top_gap)
	var n := clampi(20 + complexity * 2, 8, 48)
	for i in range(n):
		var ang := _rng.randf() * TAU
		var rr := _rng.randf() * (tank_r - fluid_inset - 0.03)
		var yy := lerpf(tank_bottom + 0.05, fluid_top - 0.04, _rng.randf())
		var rad := lerpf(0.008, 0.022, _rng.randf())
		var p := Vector3(cos(ang) * rr, yy, sin(ang) * rr)
		_sl_sphere(self, rad, p, bubble, 8, 12)


func _specimen_cap(tank_r: float, tank_bottom: float, tank_h: float, cap_h: float) -> void:
	var dark := Color(0.11, 0.13, 0.15)
	var mid := Color(0.17, 0.19, 0.22)
	var cap_base_y := tank_bottom + tank_h
	_sl_cylinder(self, tank_r + 0.03, tank_r + 0.05, 0.06, Vector3(0, cap_base_y + 0.03, 0),
		_sl_metal_mat(mid), 36)
	# Bolt ring.
	var bolt := _sl_metal_mat(Color(0.22, 0.24, 0.27))
	for i in range(10):
		var ang := TAU * (float(i) / 10.0)
		var bp := Vector3(cos(ang) * (tank_r + 0.04), cap_base_y + 0.03, sin(ang) * (tank_r + 0.04))
		_sl_sphere(self, 0.014, bp, bolt, 6, 10)
	# Domed cap.
	var dome := _sl_sphere(self, tank_r + 0.02, Vector3(0, cap_base_y + 0.06, 0),
		_sl_metal_mat(dark), 14, 36)
	dome.scale = Vector3(1.0, cap_h / (tank_r + 0.02), 1.0)
	# Glowing valve / port on top — accent.
	var port := _sl_emissive_mat(accent, 0.95, 4.0)
	_sl_cylinder(self, 0.04, 0.05, 0.05, Vector3(0, cap_base_y + cap_h + 0.02, 0), port, 18)
	var beacon := _sl_emissive_mat(accent, 1.0, 6.0)
	_sl_sphere(self, 0.028, Vector3(0, cap_base_y + cap_h + 0.06, 0), beacon, 10, 16)


func _specimen_rim_lights(base_r: float, base_h: float) -> void:
	var cols: Array[Color] = [accent, color_a]
	for i in range(cols.size()):
		var ang := -0.5 + float(i) * 1.0
		var p := Vector3(cos(ang + PI * 0.5) * (base_r - 0.02),
			base_h + 0.02, sin(ang + PI * 0.5) * (base_r - 0.02))
		var m := _sl_emissive_mat(cols[i], 1.0, 6.0)
		_sl_sphere(self, 0.018, p, m, 8, 12)


# =============================================================================
# MODE: reactor — plasma core caged in gimbal rings + helical coils (v2)
# =============================================================================

func _build_reactor() -> void:
	var w := maxf(sculpt_width, 0.2)
	var base_h := 0.30
	var base_r := 0.50 * w
	var neck_h := 0.14
	var cage_bottom := base_h + neck_h
	var cage_r := 0.42 * w
	# Vertical scale so the antenna tip lands near sculpt_height.
	var native_total := 1.80
	var vscale := maxf(sculpt_height, 0.4) / native_total
	base_h *= vscale
	neck_h *= vscale
	cage_bottom = base_h + neck_h
	var core_y := 1.12 * vscale
	var core_r := 0.20 * w
	var total_top := native_total * vscale

	# color_a = plasma core, color_b = accelerator nodes / counter-tint, accent = arcs/tips.
	_reactor_base(base_r, base_h, neck_h)
	_reactor_conduits(base_r, base_h, cage_r, cage_bottom)
	_reactor_readout(base_r, base_h)
	_reactor_struts(base_r, cage_bottom, core_y, core_r, cage_r)
	_reactor_coils(cage_bottom, core_y, cage_r)
	_reactor_cage(core_y, cage_r)
	_reactor_core(core_y, core_r, cage_r)
	_reactor_arcs(core_y, core_r, cage_r)
	_reactor_finial(core_y, cage_r, total_top)


func _reactor_base(base_r: float, base_h: float, neck_h: float) -> void:
	var dark := Color(0.085, 0.10, 0.13)
	var mid := Color(0.15, 0.17, 0.21)
	var ring := Color(0.20, 0.22, 0.26)
	_sl_cylinder(self, base_r * 0.92, base_r, base_h, Vector3(0, base_h * 0.5, 0),
		_sl_metal_mat(dark), 40)
	_sl_torus(self, base_r - 0.015, base_r + 0.03, Vector3(0, base_h * 0.55, 0),
		_sl_metal_mat(ring), 44, 12)
	_sl_cylinder(self, base_r * 0.42, base_r * 0.78, neck_h, Vector3(0, base_h + neck_h * 0.5, 0),
		_sl_metal_mat(mid), 36)
	# Glowing ignition seal — color_a.
	var seal := _sl_emissive_mat(color_a, 0.9, 3.2)
	_sl_torus(self, base_r * 0.78, base_r * 0.86, Vector3(0, base_h + 0.005, 0), seal, 44, 12)
	# Bolt ring.
	var bolt := _sl_metal_mat(Color(0.24, 0.26, 0.30))
	for i in range(12):
		var ang := TAU * (float(i) / 12.0)
		var bp := Vector3(cos(ang) * (base_r - 0.04), base_h - 0.02, sin(ang) * (base_r - 0.04))
		_sl_sphere(self, 0.016, bp, bolt, 8, 12)
	# Three feet.
	var foot_mat := _sl_metal_mat(Color(0.06, 0.07, 0.09))
	for i in range(3):
		var ang := TAU * (float(i) / 3.0) + 0.5
		var fp := Vector3(cos(ang) * (base_r * 0.84), 0.035, sin(ang) * (base_r * 0.84))
		_sl_cylinder(self, 0.065, 0.085, 0.07, fp, foot_mat, 14)


func _reactor_conduits(base_r: float, base_h: float, cage_r: float, cage_bottom: float) -> void:
	var cable_mat := _sl_metal_mat(Color(0.05, 0.06, 0.08))
	cable_mat.roughness = 0.7
	var glow := _sl_emissive_mat(color_a, 1.0, 4.5)
	var azimuths: Array[float] = [0.9, 2.6, 4.4]
	for a in azimuths:
		var bot := Vector3(cos(a) * (base_r - 0.06), base_h + 0.02, sin(a) * (base_r - 0.06))
		var top := Vector3(cos(a) * (cage_r - 0.04), cage_bottom + 0.18, sin(a) * (cage_r - 0.04))
		_reactor_conduit_arc(bot, top, 0.026, cable_mat)
		_sl_sphere(self, 0.03, bot, glow, 10, 14)


func _reactor_conduit_arc(p_bot: Vector3, p_top: Vector3, radius: float, mat: Material) -> void:
	var segs := 8
	var bow := (p_bot + p_top) * 0.5
	bow += Vector3(bow.x, 0.0, bow.z).normalized() * 0.11
	var prev := p_bot
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var omt := 1.0 - t
		var pt := omt * omt * p_bot + 2.0 * omt * t * bow + t * t * p_top
		_sl_segment(self, prev, pt, radius, mat, 10)
		prev = pt
	_sl_sphere(self, radius * 1.6, p_bot, mat, 8, 12)
	_sl_sphere(self, radius * 1.6, p_top, mat, 8, 12)


func _reactor_readout(base_r: float, base_h: float) -> void:
	var panel := Node3D.new()
	panel.name = "Readout"
	add_child(panel)
	panel.position = Vector3(0.0, base_h * 0.52, base_r - 0.015)
	panel.rotation_degrees = Vector3(-20.0, 0.0, 0.0)

	var housing := _sl_metal_mat(Color(0.07, 0.08, 0.11))
	_sl_box(panel, Vector3(0.34, 0.16, 0.028), Vector3.ZERO, housing)
	# Screen tinted by color_a.
	var screen := _sl_emissive_mat(color_a.darkened(0.2), 0.95, 1.2)
	_sl_box(panel, Vector3(0.18, 0.085, 0.006), Vector3(-0.06, 0.026, 0.018), screen)
	# Oscilloscope traces — color_a hot.
	var trace := _sl_emissive_mat(color_a.lightened(0.4), 1.0, 3.0)
	for i in range(3):
		var ty := 0.026 + (float(i) - 1.0) * 0.022
		_sl_box(panel, Vector3(0.15, 0.004, 0.004), Vector3(-0.06, ty, 0.021), trace)
	# Circular dial / gauge.
	var dial_ring := _sl_metal_mat(Color(0.22, 0.24, 0.28))
	_sl_torus(panel, 0.034, 0.05, Vector3(0.10, 0.02, 0.016), dial_ring, 28, 10)
	var dial_face := _sl_emissive_mat(accent.lerp(Color(0.95, 0.80, 0.25), 0.5), 0.95, 1.6)
	var face_node := _sl_cylinder(panel, 0.034, 0.034, 0.006, Vector3(0.10, 0.02, 0.018), dial_face, 24)
	face_node.rotation_degrees = Vector3(90, 0, 0)
	# Dial needle.
	var needle := _sl_emissive_mat(Color(1.0, 0.35, 0.30), 1.0, 3.0)
	_sl_segment(panel, Vector3(0.10, 0.02, 0.022),
		Vector3(0.10 + 0.026, 0.02 + 0.018, 0.022), 0.004, needle, 6)
	# Indicator lights — accent leads.
	var light_cols: Array[Color] = [
		accent,
		Color(1.00, 0.78, 0.20),
		Color(0.30, 0.80, 1.00),
		Color(1.00, 0.30, 0.42),
	]
	for i in range(light_cols.size()):
		var lx := -0.13 + 0.045 * float(i)
		var lmat := _sl_emissive_mat(light_cols[i], 1.0, 5.5)
		_sl_sphere(panel, 0.011, Vector3(lx, -0.055, 0.018), lmat, 8, 12)


func _reactor_struts(base_r: float, cage_bottom: float, core_y: float,
		core_r: float, cage_r: float) -> void:
	var strut_mat := _sl_metal_mat(Color(0.13, 0.15, 0.18))
	var hub_y := core_y + cage_r + 0.10
	for i in range(3):
		var ang := TAU * (float(i) / 3.0) + 0.5
		var foot := Vector3(cos(ang) * (base_r * 0.55), cage_bottom + 0.02, sin(ang) * (base_r * 0.55))
		var head := Vector3(cos(ang) * 0.06, hub_y, sin(ang) * 0.06)
		_sl_segment(self, foot, head, 0.022, strut_mat, 10)
	_sl_sphere(self, 0.06, Vector3(0, hub_y, 0), _sl_metal_mat(Color(0.16, 0.18, 0.22)), 12, 18)
	_sl_cylinder(self, 0.018, 0.024, 0.14, Vector3(0, (hub_y + core_y + core_r) * 0.5 + 0.06, 0),
		strut_mat, 12)


func _reactor_coils(cage_bottom: float, core_y: float, cage_r: float) -> void:
	var coil_mat := _sl_metal_mat(Color(0.17, 0.19, 0.23))
	var n_coils := 4
	var helix_r := cage_r * 0.74
	var bottom_y := cage_bottom + 0.04
	var top_y := core_y + cage_r * 0.55
	var turns := 1.4
	var steps := clampi(20 + complexity * 2, 18, 40)
	for c in range(n_coils):
		var phase := TAU * (float(c) / float(n_coils))
		var prev := Vector3.ZERO
		for i in range(steps + 1):
			var t := float(i) / float(steps)
			var ang := phase + t * turns * TAU
			var pinch := 1.0 - 0.25 * absf(t - 0.5) * 2.0
			var r := helix_r * pinch
			var p := Vector3(cos(ang) * r, lerpf(bottom_y, top_y, t), sin(ang) * r)
			if i > 0:
				_sl_segment(self, prev, p, 0.013, coil_mat, 8)
			prev = p


func _reactor_cage(core_y: float, cage_r: float) -> void:
	var ring_mat := _sl_metal_mat(Color(0.20, 0.23, 0.27), _STEEL_TINT, 0.28)
	var centre := Vector3(0, core_y, 0)
	var orientations: Array[Vector3] = [
		Vector3(90, 0, 0),
		Vector3(0, 0, 0),
		Vector3(0, 90, 0),
		Vector3(35, 22, 14),
	]
	var radii: Array[float] = [cage_r, cage_r * 0.92, cage_r * 0.92, cage_r * 0.82]
	for i in range(orientations.size()):
		var outer := radii[i]
		var inner := outer - 0.022
		var t := _sl_torus(self, inner, outer, centre, ring_mat, 48, 12)
		t.rotation_degrees = orientations[i]
	# Accelerator ring with emissive nodes — color_b.
	var accel := _sl_metal_mat(Color(0.24, 0.27, 0.31), _STEEL_TINT, 0.30)
	var aring := _sl_torus(self, cage_r - 0.01, cage_r + 0.02, centre, accel, 52, 12)
	aring.rotation_degrees = Vector3(90, 0, 0)
	var node_mat := _sl_emissive_mat(color_b, 1.0, 4.5)
	var n_nodes := clampi(complexity + 3, 6, 12)
	for i in range(n_nodes):
		var ang := TAU * (float(i) / float(n_nodes))
		var p := centre + Vector3(cos(ang) * cage_r, 0.0, sin(ang) * cage_r)
		_sl_sphere(self, 0.022, p, node_mat, 8, 12)


func _reactor_core(core_y: float, core_r: float, cage_r: float) -> void:
	var centre := Vector3(0, core_y, 0)
	# Faint containment field — color_a.
	_sl_sphere(self, core_r * 1.5, centre, _reactor_field_mat(color_a), 18, 28)
	# Main plasma orb — color_a.
	var orb := _sl_emissive_mat(color_a, 1.0, 5.2)
	_sl_sphere(self, core_r, centre, orb, 24, 36)
	# Counter-tint swirl shell — color_b.
	var swirl := _sl_emissive_mat(color_b, 0.45, 4.0)
	var swirl_mi := _sl_sphere(self, core_r * 0.84, centre, swirl, 20, 30)
	swirl_mi.scale = Vector3(1.05, 0.9, 1.02)
	# Hot near-white inner core (color_a lightened toward white).
	var hot := _sl_emissive_mat(color_a.lightened(0.55), 1.0, 6.5)
	_sl_sphere(self, core_r * 0.42, centre, hot, 18, 26)
	# OmniLight — color_a.
	var lamp := OmniLight3D.new()
	lamp.light_color = color_a
	lamp.light_energy = _sl_glow_energy(4.5)
	lamp.omni_range = cage_r * 6.0
	lamp.omni_attenuation = 1.2
	lamp.position = centre
	add_child(lamp)
	# Second complementary light — color_b.
	var lamp2 := OmniLight3D.new()
	lamp2.light_color = color_b
	lamp2.light_energy = _sl_glow_energy(1.6)
	lamp2.omni_range = cage_r * 4.0
	lamp2.position = centre + Vector3(0.0, -0.05, 0.0)
	add_child(lamp2)


func _reactor_field_mat(tint: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_BACK
	m.albedo_color = Color(tint.r, tint.g, tint.b, 0.10)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	m.emission_enabled = true
	m.emission = tint
	m.emission_energy_multiplier = _sl_glow_energy(0.45)
	m.rim_enabled = true
	m.rim = 0.9
	m.rim_tint = 0.0
	return m


func _reactor_arcs(core_y: float, core_r: float, cage_r: float) -> void:
	# Faked lightning from core to cage — accent, jitter seeded from _rng.
	var arc_mat := _sl_emissive_mat(accent, 1.0, 7.0)
	var centre := Vector3(0, core_y, 0)
	var n_arcs := clampi(complexity, 3, 9)
	for a in range(n_arcs):
		var ang := TAU * (float(a) / float(n_arcs)) + 0.3
		var tilt := lerpf(-0.5, 0.6, _rng.randf())
		var dir := Vector3(cos(ang), tilt, sin(ang)).normalized()
		var start := centre + dir * (core_r * 1.55)
		var end := centre + dir * (cage_r - 0.02)
		_reactor_arc_strand(start, end, arc_mat)


func _reactor_arc_strand(start: Vector3, end: Vector3, mat: Material) -> void:
	var segs := 6
	var axis := end - start
	var length := axis.length()
	if length < 0.0001:
		return
	var fwd := axis / length
	var perp := fwd.cross(Vector3.UP)
	if perp.length() < 0.001:
		perp = fwd.cross(Vector3.RIGHT)
	perp = perp.normalized()
	var perp2 := fwd.cross(perp).normalized()
	var prev := start
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var base := start.lerp(end, t)
		var amp := sin(t * PI) * 0.05
		var jx := (_rng.randf() * 2.0 - 1.0) * amp
		var jy := (_rng.randf() * 2.0 - 1.0) * amp
		var p := base + perp * jx + perp2 * jy
		if i == segs:
			p = end
		_sl_segment(self, prev, p, 0.006, mat, 6)
		prev = p
	_sl_sphere(self, 0.018, end, mat, 8, 12)


func _reactor_finial(core_y: float, cage_r: float, total_top: float) -> void:
	var hub_y := core_y + cage_r + 0.10
	var cap_y := hub_y + 0.12
	var cap_mat := _sl_metal_mat(Color(0.15, 0.17, 0.21))
	_sl_cylinder(self, 0.05, 0.038, 0.07, Vector3(0, cap_y, 0), cap_mat, 18)
	var beacon := _sl_emissive_mat(color_a, 1.0, 7.0)
	_sl_sphere(self, 0.03, Vector3(0, cap_y + 0.06, 0), beacon, 10, 16)
	var spike_mat := _sl_metal_mat(Color(0.22, 0.24, 0.28))
	_sl_cylinder(self, 0.004, 0.008, 0.16, Vector3(0, cap_y + 0.06 + 0.10, 0), spike_mat, 8)
	var tip := _sl_emissive_mat(accent, 1.0, 8.0)
	_sl_sphere(self, 0.016, Vector3(0, total_top, 0), tip, 8, 12)


# =============================================================================
# MODE: scanner — articulated analysis arm + glowing sensor head (v3)
# =============================================================================

func _build_scanner() -> void:
	var w := maxf(sculpt_width, 0.2)
	# Native arm reaches ~1.7 m; scale the whole rig vertically + horizontally.
	var vscale := maxf(sculpt_height, 0.4) / 1.7

	var root := Node3D.new()
	root.name = "ScannerRig"
	add_child(root)
	root.scale = Vector3(w, vscale, w)

	# color_a = optics / probe core, color_b = sensor pods, accent = indicators / tips.
	_scanner_base(root)
	_scanner_stage(root)
	_scanner_panel(root)
	var head_pos := _scanner_arm(root)
	_scanner_head(root, head_pos)
	_scanner_beam(root, head_pos)


func _scanner_base(root: Node3D) -> void:
	var base_mat := _sl_metal_mat(Color(0.085, 0.095, 0.115), Color(0.13, 0.155, 0.18), 0.14)
	base_mat.metallic = clampf(metallic_amt * 0.65, 0.0, 1.0)
	base_mat.roughness = 0.42
	var plate_mat := _sl_metal_mat(Color(0.07, 0.08, 0.10), Color(0.11, 0.13, 0.16), 0.12)
	plate_mat.roughness = 0.5
	_sl_cylinder(root, 0.46, 0.52, 0.07, Vector3(0, 0.035, 0), plate_mat, 28)
	_sl_cylinder(root, 0.34, 0.40, 0.30, Vector3(0, 0.21, 0), base_mat, 6)
	_sl_cylinder(root, 0.36, 0.34, 0.05, Vector3(0, 0.385, 0), base_mat, 28)
	var bolt_mat := _sl_metal_mat(Color(0.15, 0.16, 0.19), Color(0.24, 0.27, 0.31), 0.28)
	bolt_mat.roughness = 0.2
	for i in range(6):
		var ang := TAU * float(i) / 6.0
		_sl_cylinder(root, 0.028, 0.028, 0.05,
			Vector3(cos(ang) * 0.42, 0.07, sin(ang) * 0.42), bolt_mat, 8)
	# Rear riser the arm mounts onto.
	var riser_mat := _sl_metal_mat(Color(0.115, 0.13, 0.155), _STEEL_TINT, 0.18)
	_sl_box(root, Vector3(0.20, 0.34, 0.18), Vector3(0, 0.55, -0.16), riser_mat)
	# Glowing seam strips on the riser front — accent.
	var seam := _sl_emissive_mat(accent.lerp(Color(0.08, 0.55, 0.85), 0.5), 1.0, 2.6)
	_sl_box(root, Vector3(0.13, 0.012, 0.005), Vector3(0, 0.62, -0.07), seam)
	_sl_box(root, Vector3(0.13, 0.012, 0.005), Vector3(0, 0.52, -0.07), seam)


func _scanner_stage(root: Node3D) -> void:
	var stage_center := Vector3(0, 0.40, 0.30)
	var stage_mat := _sl_metal_mat(Color(0.14, 0.155, 0.17), Color(0.18, 0.20, 0.24), 0.18)
	stage_mat.roughness = 0.35
	_sl_cylinder(root, 0.05, 0.07, 0.10, stage_center - Vector3(0, 0.05, 0), stage_mat, 16)
	_sl_cylinder(root, 0.20, 0.15, 0.035, stage_center, stage_mat, 32)
	# Under-lighting ring — color_a.
	_sl_torus(root, 0.025, 0.155, stage_center + Vector3(0, 0.020, 0),
		_sl_emissive_mat(color_a, 1.0, 2.2))
	_sl_cylinder(root, 0.13, 0.13, 0.008, stage_center + Vector3(0, 0.022, 0),
		_sl_emissive_mat(color_a.darkened(0.2), 1.0, 1.0), 28)
	var pl := OmniLight3D.new()
	pl.name = "StageLight"
	pl.light_color = color_a
	pl.light_energy = _sl_glow_energy(1.6)
	pl.omni_range = 0.9
	pl.position = stage_center + Vector3(0, 0.10, 0)
	root.add_child(pl)
	# The SAMPLE: a faceted glowing shard — color_b.
	_scanner_sample(root, stage_center + Vector3(0, 0.11, 0))


func _scanner_sample(root: Node3D, p: Vector3) -> void:
	var core := _sl_emissive_mat(color_b, 1.0, 4.5)
	core.roughness = 0.2
	var holder := Node3D.new()
	holder.name = "Sample"
	holder.position = p
	root.add_child(holder)
	var shard := _sl_box(holder, Vector3(0.07, 0.13, 0.07), Vector3(0, 0.02, 0), core)
	shard.rotation_degrees = Vector3(0, 45, 0)
	var shard_lo := _sl_box(holder, Vector3(0.085, 0.07, 0.085), Vector3(0, -0.05, 0), core)
	shard_lo.rotation_degrees = Vector3(0, 18, 0)
	_sl_sphere(holder, 0.028, Vector3(0, 0.0, 0), _sl_emissive_mat(color_b.lightened(0.4), 1.0, 6.0), 10, 12)
	# Two orbiting motes, jittered from _rng.
	var m1 := Vector3(0.12 + _rng.randf_range(-0.02, 0.02), 0.05, 0.02)
	var m2 := Vector3(-0.09, 0.10, -0.06 + _rng.randf_range(-0.02, 0.02))
	_sl_sphere(holder, 0.013, m1, _sl_emissive_mat(color_b.lightened(0.2), 1.0, 5.0), 8, 8)
	_sl_sphere(holder, 0.011, m2, _sl_emissive_mat(color_b.lightened(0.3), 1.0, 5.0), 8, 8)


func _scanner_panel(root: Node3D) -> void:
	var panel_mat := _sl_metal_mat(Color(0.09, 0.10, 0.12), Color(0.14, 0.16, 0.19), 0.16)
	panel_mat.roughness = 0.4
	var panel := _sl_box(root, Vector3(0.26, 0.12, 0.025), Vector3(0, 0.27, 0.345), panel_mat)
	panel.rotation_degrees = Vector3(-28, 0, 0)
	# Indicator lights — accent + greens/red.
	var cols: Array[Color] = [accent, Color(1.0, 0.42, 0.18), Color(1.0, 0.16, 0.30), accent]
	for i in range(cols.size()):
		var x := -0.085 + 0.045 * float(i)
		_sl_sphere(panel, 0.013, Vector3(x, 0.028, 0.02), _sl_emissive_mat(cols[i], 1.0, 5.0), 8, 10)
	# Screen strips — color_a.
	_sl_box(panel, Vector3(0.10, 0.022, 0.004), Vector3(-0.06, -0.018, 0.014),
		_sl_emissive_mat(color_a.lerp(Color(0.10, 0.7, 0.9), 0.5), 1.0, 2.0))
	_sl_box(panel, Vector3(0.06, 0.022, 0.004), Vector3(0.07, -0.018, 0.014),
		_sl_emissive_mat(color_a, 1.0, 2.0))
	# Brass dial.
	var brass := _sl_metal_mat(Color(0.62, 0.50, 0.24), Color(0.4, 0.32, 0.14), 0.18)
	brass.metallic = 0.9
	brass.roughness = 0.3
	var dial := _sl_cylinder(panel, 0.026, 0.030, 0.018, Vector3(0.07, 0.03, 0.016), brass, 18)
	dial.rotation_degrees = Vector3(90, 0, 0)
	_sl_box(panel, Vector3(0.004, 0.018, 0.004), Vector3(0.07, 0.03, 0.028),
		_sl_emissive_mat(accent.lightened(0.2), 1.0, 2.0))


func _scanner_arm(root: Node3D) -> Vector3:
	var metal := _sl_metal_mat(Color(0.10, 0.115, 0.135), _STEEL_TINT, 0.18)
	var metal_rim := _sl_metal_mat(Color(0.10, 0.115, 0.135), _STEEL_TINT, 0.30)
	metal_rim.roughness = 0.20
	var joint_mat := _sl_metal_mat(Color(0.13, 0.145, 0.17), Color(0.22, 0.28, 0.34), 0.26)
	joint_mat.roughness = 0.18
	var cable_mat := _sl_metal_mat(Color(0.06, 0.065, 0.08), Color(0.10, 0.11, 0.14), 0.14)
	cable_mat.metallic = 0.2
	cable_mat.roughness = 0.55

	var shoulder := Vector3(0, 0.74, -0.16)
	_sl_sphere(root, 0.075, shoulder, joint_mat, 16, 20)
	var p1 := shoulder + Vector3(0, 0.46, 0.10)
	_sl_capsule_segment(root, shoulder, p1, 0.052, metal)
	_sl_sphere(root, 0.066, p1, joint_mat, 16, 20)
	var p2 := p1 + Vector3(0, 0.12, 0.42)
	_sl_capsule_segment(root, p1, p2, 0.046, metal)
	_sl_sphere(root, 0.058, p2, joint_mat, 16, 20)
	var stage_top := Vector3(0, 0.40, 0.30)
	var head_pos := stage_top + Vector3(0, 0.52, 0.0)
	_sl_capsule_segment(root, p2, head_pos, 0.040, metal_rim)
	_sl_sphere(root, 0.050, head_pos, joint_mat, 16, 20)
	# Hydraulic pistons alongside segment 2.
	_sl_capsule_segment(root, p1 + Vector3(0.05, 0, 0), p2 + Vector3(0.05, 0, 0), 0.012, metal_rim)
	_sl_capsule_segment(root, p1 + Vector3(-0.05, 0, 0), p2 + Vector3(-0.05, 0, 0), 0.012, metal_rim)
	# Cables (sagging bead chains).
	_scanner_cable(root, shoulder + Vector3(0.04, 0, 0.05), p1 + Vector3(0.03, 0, 0),
		Vector3(0.10, -0.06, 0.04), cable_mat, 12, 0.016)
	_scanner_cable(root, p1 + Vector3(-0.03, 0, 0.02), p2 + Vector3(-0.03, 0, 0),
		Vector3(-0.08, -0.05, 0.02), cable_mat, 14, 0.014)
	_scanner_cable(root, p2 + Vector3(0.02, -0.02, 0), head_pos + Vector3(0.02, 0.05, 0),
		Vector3(0.06, -0.04, 0), cable_mat, 10, 0.013)
	return head_pos


func _scanner_cable(parent: Node3D, p0: Vector3, p1: Vector3, sag: Vector3,
		mat: Material, beads: int, r: float) -> void:
	var holder := Node3D.new()
	holder.name = "Cable"
	parent.add_child(holder)
	var mid := (p0 + p1) * 0.5 + sag
	for i in range(beads + 1):
		var t := float(i) / float(beads)
		var a := p0.lerp(mid, t)
		var b := mid.lerp(p1, t)
		var pos := a.lerp(b, t)
		_sl_sphere(holder, r, pos, mat, 6, 8)


func _scanner_head(root: Node3D, head_pos: Vector3) -> void:
	var head := Node3D.new()
	head.name = "SensorHead"
	head.position = head_pos
	root.add_child(head)
	var housing := _sl_metal_mat(Color(0.12, 0.135, 0.16), Color(0.18, 0.22, 0.27), 0.22)
	housing.roughness = 0.22
	_sl_sphere(head, 0.10, Vector3(0, 0.02, 0), housing, 16, 22)
	_sl_cylinder(head, 0.095, 0.115, 0.10, Vector3(0, -0.08, 0), housing, 28)
	# Concentric optic rings — color_a stack.
	var ring_y := -0.135
	_sl_torus(head, 0.018, 0.110, Vector3(0, ring_y, 0),
		_sl_emissive_mat(color_a.darkened(0.1), 1.0, 2.4))
	_sl_torus(head, 0.014, 0.078, Vector3(0, ring_y - 0.006, 0),
		_sl_emissive_mat(color_a, 1.0, 2.8))
	_sl_torus(head, 0.012, 0.050, Vector3(0, ring_y - 0.012, 0),
		_sl_emissive_mat(color_a.lightened(0.2), 1.0, 3.4))
	# Central glowing lens (the eye) — color_a.
	_sl_sphere(head, 0.040, Vector3(0, ring_y - 0.020, 0),
		_sl_emissive_mat(color_a.lightened(0.1), 1.0, 6.0), 16, 20)
	# Real spotlight onto the stage below.
	var spot := SpotLight3D.new()
	spot.name = "ScanLight"
	spot.light_color = color_a
	spot.light_energy = _sl_glow_energy(2.2)
	spot.spot_range = 1.2
	spot.spot_angle = 28.0
	spot.position = Vector3(0, ring_y - 0.02, 0)
	spot.rotation_degrees = Vector3(-90, 0, 0)
	head.add_child(spot)
	# Antennae / probes — accent tips.
	var ant_mat := _sl_metal_mat(Color(0.10, 0.115, 0.135), _STEEL_TINT, 0.30)
	ant_mat.roughness = 0.20
	var tip_mat := _sl_emissive_mat(accent, 1.0, 4.0)
	tip_mat.roughness = 0.3
	for i in range(4):
		var ang := TAU * float(i) / 4.0 + 0.4
		var base := Vector3(cos(ang) * 0.085, 0.05, sin(ang) * 0.085)
		var tip := base + Vector3(cos(ang) * 0.06, 0.16, sin(ang) * 0.06)
		_sl_capsule_segment(head, base, tip, 0.0075, ant_mat)
		_sl_sphere(head, 0.016, tip, tip_mat, 8, 10)
	# Side micro-sensor pods — color_b.
	_sl_sphere(head, 0.030, Vector3(0.10, -0.02, 0.02), _sl_emissive_mat(color_b, 1.0, 3.0), 12, 14)
	_sl_sphere(head, 0.026, Vector3(-0.10, -0.02, -0.02), _sl_emissive_mat(color_b.lerp(Color(0.2, 0.6, 1.0), 0.5), 1.0, 3.0), 12, 14)


func _scanner_beam(root: Node3D, head_pos: Vector3) -> void:
	var lens_y := head_pos.y - 0.155
	var sample_y := 0.51
	var height := maxf(lens_y - sample_y, 0.1)
	var beam := MeshInstance3D.new()
	beam.name = "ProbeBeam"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.018
	cone.bottom_radius = 0.16
	cone.height = height
	cone.radial_segments = 28
	beam.mesh = cone
	beam.material_override = _sl_flame_mat(accent, 0.22, 1.6)
	beam.position = Vector3(head_pos.x, (lens_y + sample_y) * 0.5, head_pos.z)
	root.add_child(beam)
	var coremi := MeshInstance3D.new()
	coremi.name = "ProbeCore"
	var ccyl := CylinderMesh.new()
	ccyl.top_radius = 0.006
	ccyl.bottom_radius = 0.010
	ccyl.height = height
	ccyl.radial_segments = 12
	coremi.mesh = ccyl
	coremi.material_override = _sl_flame_mat(accent.lightened(0.4), 0.5, 1.6)
	coremi.position = beam.position
	root.add_child(coremi)


# =============================================================================
# MODE: chemrig — alien glassware + condenser coil + burner (v4)
# =============================================================================

func _build_chemrig() -> void:
	var w := maxf(sculpt_width, 0.2)
	var vscale := maxf(sculpt_height, 0.4) / 1.7

	var root := Node3D.new()
	root.name = "ChemRig"
	add_child(root)
	root.scale = Vector3(w, vscale, w)

	# color_a = cyan cylinder fluid + glow, color_b = magenta retort fluid, accent = LED/drips.
	var metal := _sl_metal_mat(Color(0.105, 0.115, 0.135), _STEEL_TINT, 0.20)
	var metal_thin := _sl_metal_mat(Color(0.105, 0.115, 0.135), _STEEL_TINT, 0.32)
	metal_thin.roughness = 0.22
	var base_mat := _sl_metal_mat(Color(0.085, 0.092, 0.11), Color(0.135, 0.155, 0.185), 0.16)
	base_mat.metallic = clampf(metallic_amt * 0.65, 0.0, 1.0)
	base_mat.roughness = 0.45
	var brass := _sl_metal_mat(Color(0.60, 0.47, 0.21), Color(0.42, 0.32, 0.12), 0.34)
	brass.metallic = 0.7
	brass.roughness = 0.30
	var glass := _sl_glass_mat(Color(0.74, 0.86, 0.92), 0.16)
	var glass_tube := _sl_glass_mat(Color(0.74, 0.86, 0.92), 0.13)

	_chemrig_stand(root, base_mat, metal, metal_thin)
	_chemrig_retort(root, glass, brass)
	_chemrig_cylinder(root, glass, brass)
	_chemrig_side_flask(root, glass, brass)
	_chemrig_condenser(root)
	_chemrig_tubes(root, glass_tube)
	_chemrig_burner(root, metal, brass)
	_chemrig_details(root, metal_thin, brass)


func _chemrig_stand(root: Node3D, base_mat: Material, metal: Material, metal_thin: Material) -> void:
	var stand := Node3D.new()
	stand.name = "Stand"
	root.add_child(stand)
	_sl_box(stand, Vector3(1.18, 0.06, 0.78), Vector3(0.0, 0.03, 0.0), base_mat)
	_sl_box(stand, Vector3(1.26, 0.025, 0.86), Vector3(0.0, 0.012, 0.0), base_mat)
	for fx in [-0.5, 0.5]:
		for fz in [-0.3, 0.3]:
			_sl_cylinder(stand, 0.05, 0.06, 0.04, Vector3(fx, 0.005, fz), base_mat, 12)
	var post_h := 1.62
	_sl_cylinder(stand, 0.026, 0.030, post_h, Vector3(-0.46, 0.06 + post_h * 0.5, -0.18), metal_thin, 16)
	_sl_cylinder(stand, 0.026, 0.030, post_h, Vector3(0.50, 0.06 + post_h * 0.5, -0.18), metal_thin, 16)
	_sl_sphere(stand, 0.038, Vector3(-0.46, 0.06 + post_h, -0.18), metal, 8, 12)
	_sl_sphere(stand, 0.038, Vector3(0.50, 0.06 + post_h, -0.18), metal, 8, 12)
	_sl_segment(stand, Vector3(-0.46, 1.5, -0.18), Vector3(0.50, 1.5, -0.18), 0.022, metal, 14)
	_sl_segment(stand, Vector3(-0.46, 0.92, -0.18), Vector3(0.50, 0.92, -0.18), 0.02, metal, 14)


func _chemrig_clamp(parent: Node3D, target: Vector3, post_x: float, ring_r: float,
		metal: Material, brass: Material) -> void:
	var clamp := Node3D.new()
	clamp.name = "Clamp"
	parent.add_child(clamp)
	var post_pt := Vector3(post_x, target.y, -0.18)
	_sl_segment(clamp, post_pt, target, 0.017, metal, 10)
	var ring := _sl_torus(clamp, ring_r * 0.45, ring_r, target, metal)
	ring.rotation_degrees = Vector3(90, 0, 0)
	var knob_pos := post_pt.lerp(target, 0.34)
	_sl_sphere(clamp, 0.035, knob_pos, brass, 8, 12)
	_sl_cylinder(clamp, 0.012, 0.012, 0.05, knob_pos + Vector3(0, 0.04, 0), brass, 8)


func _chemrig_retort(root: Node3D, glass: Material, brass: Material) -> void:
	var grp := Node3D.new()
	grp.name = "Retort"
	root.add_child(grp)
	var cx := -0.34
	var body_cy := 0.46
	var body_r := 0.21
	_sl_sphere(grp, body_r, Vector3(cx, body_cy, 0.0), glass, 18, 24)
	_sl_cylinder(grp, 0.052, 0.075, 0.40, Vector3(cx, body_cy + body_r + 0.16, 0.0), glass, 18)
	_sl_cylinder(grp, 0.075, 0.052, 0.06, Vector3(cx, body_cy + body_r + 0.38, 0.0), glass, 18)
	var spout: Array[Vector3] = [
		Vector3(cx + body_r * 0.5, body_cy + body_r * 0.6, 0.05),
		Vector3(cx + 0.14, body_cy + body_r * 0.7, 0.08),
		Vector3(cx + 0.18, 1.02, 0.10),
		Vector3(-0.04, 1.30, 0.10),
		Vector3(-0.04, 1.34, 0.10),
	]
	_sl_tube_path(grp, spout, 0.030, glass, 10)
	# Glowing magenta fluid — color_b.
	var fluid := _chemrig_fluid_mat(color_b, 3.6, 0.66)
	var fluid_body := _sl_sphere(grp, body_r * 0.86, Vector3(cx, body_cy - 0.02, 0.0), fluid, 16, 20)
	fluid_body.scale = Vector3(1.0, 0.82, 1.0)
	var surf := _sl_emissive_mat(color_b.lightened(0.15), 1.0, 4.4)
	surf.roughness = 0.3
	_sl_cylinder(grp, body_r * 0.66, body_r * 0.66, 0.012, Vector3(cx, body_cy + 0.07, 0.0), surf, 18)
	# Rising bubbles — count scales with complexity, jittered from _rng.
	var bub := _sl_emissive_mat(color_b.lightened(0.35), 1.0, 3.8)
	bub.roughness = 0.2
	var n := clampi(6 + complexity, 4, 16)
	for i in range(n):
		var t := float(i) / float(n)
		var ang := t * TAU * 1.7 + _rng.randf_range(-0.2, 0.2)
		var rr := 0.05 + t * 0.04
		var yy := body_cy - 0.10 + t * 0.22
		var bx := cx + cos(ang) * rr
		var bz := sin(ang) * rr
		var br := lerpf(0.018, 0.030, t)
		_sl_sphere(grp, br, Vector3(bx, yy, bz), bub, 6, 8)


func _chemrig_fluid_mat(col: Color, energy: float, alpha: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(col.r, col.g, col.b, alpha)
	m.metallic = 0.0
	m.roughness = 0.20
	m.emission_enabled = true
	m.emission = col
	m.emission_energy_multiplier = _sl_glow_energy(energy)
	return m


func _chemrig_cylinder(root: Node3D, glass: Material, brass: Material) -> void:
	var grp := Node3D.new()
	grp.name = "GradCylinder"
	root.add_child(grp)
	var cx := 0.40
	var base_y := 0.10
	var height := 0.92
	var r := 0.115
	_sl_cylinder(grp, r, r * 1.04, height, Vector3(cx, base_y + height * 0.5, 0.0), glass, 22)
	_sl_sphere(grp, r * 1.02, Vector3(cx, base_y + r * 0.4, 0.0), glass, 12, 22)
	_sl_cylinder(grp, r * 1.35, r * 1.55, 0.05, Vector3(cx, base_y * 0.5 + 0.02, 0.0), glass, 22)
	_sl_torus(grp, r * 0.25, r * 1.05, Vector3(cx, base_y + height, 0.0), glass)
	# Glowing cyan fluid — color_a.
	var fill_h := height * 0.68
	var fluid := _chemrig_fluid_mat(color_a, 3.2, 0.6)
	_sl_cylinder(grp, r * 0.9, r * 0.92, fill_h, Vector3(cx, base_y + 0.04 + fill_h * 0.5, 0.0), fluid, 20)
	var surf := _sl_emissive_mat(color_a.lightened(0.18), 1.0, 4.2)
	surf.roughness = 0.3
	_sl_cylinder(grp, r * 0.9, r * 0.9, 0.012, Vector3(cx, base_y + 0.04 + fill_h, 0.0), surf, 20)
	for i in range(6):
		var gy := base_y + 0.12 + float(i) * 0.12
		_sl_torus(grp, r * 0.04, r * 1.02, Vector3(cx, gy, 0.0), brass)
	var bub := _sl_emissive_mat(color_a.lightened(0.3), 1.0, 3.6)
	bub.roughness = 0.2
	var nb := clampi(3 + complexity / 2, 3, 10)
	for i in range(nb):
		var t := float(i) / float(nb)
		var yy := base_y + 0.10 + t * fill_h * 0.85
		var bx := cx + cos(t * TAU * 2.0) * 0.03
		var bz := sin(t * TAU * 2.0) * 0.03
		_sl_sphere(grp, lerpf(0.016, 0.026, t), Vector3(bx, yy, bz), bub, 6, 8)


func _chemrig_side_flask(root: Node3D, glass: Material, brass: Material) -> void:
	var grp := Node3D.new()
	grp.name = "SideFlask"
	root.add_child(grp)
	var cx := 0.04
	var cz := 0.26
	var body_cy := 0.28
	var body_r := 0.135
	_sl_cylinder(grp, 0.05, body_r, 0.30, Vector3(cx, body_cy, cz), glass, 20)
	_sl_cylinder(grp, body_r, body_r * 1.02, 0.04, Vector3(cx, body_cy - 0.15 + 0.02, cz), glass, 20)
	_sl_cylinder(grp, 0.05, 0.05, 0.16, Vector3(cx, body_cy + 0.23, cz), glass, 16)
	_sl_torus(grp, 0.018, 0.058, Vector3(cx, body_cy + 0.31, cz), glass)
	# Amber fluid — accent-tinted (a third register).
	var amber := accent.lerp(Color(1.0, 0.62, 0.16), 0.5)
	var fluid := _chemrig_fluid_mat(amber, 3.8, 0.66)
	_sl_cylinder(grp, 0.045, body_r * 0.85, 0.16, Vector3(cx, body_cy - 0.06, cz), fluid, 18)
	var surf := _sl_emissive_mat(amber.lightened(0.15), 1.0, 3.8)
	surf.roughness = 0.3
	_sl_cylinder(grp, body_r * 0.72, body_r * 0.72, 0.01, Vector3(cx, body_cy + 0.02, cz), surf, 18)
	_sl_cylinder(grp, 0.044, 0.05, 0.05, Vector3(cx, body_cy + 0.34, cz), brass, 14)


func _chemrig_condenser(root: Node3D) -> void:
	var grp := Node3D.new()
	grp.name = "Condenser"
	root.add_child(grp)
	# Faintly glowing coil glass — color_a tinted.
	var coil_glass := _sl_glass_mat(color_a.lerp(Color(0.62, 0.86, 0.94), 0.5), 0.20)
	coil_glass.emission = color_a.lerp(Color(0.30, 0.72, 0.82), 0.5)
	coil_glass.emission_energy_multiplier = _sl_glow_energy(0.55)
	var axis := Vector3(0.04, 0.0, 0.16)
	var coil_top_y := 1.30
	var coil_bot_y := 0.74
	var turns := 5.0
	var coil_r := 0.115
	var samples := 80
	var pts: Array[Vector3] = []
	pts.append(Vector3(-0.04, 1.34, 0.10))
	for i in range(samples + 1):
		var t := float(i) / float(samples)
		var yy := lerpf(coil_top_y, coil_bot_y, t)
		var ang := t * TAU * turns
		var offset := Vector3(cos(ang) * coil_r, 0.0, sin(ang) * coil_r)
		pts.append(Vector3(axis.x, yy, axis.z) + offset)
	pts.append(Vector3(0.30, 0.66, 0.06))
	pts.append(Vector3(0.40, 0.62, 0.0))
	_sl_tube_path(grp, pts, 0.028, coil_glass, 9)
	# Support rod.
	var rod := _sl_metal_mat(Color(0.105, 0.115, 0.135), _STEEL_TINT, 0.30)
	rod.roughness = 0.22
	_sl_cylinder(grp, 0.012, 0.012, coil_top_y - coil_bot_y + 0.16,
		Vector3(axis.x, (coil_top_y + coil_bot_y) * 0.5, axis.z), rod, 10)
	# Condensate droplets — color_a.
	var drop := _sl_emissive_mat(color_a.lightened(0.2), 1.0, 3.4)
	drop.roughness = 0.2
	_sl_sphere(grp, 0.024, pts[int(pts.size() * 0.40)], drop, 7, 9)
	_sl_sphere(grp, 0.018, pts[int(pts.size() * 0.66)], drop, 7, 9)


func _chemrig_tubes(root: Node3D, glass_tube: Material) -> void:
	var grp := Node3D.new()
	grp.name = "Tubes"
	root.add_child(grp)
	var t1: Array[Vector3] = [
		Vector3(0.40, 1.00, 0.02),
		Vector3(0.34, 1.06, 0.12),
		Vector3(0.20, 1.02, 0.22),
		Vector3(0.04, 0.78, 0.26),
		Vector3(0.04, 0.62, 0.26),
	]
	_sl_tube_path(grp, t1, 0.024, glass_tube, 8)
	var t2: Array[Vector3] = [
		Vector3(-0.34, 1.02, 0.0),
		Vector3(-0.24, 0.96, 0.14),
		Vector3(-0.12, 0.84, 0.24),
		Vector3(0.04, 0.66, 0.26),
	]
	_sl_tube_path(grp, t2, 0.022, glass_tube, 8)
	# Coloured drips — color_a + accent.
	_sl_sphere(grp, 0.022, Vector3(0.20, 0.99, 0.22), _sl_emissive_mat(color_a.lightened(0.1), 1.0, 3.6), 8, 10)
	_sl_sphere(grp, 0.014, Vector3(0.20, 0.93, 0.22), _sl_emissive_mat(color_a.lightened(0.1), 1.0, 3.0), 7, 9)
	_sl_sphere(grp, 0.020, Vector3(-0.12, 0.84, 0.24), _sl_emissive_mat(accent.lightened(0.1), 1.0, 3.4), 8, 10)


func _chemrig_burner(root: Node3D, metal: Material, brass: Material) -> void:
	var grp := Node3D.new()
	grp.name = "Burner"
	root.add_child(grp)
	var cx := -0.34
	var base_y := 0.07
	var burner_col := Color(1.0, 0.5, 0.12)
	var burner_hot := Color(1.0, 0.86, 0.42)
	_sl_cylinder(grp, 0.085, 0.11, 0.12, Vector3(cx, base_y + 0.06, 0.0), metal, 18)
	_sl_torus(grp, 0.02, 0.09, Vector3(cx, base_y + 0.12, 0.0), brass)
	_sl_segment(grp, Vector3(cx, base_y + 0.04, 0.0), Vector3(cx - 0.14, base_y + 0.0, 0.18), 0.016, metal, 10)
	# Flame.
	var flame := _sl_flame_mat(burner_col, 0.55, 2.8)
	_sl_cylinder(grp, 0.001, 0.07, 0.20, Vector3(cx, base_y + 0.22, 0.0), flame, 16)
	var core := _sl_emissive_mat(burner_hot, 1.0, 5.0)
	core.roughness = 0.2
	_sl_cylinder(grp, 0.001, 0.035, 0.13, Vector3(cx, base_y + 0.18, 0.0), core, 14)
	var ring := _sl_emissive_mat(burner_col, 1.0, 4.6)
	ring.roughness = 0.2
	_sl_torus(grp, 0.012, 0.05, Vector3(cx, base_y + 0.13, 0.0), ring)
	# Pool of light.
	_sl_cylinder(grp, 0.30, 0.30, 0.004, Vector3(cx, 0.064, 0.0), _sl_flame_mat(burner_col, 0.32, 1.6), 28)
	var lamp := OmniLight3D.new()
	lamp.name = "BurnerLight"
	lamp.light_color = burner_col
	lamp.light_energy = _sl_glow_energy(2.2)
	lamp.omni_range = 1.1
	lamp.position = Vector3(cx, base_y + 0.18, 0.0)
	grp.add_child(lamp)


func _chemrig_details(root: Node3D, metal_thin: Material, brass: Material) -> void:
	var stand := root.get_node_or_null("Stand")
	var clamp_parent: Node3D = stand if stand != null else root
	_chemrig_clamp(clamp_parent, Vector3(-0.34, 0.92, 0.0), -0.46, 0.085, metal_thin, brass)
	_chemrig_clamp(clamp_parent, Vector3(0.40, 1.18, 0.0), 0.50, 0.135, metal_thin, brass)
	_chemrig_clamp(clamp_parent, Vector3(0.04, 0.60, 0.26), -0.46, 0.065, metal_thin, brass)
	# Indicator LED — accent.
	var led := _sl_emissive_mat(accent, 1.0, 5.0)
	led.roughness = 0.2
	_sl_sphere(root, 0.018, Vector3(0.34, 0.075, 0.30), led, 8, 10)
	_sl_torus(root, 0.006, 0.026, Vector3(0.34, 0.066, 0.30), brass)
	var lamp := OmniLight3D.new()
	lamp.name = "LEDLight"
	lamp.light_color = accent
	lamp.light_energy = _sl_glow_energy(0.7)
	lamp.omni_range = 0.28
	lamp.position = Vector3(0.34, 0.10, 0.30)
	root.add_child(lamp)


# ── Small rotation-aware primitive helpers (shared by the HL-lab modes) ───────

## Box with explicit Euler-degree rotation (the `_sl_box` variant returns a
## non-rotated mesh; these trials place many tilted boxes).
func _sl_box_rot(parent: Node3D, size: Vector3, pos: Vector3, rot_deg: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := _sl_box(parent, size, pos, mat)
	mi.rotation_degrees = rot_deg
	return mi


## Cylinder with explicit Euler-degree rotation.
func _sl_cyl_rot(parent: Node3D, top_r: float, bot_r: float, height: float,
		pos: Vector3, rot_deg: Vector3, mat: Material, radial: int = 24) -> MeshInstance3D:
	var mi := _sl_cylinder(parent, top_r, bot_r, height, pos, mat, radial)
	mi.rotation_degrees = rot_deg
	return mi


## Torus with explicit Euler-degree rotation.
func _sl_torus_rot(parent: Node3D, inner_r: float, outer_r: float, pos: Vector3,
		rot_deg: Vector3, mat: Material, rings: int = 28, ring_segs: int = 14) -> MeshInstance3D:
	var mi := _sl_torus(parent, inner_r, outer_r, pos, mat, rings, ring_segs)
	mi.rotation_degrees = rot_deg
	return mi


# =============================================================================
# MODE: spectrometer — Black Mesa anti-mass spectrometer (hllab trial v1)
# =============================================================================
# DNA mapping: color_a = teal emitter aperture + beam; color_b = green Xen
# crystal sample; accent = hazard stripes + CRT trace + indicator. The barrel
# aims down-and-forward into a crystal cluster on a sample cart; a gantry frames
# it, a console carries a CRT oscilloscope, conduits run along the floor.

# Iconic aim points (native trial coordinates, scaled by _spec_s()).
const _SPEC_EMITTER_TIP: Vector3 = Vector3(0.0, 0.74, 0.46)
const _SPEC_CRYSTAL_POS: Vector3 = Vector3(0.0, 0.30, 0.62)


func _build_spectrometer() -> void:
	var w := maxf(sculpt_width, 0.2)
	# Native rig is ~2.0 m tall; scale vertically to honour sculpt_height.
	var vscale := maxf(sculpt_height, 0.4) / 2.0

	var root := Node3D.new()
	root.name = "Spectrometer"
	add_child(root)
	root.scale = Vector3(w, vscale, w)

	# Beige/grey machined metal — each tint is its own emission floor (trial used
	# emission = albedo * 0.14), so it never renders black.
	var beige := _sl_metal_mat(Color(0.70, 0.66, 0.56), Color(0.70, 0.66, 0.56), 0.14)
	beige.roughness = 0.55
	beige.metallic = clampf(metallic_amt * 0.82, 0.0, 1.0)
	var grey := _sl_metal_mat(Color(0.52, 0.54, 0.57), Color(0.52, 0.54, 0.57), 0.14)
	grey.roughness = 0.5
	var dark := _sl_metal_mat(Color(0.30, 0.31, 0.33), Color(0.30, 0.31, 0.33), 0.14)
	dark.roughness = 0.45
	var hazard := _sl_hazard_mat(10)

	_spectrometer_gantry(root, grey, dark)
	_spectrometer_emitter(root, beige, grey, dark, hazard)
	_spectrometer_sample(root, grey, dark, hazard)
	_spectrometer_beam(root)
	_spectrometer_console(root, beige, dark, hazard)
	_spectrometer_conduits(root, dark)
	# Cool ambient fill so the beige metal reads without washing the glows.
	var fill := OmniLight3D.new()
	fill.name = "FillLight"
	fill.light_color = Color(0.7, 0.78, 0.9)
	fill.light_energy = _sl_glow_energy(0.7)
	fill.omni_range = 4.5
	fill.position = Vector3(0.6, 1.9, 1.2)
	root.add_child(fill)


func _spectrometer_gantry(root: Node3D, grey: Material, dark: Material) -> void:
	var g := Node3D.new()
	g.name = "Gantry"
	root.add_child(g)
	var leg_h := 1.55
	var fx := 0.62
	var fz := 0.55
	var corners: Array[Vector2] = [
		Vector2(-fx, -fz), Vector2(fx, -fz), Vector2(-fx, fz), Vector2(fx, fz)
	]
	for cpos in corners:
		_sl_cylinder(g, 0.05, 0.06, leg_h, Vector3(cpos.x, leg_h * 0.5, cpos.y), grey, 10)
		_sl_cylinder(g, 0.11, 0.11, 0.05, Vector3(cpos.x, 0.025, cpos.y), dark, 12)
	var top_y := 1.5
	_sl_box(g, Vector3(2.0 * fx + 0.1, 0.08, 0.09), Vector3(0.0, top_y, -fz), grey)
	_sl_box(g, Vector3(2.0 * fx + 0.1, 0.08, 0.09), Vector3(0.0, top_y, fz), grey)
	_sl_box(g, Vector3(0.09, 0.08, 2.0 * fz + 0.1), Vector3(-fx, top_y, 0.0), grey)
	_sl_box(g, Vector3(0.09, 0.08, 2.0 * fz + 0.1), Vector3(fx, top_y, 0.0), grey)
	# Diagonal cross-braces on the back face.
	_sl_box_rot(g, Vector3(0.05, 1.6, 0.05), Vector3(-fx, 0.75, -fz), Vector3(0, 0, 38), dark)
	_sl_box_rot(g, Vector3(0.05, 1.6, 0.05), Vector3(fx, 0.75, -fz), Vector3(0, 0, -38), dark)


func _spectrometer_emitter(root: Node3D, beige: Material, grey: Material,
		dark: Material, hazard: Material) -> void:
	var e := Node3D.new()
	e.name = "Emitter"
	root.add_child(e)
	# Pivot the whole barrel: aimed DOWN-and-FORWARD (+Z, downward).
	var pivot := Node3D.new()
	pivot.name = "BarrelPivot"
	pivot.position = Vector3(0.0, 1.46, -0.16)
	pivot.rotation_degrees = Vector3(140.0, 0.0, 0.0)
	e.add_child(pivot)

	var barrel_len := 0.95
	_sl_cylinder(pivot, 0.20, 0.26, barrel_len, Vector3(0.0, barrel_len * 0.5, 0.0), beige, 28)
	_sl_cylinder(pivot, 0.28, 0.22, 0.10, Vector3(0.0, -0.02, 0.0), grey, 28)
	# Hazard band around the body — accent stripes.
	_sl_cylinder(pivot, 0.265, 0.235, 0.16, Vector3(0.0, barrel_len * 0.42, 0.0), hazard, 28)
	# Dark reinforcement ribs.
	for ry in [0.18, 0.60]:
		_sl_torus_rot(pivot, 0.20, 0.255, Vector3(0.0, ry, 0.0), Vector3(90, 0, 0), dark, 24, 16)

	# Concentric FOCUSING RINGS at the mouth, increasing radius outward.
	var mouth_y := barrel_len
	var ring_specs: Array = [
		[0.18, 0.24, dark],
		[0.21, 0.28, grey],
		[0.24, 0.32, dark],
		[0.27, 0.36, grey],
	]
	for idx in range(ring_specs.size()):
		var spec: Array = ring_specs[idx]
		_sl_torus_rot(pivot, float(spec[0]), float(spec[1]),
			Vector3(0.0, mouth_y + 0.02 + float(idx) * 0.05, 0.0), Vector3(90, 0, 0),
			spec[2] as Material, 24, 16)

	# Glowing TEAL emitter aperture (a disc + a cone of light) — color_a.
	_sl_cylinder(pivot, 0.19, 0.19, 0.02, Vector3(0.0, mouth_y + 0.01, 0.0),
		_sl_emissive_mat(color_a, 1.0, 5.0), 28)
	_sl_cylinder(pivot, 0.02, 0.20, 0.16, Vector3(0.0, mouth_y + 0.12, 0.0),
		_sl_emissive_mat(color_a.lightened(0.2), 1.0, 6.0), 24)

	# Bright point light at the aperture — color_a (in scaled root space).
	var ap_light := OmniLight3D.new()
	ap_light.name = "ApertureLight"
	ap_light.light_color = color_a
	ap_light.light_energy = _sl_glow_energy(2.4)
	ap_light.omni_range = 1.4
	ap_light.position = _SPEC_EMITTER_TIP
	root.add_child(ap_light)

	# Yoke arms connecting barrel sides to the gantry frame.
	for sx in [-1.0, 1.0]:
		_sl_box_rot(e, Vector3(0.07, 0.5, 0.07), Vector3(sx * 0.46, 1.34, -0.18),
			Vector3(20, 0, 0), grey)


func _spectrometer_sample(root: Node3D, grey: Material, dark: Material, hazard: Material) -> void:
	var s := Node3D.new()
	s.name = "Sample"
	root.add_child(s)
	_sl_box(s, Vector3(0.5, 0.06, 0.34), Vector3(0.0, 0.05, 0.62), grey)
	_sl_box(s, Vector3(0.52, 0.07, 0.04), Vector3(0.0, 0.10, 0.78), hazard)
	_sl_cylinder(s, 0.08, 0.12, 0.14, Vector3(0.0, 0.15, 0.62), dark, 16)
	_sl_cylinder(s, 0.16, 0.11, 0.05, Vector3(0.0, 0.24, 0.62), grey, 20)
	# Four clamp posts around the dish.
	for ang_i in range(4):
		var a := float(ang_i) * PI * 0.5 + PI * 0.25
		var px := cos(a) * 0.13
		var pz := sin(a) * 0.13 + 0.62
		_sl_cylinder(s, 0.02, 0.02, 0.08, Vector3(px, 0.28, pz), dark, 8)
	_spectrometer_crystal(s)


func _spectrometer_crystal(parent: Node3D) -> void:
	# Faceted glowing Xen crystal cluster — color_b. Jitter seeded from _rng.
	var cluster := Node3D.new()
	cluster.name = "XenCrystal"
	cluster.position = _SPEC_CRYSTAL_POS
	parent.add_child(cluster)
	var core_mat := _sl_emissive_mat(color_b, 1.0, 5.5)
	core_mat.roughness = 0.4
	var shard_mat := _sl_emissive_mat(color_b.lightened(0.15), 1.0, 4.4)
	shard_mat.roughness = 0.4
	# Central tall shard (pointed prism = low-segment cone).
	_sl_cylinder(cluster, 0.0, 0.07, 0.34, Vector3(0.0, 0.10, 0.0), core_mat, 6)
	var shard_data: Array = [
		[Vector3(0.07, 0.02, 0.03), Vector3(18, 0, 28), 0.22, 0.05],
		[Vector3(-0.08, 0.0, -0.02), Vector3(-12, 40, -34), 0.20, 0.045],
		[Vector3(0.02, 0.0, -0.08), Vector3(26, 0, -16), 0.24, 0.05],
		[Vector3(-0.04, 0.0, 0.08), Vector3(-22, 0, 18), 0.18, 0.04],
		[Vector3(0.10, 0.0, -0.05), Vector3(8, 0, 44), 0.16, 0.04],
	]
	var n_shards := clampi(2 + complexity, 3, shard_data.size())
	for i in range(n_shards):
		var sd: Array = shard_data[i]
		var off: Vector3 = sd[0]
		var rot: Vector3 = sd[1]
		var hh: float = float(sd[2])
		var rr: float = float(sd[3])
		# tiny deterministic jitter on the angle so reseeds are siblings.
		rot += Vector3(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-6.0, 6.0), _rng.randf_range(-4.0, 4.0))
		_sl_cyl_rot(cluster, 0.0, rr, hh, off + Vector3(0.0, hh * 0.4, 0.0), rot, shard_mat, 5)
	var gl := OmniLight3D.new()
	gl.name = "CrystalLight"
	gl.light_color = color_b
	gl.light_energy = _sl_glow_energy(2.2)
	gl.omni_range = 1.6
	gl.position = Vector3(0.0, 0.12, 0.0)
	cluster.add_child(gl)


func _spectrometer_beam(root: Node3D) -> void:
	var b := Node3D.new()
	b.name = "Beam"
	root.add_child(b)
	var start := _SPEC_EMITTER_TIP
	var endp := _SPEC_CRYSTAL_POS + Vector3(0.0, 0.16, 0.0)
	var dir := endp - start
	var length := dir.length()
	var mid := (start + endp) * 0.5
	# Outer translucent cone (wide at emitter, narrow at crystal) — color_a.
	var outer := MeshInstance3D.new()
	outer.name = "BeamCone"
	var cone := CylinderMesh.new()
	cone.top_radius = 0.035
	cone.bottom_radius = 0.16
	cone.height = length
	cone.radial_segments = 20
	outer.mesh = cone
	outer.material_override = _sl_flame_mat(color_a, 0.28, 3.5)
	outer.position = mid
	_sl_orient_y_along(outer, start, endp)
	b.add_child(outer)
	# Bright inner core column.
	var inner := MeshInstance3D.new()
	inner.name = "BeamCore"
	var ccyl := CylinderMesh.new()
	ccyl.top_radius = 0.015
	ccyl.bottom_radius = 0.05
	ccyl.height = length
	ccyl.radial_segments = 12
	inner.mesh = ccyl
	inner.material_override = _sl_flame_mat(color_a.lightened(0.45), 0.7, 6.0)
	inner.position = mid
	_sl_orient_y_along(inner, start, endp)
	b.add_child(inner)
	# Flare spheres at the strike point and the mouth.
	_sl_sphere(b, 0.12, endp, _sl_flame_mat(color_a.lightened(0.55), 0.8, 5.5), 16, 10)
	_sl_sphere(b, 0.07, start, _sl_flame_mat(color_a.lightened(0.3), 0.8, 5.0), 12, 10)


## Orient a +Y-axis cylinder mesh so its axis spans a -> b (basis only, in-tree).
func _sl_orient_y_along(mi: MeshInstance3D, a: Vector3, bpt: Vector3) -> void:
	var dir := bpt - a
	if dir.length() < 0.0001:
		return
	var up := Vector3.UP
	var ndir := dir.normalized()
	var dot := clampf(up.dot(ndir), -1.0, 1.0)
	if dot < 0.99995 and dot > -0.99995:
		var axis := up.cross(ndir).normalized()
		mi.basis = Basis(axis, acos(dot))
	elif dot <= -0.99995:
		mi.basis = Basis(Vector3.RIGHT, PI)


func _spectrometer_console(root: Node3D, beige: Material, dark: Material, hazard: Material) -> void:
	var cb := Node3D.new()
	cb.name = "ControlBox"
	cb.position = Vector3(0.72, 0.0, 0.05)
	root.add_child(cb)
	_sl_box(cb, Vector3(0.42, 0.46, 0.34), Vector3(0.0, 0.55, 0.0), beige)
	_sl_box_rot(cb, Vector3(0.36, 0.30, 0.04), Vector3(0.0, 0.62, 0.18), Vector3(-22, 0, 0), dark)
	_sl_box(cb, Vector3(0.42, 0.05, 0.34), Vector3(0.0, 0.79, 0.0), hazard)
	_sl_cylinder(cb, 0.07, 0.09, 0.32, Vector3(0.0, 0.16, 0.0), dark, 10)
	# CRT screen — accent-tinted oscilloscope trace baked into a texture.
	_sl_box_rot(cb, Vector3(0.26, 0.20, 0.012), Vector3(0.0, 0.64, 0.205),
		Vector3(-22, 0, 0), _sl_crt_mat())
	var sl := OmniLight3D.new()
	sl.name = "CRTLight"
	sl.light_color = accent
	sl.light_energy = _sl_glow_energy(0.9)
	sl.omni_range = 0.7
	sl.position = Vector3(0.0, 0.64, 0.30)
	cb.add_child(sl)
	# Indicator lights row beneath the screen.
	var ind_cols: Array[Color] = [
		Color(1.0, 0.2, 0.15), Color(1.0, 0.7, 0.1), Color(0.2, 1.0, 0.3)
	]
	for i in range(ind_cols.size()):
		_sl_sphere(cb, 0.022, Vector3(-0.08 + float(i) * 0.08, 0.50, 0.205),
			_sl_emissive_mat(ind_cols[i], 1.0, 4.0), 10, 12)


func _spectrometer_conduits(root: Node3D, dark: Material) -> void:
	var c := Node3D.new()
	c.name = "Conduits"
	root.add_child(c)
	_sl_cyl_rot(c, 0.04, 0.04, 0.7, Vector3(0.45, 0.92, -0.22), Vector3(0, 0, 64), dark, 10)
	_sl_cyl_rot(c, 0.035, 0.035, 0.55, Vector3(0.40, 0.55, 0.10), Vector3(28, 0, 18), dark, 10)
	_sl_cyl_rot(c, 0.05, 0.05, 1.3, Vector3(0.0, 0.07, -0.55), Vector3(0, 0, 90), dark, 10)
	_sl_box(c, Vector3(0.08, 0.08, 0.08), Vector3(0.55, 0.6, -0.22), dark)


# =============================================================================
# MODE: teleporter — Combine teleportation pad + portal column (hllab trial v2)
# =============================================================================
# DNA mapping: color_a = blue-white portal energy (disc + column + light);
# color_b = the hotter core / ring filament energy; accent = combine hazard
# chevrons + alert indicators. A circular deck holds a portal disc firing a
# vertical light column; tilted gimbal rings arc over it; consoles + cables at
# the rim; energy arcs and motes rise in the column.

const _TP_PAD_RADIUS: float = 0.95
const _TP_PAD_HEIGHT: float = 0.18


func _build_teleporter() -> void:
	var w := maxf(sculpt_width, 0.2)
	# Native rig is ~2.0 m to the ring apex; scale vertically.
	var vscale := maxf(sculpt_height, 0.4) / 2.0

	var root := Node3D.new()
	root.name = "Teleporter"
	add_child(root)
	root.scale = Vector3(w, vscale, w)

	_teleporter_deck(root)
	_teleporter_portal(root)
	_teleporter_rings(root)
	_teleporter_gantry(root)
	_teleporter_consoles(root)
	_teleporter_cables(root)
	_teleporter_fx(root)


## Combine dark blue-grey metal — albedo doubles as its own faint emission floor.
func _tp_metal(albedo: Color, emit: Color, rough: float = 0.55, metal: float = 0.85) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = albedo
	m.roughness = rough
	m.metallic = clampf(metal, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = emit
	m.emission_energy_multiplier = 1.0
	return m


func _teleporter_deck(root: Node3D) -> void:
	var deck := Node3D.new()
	deck.name = "Deck"
	root.add_child(deck)
	var c_metal := Color(0.16, 0.18, 0.22)
	var c_metal_emit := Color(0.05, 0.07, 0.11)
	var c_metal_dark := Color(0.10, 0.11, 0.14)
	var c_metal_dark_emit := Color(0.03, 0.05, 0.09)
	var c_panel := Color(0.22, 0.25, 0.30)
	var pad_mat := _tp_metal(c_metal, c_metal_emit, 0.6, 0.8)
	_sl_cylinder(deck, _TP_PAD_RADIUS, _TP_PAD_RADIUS * 1.04, _TP_PAD_HEIGHT,
		Vector3(0.0, _TP_PAD_HEIGHT * 0.5, 0.0), pad_mat, 40)
	var rim_mat := _tp_metal(c_metal_dark, c_metal_dark_emit, 0.45, 0.9)
	_sl_torus(deck, _TP_PAD_RADIUS * 0.92 - 0.05, _TP_PAD_RADIUS * 0.92 + 0.05,
		Vector3(0.0, _TP_PAD_HEIGHT, 0.0), rim_mat, 40, 8)
	var skirt_mat := _tp_metal(c_metal_dark, c_metal_dark_emit, 0.7, 0.7)
	_sl_cylinder(deck, _TP_PAD_RADIUS * 1.06, _TP_PAD_RADIUS * 1.18, 0.08,
		Vector3(0.0, 0.04, 0.0), skirt_mat, 40)
	# Radial hazard chevrons on the deck top — accent.
	var hz_mat := _sl_hazard_mat(2)
	var wedge_count := clampi(6 + complexity, 6, 12)
	for i in range(wedge_count):
		var ang := (float(i) / float(wedge_count)) * TAU
		var rr := _TP_PAD_RADIUS * 0.78
		var deg := rad_to_deg(ang)
		_sl_box_rot(deck, Vector3(0.06, 0.012, 0.22),
			Vector3(cos(ang) * rr, _TP_PAD_HEIGHT + 0.006, sin(ang) * rr),
			Vector3(0.0, -deg + 90.0, 0.0), hz_mat)
	# Six bolt-feet around the skirt.
	var bolt_mat := _tp_metal(c_panel, c_metal_dark_emit, 0.4, 0.95)
	for j in range(6):
		var ba := (float(j) / 6.0) * TAU + 0.3
		var brad := _TP_PAD_RADIUS * 1.12
		_sl_cylinder(deck, 0.05, 0.06, 0.06,
			Vector3(cos(ba) * brad, 0.03, sin(ba) * brad), bolt_mat, 8)


func _teleporter_portal(root: Node3D) -> void:
	var portal := Node3D.new()
	portal.name = "Portal"
	root.add_child(portal)
	var top_y := _TP_PAD_HEIGHT + 0.012
	# Recessed dark well.
	var well_mat := _tp_metal(Color(0.04, 0.05, 0.07), Color(0.02, 0.03, 0.05), 0.35, 0.95)
	_sl_cylinder(portal, _TP_PAD_RADIUS * 0.66, _TP_PAD_RADIUS * 0.66, 0.03,
		Vector3(0.0, top_y, 0.0), well_mat, 36)
	# Energy disc — color_a.
	_sl_cylinder(portal, _TP_PAD_RADIUS * 0.6, _TP_PAD_RADIUS * 0.6, 0.02,
		Vector3(0.0, top_y + 0.02, 0.0), _sl_emissive_mat(color_a, 1.0, 4.2), 36)
	# Concentric energy rings — color_b (hotter).
	var ring_mat := _sl_emissive_mat(color_b, 1.0, 5.5)
	_sl_torus(portal, _TP_PAD_RADIUS * 0.44 - 0.018, _TP_PAD_RADIUS * 0.44 + 0.018,
		Vector3(0.0, top_y + 0.03, 0.0), ring_mat, 36, 8)
	_sl_torus(portal, _TP_PAD_RADIUS * 0.26 - 0.016, _TP_PAD_RADIUS * 0.26 + 0.016,
		Vector3(0.0, top_y + 0.03, 0.0), ring_mat, 36, 8)
	# Hot core dot — color_b.
	_sl_sphere(portal, 0.09, Vector3(0.0, top_y + 0.06, 0.0),
		_sl_emissive_mat(color_b, 1.0, 7.0), 10, 16)
	# Vertical translucent LIGHT COLUMN — stacked tapering additive cylinders.
	var col_base_y := top_y + 0.04
	var col_segments := 5
	var col_height := 1.75
	var seg_h := col_height / float(col_segments)
	for s in range(col_segments):
		var t0 := float(s) / float(col_segments)
		var r0 := lerpf(_TP_PAD_RADIUS * 0.52, _TP_PAD_RADIUS * 0.14, t0)
		var r1 := lerpf(_TP_PAD_RADIUS * 0.52, _TP_PAD_RADIUS * 0.14, float(s + 1) / float(col_segments))
		var seg_alpha := lerpf(0.32, 0.08, t0)
		var seg_energy := lerpf(2.6, 1.2, t0)
		var cy := col_base_y + seg_h * (float(s) + 0.5)
		_sl_cylinder(portal, r1, r0, seg_h, Vector3(0.0, cy, 0.0),
			_sl_flame_mat(color_a, seg_alpha, seg_energy), 28)
	# Bright inner core column — color_b.
	_sl_cylinder(portal, 0.06, 0.14, col_height, Vector3(0.0, col_base_y + col_height * 0.5, 0.0),
		_sl_flame_mat(color_b, 0.55, 4.5), 20)
	# OmniLights casting cold portal light — color_a then color_b.
	var light := OmniLight3D.new()
	light.name = "PortalLight"
	light.light_color = color_a
	light.light_energy = _sl_glow_energy(4.0)
	light.omni_range = 4.5
	light.omni_attenuation = 1.4
	light.position = Vector3(0.0, top_y + 0.55, 0.0)
	portal.add_child(light)
	var light_top := OmniLight3D.new()
	light_top.name = "PortalLightTop"
	light_top.light_color = color_b
	light_top.light_energy = _sl_glow_energy(1.8)
	light_top.omni_range = 2.8
	light_top.position = Vector3(0.0, col_base_y + col_height * 0.8, 0.0)
	portal.add_child(light_top)


func _teleporter_rings(root: Node3D) -> void:
	var rings := Node3D.new()
	rings.name = "Rings"
	root.add_child(rings)
	var pivot_y := _TP_PAD_HEIGHT + 0.78
	var c_metal_dark := Color(0.10, 0.11, 0.14)
	var c_metal_dark_emit := Color(0.03, 0.05, 0.09)
	var c_panel := Color(0.22, 0.25, 0.30)
	var hoop_mat := _tp_metal(c_metal_dark, c_metal_dark_emit, 0.4, 0.95)
	# Three rings on gimbal pivots, frozen mid-rotation. [major, tube, tx, tz, spin, energy_b?]
	var ring_specs: Array = [
		[0.82, 0.05, 18.0, 0.0, 22.0, false],
		[0.66, 0.045, -34.0, 24.0, -48.0, true],
		[0.50, 0.04, 62.0, -14.0, 70.0, false],
	]
	for spec_v in ring_specs:
		var spec: Array = spec_v
		var major: float = spec[0]
		var tube: float = spec[1]
		var gimbal := Node3D.new()
		gimbal.position = Vector3(0.0, pivot_y, 0.0)
		gimbal.rotation_degrees = Vector3(float(spec[2]), float(spec[4]), float(spec[3]))
		rings.add_child(gimbal)
		# Metal hoop.
		_sl_torus(gimbal, major - tube, major + tube, Vector3.ZERO, hoop_mat, 32, 10)
		# Energy filament threaded inside the hoop — color_b for the hot ring, color_a else.
		var fil_tint: Color = color_b if bool(spec[5]) else color_a
		_sl_torus(gimbal, major - tube * 0.4, major + tube * 0.4, Vector3.ZERO,
			_sl_emissive_mat(fil_tint, 0.9, 3.2), 32, 8)
		# Four gimbal-bracket boxes at cardinal points.
		for k in range(4):
			var ka := (float(k) / 4.0) * TAU
			_sl_box_rot(gimbal, Vector3(0.09, 0.09, 0.13),
				Vector3(cos(ka) * major, 0.0, sin(ka) * major),
				Vector3(0.0, rad_to_deg(ka), 0.0), hoop_mat)
	# Two outer gimbal pivot caps.
	var cap_mat := _tp_metal(c_panel, c_metal_dark_emit, 0.45, 0.9)
	_sl_sphere(rings, 0.1, Vector3(0.86, pivot_y, 0.0), cap_mat, 10, 14)
	_sl_sphere(rings, 0.1, Vector3(-0.86, pivot_y, 0.0), cap_mat, 10, 14)


func _teleporter_gantry(root: Node3D) -> void:
	var gantry := Node3D.new()
	gantry.name = "Gantry"
	root.add_child(gantry)
	var post_h := _TP_PAD_HEIGHT + 0.86
	var c_metal := Color(0.16, 0.18, 0.22)
	var c_metal_emit := Color(0.05, 0.07, 0.11)
	var c_metal_dark := Color(0.10, 0.11, 0.14)
	var c_metal_dark_emit := Color(0.03, 0.05, 0.09)
	var c_panel := Color(0.22, 0.25, 0.30)
	var post_mat := _tp_metal(c_metal, c_metal_emit, 0.5, 0.85)
	var post_x := 0.92
	for sx in [-1.0, 1.0]:
		_sl_box(gantry, Vector3(0.12, post_h, 0.16), Vector3(post_x * sx, post_h * 0.5, 0.0), post_mat)
		var brace_mat := _tp_metal(c_metal_dark, c_metal_dark_emit, 0.55, 0.8)
		_sl_box_rot(gantry, Vector3(0.07, 0.07, 0.55),
			Vector3(post_x * sx * 0.82, 0.28, 0.0), Vector3(40.0, 90.0, 0.0), brace_mat)
		_sl_cyl_rot(gantry, 0.13, 0.13, 0.1, Vector3(post_x * sx, post_h, 0.0),
			Vector3(0.0, 0.0, 90.0), post_mat, 12)
	var cross_mat := _tp_metal(c_panel, c_metal_dark_emit, 0.45, 0.85)
	_sl_box_rot(gantry, Vector3(0.9, 0.08, 0.1), Vector3(0.0, post_h + 0.12, -0.42),
		Vector3(-20.0, 0.0, 0.0), cross_mat)
	# Hazard chevron plate on the crossbar — accent.
	_sl_box_rot(gantry, Vector3(0.5, 0.05, 0.03), Vector3(0.0, post_h + 0.16, -0.40),
		Vector3(-20.0, 0.0, 0.0), _sl_hazard_mat(2))


func _teleporter_consoles(root: Node3D) -> void:
	var consoles := Node3D.new()
	consoles.name = "Consoles"
	root.add_child(consoles)
	var specs: Array = [
		[Vector3(0.78, 0.0, 0.62), -40.0],
		[Vector3(-0.78, 0.0, 0.62), 40.0],
	]
	for spec_v in specs:
		var spec: Array = spec_v
		_teleporter_one_console(consoles, spec[0] as Vector3, float(spec[1]))


func _teleporter_one_console(parent: Node3D, base_pos: Vector3, yaw: float) -> void:
	var node := Node3D.new()
	node.position = base_pos
	node.rotation_degrees = Vector3(0.0, yaw, 0.0)
	parent.add_child(node)
	var body_mat := _tp_metal(Color(0.16, 0.18, 0.22), Color(0.05, 0.07, 0.11), 0.55, 0.8)
	_sl_box(node, Vector3(0.3, 0.5, 0.22), Vector3(0.0, 0.25, 0.0), body_mat)
	_sl_box_rot(node, Vector3(0.34, 0.26, 0.08), Vector3(0.0, 0.6, 0.06), Vector3(-52.0, 0.0, 0.0), body_mat)
	# Glowing screen — color_a.
	_sl_box_rot(node, Vector3(0.26, 0.18, 0.012), Vector3(0.0, 0.605, 0.105),
		Vector3(-52.0, 0.0, 0.0), _sl_emissive_mat(color_a, 1.0, 3.0))
	# Three indicator lights — accent / green ready.
	var ind_colors: Array[Color] = [Color(0.30, 1.0, 0.55), accent, Color(0.30, 1.0, 0.55)]
	for i in range(3):
		var ox := (float(i) - 1.0) * 0.08
		_sl_sphere(node, 0.022, Vector3(ox, 0.42, 0.115), _sl_emissive_mat(ind_colors[i], 1.0, 4.0), 10, 8)
	var clight := OmniLight3D.new()
	clight.name = "ConsoleLight"
	clight.light_color = color_a
	clight.light_energy = _sl_glow_energy(0.9)
	clight.omni_range = 1.0
	clight.position = Vector3(0.0, 0.6, 0.18)
	node.add_child(clight)


func _teleporter_cables(root: Node3D) -> void:
	var cables := Node3D.new()
	cables.name = "Cables"
	root.add_child(cables)
	var cable_mat := _tp_metal(Color(0.07, 0.08, 0.10), Color(0.02, 0.03, 0.04), 0.8, 0.3)
	var endpoints: Array[Vector3] = [
		Vector3(0.78, 0.0, 0.62),
		Vector3(-0.78, 0.0, 0.62),
		Vector3(0.92, 0.0, 0.0),
		Vector3(-0.92, 0.0, 0.0),
	]
	for ep in endpoints:
		_teleporter_cable_arc(cables, Vector3(0.0, 0.06, 0.0), ep, cable_mat, 0.035)
	# Two glowing energy conduits up the back — color_a.
	var glow_cable := _sl_emissive_mat(color_a, 0.95, 2.2)
	_teleporter_cable_arc(cables, Vector3(0.3, 0.06, -0.2), Vector3(0.7, _TP_PAD_HEIGHT + 0.7, -0.3), glow_cable, 0.025)
	_teleporter_cable_arc(cables, Vector3(-0.3, 0.06, -0.2), Vector3(-0.7, _TP_PAD_HEIGHT + 0.7, -0.3), glow_cable, 0.025)


func _teleporter_cable_arc(parent: Node3D, a: Vector3, b: Vector3, mat: Material, radius: float) -> void:
	var segs := 7
	var sag := 0.18 + a.distance_to(b) * 0.12
	var prev := a
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var mid := a.lerp(b, t)
		var droop := sag * (4.0 * t * (1.0 - t))
		var p := Vector3(mid.x, mid.y - droop, mid.z)
		_sl_segment(parent, prev, p, radius, mat, 8)
		prev = p


func _teleporter_fx(root: Node3D) -> void:
	var fx := Node3D.new()
	fx.name = "FX"
	root.add_child(fx)
	var top_y := _TP_PAD_HEIGHT + 0.07
	# Crackling energy arcs from the disc rim toward the rings — color_b.
	var arc_mat := _sl_emissive_mat(color_b, 0.9, 5.0)
	var arc_count := clampi(3 + complexity, 3, 9)
	for i in range(arc_count):
		var ang := (float(i) / float(arc_count)) * TAU + 0.4
		var start := Vector3(cos(ang) * _TP_PAD_RADIUS * 0.5, top_y, sin(ang) * _TP_PAD_RADIUS * 0.5)
		var apex := Vector3(cos(ang) * 0.18, top_y + 0.95, sin(ang) * 0.18)
		_teleporter_jagged_arc(fx, start, apex, arc_mat, ang)
	# Floating motes rising in the column — color_b. Jitter seeded from _rng.
	var mote_mat := _sl_emissive_mat(color_b.lightened(0.1), 0.95, 6.0)
	var mote_count := clampi(10 + complexity * 2, 8, 28)
	for m in range(mote_count):
		var a := _rng.randf() * TAU
		var rr := (0.06 + 0.30 * _rng.randf()) * _TP_PAD_RADIUS
		var hh := top_y + 0.1 + 1.55 * _rng.randf()
		var sz := lerpf(0.012, 0.024, _rng.randf())
		_sl_sphere(fx, sz, Vector3(cos(a) * rr, hh, sin(a) * rr), mote_mat, 8, 6)


func _teleporter_jagged_arc(parent: Node3D, a: Vector3, b: Vector3, mat: Material, seed_ang: float) -> void:
	var steps := 4
	var prev := a
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var base := a.lerp(b, t)
		var jit := 0.07 * sin(seed_ang * 3.0 + float(i) * 2.7)
		var jit2 := 0.07 * cos(seed_ang * 2.0 + float(i) * 1.9)
		var p := base + Vector3(jit, 0.0, jit2)
		if i == steps:
			p = b
		_sl_segment(parent, prev, p, 0.01, mat, 6)
		prev = p


## Oriented tapered BOX spanning a->b (long axis = local Y). Reused for the
## gravgun prongs and the darkreactor claw struts / arcs.
func _sl_box_segment(parent: Node3D, a: Vector3, b: Vector3, w_a: float, w_b: float,
		flatten: float, mat: Material) -> void:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		return
	var y_axis := dir / length
	var ref := Vector3.RIGHT
	if absf(y_axis.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x_axis := ref.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var w := (w_a + w_b) * 0.5
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, length, w * flatten)
	mi.mesh = bm
	mi.material_override = mat
	mi.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5)
	parent.add_child(mi)


# =============================================================================
# MODE: gravgun — zero-point energy field manipulator (hllab trial v3)
# =============================================================================
# DNA mapping: color_a = the glowing core cradled in the prongs (gun energy);
# color_b = the inner nucleus / supercharged tint blended into the core; accent =
# the worn industrial amber trim + bench hazard label + status strip. The gun
# rests nose-up in a lab cradle on a small bench, prongs splayed toward +Z.

const _GG_AXIS_Y: float = 0.92


func _build_gravgun() -> void:
	var w := maxf(sculpt_width, 0.2)
	# Native rig is ~1.5 m tall; scale vertically.
	var vscale := maxf(sculpt_height, 0.4) / 1.5

	var root := Node3D.new()
	root.name = "GravGun"
	add_child(root)
	root.scale = Vector3(w, vscale, w)

	# Core colour is color_a, with a touch of color_b mixed into the nucleus.
	var core_col := color_a
	_gravgun_bench(root, core_col)
	_gravgun_gun(root, core_col)


## Dark industrial metal with a faint emission FLOOR of its own tint (trial used
## emission = base * 0.18 * boost).
func _gg_metal(base: Color, rough: float, metal: float, emit_boost: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = base
	m.roughness = clampf(rough, 0.0, 1.0)
	m.metallic = clampf(metal, 0.0, 1.0)
	m.emission_enabled = true
	m.emission = base * (0.18 * emit_boost)
	m.emission_energy_multiplier = 1.0
	return m


func _gravgun_bench(root: Node3D, core_col: Color) -> void:
	var bench := Node3D.new()
	bench.name = "BenchCradle"
	root.add_child(bench)
	var metal_mid := Color(0.16, 0.17, 0.19)
	var mat_bench := _gg_metal(Color(0.14, 0.145, 0.16), 0.85, 0.3)
	var mat_frame := _gg_metal(metal_mid, 0.55, 0.85)
	var mat_rubber := _gg_metal(Color(0.05, 0.05, 0.06), 0.95, 0.05, 1.4)
	# Bench top + rim lip.
	_sl_box(bench, Vector3(0.92, 0.07, 0.66), Vector3(0.0, 0.16, 0.0), mat_bench)
	_sl_box(bench, Vector3(0.98, 0.02, 0.72), Vector3(0.0, 0.205, 0.0), _gg_metal(metal_mid, 0.5, 0.9))
	# Four feet.
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_sl_cylinder(bench, 0.045, 0.045, 0.13, Vector3(sx * 0.40, 0.065, sz * 0.27), mat_rubber, 14)
	# Two arched supports cradling the gun.
	var post_y0 := 0.20
	var saddle_y := _GG_AXIS_Y - 0.085
	for side_z in [-0.20, 0.20]:
		var grp := Node3D.new()
		bench.add_child(grp)
		for px in [-0.16, 0.16]:
			var post_h := saddle_y - post_y0
			_sl_box(grp, Vector3(0.06, post_h, 0.06), Vector3(px, post_y0 + post_h * 0.5, side_z), mat_frame)
		_sl_box(grp, Vector3(0.40, 0.05, 0.10), Vector3(0.0, saddle_y, side_z), mat_frame)
		_sl_box_rot(grp, Vector3(0.12, 0.035, 0.10), Vector3(-0.085, saddle_y + 0.045, side_z),
			Vector3(0, 0, 20), mat_rubber)
		_sl_box_rot(grp, Vector3(0.12, 0.035, 0.10), Vector3(0.085, saddle_y + 0.045, side_z),
			Vector3(0, 0, -20), mat_rubber)
	# Hazard label panel on the bench front — accent background + black stripes.
	_sl_box(bench, Vector3(0.30, 0.13, 0.012),
		Vector3(0.30, 0.135, 0.345), _gg_metal(accent, 0.6, 0.2, 1.8))
	for i in range(4):
		var sx := -0.11 + float(i) * 0.073
		_sl_box_rot(bench, Vector3(0.026, 0.115, 0.004),
			Vector3(0.30 + sx, 0.135, 0.353), Vector3(0, 0, 28),
			_gg_metal(Color(0.04, 0.04, 0.04), 0.7, 0.0, 1.0))
	# Status light strip — color_a.
	_sl_box(bench, Vector3(0.16, 0.02, 0.02), Vector3(-0.30, 0.205, 0.30),
		_sl_emissive_mat(core_col, 1.0, 3.0))


func _gravgun_gun(root: Node3D, core_col: Color) -> void:
	var gun := Node3D.new()
	gun.name = "GravityGun"
	gun.position = Vector3(0.0, _GG_AXIS_Y, -0.04)
	gun.rotation_degrees = Vector3(-8.0, 13.0, 0.0)
	root.add_child(gun)
	var metal_dark := Color(0.10, 0.105, 0.12)
	var metal_mid := Color(0.16, 0.17, 0.19)
	var mat_body := _gg_metal(metal_dark, 0.55, 0.8, 1.1)
	var mat_body2 := _gg_metal(metal_mid, 0.45, 0.85, 1.0)
	var mat_accent := _gg_metal(accent, 0.4, 0.7, 1.3)
	var mat_grip := _gg_metal(Color(0.07, 0.07, 0.08), 0.9, 0.15, 1.2)
	var mat_dark := _gg_metal(Color(0.06, 0.06, 0.07), 0.7, 0.6, 1.0)
	# Main housing.
	_sl_box(gun, Vector3(0.20, 0.20, 0.26), Vector3(0, 0.0, -0.18), mat_body)
	_sl_box(gun, Vector3(0.16, 0.05, 0.24), Vector3(0, 0.11, -0.18), mat_body2)
	_sl_box(gun, Vector3(0.165, 0.165, 0.22), Vector3(0, 0.0, 0.02), mat_body2)
	for sx in [-1.0, 1.0]:
		_sl_box(gun, Vector3(0.018, 0.15, 0.40), Vector3(sx * 0.095, 0.0, -0.06), mat_accent)
	# Front collar + muzzle ring.
	_sl_cyl_rot(gun, 0.105, 0.105, 0.10, Vector3(0, 0, 0.18), Vector3(90, 0, 0), mat_dark, 20)
	_sl_torus_rot(gun, 0.075, 0.105, Vector3(0, 0, 0.235), Vector3(90, 0, 0), mat_accent, 24, 12)
	# Panel-line grooves on the top.
	for gz in [-0.24, -0.12, 0.0]:
		_sl_box(gun, Vector3(0.14, 0.012, 0.012), Vector3(0, 0.101, gz), mat_dark)
	# Glowing energy coil rings wrapping the mid barrel — color_a.
	for cz in [-0.02, 0.06]:
		_sl_torus_rot(gun, 0.072, 0.092, Vector3(0, 0, cz), Vector3(90, 0, 0),
			_sl_emissive_mat(core_col, 1.0, 2.6), 24, 12)
	# Vent slots on top, glowing faintly — color_a.
	for vi in range(3):
		_sl_box(gun, Vector3(0.10, 0.006, 0.018), Vector3(0, 0.122, -0.26 + float(vi) * 0.05),
			_sl_emissive_mat(core_col, 1.0, 1.6))
	# Pistol grip + butt + trigger guard + trigger.
	_sl_box_rot(gun, Vector3(0.085, 0.26, 0.10), Vector3(0, -0.20, -0.16), Vector3(16, 0, 0), mat_grip)
	_sl_box_rot(gun, Vector3(0.10, 0.04, 0.12), Vector3(0, -0.325, -0.20), Vector3(16, 0, 0), mat_dark)
	_sl_torus(gun, 0.045, 0.062, Vector3(0, -0.115, -0.05), mat_dark, 24, 12)
	_sl_box_rot(gun, Vector3(0.02, 0.06, 0.02), Vector3(0, -0.12, -0.06), Vector3(20, 0, 0), mat_accent)
	# Rear indicator lights.
	_sl_sphere(gun, 0.018, Vector3(0.07, 0.07, -0.30), _sl_emissive_mat(Color(0.2, 1.0, 0.35), 1.0, 5.0), 12, 14)
	_sl_sphere(gun, 0.014, Vector3(0.07, 0.04, -0.30), _sl_emissive_mat(Color(1.0, 0.25, 0.2), 1.0, 4.0), 10, 12)
	# Cables looping along the body.
	_gravgun_cable(gun, Vector3(-0.10, 0.06, -0.28), Vector3(-0.13, -0.02, 0.14), -1.0, mat_dark)
	_gravgun_cable(gun, Vector3(0.10, 0.02, -0.26), Vector3(0.12, -0.04, 0.10), 1.0,
		_gg_metal(Color(0.5, 0.30, 0.05), 0.7, 0.3, 1.2))
	# The front: prongs + core.
	_gravgun_prongs_and_core(gun, core_col)


func _gravgun_cable(parent: Node3D, a: Vector3, b: Vector3, side: float, mat: Material) -> void:
	var segs := 9
	var sag := 0.10
	var prev := a
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var p := a.lerp(b, t)
		p.x += side * 0.05 * sin(t * PI)
		p.y -= sag * (4.0 * t * (1.0 - t))
		_sl_segment(parent, prev, p, 0.012, mat, 8)
		prev = p


func _gravgun_prongs_and_core(gun: Node3D, core_col: Color) -> void:
	var front := Node3D.new()
	front.name = "ProngHead"
	front.position = Vector3(0, 0, 0.27)
	gun.add_child(front)
	# The glowing CORE cradled between the prongs — color_a glass-core.
	var core_mat := _sl_emissive_mat(core_col, 1.0, 4.6)
	core_mat.roughness = 0.12
	core_mat.rim_enabled = true
	core_mat.rim = 0.8
	var core_r := 0.072
	_sl_sphere(front, core_r, Vector3(0, 0, 0.10), core_mat, 18, 28)
	# Inner brighter nucleus — white blended toward color_b.
	_sl_sphere(front, core_r * 0.55, Vector3(0, 0, 0.10),
		_sl_emissive_mat(Color(1, 1, 1).lerp(color_b, 0.45), 1.0, 7.0), 14, 20)
	# Faint containment halo ring — color_a.
	_sl_torus_rot(front, core_r * 1.05, core_r * 1.35, Vector3(0, 0, 0.10), Vector3(90, 0, 0),
		_sl_emissive_mat(core_col, 1.0, 1.4), 24, 12)
	# OmniLight at the core — color_a.
	var light := OmniLight3D.new()
	light.name = "CoreLight"
	light.light_color = core_col
	light.light_energy = _sl_glow_energy(4.2)
	light.omni_range = 2.6
	light.omni_attenuation = 1.4
	light.position = Vector3(0, 0, 0.10)
	front.add_child(light)
	# Three splayed curved prongs opening forward.
	var prong_angles: Array[float] = [90.0, 210.0, 330.0]
	var mat_prong := _gg_metal(Color(0.12, 0.125, 0.14), 0.5, 0.85, 1.15)
	var mat_prong_tip := _gg_metal(Color(0.16, 0.17, 0.19), 0.4, 0.9, 1.2)
	for ang_deg in prong_angles:
		var ang := deg_to_rad(ang_deg)
		_gravgun_one_prong(front, Vector3(cos(ang), sin(ang), 0.0), mat_prong, mat_prong_tip, core_col)
	# Energy arcs between each prong tip and the core — color_a.
	for ang_deg in prong_angles:
		var ang := deg_to_rad(ang_deg)
		var radial := Vector3(cos(ang), sin(ang), 0.0)
		var tip := radial * 0.092 + Vector3(0, 0, 0.275)
		_gravgun_arc(front, tip, Vector3(0, 0, 0.10), radial, core_col)


func _gravgun_one_prong(parent: Node3D, radial: Vector3, mat: Material, mat_tip: Material, core_col: Color) -> void:
	var grp := Node3D.new()
	parent.add_child(grp)
	var steps := 8
	var prev_p := radial * 0.060 + Vector3(0, 0, -0.02)
	var max_spread := 0.135
	for i in range(1, steps + 1):
		var t := float(i) / float(steps)
		var z := lerpf(-0.02, 0.30, t)
		var spread := sin(t * PI * 0.70) * max_spread + 0.058
		if t > 0.78:
			spread = lerpf(spread, 0.090, (t - 0.78) / 0.22)
		var p := radial * spread + Vector3(0, 0, z)
		var thick_a := lerpf(0.055, 0.024, float(i - 1) / float(steps))
		var thick_b := lerpf(0.055, 0.024, t)
		var m: Material = mat_tip if t > 0.7 else mat
		_sl_box_segment(grp, prev_p, p, thick_a, thick_b, 1.0, m)
		prev_p = p
	# Glowing emitter notch at the prong tip — color_a.
	var tip_pos := radial * 0.092 + Vector3(0, 0, 0.275)
	_sl_sphere(grp, 0.020, tip_pos, _sl_emissive_mat(core_col, 1.0, 5.5), 10, 12)
	# Emissive inner rail along the prong's inward face.
	_sl_box(grp, Vector3(0.010, 0.010, 0.20), radial * 0.060 + Vector3(0, 0, 0.13),
		_sl_emissive_mat(core_col, 1.0, 2.2))


func _gravgun_arc(parent: Node3D, from_p: Vector3, to_p: Vector3, radial: Vector3, col: Color) -> void:
	var mat := _sl_emissive_mat(Color(1, 1, 1).lerp(col, 0.55), 1.0, 6.0)
	var segs := 5
	var axis := (to_p - from_p).normalized()
	var perp := axis.cross(radial).normalized()
	if perp.length() < 0.01:
		perp = Vector3(0, 1, 0)
	var prev := from_p
	for i in range(1, segs + 1):
		var t := float(i) / float(segs)
		var p := from_p.lerp(to_p, t)
		var sign_w := 1.0 if (i % 2 == 0) else -1.0
		p += perp * sign_w * (0.018 * sin(t * PI))
		_sl_segment(parent, prev, p, 0.004, mat, 6)
		prev = p


# =============================================================================
# MODE: darkreactor — Combine dark-energy column in claw struts (hllab trial v4)
# =============================================================================
# DNA mapping: color_a = the brilliant captured-energy column (core + nodes +
# crown); color_b = the Combine armour tint blended into the dark plate + the
# cold rim sheen; accent = the glowing seams + arcs + harsh indicators. A tall
# energy column on an armoured octagonal base, caged in angular claw struts that
# curve inward to grip it.

# Combine palette anchors (color_b shifts the armour; color_a drives the energy).
const _DR_ENERGY_DEEP: Color = Color(0.22, 0.55, 1.0)


func _build_darkreactor() -> void:
	var w := maxf(sculpt_width, 0.2)
	# Native rig is ~2.1 m tall; scale vertically.
	var vscale := maxf(sculpt_height, 0.4) / 2.1

	var root := Node3D.new()
	root.name = "DarkReactor"
	add_child(root)
	root.scale = Vector3(w, vscale, w)

	_darkreactor_base(root)
	_darkreactor_column(root)
	_darkreactor_struts(root)
	_darkreactor_nodes(root)
	_darkreactor_arcs(root)
	_darkreactor_lights(root)


## Dark Combine armour: metal with a faint emission floor + cold rim. The base
## plate tint is nudged toward color_b so the armour re-registers per palette.
func _dr_armour(facet_light: float = 0.0) -> StandardMaterial3D:
	var armour_dark := Color(0.085, 0.105, 0.135).lerp(color_b.darkened(0.55), 0.35)
	var armour_mid := Color(0.135, 0.165, 0.205).lerp(color_b.darkened(0.35), 0.35)
	var armour_emit := Color(0.045, 0.075, 0.115)
	var rim_cold := Color(0.18, 0.34, 0.55).lerp(color_b, 0.3)
	var m := StandardMaterial3D.new()
	m.albedo_color = armour_dark.lerp(armour_mid, clampf(facet_light, 0.0, 1.0))
	m.metallic = clampf(metallic_amt * 0.96, 0.0, 1.0)
	m.roughness = 0.42
	m.emission_enabled = true
	m.emission = armour_emit.lerp(rim_cold, 0.25)
	m.emission_energy_multiplier = _sl_glow_energy(0.55 + facet_light * 0.25)
	m.rim_enabled = true
	m.rim = 0.6
	m.rim_tint = 0.7
	return m


## Brilliant captured-energy emissive (column / nodes / crown). color_a-driven.
func _dr_energy(col: Color, energy: float) -> StandardMaterial3D:
	return _sl_emissive_mat(col, 1.0, energy)


## Soft additive halo shell (cold energy glow). color_a deep-shade by default.
func _dr_halo(col: Color, energy: float, alpha: float) -> StandardMaterial3D:
	return _sl_flame_mat(col, alpha, energy)


## Thin glowing seam material between armour plates — accent.
func _dr_seam() -> StandardMaterial3D:
	return _sl_emissive_mat(accent, 1.0, 4.5)


func _darkreactor_base(root: Node3D) -> void:
	var base_root := Node3D.new()
	base_root.name = "Base"
	root.add_child(base_root)
	var dark := _dr_armour(0.0)
	var mid := _dr_armour(1.0)
	var seam_blue := accent
	var energy_core := color_a.lightened(0.35)
	# Octagonal feel via stacked rotated foot slabs.
	_sl_box(base_root, Vector3(1.30, 0.10, 1.30), Vector3(0, 0.05, 0), dark)
	_sl_box_rot(base_root, Vector3(1.05, 0.12, 1.05), Vector3(0, 0.11, 0), Vector3(0, 45, 0), mid)
	# Angular tapered plinth drum (8 sides) + bevel cap.
	_sl_cylinder(base_root, 0.42, 0.55, 0.34, Vector3(0, 0.30, 0), dark, 8)
	_sl_cylinder(base_root, 0.40, 0.46, 0.07, Vector3(0, 0.50, 0), mid, 8)
	# Angular armour panels around the plinth, each with a glowing seam.
	var panel_count := clampi(4 + complexity, 6, 10)
	for i in range(panel_count):
		var ang := TAU * float(i) / float(panel_count)
		var r := 0.46
		var deg := rad_to_deg(ang)
		var panel := _sl_box_rot(base_root, Vector3(0.20, 0.30, 0.07),
			Vector3(cos(ang) * r, 0.30, sin(ang) * r), Vector3(8, -deg + 90.0, 0), dark)
		_sl_box(panel, Vector3(0.02, 0.26, 0.012), Vector3(0, 0, 0.045), _dr_seam())
	# Conduits feeding the column.
	for i in range(3):
		var ang := TAU * float(i) / 3.0 + deg_to_rad(60.0)
		var r := 0.30
		var px := cos(ang) * r
		var pz := sin(ang) * r
		_sl_cyl_rot(base_root, 0.045, 0.055, 0.55, Vector3(px, 0.62, pz), Vector3(10, 0, 0), mid, 10)
		_sl_cylinder(base_root, 0.052, 0.052, 0.04, Vector3(px, 0.78, pz),
			_sl_emissive_mat(seam_blue, 1.0, 4.0), 10)
	# Harsh indicator lights in the cap ring — accent.
	for i in range(4):
		var ang := TAU * float(i) / 4.0 + deg_to_rad(45.0)
		var r := 0.39
		_sl_sphere(base_root, 0.028, Vector3(cos(ang) * r, 0.52, sin(ang) * r),
			_sl_emissive_mat(accent.lerp(Color(0.45, 0.78, 1.0), 0.4), 1.0, 5.5), 16, 8)
	# Energy ring at the base of the column — color_a.
	_sl_cylinder(base_root, 0.26, 0.26, 0.018, Vector3(0, 0.555, 0), _dr_halo(_dr_energy_deep(), 3.2, 0.55), 32)
	_sl_cylinder(base_root, 0.16, 0.16, 0.012, Vector3(0, 0.56, 0), _dr_energy(energy_core, 3.0), 24)


## color_a-tinted cold deep-energy halo colour.
func _dr_energy_deep() -> Color:
	return color_a.lerp(_DR_ENERGY_DEEP, 0.45)


func _darkreactor_column(root: Node3D) -> void:
	var col_root := Node3D.new()
	col_root.name = "EnergyColumn"
	root.add_child(col_root)
	var col_base_y := 0.56
	var col_top_y := 2.02
	var col_h := col_top_y - col_base_y
	var col_mid_y := (col_base_y + col_top_y) * 0.5
	var energy_core := color_a.lightened(0.35)
	# Bright inner core column — color_a.
	_sl_cylinder(col_root, 0.055, 0.07, col_h, Vector3(0, col_mid_y, 0), _dr_energy(energy_core, 6.0), 16)
	# Stacked energy "knuckle" nodes climbing the column.
	var node_count := clampi(4 + complexity / 2, 4, 9)
	for i in range(node_count):
		var t := float(i) / float(maxi(node_count - 1, 1))
		var y := lerpf(col_base_y + 0.10, col_top_y - 0.10, t)
		var rad := lerpf(0.11, 0.075, t)
		var n := _sl_sphere(col_root, rad, Vector3(0, y, 0), _dr_energy(energy_core, 5.0), 16, 8)
		n.scale = Vector3(1.0, 0.62, 1.0)
		var halo := _sl_sphere(col_root, rad * 1.7, Vector3(0, y, 0), _dr_halo(_dr_energy_deep(), 2.4, 0.32), 16, 8)
		halo.scale = Vector3(1.0, 0.7, 1.0)
	# Outer soft glow shell down the whole column — color_a deep.
	_sl_cylinder(col_root, 0.13, 0.16, col_h, Vector3(0, col_mid_y, 0), _dr_halo(_dr_energy_deep(), 1.8, 0.22), 18)
	# Bright crown at the very top.
	_sl_sphere(col_root, 0.072, Vector3(0, col_top_y, 0), _dr_energy(energy_core, 7.0), 16, 8)
	_sl_sphere(col_root, 0.115, Vector3(0, col_top_y, 0), _dr_halo(_dr_energy_deep(), 2.4, 0.26), 16, 8)


func _darkreactor_struts(root: Node3D) -> void:
	var cage := Node3D.new()
	cage.name = "ContainmentCage"
	root.add_child(cage)
	var dark := _dr_armour(0.0)
	var mid := _dr_armour(0.65)
	# 5 struts — asymmetric-but-deliberate (deterministic per index).
	var angles: Array[float] = [10.0, 82.0, 150.0, 214.0, 290.0]
	var len_scales: Array[float] = [1.0, 0.86, 1.12, 0.92, 1.04]
	var n_struts := clampi(3 + complexity, 5, angles.size())
	for i in range(n_struts):
		_darkreactor_one_strut(cage, angles[i], len_scales[i], dark, mid, i)
	# Upper binding ring — angular octagon clasp squeezing the column near the top.
	var ring_y := 1.84
	var clasp_count := 8
	for i in range(clasp_count):
		var ang := TAU * float(i) / float(clasp_count)
		var r := 0.18
		var deg := rad_to_deg(ang)
		_sl_box_rot(cage, Vector3(0.10, 0.05, 0.04),
			Vector3(cos(ang) * r, ring_y, sin(ang) * r), Vector3(0, -deg + 90.0, 0), mid)


func _darkreactor_one_strut(parent: Node3D, base_angle_deg: float, length_scale: float,
		mat_dark: Material, mat_mid: Material, idx: int) -> void:
	var strut := Node3D.new()
	strut.name = "Strut%d" % idx
	strut.rotation_degrees = Vector3(0, base_angle_deg, 0)
	parent.add_child(strut)
	var foot_r := 0.50
	# Anchor foot.
	_sl_box_rot(strut, Vector3(0.16, 0.14, 0.16), Vector3(0.0, 0.50, foot_r), Vector3(-22, 0, 0), mat_mid)
	# Claw path: foot -> knee(out) -> elbow(in) -> tip(grips near core).
	var p0 := Vector3(0.0, 0.55, foot_r)
	var p1 := Vector3(0.0, 0.95, foot_r + 0.10 * length_scale)
	var p2 := Vector3(0.0, 1.45, foot_r - 0.14 * length_scale)
	var p3 := Vector3(0.0, 1.86, 0.16)
	var seg_pts: Array[Vector3] = [p0, p1, p2, p3]
	var seg_w: Array[float] = [0.135, 0.115, 0.085, 0.06]
	for s in range(3):
		var a := seg_pts[s]
		var b := seg_pts[s + 1]
		_sl_box_segment(strut, a, b, seg_w[s], seg_w[s + 1], 0.78, mat_dark)
		# Glowing seam ridge along the segment — accent.
		_darkreactor_seam_segment(strut, a, b)
	# Claw tip pincer + blue glow where it touches the energy.
	_sl_box_rot(strut, Vector3(0.10, 0.10, 0.14), p3 + Vector3(0, 0.02, -0.02), Vector3(40, 0, 0), mat_mid)
	_sl_sphere(strut, 0.035, p3 + Vector3(0, 0.0, -0.05), _sl_emissive_mat(accent, 1.0, 5.0), 16, 8)
	# Knee armour plate on the outer bend.
	_sl_box_rot(strut, Vector3(0.22, 0.20, 0.05), p1 + Vector3(0, 0.0, 0.07), Vector3(18, 0, 0), mat_dark)


## Thin glowing seam riding along the outer face of a claw segment — accent.
func _darkreactor_seam_segment(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		return
	var y_axis := dir / length
	var ref := Vector3.RIGHT
	if absf(y_axis.dot(ref)) > 0.95:
		ref = Vector3.FORWARD
	var x_axis := ref.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.012, length * 0.86, 0.012)
	mi.mesh = bm
	mi.material_override = _dr_seam()
	mi.transform = Transform3D(Basis(x_axis, y_axis, z_axis), (a + b) * 0.5 + z_axis * 0.05)
	parent.add_child(mi)


func _darkreactor_nodes(root: Node3D) -> void:
	var orb := Node3D.new()
	orb.name = "FloatingNodes"
	root.add_child(orb)
	var energy_core := color_a.lightened(0.35)
	# Captured-energy motes suspended around the core. Base set is deterministic;
	# count scales with complexity, positions jittered from _rng for sibling reseeds.
	var data: Array = [
		[0.24, 0.85, 30.0],
		[0.27, 1.25, 165.0],
		[0.22, 1.60, 255.0],
		[0.30, 1.05, 300.0],
		[0.20, 1.45, 95.0],
	]
	var n := clampi(3 + complexity / 2, 4, data.size())
	for i in range(n):
		var entry: Array = data[i]
		var r: float = float(entry[0]) + _rng.randf_range(-0.02, 0.02)
		var y: float = float(entry[1]) + _rng.randf_range(-0.04, 0.04)
		var ang: float = deg_to_rad(float(entry[2]))
		var px := cos(ang) * r
		var pz := sin(ang) * r
		_sl_sphere(orb, 0.022, Vector3(px, y, pz), _dr_energy(energy_core, 5.5), 16, 8)
		_sl_sphere(orb, 0.045, Vector3(px, y, pz), _dr_halo(_dr_energy_deep(), 2.2, 0.30), 16, 8)


func _darkreactor_arcs(root: Node3D) -> void:
	var arcs := Node3D.new()
	arcs.name = "EnergyArcs"
	root.add_child(arcs)
	# Thin jagged emissive filaments spiralling up the core (fake lightning) — accent.
	var arc_mat := _sl_emissive_mat(accent, 1.0, 5.5)
	var col_base_y := 0.60
	var col_top_y := 1.98
	var arc_count := clampi(2 + complexity / 2, 3, 6)
	var steps := 10
	for a in range(arc_count):
		var phase := TAU * float(a) / float(arc_count)
		var prev := Vector3.ZERO
		var have_prev := false
		for s in range(steps + 1):
			var t := float(s) / float(steps)
			var y := lerpf(col_base_y, col_top_y, t)
			var wob := 0.085 + 0.035 * sin(t * 9.0 + phase)
			var theta := phase + t * TAU * 1.4
			var pt := Vector3(cos(theta) * wob, y, sin(theta) * wob)
			if have_prev:
				_sl_box_segment(arcs, prev, pt, 0.010, 0.010, 1.0, arc_mat)
			prev = pt
			have_prev = true


func _darkreactor_lights(root: Node3D) -> void:
	# Hero omni: cold blue-white energy light from the column core — color_a.
	var core_light := OmniLight3D.new()
	core_light.name = "CoreLight"
	core_light.position = Vector3(0, 1.35, 0)
	core_light.light_color = color_a.lightened(0.2)
	core_light.light_energy = _sl_glow_energy(4.2)
	core_light.omni_range = 4.5
	core_light.omni_attenuation = 1.4
	root.add_child(core_light)
	# Secondary fill from the base ring.
	var base_light := OmniLight3D.new()
	base_light.name = "BaseLight"
	base_light.position = Vector3(0, 0.58, 0)
	base_light.light_color = _dr_energy_deep()
	base_light.light_energy = _sl_glow_energy(1.8)
	base_light.omni_range = 1.8
	base_light.omni_attenuation = 1.8
	root.add_child(base_light)
	# Top crown light.
	var top_light := OmniLight3D.new()
	top_light.name = "TopLight"
	top_light.position = Vector3(0, 2.0, 0)
	top_light.light_color = color_a.lightened(0.35)
	top_light.light_energy = _sl_glow_energy(2.0)
	top_light.omni_range = 1.4
	root.add_child(top_light)
