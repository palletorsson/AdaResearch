extends Node3D
## A coordinate operation, a surface reading, and a visible record between them.
## Both images and both sphere meshes receive the same CPU sampler. Nothing runs
## on TIME; comparison states change only through these four local controls.
const Kit = preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const STRENGTHS := [0.0, 0.35, 0.8, 1.4]
const IMAGE_RES := 96
const DOMAIN := 4.0
const PROBES := [Vector3(-0.6,0,0.8),Vector3(0,0.6,0.8),Vector3(0.6,0,0.8),Vector3(0.4,0.8,0.4472136),Vector3(-0.4,0.8,0.4472136)]
var strength_index: int = 2
var sample_index: int = 0
var relief: bool = false
var base := FastNoiseLite.new()
var warp_x := FastNoiseLite.new()
var warp_z := FastNoiseLite.new()
var spheres: Array[MeshInstance3D] = []
var arrays: Array = []
var textures: Array[ImageTexture] = []
var images: Array[Image] = []
var values: Array = []
var markers: Array[MeshInstance3D] = []
var _plate_markers: Array[MeshInstance3D] = []
var _readout: Label3D
var _grid: MeshInstance3D
var _board: Node3D
var revision: int = 0
var enclosure: Node3D

func build(original: MeshInstance3D) -> void:
	base.noise_type=FastNoiseLite.TYPE_VALUE; base.fractal_type=FastNoiseLite.FRACTAL_NONE; base.seed=4; base.frequency=1.2
	for n in [warp_x,warp_z]:
		n.noise_type=FastNoiseLite.TYPE_PERLIN; n.fractal_type=FastNoiseLite.FRACTAL_NONE; n.frequency=0.45
	warp_x.seed=19; warp_z.seed=47
	var stone := StandardMaterial3D.new();stone.albedo_color=Color(0.21,0.24,0.28);stone.roughness=0.85
	var dark := StandardMaterial3D.new();dark.albedo_color=Color(0.018,0.03,0.04);dark.roughness=0.9
	_box("Floor",Vector3(0,0.03,0.2),Vector3(7.2,0.06,5.6),stone,true)
	# Keep the authored sphere's mesh resolution, with a private outward-facing copy.
	var support: SphereMesh=original.mesh.duplicate();support.flip_faces=false;support.radius=1.0;support.height=2.0
	arrays=support.get_mesh_arrays()
	original.reparent(self);original.name="DirectSphere";original.transform=Transform3D.IDENTITY
	spheres.append(original)
	var warped:=MeshInstance3D.new();warped.name="WarpedSphere";add_child(warped);spheres.append(warped)
	for i in range(2):
		var x: float=-1.6 if i==0 else 1.6
		spheres[i].position=Vector3(x,1.60,-0.75)
		var mat:=StandardMaterial3D.new();mat.vertex_color_use_as_albedo=true;mat.roughness=0.8
		spheres[i].material_override=mat
		_box("Plinth%d" % i,Vector3(x,0.22,-0.75),Vector3(1.95,0.32,1.95),dark,true)
		_box("Post%d" % i,Vector3(x,0.52,-0.75),Vector3(0.08,0.30,0.08),stone,false)
		var mark:=_dot(Color(1,0.9,0.25),0.035);mark.name="Sample%d" % i;add_child(mark);markers.append(mark)
		var cap:=Kit.stencil("DIRECT · N(p)" if i==0 else "WARPED · N(q)",Vector2(1.8,0.07),Color(0.88,0.94,1))
		cap.position=Vector3(x,0.43,0.58);add_child(cap)
	_board=Node3D.new();_board.name="Instrument";_board.position=Vector3(0,0.90,1.70);_board.rotation_degrees.x=-55;add_child(_board)
	var shell:=Kit.box(Vector3(0,-0.10,-0.04),Vector3(4.65,1.45,0.08),dark);_board.add_child(shell)
	for x in [-1.85,1.85]:_box("Leg",Vector3(x,0.46,1.35),Vector3(0.12,0.92,0.16),stone,true)
	for i in range(2):
		var img:=Image.create(IMAGE_RES,IMAGE_RES,false,Image.FORMAT_RGB8);images.append(img)
		var tex:=ImageTexture.create_from_image(img);textures.append(tex)
		var mat:=StandardMaterial3D.new();mat.albedo_texture=tex;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		var mi:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(1.10,1.10);mi.mesh=quad;mi.material_override=mat
		mi.position=Vector3(-1.53+float(i)*1.53,0.08,0.012);mi.name="Field%d" % i;_board.add_child(mi)
		var cap:=Kit.stencil("DIRECT AT p" if i==0 else "WARPED AT p",Vector2(1.15,0.045),Color(0.85,0.94,1));cap.position=Vector3(mi.position.x,0.69,0.015);_board.add_child(cap)
	_grid=MeshInstance3D.new();_grid.name="CoordinateWitness";_grid.position=Vector3(1.53,0.08,0.015);_board.add_child(_grid)
	var grid_mat:=StandardMaterial3D.new();grid_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;grid_mat.vertex_color_use_as_albedo=true;_grid.material_override=grid_mat
	var cap:=Kit.stencil("CYAN p  →  PINK q",Vector2(1.2,0.045),Color(0.9,0.9,1));cap.position=Vector3(1.53,0.69,0.015);_board.add_child(cap)
	for c in [Color(1,0.9,0.25),Color(1,0.2,0.58),Color(1,0.9,0.25)]:
		var marker:=_dot(c,0.012);_board.add_child(marker);_plate_markers.append(marker)
	_readout=Label3D.new();_readout.name="Readout";_readout.font_size=24;_readout.pixel_size=0.0025;_readout.line_spacing=0.3
	_readout.horizontal_alignment=HORIZONTAL_ALIGNMENT_LEFT;_readout.vertical_alignment=VERTICAL_ALIGNMENT_TOP
	_readout.position=Vector3(-2.20,-0.51,0.018);_readout.modulate=Color(0.88,0.95,1);_board.add_child(_readout)
	var rack: GDScript=load("res://commons/audio/rack_templates/RackTemplates.gd")
	var controls: Node3D=rack.create_panel("",[[{"type":"button","label":"WARP"},{"type":"button","label":"SAMPLE"}],[{"type":"button","label":"RELIEF"},{"type":"button","label":"ZERO"}]],true)
	controls.name="Controls";controls.position=Vector3(2.62,1.02,1.48);controls.rotation_degrees.x=-32;controls.scale=Vector3.ONE*1.9;controls.set_meta("em_local_instrument",true);add_child(controls)
	var actions: Array[Callable]=[next_warp,next_sample,toggle_relief,zero_warp]
	for i in range(4):
		var area: Node=controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton")
		var action: Callable=actions[i];area.button_pressed.connect(func(_button):action.call())
	enclosure=load("res://algorithms/randomness/noisesphere/enclosing_sphere.gd").new()
	add_child(enclosure)
	enclosure.build(self)
	refresh()

