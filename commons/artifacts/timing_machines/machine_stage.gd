extends Node3D
## Shared construction helpers for the two timing encounters. Dimensions are metres.
const PUSH = preload("res://commons/interactables/push_button.tscn")
var buttons: Dictionary = {}
var readout: Label3D
func material(hex: String, glow: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color=Color(hex);m.roughness=0.48
	if glow: m.emission_enabled=true;m.emission=Color(hex);m.emission_energy_multiplier=1.5
	return m
func box(at: Vector3, size: Vector3, mat: Material, solid: bool = false, host: Node3D = self) -> MeshInstance3D:
	var mesh := MeshInstance3D.new();var shape := BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.position=at;mesh.material_override=mat;host.add_child(mesh)
	if solid:
		var body := StaticBody3D.new();body.position=at;host.add_child(body)
		var c := CollisionShape3D.new();var s := BoxShape3D.new();s.size=size;c.shape=s;body.add_child(c)
	return mesh
func label(text: String, at: Vector3, pixels: float = 0.002) -> Label3D:
	var l := Label3D.new();l.text=text;l.position=at;l.font_size=42;l.pixel_size=pixels;l.modulate=Color("f7eeda");add_child(l);return l
func console(ids: Array, z: float, title: String) -> void:
	box(Vector3(0,0.94,z),Vector3(3.8,0.16,0.68),material("263a44"),true)
	for x in [-1.5,1.5]:box(Vector3(x,0.45,z),Vector3(0.15,0.9,0.35),material("263a44"),true)
	for i in ids.size():
		var id: String=ids[i];var b=PUSH.instantiate();b.position=Vector3((i-(ids.size()-1)*0.5)*0.7,1.04,z+0.07);b.scale=Vector3.ONE*1.15;add_child(b);buttons[id]=b;b.pressed.connect(act.bind(id))
		var caption=label(id,b.position+Vector3(0,0.06,0.17),0.00095);caption.rotation_degrees.x=-55
	readout=label(title,Vector3(0,1.52,z-0.12),0.00135)
	box(Vector3(0,1.52,z-0.17),Vector3(3.8,0.63,0.055),material("15232c"))
func act(_id: String) -> void: pass
