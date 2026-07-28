# Florensky in Production — paraconsistent symbol made operational
#
# Florensky's icon-as-window: an image that holds two ontological positions at once.
# Visualized as a triptych panel where the same form (a sphere) is rendered three ways:
#   - solid (one view says it is here)
#   - hollow (another view says it is not here)
#   - both at once, the holding gesture
# The triptych slowly rotates so the player sees the contradiction from many angles —
# the form doesn't resolve. It works because it doesn't resolve.
#
# @identity: First map where the player sees paraconsistent logic as production-ready.
# @qfep_term: Edge — holding without collapse.

extends Node3D
class_name FlorenskyInProduction

@export var panel_color: Color = Color(0.3, 0.3, 0.35, 1.0)
@export var solid_color: Color = Color(0.9, 0.85, 0.5, 1.0)
@export var hollow_color: Color = Color(0.5, 0.6, 0.85, 1.0)
@export var both_color: Color = Color(0.85, 0.55, 0.95, 1.0)
@export var rotation_speed: float = 0.2

# ═══════════════════════════════════════════════════════════════════
# STAGE-2 DNA AXIS
# ═══════════════════════════════════════════════════════════════════

## What varies: HOW MANY BODIES the contradiction is allowed to occupy, and whether
## it survives at all. A row of three labelled panels is a *diagram* of paraconsistency —
## "is", "is/not" and "not" each get a tidy frame of their own, so the still shows an
## artifact explaining holding-without-collapse rather than performing it.
##
##   triptych    three flat panels in a row — the legacy look; the positions are held APART
##   folded      the same three panels hinged into a standing screen — held apart but
##               turned to face each other across the fold; the contradiction is now a room
##   superposed  ONE panel, three concentric spheres on one centre — the positions share a
##               volume, and no camera angle can separate them
##   collapsed   ONE panel, ONE opaque sphere, ONE label: the resolution the artifact
##               refuses, built so the refusal is legible by comparison
##
## Worth varying because it is silhouette-level (panel COUNT changes, 3 -> 1) and because
## `collapsed` is the only place in this sequence where the failure mode is shown rather
## than described. `triptych` is reused verbatim from science_screen's `surface`
## vocabulary — same level, same meaning.
@export_enum("triptych", "folded", "superposed", "collapsed") var contradiction: String = "triptych"

const CONTRADICTIONS: PackedStringArray = ["triptych", "folded", "superposed", "collapsed"]

## Panel geometry, shared by every branch so the values differ in ARRANGEMENT, not size.
const PANEL_W: float = 0.55
const PANEL_H: float = 0.8
const PANEL_D: float = 0.04
const PANEL_Y: float = 1.0
const SPHERE_R: float = 0.16

## Folded: wing hinge angle, and the seam left open at each hinge so the three panels
## read as three hinged panels and not as one creased sheet. 50° is decisive on purpose —
## the wings turn far enough that the outer spheres look at each other, which a polite
## 10° cant would not have shown from across a room.
const FOLD_DEG: float = 50.0
const FOLD_SEAM: float = 0.06

## Superposed: the nesting radii. The shell and the cage have to clear the core by enough
## to read as three distinct surfaces at walking distance — 0.16 / 0.26 / 0.36 gives 10 cm
## of air between each, so the silhouette is visibly a sphere inside a sphere inside a cage.
const SUPER_CORE_R: float = 0.16
const SUPER_SHELL_R: float = 0.26
const SUPER_CAGE_R: float = 0.36

var _triptych_root: Node3D
var _t: float = 0.0

## Only the nodes THIS script parented to self. A rebuild frees these and nothing else, so
## label plates, packaging and tags added by the grid system survive it.
var _owned: Array[Node] = []

## False until _ready has built once. On the normal grid path apply_grid_config() runs
## BEFORE add_child (GridInteractablesComponent applies config at line 1161, adds at 1187),
## so there is nothing built to rebuild — _ready will build with whatever we resolved here.
var _built: bool = false


func _ready() -> void:
	_build_all()
	_built = true


func apply_grid_config(config_data: Dictionary) -> void:
	var before_contradiction: String = contradiction

	# Stage-2 DNA axis — #contradiction:superposed
	if config_data.has("contradiction"):
		contradiction = _pick_axis(str(config_data["contradiction"]), CONTRADICTIONS, contradiction)

	if not _built:
		return
	if contradiction == before_contradiction:
		# Nothing geometric changed. curation_station passes {"emissive": false} AFTER it has
		# already framed the labels — rebuilding here would throw that framing away.
		return

	_rebuild_now()
	print("[FlorenskyInProduction] Config applied — contradiction=%s" % [contradiction])


