@tool
extends "res://commons/primitives/cubes/grab_cube.gd"

# The rod body shared by grab_long_stick.tscn and grab_rainbow_stick.tscn.
#
# THESE TWO ARTIFACTS ARE ONE BODY UNDER TWO NAMES. Both instance
# addons/godot-xr-tools/objects/pickable.tscn, both ran grab_cube.gd, and their node
# trees are identical name for name and transform for transform: the same 0.169 m grip
# block at x = -0.608, the same 1.5 m cylinder lying along X, the same 0.05 m lit bead
# at x = 1.003, the same trail targeting that bead. They differ ONLY in dressing —
# magenta grip + cloth trail on one, dark metallic grip + rainbow trail on the other,
# and 2 mm of shaft radius. So they take ONE axis with ONE value list, declared here.
#
# This script exists so the axis does not have to live in grab_cube.gd, which is shared
# by seventeen other scenes (grab_cube, grab_sphere, grab_plane, the paper panels, the
# magnifier, the Mondrian and Agnes grids). A rod's argument is not a cube's. Everything
# grab_cube.gd does — snapping, pickup, the alternate material on ax_button — is
# inherited unchanged; nothing here touches collision, mass, grab points or any layer
# the XR interaction system reads.
#
# @identity
# essence: a 1.6 m rod with a grip at one end and a lit bead at the other — the simplest
#   possible extension of the hand, and the first thing in the curriculum that makes the
#   arm longer than the arm.
# desire: to be carried into a place the hand cannot reach and to report back — the trail
#   behind the bead is the report, written in the air.
# critical_parameter: office — what the rod is FOR. A rod is not one tool; it is the
#   ancestor of five, and which one it is shows entirely in what is fitted at its ends.
# triggers: _ready builds the dressing after the inherited pickup wiring; apply_grid_config
#   rebuilds it when a map names an office.
# emerges: a bare shaft reads "go and touch that"; a graduated one reads "go and measure
#   that"; a fulcrum reads "go and move that"; a needle reads "look there"; a bound grip
#   reads "hold this and be seen holding it".
# needs: the grip block and shaft of the host scene [present]; nothing else.
# relationships: the hand-tool sibling of [[grab_cube]] and [[grab_sphere]], which extend
#   nothing; the ancestor of every measuring, prying and pointing instrument later in the
#   spine.
# truth: an extension of the body is never neutral. The moment a stick is fitted at its
#   ends it stops being a length and becomes a claim about what the arm was missing.

# ── The host scene's geometry, measured from the two .tscn files ──────
# The shaft lies along +X. Everything below is positioned against these, so the dressing
# lands on the rod that is actually there rather than on an assumed one.
const SHAFT_X0 := -0.528                  # cylinder centre 0.222, half-height 0.75
const SHAFT_X1 := 0.972
const SHAFT_CX := 0.222
const SHAFT_LEN := 1.500
const GRIP_X := -0.608                    # the grab block and its highlight ring
const BEAD_X := 1.003                     # the lit trail anchor, radius 0.05

# ── DNA ───────────────────────────────────────────────────────────────
## AXIS — WHAT THE ROD IS FOR. Not what it is made of and not how long it is: what the
## arm was missing. A rod is the ancestor of five tools and the difference between them
## lives at the ENDS, which is the only place a hand ever meets one.
##
##   reach    the bare shaft, lit bead, nothing fitted — distance, and nothing else.
##            The legacy lineage of both sticks, byte for byte.
##   rule     a bone-white graduated blade the full length of the shaft, ticked every
##            0.1 m with a longer mark every 0.5 m and a red datum block at zero —
##            the arm was missing a MEASURE. (This is what the token grab_rainbow_stick
##            has always claimed to be: "a spectrum along a stick". The rainbow is on
##            the motion trail, not on the rod, so the stick never carried a scale.
##            Now one value of the family does.)
##   lever    a thick sleeved effort arm with grip bands, a bearing collar and a wedge
##            fulcrum standing under the shaft a third of the way along, a bare thin
##            load arm past it, a counterweight at the butt — the arm was missing FORCE.
##            The only value whose mass hangs BELOW the line of the rod.
##   pointer  the whole shaft becomes one graphite taper, 84 mm at the hand narrowing to
##            a needle that dies just short of the bead, with an orange finger stop —
##            the arm was missing ATTENTION. It indicates; it does not touch.
##   baton    an ivory lacquer sleeve over the whole shaft, a fat cork grip bound with
##            five black rings, a brass pommel at the butt — the arm was missing
##            AUTHORITY. A rod made to be held and to be seen being held.
##
## Visible in a still by construction: every value is fitted geometry on a rod that never
## moves. Nothing here is a rate, and the two things about these sticks that ARE rates —
## the cloth trail and the rainbow trail — are invisible to a still anyway, because
## MesmerizingTrail needs two recorded points before it builds a mesh at all.
@export var office: String = "reach"
const OFFICES: PackedStringArray = ["reach", "rule", "lever", "pointer", "baton"]

