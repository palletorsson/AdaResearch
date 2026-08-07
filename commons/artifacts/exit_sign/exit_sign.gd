extends Node3D
class_name ExitSign

const BakedText := preload("res://commons/utils/baked_text_albedo.gd")
const PBR := preload("res://commons/render/pbr_kit.gd")

# @identity
# essence: a wall-mounted illuminated EXIT sign — Portal 2 / Half-Life vocabulary. A small emissive rectangle that names a way out and points at it. The cheapest, most legible piece of architectural narrative the room can hold.
# desire: every lab/chamber that has an exit gets a sign that SAYS so — readable from across the room, glowing enough to be a beacon, small enough to be ambient
# critical_parameter: sign_color — green = safe egress (the standard), red = warning/alarm exit, accent-color tint = "this exit belongs to THIS phase". The text stays white.
# triggers: _ready() builds the body, text, and arrow from exports; rebuilds on apply_grid_config
# emerges: same script, four signs — green "EXIT →", red "EMERGENCY ↓", phase-tinted "λ-S LAB ←", contextual "RETURN ↑"
# needs: emissive material with high glow_energy [present]; baked text quads painted onto the sign face [present]; arrow glyph baked as unshaded quad [present]; a HOUSING that is not the light — moulded shell, painted-steel bezel, and the green the lens throws back onto both [present]
# relationships: sibling to lab_room (a chamber with no exit sign is a sealed room — the sign is the seal's release valve); peer to sliding_door (the sign names the door); descendant of the Half-Life test-chamber visual vocabulary the lab_room inherits from
# truth: a sign is not the way out. The sign is the PROMISE that there IS a way out. A room without an exit sign is a trap. A room with one is a stage.

## A wall-mounted illuminated EXIT sign with optional directional arrow.
##
## Built procedurally from DNA exports — no .tres dependencies. The sign
## faces +Z by default (mount on a -Z wall and the player will see it
## as they look into the room). Re-orient the parent transform to mount
## on other walls.
##
## ── THE FINISH (material pass, 2026-08-07) ────────────────────────────
##
## The sign shipped as ONE box that glowed on all six faces: sides, back and
## front the same emerald, one albedo, one roughness, one metallic. A render
## lint measured it flat, and it is flat — the object had no housing at all,
## only light shaped like a brick.
##
## What changed is NOT the light. glow_energy is passed through untouched and
## no emission was raised anywhere: the glowing face is already the brightest
## thing in any room this sign hangs in, and this corpus runs with bloom off
## precisely because lit things here fatten past their own silhouette. The
## work went into the three surfaces that were never there:
##
##   Shell   the back box. Moulded ABS, satin, barely worn — it lives against
##           a wall. Inset 4 mm per side so the bezel laps over it and throws
##           a shadow line down the join.
##   Bezel   painted steel, dark, chamfered. The ring around the light, and
##           the reason the green reads as bright: it has something dull to be
##           bright against. Its chamfer is 5 mm on purpose — see below.
##   Lens    the acrylic diffuser. It still glows at exactly the shipped
##           energy, but it is now a PLASTIC that glows: clear coat, fine
##           roughness break-up, a specular that moves when you do, and an
##           albedo dropped under the emission so scene light cannot clip the
##           panel to white and take its colour away.
##
## Plus one shadowless, distance-faded omni at the lens (`spill`), because a
## lamp that lights nothing is a sticker. It is what puts a gradient across
## the bezel and the bracket instead of a flat ambient wash.
##
## ── GRAIN SCALE, WHICH IS THE WHOLE GAME ──────────────────────────────
##
## The sign body is 0.45 x 0.18 x 0.06 m; with the gantry it stands about
## 0.63 m tall. Framed for a 760 px capture that is roughly 1200 px per metre
## (840 for the gantry). PbrKit's triplanar scale is texture tiles per metre
## of local space, and GRAIN_MICRO's dominant blob is about 1/24 of a tile, so
##
##     blob_px  =  (px_per_m / tiles_per_m) / 24
##
## At the kit's own defaults (hard_plastic 5, painted_metal 3) that lands the
## blob at 10-16 px — soft mottling, which reads as dirt on a part this small,
## not as moulded plastic. At the docstring's rule of thumb (1 / longest = 2.2
## as a multiplier) it lands near 4.5 px, which is legible but thin. This file
## picks GRAIN_TILES_PER_M = 8.0 for EVERY surface, which puts the blob at
## about 6 px on the body and 4.3 px on the gantry — a feature several pixels
## wide, which is the rule that matters. One tile is then 0.125 m, so roughly
## three and a half grain periods span the sign: a surface, not static.
##
## The same arithmetic is why brushed_metal appears nowhere here. Its brush is
## a 40x stretch along one axis; on parts this small that puts the streaks at
## a fraction of a pixel and the result is television static, not steel. The
## rods use machined_metal, which is isotropic, and they read as drawn stock.
##
## And it is why the bezel's chamfer is 5 mm rather than the kit's automatic
## 1 mm: PbrKit.box() derives its bevel from the box's SMALLEST dimension, and
## an 18 mm bezel gets a 1 mm chamfer — about one pixel, i.e. invisible. Same
## lesson, in geometry instead of texture.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Text")
@export var text: String = "EXIT"
## "left", "right", "down", "up", "none". Default "none" — just the word EXIT.
@export var arrow_direction: String = "none"