## Accept an axis value only if it names something we actually build. A typo in a map
## token has to land on the legacy look — a half-recognised value would strand a
## placement with a panel count nobody asked for.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


func _process(delta: float) -> void:
	if not is_instance_valid(_triptych_root):
		return
	_t += delta * rotation_speed
	_triptych_root.rotation.y = _t


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## Synchronous, inline. No call_deferred anywhere in the build path: a deferred rebuild
## would land after LabelFramer.frame_labels and after _auto_ground_artifact, replacing
## framed labels and grounding against a stale AABB.
func _rebuild_now() -> void:
	# Detach immediately (not just queue_free) so the old triptych leaves the tree in the
	# same frame and cannot overlap the new one.
	for c in _owned:
		if is_instance_valid(c):
			remove_child(c)
			c.queue_free()
	_owned.clear()
	_triptych_root = null
	_build_all()


func _build_all() -> void:
	_triptych_root = Node3D.new()
	add_child(_triptych_root)
	_owned.append(_triptych_root)
	_triptych_root.rotation.y = _t

	match contradiction:
		"folded":
			_build_folded()
		"superposed":
			_build_superposed()
		"collapsed":
			_build_collapsed()
		_:
			_build_triptych()

	_build_label()


## LEGACY LOOK — three flat panels in a row at x -0.7 / 0 / +0.7, one r 0.16 sphere each,
## the middle sphere at alpha 0.55. This is what every shipped placement renders today and
## it must stay exactly that.
func _build_triptych() -> void:
	_build_panel(-0.7, solid_color, "is")
	_build_panel(0.0, both_color, "is/not")
	_build_panel(0.7, hollow_color, "not")


## The same three panels, hinged into a standing screen. The centre panel stays square-on
## at x 0; each wing pivots about its INNER edge so the outer spheres swing forward and
## face each other across the fold. The contradiction stops being a row to be read left to
## right and becomes an enclosure you stand in front of.
func _build_folded() -> void:
	var hinge_x: float = PANEL_W * 0.5 + FOLD_SEAM
	var half: float = PANEL_W * 0.5
	var ang: float = deg_to_rad(FOLD_DEG)

	# Centre leaf — square-on, unchanged position, still the translucent both/and sphere.
	_build_leaf(_triptych_root, 0.0, both_color, "is/not", 0.55)

	# Left wing: pivot sits at the seam, panel body hangs to -x, +ang turns it toward +Z.
	var left := Node3D.new()
	left.position = Vector3(-hinge_x, 0.0, 0.0)
	left.rotation.y = ang
	_triptych_root.add_child(left)
	_build_leaf(left, -half, solid_color, "is", 1.0)

	# Right wing: mirror.
	var right := Node3D.new()
	right.position = Vector3(hinge_x, 0.0, 0.0)
	right.rotation.y = -ang
	_triptych_root.add_child(right)
	_build_leaf(right, half, hollow_color, "not", 1.0)


## ONE panel, three concentric spheres sharing a single centre: an opaque core, a
## translucent shell, an unshaded wireframe cage. The three positions occupy one volume,
## so no camera angle and no still can pull them apart — which is the claim the row of
## three panels only describes. All three labels stack on the one panel.
func _build_superposed() -> void:
	_build_backing(_triptych_root, 0.0)
	var centre := Vector3(0.0, PANEL_Y + 0.05, 0.06 + SUPER_CAGE_R * 0.5)
	# is — opaque core.
	_build_sphere(_triptych_root, centre, SUPER_CORE_R, solid_color, 1.0)
	# is/not — translucent shell you see the core through.
	_build_sphere(_triptych_root, centre, SUPER_SHELL_R, both_color, 0.4, true)
	# not — a cage of lines: present as a boundary, absent as a body.
	_build_wire_sphere(_triptych_root, centre, SUPER_CAGE_R, hollow_color)
	# Three names, one frame — stacked because there is nowhere else to put them.
	_build_panel_label(_triptych_root, 0.0, 0.55, solid_color, "is")
	_build_panel_label(_triptych_root, 0.0, 0.40, both_color, "is/not")
	_build_panel_label(_triptych_root, 0.0, 0.25, hollow_color, "not")


