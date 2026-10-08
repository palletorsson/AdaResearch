extends Node3D
## Original museum carton: a repeatable printed object, not a Brillo facsimile.
@export var word := "AGAIN"
@export var paper_color := Color(0.95,0.94,0.9)
@export var ink_color := Color(0.065,0.13,0.28)
@export var accent_color := Color(0.8,0.08,0.055)

func _ready() -> void:
	var paper := mat(paper_color)
	var ink := mat(ink_color)
	var accent := mat(accent_color)
	box(self,Vector3(0.64,0.64,0.64),Vector3(0,0.32,0),paper)
	for side in 4:
		var face := Node3D.new();face.rotation.y=side*PI/2;add_child(face)
		box(face,Vector3(0.62,0.05,0.003),Vector3(0,0.53,0.322),accent)
		box(face,Vector3(0.62,0.022,0.003),Vector3(0,0.1,0.322),ink)
		text(face,word,Vector3(0,0.34,0.326),0.0030,ink_color,52)
		text(face,"READY / MADE",Vector3(0,0.46,0.326),0.0014,ink_color,30)
		text(face,"ONE BOX / MANY PLACES",Vector3(0,0.18,0.326),0.0010,ink_color,28)
	box(self,Vector3(0.085,0.002,0.635),Vector3(0,0.641,0),accent)
	for i in range(11):
		box(self,Vector3(0.004 if i%3==0 else 0.008,0.002,0.075),Vector3(-0.23+i*0.011,0.642,0.2),ink)

func mat(colour: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color=colour;m.roughness=0.75;return m

func box(parent: Node3D,size: Vector3,at: Vector3,material: Material) -> void:
	var node := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size
	node.mesh=mesh;node.material_override=material;node.position=at;parent.add_child(node)

func text(parent: Node3D,words: String,at: Vector3,pixel: float,colour: Color,font: int) -> void:
	var label := Label3D.new();label.text=words;label.position=at;label.pixel_size=pixel;label.font_size=font
	label.modulate=colour;label.outline_size=0;parent.add_child(label)