func strength() -> float: return float(STRENGTHS[strength_index])

func displacement_at(p: Vector2) -> Vector2:
	return Vector2(warp_x.get_noise_2d(p.x,p.y),warp_z.get_noise_2d(p.x,p.y))

func address_at(p: Vector2, amount: float) -> Vector2:
	return p + amount * displacement_at(p)

func value_at(p: Vector2, amount: float) -> float:
	var q: Vector2 = address_at(p, amount)
	return base.get_noise_2d(q.x, q.y)

func colour(value: float) -> Color:
	return Color(0.28,0.08,0.46).lerp(Color(0.30,1.0,0.79),clampf((value+1.0)*0.5,0.0,1.0))

func radius_at(value: float) -> float:
	return 0.94 + (0.16 * value if relief else 0.0)

func refresh() -> void:
	for k in range(2):
		var amount: float=0.0 if k==0 else strength()
		var samples: Array=[]
		for y in range(IMAGE_RES):
			for x in range(IMAGE_RES):
				var p:=Vector2(lerpf(-DOMAIN,DOMAIN,(x+0.5)/IMAGE_RES),lerpf(DOMAIN,-DOMAIN,(y+0.5)/IMAGE_RES))
				var v: float=value_at(p,amount);samples.append(v);images[k].set_pixel(x,y,colour(v))
		textures[k].update(images[k])
		if values.size()<2:values.append(samples)
		else:values[k]=samples
		var a: Array=arrays.duplicate(true);var verts: PackedVector3Array=a[Mesh.ARRAY_VERTEX];var colors:=PackedColorArray();colors.resize(verts.size())
		for i in range(verts.size()):
			var direction: Vector3=verts[i].normalized()
			var p:=Vector2(direction.x,direction.z)*3.0
			var v: float=value_at(p,amount)
			verts[i]=direction*radius_at(v);colors[i]=colour(v)
		a[Mesh.ARRAY_VERTEX]=verts;a[Mesh.ARRAY_COLOR]=colors
		var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,a)
		var st:=SurfaceTool.new();st.create_from(mesh,0);st.generate_normals();spheres[k].mesh=st.commit()
	if enclosure != null: enclosure.refresh(self)
	_update_witness();revision+=1

