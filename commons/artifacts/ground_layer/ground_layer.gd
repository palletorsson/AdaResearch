extends Node3D
class_name GroundLayer

## ground_layer — a ground is a layer chosen for what will be put ON it, and the family it
## comes from never puts anything on it.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## THE FAMILY, AND WHY IT IS NOT ONE.
##
## Two registry tokens declare an axis called `priming` with identical values
## (white | ochre | bole | verdaccio): `ball_painting_demo` and `drawing_paper`. The brief
## for this bench asked whether the two members agree about what the word means. They
## cannot disagree. They are ONE SCRIPT:
##
##   ball_painting_demo_v2.tscn:3   ext_resource → res://commons/context/drawingboard/paper_draw_surface.gd
##   drawing_paper.tscn:3           ext_resource → res://commons/context/drawingboard/paper_draw_surface.gd
##   drawing_paper.tscn:67          script = ExtResource("1_6y74l")   ← the same file, attached
##
## paper_draw_surface.gd owns the whole visible body of both tokens. The enum
## (paper_draw_surface.gd:42), the allow-list (:45), the colour table (:48-53), the
## resolver (:313-323) and the single point of use (:159) are one implementation counted
## twice. So the census is: `priming` · 2 tokens · 1 script · 1 vocabulary · ZERO
## independent evidence. The corpus's most common hidden family, found again, and this
## time it is the whole family.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## WHAT THE SOURCE ACTUALLY IMPLEMENTS, AND IT IS NOT PRIMING.
##
## `reset_canvas()` (paper_draw_surface.gd:149-162) is the only reader of the axis. It
## does exactly one thing with it:
##
##     brush_layer.add_splat(centre, max(texture_size.x, texture_size.y), _priming_color())
##
## One splat, full surface, one flat colour. Nothing is ever drawn on top at spawn — every
## draw_point/draw_line call in the drawingboard folder comes from a pen tip or a ball tip
## under player interaction (pentip_ray_cast.gd:55,57,76; ball_paint_tip.gd:94,96,118), and
## neither runs in `_ready`. In a STILL, which is the only evidence this programme accepts,
## both tokens photograph a rectangle of one colour. Four values, four swatches.
##
## THE SUSPICION IN THE BRIEF HOLDS, AND THE SOURCE CONVICTS ITSELF IN ITS OWN COMMENTS.
## paper_draw_surface.gd:29-32 states the art history correctly and completely:
##
##     bole        "the ground stays visible in every shadow it left"
##     verdaccio   "the ground is a CORRECTION — laid in order to be cancelled by what
##                  goes over it"
##
## Both sentences are claims about a RELATION between the ground and a layer above it. The
## code has no layer above it. A ground that nothing is put on is a background, and
## `background` is what those four values name in that file. The docstring is a promissory
## note the implementation does not pay.
##
## ─────────────────────────────────────────────────────────────────────────────────────
## WHAT THIS BENCH DOES ABOUT IT.
##
## It keeps the four grounds — the exact four Colors, copied from paper_draw_surface.gd:48-53
## and not retyped from prose — and gives them the second thing a ground needs in order to
## be a ground: something on top. The second axis is `handling`, and it is one question:
## WHAT OF THE GROUND SURVIVES INTO THE MARK?
##
##   bare        nothing is on it. The disc is the ground's own colour; the only thing that
##               marks the nimbus is the incised circle. This is the SOURCE'S ONLY STATE,
##               reproduced exactly, and it is the control row.
##   glaze       a transparent film. The mark is ground × tint, multiplied in LINEAR light
##               (Color.srgb_to_linear → multiply → linear_to_srgb), because a glaze is a
##               transmittance and transmittance multiplies radiance, not gamma-encoded
##               bytes. The ground survives whole, as colour.
##   body        an opaque covering. The mark is the tint alone. The ground survives
##               NOWHERE inside the mark, which is the whole reason this row is the
##               programme's control here.
##   sgraffito   the opaque covering scratched back through in sixteen rays. The ground
##               survives inside the mark, in lines. This is bole's own technique — the
##               red clay is scratched through gold so the drawing reads.
##
## THE THESIS THE SHEET IS BUILT TO PHOTOGRAPH: glaze is verdaccio's instrument and
## sgraffito is bole's, and each is nearly useless on the other's ground. Both halves are
## in the numbers, computed before the capture (see dna.predicted_degeneracy).
##
## ─────────────────────────────────────────────────────────────────────────────────────
## INSTRUMENT DECISIONS, EACH ONE COSTING SOMETHING.
##
## THE PAINTED LAYERS ARE UNSHADED. The axis is a colour axis; if the rig's key light rakes
## across the panel then every measured difference between two grounds is partly a fact
## about the light. Unshaded, the rendered pixel is filmic(srgb_to_linear(albedo)) and
## nothing else, which is why the predicted degeneracy below could be computed to the byte
## instead of estimated. The board and the feet stay lit, so the object still has a body.
##
## THE GLAZE IS COMPUTED, NOT ALPHA-BLENDED. A transparent material would have made the
## result depend on transparency sort order, which is not a property of the ground. The
## composite is arithmetic on two Colors and is identical on every machine.
##
## THE BOARD IS YAWED 0.62 rad. capture_config_sweep.gd:69 puts the camera at YAW 0.62, and
## its direction is Vector3(sin(yaw)cos(pitch), -sin(pitch), cos(yaw)cos(pitch)) (:443), whose
## horizontal bearing is atan2(sin 0.62, cos 0.62) = 0.62 exactly. Facing the board along it
## photographs the face square and costs only the 15 deg pitch (cos 0.26 = 0.9664 of the
## height). A panel photographed at 35 deg would have measured its own foreshortening.
##
## Deterministic: no RandomNumberGenerator, no randf, no noise, no _process, no Timer, no
## tween. Every vertex and every colour is arithmetic on constants. Two builds are the same
## mesh and the same bytes.


