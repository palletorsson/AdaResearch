# @identity
# essence: a 4.4 m drum of blue and yellow whose stripes are either painted on as shingles or stood out as two-faced fins, so that the colour a standpoint sees is decided by where the body stands and how far off it is
# desire: that a visitor walk round the fin drum and watch the blue/yellow split stay on their own meridian, then back down the hall until the fine stripes fuse to a grey that is neither the paint pot's green nor the dark green the filters leave
# critical_parameter: face, because it decides whether the colour belongs to the stripe or to the standpoint. grain only sets how fast the flip is and how far off the fusion is, and at fine the two faces are two solid halves
# triggers: _ready() reads config_face / config_grain metadata, builds the three dark cylinders, the N stripes or 2N fin boxes, the plate and the body once. apply_grid_config rebuilds only when one of the two words actually changes
# emerges: under fin a seam nobody painted - a dark meridian that faces the viewer from every standpoint and walks round the drum as they do; under shingle fine, a grey that is on no stripe
# needs: floor at y=0 under the origin [the grid provides it]; 4.4 m of headroom [the museum's halls have it]; a lit hall, since nothing here emits [the hall provides it]; room to be walked round [spatial_needs, clearance 2 on every side but the front]; a hall long enough to back away in, since the fusion claim is about the headset's pixels at ~26 m [Color_Context_Placed's 41 rows]; apply_grid_config [present]
# relationships: the VIEWER companion to chroma_stack, which holds the viewer still, and the partitive leg of chroma_filter's subtractive argument. Taken from the gallery's ps07_kras_slon_round stripe pedestal (its 1.05 chord overlap is the shipped Kras seam and is kept) and ps07_kras_rainbow; taken further, not repeated - the stripes become fins and the grain, not the palette, is the axis. The palette is chroma_stack's BLUE and YELLOW, held for their 0.40 luminance gap
# truth: a colour can be a property of where you stand. With two-faced fins no fin has a colour and every fin has two, and the drum is half blue and half yellow from every standpoint, split on the fin that faces you. With fine stripes the same blue and yellow become one grey from the far end of the hall. Which of the three mixes you get - pot, pane or distance - depends on the company

extends Node3D
class_name ChromaDrum