@export_group("Color")
## Default emerald green — the international emergency-egress standard.
@export var sign_color: Color = Color(0.20, 0.80, 0.30)
@export var text_color: Color = Color(1.0, 1.0, 1.0)

@export_group("Dimensions")
@export var width: float = 0.45
@export var height: float = 0.18
## Sign body depth — how thick the box is (a solid sign, not a sticker).
@export var thickness: float = 0.06
## How far the sign protrudes from the wall it mounts to.
@export var mount_offset_z: float = 0.02

@export_group("Emission")
@export var glow_energy: float = 1.5
## Light the sign throws back onto its own bezel and the wall around it, as a
## fraction of glow_energy. ONE OmniLight3D, shadows off, distance-faded past
## 7 m — a sign that lights nothing is a decal, and the bezel is the surface
## that proves it is a lamp. Set 0 in a room that is already light-bound.
## This does NOT touch glow_energy: the face is bright enough already.
@export var spill: float = 0.55

# ── Stage-2 DNA: support ──────────────────────────────────────────────
#
# `support` is the project's one word for "what apparatus holds this object up",
# reused VERBATIM here from science_screen / info_board / the fire pieces. The
# canonical vocabulary is eight lowercase nouns:
#
#   none | bracket | stand | cradle | frame | gantry | cabinet | pylon
#
# What never varies about this sign is that it is UNATTACHED. Colour and text are
# already the room's business and already differ per map; what all 40 placements
# share is a glowing rectangle hovering 2 cm off a wall with no fixing of any kind,
# which is why it reads as a decal rather than as building fabric. That is exactly
# the shared `support` question, so it is asked with the shared word.
#
# FOUR of the eight are declared, and they are the four a 0.45 m body can build
# without one degrading into a twin of its neighbour:
#
#   none     the emissive box alone — the pre-promotion look, zero nodes added
#   bracket  a small back plate on the wall plane with two arms out to the sign
#   frame    a dark bezel around all four edges, sign recessed into it, back panel
#   gantry   two rods up from the top edge to a plate overhead — the sign HANGS
#
# stand / cradle / cabinet / pylon are deliberately NOT declared and NOT silently
# degraded. They are architecture — a floor member, a base, a body of cabinetwork,
# a slab of building — and a sign this small cannot make an honest claim to any of
# them. See `refusal` in the promotion record.
@export_group("Support")
## What apparatus holds this sign up. `none` is the shipped look exactly (zero
## extra nodes); the other three add real, differently-shaped hardware. Worth
## varying because the sign's one constant flaw across 40 rooms is that nothing
## holds it and nothing says where the wall is.
@export_enum("none", "bracket", "frame", "gantry") var support: String = "none"