## WHICH OF THE FOUR HISTORICAL GROUNDS IS LAID. The values and the colours are the source's,
## verbatim: paper_draw_surface.gd:42 for the enum, :48-53 for the table. Not a lightness
## ladder — neutral light, warm mid, warm dark, cool mid — so every pair differs in hue as
## well as value.
@export_enum("white", "ochre", "bole", "verdaccio") var priming: String = "white":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not PRIMINGS.has(picked):
			return                      ## an unreachable value keeps the standing panel
		priming = picked
		if is_inside_tree() and not _bulk:
			_rebuild()

## WHAT OF THE GROUND SURVIVES INTO THE MARK. Four answers, and the default is `bare`
## because bare is what the two source tokens photograph — the shipped state of the family
## this bench is about, so the default cell is the thing being argued with.
@export_enum("bare", "glaze", "body", "sgraffito") var handling: String = "bare":
	set(v):
		var picked: String = str(v).strip_edges().to_lower()
		if not HANDLINGS.has(picked):
			return
		handling = picked
		if is_inside_tree() and not _bulk:
			_rebuild()


const PRIMINGS: PackedStringArray = ["white", "ochre", "bole", "verdaccio"]
const HANDLINGS: PackedStringArray = ["bare", "glaze", "body", "sgraffito"]

## COPIED FROM paper_draw_surface.gd:48-53, value for value. If these ever drift, this bench
## stops being about that family and starts being about a palette someone liked.
const PRIMING_COLOR: Dictionary = {
	"white": Color(1, 1, 1, 1),
	"ochre": Color(0.78, 0.60, 0.33, 1),
	"bole": Color(0.42, 0.20, 0.16, 1),
	"verdaccio": Color(0.45, 0.50, 0.36, 1),
}

## THE ONE TINT, and it has to serve two histories with one value: the flesh rose that
## verdaccio exists to neutralise, and the warm leaf that bole exists to stand under. In
## LINEAR light its red:green ratio is 0.78741 / 0.44799 = 1.7576. Over verdaccio that
## becomes 1.4021 (verdaccio's own ratio is 0.7977, and the ratios multiply) — 20 percent
## of the way back to neutral. Over ochre it becomes 3.1490. Verdaccio is the ONLY ground
## in the table that reduces it. That is the whole claim, and it is arithmetic.
const MARK_TINT: Color = Color(0.90, 0.70, 0.58, 1)