## The resolution the artifact refuses: one panel, one fully opaque sphere, one word.
## The other two panels, their spheres and their labels are not built at all — the
## contradiction has been decided, and what that costs is visible as empty room.
func _build_collapsed() -> void:
	_build_backing(_triptych_root, 0.0)
	_build_sphere(_triptych_root, Vector3(0.0, PANEL_Y + 0.05, 0.06), SPHERE_R, solid_color, 1.0)
	_build_panel_label(_triptych_root, 0.0, 0.55, solid_color, "is")


# ═══════════════════════════════════════════════════════════════════
# PARTS
# ═══════════════════════════════════════════════════════════════════

## Legacy entry point, kept so the triptych branch composes exactly the geometry it
## always did — including the middle panel's alpha 0.55 rule.
func _build_panel(x_off: float, color: Color, label_text: String) -> void:
	var alpha: float = 0.55 if x_off == 0.0 else 1.0
	_build_leaf(_triptych_root, x_off, color, label_text, alpha)


## One complete leaf: backing panel, sphere standing proud of it, label under it.
func _build_leaf(parent: Node3D, x_off: float, color: Color, label_text: String, alpha: float) -> void:
	_build_backing(parent, x_off)
	_build_sphere(parent, Vector3(x_off, PANEL_Y + 0.05, 0.06), SPHERE_R, color, alpha)
	_build_panel_label(parent, x_off, 0.55, color, label_text)


func _build_backing(parent: Node3D, x_off: float) -> void:
	var panel := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(PANEL_W, PANEL_H, PANEL_D)
	panel.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.roughness = 0.7
	panel.material_override = mat
	panel.position = Vector3(x_off, PANEL_Y, 0)
	parent.add_child(panel)


## `double_sided` is opt-in rather than derived from alpha on purpose: the legacy middle
## sphere is translucent AND back-face culled, and turning culling off for it would darken
## the default look. Only the superposed shell asks for it.
func _build_sphere(parent: Node3D, pos: Vector3, radius: float, color: Color, alpha: float,
		double_sided: bool = false) -> void:
	var sphere := MeshInstance3D.new()
	var s := SphereMesh.new()
	s.radius = radius
	s.height = radius * 2.0
	sphere.mesh = s
	var smat := StandardMaterial3D.new()
	smat.albedo_color = color
	smat.emission_enabled = true
	smat.emission = color
	smat.emission_energy_multiplier = 1.5
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color.a = alpha
	if double_sided:
		# A shell has to be seen from inside as well as outside or the core reads as a hole.
		smat.cull_mode = BaseMaterial3D.CULL_DISABLED
	sphere.material_override = smat
	sphere.position = pos
	parent.add_child(sphere)


## A sphere that is only its boundary — latitude rings and meridians as unshaded lines.
## Used for `not` in the superposed build: it bounds a volume without filling one.
func _build_wire_sphere(parent: Node3D, centre: Vector3, radius: float, color: Color) -> void:
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 1.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var seg: int = 40

	# Three latitude rings at 45 / 90 / 135 degrees.
	for r in range(1, 4):
		var lat: float = PI * float(r) / 4.0
		var ring_y: float = cos(lat) * radius
		var ring_r: float = sin(lat) * radius
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
		for i in range(seg + 1):
			var a: float = TAU * float(i) / float(seg)
			im.surface_add_vertex(Vector3(cos(a) * ring_r, ring_y, sin(a) * ring_r))
		im.surface_end()

	# Four meridians.
	for m in range(4):
		var turn: float = PI * float(m) / 4.0
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP, mat)
		for i in range(seg + 1):
			var a: float = TAU * float(i) / float(seg)
			im.surface_add_vertex(Vector3(
				cos(a) * radius * cos(turn),
				sin(a) * radius,
				cos(a) * radius * sin(turn)))
		im.surface_end()

	var cage := MeshInstance3D.new()
	cage.mesh = im
	cage.position = centre
	parent.add_child(cage)


func _build_panel_label(parent: Node3D, x_off: float, y: float, color: Color, label_text: String) -> void:
	var label := Label3D.new()
	label.text = label_text
	label.font_size = 24
	label.modulate = color
	label.position = Vector3(x_off, y, 0.07)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	parent.add_child(label)


func _build_label() -> void:
	var label := Label3D.new()
	label.text = "Florensky: in production"
	label.font_size = 28
	label.outline_size = 6
	label.modulate = both_color
	label.position = Vector3(0, 1.85, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
	_owned.append(label)