## CHROMA_DRUM -- primitives x colour, at pillar scale: the viewer's standpoint.
##
## Color_Context_Placed's sequence truth is that a colour value enters an encounter:
## a light, a surface, a position, a neighbour and a viewer. chroma_stack holds the
## viewer still. This drum is the one work of the set in which the viewer is the
## axis: what it shows depends on where the body stands and how far off it is.
##
## `face` decides what a stripe IS:
##
##   shingle   N tangential stripes round the core, BLUE and YELLOW alternating
##             (N is even in every value, so the ring closes). Painted on: walk
##             round and the stripes stay where they are.
##   fin       N radial fins, each two thin boxes back to back, BLUE on the
##             +tangent face and YELLOW on the -tangent face. From any standpoint
##             the drum is half blue and half yellow, split on the fin that faces
##             you (a fin at angle t from your meridian shows its +tangent face
##             when sin t < 0), and the split walks round the drum as you do. No
##             fin has a colour; every fin has two.
##
## `grain` sets N, the number of units round the drum, from a constant table and
## never from a token number:
##
##   coarse    16     shingle chord 0.379 m; fin gap 0.353 m at r 0.95
##   medium    48     0.126 m / 0.104 m
##   fine      192    0.032 m / 0.011 m
##
## On fin the dark core shows between coarse fins (a 0.20 m face leaning 30 deg
## fills 27% of a 0.37 m gap, 83% of a 0.12 m gap) and disappears at fine: coarse
## fins read as a dark drum with coloured blades, fine fins as two solid halves.
## On shingle the fine stripes are 0.032 m, finer than the headset draws from the
## far end of the hall (about 26 m from row 15 to the south wall): there blue and
## yellow are one grey - not the green of the paint pot and not the dark green the
## filters leave. The fusion is DISPLAY-limited, never retinal: at 26 m a 3.2 cm
## stripe subtends about 4 arcmin (the eye resolves about 1); it is the headset's
## roughly 2.4 arcmin per pixel that fuses them. If a Quest walk still separates
## them at the south wall, set fine to 288 (0.020 m): one constant either way.
##
## THE DRUM, in metres. A base disc r 0.98 and 0.10 tall, a dark core r 0.75 from
## 0.10 to 4.30, a cap disc r 0.98 from 4.30 to 4.40: 4.40 m in all, chroma_stack's
## height. Family loyalty, not need: the grain needs the hall's length and the fins
## need the walk-round; 4.4 m does no harm and the plate does not claim the height
## earns anything. Stripes stand at radius 0.92 (r 0.89..0.95) and fins at 0.85
## (r 0.75..0.95); no unit reaches the cap radius, so the extent is 1.96 x 4.40 x
## 1.99 for all six values and the sweep camera never moves.
##
## THE PLATE. One text_screen in SCREEN mode (the framed face alone, no post) on
## the +Z side at 1.20 m, 0.90 wide, held by a dark mount that runs from the axis
## out through the ring, its back in the plane of the base's rim. Title = the two
## words in force, body = one sentence about what the face does. It faces +Z and
## is never turned about Y. Rebuilt with everything else on every rebuild.
##
## NO RANDOMNESS anywhere, so a sweep photographs the axis and nothing else. The
## angles are i * 2 * PI / N and N comes from the UNITS table. Built-in meshes
## only, plain MeshInstance3D (no MultiMesh, so the capture AABB is honest). No
## emission (it cannot make a dark thing glow and it hides the hue).
##
## ARITHMETIC, not renders (the session that wrote this did not run Godot):
##   Predicted closest pair: face=fin, grain=medium vs grain=fine, about 15%, a
##   lower bound. The bounding sphere is 2.6 m, so the sweep camera stands 16.2 m
##   out with a 9.9 m frame, 76.7 px/m: medium fins are 9 px apart, fine 2.4 px.
##   At medium a 0.20 m face leaning 30 deg fills 83% of each 0.104 m gap, so the
##   dark core (lum 0.22) shows as ~1.5 px slivers; at fine the faces overlap
##   fully. On the yellow half those sliver pixels move 0.53 (0.75 vs 0.22),
##   halved by 8x MSAA to ~0.27, over ~17% of that half's pixels - more than the
##   hottest 5% of a ~9 m^2 crop - so >= 0.15. Shingle grain pairs are PHASE
##   differences between stripe patterns (yellow where the other has blue) at up
##   to 0.40 over half the drum: 30-40%, and the fine tile shows moire, not
##   fusion. The face pairs swap half the drum's luminance by 0.40: 35%+. A sweep
##   BELOW 15% on the named row is the harness: widen the ladder (12/36/216) or
##   set dna.framing 0.8 before touching the design.
##
## NOT COMPILED OR CAPTURED in the session that wrote it. The lead compiles and
## captures every artifact of the pass in one boot afterwards.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# -- The drum, in metres. EVERYTHING SITS ABOVE y = 0. --------------------------
# The origin is the base centre. The base disc's underside is at y = 0 exactly, so
# a map token with an explicit y (where auto-grounding is skipped) still stands
# the drum on the floor rather than half through it.
const BASE_R := 0.98          ## the base and cap discs, and the widest thing here
const DISC_H := 0.10          ## base and cap thickness
const CORE_R := 0.75          ## the dark core the units stand round
const UNIT_H := 4.20          ## the core, every stripe and every fin: y 0.10..4.30
const TOTAL_H := DISC_H + UNIT_H + DISC_H   ## 4.40
const STRIPE_R := 0.92        ## shingle stripes, centre radius (r 0.89..0.95)
const STRIPE_D := 0.06        ## shingle stripe depth, radial
const STRIPE_OVERLAP := 1.05  ## chord factor: the shipped Kras seam, leave it
const FIN_R := 0.85           ## fin centre radius (r 0.75..0.95)
const FIN_D := 0.20           ## fin depth, radial
const FIN_T := 0.010          ## one fin box's thickness, tangential; a fin is two
const ROUGHNESS := 0.55       ## one roughness for every surface, so only hue differs

# -- The plate ------------------------------------------------------------------
const PLATE_W := 0.90
const PLATE_Y := 1.20         ## reading height; text_screen's own stand default is 1.15
const PLATE_GAP := 0.001      ## between the base's rim plane and the frame's back
const SCREEN_BACK := 0.014    ## text_screen SCREEN: frame centred at z -0.008, 12 mm deep
const MOUNT_SIDE := 0.08      ## the dark bar that holds the plate off the drum
const MOUNT_COLOR := Color(0.20, 0.22, 0.27)

# -- The colour vocabulary --------------------------------------------------------
## chroma_stack's BLUE and YELLOW exactly, chosen for the 0.40 luminance gap
## (BLUE 0.35, YELLOW 0.75). Not ochre and slate (0.16 apart): the critic scores
## luminance, and the fin flip has to carry.
const BLUE := Color(0.16, 0.36, 0.80)
const YELLOW := Color(0.92, 0.78, 0.18)
## The base, core and cap: a dark rail grey, so the core reads as a gap between
## coarse fins and as nothing at fine.
const RAIL_COLOR := Color(0.20, 0.20, 0.22)

