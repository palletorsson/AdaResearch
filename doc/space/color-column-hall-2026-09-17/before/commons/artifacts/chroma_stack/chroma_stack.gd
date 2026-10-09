# @identity
# essence: a pillar-sized totem of five stacked primitives whose paint follows one of four rules - a coat, the shape's name, the height, or the neighbour below - so that one stack asks four times what a colour is attached to
# desire: that a visitor stand at the plate, read which two words are in force, look up the stack, and see whether the colour is telling them about the object, the kind, the place, or the company
# critical_parameter: rule, because it decides what the colour is a function OF. stack only changes what the rules have to answer about, and at rule one the three stacks are three ochre silhouettes
# triggers: _ready() reads config_rule / config_stack metadata, builds the five meshes, the plate and the body once. apply_grid_config rebuilds only when one of the two words actually changes
# emerges: under by_neighbour an alternation nobody typed - ochre, its complement, ochre again - and under by_height five hues that stay where they are when the shapes change alphabet
# needs: floor at y=0 under the origin [the grid provides it]; 4.4 m of headroom [the museum's halls have it]; a lit hall, since nothing here emits [the hall provides it]; a body approaching from +Z to read the plate [spatial_needs, player_position "front"]; apply_grid_config [present]
# relationships: the pillar-sized answer to dna_primitive_stack_ps01_bauhaus_totem_green, the 1x1x2-cell example standing in Color_Context_Placed. The still twin of chroma_translation, which takes this stack's by_shape colours and moves them. Kandinsky's 1923 Bauhaus questionnaire for the by_shape assignment, Siedhoff-Buscher's Bauspiel (1923) for the bauhaus alphabet
# truth: a colour value is not a property of a thing until a rule says which thing. The same five solids take one ochre under `one`, and under `by_neighbour` the second and fourth turn slate blue without a vertex moving. The colour was never in the shape; it was in the relation the rule chose to read

extends Node3D
class_name ChromaStack

## CHROMA_STACK -- primitives x colour, at pillar scale and larger.
##
## Color_Context_Placed's sequence truth is that a colour value enters an encounter:
## a light, a surface, a position, a neighbour and a viewer. This object holds the
## light, the surfaces and the viewer still and lets ONE word decide which of the
## rest the colour answers to. Five solids are stacked into a 4.4 m totem, and the
## paint on them follows `rule`:
##
##   one           every element the same ochre. Colour attached to nothing but the
##                 object: a coat.
##   by_shape      colour names the KIND, after the questionnaire Kandinsky ran at the
##                 Bauhaus in 1923: circle blue, square red, triangle yellow. Turned
##                 kinds (cylinder, torus, capsule) get a grey-green. Two boxes at
##                 different heights share a colour; the sphere is blue wherever it
##                 stands.
##   by_height     colour reads POSITION: a hue ramp from blue at the floor to orange
##                 at the top, sampled at each element's centre height.
##   by_neighbour  colour is a RELATION: the base takes the ochre and every element
##                 above takes the complement of the one below, so it alternates.
##                 This is the chapter's "a colour with company".
##
## `stack` chooses the alphabet the rules have to answer about, bottom to top:
##
##   bauhaus   cuboid, cube, sphere, block, dome       (Siedhoff-Buscher, Bauspiel)
##   turned    cylinder, cylinder, torus, capsule, cone (lathe shapes)
##   cut       box, wedge, box, wedge, box              (cut shapes)
##
## Shape KIND is what the rules read: sphere and dome are "circle", box and cube are
## "square", cone and wedge are "triangle", cylinder, torus and capsule are "turned".
##
## THE STACK, in metres. A broad base 1.10 wide and 0.60 tall, then four levels of
## 0.95 each: 4.40 m in all, against the museum pillar's 4.00. Every stack uses the
## SAME level heights, so under by_height the five hues are identical across the
## three alphabets and a sweep of `stack` photographs shape and nothing else.
## Widths taper from 1.10 at the base to 0.75-0.85 at the top.
##
## Two places where the alphabet bent to the level grid, both deliberate:
##   - the bauhaus dome is a SphereMesh hemisphere stretched to the 0.95 level. A
##     true hemisphere at 0.85 wide would be 0.425 tall and the totem 3.9 m.
##   - the torus stands on edge, so its level is also 0.95. Lying flat, a torus of
##     this width can be at most 0.475 tall (outer radius minus a zero hole).
##
## THE PLATE. One text_screen in SCREEN mode (the framed face alone, no post) on the
## +Z side at 1.20 m, 0.90 wide, held by a short dark mount out of the stack's axis,
## its back in the plane of the base's +Z face. Title = the two words in force, body
## = one sentence about the rule. It faces +Z and is never turned about Y. Rebuilt
## with everything else on every rebuild.
##
## NO RANDOMNESS anywhere, so a sweep photographs the axis and nothing else. Built-in
## meshes only. No emission (it cannot make a dark thing glow and it hides the hue).
##
## ARITHMETIC, not renders (the session that wrote this did not run Godot):
##   ochre (0.78, 0.60, 0.30) is HSV (0.104, 0.615, 0.78); its complement is HSV
##   (0.604, 0.615, 0.78) = RGB (0.30, 0.48, 0.78), a slate blue, and the complement
##   of THAT is the ochre again, so by_neighbour alternates ochre / slate / ochre /
##   slate / ochre. by_height samples the ramp at centre heights 0.30, 1.075, 2.025,
##   2.975 and 3.925 m: hues 0.583, 0.488, 0.372, 0.255 and 0.138.
##   Predicted closest pair on `rule` (bauhaus): one vs by_neighbour - only the cube
##   and the block change, ochre to slate, about 46% of the front-projected subject
##   (0.90 + 0.81 of about 3.7 m^2). On `stack` (rule one): bauhaus vs cut, which
##   share the base and the level widths, so only silhouettes differ - roughly a
##   quarter of the subject. Both are lower bounds; a sweep that lands BELOW them
##   is broken, not subtle.
##
## NOT COMPILED OR CAPTURED in the session that wrote it. The lead compiles and
## captures every artifact of the pass in one boot afterwards.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# -- The stack, in metres. EVERYTHING SITS ABOVE y = 0. ------------------------
# The origin is the base. The bottom element's underside is at y = 0 exactly, so
# a map token with an explicit y (where auto-grounding is skipped) still stands
# the totem on the floor rather than half through it.
const BASE_W := 1.10          ## the broad base, and the widest thing here
const BASE_H := 0.60
const LEVEL_H := 0.95         ## each of the four levels above the base
const TOTAL_H := BASE_H + 4.0 * LEVEL_H
const TORUS_TUBE := 0.15      ## tube radius of the standing ring; the hole is what is left
const ROUGHNESS := 0.55       ## one roughness for every surface, so only hue differs

