extends Node3D

# @identity
# essence: three labeled CSGCylinder3D axes (X=red, Y=green, Z=blue) assembled into a pickable coordinate reference object that the player can hold in their hand
# desire: to hold space in your hand — to pick up the XYZ gadget and reorient it until you understand that X, Y, and Z are directions relative to you, not absolute truths about the world
# critical_parameter: initial_scale — at 3.2x the gadget is large enough to read labels comfortably in VR; at 1.0 it would be too small to hold and read simultaneously
# triggers: grabbing the object lets the player physically rotate it, embodying the relationship between coordinate axes; the axes' emission glow makes them readable in dark VR environments
# emerges: students consistently discover that "X goes right" is only true when you're looking in the default direction — rotating the gadget breaks this assumption and makes coordinates genuinely spatial rather than notational
# needs: colored axis cylinders [has]; pickup physics [has via grab_sphere]; Label3D axis labels [has]; no slider or button controls [has none needed]
# relationships: appears in Tutorial_Single (first VR object encounter), Tutorial_Row, Tutorial_2D_Build (coordinate reference throughout array tutorial); contrasts with basis_vectors_rig (mathematical vs intuitive representation)
#   Kin on the `readout` axis to [[xyz_slider_plate]] and [[line]], which already carry the same
#   four rungs. Those two are the plate and the segment; this is the frame they are read against,
#   so the three had to speak one vocabulary or the family would have had three private ones.
# truth: coordinate systems are conventions about shared directions, not properties of space itself — the XYZ gadget makes this visible by being rotatable
#
# DNA AXIS — readout: whether this frame only NAMES directions or also MEASURES along them. The
#   shipped gadget is three coloured rods and three letters: it says "this way is X" and nothing
#   about how far. That is a real position to hold, and the rungs above it are three progressively
#   stronger disagreements with it, ending at a frame that has stopped being a set of directions
#   and become a space with addresses in it.

# XYZ Coordinate Gadget for VR Interaction
@export var initial_scale: Vector3 = Vector3(3.2, 3.2, 3.2)  # Smaller scale for VR
@export var rotation_speed: float = 1.0  # Rotation speed in radians per second
@export var camera_rotation_sensitivity: float = 2.0  # Sensitivity of camera rotation
@export var camera_movement_sensitivity: float = 0.5  # Sensitivity of camera movement

## AXIS — DOES THE FRAME MEASURE, OR ONLY POINT? Adopted character for character from
## [[xyz_slider_plate]] and [[line]] / [[line_interface]], where the same ladder already runs
## none < numeral < gradation < lattice. Rungs are APPEND-ONLY: everything hangs off the
## CoordinateAxes node after the three rods, so no existing child moves.
##
##   none       three 1.2 m rods and three billboard letters — the shipped look, 7 rooms,
##              byte for byte. A direction has a name and no magnitude
##   numeral    0.25 / 0.50 / 0.75 / 1.00 printed in the axis colour beside each rod, twelve
##              small billboard numerals in all: the rod acquires addresses but no marks
##   gradation  eight square collars threaded onto each rod at every 0.15 m, the four that land
##              on the quarters (0.30 / 0.60 / 0.90 / 1.20) half again as wide as the four
##              between: the rod is now a RULE, readable from any angle, with no text to face
##   lattice    the gradation collars plus the octant filled in — 5 x 5 grid lines drawn in
##              each of the three coordinate planes out to 1.2 m, so the empty space between
##              the rods is finally divided and a point in it has somewhere to be
##
## R2 note: every rung is standing geometry. Nothing here animates, so a still can hold it.
@export_enum("none", "numeral", "gradation", "lattice") var readout: String = "none"

## Allow-list — an unrecognised token falls back to the shipped bare frame.
const READOUTS: PackedStringArray = ["none", "numeral", "gradation", "lattice"]

const AXIS_LEN := 1.2               # rod length, matching the label positions
const RO_TICK_STEP := 0.15          # spacing of gradation collars
const RO_LATTICE_DIV := 5           # grid lines per coordinate plane, per direction

var is_grabbed: bool = false
var initial_camera_transform: Transform3D
var initial_camera_rotation: Basis

var _axes_root: Node3D
var _readout_root: Node3D

func _ready():
	# Scale down the gadget
	scale = initial_scale
	create_axes()
	# Appended LAST, after the three rods and their labels exist.
	_build_readout()


