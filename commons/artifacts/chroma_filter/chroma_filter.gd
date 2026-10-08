# @identity
# essence: a white corner - a slab and two walls - with three tall coloured panes crossing in front of it at 60 degrees, so that how many panes stand between a visitor and the white is decided by where the visitor stands; one word decides whether the panes subtract from the white (a filter), average with it (the gallery's veil) or hide it (a solid coat), and another decides which three colours they carry
# desire: that a visitor walk into one wedge, look through one pane at the wall, then across the crossing through two, then at the axis through three, and find that the colour was never on the pane - it is what the panes between them and the white have taken away - and that the darkest place moves when they do
# critical_parameter: mix, because it decides what a coloured pane DOES to the white behind it. triad only changes which three colours are asked the question; under mix=solid the three triads are three sets of opaque paint and nothing overlaps at all
# triggers: _ready() reads config_mix / config_triad / config_plate metadata, builds the slab, the two walls, the three panes, the plate and the body once. apply_grid_config rebuilds only when one of the three words actually changes
# emerges: under filter, colours nobody painted - blue, green and red where cyan, magenta and yellow cross, and a near-black post of triple overlap at the axis - and under the bauhaus triad the same crossing goes dark almost everywhere, so "primary" turns out to be a claim about a medium
# needs: floor at y=0 under the origin [the grid provides it]; 4.4 m of headroom [the museum's halls have it]; a lit hall, since nothing here emits - the white is the piece's own but the light is the hall's [the hall provides it]; a hall corner or a free +X/+Z quadrant to walk in from [placement, footprint 4x4 growing +X/+Z]; a body approaching the plate from +Z [spatial_needs, player_position "front"]; apply_grid_config [present]
# relationships: the SURFACE companion of chroma_stack and chroma_translation, which hold the surface still and vary the rule; this holds the rule (multiply) still and varies the surface the visitor stands in front of. Taken from ps06_grawunder_cmy (the gallery's winner) and its warm/cool hue variants, whose panes averaged (TRANSPARENCY_ALPHA + BLEND_MODE_MIX at alpha 0.5, primitive_stack._translucent_material); that surface is kept here as the value veil beside the true filter. The MUL pane is the shipped recipe of grab_disk.gd and color_display_disk.gd at disk scale; stained_curtain and color_constellation_office are veils; this is the corpus's first walk-scale MUL pane. The bauhaus triad is chroma_stack's RED / YELLOW / BLUE exactly
# truth: a colour on a pane is not a colour added but a colour left over. Each pane removes part of the white behind it; two panes leave the printer's secondary; three leave almost nothing; and how many stand between you and the wall is decided by where you stand. Run the same crossing under the red, yellow and blue that name kinds on the row-six totem and the Bauhaus triad goes dark nearly everywhere it overlaps, while cyan, magenta and yellow leave blue, green and red. The veil is not a lie: it is what the gallery did, averaging, which is what the eye does further down the hall - and it is another thing

extends Node3D
class_name ChromaFilter

