extends Node3D
class_name CoordinateLine

# @identity
# essence: a single coordinate axis — a colored shaft from origin with an arrowhead at +X, the geometric atom of every axis in the project
# desire: a configurable line-with-arrow primitive that any vector, axis, or directional indicator can drop in — not a one-off mesh built inline
# critical_parameter: length — how far the axis extends; together with arrow_size and tick_step it tells the eye both the direction and the scale
# triggers: _ready() builds shaft cylinder (oriented along +X), cone arrowhead at the +X end, and optional tick-mark crosses every tick_step metres along the shaft
# emerges: a clean directional indicator with a tip, a body, and a ruler — the same vocabulary that laser_measure uses for its beam
# needs: CylinderMesh [present]; StandardMaterial3D [present]; tick marks every tick_step m [present, 2026-05-19]; class_name CoordinateLine [present, 2026-05-19]; @identity [present, 2026-05-19]
# relationships: consumed by CoordinateSystem3M (three orthogonal instances → X red, Y green, Z blue); embedded indirectly via xyz_slider_plate which embeds CoordinateSystem3M; sibling-vocabulary with laser_measure (tick-marks-along-a-line); replaces ad-hoc arrows scattered through the vectors/ tree
# truth: an axis is a measurement, not a decoration. A line by itself is just a stroke; a line with a tip is direction; a line with ticks is scale. Combine all three and you get a coordinate.

## Configurable axis primitive. A shaft cylinder oriented along +X, a cone
## arrowhead at the +X end, and optional tick marks every `tick_step` metres.
## CoordinateSystem3M uses three of these (rotated to +X / +Y / +Z) to build
## the standard X/Y/Z frame embedded in xyz_slider_plate, laser_measure
## test rigs, and the vector-math curriculum.

@export var length: float = 1.5
@export var thickness: float = 0.01
@export var color: Color = Color(0.9, 0.1, 0.1, 1.0)  # red (visible on gray)
@export var arrow_size: float = 0.06
## Where the shaft starts. When false (default), shaft is centered at origin and
## extends ±length/2 along +X — the symmetric axis shape used by
## coordinate_axes_xy.tscn. When true, shaft starts at origin (0) and extends
## to +length along +X — the positive-only axis shape used by
## CoordinateSystem3M (right-handed +X/+Y/+Z frame from origin).
@export var from_origin: bool = false
## Optional unshaded shading for matching the CoordinateSystem3M look (flat colored
## bars). Default false uses shaded StandardMaterial3D for the laser_measure /
## coordinate_axes_xy look. When true, the axis becomes self-lit and the alpha
## is honoured for transparency.
@export var unshaded: bool = false
## Optional alpha for unshaded mode. 1.0 = opaque, 0.5 = the CoordinateSystem3M
## transparent look. Has no effect when unshaded = false.
@export_range(0.0, 1.0, 0.05) var alpha: float = 1.0

@export_group("Tick Marks")
## Show tick marks along the shaft. The tick-mark vocabulary is shared with
## laser_measure's beam ruler — a line without ticks reads as decoration,
## with ticks it reads as a ruler.
@export var show_ticks: bool = true
## Spacing between ticks, in shaft-length units (metres). 0 disables ticks.
## Default 0.5 = a half-metre tick, visible at the default 1.5m length.
## At length 4m (CoordinateSystem3M), set tick_step = 1.0 for whole-metre marks.
@export var tick_step: float = 0.5
## Half-length of each tick mark, perpendicular to the shaft.
@export var tick_size: float = 0.04
## Thickness of each tick mark (same units as `thickness`).
@export var tick_thickness: float = 0.008

var shaft: MeshInstance3D
var arrow: MeshInstance3D
var _ticks: Array[MeshInstance3D] = []

func _ready():
	_build_geometry()