## Allow-list for the axis. Anything outside it is a typo and falls back.
const SUPPORTS: PackedStringArray = ["none", "bracket", "frame", "gantry"]

# Hardware proportions, all in metres. Named constants so a reader can check them
# against the spec without counting literals inside the build.
const BRACKET_PLATE: Vector3 = Vector3(0.14, 0.20, 0.006)  ## back plate on the wall plane
const BRACKET_ARM: float = 0.02                            ## square section of each arm
const BRACKET_ARM_Y: float = 0.055                         ## arms sit above/below centre
const FRAME_SECTION: float = 0.025                         ## bezel bar, face-on width
const FRAME_RECESS: float = 0.01                           ## how far the body sits behind the bezel face
const FRAME_PANEL_D: float = 0.006                         ## back panel thickness
const GANTRY_ROD_D: float = 0.008                          ## rod diameter
const GANTRY_RISE: float = 0.45                            ## rod length above the sign's top edge
const GANTRY_ROD_X: float = 0.10                           ## rods either side of centre
const GANTRY_PLATE: Vector3 = Vector3(0.30, 0.06, 0.02)    ## the plate the load comes from

# ── Finish constants ──────────────────────────────────────────────────

## Texture tiles per metre of local space, for EVERY surface on this sign.
##
## One number for the whole artifact is not a shortcut, it is the point: shell,
## bezel, bracket plate and gantry rod are one object photographed at one
## distance, and a real object's parts all carry grain at the same texel
## density. The derivation is in the file docstring — 8.0 puts a GRAIN_MICRO
## blob at about 6 px in a 760 px frame and one full tile at 0.125 m.
const GRAIN_TILES_PER_M: float = 8.0

## The housing is deliberately NOT the sign's colour. It is building fabric and
## it should be the same grey in all 59 rooms; only the light changes.
const HOUSING_SHELL: Color = Color(0.615, 0.605, 0.585)   ## moulded ABS back box
const HOUSING_BEZEL: Color = Color(0.235, 0.240, 0.250)   ## painted steel ring
const HARDWARE_MID: Color = Color(0.400, 0.400, 0.412)    ## bracket / gantry plate
const HARDWARE_DARK: Color = Color(0.255, 0.260, 0.270)   ## frame bezel stock

## Bezel depth as a fraction of `thickness`, and the face-on width of the ring
## as a fraction of the sign's short side. Both clamped, so a map that sets a
## 0.02 m thick sign still gets a bezel rather than a knife edge.
const BEZEL_DEPTH_FRAC: float = 0.30
const BEZEL_FACE_FRAC: float = 0.075
## The shell is inset this much in TOTAL (half per side) so the bezel laps over
## it. 8 mm reads as a ~5 px lip in a capture; 4 mm would not have.
const SHELL_INSET: float = 0.008
## How far the diffuser stands out of the bezel opening. Small — the text quad
## already floats 3 mm off the body face and must stay clear of it.
const LENS_PROUD: float = 0.0015

# ── Internal state ────────────────────────────────────────────────────

var _built: bool = false
## Every node THIS script added, so teardown never touches grid-added label
## plates, packaging or tag markers that arrived as siblings.
var _owned: Array[Node3D] = []

# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_read_metadata_overrides()
	_build_all()
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	# Snapshot every key that changes geometry. curation_station calls this with
	# {"emissive": false} one line after it has un-billboarded and dimmed the
	# labels — an unconditional rebuild there would throw that framing away.
	var before_text: String = text
	var before_arrow: String = arrow_direction
	var before_sign_color: Color = sign_color
	var before_text_color: Color = text_color
	var before_width: float = width
	var before_height: float = height
	var before_thickness: float = thickness
	var before_mount: float = mount_offset_z
	var before_glow: float = glow_energy
	var before_spill: float = spill
	var before_support: String = support

	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()

	if not _built:
		# Nothing exists yet; _ready() will build with the values just resolved.
		return

	if (text == before_text
			and arrow_direction == before_arrow
			and sign_color == before_sign_color
			and text_color == before_text_color
			and is_equal_approx(width, before_width)
			and is_equal_approx(height, before_height)
			and is_equal_approx(thickness, before_thickness)
			and is_equal_approx(mount_offset_z, before_mount)
			and is_equal_approx(glow_energy, before_glow)
			and is_equal_approx(spill, before_spill)
			and support == before_support):
		# Nothing that shapes this sign moved. Touch nothing, say nothing.
		return

	_rebuild_now()
	print("[ExitSign] Config applied — support=%s, text=%s, arrow=%s" % [
		support, text, arrow_direction])


func _read_metadata_overrides() -> void:
	if has_meta("config_text"):
		text = str(get_meta("config_text"))
	if has_meta("config_arrow_direction"):
		arrow_direction = str(get_meta("config_arrow_direction"))
	if has_meta("config_sign_color"):
		sign_color = _parse_color(str(get_meta("config_sign_color")), sign_color)
	if has_meta("config_text_color"):
		text_color = _parse_color(str(get_meta("config_text_color")), text_color)
	if has_meta("config_width"):
		width = float(str(get_meta("config_width")))
	if has_meta("config_height"):
		height = float(str(get_meta("config_height")))
	if has_meta("config_thickness"):
		thickness = float(str(get_meta("config_thickness")))
	if has_meta("config_mount_offset_z"):
		mount_offset_z = float(str(get_meta("config_mount_offset_z")))
	if has_meta("config_glow_energy"):
		glow_energy = float(str(get_meta("config_glow_energy")))
	if has_meta("config_spill"):
		spill = float(str(get_meta("config_spill")))
	if has_meta("config_support"):
		support = _pick_axis(str(get_meta("config_support")), SUPPORTS, support)


## Synchronous teardown + rebuild. remove_child() first so the old nodes leave the
## tree in this frame — a deferred rebuild would let _auto_ground_artifact measure
## an empty AABB and skip grounding the sign entirely.
func _rebuild_now() -> void:
	for c in _owned:
		if is_instance_valid(c):
			if c.get_parent() == self:
				remove_child(c)
			c.queue_free()
	_owned.clear()
	_build_all()


# ── Build ─────────────────────────────────────────────────────────────

func _build_all() -> void:
	_build_support()
	_build_body()
	_build_text()
	_build_arrow()
	_build_wall_contact()


func _add_owned(n: Node3D) -> void:
	add_child(n)
	_owned.append(n)