## CHROMA_FILTER -- three coloured panes crossing in front of a white corner.
##
## Color_Context_Placed's sequence truth is that a colour value enters an encounter:
## a light, a surface, a position, a neighbour and a viewer. This object brings its
## own SURFACE - a white slab and two white walls at a hall corner - and stands three
## tall coloured panes across it at 0, 60 and 120 degrees, all through one axis. A
## visitor in any of the six wedges looks at the white through one, two or three
## panes depending on where they stand. `mix` decides what a pane does to the white:
##
##   filter   the pane MULTIPLIES what is behind it (unshaded, transparency alpha,
##            blend multiply, alpha 1.0, the DEFAULT back-face cull). One pane
##            leaves its own colour on the white; two leave their product - under
##            cyan, magenta and yellow that is blue, green and red; three leave
##            almost nothing. Commutative, so the three same-origin panes read the
##            same in any sort order. The cull is left at its default on purpose:
##            a box is two-sided by its own six faces, and cull disabled on a
##            transparent box (the transparent pass writes no depth) rasterises
##            the far face too, so every colour would be applied twice and squared.
##   veil     the pane AVERAGES with what is behind it (shaded, transparency alpha,
##            blend mix, alpha 0.50, cull DISABLED - the gallery's own
##            _translucent_material, to the letter). Under cull disabled a ray
##            crosses both faces of the box, so one pane shows a quarter wall and
##            three quarters paint; two show a sixteenth of wall, three sixteenths
##            of the far pane and three quarters of the near one - the veil takes
##            sides, the filter does not. This is the gallery's surface: the winner
##            ps06_grawunder_cmy mixed its panes exactly like this and its note
##            called the result subtractive. Kept beside the truth, not as a lie.
##   solid    the pane is opaque paint. Each hides the wall and shows its own
##            colour; nothing mixes. The control.
##
## `triad` decides which three colours the panes carry (pane 0, 1, 2 in order):
##
##   paint     cyan, magenta, yellow - the printer's three. Filter products blue,
##             green, red; triple (0.22, 0.20, 0.14).
##   light     green, BLUE, red - the screen's three. As filters any two leave the
##             wall dark: every product under 0.3 in every channel.
##   bauhaus   RED, YELLOW, BLUE - chroma_stack's constants, the ones that name
##             kinds on the row-six totem. As filters: red-orange, plum, dark green,
##             and a triple of (0.12, 0.05, 0.02). A primary is a claim about a
##             medium.
##
## The pane order puts the pair that can only differ in hue on pane 2, which the
## canonical sweep camera (35.5 degrees off +Z toward +X) sees nearly edge-on at 84
## degrees; panes 0 and 1 face it at 35 and 24 degrees and carry the luminance
## differences (raw luminances pane 0: 0.72 / 0.55 / 0.35; pane 1: 0.49 / 0.35 /
## 0.75; pane 2: 0.83 / 0.40 / 0.35 across paint / light / bauhaus).
##
## `plate` is furniture, not DNA: it puts the reading plate at the west or the east
## end of the piece's +Z edge, so a second placement can keep its reader out from
## under a hall lamp. It is never swept.
##
## THE GEOMETRY, in metres, local, origin at the token cell's centre. The grid seats
## an artifact's origin at the CENTRE of its cell, and a hall's inner wall faces are
## 0.5 m from the first interior cell's centre, so the slab and the two walls put
## their outer faces at -0.46: placed in a hall corner the piece stands 4 cm off both
## hall walls. Slab 3.60 x 0.06 x 3.60 on y = 0; WallX 0.08 thick along the -X edge
## and WallZ 0.08 thick along the -Z edge, both from the slab's top (0.06) to 4.40;
## three panes 3.40 x 4.20 x 0.03 centred at (1.34, 2.16, 1.34) with rotation.y of
## 0, PI/3 and 2 PI/3, tops at 4.26 under the wall line. Pane 0 reaches x -0.36..3.04,
## 2 cm short of WallX's inner face; panes 1 and 2 reach z -0.13..2.81, inside the
## slab. Total extent 3.60 x 4.40 x 3.62 (the plate adds 2 cm past the slab's +Z
## face), identical for all nine axis values, because the walls fix the box.
##
## THE PLATE. One text_screen in SCREEN mode on the +Z edge at 1.20 m, 0.90 wide,
## held by a short dark post standing on the slab, its back in the plane of the
## slab's +Z face. Title = the two words in force, body = one sentence about what
## the mix does. It faces +Z and is never turned about Y. Rebuilt on every rebuild.
##
## THE BODY. Walk in from the open +X/+Z quadrant into a wedge and stand near the
## axis. Look sideways through one pane at the white wall, across the crossing
## through two, at the axis through three. Step round to the next wedge and the pair
## changes; the darkest place moves with you. The three wedges whose mouths open
## east, south and south-east are enterable (mouth arcs 1.70 m wide); the wedge
## facing the west wall has a 0.25 m gap between pane tip and wall, and the two
## facing the corner are closed - they are for looking through, not standing in.
## The hall is open-roof, so above the walls the panes multiply the sky.
##
## NO RANDOMNESS anywhere: every position, angle and colour is a constant or a pure
## function of the two words, so a sweep photographs the axis and nothing else. No
## _process, no timers, no lights (the hall lights it). Built-in meshes only. No
## emission on any surface.
##
## ARITHMETIC, not renders (the session that wrote this did not run Godot):
##   Predicted closest pair, a LOWER BOUND and a WEAK row, named and accepted:
##   mix=veil, triad=paint vs triad=light, about 9%. Each veil pane is a two-sided
##   box under the gallery's cull-disabled MIX, so a ray crosses two faces and a
##   pane shows 0.25 * wall + 0.75 * paint with the lit wall about 0.82: paint
##   differences scale by 0.75, not by half. Pane 0 (seen at 35 degrees, about
##   5 m^2 of single-pane image) cyan to green: luminance 0.745 vs 0.618, 33 grey
##   levels. Pane 1 (24 degrees) magenta to BLUE: 0.57 vs 0.47, 27 levels. Pane 2
##   (84 degrees, near edge-on, about 1.4 m^2 projected) yellow to red: 0.83 vs
##   0.50, 82 levels. The hottest 5% of an ~18 m^2 crop is ~0.9 m^2: if pane 2's
##   sliver is not hidden behind panes 0/1 the row reads ~30%, if hidden ~13%.
##   The headline stays at 9%, under the pane-0 arithmetic, because the veil is
##   shaded and the arithmetic is not. Per channel the pair moves 134 levels on
##   the veiled pane (B 0.89 vs 0.37; raw paint cyan B 0.92 vs green B 0.22), so
##   it can never be a twin. Every other triad row 18-40%; closest mix pair
##   triad=light, filter vs solid, ~20%. A sweep UNDER 9% on the named row means
##   a pane rendered opaque (MUL missed the transparent pass) or the walls not
##   lit - check the harness before the axis.
##
## NOT COMPILED OR CAPTURED in the session that wrote it. The lead compiles and
## captures every artifact of the pass in one boot afterwards; the first capture
## is the gate before the plate's word "filter" ships.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# -- The corner, in metres. EVERYTHING SITS ABOVE y = 0. -------------------------
# The origin is the token cell's centre and the slab's underside is y = 0 exactly,
# so a map token with an explicit y (where auto-grounding is skipped) still stands
# the piece on the floor rather than half through it.
const OUTER := -0.46          ## outer face of slab and walls: 4 cm off a hall wall face at -0.5
const SLAB_W := 3.60          ## the slab across X and Z, and the walls' length
const SLAB_H := 0.06
const WALL_T := 0.08          ## the two white walls' thickness
const WALL_TOP := 4.40        ## the wall line, and the piece's height
const CENTRE := OUTER + SLAB_W * 0.5   ## 1.34: the panes' shared axis in X and Z
const PANE_W := 3.40
const PANE_H := 4.20          ## tops at 0.06 + 4.20 = 4.26, under the wall line
const PANE_T := 0.03
const PANE_COUNT := 3
const ROUGHNESS := 0.55       ## one roughness for every opaque surface
const VEIL_ALPHA := 0.50      ## the gallery's alpha (primitive_stack._translucent_material)
const VEIL_ROUGHNESS := 0.18  ## the gallery's gloss on its translucent panes