# -- The plate ------------------------------------------------------------------
const PLATE_W := 0.90
const PLATE_Y := 1.20         ## reading height; text_screen's own stand default is 1.15
const PLATE_GAP := 0.001      ## between the base's +Z face plane and the frame's back
const SCREEN_BACK := 0.014    ## text_screen SCREEN: frame centred at z -0.008, 12 mm deep
const MOUNT_SIDE := 0.08      ## the dark bar that holds the plate off the stack
const MOUNT_COLOR := Color(0.20, 0.22, 0.27)

# -- The colour vocabulary --------------------------------------------------------
## Kandinsky's assignment: circle blue, square red, triangle yellow.
const BLUE := Color(0.16, 0.36, 0.80)
const RED := Color(0.80, 0.16, 0.16)
const YELLOW := Color(0.92, 0.78, 0.18)
## Lathe shapes had no seat in the questionnaire; they get a grey-green.
const GREY_GREEN := Color(0.45, 0.52, 0.48)
## The single coat for rule `one`, and the base's colour under `by_neighbour`.
const OCHRE := Color(0.78, 0.60, 0.30)
## The height ramp: HSV hue from 0.62 (blue) at the floor to 0.08 (orange) at the
## top, at one saturation and one value so only the hue carries the number.
const RAMP_H0 := 0.62
const RAMP_H1 := 0.08
const RAMP_S := 0.75
const RAMP_V := 0.85
const KIND_COLOR: Dictionary = {
	"circle": BLUE,
	"square": RED,
	"triangle": YELLOW,
	"turned": GREY_GREEN,
}

# -- THE AXES ---------------------------------------------------------------------
## What the colour is a function of. `one` is the default: a coat.
@export_enum("one", "by_shape", "by_height", "by_neighbour") var rule: String = "one"
## Which alphabet of five solids the rule has to answer about.
@export_enum("bauhaus", "turned", "cut") var stack: String = "bauhaus"

## The allow-lists, same spelling and same order as the @export_enum lines above.
## An unknown word warns and falls back to the DEFAULT, never to a blank stack.
const RULES: PackedStringArray = ["one", "by_shape", "by_height", "by_neighbour"]
const STACK_NAMES: PackedStringArray = ["bauhaus", "turned", "cut"]
const DEFAULT_RULE := "one"
const DEFAULT_STACK := "bauhaus"