## Reachable configuration. THIS METHOD DID NOT EXIST — the gadget had no apply_grid_config at
## all, so a map token could not reach a single one of its exports, and the DNA sweep (which
## calls the method only `if art.has_method(...)`) would have silently photographed the default
## four times over and reported the axis INERT. Adding the hook is the precondition for this
## artifact having DNA at all; it reads only `readout`, so no shipped placement changes.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("readout"):
		var word: String = str(config_data["readout"]).strip_edges().to_lower()
		readout = word if READOUTS.has(word) else readout
		_rebuild_readout()

func create_axes():
	# Create axes visualization to show X, Y, Z directions
	var axes = Node3D.new()
	axes.name = "CoordinateAxes"
	add_child(axes)
	_axes_root = axes

	# Create X axis (red)
	var x_axis = CSGCylinder3D.new()
	x_axis.radius = 0.02
	x_axis.height = 1.2  # Match label position
	x_axis.rotation_degrees.z = 90
	x_axis.position = Vector3(0.6, 0, 0)  # Centered at half the height
	var x_material = StandardMaterial3D.new()
	x_material.albedo_color = Color(1, 0, 0)  # Red
	x_material.emission_enabled = true
	x_material.emission = Color(1, 0, 0, 0.5)
	x_axis.material = x_material
	axes.add_child(x_axis)
	
	# Create Y axis (green)
	var y_axis = CSGCylinder3D.new()
	y_axis.radius = 0.02
	y_axis.height = 1.2  # Match label position
	y_axis.position = Vector3(0, 0.6, 0)  # Centered at half the height
	var y_material = StandardMaterial3D.new()
	y_material.albedo_color = Color(0, 1, 0)  # Green
	y_material.emission_enabled = true
	y_material.emission = Color(0, 1, 0, 0.5)
	y_axis.material = y_material
	axes.add_child(y_axis)
	
	# Create Z axis (blue)
	var z_axis = CSGCylinder3D.new()
	z_axis.radius = 0.02
	z_axis.height = 1.2  # Match label position
	z_axis.rotation_degrees.x = 90
	z_axis.position = Vector3(0, 0, 0.6)  # Centered at half the height
	var z_material = StandardMaterial3D.new()
	z_material.albedo_color = Color(0, 0, 1)  # Blue
	z_material.emission_enabled = true
	z_material.emission = Color(0, 0, 1, 0.5)
	z_axis.material = z_material
	axes.add_child(z_axis)
	
	# Add axis labels
	add_axis_label("X", Vector3(1.2, 0, 0), Color(1, 0, 0))
	add_axis_label("Y", Vector3(0, 1.2, 0), Color(0, 1, 0))
	add_axis_label("Z", Vector3(0, 0, 1.2), Color(0, 0, 1))

	_build_frame_anchor(axes)


## FRAMING ANCHOR — invisible, and it exists for the capture harness rather than for the game.
## This gadget is built entirely from CSGCylinder3D and Label3D, and BOTH of the project's AABB
## walks measure meshes only: capture_artifact_config._combined_aabb types `is MeshInstance3D`
## and finds nothing here, so it falls back to its 1 m default box and frames a 4.2 m object
## (1.2 m rods times the 3.2x initial_scale) as though it were a 1 m one. Three quarters of the
## gadget lands outside the frame and any axis measured on it is measured on a crop.
##
## `layers = 0` means no camera renders it, so the game is untouched. It is parented to
## CoordinateAxes, NOT to the root, on purpose: GridInteractablesComponent._compute_local_aabb
## walks the root's DIRECT children only, so a mesh one level down stays invisible to
## auto-grounding and none of the 7 live placements move by a millimetre.
func _build_frame_anchor(parent: Node3D) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(1.32, 1.32, 1.32)          # -0.04 .. 1.28 on each axis: rods plus labels
	var mi := MeshInstance3D.new()
	mi.name = "FrameAnchor"
	mi.mesh = box
	mi.position = Vector3(0.62, 0.62, 0.62)
	mi.layers = 0
	parent.add_child(mi)

func add_axis_label(text: String, position: Vector3, color: Color):
	var label_3d = Label3D.new()
	label_3d.text = text
	label_3d.font_size = 32
	label_3d.modulate = color
	label_3d.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label_3d.position = position
	add_child(label_3d)


