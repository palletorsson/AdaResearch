extends RefCounted
## Metres: seat .46 m, chair top .93 m, table .75 m, door 2.2 m.
const Kit=preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const PINK=Color("d55d90")
const DARK=Color("252b31")
const TEAL=Color("388b91")
static func material(c: Color) -> StandardMaterial3D: return Kit.rams_body(c,0)
static func box(parent: Node3D, p: Vector3, size: Vector3, color: Color, solid: bool=false) -> MeshInstance3D:
	var mesh:=Kit.box(p,size,material(color));parent.add_child(mesh)
	if solid: parent.add_child(Kit.box_collider(size,p))
	return mesh
static func chair(parent: Node3D,p: Vector3,color: Color,variant: int=0) -> Node3D:
	var root:=Node3D.new();parent.add_child(root);root.position=p
	box(root,Vector3(0,0.46,0),Vector3(0.47,0.07,0.47),color)
	for x in [-0.19,0.19]:
		for z in [-0.19,0.19]: box(root,Vector3(x,0.22,z),Vector3(0.045,0.44,0.045),color)
	for x in [-0.19,0.19]: box(root,Vector3(x,0.68,-0.19),Vector3(0.045,0.50,0.045),color)
	box(root,Vector3(0,0.81,-0.19),Vector3(0.45,0.23,0.055),color)
	if variant&1:
		for x in [-0.28,0.28]: box(root,Vector3(x,0.64,0),Vector3(0.07,0.055,0.45),color)
	if variant&2: box(root,Vector3(0,0.65,-0.19),Vector3(0.36,0.06,0.06),color)
	root.add_child(Kit.box_collider(Vector3(0.5,0.94,0.5),Vector3(0,0.47,0)))
	return root
static func label(parent: Node3D,text: String,p: Vector3,width: float=3.5,font: int=31) -> Label3D:
	var root:=Node3D.new();parent.add_child(root);root.position=p
	var back:=box(root,Vector3.ZERO,Vector3(width,0.48,0.04),Color("ece7dc"))
	back.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	var l:=Label3D.new();root.add_child(l);l.position.z=0.026;l.text=text;l.font_size=font;l.pixel_size=0.0038
	l.modulate=Color("26343c");l.outline_size=0
	return l
static func sphere(parent: Node3D,p: Vector3,radius: float,color: Color) -> MeshInstance3D:
	var mesh:=SphereMesh.new();mesh.radius=radius;mesh.height=radius*2;mesh.radial_segments=20;mesh.rings=12
	var view:=MeshInstance3D.new();view.mesh=mesh;view.material_override=material(color);parent.add_child(view);view.position=p;return view
static func table(parent: Node3D, width: float=1.6, depth: float=0.9) -> void:
	var top:=box(parent,Vector3(0,0.72,0),Vector3(width,0.06,depth),Color("b89773"),true)
	top.name="TableTop"
	box(parent,Vector3(0,0.64,depth/2-0.025),Vector3(width,0.16,0.05),Color("b89773"))
	for x in [-width/2+0.15,width/2-0.15]:
		for z in [-depth/2+0.13,depth/2-0.13]:box(parent,Vector3(x,0.35,z),Vector3(0.07,0.7,0.07),DARK)

static func ink(parent: Node3D, words: String, p: Vector3, size: int=32, pixel: float=0.002) -> Label3D:
	var l:=Label3D.new();parent.add_child(l);l.text=words;l.position=p;l.font_size=size;l.pixel_size=pixel
	l.font=preload("res://commons/utils/baked_text_albedo.gd").project_font();l.modulate=DARK;l.outline_size=0
	return l

static func lathe(parent: Node3D, profile: Array[Vector2], p: Vector3, color: Color) -> MeshInstance3D:
	# Profile coordinates are radius/height; the hollow interior stays open from above.
	var surface:=SurfaceTool.new();surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in profile.size()-1:
		for j in 64:
			var points: Array[Vector3]=[]
			for q in [Vector2i(i,j),Vector2i(i,j+1),Vector2i(i+1,j),Vector2i(i+1,j+1)]:
				var a: float=TAU*q.y/64.0;var r: Vector2=profile[q.x]
				points.append(Vector3(r.x*cos(a),r.y,r.x*sin(a)))
			for n in [0,1,2,1,3,2]:surface.add_vertex(points[n])
	surface.index();surface.generate_normals()
	var view:=MeshInstance3D.new();view.mesh=surface.commit();view.material_override=material(color)
	parent.add_child(view);view.position=p;return view