## The alphabets, bottom to top. `w` is the element's width across X and Z; the
## height comes from the level (BASE_H for index 0, LEVEL_H above). `kind` is what
## the colour rules read.
const STACKS: Dictionary = {
	"bauhaus": [
		{"shape": "box", "kind": "square", "w": 1.10},
		{"shape": "box", "kind": "square", "w": 0.95},
		{"shape": "sphere", "kind": "circle", "w": 0.95},
		{"shape": "box", "kind": "square", "w": 0.85},
		{"shape": "dome", "kind": "circle", "w": 0.85},
	],
	"turned": [
		{"shape": "cylinder", "kind": "turned", "w": 1.10},
		{"shape": "cylinder", "kind": "turned", "w": 0.95},
		{"shape": "torus", "kind": "turned", "w": 0.95},
		{"shape": "capsule", "kind": "turned", "w": 0.80},
		{"shape": "cone", "kind": "triangle", "w": 0.75},
	],
	"cut": [
		{"shape": "box", "kind": "square", "w": 1.10},
		{"shape": "wedge", "kind": "triangle", "w": 0.95},
		{"shape": "box", "kind": "square", "w": 0.90},
		{"shape": "wedge", "kind": "triangle", "w": 0.85},
		{"shape": "box", "kind": "square", "w": 0.80},
	],
}

## One honest sentence per rule, for the plate.
const PLATE_BODY: Dictionary = {
	"one": "one colour, five shapes: the paint knows nothing about the form",
	"by_shape": "circle blue, square red, triangle yellow: the colour names the kind",
	"by_height": "the colour reads the height: a position, not a shape",
	"by_neighbour": "each colour is the complement of the one below: a colour with company",
}

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

	var elements: Array = STACKS.get(stack, STACKS[DEFAULT_STACK])
	var colours: Array = _colours_for(elements)

	var body := StaticBody3D.new()
	body.name = "Body"

	var y0: float = 0.0
	for i in range(elements.size()):
		var e: Dictionary = elements[i]
		var shape: String = str(e["shape"])
		var w: float = float(e["w"])
		var h: float = _level_height(i)
		var c: Color = colours[i]
		var mi: MeshInstance3D = _add_mesh(_element_mesh(shape, w, h),
			Vector3(0.0, y0 + _origin_lift(shape, h), 0.0), c,
			"Element_%d_%s" % [i, shape])
		if shape == "torus":
			# TorusMesh lies in XZ round the Y axis. Stood on edge (the ring in the
			# XY plane, its hole facing +Z like the plate) it fills the 0.95 level;
			# flat, at this width, it could be at most 0.475 tall.
			mi.rotation.x = PI * 0.5
		# The body: one box per element, from the same numbers as the mesh.
		_add_box_shape(body, Vector3(0.0, y0 + h * 0.5, 0.0),
			Vector3(w, h, _depth_of(shape, w)))
		y0 += h

	_add_plate(body)
	add_child(body)


## The element's height: the base is 0.60, every level above it 0.95.
func _level_height(i: int) -> float:
	return BASE_H if i == 0 else LEVEL_H


## Where the mesh's origin sits relative to the element's underside. Every built-in
## mesh is centred on its origin except a hemisphere, whose flat cap IS y = 0.
func _origin_lift(shape: String, h: float) -> float:
	return 0.0 if shape == "dome" else h * 0.5


## Depth along Z. Every element is as deep as it is wide except the standing ring.
func _depth_of(shape: String, w: float) -> float:
	return 2.0 * TORUS_TUBE if shape == "torus" else w


## Built-in meshes only. A cone is a cylinder with no top; a wedge is a PrismMesh
## with its ridge along Z, so the triangle faces the plate side and the camera.
func _element_mesh(shape: String, w: float, h: float) -> Mesh:
	var r: float = w * 0.5
	match shape:
		"box":
			var b := BoxMesh.new()
			b.size = Vector3(w, h, w)
			return b
		"sphere":
			var s := SphereMesh.new()
			s.radius = r
			s.height = h
			return s
		"dome":
			var d := SphereMesh.new()
			d.radius = r
			d.height = h
			d.is_hemisphere = true
			return d
		"cylinder":
			var cy := CylinderMesh.new()
			cy.top_radius = r
			cy.bottom_radius = r
			cy.height = h
			return cy
		"cone":
			var co := CylinderMesh.new()
			co.top_radius = 0.0
			co.bottom_radius = r
			co.height = h
			return co
		"capsule":
			var ca := CapsuleMesh.new()
			ca.radius = r
			ca.height = h
			return ca
		"torus":
			var t := TorusMesh.new()
			t.outer_radius = r
			t.inner_radius = r - 2.0 * TORUS_TUBE
			return t
		"wedge":
			var p := PrismMesh.new()
			p.size = Vector3(w, h, w)
			p.left_to_right = 0.5
			return p
	push_warning("chroma_stack: unknown shape '%s' - building a box" % shape)
	var fallback := BoxMesh.new()
	fallback.size = Vector3(w, h, w)
	return fallback


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