const DRESS_NODE := "OfficeDressing"


# ── Lifecycle ─────────────────────────────────────────────────────────
func _ready() -> void:
	# The inherited body first, untouched: pickup wiring, original material, snapping.
	super._ready()
	_read_metadata_overrides()
	_apply_office()


## A map can name an office through the # token syntax. Called deferred by
## GridInteractablesComponent AFTER _ready, and only ever when a placement carries
## config at all — the 44 live placements carry none, so this never runs for them.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("office"):
		return
	office = str(config_data["office"])
	_apply_office()


func _read_metadata_overrides() -> void:
	if has_meta("config_office"):
		office = str(get_meta("config_office"))


# ── The axis ──────────────────────────────────────────────────────────
# Appended LAST and only ever as ONE new child, so every existing child index, node path
# and transform in both scenes is untouched. "reach" builds nothing at all.
func _apply_office() -> void:
	var token: String = office.strip_edges().to_lower()
	office = token if OFFICES.has(token) else office

	var old: Node = get_node_or_null(NodePath(DRESS_NODE))
	if old != null:
		remove_child(old)
		old.queue_free()

	# "reach" — the bare shaft. Nothing is fitted, so nothing is built and nothing is
	# even allocated: the scene renders exactly as it did before this script existed.
	if office == "reach":
		return

	var dress := Node3D.new()
	dress.name = DRESS_NODE

	match office:
		"rule":
			_office_rule(dress)
		"lever":
			_office_lever(dress)
		"pointer":
			_office_pointer(dress)
		"baton":
			_office_baton(dress)
		_:
			# An unrecognised word keeps the bare shaft rather than inventing a rod.
			dress.free()
			return

	add_child(dress)


## RULE — the graduated end. A flat bone blade laid along the front face of the shaft,
## ticked every 0.1 m with a longer mark every 0.5 m, a fine second scale printed along
## its lower edge and a red datum block at zero. Fits entirely inside the body's existing
## bounding box, so the comparison against `reach` is a pure change of content.
func _office_rule(dress: Node3D) -> void:
	var bone: StandardMaterial3D = _matte(Color(0.88, 0.86, 0.79), 0.55)
	var ink: StandardMaterial3D = _matte(Color(0.07, 0.07, 0.08), 0.80)
	var datum: StandardMaterial3D = _matte(Color(0.72, 0.15, 0.10), 0.60)

	dress.add_child(_bar(Vector3(SHAFT_CX, 0.0, 0.024), Vector3(SHAFT_LEN, 0.052, 0.008), bone))
	# The printed edge — a hairline second scale under the graduations.
	dress.add_child(_bar(Vector3(SHAFT_CX, -0.020, 0.031), Vector3(1.44, 0.006, 0.003), ink))

	for i in range(15):
		var tx: float = -0.45 + float(i) * 0.1
		if i % 5 == 0:
			dress.add_child(_bar(Vector3(tx, 0.0, 0.030), Vector3(0.010, 0.050, 0.004), ink))
		else:
			dress.add_child(_bar(Vector3(tx, 0.014, 0.030), Vector3(0.007, 0.024, 0.004), ink))

	dress.add_child(_bar(Vector3(-0.50, 0.0, 0.030), Vector3(0.026, 0.052, 0.010), datum))