# -- The plate ------------------------------------------------------------------
const PLATE_W := 0.90
const PLATE_Y := 1.20         ## reading height; text_screen's own stand default is 1.15
const PLATE_GAP := 0.001      ## between the slab's +Z face plane and the frame's back
const SCREEN_BACK := 0.014    ## text_screen SCREEN: frame centred at z -0.008, 12 mm deep
const MOUNT_SIDE := 0.08      ## the dark post that holds the plate
const MOUNT_COLOR := Color(0.20, 0.22, 0.27)
const POST_H := 1.20          ## the post stands on the slab, 0.06..1.26
## Where the post stands along the +Z edge, by the `plate` word. West keeps the
## reader clear of the row below; east keeps a second placement's reader out from
## under the (5,17) lamp.
const POST_X: Dictionary = {"west": 0.05, "east": 2.90}

# -- The colour vocabulary --------------------------------------------------------
const WHITE := Color(0.92, 0.92, 0.90)
## chroma_stack's three, exactly, so the bauhaus triad is the totem's own paint.
const BLUE := Color(0.16, 0.36, 0.80)
const RED := Color(0.80, 0.16, 0.16)
const YELLOW := Color(0.92, 0.78, 0.18)
## The printer's three.
const CYAN := Color(0.25, 0.92, 0.92)
const MAGENTA := Color(0.92, 0.25, 0.62)
const PROCESS_YELLOW := Color(0.95, 0.88, 0.25)
## The screen's remaining two (its blue is BLUE).
const GREEN := Color(0.18, 0.80, 0.22)
const LIGHT_RED := Color(0.92, 0.18, 0.15)
## Pane i takes entry i. The order is deliberate: pane 2 is the one the sweep
## camera sees edge-on, so it carries the hue-only differences.
const TRIAD_COLORS: Dictionary = {
	"paint": [CYAN, MAGENTA, PROCESS_YELLOW],
	"light": [GREEN, BLUE, LIGHT_RED],
	"bauhaus": [RED, YELLOW, BLUE],
}

