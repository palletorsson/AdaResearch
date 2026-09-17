# @identity
# essence: one five-piece Bauhaus stack, 4.4 m tall on a 1.1 m base, standing where it was put and again three times over along one direction of the floor - a translation held still in a hall, with a colour rule deciding whether the colour went with the shapes or stayed behind with the position
# desire: that a visitor walk the row, find every copy the same five shapes in the same order, and only then ask why the second one is not the same colour as the first - or why it is
# critical_parameter: colour_by. `along` only says where the copies went; `colour_by` says what the colour was attached to - the shape (kept), the place the copy now stands (distance) or the number of moves it took to get there (step). The stacks are byte-identical geometry under all three
# triggers: _ready() reads config_along and config_colour_by, builds the original and its copies, a floor rail (a post for y), one plate and one collider box per copy. Nothing moves afterwards and nothing is drawn at random: the same two words give the same picture every time
# emerges: that translation preserves colour only under a rule that says so. Under kept the row is one thing repeated; under distance it is a gradient that happens to be made of stacks; under step it is a count written in paint
# needs: floor at y=0 [the grid provides it]; 4.85 m of clear floor in +x, +z or 4.9 m on the diagonal, or 8.85 m of headroom for y [size_group large, footprint 6 x 2 x 5]; a lit hall [the hall provides it]; apply_grid_config [present]
# relationships: the translation half of the pair asked for on 2026-09-17 for Color_Context_Placed - chroma_stack (primitives x colour) argues a colour rule inside ONE stack; this asks what any such rule does once the stack moves. Its stack is chroma_stack's bauhaus alphabet at rule by_shape, rebuilt here from the shared numbers rather than imported. axis_translation_cube in the transformation halls animates the same operation on a 0.15 m cube with a rail and ghost trail; this holds it still at 4.4 m with a rail and solid copies
# truth: a translation moves every point by one vector and touches nothing else - position is the ONLY thing it changes. Whether a colour survives it is therefore not a fact about translation; it is a fact about what the colour was attached to. Attached to the shape, it rides along. Attached to the position, it cannot, because the position is exactly what was given up

extends Node3D
class_name ChromaTranslation

## CHROMA_TRANSLATION - primitives x colour x translation, for the first colour hall.
##
## The sequence's truth for Color_Context_Placed is that a colour value enters an
## encounter: a light, a surface, a position, a neighbour, a viewer. This object takes
## ONE of those companions - position - and moves it. A five-piece Bauhaus stack
## (after Siedhoff-Buscher's Bauspiel of 1923: a broad base, a cube, a sphere, a cube,
## a dome) stands at the origin and again as three solid copies, each one step of
## 1.25 m further along the floor. Every copy is the same five meshes at the same five
## heights. What the row argues is decided by two words:
##
##   along      x | y | z | diagonal - where the copies went. For y the copies stack
##              upward, each base on the previous top plus 50 mm, and the run is capped
##              at TWO copies so the tower stays under 9.5 m in an 8 m hall.
##   colour_by  kept | distance | step - what the colour was attached to.
##              kept:      Kandinsky's 1923 assignment, circle blue / square red, on
##                         every copy. Translation preserved the colour because the
##                         colour was a property of the shape. The control.
##              distance:  one hue per copy from a ramp on the copy's displacement -
##                         blue at the origin, orange at the farthest copy. The colour
##                         is a function of position, so a moved copy cannot keep it.
##              step:      the copy's index picks ochre, blue, red, yellow. The colour
##                         counts the moves.
##
## The translation is DRAWN, not animated: a 50 mm rail on the floor runs beside the
## row from the origin to the last copy (a post for y). A plate on the +Z face of the
## front-most copy names the two axis values and says in one sentence what the rule did.
##
## BUILT FROM THE SPEC of 2026-09-17 (scratchpad chroma_spec.md). NOT COMPILED AND NOT
## CAPTURED in the session that wrote it - the lead compiles and captures every
## artifact in one boot afterwards. The extents quoted in the registry are arithmetic
## from the constants below, checked in a Python mirror, not renders.

const TextScreenScript := preload("res://commons/ui/text_screen.gd")

