extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
const Draw = preload("res://commons/artifacts/spine_films/more_motion/drawing.gd")
var originals:PackedVector3Array
var final_meshes:Array[Mesh]=[]
var body:MeshInstance3D
var twin:MeshInstance3D
var samples:Array[float]=[]
var warped:Array[float]=[]
var pointers:Array[MeshInstance3D]=[]
var marks:Array[Node3D]=[]
var skin_material:StandardMaterial3D
var ghost_material:StandardMaterial3D
var radius_frame:Node3D
var label_:Label3D
var source
var template:Array

func _build() -> void:
	title_text="ONE SAMPLE BECOMES COLOUR AND DISTANCE"
	duration=28
	phases.assign(["READ A SKIN","GIVE THE VALUE A RADIUS","THE WHOLE BODY ANSWERS","BORROW ANOTHER ADDRESS"])
	notes.assign(["The existing noise-sphere study samples a held field at each direction on the sphere.","Its radius function is 0.94 + 0.16 × value. A sample becomes a radial offset.","The same source values still supply colour. The animated transition merely reveals its skin and relief endpoints.","At the same direction, the source borrows q = p + 0.8 × offset. A new address changes the value and the surface."])
	source_paths.assign(["res://algorithms/randomness/noisesphere/warp_study.gd","res://algorithms/randomness/noisesphere/noisesphere.gd"])
	source=load(source_paths[0]).new()
	source.base.noise_type=FastNoiseLite.TYPE_VALUE;source.base.fractal_type=FastNoiseLite.FRACTAL_NONE;source.base.seed=4;source.base.frequency=1.2
	for field in [source.warp_x,source.warp_z]:field.noise_type=FastNoiseLite.TYPE_PERLIN;field.fractal_type=FastNoiseLite.FRACTAL_NONE;field.frequency=.45
	source.warp_x.seed=19;source.warp_z.seed=47
	var mesh:=SphereMesh.new();mesh.radius=1;mesh.height=2;mesh.radial_segments=48;mesh.rings=24
	template=mesh.get_mesh_arrays();originals=template[Mesh.ARRAY_VERTEX]
	for v in originals:
		var direction:=v.normalized();var p:=Vector2(direction.x,direction.z)*3
		samples.append(source.value_at(p,0));warped.append(source.value_at(p,.8))
	for step in 33:final_meshes.append(make_mesh(samples,float(step)/32))
	final_meshes.append(make_mesh(warped,1))
	skin_material=Kit.material(Color.WHITE);skin_material.vertex_color_use_as_albedo=true
	ghost_material=skin_material.duplicate()
	ghost_material.albedo_color=Color(1,1,1,.12)
	ghost_material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	body=Kit.node(display,final_meshes[0],Vector3(0,1.65,0),skin_material);body.scale=Vector3.ONE*1.5
	twin=Kit.node(display,final_meshes[-1],Vector3(2,1.65,0),skin_material);twin.scale=Vector3.ONE*1.5
	var circles:=PackedVector3Array()
	for i in 64:
		var a:=float(i)/64*TAU;var b:=float(i+1)/64*TAU
		for axis in [0,1]:
			var start:=Vector3(cos(a),sin(a),0) if axis==0 else Vector3(0,sin(a),cos(a))
			var end:=Vector3(cos(b),sin(b),0) if axis==0 else Vector3(0,sin(b),cos(b))
			circles.append_array(PackedVector3Array([body.position+start*.94*1.5,body.position+end*.94*1.5]))
	radius_frame=add_lines(circles,Kit.WHITE)
	var largest_offset:=0.0
	for v in source.PROBES:
		var direction:Vector3=v.normalized()
		var value:float=source.value_at(Vector2(direction.x,direction.z)*3,0)
		var from:Vector3=direction*.94*1.5+body.position
		var end:Vector3=direction*source.radius_at(value)*1.5+body.position
		pointers.append(Kit.rod(display,from,end,.018,Kit.material(Kit.GOLD,true)))
		marks.append(add_ball(from,.028,Kit.WHITE));marks.append(add_ball(end,.043,Kit.GOLD))
		pointers.append(Kit.rod(display,body.position,end,.009,Kit.material(Color("53716f"),true)))
		largest_offset=maxf(largest_offset,absf(source.radius_at(value)-.94))
	label_=Draw.caption(display,"",Vector3(0,3.5,0))
	var max_difference:=0.0
	for i in samples.size():max_difference=maxf(max_difference,absf(samples[i]-warped[i]))
	evidence={"display_vertices":originals.size(),"radial_segments":48,"rings":24,"source_seeds":[4,19,47],"warp_amount":.8,"maximum_value_change":max_difference,"radius_base":.94,"radius_gain":.16,"largest_witness_offset":largest_offset}
	source.free();source=null

func make_mesh(values:Array[float],relief_amount:float) -> ArrayMesh:
	var arrays:=template.duplicate(true)
	var vertices:=PackedVector3Array();var colors:=PackedColorArray()
	for i in originals.size():
		var radius:float=lerpf(.94,source.radius_at(values[i]),relief_amount)
		vertices.append(originals[i].normalized()*radius)
		colors.append(source.colour(values[i]))
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_COLOR]=colors
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var st:=SurfaceTool.new();st.create_from(mesh,0);st.generate_normals()
	return st.commit()

func _draw(time:float) -> void:
	if body==null:return
	var p:=phase_index(time);var u:=phase_progress(time)
	body.mesh=final_meshes[0 if p<2 else (int(u*32) if p==2 else 32)]
	body.material_override=ghost_material if p==1 else skin_material
	body.position.x=-1.85 if p==3 else 0.0
	twin.visible=p==3;twin.position.x=1.85
	for line in pointers:line.visible=p==1
	for dot in marks:dot.visible=p==1
	radius_frame.visible=p==1
	label_.text="SAME VALUES · COLOUR" if p==0 else ("radius = 0.94 + 0.16 × value" if p<3 else "DIRECT p                     WARPED q")
	frame_scene(Vector3(0,1.65,0),11.7 if p==3 else 8.5,.15+time*.009,.18)

func validation() -> Dictionary:
	var error:=0.0
	var vertices:PackedVector3Array=final_meshes[32].surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	# Generated normals can expand vertices; each retained radius must stay in the source range.
	for v in vertices:error=maxf(error,maxf(0.0,absf(v.length()-.94)-.16001))
	return {"passed":evidence.maximum_value_change>.1 and error==0.0 and samples.size()==warped.size(),"evidence":evidence}