# -- THE AXES ---------------------------------------------------------------------
## What a pane does to the white behind it. `filter` is the default: multiply.
@export_enum("filter", "veil", "solid") var mix: String = "filter"
## Which three colours the panes carry.
@export_enum("paint", "light", "bauhaus") var triad: String = "paint"
## Furniture, not DNA: which end of the +Z edge holds the plate. Never swept.
@export_enum("west", "east") var plate: String = "west"

## The allow-lists, same spelling and same order as the @export_enum lines above.
## An unknown word warns and falls back to the DEFAULT, never to a blank corner.
const MIXES: PackedStringArray = ["filter", "veil", "solid"]
const TRIADS: PackedStringArray = ["paint", "light", "bauhaus"]
const DEFAULT_MIX := "filter"
const DEFAULT_TRIAD := "paint"
const PLATE_ENDS: PackedStringArray = ["west", "east"]
const DEFAULT_PLATE := "west"

## One honest sentence per (mix, triad) for the plate. Under filter the triad
## changes what the crossing leaves, so it gets a sentence each; under veil and
## solid the triad only changes the paint, so one sentence serves.
const FILTER_BODY: Dictionary = {
	"paint": "Through two panes the wall is blue, green or red; through three, almost nothing. The darkest place moves with you.",
	"light": "A screen adds red, green and blue; crossed as filters, any two leave the wall dark.",
	"bauhaus": "The totem's red, yellow and blue, crossed as filters: red-orange, dark green, plum, and almost nothing.",
}
const VEIL_BODY := "The panes average with the wall, and where they cross the nearest pane has the last word. The gallery mixed like this."
const SOLID_BODY := "Each pane hides the wall and shows its own paint. Nothing mixes."

## True once _ready has built once. apply_grid_config before that only stores.
var _built: bool = false


func _ready() -> void:
	# The museum stamps config_* metadata on the root BEFORE it enters the tree,
	# and the grid calls apply_grid_config call_deferred, AFTER this. So the meta
	# read happens here, before a single mesh is made.
	_read_meta_overrides()
	_build()
	_built = true


# -- the build ------------------------------------------------------------------

func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var colours: Array = TRIAD_COLORS.get(triad, TRIAD_COLORS[DEFAULT_TRIAD])

	var body := StaticBody3D.new()
	body.name = "Body"

	# The slab: 3.60 square, 0.06 thick, its underside on y = 0.
	var slab_size := Vector3(SLAB_W, SLAB_H, SLAB_W)
	var slab_pos := Vector3(CENTRE, SLAB_H * 0.5, CENTRE)
	var slab := BoxMesh.new()
	slab.size = slab_size
	_add_mesh(slab, slab_pos, WHITE, "Slab")
	_add_box_shape(body, slab_pos, slab_size)

	# The two walls, from the slab's top to the wall line. They overlap at the
	# corner block, which is deliberate: the corner is one white thing.
	var wall_h: float = WALL_TOP - SLAB_H
	var wall_y: float = SLAB_H + wall_h * 0.5
	var wall_x_size := Vector3(WALL_T, wall_h, SLAB_W)
	var wall_x_pos := Vector3(OUTER + WALL_T * 0.5, wall_y, CENTRE)
	var wall_x := BoxMesh.new()
	wall_x.size = wall_x_size
	_add_mesh(wall_x, wall_x_pos, WHITE, "WallX")
	_add_box_shape(body, wall_x_pos, wall_x_size)

	var wall_z_size := Vector3(SLAB_W, wall_h, WALL_T)
	var wall_z_pos := Vector3(CENTRE, wall_y, OUTER + WALL_T * 0.5)
	var wall_z := BoxMesh.new()
	wall_z.size = wall_z_size
	_add_mesh(wall_z, wall_z_pos, WHITE, "WallZ")
	_add_box_shape(body, wall_z_pos, wall_z_size)

	# The three panes, one origin, turned 0, 60 and 120 degrees about Y. Pane i
	# takes triad colour i; the material is the mix's.
	var pane_size := Vector3(PANE_W, PANE_H, PANE_T)
	var pane_pos := Vector3(CENTRE, SLAB_H + PANE_H * 0.5, CENTRE)
	for i in range(PANE_COUNT):
		var yaw: float = float(i) * PI / 3.0
		var c: Color = colours[i]
		var pane := BoxMesh.new()
		pane.size = pane_size
		var mi: MeshInstance3D = _add_mesh(pane, pane_pos, c, "Pane_%d" % i)
		mi.rotation.y = yaw
		_dress_pane(mi, c, i)
		_add_yawed_box_shape(body, pane_pos, pane_size, yaw)

	_add_plate(body)
	add_child(body)