# -- The stack, in metres. EVERYTHING SITS ABOVE y = 0. -----------------------
# The origin is the base. Every copy's base is on y = 0 too, except along = y,
# where each copy's base sits 50 mm above the previous copy's top.
## The broad base: 1.1 m square, 0.6 m tall, and the widest thing here.
const BASE_W := 1.1
const BASE_H := 0.6
## The four pieces above it, all narrower than the base and 0.95 m tall each:
## 0.6 + 4 * 0.95 = 4.4 m.
const ELEM_W := 0.95
const ELEM_H := 0.95
const STACK_H := BASE_H + 4.0 * ELEM_H

## The bauhaus alphabet, bottom to top. `kind` is what a colour rule reads - the
## sphere and the dome are "circle", every box is "square" - and it is the only thing
## the colour code knows about a piece. The dome is SphereMesh's hemisphere at radius
## 0.475 and height 0.95: a half-ellipsoid rather than a half-sphere, so that it is
## 0.95 m tall like its neighbours and still no wider than them. A true hemisphere
## 0.95 m tall would be 1.9 m wide, wider than the base.
const ALPHABET: Array = [
	{"name": "Base", "shape": "box", "kind": "square", "w": BASE_W, "h": BASE_H},
	{"name": "Cube_1", "shape": "box", "kind": "square", "w": ELEM_W, "h": ELEM_H},
	{"name": "Sphere", "shape": "sphere", "kind": "circle", "w": ELEM_W, "h": ELEM_H},
	{"name": "Cube_2", "shape": "box", "kind": "square", "w": ELEM_W, "h": ELEM_H},
	{"name": "Dome", "shape": "hemisphere", "kind": "circle", "w": ELEM_W, "h": ELEM_H},
]

# -- The translation ----------------------------------------------------------
## One step along the floor.
const STEP_M := 1.25
## The original and three copies.
const COPIES := 4
## The original and ONE copy for along = y: the tower tops out at 8.85 m, under the
## 9.5 m the spec allows in an 8 m hall. A third copy would reach 13.3 m.
const COPIES_UP := 2
## Daylight between a copy's top and the next one's base.
const Y_GAP := 0.05
## The rail and the post are 50 mm square in section.
const RAIL_T := 0.05
## The rail runs BESIDE the bases, not through them: with 1.25 m steps and 1.1 m
## bases only 0.15 m of a rail down the centre line would ever show. 20 mm off the
## face.
const RAIL_CLEAR := 0.02

# -- The plate ----------------------------------------------------------------
## Screen centre. The base is 0.6 m tall, so 1.2 m is on the +Z face of the cube
## above it, 0.95 m wide against the screen's 0.936 m frame; the plate spans
## 0.90-1.50 m.
const PLATE_Y := 1.2
const PLATE_W := 0.9
## The frame's back face is 14 mm behind the node, so 20 mm leaves 6 mm of air
## between it and the cube face.
const PLATE_GAP := 0.02

# -- Colour vocabulary (shared with chroma_stack) ------------------------------
## Kandinsky's Bauhaus questionnaire of 1923: circle blue, square red, triangle
## yellow. Turned shapes (cylinder, torus, capsule) take a grey-green; this alphabet
## has none, so that entry is here for the shared vocabulary and is never drawn.
const BLUE := Color(0.16, 0.36, 0.80)
const RED := Color(0.80, 0.16, 0.16)
const YELLOW := Color(0.92, 0.78, 0.18)
const GREY_GREEN := Color(0.45, 0.52, 0.48)
const OCHRE := Color(0.78, 0.60, 0.30)
## The rail and the post: dark, neutral, none of the palette - a drawing of the
## operation, not a coloured thing.
const RAIL_COLOR := Color(0.20, 0.20, 0.22)
## The hue ramp for `distance`: HSV hue from blue at the origin to orange at the
## farthest copy, at one saturation and one value, so only the hue moves.
const RAMP_HUE_NEAR := 0.62
const RAMP_HUE_FAR := 0.08
const RAMP_S := 0.75
const RAMP_V := 0.85

