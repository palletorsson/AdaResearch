extends Node3D
## Supplied drawing and readouts. All lengths arrive from the learner script.
## The grey reference is fixed at 256 segments, not an exact rendered circle.

const CircleSamples = preload("res://prepared/circle_samples.gd")
const Segment = preload("res://prepared/segment.gd")
const PolygonMaterial = preload("res://prepared/cube_fold.tres")

var polygon_segments: Array[Segment] = []
var reference_segments: Array[Segment] = []
var readout := Label3D.new()
var status := Label3D.new()
var content := Node3D.new()
var reference_material := StandardMaterial3D.new()
var within_tolerance := false

func _init():
    reference_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    reference_material.albedo_color = Color(0.61, 0.6, 0.65)
    readout.position = Vector3(0, -1.17, 0)
    readout.font_size = 24
    readout.pixel_size = 0.003
    readout.outline_size = 0
    status.position = Vector3(0, -1.44, 0)
    status.font_size = 24
    status.pixel_size = 0.003
    status.outline_size = 0
    add_child(content)
    add_child(readout)
    add_child(status)

func show_polygon(points: Array[Vector3], radius: float, perimeter: float, gap: float, tolerance: float) -> void:
    for child in content.get_children():
        content.remove_child(child)
        child.queue_free()
    polygon_segments.clear()
    reference_segments.clear()
    # Duplicate only for closing the drawing; never append to the learner's list.
    var closed: Array[Vector3] = points.duplicate()
    closed.append(points[0])
    for i in range(closed.size() - 1):
        polygon_segments.append(_segment(closed[i], closed[i+1], 0.014, PolygonMaterial))
    var reference: Array[Vector3] = CircleSamples.points_on_circle(256, radius)
    reference.append(reference[0])
    for i in range(reference.size() - 1):
        reference_segments.append(_segment(reference[i], reference[i+1], 0.004, reference_material))
    within_tolerance = gap <= tolerance
    readout.text = "%d SIDES   /   RADIUS %.2f m\nPerimeter %.6f m   /   Circle %.6f m\nShortfall %.6f m   /   Tolerance %.6f m" % [points.size(), radius, perimeter, TAU*radius, gap, tolerance]
    status.text = "WITHIN TOLERANCE" if within_tolerance else "OUTSIDE TOLERANCE"
    status.modulate = Color(0.91,0.73,0.47) if within_tolerance else Color(0.91,0.67,0.77)

func _segment(a: Vector3, b: Vector3, thickness: float, material: Material) -> Segment:
    var segment := Segment.new()
    segment.mesh.top_radius = thickness
    segment.mesh.bottom_radius = thickness
    segment.mesh.radial_segments = 6
    segment.mesh.rings = 1
    segment.material_override = material
    content.add_child(segment)
    segment.show_between(a, b)
    return segment
