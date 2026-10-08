extends Node3D
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const TYPES = ["tetrahedron","cube","octahedron","dodecahedron","icosahedron"]
const SOURCES = [
	"res://commons/primitives/tetrahedron/grab_tetrahedron.tscn",
	"res://commons/primitives/cubes/grab_cube.tscn",
	"res://commons/primitives/octahedron/grab_octahedron.tscn",
	"res://commons/primitives/dodecahedron/grab_dodecahedron.tscn",
	"res://commons/primitives/icosahedron/grab_icosahedron.tscn"]
var solids: Array[XRToolsPickable]=[]
var columns: Array[MeshInstance3D]=[]

func _ready() -> void:
	preload("res://commons/artifacts/ignorance_gallery/gallery_architecture.gd").bay(self,12.0)
	var divisions := [4,5,6,8,12,20,32,64]
	for side in [-1,1]:
		for i in divisions.size():
			var z := -4.5+float(i)*1.28
			columns.append(Kit.cylinder(self,Vector3(side*6.4,1.9,z),0.32,3.8,divisions[i]))
			Kit.block(self,Vector3(0.85,0.14,0.85),Vector3(side*6.4,0.07,z))
			Kit.block(self,Vector3(0.85,0.14,0.85),Vector3(side*6.4,3.73,z),Kit.WHITE,false)
			Kit.label(self,str(divisions[i]),Vector3(side*6.4,0.18,z-0.34),0.0016,PI)
	# A lintel and inscription frame the actual entrance, with clear headroom.
	Kit.block(self,Vector3(4.9,0.64,0.10),Vector3(0,3.22,-6.61))
	Kit.label(self,"LET NO ONE IGNORANT OF GEOMETRY ENTER",Vector3(0,3.22,-6.667),0.0034,PI)
	var positions := [Vector3(-2.2,0,-1.0),Vector3(0,0,-1.6),Vector3(2.2,0,-1.0),Vector3(-1.35,0,1.55),Vector3(1.35,0,1.55)]
	for i in TYPES.size():
		var source: Node3D=load(SOURCES[i]).instantiate();add_child(source)
		var mesh: Mesh
		for n: MeshInstance3D in source.find_children("*","MeshInstance3D",true,false):
			if n.mesh!=null and not str(n.name).begins_with("Highlight"):
				mesh=n.mesh;break
		assert(mesh!=null,"Missing source solid "+str(TYPES[i]))
		var at: Vector3=positions[i]
		Kit.pedestal(self,at,0.88,1.12)
		var body := Kit.pickable_mesh(self,mesh,at+Vector3.UP*0.885,Kit.BLACK if i%2==0 else Kit.WHITE,0.88)
		body.name=String(TYPES[i]).capitalize();body.set_meta("solid_type",TYPES[i]);solids.append(body)
		Kit.label(self,String(TYPES[i]).to_upper(),at+Vector3(0,0.56,-0.568),0.0015,PI)
		remove_child(source);source.queue_free()
	Kit.lamp(self,Vector3(-3.5,3.4,0),0.85)
	Kit.lamp(self,Vector3(3.5,3.4,0),0.85)
	_neutral_display.call_deferred()

func _neutral_display() -> void:
	var hall: Node = self
	while hall != null and not hall.has_meta("em_map"): hall=hall.get_parent()
	if hall == null or str(hall.get_meta("em_map")) != "Primitives_Ignorance": return
	if hall.has_node("IgnoranceStonePalette"): return
	var palette := preload("res://commons/rendering/museum_grayscale.gd").new()
	palette.name="IgnoranceStonePalette"
	hall.add_child(palette)