@export_category("Axes")
## ALONG - where the copies went.
##   x         three copies at 1.25, 2.5 and 3.75 m in +x. THE DEFAULT.
##   y         ONE copy, its base 50 mm above the original's top (a step of 4.45 m).
##             Capped at two copies so the tower tops out at 8.85 m; the plate says so.
##   z         as x, in +z.
##   diagonal  steps of (1.25, 0, 1.25): the same three copies, 1.77 m apart.
## Every copy keeps the original's y = 0 base except y.
@export_enum("x", "y", "z", "diagonal") var along: String = "x"
const ALONGS: PackedStringArray = ["x", "y", "z", "diagonal"]
const ALONG_DEFAULT := "x"

## COLOUR_BY - what the colour was attached to.
##   kept      every copy keeps the original's by-shape colours: circle blue, square
##             red. THE DEFAULT, and the control: translation preserves colour.
##   distance  one hue per copy from the ramp on its displacement: blue at 0, orange
##             at the farthest copy (3.75 m on an axis). Colour as a function of
##             position, so the moved copy is a different colour.
##   step      copy 0..3 painted ochre, blue, red, yellow. Colour counts the step.
@export_enum("kept", "distance", "step") var colour_by: String = "kept"
const COLOUR_BYS: PackedStringArray = ["kept", "distance", "step"]
const COLOUR_BY_DEFAULT := "kept"

## True once _ready has built once. apply_grid_config only stores until then.
var _built: bool = false


func _ready() -> void:
	# The museum stamps config_* metadata on the root BEFORE it is in the tree, and the
	# grid sets it synchronously before add_child and calls apply_grid_config deferred,
	# i.e. after this. So the meta is read here, before a single mesh exists.
	_read_meta_overrides()
	_build()
	_built = true


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var n: int = _copy_count()
	var step: Vector3 = _step_vector()
	var far: float = (step * float(n - 1)).length()

	var body := StaticBody3D.new()
	body.name = "Body"
	for i in range(n):
		var d: Vector3 = step * float(i)
		var copy := Node3D.new()
		copy.name = "Copy_%d" % i
		copy.position = d
		_build_stack(copy, i, d.length(), far)
		add_child(copy)
		# ONE BOX PER COPY, from the same numbers as the meshes: the base's square and
		# the stack's full height. The four pieces above the base sit 75 mm inside it
		# on every side, so the box is the base's footprint carried up to the top.
		var shape := CollisionShape3D.new()
		shape.name = "Copy_%d_Box" % i
		var box := BoxShape3D.new()
		box.size = Vector3(BASE_W, STACK_H, BASE_W)
		shape.shape = box
		shape.position = d + Vector3(0.0, STACK_H * 0.5, 0.0)
		body.add_child(shape)
	add_child(body)

	_build_rail(step, n)
	_build_plate(step, n)


## The five pieces, bottom to top, each one's base on the previous one's top. The
## first base is on y = 0, which is the origin - so the copy node's own position is
## the only thing that ever lifts a stack, and only along = y sets a y there.
func _build_stack(parent: Node3D, index: int, dist: float, far: float) -> void:
	var y: float = 0.0
	for e in ALPHABET:
		var piece_name: String = e["name"]
		var shape: String = e["shape"]
		var kind: String = e["kind"]
		var w: float = e["w"]
		var h: float = e["h"]
		var mesh: Mesh = null
		var at_y: float = y + h * 0.5
		match shape:
			"sphere":
				var sph := SphereMesh.new()
				sph.radius = w * 0.5
				sph.height = h
				mesh = sph
			"hemisphere":
				# SphereMesh's hemisphere spans local y in [0, height] with its flat
				# face at 0, so the node sits ON the piece below, not half inside it.
				var dome := SphereMesh.new()
				dome.radius = w * 0.5
				dome.height = h
				dome.is_hemisphere = true
				mesh = dome
				at_y = y
			_:
				var box := BoxMesh.new()
				box.size = Vector3(w, h, w)
				mesh = box
		_add_mesh(parent, piece_name, mesh, Vector3(0.0, at_y, 0.0),
			_element_colour(kind, index, dist, far))
		y += h


