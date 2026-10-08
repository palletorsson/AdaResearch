extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var cells: Array[MeshInstance3D] = []
var places: Array[Vector3] = []
var values: Array[int] = []
var marker: MeshInstance3D
var readout: Label3D

func _build() -> void:
	title_text = "A CHOICE BECOMES A PASSAGE"
	duration = 26.0
	phases.assign(["One retained decision", "The stream enters cells", "The same marks become walls", "A pattern becomes a place"])
	notes.assign(["A seeded example from the existing 10 PRINT structure.", "One decision per cell; the probability is allowed to change.", "Only the height changes. Every diagonal keeps its choice.", "The pattern offers walls and gaps. Not every gap connects."])
	source_paths.assign(["res://commons/artifacts/ten_print_structure/ten_print_structure.gd"])
	var source: Node3D = load(source_paths[0]).new()
	source.set("seed",1982)
	source.set("size",1.2)
	source.set("form","floor")
	var length: float = source.call("slab_length")
	var thickness: float = source.call("slab_thickness")
	var pink := Kit.material(Kit.PINK)
	var teal := Kit.material(Kit.TEAL)
	for row in 4:
		for col in 4:
			var index := row*4+col
			var value := 1 if source.call("coin_is_forward",index) else 2
			values.append(value)
			var transform_: Transform3D = source.call("slab_transform",col,row,value)
			var at := transform_.origin - Vector3(2.4,0,2.4)
			places.append(at)
			var n := Kit.box(display,at,Vector3(length,0.25,thickness),pink if value==1 else teal)
			n.basis = transform_.basis
			cells.append(n)
			Kit.box(display,Vector3(at.x,-0.04,at.z),Vector3(1.16,0.08,1.16),Kit.material(Color("252c36")))
	source.free()
	marker = Kit.dot(display,Vector3.ZERO,0.12,Kit.material(Kit.GOLD,true))
	readout = Kit.label(display,"",Vector3(0,3.0,0),Kit.WHITE,.006)
	evidence = {"source_method":"coin_is_forward / slab_transform", "seed":1982,"cells":16,"decisions":values,"changes_source":false}

func _draw(time: float) -> void:
	var reveal := clampi(int((time-3.0)*2.5)+1,1,16)
	var height_ := lerpf(0.25,2.4,Kit.progress(time,11.0,17.0))
	for i in cells.size():
		cells[i].visible = i < reveal
		(cells[i].mesh as BoxMesh).size.y = height_
		cells[i].position = Vector3(places[i].x,height_*0.5,places[i].z)
	var index := mini(reveal-1,15)
	marker.position = Vector3(places[index].x,height_+0.18,places[index].z)
	marker.visible = time < 17.0
	readout.text = "%d / 16 choices kept\n%.2f m high" % [reveal,height_]
	var enter := Kit.progress(time,18.0,24.0)
	frame_from_position(Vector3(0,0.8,0),Vector3(6.4,5.7,7.8).lerp(Vector3(4.6,3.3,5.2),enter))
