extends Node3D
## A second drawing of the same samples: x and age, projected onto a floor.
## It never writes into the motion state or the stored record.
var source: Node3D
var segments := MultiMeshInstance3D.new()

func _ready() -> void:
	name = "FloorRecord"
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.014
	cylinder.bottom_radius = 0.014
	cylinder.height = 1.0
	cylinder.radial_segments = 6
	var ink := StandardMaterial3D.new()
	ink.albedo_color = Color(0.1, 0.8, 0.9)
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cylinder.material = ink
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = cylinder
	mm.instance_count = source.max_trail_length
	mm.visible_instance_count = 0
	segments.multimesh = mm
	add_child(segments)
	for seconds in range(0,11,2):
		var label := Label3D.new()
		label.text = "%d s" % seconds
		label.font_size = 40
		label.pixel_size = 0.002
		label.position = Vector3(2.05,0.035,-seconds*source.time_speed)
		label.rotation_degrees.x = -90
		add_child(label)
	var title := Label3D.new()
	title.text = "POSITION / AGE\nProjected record — height omitted"
	title.font_size = 28
	title.pixel_size = 0.0025
	title.position = Vector3(0,0.035,0.55)
	title.rotation_degrees.x = -90
	add_child(title)

func floor_position(sample: Vector3) -> Vector3:
	return Vector3(sample.x,0.035,-(source.time-sample.z)*source.time_speed)

func draw_record() -> void:
	if segments.multimesh == null: return
	var points: Array = source.trail_points
	var count := maxi(0,points.size()-1)
	segments.multimesh.visible_instance_count = count
	for i in count:
		var a := floor_position(points[i])
		var b := floor_position(points[i+1])
		var displacement := b-a
		var distance := displacement.length()
		# Scale along the cylinder's local Y before rotating into the floor plane.
		var basis := Basis(Quaternion(Vector3.UP,displacement.normalized())) * Basis.from_scale(Vector3(1,distance,1)) if distance>0.00001 else Basis.from_scale(Vector3.ZERO)
		segments.multimesh.set_instance_transform(i,Transform3D(basis,(a+b)*0.5))