## Shell + bezel + lens, occupying exactly the box the old single emissive
## BoxMesh occupied. The OUTLINE is unchanged — same width, same height, same
## thickness, back face still on the local plane at mount_offset_z — so every
## shipped `support = none` placement keeps its silhouette. What changed is
## that the outline is now filled by three surfaces instead of one, and only
## the middle one is a light.
func _build_body() -> void:
	var bezel_d: float = clampf(thickness * BEZEL_DEPTH_FRAC, 0.006, 0.022)
	var bezel_w: float = clampf(minf(width, height) * BEZEL_FACE_FRAC, 0.005, 0.018)
	var shell_d: float = maxf(thickness - bezel_d, 0.004)
	var z_front: float = mount_offset_z + thickness

	# ── Shell: the moulded back box, inset so the bezel laps over it ──
	# No chamfer (bevel 0 -> PbrKit falls back to a 12-tri BoxMesh): the only
	# edge that ever catches a highlight here is the bezel's, and this box is
	# tucked under it. Paying 44 triangles for edges nobody sees is the kind of
	# thing that turns a prop with 59 placements into a budget problem.
	var inset: float = SHELL_INSET
	var shell: MeshInstance3D = PBR.box(
		Vector3(0.0, 0.0, mount_offset_z + shell_d * 0.5),
		Vector3(maxf(width - inset, 0.01), maxf(height - inset, 0.01), shell_d),
		_shell_material(), 0.0, 0.0)
	shell.name = "Shell"
	_add_owned(shell)

	# ── Bezel: the painted ring around the light ─────────────────────
	# Chamfered, and chamfered by hand. PbrKit derives its automatic bevel from
	# the SMALLEST dimension, which on an 18 mm bezel is about 1 mm — roughly
	# one pixel in a capture, so the edge would vanish exactly as it did before
	# this pass. 5 mm is ~6 px: a band, not a hairline.
	var bevel: float = clampf(bezel_d * 0.28, 0.0025, 0.006)
	var bezel: MeshInstance3D = PBR.box(
		Vector3(0.0, 0.0, z_front - bezel_d * 0.5),
		Vector3(width, height, bezel_d),
		_bezel_material(), bevel, 0.10)
	bezel.name = "Bezel"
	_add_owned(bezel)

	# ── Lens: the diffuser, still the only thing that glows ──────────
	# A solid box passing THROUGH the bezel plate rather than a hollow frame
	# plus a pane — the interpenetration is invisible and it buys the whole
	# ring for 12 triangles. Node keeps the old name "Body" so anything that
	# ever went looking for the glowing part still finds it.
	var lens_d: float = bezel_d + 0.006
	var lens: MeshInstance3D = PBR.box(
		Vector3(0.0, 0.0, z_front + LENS_PROUD - lens_d * 0.5),
		Vector3(maxf(width - bezel_w * 2.0, 0.01),
			maxf(height - bezel_w * 2.0, 0.01), lens_d),
		_lens_material(), 0.0, 0.0)
	lens.name = "Body"
	lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_add_owned(lens)

	_build_spill(z_front)


# ── Finish ────────────────────────────────────────────────────────────

## Land a kit material's detail frequency on THIS artifact's scale.
##
## scale_detail MULTIPLIES, so the factor is derived from whatever tiling the
## kit builder chose (uv1_scale.x, the across-grain component in every builder
## used here) rather than assigned over the top of it. Each material keeps its
## own character; only the frequency moves, and it moves to one shared number.
func _fit_grain(m: StandardMaterial3D) -> StandardMaterial3D:
	if m == null:
		return m
	var base: float = maxf(m.uv1_scale.x, 0.001)
	return PBR.scale_detail(m, GRAIN_TILES_PER_M / base)


## The back box. Moulded ABS: satin, dielectric, hardly worn. No weathering and
## no crevice AO — a mid-grey with three separate "slight" darkenings stacked on
## it is how a light object arrives at charcoal.
func _shell_material() -> StandardMaterial3D:
	return _fit_grain(PBR.hard_plastic(HOUSING_SHELL, 0.42, 0.06))


## The bezel: painted steel, the darkest surface on the sign and the reason the
## green reads as bright. `wear` stays under 0.30, which is the line where
## painted_metal starts multiplying grime into the albedo — this surface is
## already dark, its box wear already dims the underside, and a third darkening
## would take it to a hole in the scene rather than a ring around a lamp.
func _bezel_material() -> StandardMaterial3D:
	return _fit_grain(PBR.painted_metal(HOUSING_BEZEL, 0.18, 0.28, 0.56))