# -- THE AXES ---------------------------------------------------------------------
## What a stripe is: painted on, or a two-faced fin. `shingle` is the default.
@export_enum("shingle", "fin") var face: String = "shingle"
## How many units round the drum: the speed of the flip, the distance of the fusion.
@export_enum("coarse", "medium", "fine") var grain: String = "coarse"

## The allow-lists, same spelling and same order as the @export_enum lines above.
## An unknown word warns and falls back to the DEFAULT, never to a bare core.
const FACES: PackedStringArray = ["shingle", "fin"]
const GRAINS: PackedStringArray = ["coarse", "medium", "fine"]
const DEFAULT_FACE := "shingle"
const DEFAULT_GRAIN := "coarse"
## N per grain word. Every value is even, so the alternation closes. If the Quest
## still separates the fine stripes at the south wall, fine becomes 288 (0.020 m).
const UNITS: Dictionary = {"coarse": 16, "medium": 48, "fine": 192}   # never from a token number

## One honest sentence per (face, grain), for the plate. The fusion sentence is
## display-limited on purpose: "from the far end of the hall", never Seurat.
const PLATE_SHINGLE := "Blue and yellow, painted on: walk round and the stripes stay where they are."
const PLATE_SHINGLE_FINE := "Painted on, but finer than the headset draws from the far end of the hall: there, blue and yellow are one grey."
const PLATE_FIN := "Blue on one face, yellow on the other: half the drum is blue, split on the fin facing you. Walk round it; the split walks with you. Turn around."
const PLATE_FIN_FINE := "Two solid halves, blue and yellow, and the seam is wherever you stand. Turn around."

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

	var n: int = int(UNITS.get(grain, UNITS[DEFAULT_GRAIN]))

	var body := StaticBody3D.new()
	body.name = "Body"

	# The three dark cylinders: the base disc on y = 0, the core, the cap disc.
	_add_mesh(_disc_mesh(BASE_R, DISC_H), Vector3(0.0, DISC_H * 0.5, 0.0), RAIL_COLOR, "Base")
	_add_mesh(_disc_mesh(CORE_R, UNIT_H), Vector3(0.0, DISC_H + UNIT_H * 0.5, 0.0), RAIL_COLOR, "Core")
	_add_mesh(_disc_mesh(BASE_R, DISC_H), Vector3(0.0, TOTAL_H - DISC_H * 0.5, 0.0), RAIL_COLOR, "Cap")

	match face:
		"fin":
			_build_fins(n)
		_:
			_build_shingles(n)

	# The body: one cylinder for the whole drum, from the same numbers as the base
	# and cap (no stripe or fin reaches the cap radius), and one box for the plate.
	_add_cylinder_shape(body, Vector3(0.0, TOTAL_H * 0.5, 0.0), BASE_R, TOTAL_H)
	_add_plate(body)
	add_child(body)


## N tangential stripes round the core, alternating BLUE / YELLOW. Each is a flat
## box tangent to the circle of radius STRIPE_R, its width the arc times 1.05 (the
## shipped Kras seam: adjacent stripes overlap a little at their edges).
## rotation.y = -a + PI/2 turns local +Z radial and local +X tangential.
func _build_shingles(n: int) -> void:
	var w: float = 2.0 * PI * STRIPE_R / float(n) * STRIPE_OVERLAP
	var stripe := BoxMesh.new()
	stripe.size = Vector3(w, UNIT_H, STRIPE_D)
	for i in range(n):
		var a: float = float(i) * 2.0 * PI / float(n)
		var c: Color = BLUE if i % 2 == 0 else YELLOW
		var mi: MeshInstance3D = _add_mesh(stripe,
			Vector3(STRIPE_R * cos(a), DISC_H + UNIT_H * 0.5, STRIPE_R * sin(a)), c,
			"Stripe_%d" % i)
		mi.rotation.y = -a + PI * 0.5


## N radial fins, each two thin boxes back to back at radius FIN_R: A stands
## +FIN_T/2 along the local tangent and is BLUE, B stands -FIN_T/2 and is YELLOW,
## so the +tangent face of the fin is blue and the -tangent face yellow. Under
## rotation.y = -a + PI/2 the local +X axis is the world tangent (sin a, 0, -cos a).
func _build_fins(n: int) -> void:
	var fin := BoxMesh.new()
	fin.size = Vector3(FIN_T, UNIT_H, FIN_D)
	var half: float = FIN_T * 0.5
	for i in range(n):
		var a: float = float(i) * 2.0 * PI / float(n)
		var centre := Vector3(FIN_R * cos(a), DISC_H + UNIT_H * 0.5, FIN_R * sin(a))
		var tangent := Vector3(sin(a), 0.0, -cos(a))
		var mi_a: MeshInstance3D = _add_mesh(fin, centre + tangent * half, BLUE, "Fin_%d_A" % i)
		mi_a.rotation.y = -a + PI * 0.5
		var mi_b: MeshInstance3D = _add_mesh(fin, centre - tangent * half, YELLOW, "Fin_%d_B" % i)
		mi_b.rotation.y = -a + PI * 0.5