## The operation, drawn. A 50 mm rail on the floor beside the row, from the origin's
## centre line to the last copy's; for y a 50 mm post beside the +X face, from the
## floor to the copy's base plane. Beside, not under: 1.1 m bases at 1.25 m steps
## would swallow all but 0.15 m of a rail down the centre line.
func _build_rail(step: Vector3, n: int) -> void:
	var span: Vector3 = step * float(n - 1)
	var length: float = span.length()
	if along == "y":
		var post := BoxMesh.new()
		post.size = Vector3(RAIL_T, length, RAIL_T)
		_add_mesh(self, "Post", post,
			Vector3(BASE_W * 0.5 + RAIL_CLEAR + RAIL_T * 0.5, length * 0.5, 0.0), RAIL_COLOR)
		return
	var dir: Vector3 = span.normalized()
	# The side the rail lies on: +Z for x, +X for z, and the (-X, +Z) side for the
	# diagonal - in each case the side that faces the canonical capture camera, which
	# stands to the front-right. The base is a square, so its half-extent along any
	# floor direction s is half its side times (|s.x| + |s.z|): 0.55 m on an axis,
	# 0.778 m on the diagonal.
	var side := Vector3(0.0, 0.0, 1.0)
	match along:
		"z":
			side = Vector3(1.0, 0.0, 0.0)
		"diagonal":
			side = Vector3(-1.0, 0.0, 1.0).normalized()
	var reach: float = BASE_W * 0.5 * (absf(side.x) + absf(side.z)) + RAIL_CLEAR + RAIL_T * 0.5
	var rail := BoxMesh.new()
	rail.size = Vector3(length, RAIL_T, RAIL_T)
	var mi: MeshInstance3D = _add_mesh(self, "Rail", rail,
		span * 0.5 + side * reach + Vector3(0.0, RAIL_T * 0.5, 0.0), RAIL_COLOR)
	# Rotation about +Y maps local +X to (cos t, 0, -sin t), so aligning the box's long
	# axis with (dir.x, dir.z) needs t = atan2(-dir.z, dir.x).
	mi.rotation = Vector3(0.0, atan2(-dir.z, dir.x), 0.0)


## One plate, text_screen.gd and nothing else - Label3D and baked-albedo quads both
## photograph blank in this project's capture. SCREEN is the framed face alone: no
## post, no pad. It presents toward +Z and is not turned, because an artifact that
## faces its text away from +Z photographs bare.
##
## It hangs on the +Z face of the FRONT-MOST copy. For x and y that is the original;
## for z and the diagonal the run itself goes +Z, and the copies would stand squarely
## in front of a plate on the original, so the plate goes to the copy nearest the
## viewer instead.
func _build_plate(step: Vector3, n: int) -> void:
	var host: Vector3 = Vector3.ZERO
	if step.z > 0.0:
		host = step * float(n - 1)
	var screen := TextScreenScript.new()
	screen.name = "Plate"
	screen.mode = 0                    # TextScreen.Mode.SCREEN
	screen.width_m = PLATE_W
	screen.title = _plate_title()
	screen.body = _plate_body()
	screen.position = host + Vector3(0.0, PLATE_Y, ELEM_W * 0.5 + PLATE_GAP)
	add_child(screen)


## "ALONG X . COLOUR KEPT" - the two axis values in caps, joined by a middle dot
## written as its escape so the source stays ASCII.
func _plate_title() -> String:
	var rule: String = "COLOUR KEPT"
	match colour_by:
		"distance":
			rule = "COLOUR BY DISTANCE"
		"step":
			rule = "COLOUR BY STEP"
	return "ALONG " + along.to_upper() + " \u00b7 " + rule


## One honest sentence about what the rule did; along = y adds the cap, because a
## visitor who counts two stacks where the plate promised three has been lied to.
func _plate_body() -> String:
	var moved: String = "moved three times"
	if along == "y":
		moved = "moved once, upward"
	var claim: String = "the colours moved with the shapes"
	match colour_by:
		"distance":
			claim = "the colour reads how far"
		"step":
			claim = "the colour counts the step"
	var text: String = moved + ": " + claim
	if along == "y":
		text += "\ntwo copies only: the hall is eight metres tall"
	return text