## The plate: text_screen.gd and nothing else, since it is the one text lane that
## renders in a capture. SCREEN mode (0) is the framed face alone - no floor post,
## no recline. Its back sits in the plane of the base's +Z face at reading height,
## and a short dark mount runs from the stack's axis out to it so the plate is
## held rather than floating. Nothing is turned about Y: the face presents to +Z.
func _add_plate(body: StaticBody3D) -> void:
	var back_z: float = BASE_W * 0.5 + PLATE_GAP
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

	# The plate is 0.936 x 0.594 m of visible object standing off the stack; a
	# visitor should not put a hand through it.
	var plate_h: float = PLATE_W * 0.62 + 0.036
	_add_box_shape(body, Vector3(0.0, PLATE_Y, back_z + 0.010),
		Vector3(PLATE_W + 0.036, plate_h, 0.020))


## "BY NEIGHBOUR <middle dot> BAUHAUS": the two words in force, in caps, joined by U+00B7 (written as an escape so the source stays ASCII).
func _plate_title() -> String:
	return "%s \u00b7 %s" % [rule.replace("_", " ").to_upper(), stack.to_upper()]


func _plate_body() -> String:
	return str(PLATE_BODY.get(rule, PLATE_BODY[DEFAULT_RULE]))


# -- the rules ------------------------------------------------------------------

## One colour per element, bottom to top, from `rule` and nothing else.
func _colours_for(elements: Array) -> Array:
	var out: Array = []
	var y0: float = 0.0
	var below: Color = OCHRE
	for i in range(elements.size()):
		var h: float = _level_height(i)
		var kind: String = str(elements[i]["kind"])
		var c: Color = OCHRE
		match rule:
			"one":
				c = OCHRE
			"by_shape":
				c = KIND_COLOR.get(kind, OCHRE)
			"by_height":
				c = _ramp((y0 + h * 0.5) / TOTAL_H)
			"by_neighbour":
				c = OCHRE if i == 0 else _complement(below)
			_:
				c = OCHRE
		out.append(c)
		below = c
		y0 += h
	return out


## The ramp is a property of SPACE, not of the stack: 0 m is blue, TOTAL_H is
## orange, and an element samples it at its centre height.
func _ramp(t: float) -> Color:
	var hue: float = lerpf(RAMP_H0, RAMP_H1, clampf(t, 0.0, 1.0))
	return Color.from_hsv(hue, RAMP_S, RAMP_V, 1.0)


## Complement of (h, s, v) = ((h + 0.5) mod 1, s, v). Applied twice it returns the
## colour it was given, which is why by_neighbour alternates rather than drifts.
func _complement(c: Color) -> Color:
	return Color.from_hsv(fposmod(c.h + 0.5, 1.0), c.s, c.v, 1.0)


# -- DNA plumbing -----------------------------------------------------------------

## Per-cell configuration, read from config_* metadata. Keys honoured:
##
##   #rule:<one|by_shape|by_height|by_neighbour>   what the colour is a function of
##   #stack:<bauhaus|turned|cut>                   the alphabet of five solids
##
## Both values are WORDS, so neither key needs to sit in CONFIG_PARAM_NAMES: only a
## `#key:<number>` on an unlisted key is eaten as the tutorial's rotation shorthand.
## An unknown word warns and falls back to the default.
func _read_meta_overrides() -> void:
	rule = _axis_word("config_rule", RULES, rule, DEFAULT_RULE, "rule")
	stack = _axis_word("config_stack", STACK_NAMES, stack, DEFAULT_STACK, "stack")


func _axis_word(meta_key: String, allowed: PackedStringArray, current: String,
		fallback: String, axis: String) -> String:
	if not has_meta(meta_key):
		return current
	var v: String = str(get_meta(meta_key)).strip_edges().to_lower()
	if v == "":
		return current
	if allowed.has(v):
		return v
	push_warning("chroma_stack: unknown %s '%s' - using '%s'" % [axis, v, fallback])
	return fallback


## The grid's hook. Every key is stored as config_<key> metadata and re-read, so a
## value set here and a value stamped by the museum before _ready take the same
## path. Before the first build this only stores; after it, it rebuilds ONLY when
## one of the two words actually changed - curation_station's blanket
## apply_grid_config({"emissive": false}) must not rebuild a stack.
func apply_grid_config(config: Dictionary) -> void:
	var rule_before: String = rule
	var stack_before: String = stack
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return
	if rule == rule_before and stack == stack_before:
		return
	_build()