## A flat cylinder, for the base, the core and the cap.
func _disc_mesh(r: float, h: float) -> Mesh:
	var cy := CylinderMesh.new()
	cy.top_radius = r
	cy.bottom_radius = r
	cy.height = h
	return cy


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


func _add_cylinder_shape(body: StaticBody3D, pos: Vector3, r: float, h: float) -> void:
	var shape := CollisionShape3D.new()
	var cyl := CylinderShape3D.new()
	cyl.radius = r
	cyl.height = h
	shape.shape = cyl
	shape.position = pos
	body.add_child(shape)


## The plate: text_screen.gd and nothing else, since it is the one text lane that
## renders in a capture. SCREEN mode (0) is the framed face alone - no floor post,
## no recline. Its back sits in the plane of the base's rim at reading height,
## and a dark mount runs from the drum's axis out to it so the plate is held
## rather than floating. Nothing is turned about Y: the face presents to +Z.
func _add_plate(body: StaticBody3D) -> void:
	var back_z: float = BASE_R + PLATE_GAP
	var mount_len: float = back_z + 0.001
	var mount := BoxMesh.new()
	mount.size = Vector3(MOUNT_SIDE, MOUNT_SIDE, mount_len)
	_add_mesh(mount, Vector3(0.0, PLATE_Y, mount_len * 0.5), MOUNT_COLOR, "PlateMount")

	var screen := TextScreenScript.new()
	screen.name = "Plate"
	screen.mode = 0
	screen.width_m = PLATE_W
	screen.title = _plate_title()
	screen.body = _plate_body()
	screen.position = Vector3(0.0, PLATE_Y, back_z + SCREEN_BACK)
	add_child(screen)

	# The plate is 0.936 x 0.594 m of visible object standing off the drum; a
	# visitor should not put a hand through it.
	var plate_h: float = PLATE_W * 0.62 + 0.036
	_add_box_shape(body, Vector3(0.0, PLATE_Y, back_z + 0.010),
		Vector3(PLATE_W + 0.036, plate_h, 0.020))


## "FIN <middle dot> MEDIUM": the two words in force, in caps, joined by U+00B7 (written as an escape so the source stays ASCII).
func _plate_title() -> String:
	return "%s \u00b7 %s" % [face.to_upper(), grain.to_upper()]


func _plate_body() -> String:
	if face == "fin":
		return PLATE_FIN_FINE if grain == "fine" else PLATE_FIN
	return PLATE_SHINGLE_FINE if grain == "fine" else PLATE_SHINGLE


# -- DNA plumbing -----------------------------------------------------------------

## Per-cell configuration, read from config_* metadata. Keys honoured:
##
##   #face:<shingle|fin>            what a stripe is
##   #grain:<coarse|medium|fine>    how many units round the drum
##
## Both values are WORDS, so neither key needs to sit in CONFIG_PARAM_NAMES: only a
## `#key:<number>` on an unlisted key is eaten as the tutorial's rotation shorthand.
## N is never read from a token number. An unknown word warns and falls back to
## the default.
func _read_meta_overrides() -> void:
	face = _axis_word("config_face", FACES, face, DEFAULT_FACE, "face")
	grain = _axis_word("config_grain", GRAINS, grain, DEFAULT_GRAIN, "grain")


func _axis_word(meta_key: String, allowed: PackedStringArray, current: String,
		fallback: String, axis: String) -> String:
	if not has_meta(meta_key):
		return current
	var v: String = str(get_meta(meta_key)).strip_edges().to_lower()
	if v == "":
		return current
	if allowed.has(v):
		return v
	push_warning("chroma_drum: unknown %s '%s' - using '%s'" % [axis, v, fallback])
	return fallback


## The grid's hook. Every key is stored as config_<key> metadata and re-read, so a
## value set here and a value stamped by the museum before _ready take the same
## path. Before the first build this only stores; after it, it rebuilds ONLY when
## one of the two words actually changed - curation_station's blanket
## apply_grid_config({"emissive": false}) must not rebuild a drum.
func apply_grid_config(config: Dictionary) -> void:
	var face_before: String = face
	var grain_before: String = grain
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return
	if face == face_before and grain == grain_before:
		return
	_build()