# -- Colour ---------------------------------------------------------------------

## What a piece is painted. `kept` asks the piece what it is; `distance` asks the copy
## where it stands; `step` asks the copy how many moves it has made. Only the first
## ever looks at the shape - under the other two a whole copy is one colour.
func _element_colour(kind: String, index: int, dist: float, far: float) -> Color:
	match colour_by:
		"distance":
			var t: float = 0.0
			if far > 0.0001:
				t = clampf(dist / far, 0.0, 1.0)
			return Color.from_hsv(lerpf(RAMP_HUE_NEAR, RAMP_HUE_FAR, t), RAMP_S, RAMP_V, 1.0)
		"step":
			return _step_colour(index)
		_:
			return _kind_colour(kind)


## Kandinsky's assignment, by KIND - the same word chroma_stack reads.
func _kind_colour(kind: String) -> Color:
	match kind:
		"circle":
			return BLUE
		"square":
			return RED
		"triangle":
			return YELLOW
		_:
			return GREY_GREEN


## The step palette: ochre, blue, red, yellow for copies 0..3.
func _step_colour(index: int) -> Color:
	match index:
		1:
			return BLUE
		2:
			return RED
		3:
			return YELLOW
		_:
			return OCHRE


# -- Geometry helpers -----------------------------------------------------------

func _copy_count() -> int:
	if along == "y":
		return COPIES_UP
	return COPIES


func _step_vector() -> Vector3:
	match along:
		"y":
			return Vector3(0.0, STACK_H + Y_GAP, 0.0)
		"z":
			return Vector3(0.0, 0.0, STEP_M)
		"diagonal":
			return Vector3(STEP_M, 0.0, STEP_M)
		_:
			return Vector3(STEP_M, 0.0, 0.0)


## MeshInstance3D + StandardMaterial3D as a SURFACE override, not material_override.
## Matte, no metal, no emission: emission cannot make a dark thing glow, and it hides
## the hue, and the hue is the whole subject.
func _add_mesh(parent: Node3D, node_name: String, mesh: Mesh, at: Vector3, colour: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = node_name
	mi.mesh = mesh
	mi.position = at
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.metallic = 0.0
	m.roughness = 0.55
	mi.set_surface_override_material(0, m)
	parent.add_child(mi)
	return mi


# -- DNA plumbing ---------------------------------------------------------------

## The two axes, from the map's config_<key> metadata. An unknown word falls back to
## the DEFAULT with a warning rather than to whatever was there, so a typo on a map
## token is a visible default and never a silent variant.
func _read_meta_overrides() -> void:
	along = _read_word("config_along", ALONGS, ALONG_DEFAULT, along)
	colour_by = _read_word("config_colour_by", COLOUR_BYS, COLOUR_BY_DEFAULT, colour_by)


func _read_word(meta_key: String, allowed: PackedStringArray, fallback: String, current: String) -> String:
	if not has_meta(meta_key):
		return current
	var v: String = str(get_meta(meta_key)).strip_edges().to_lower()
	if allowed.has(v):
		return v
	push_warning("chroma_translation: unknown %s '%s' - falling back to '%s'"
		% [meta_key.trim_prefix("config_"), v, fallback])
	return fallback


## Config from a map token, e.g. `#along:diagonal #colour_by:step`. Both keys take
## WORDS only: a numeric value on an unlisted key is read by the grid as the tutorial's
## rotation shorthand before it could ever reach here.
##
## Guarded like ProfileRandom's: each key is stored as config_<key> meta and re-read,
## and the row is rebuilt ONLY IF A VALUE CHANGED - so the grid's deferred call after
## _ready, which carries the same words _ready already read, touches nothing, and
## curation_station's blanket apply_grid_config({"emissive": false}) cannot trigger a
## rebuild. Before _ready has built (the museum stamps config on a root still outside
## the tree) it only stores; _ready reads.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var was_along: String = along
	var was_colour_by: String = colour_by
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	_read_meta_overrides()
	if not _built:
		return
	if along == was_along and colour_by == was_colour_by:
		return
	_build()