## The diffuser. An acrylic panel that glows, not a slab of coloured light.
##
## hard_plastic brings the roughness texture, the micro normal and the clear
## coat, so the face carries a specular that MOVES over an emission that does
## not. The emission itself is bolted on at exactly the shipped glow_energy —
## nothing here raises it.
func _lens_material() -> StandardMaterial3D:
	var m: StandardMaterial3D = PBR.hard_plastic(sign_color, 0.86, 0.02)
	# The kit's anti-clip rule: albedo sits BELOW emission. A face whose albedo
	# and emission are both full-value goes to flat white the moment any room
	# light lands on it, and a clipped white sign has no colour left to be.
	m.albedo_color = sign_color.darkened(0.35)
	m.emission_enabled = true
	m.emission = sign_color
	m.emission_energy_multiplier = maxf(glow_energy, 0.0)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	# hard_plastic's rim is tuned for an unlit part; on a face this bright it
	# just washes the border into the bezel.
	m.rim = 0.12
	return _fit_grain(m)


## Drawn steel rod. machined_metal rather than brushed_metal on purpose:
## brushed_metal's 40x stretch is sized for a cabinet face, and on an 8 mm rod
## it puts the streaks well under a pixel — which is static, not steel.
func _rod_material() -> StandardMaterial3D:
	return _fit_grain(PBR.machined_metal(PBR.STEEL, 0.34, 0.16))


## The sign's own light, thrown back at its housing.
##
## VR budget: ONE OmniLight3D, shadows OFF, range under 1.1 m, and distance
## fade so it stops being submitted past ~10 m. A room places one to three of
## these, not fifty-nine — the corpus-wide placement count is spread across
## maps. Without it the new bezel and the support hardware are lit only by
## whatever ambient the room has, and a flat wash on a good surface still
## renders as a flat surface.
func _build_spill(z_front: float) -> void:
	var energy: float = glow_energy * clampf(spill, 0.0, 2.0)
	if energy <= 0.001:
		return
	var lamp := OmniLight3D.new()
	lamp.name = "Spill"
	lamp.light_color = sign_color
	lamp.light_energy = clampf(energy, 0.0, 3.0)
	lamp.light_specular = 0.6
	lamp.omni_range = clampf(maxf(width, height) * 2.4, 0.30, 1.60)
	lamp.omni_attenuation = 1.4
	lamp.shadow_enabled = false
	lamp.distance_fade_enabled = true
	lamp.distance_fade_begin = 7.0
	lamp.distance_fade_length = 3.0
	# Just in front of the lens, so the bezel ring takes it at a grazing angle
	# and gets a gradient across its width instead of a uniform tint.
	lamp.position = Vector3(0.0, 0.0, z_front + 0.045)
	_add_owned(lamp)


## A soft contact shadow on the WALL, not the floor.
##
## PbrKit.ground_shadow projects along its own -Y; a pivot rotated 90 degrees
## about X turns that into -Z, which is where this artifact's wall is. It is
## the cheapest cue that the sign is mounted rather than floating, and it costs
## no triangles and no light. normal_fade keeps it off surfaces facing the
## wrong way, so it cannot smear a dark square across a floor.
func _build_wall_contact() -> void:
	if mount_offset_z <= 0.001:
		return
	var pivot := Node3D.new()
	pivot.name = "WallContact"
	pivot.rotation = Vector3(deg_to_rad(90.0), 0.0, 0.0)
	var d: Decal = PBR.ground_shadow(maxf(width, height) * 0.62, 0.40, 0.015)
	d.name = "WallShadow"
	d.normal_fade = 0.55
	pivot.add_child(d)
	_add_owned(pivot)


func _build_text() -> void:
	# Baked text quad painted on the front face of the sign body.
	# Emissive/glowing sign — unshaded=true so the text reads as self-lit.
	if text.is_empty():
		return

	# Horizontal space: narrower when arrow shares the sign, full width otherwise.
	var dir := arrow_direction.to_lower()
	var arrow_width := height * 0.45
	var text_w: float
	var text_x_offset := 0.0
	if dir == "right" or dir == "left":
		# Arrow occupies ~arrow_width on one side; text takes the rest with a small gap.
		text_w = width - arrow_width - 0.01
		text_x_offset = (-arrow_width * 0.5) if dir == "right" else (arrow_width * 0.5)
	else:
		text_w = width - 0.02

	var text_h := height * 0.55
	var quad := BakedText.make_label_mesh(text, text_color, Vector2(text_w, text_h), 1400, true)
	if quad == null:
		return
	quad.name = "Text"
	# Push slightly forward of the body face.
	var z_face := mount_offset_z + thickness + 0.003
	quad.position = Vector3(text_x_offset, 0.0, z_face)
	_add_owned(quad)