## The incised drawing. Fixed in every cell of the sheet, on purpose: it is the one thing
## on the panel that is not a variable, so its contrast against each ground is free
## evidence about the ground (it nearly vanishes on bole).
const DRAW_COLOR: Color = Color(0.11, 0.09, 0.08, 1)
const BOARD_COLOR: Color = Color(0.30, 0.22, 0.15, 1)

## capture_config_sweep.gd:69. The board turns to meet it.
const CAMERA_YAW: float = 0.62

const BOARD_SIZE: Vector3 = Vector3(0.540, 0.500, 0.022)
const FOOT_SIZE: Vector3 = Vector3(0.060, 0.050, 0.060)
const FOOT_X: float = 0.170
const FACE_SIZE: Vector2 = Vector2(0.460, 0.420)

const R_MARK: float = 0.185
const R_RING: float = 0.1925
const DISC_T: float = 0.0008

const N_RAY: int = 16
const RAY_LEN: float = 0.135
const RAY_W: float = 0.008
const RAY_MID: float = 0.1125          ## 0.045 → 0.180, so every ray ends inside R_MARK

const TICK_LEN: float = 0.014
const TICK_W: float = 0.005
const TICK_MID: float = 0.2005

## Z of each layer, board front face at 0.011. Gaps of 1.0-1.2 mm: enough that nothing
## z-fights and little enough that the parallax at the sweep's 1.28 m is sub-pixel.
const Z_FACE: float = 0.0120
const Z_RING: float = 0.0130
const Z_MARK: float = 0.0142
const Z_RAY: float = 0.0152

var _bulk: bool = false
var _board: Node3D = null


func _ready() -> void:
	_check_hints()
	_rebuild()


## THE MARK'S COLOUR IS THE WHOLE SECOND AXIS. `bare` returns the ground itself, which is
## why the bare row is geometrically identical to the body row and differs only here.
func _mark_color() -> Color:
	var g: Color = _ground_color()
	if handling == "bare":
		return g
	if handling == "glaze":
		return _glazed(g, MARK_TINT)
	return MARK_TINT


func _ground_color() -> Color:
	var c: Color = PRIMING_COLOR.get(priming, Color(1, 1, 1, 1))
	return c


## A GLAZE MULTIPLIES RADIANCE, NOT BYTES. Godot's Color literals are sRGB-encoded, so the
## multiplication has to happen either side of the transfer function or the result is a
## number with no physical referent. Over white this is the identity — s2l(1) = 1 — which
## is the designed null registered for this bench.
func _glazed(ground: Color, tint: Color) -> Color:
	var g: Color = ground.srgb_to_linear()
	var t: Color = tint.srgb_to_linear()
	var mixed: Color = Color(g.r * t.r, g.g * t.g, g.b * t.b, 1.0)
	return mixed.linear_to_srgb()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	_board = Node3D.new()
	_board.name = "Board"
	_board.rotation.y = CAMERA_YAW
	add_child(_board)

	var face_y: float = FOOT_SIZE.y + BOARD_SIZE.y * 0.5

	_box("Panel", BOARD_SIZE, Vector3(0.0, face_y, 0.0), BOARD_COLOR, false, _board)
	_box("FootL", FOOT_SIZE, Vector3(-FOOT_X, FOOT_SIZE.y * 0.5, 0.0), BOARD_COLOR, false, _board)
	_box("FootR", FOOT_SIZE, Vector3(FOOT_X, FOOT_SIZE.y * 0.5, 0.0), BOARD_COLOR, false, _board)

	var face: Node3D = Node3D.new()
	face.name = "Face"
	face.position = Vector3(0.0, face_y, 0.0)
	_board.add_child(face)

	_quad("Ground", FACE_SIZE, Vector3(0.0, 0.0, Z_FACE), _ground_color(), face)
	_disc("Incision", R_RING, Vector3(0.0, 0.0, Z_RING), DRAW_COLOR, face)
	_ticks(face)
	_disc("Mark", R_MARK, Vector3(0.0, 0.0, Z_MARK), _mark_color(), face)
	if handling == "sgraffito":
		_rays(face)


