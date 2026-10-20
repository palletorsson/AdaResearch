extends Node3D
## Architectural linework from the same frame and saved partitions as the game.
const Source := preload("room_source.gd")
var strokes: Array[Transform3D] = []
var structure_size := Vector2.ZERO
var shaft_count := 0
var column_count := 0
var partition_count := 0

func _ready() -> void:
	call_deferred("build") # Parent's saved part placements have now been applied.

func stroke(a: Vector2,b: Vector2,weight := .003) -> void:
	var start := Vector3(a.x/10.0,0,a.y/10.0)
	var end := Vector3(b.x/10.0,0,b.y/10.0)
	var length := start.distance_to(end)
	if length < .0001: return
	var axis := (end-start)/length
	strokes.append(Transform3D(Basis(axis,Vector3.UP,axis.cross(Vector3.UP)).scaled_local(Vector3(length,.003,weight)),(start+end)*.5))

func rectangle(centre: Vector2,size: Vector2,weight := .003) -> void:
	var lo := centre-size*.5
	var hi := centre+size*.5
	stroke(lo,Vector2(hi.x,lo.y),weight)
	stroke(Vector2(hi.x,lo.y),hi,weight)
	stroke(hi,Vector2(lo.x,hi.y),weight)
	stroke(Vector2(lo.x,hi.y),lo,weight)

func note(words: String, at: Vector2, size := 22) -> void:
	var label := Label3D.new()
	label.text = words
	label.position = Vector3(at.x/10.0,.005,at.y/10.0)
	label.rotation.x = -PI/2
	label.font_size = size
	label.pixel_size = .0013
	label.outline_size = 0
	label.modulate = Color("b8e9e8")
	add_child(label)

func build() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/layout.json"))
	structure_size = Vector2(float(spec.width),float(spec.depth))
	rectangle(Vector2.ZERO,structure_size,.006)
	for shaft in spec.shafts:
		var centre := Vector2(float(shaft.x),0)
		var size := Vector2(float(spec.shaft_width),float(spec.shaft_depth))
		rectangle(centre,size,.005)
		stroke(centre-size*.5,centre+size*.5,.0015)
		stroke(centre+Vector2(-size.x,size.y)*.5,centre+Vector2(size.x,-size.y)*.5,.0015)
		note("SHAFT "+str(shaft.name),centre+Vector2(0,2.0))
		shaft_count += 1
	for x in spec.column_x:
		for z in spec.column_z:
			rectangle(Vector2(float(x),float(z)),Vector2.ONE*float(spec.column_width),.005)
			column_count += 1
	var rooms := Source.read_rooms()
	for wall in rooms.floors[3].walls:
		var a := Vector2(float(wall.from[0]),float(wall.from[1]))
		var b := Vector2(float(wall.to[0]),float(wall.to[1]))
		rectangle((a+b)*.5,(b-a).abs()+Vector2(.18,.18))
		partition_count += 1
	var gate: Node3D = get_parent().get_parent().get_node_or_null("MeasurementRoom")
	if gate != null:
		for wall in gate._partitions:
			var size: Vector3 = wall.mesh.size
			var along := Vector3(size.x*.5,0,0) if size.x>size.z else Vector3(0,0,size.z*.5)
			var a: Vector3 = wall.to_global(-along)
			var b: Vector3 = wall.to_global(along)
			stroke(Vector2(a.x,a.z),Vector2(b.x,b.z),.005)
			partition_count += 1
	var descent: Dictionary = spec.descent
	if descent.get("mode") == "corner_pads":
		rectangle(Vector2(11.7,1.9),Vector2(1.56,2.2))
	elif descent.get("mode") == "balcony":
		rectangle(Vector2(0,float(spec.depth)*.5+float(descent.balcony_depth)*.5),Vector2(float(descent.balcony_width),float(descent.balcony_depth)))
	stroke(Vector2(-21,-10),Vector2(21,-10),.002)
	for x in [-21,21]: stroke(Vector2(x,-9.6),Vector2(x,-10.4),.002)
	note("42.00 m",Vector2(0,-10.6),27)
	note("POINT LINES  /  FLOOR 03  /  1:10",Vector2(-9,10.8),25)
	note("18.00 m",Vector2(17.5,0))
	var drawn := MultiMeshInstance3D.new()
	drawn.name = "ArchitecturalLinework"
	drawn.multimesh = MultiMesh.new()
	drawn.multimesh.transform_format = MultiMesh.TRANSFORM_3D
	drawn.multimesh.mesh = BoxMesh.new()
	(drawn.multimesh.mesh as BoxMesh).size = Vector3.ONE
	drawn.multimesh.instance_count = strokes.size()
	var ink := StandardMaterial3D.new()
	ink.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	ink.albedo_color = Color("bce9e8")
	drawn.material_override = ink
	for i in range(strokes.size()): drawn.multimesh.set_instance_transform(i,strokes[i])
	add_child(drawn)