## The pane's material by `mix`, replacing the matte one _add_mesh gave it.
##
##   filter  the shipped MUL recipe (grab_disk.gd, color_display_disk.gd): unshaded,
##           TRANSPARENCY_ALPHA is what puts the pane in the transparent pass, blend
##           multiply, alpha 1.0, and the DEFAULT cull, exactly as those two ship
##           it (neither sets cull_mode). Commutative, so no sort pinning is needed.
##   veil    the gallery's lerp: shaded, TRANSPARENCY_ALPHA, blend mix, alpha 0.50,
##           roughness 0.18, CULL_DISABLED (primitive_stack._translucent_material
##           sets it, so the doubled blend IS what the gallery did). render_priority
##           0 / 1 / 2 pins the sort of three coincident origins so the blend
##           cannot flicker between frames.
##   solid   opaque paint at the corner's roughness.
##
## A pane is a BoxMesh, so it is two-sided by its own faces (a visitor on either
## side sees a front face) without any cull setting. CULL_DISABLED must NOT be put
## on the filter: the transparent pass writes no depth, so the far face would be
## rasterised as well and every colour multiplied in twice - cyan x magenta would
## read (0.05, 0.05, 0.33) instead of (0.23, 0.23, 0.57), and the bauhaus products
## would go black instead of plum and dark green. Both transparent panes cast no
## shadow: the sweep's key light has shadows on, and an alpha pane throws an
## opaque one. The solid pane casts its shadow like any wall.
func _dress_pane(mi: MeshInstance3D, c: Color, i: int) -> void:
	var m := StandardMaterial3D.new()
	m.metallic = 0.0
	match mix:
		"filter":
			m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_MUL
			m.albedo_color = Color(c.r, c.g, c.b, 1.0)
			m.roughness = ROUGHNESS
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		"veil":
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			m.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			m.cull_mode = BaseMaterial3D.CULL_DISABLED
			m.albedo_color = Color(c.r, c.g, c.b, VEIL_ALPHA)
			m.roughness = VEIL_ROUGHNESS
			m.render_priority = i
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_:
			m.albedo_color = Color(c.r, c.g, c.b, 1.0)
			m.roughness = ROUGHNESS
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	mi.set_surface_override_material(0, m)


## MeshInstance3D + StandardMaterial3D through the surface override, not
## material_override. Matte, no metal, no emission: only the hue differs.
func _add_mesh(mesh: Mesh, pos: Vector3, c: Color, node_name: String) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.0
	m.roughness = ROUGHNESS
	mi.set_surface_override_material(0, m)
	mi.position = pos
	add_child(mi)
	return mi