# ── Readout axis ──────────────────────────────────────────────────────
# The three axis directions, paired with the colours the rods already use. Held once, here, so
# a rung cannot disagree with the rods about which way is Y or what colour green is.
const RO_AXES: Array = [
	{"dir": Vector3(1, 0, 0), "color": Color(1, 0, 0)},
	{"dir": Vector3(0, 1, 0), "color": Color(0, 1, 0)},
	{"dir": Vector3(0, 0, 1), "color": Color(0, 0, 1)},
]


func _rebuild_readout() -> void:
	if is_instance_valid(_readout_root):
		_readout_root.get_parent().remove_child(_readout_root)
		_readout_root.queue_free()
	_readout_root = null
	_build_readout()


func _build_readout() -> void:
	if _axes_root == null:
		return
	match readout:
		"numeral":
			_ro_root()
			_ro_numerals()
		"gradation":
			_ro_root()
			_ro_collars()
		"lattice":
			_ro_root()
			_ro_collars()
			_ro_lattice()
		_:
			pass                                  # "none" — the shipped frame, nothing added


func _ro_root() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	_axes_root.add_child(_readout_root)


func _ro_material(tint: Color, glow: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = glow
	return mat


## NUMERAL — addresses without marks. Four values per axis, printed in that axis's own colour
## and offset off the rod so they do not z-fight with it.
func _ro_numerals() -> void:
	for entry in RO_AXES:
		var dir: Vector3 = entry["dir"]
		var tint: Color = entry["color"]
		# Offset the text sideways off the rod, along whichever axis this one is not.
		var side: Vector3 = Vector3(dir.z, dir.x, dir.y) * 0.09
		for i in range(1, 5):
			var t: float = 0.25 * float(i)
			var lab := Label3D.new()
			lab.text = "%.2f" % t
			lab.font_size = 18
			lab.modulate = tint
			lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lab.position = dir * (AXIS_LEN * t) + side
			_readout_root.add_child(lab)


## GRADATION — marks without text. Square collars threaded onto each rod, the quarter marks
## wide and the marks between them narrow, so the eye reads the quarters first.
func _ro_collars() -> void:
	for entry in RO_AXES:
		var dir: Vector3 = entry["dir"]
		var tint: Color = entry["color"]
		var mat := _ro_material(tint.lightened(0.35), 0.7)
		var count: int = int(AXIS_LEN / RO_TICK_STEP)
		for i in range(1, count + 1):
			var d: float = RO_TICK_STEP * float(i)
			if d > AXIS_LEN + 0.001:
				break
			# A quarter mark falls on 0.30 / 0.60 / 0.90 / 1.20 at this step; those get width.
			var major: bool = (i % 2) == 0
			var r: float = 0.075 if major else 0.048
			var box := BoxMesh.new()
			box.size = Vector3(r, r, r) - dir * (r * 0.72)   # flattened along its own rod
			var mi := MeshInstance3D.new()
			mi.mesh = box
			mi.position = dir * d
			mi.material_override = mat
			_readout_root.add_child(mi)


## LATTICE — the octant divided. Grid lines in each of the three coordinate planes, so the void
## between the rods stops being void: a point out there now sits in a named cell.
func _ro_lattice() -> void:
	var mat := _ro_material(Color(0.62, 0.66, 0.74), 0.32)
	var step: float = AXIS_LEN / float(RO_LATTICE_DIV)
	var thick: float = 0.012
	# Three planes: XY (normal Z), YZ (normal X), XZ (normal Y).
	var planes: Array = [
		[Vector3(1, 0, 0), Vector3(0, 1, 0)],
		[Vector3(0, 1, 0), Vector3(0, 0, 1)],
		[Vector3(1, 0, 0), Vector3(0, 0, 1)],
	]
	for pl in planes:
		var u: Vector3 = pl[0]
		var v: Vector3 = pl[1]
		for i in range(1, RO_LATTICE_DIV + 1):
			var d: float = step * float(i)
			# A line parallel to u, offset d along v — and the same grid transposed.
			_ro_bar(u * AXIS_LEN * 0.5 + v * d, u, AXIS_LEN, thick, mat)
			_ro_bar(v * AXIS_LEN * 0.5 + u * d, v, AXIS_LEN, thick, mat)


func _ro_bar(at: Vector3, along: Vector3, length: float, thick: float, mat: StandardMaterial3D) -> void:
	var box := BoxMesh.new()
	box.size = Vector3(thick, thick, thick) + along * (length - thick)
	var mi := MeshInstance3D.new()
	mi.mesh = box
	mi.position = at
	mi.material_override = mat
	_readout_root.add_child(mi)