## Four ruled ticks on the diagonals, where the margin is widest. They are the reason the
## panel reads as a drawing that was made before the paint, and they never vary.
func _ticks(face: Node3D) -> void:
	for i in range(4):
		var pivot: Node3D = Node3D.new()
		pivot.name = "Tick%d" % i
		pivot.rotation.z = PI * 0.25 + float(i) * PI * 0.5
		pivot.position = Vector3(0.0, 0.0, Z_RING)
		face.add_child(pivot)
		_box("Bar", Vector3(TICK_W, TICK_LEN, DISC_T),
			Vector3(0.0, TICK_MID, 0.0), DRAW_COLOR, true, pivot)


## Sixteen rays scratched through the covering. They are the ONLY geometry that differs
## across the handling axis; bare, glaze and body are the same meshes with one albedo
## changed. The ground colour goes here because that is what a scratch reveals.
func _rays(face: Node3D) -> void:
	var g: Color = _ground_color()
	for i in range(N_RAY):
		var pivot: Node3D = Node3D.new()
		pivot.name = "Ray%d" % i
		pivot.rotation.z = float(i) * TAU / float(N_RAY)
		pivot.position = Vector3(0.0, 0.0, Z_RAY)
		face.add_child(pivot)
		_box("Cut", Vector3(RAY_W, RAY_LEN, 0.0006),
			Vector3(0.0, RAY_MID, 0.0), g, true, pivot)


func _box(nm: String, size: Vector3, pos: Vector3, col: Color, flat: bool, parent: Node3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: BoxMesh = BoxMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = _mat(col, flat)
	parent.add_child(mi)


func _quad(nm: String, size: Vector2, pos: Vector3, col: Color, parent: Node3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: QuadMesh = QuadMesh.new()
	m.size = size
	mi.mesh = m
	mi.position = pos
	mi.material_override = _mat(col, true)
	parent.add_child(mi)


func _disc(nm: String, radius: float, pos: Vector3, col: Color, parent: Node3D) -> void:
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.name = nm
	var m: CylinderMesh = CylinderMesh.new()
	m.top_radius = radius
	m.bottom_radius = radius
	m.height = DISC_T
	m.radial_segments = 96
	m.rings = 0
	mi.mesh = m
	mi.position = pos
	mi.rotation.x = PI * 0.5
	mi.material_override = _mat(col, true)
	parent.add_child(mi)


func _mat(col: Color, flat: bool) -> StandardMaterial3D:
	var m: StandardMaterial3D = StandardMaterial3D.new()
	m.albedo_color = col
	if flat:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	else:
		m.metallic = 0.0
		m.roughness = 0.85
	return m


## Config from map_data.json tokens:  ground_layer#priming:bole#handling:sgraffito
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.is_empty():
		return
	_bulk = true
	if config_data.has("priming"):
		priming = str(config_data["priming"])
	if config_data.has("handling"):
		handling = str(config_data["handling"])
	_bulk = false
	if is_inside_tree():
		_rebuild()


## The declaration gate reads the @export_enum hint; the builder reads the const. If they
## ever drift, every frame in a sweep is a fact about which of the two a given tool trusted
## — which is science_screen's whole failure, and it cost that pass sixteen identical
## frames and a confident INERT verdict about a typo.
func _check_hints() -> void:
	var pairs: Array = [["priming", PRIMINGS], ["handling", HANDLINGS]]
	for entry in pairs:
		var key: String = str(entry[0])
		var want: PackedStringArray = entry[1]
		for prop in get_property_list():
			if String(prop.get("name", "")) != key:
				continue
			var got: PackedStringArray = String(prop.get("hint_string", "")).split(",")
			if got != want:
				push_warning("ground_layer: %s hint %s != const %s" % [key, got, want])