func _build_geometry():
	# Build shared material — shaded for the coordinate_axes_xy/laser look or
	# unshaded+transparent for the CoordinateSystem3M look.
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		if alpha < 1.0:
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = alpha
	else:
		mat.roughness = 0.2

	# Shaft (cylinder) oriented along +X by rotating 90° around Z so its local Y-axis aligns with world X
	shaft = MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.height = length
	cyl.top_radius = thickness
	cyl.bottom_radius = thickness
	cyl.radial_segments = 12
	shaft.mesh = cyl
	# Position depends on from_origin: centered at zero, or offset so cylinder
	# starts at origin and extends to +length along +X.
	var shaft_basis := Basis(Vector3(0,1,0), Vector3(-1,0,0), Vector3(0,0,1))
	var shaft_pos := Vector3.ZERO
	if from_origin:
		shaft_pos = Vector3(length * 0.5, 0.0, 0.0)
	shaft.transform = Transform3D(shaft_basis, shaft_pos)
	shaft.material_override = mat
	add_child(shaft)

	# Arrow head (cone) placed at +X end
	arrow = MeshInstance3D.new()
	var cone := CylinderMesh.new()  # Use cylinder with top_radius = 0 to form a cone
	cone.top_radius = max(thickness * 3.0, 0.01)
	cone.bottom_radius = 0.0
	cone.height = arrow_size
	cone.radial_segments = 16
	arrow.mesh = cone
	# Arrow sits at +length end of the shaft. With from_origin, that's
	# +length + arrow_size/2 from origin; otherwise it's length/2 + arrow_size/2.
	var arrow_x := (length if from_origin else length * 0.5) + arrow_size * 0.5
	var end_pos := Vector3(arrow_x, 0.0, 0.0)
	var basis := Basis(Vector3(0,1,0), Vector3(-1,0,0), Vector3(0,0,1))
	arrow.transform = Transform3D(basis, end_pos)
	arrow.material_override = mat
	add_child(arrow)

	# Tick marks — small cross-bars perpendicular to the shaft, every tick_step metres
	if show_ticks and tick_step > 0.0:
		_build_ticks(mat)

func _build_ticks(mat: StandardMaterial3D) -> void:
	# Tick placement depends on shaft geometry:
	# - centered (from_origin=false): ticks at ±tick_step, ±2*tick_step, ... up to ±length/2
	# - from-origin (from_origin=true): ticks at +tick_step, +2*tick_step, ... up to length-epsilon
	var positions: Array[float] = []
	if from_origin:
		var max_x := length - 1e-4
		var x := tick_step
		while x <= max_x:
			positions.append(x)
			x += tick_step
	else:
		var max_x := length * 0.5
		var x := tick_step
		while x <= max_x + 1e-4:
			positions.append(x)
			positions.append(-x)
			x += tick_step
	for px in positions:
		_emit_tick_cross(px, mat)


func _emit_tick_cross(x_pos: float, mat: StandardMaterial3D) -> void:
	# Y-axis tick (vertical cross-bar of the cross)
	var ty := MeshInstance3D.new()
	var tym := CylinderMesh.new()
	tym.height = tick_size * 2.0
	tym.top_radius = tick_thickness
	tym.bottom_radius = tick_thickness
	tym.radial_segments = 6
	ty.mesh = tym
	# Default CylinderMesh is along local +Y, no rotation needed for vertical
	ty.transform = Transform3D(Basis.IDENTITY, Vector3(x_pos, 0.0, 0.0))
	ty.material_override = mat
	add_child(ty)
	_ticks.append(ty)

	# Z-axis tick (horizontal cross-bar of the cross)
	var tz := MeshInstance3D.new()
	var tzm := CylinderMesh.new()
	tzm.height = tick_size * 2.0
	tzm.top_radius = tick_thickness
	tzm.bottom_radius = tick_thickness
	tzm.radial_segments = 6
	tz.mesh = tzm
	# Rotate 90° around X so the cylinder lies along +Z
	var rot_basis := Basis(Vector3(1,0,0), Vector3(0,0,1), Vector3(0,-1,0))
	tz.transform = Transform3D(rot_basis, Vector3(x_pos, 0.0, 0.0))
	tz.material_override = mat
	add_child(tz)
	_ticks.append(tz)

func set_length(new_length: float):
	length = new_length
	_build_reset()

func set_thickness(new_thickness: float):
	thickness = new_thickness
	_build_reset()

func set_color(new_color: Color):
	color = new_color
	_build_reset()

## Toggle tick marks at runtime. Rebuilds geometry.
func set_show_ticks(b: bool) -> void:
	show_ticks = b
	_build_reset()

## Set tick spacing at runtime. Rebuilds geometry.
func set_tick_step(step: float) -> void:
	tick_step = max(0.0, step)
	_build_reset()

func _build_reset():
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_ticks.clear()
	_build_geometry()