## LEVER — the fulcrum. The hand end thickens into a sleeved effort arm with grip bands
## and a counterweight; a bearing collar and a wedge stand at the pivot; past it the load
## arm stays bare and thin. The wedge is the silhouette: the only value in the family
## that puts mass below the line of the rod.
func _office_lever(dress: Node3D) -> void:
	var steel: StandardMaterial3D = _metal(Color(0.33, 0.34, 0.37), 0.42)
	var band: StandardMaterial3D = _matte(Color(0.10, 0.10, 0.11), 0.85)
	var bright: StandardMaterial3D = _metal(Color(0.62, 0.62, 0.60), 0.30)
	var block: StandardMaterial3D = _matte(Color(0.15, 0.16, 0.18), 0.75)
	var shim: StandardMaterial3D = _metal(Color(0.42, 0.43, 0.45), 0.55)

	dress.add_child(_rod(-0.22, 0.60, 0.026, 0.026, steel))
	var bands: PackedFloat32Array = [-0.46, -0.36, -0.26]
	for gx in bands:
		dress.add_child(_rod(gx, 0.018, 0.032, 0.032, band))
	dress.add_child(_rod(-0.49, 0.10, 0.046, 0.046, block))

	dress.add_child(_rod(0.10, 0.06, 0.036, 0.036, bright))
	dress.add_child(_wedge(Vector3(0.10, -0.052, 0.0), Vector3(0.24, 0.104, 0.12), block))
	dress.add_child(_bar(Vector3(0.10, -0.112, 0.0), Vector3(0.30, 0.016, 0.16), shim))


## POINTER — the tip. The whole shaft becomes one long graphite taper, 84 mm across at
## the hand and dying to a needle just short of the lit bead, so the body of the rod is
## itself an arrow at the light. An orange finger stop and a pale index ring mark where
## it is held. Fits inside the existing bounding box.
func _office_pointer(dress: Node3D) -> void:
	var graphite: StandardMaterial3D = _metal(Color(0.20, 0.21, 0.24), 0.42, 0.15)
	var accent: StandardMaterial3D = _matte(Color(0.88, 0.36, 0.12), 0.45)
	var pale: StandardMaterial3D = _matte(Color(0.85, 0.85, 0.82), 0.50)

	dress.add_child(_rod(0.212, 1.48, 0.004, 0.042, graphite))
	dress.add_child(_rod(-0.44, 0.016, 0.049, 0.049, accent))
	dress.add_child(_rod(-0.36, 0.010, 0.040, 0.040, pale))
	dress.add_child(_rod(0.965, 0.026, 0.0, 0.005, pale))


## BATON — the grip. An ivory lacquer sleeve makes the whole shaft read as one clean
## wand; a fat cork grip bound with five rings and a brass pommel make the hand end an
## object in its own right. Nothing is fitted at the far end at all: a baton is held and
## shown, and it touches nothing.
func _office_baton(dress: Node3D) -> void:
	var ivory: StandardMaterial3D = _matte(Color(0.94, 0.93, 0.89), 0.35)
	var cork: StandardMaterial3D = _matte(Color(0.58, 0.40, 0.23), 0.85)
	var binding: StandardMaterial3D = _matte(Color(0.09, 0.09, 0.10), 0.70)
	var brass: StandardMaterial3D = _metal(Color(0.76, 0.64, 0.32), 0.28, 0.85)

	dress.add_child(_rod(SHAFT_CX, SHAFT_LEN, 0.019, 0.019, ivory))
	dress.add_child(_rod(-0.40, 0.30, 0.052, 0.052, cork))
	for i in range(5):
		var bx: float = -0.53 + float(i) * 0.07
		dress.add_child(_rod(bx, 0.012, 0.058, 0.058, binding))
	dress.add_child(_rod(-0.235, 0.020, 0.040, 0.040, brass))
	dress.add_child(_ball(-0.575, 0.048, brass))


# ── Local helpers ─────────────────────────────────────────────────────
func _matte(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = 0.0
	return m


func _metal(c: Color, rough: float, metal: float = 0.75) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = rough
	m.metallic = metal
	return m


func _bar(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi


## A cylinder lying along the shaft (+X). r_tip is the radius at the +X end, r_butt at
## the -X end, so a taper can be written the way the rod is read: from the hand outward.
func _rod(cx: float, length: float, r_tip: float, r_butt: float, mat: Material) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = r_tip
	mesh.bottom_radius = r_butt
	mesh.height = length
	mesh.radial_segments = 20
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(cx, 0.0, 0.0)
	# -90 about Z maps the mesh's local +Y (its top) onto world +X (the bead end).
	mi.rotation_degrees = Vector3(0.0, 0.0, -90.0)
	return mi


func _ball(cx: float, r: float, mat: Material) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = r
	mesh.height = r * 2.0
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = Vector3(cx, 0.0, 0.0)
	return mi


## A triangular prism, apex up. Used for the lever's fulcrum: the apex meets the shaft
## and the base sits below it.
func _wedge(center: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var mesh := PrismMesh.new()
	mesh.size = size
	mesh.left_to_right = 0.5
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = center
	return mi
