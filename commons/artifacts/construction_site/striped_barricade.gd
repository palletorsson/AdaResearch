extends Node3D
## Godot reconstruction inspired by props_wasteland/barricade001a.
## Folding timber A-frame, striped boards on both sides. Floor-centred, metres.
const Stock := preload("stock.gd")

func _ready() -> void:
	var timber := Stock.finish("71634f", .94)
	var white := Stock.finish("d6d0bc", .82)
	var orange := Stock.finish("c54c28", .78)
	var steel := Stock.finish("676e70", .58, .6)
	var rubber := Stock.finish("292b2a", .97)
	for x in [-.35, .35]:
		for side in [-1.0, 1.0]:
			var start := Vector3(x, .04, side*.42)
			var end := Vector3(x, 1.06, side*.025)
			var leg := Stock.box(self, "FoldingLeg", (start+end)*.5, Vector3(.065, start.distance_to(end), .05), timber)
			leg.quaternion = Quaternion(Vector3.UP, start.direction_to(end))
			Stock.box(self, "Foot", Vector3(x,.018,side*.42), Vector3(.082,.036,.10), rubber)
		Stock.tube(self,"HingePin",Vector3(x-.048,1.055,0),Vector3(x+.048,1.055,0),.025,steel,false)
		Stock.tube(self,"StayBar",Vector3(x,.35,-.29),Vector3(x,.35,.29),.008,steel,false)
	for side in [-1.0, 1.0]:
		for y in [.43,.87]:
			var board := Stock.box(self,"StripedBoard",Vector3(0,y,side*lerpf(.42,.025,(y-.04)/1.02)),Vector3(.94,.21,.035),white)
			board.rotation.x = -side*atan2(.395,1.02)
			for face in [-1.0, 1.0]:
				_stripes(board,face,orange)
				for x in [-.35,.35]:
					Stock.tube(board,"BoardBolt",Vector3(x,0,face*.019),Vector3(x,0,face*.026),.011,steel,false)
			# Small exposed corners and scratches, made from geometry, not a texture.
			for i in range(9):
				var x := -.445+i*.11
				var edge := .099 if i%2==0 else -.099
				Stock.box(board,"PaintWear",Vector3(x,edge,side*.0185),Vector3(.018+(i%3)*.009,.005,.002),timber,false)
	Stock.batch_static(self)

func _stripes(board: Node3D, side: float, material: Material) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var clip := PackedVector2Array([Vector2(-.466,-.101),Vector2(.466,-.101),Vector2(.466,.101),Vector2(-.466,.101)])
	for i in range(-4,5):
		var x := i*.24
		var stripe := PackedVector2Array([Vector2(x-.07,-.14),Vector2(x+.045,-.14),Vector2(x+.185,.14),Vector2(x+.07,.14)])
		for polygon in Geometry2D.intersect_polygons(stripe,clip):
			var indices := Geometry2D.triangulate_polygon(polygon)
			for index in indices:
				var p: Vector2 = polygon[index]
				surface.set_normal(Vector3(0,0,side))
				surface.add_vertex(Vector3(p.x,p.y,side*.018))
	var paint := MeshInstance3D.new()
	paint.name = "DiagonalPaint"
	paint.mesh = surface.commit()
	# Thin applied paint is readable from either side; no alpha or shader needed.
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	paint.material_override = material
	board.add_child(paint)