func _add_box_shape(body: StaticBody3D, pos: Vector3, size: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	body.add_child(shape)


## The same box, turned about Y by the pane's own yaw, so the body is the mesh.
func _add_yawed_box_shape(body: StaticBody3D, pos: Vector3, size: Vector3, yaw: float) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = pos
	shape.rotation.y = yaw
	body.add_child(shape)


## The plate: text_screen.gd and nothing else, since it is the one text lane that
## renders in a capture. SCREEN mode (0) is the framed face alone - no floor post,
## no recline. Its back sits in the plane of the slab's +Z face at reading height,
## and a short dark post stands on the slab under it so the plate is held rather
## than floating. The post stands at the west or east end of that edge by the
## `plate` word. Nothing is turned about Y: the face presents to +Z.
func _add_plate(body: StaticBody3D) -> void:
	var edge_z: float = OUTER + SLAB_W
	var back_z: float = edge_z + PLATE_GAP
	var post_x: float = float(POST_X.get(plate, POST_X[DEFAULT_PLATE]))
	var post := BoxMesh.new()
	post.size = Vector3(MOUNT_SIDE, POST_H, MOUNT_SIDE)
	_add_mesh(post, Vector3(post_x, SLAB_H + POST_H * 0.5, edge_z - MOUNT_SIDE * 0.5),
		MOUNT_COLOR, "PlatePost")
	_add_box_shape(body, Vector3(post_x, SLAB_H + POST_H * 0.5, edge_z - MOUNT_SIDE * 0.5),
		Vector3(MOUNT_SIDE, POST_H, MOUNT_SIDE))

	var screen := TextScreenScript.new()
	screen.name = "Plate"
	screen.mode = 0
	screen.width_m = PLATE_W
	screen.title = _plate_title()
	screen.body = _plate_body()
	screen.position = Vector3(post_x, PLATE_Y, back_z + SCREEN_BACK)
	add_child(screen)

	# The plate is 0.936 x 0.594 m of visible object standing off the slab's edge;
	# a visitor should not put a hand through it.
	var plate_h: float = PLATE_W * 0.62 + 0.036
	_add_box_shape(body, Vector3(post_x, PLATE_Y, edge_z + 0.010),
		Vector3(PLATE_W + 0.036, plate_h, 0.020))


## "FILTER <middle dot> PAINT": the two words in force, in caps, joined by U+00B7 (written as an escape so the source stays ASCII).
func _plate_title() -> String:
	return "%s \u00b7 %s" % [mix.to_upper(), triad.to_upper()]


func _plate_body() -> String:
	match mix:
		"filter":
			return str(FILTER_BODY.get(triad, FILTER_BODY[DEFAULT_TRIAD]))
		"veil":
			return VEIL_BODY
		"solid":
			return SOLID_BODY
	return str(FILTER_BODY[DEFAULT_TRIAD])


# -- DNA plumbing -----------------------------------------------------------------

## Per-cell configuration, read from config_* metadata. Keys honoured:
##
##   #mix:<filter|veil|solid>        what a pane does to the white behind it
##   #triad:<paint|light|bauhaus>    which three colours the panes carry
##   #plate:<west|east>              which end of the +Z edge holds the plate (furniture)
##
## All three values are WORDS, so no key needs to sit in CONFIG_PARAM_NAMES: only a
## `#key:<number>` on an unlisted key is eaten as the tutorial's rotation shorthand.
## An unknown word warns and falls back to the default.
func _read_meta_overrides() -> void:
	mix = _axis_word("config_mix", MIXES, mix, DEFAULT_MIX, "mix")
	triad = _axis_word("config_triad", TRIADS, triad, DEFAULT_TRIAD, "triad")
	plate = _axis_word("config_plate", PLATE_ENDS, plate, DEFAULT_PLATE, "plate")


func _axis_word(meta_key: String, allowed: PackedStringArray, current: String,
		fallback: String, axis: String) -> String:
	if not has_meta(meta_key):
		return current
	var v: String = str(get_meta(meta_key)).strip_edges().to_lower()
	if v == "":
		return current
	if allowed.has(v):
		return v
	push_warning("chroma_filter: unknown %s '%s' - using '%s'" % [axis, v, fallback])
	return fallback


## The grid's hook. Every key is stored as config_<key> metadata and re-read, so a
## value set here and a value stamped by the museum before _ready take the same
## path. Before the first build this only stores; after it, it rebuilds ONLY when
## one of the three words actually changed - curation_station's blanket
## apply_grid_config({"emissive": false}) must not rebuild a corner. `plate` is in
## the guard because two placements of this one artifact carry different ends,
## and the second would otherwise build with its plate under the lamp.
func apply_grid_config(config: Dictionary) -> void:
	var mix_before: String = mix
	var triad_before: String = triad
	var plate_before: String = plate
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return
	if mix == mix_before and triad == triad_before and plate == plate_before:
		return
	_build()
