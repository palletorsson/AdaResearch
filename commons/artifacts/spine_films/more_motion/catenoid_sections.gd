extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
const Draw = preload("res://commons/artifacts/spine_films/more_motion/drawing.gd")
var bands:Array[Node3D]=[]
var ribs:Array[Node3D]=[]
var rings_:Array[Node3D]=[]
var body:Node3D
var boundary:Node3D
var radii:Array[float]=[]

func _build() -> void:
	title_text="A WAIST AND SIXTEEN INTERVALS"
	duration=28
	phases.assign(["TWO BOUNDARIES","THE WAIST","RINGS BETWEEN","AN ANALYTIC SURFACE"])
	notes.assign(["The two boundary circles are supplied, not discovered by a solver.","At height u the source radius is c × cosh(u / c). The middle is narrowest.","Sixteen height intervals sample that exact relationship.","The original catenoid function joins the samples. This is not a settling soap film or a stability test."])
	source_paths.assign(["res://commons/primitives/parametric/catenoid.gd"])
	var source=load(source_paths[0]).new()
	source.c=.82;source.u_min=-1.0;source.u_max=1.0;source.u_steps=16;source.v_steps=48;source.v_max=TAU;source.scale_factor=1.0
	source.create_parametric_surface()
	var mesh:Mesh=source.mesh_instance.mesh
	var faces:=mesh.get_faces()
	for row in range(17):
		var y:float=lerpf(-1.0,1.0,float(row)/16)
		var selected:=PackedVector3Array()
		var radius:=0.0
		for v in faces:
			if absf(v.y-y)<.00001:radius=maxf(radius,Vector2(v.x,v.z).length())
		radii.append(radius)
		for j in 48:
			var a:=float(j)/48*TAU;var b:=float(j+1)/48*TAU
			selected.append_array(PackedVector3Array([Vector3(cos(a)*radius,y,sin(a)*radius),Vector3(cos(b)*radius,y,sin(b)*radius)]))
		var ring:=add_lines(selected,Kit.GOLD if row in [0,8,16] else Kit.TEAL)
		ring.position.y=1.6;rings_.append(ring)
	for row in 16:
		var part:=Draw.triangles(faces.slice(row*48*6,(row+1)*48*6))
		var band:=add_mesh(part,Color("b6ced2"),Vector3(0,1.6,0));bands.append(band)
	for j in 8:
		var angle:=float(j)/8*TAU
		var p:=PackedVector3Array()
		for row in 16:
			p.append_array(PackedVector3Array([Vector3(cos(angle)*radii[row],.6+row*.125,sin(angle)*radii[row]),Vector3(cos(angle)*radii[row+1],.6+(row+1)*.125,sin(angle)*radii[row+1])]))
		ribs.append(add_lines(p,Kit.PINK))
	Draw.caption(display,"c = 0.82 · u = −1 … +1",Vector3(0,3.35,0))
	add_box(Vector3(0,.25,0),Vector3(4.4,.12,4.4),Color("202934"))
	evidence={"source_vertices":faces.size(),"triangles":faces.size()/3,"height_intervals":16,"angular_intervals":48,"waist":radii[8],"end_radius":radii[0],"upper_radius":radii[16],"boundary_separation":2.0}
	source.free()

func _draw(time:float) -> void:
	if bands.is_empty():return
	var p:=phase_index(time);var u:=phase_progress(time)
	for i in rings_.size():rings_[i].visible=i in [0,16] or (p>=1 and i==8) or (p>=2 and i<=int(u*17)) or p==3
	for r in ribs:r.visible=p>=1
	for i in bands.size():
		bands[i].visible=p==3 and i<=int(u*17)
		bands[i].position.y=1.6
	frame_scene(Vector3(0,1.6,0),9.8,.35+time*.007,.23)

func validation() -> Dictionary:
	return {"passed":absf(radii[8]-.82)<.0001 and absf(radii[0]-radii[16])<.0001 and radii[0]>radii[8] and evidence.triangles==1536,"evidence":evidence,"mesh_readback_tolerance":.0001}