func _build_arrow() -> void:
	var dir := arrow_direction.to_lower()
	if dir == "none":
		return

	# Arrow is a baked unicode glyph quad — unshaded so it glows with the sign.
	var glyph: String
	match dir:
		"left":  glyph = "←"
		"right": glyph = "→"
		"up":    glyph = "↑"
		"down":  glyph = "↓"
		_:       glyph = "→"

	var arrow_size := height * 0.65
	var quad := BakedText.make_label_mesh(glyph, text_color, Vector2(arrow_size, arrow_size), 1400, true)
	if quad == null:
		return
	quad.name = "Arrow"

	# Place arrow on the side opposite the text shift.
	var arrow_x_offset := 0.0
	if dir == "right":
		arrow_x_offset = width * 0.32
	elif dir == "left":
		arrow_x_offset = -width * 0.32

	var z_face := mount_offset_z + thickness + 0.003
	quad.position = Vector3(arrow_x_offset, 0.0, z_face)
	_add_owned(quad)


# ── Support ───────────────────────────────────────────────────────────

## The hardware is deliberately NOT emissive: it is the dull thing that holds the
## bright thing, and the contrast is the whole point of the axis.
func _hardware_material(darker: bool = false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	var base: Color = Color(0.16, 0.17, 0.18) if darker else Color(0.28, 0.29, 0.31)
	mat.albedo_color = base
	mat.metallic = 0.65
	mat.roughness = 0.42
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	return mat


func _box(node_name: String, size: Vector3, pos: Vector3, mat: StandardMaterial3D) -> void:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	var mesh := BoxMesh.new()
	mesh.size = size
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	_add_owned(mi)


func _build_support() -> void:
	match support:
		"bracket":
			_build_support_bracket()
		"frame":
			_build_support_frame()
		"gantry":
			_build_support_gantry()
		_:
			# "none" — the pre-promotion look. Zero nodes added, so all 40 shipped
			# placements render exactly as they did before this axis existed.
			pass


## Minimal hardware fixing the sign to a vertical surface: a plate flat on the wall
## plane and two arms out to the sign's back face. The sign itself does not move or
## rotate — the bracket declares WHERE THE WALL IS, which is the thing the bare sign
## never said.
func _build_support_bracket() -> void:
	var mat := _hardware_material()
	# Plate: 0.14 x 0.20 x 0.006 m, back surface on the wall plane at z = 0.
	# Taller than the sign (0.20 vs 0.18) so it reads above and below the face.
	_box("BracketPlate",
		BRACKET_PLATE,
		Vector3(0.0, 0.0, BRACKET_PLATE.z * 0.5),
		mat)

	# Two square arms running forward from the plate to the sign's back face at
	# z = mount_offset_z. The gap is small by design — this is a flush fixing, not
	# a projecting signal arm.
	var arm_len: float = maxf(mount_offset_z, BRACKET_PLATE.z)
	var arm_size: Vector3 = Vector3(BRACKET_ARM, BRACKET_ARM, arm_len)
	var arm_y: float = minf(BRACKET_ARM_Y, maxf(height * 0.5 - BRACKET_ARM * 0.5, 0.0))
	for s in [1.0, -1.0]:
		var sy: float = float(s)
		_box("BracketArm%s" % ("Top" if sy > 0.0 else "Bottom"),
			arm_size,
			Vector3(0.0, arm_y * sy, arm_len * 0.5),
			mat)


## An upright structure standing AROUND the face: a dark bezel on all four edges
## with the emissive body recessed into it, closed by a back panel on the wall.
## The sign stops being a floating rectangle and becomes a fitting.
func _build_support_frame() -> void:
	var mat := _hardware_material(true)
	var outer_w: float = width + FRAME_SECTION * 2.0
	var outer_h: float = height + FRAME_SECTION * 2.0

	# Back panel flat on the wall plane — 0.50 x 0.23 x 0.006 m at default size.
	_box("FrameBackPanel",
		Vector3(outer_w, outer_h, FRAME_PANEL_D),
		Vector3(0.0, 0.0, FRAME_PANEL_D * 0.5),
		mat)

	# The bezel face sits FRAME_RECESS proud of the sign's own front face, so the
	# emissive body is recessed 0.01 m into the opening. The bars run back from
	# there to the panel, closing the frame rather than floating in front of it.
	var z_front: float = mount_offset_z + thickness + FRAME_RECESS
	var z_back: float = FRAME_PANEL_D
	var bar_d: float = maxf(z_front - z_back, FRAME_SECTION)
	var bar_z: float = z_back + bar_d * 0.5

	var y_bar: float = (outer_h - FRAME_SECTION) * 0.5
	_box("FrameBarTop", Vector3(outer_w, FRAME_SECTION, bar_d),
		Vector3(0.0, y_bar, bar_z), mat)
	_box("FrameBarBottom", Vector3(outer_w, FRAME_SECTION, bar_d),
		Vector3(0.0, -y_bar, bar_z), mat)

	var x_bar: float = (outer_w - FRAME_SECTION) * 0.5
	_box("FrameBarLeft", Vector3(FRAME_SECTION, height, bar_d),
		Vector3(-x_bar, 0.0, bar_z), mat)
	_box("FrameBarRight", Vector3(FRAME_SECTION, height, bar_d),
		Vector3(x_bar, 0.0, bar_z), mat)


## The load comes from ABOVE. Two slender rods rise from the sign's top edge to a
## plate overhead, and the sign hangs off it instead of resting against anything.
func _build_support_gantry() -> void:
	var mat := _hardware_material()
	var z_mid: float = mount_offset_z + thickness * 0.5
	var y_top: float = height * 0.5
	var rod_x: float = minf(GANTRY_ROD_X, GANTRY_PLATE.x * 0.5 - GANTRY_ROD_D)

	for s in [1.0, -1.0]:
		var sx: float = float(s)
		var rod := MeshInstance3D.new()
		rod.name = "GantryRod%s" % ("Right" if sx > 0.0 else "Left")
		var cyl := CylinderMesh.new()
		cyl.top_radius = GANTRY_ROD_D * 0.5
		cyl.bottom_radius = GANTRY_ROD_D * 0.5
		cyl.height = GANTRY_RISE
		cyl.radial_segments = 10
		rod.mesh = cyl
		rod.material_override = mat
		rod.position = Vector3(rod_x * sx, y_top + GANTRY_RISE * 0.5, z_mid)
		_add_owned(rod)

	# 0.30 x 0.06 x 0.02 m plate sitting on top of the rods — the ceiling fixing.
	_box("GantryPlate",
		GANTRY_PLATE,
		Vector3(0.0, y_top + GANTRY_RISE + GANTRY_PLATE.y * 0.5, z_mid),
		mat)


# ── Helpers ───────────────────────────────────────────────────────────

## Accept an axis value only if it names something we actually build. A typo in a
## map token falls back to the current value — a half-recognised value would strand
## a placement with hardware it never asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _parse_color(s: String, fallback: Color) -> Color:
	var parts := s.split(",")
	if parts.size() < 3:
		return fallback
	var r := float(parts[0])
	var g := float(parts[1])
	var b := float(parts[2])
	var a := 1.0
	if parts.size() >= 4:
		a = float(parts[3])
	return Color(r, g, b, a)