func selected() -> Dictionary:
	var direction: Vector3=PROBES[sample_index].normalized()
	var p:=Vector2(direction.x,direction.z)*3.0;var offset: Vector2=displacement_at(p);var q: Vector2=address_at(p,strength())
	return {"p":[p.x,p.y],"d":[offset.x,offset.y],"q":[q.x,q.y],"direct":value_at(p,0),"warped":value_at(p,strength()),"strength":strength(),"sample":sample_index,"relief":relief}

func _plot(p: Vector2) -> Vector3: return Vector3(p.x,p.y,0)*1.10/(2.0*DOMAIN)

func _line(verts: PackedVector3Array, colors: PackedColorArray, a: Vector2, b: Vector2, c: Color) -> void:
	verts.append(_plot(a));verts.append(_plot(b));colors.append(c);colors.append(c)

func _update_witness() -> void:
	var verts:=PackedVector3Array();var colors:=PackedColorArray()
	for row in range(9):
		var r: float=-2.0+row*0.5
		for i in range(32):
			var a: float=-2.0+i*0.125;var b: float=a+0.125
			for pair in [[Vector2(r,a),Vector2(r,b)],[Vector2(a,r),Vector2(b,r)]]:
				_line(verts,colors,pair[0],pair[1],Color(0.18,0.55,0.65))
				_line(verts,colors,address_at(pair[0],strength()),address_at(pair[1],strength()),Color(1,0.28,0.65))
	var rec: Dictionary=selected();var p:=Vector2(rec.p[0],rec.p[1]);var q:=Vector2(rec.q[0],rec.q[1])
	_line(verts,colors,p,q,Color(1,0.95,0.2))
	var a: Array=[];a.resize(Mesh.ARRAY_MAX);a[Mesh.ARRAY_VERTEX]=verts;a[Mesh.ARRAY_COLOR]=colors
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES,a);_grid.mesh=mesh
	_plate_markers[0].position=Vector3(-1.53,0.08,0.03)+_plot(p)
	_plate_markers[1].position=Vector3(-1.53,0.08,0.04)+_plot(q)
	_plate_markers[2].position=Vector3(0,0.08,0.03)+_plot(p)
	for i in range(2):
		var direction: Vector3=PROBES[sample_index].normalized()
		var v: float=rec.direct if i==0 else rec.warped
		markers[i].position=spheres[i].position+direction*(radius_at(v)+0.045)
	_readout.text="WARP %.2f | %s | sample %d/5 | static until you act\n" % [strength(),"RELIEF" if relief else "SKIN",sample_index+1]
	_readout.text+="p (%+.3f, %+.3f)  →  q (%+.3f, %+.3f)\n" % [p.x,p.y,q.x,q.y]
	_readout.text+="N(p) %+.4f  |  N(q) %+.4f  |  q = p + warp × offset\n" % [rec.direct,rec.warped]
	_readout.text+="Yellow: same place on the body. Pink: borrowed address on the left."

func next_warp() -> void:
	strength_index=(strength_index+1)%STRENGTHS.size();refresh()
func zero_warp() -> void:
	strength_index=0;refresh()
func next_sample() -> void:
	sample_index=(sample_index+1)%PROBES.size();_update_witness()
func toggle_relief() -> void:
	relief=not relief;refresh()

func _dot(tint: Color, radius: float) -> MeshInstance3D:
	var n:=MeshInstance3D.new();var mesh:=SphereMesh.new();mesh.radius=radius;mesh.height=2*radius;mesh.radial_segments=12;mesh.rings=6;n.mesh=mesh
	n.material_override=Kit.emissive(tint,1.4);return n

func _box(label: String, at: Vector3, size: Vector3, material: Material, collision: bool) -> void:
	var mesh: MeshInstance3D=Kit.box(at,size,material);mesh.name=label;add_child(mesh)
	if collision:
		var body:=StaticBody3D.new();var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=size;shape.shape=box;body.position=at;body.add_child(shape);add_child(body)
