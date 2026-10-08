extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
const Draw = preload("res://commons/artifacts/spine_films/more_motion/drawing.gd")
var bodies:Array[MeshInstance3D]=[]
var materials:Array[ShaderMaterial]=[]
var wires:Array[MeshInstance3D]=[]
var labels:Array[Label3D]=[]
var bare:StandardMaterial3D
var mesh:SphereMesh
var source_code:String

func _build() -> void:
	title_text="ONE FUNCTION, MANY ADDRESSES"
	duration=28
	phases.assign(["THE SAME MESH","A SINGLE UV DOMAIN","FOLD THE COORDINATES","ONE / FOUR / EIGHT"])
	notes.assign(["All three bodies use this one sphere mesh. Its vertex count will stay fixed.","The hall's original tile shader evaluates one circle in its UV coordinates.","Multiplying UV before fract() repeats the local coordinate. No new spheres or faces are added.","The same shader at grid sizes 1, 4 and 8. UV distortion and the seam belong to this sphere's mapping."])
	source_paths.assign(["res://algorithms/shaders/book_of_shaders/patterns_tile.gdshader","res://algorithms/shaders/book_of_shaders/shader_05_patterns.gd"])
	var shader:Shader=load(source_paths[0]);source_code=shader.code
	var private_shader:=Shader.new();private_shader.code=source_code.replace("shader_type spatial;","shader_type spatial;\nuniform float film_time = 0.0;").replace("TIME","film_time")
	mesh=SphereMesh.new();mesh.radius=1.08;mesh.height=2.16;mesh.radial_segments=32;mesh.rings=16
	bare=Kit.material(Color("b1bdc7"))
	for i in 3:
		var mat:=ShaderMaterial.new();mat.shader=private_shader;mat.set_shader_parameter("grid_size",float([1,4,8][i]));mat.set_shader_parameter("animate",0.0);mat.set_shader_parameter("shape_color",Color("75d7c9"));mat.set_shader_parameter("bg_color",Color("142335"))
		materials.append(mat)
		var body:=Kit.node(display,mesh,Vector3(-2.7+i*2.7,1.55,0),mat);bodies.append(body)
		var wire:=Draw.wire(body,mesh,Kit.GOLD);wire.scale=Vector3.ONE*1.002;wires.append(wire)
		labels.append(Draw.caption(display,"GRID %d" % [1,4,8][i],body.position+Vector3(0,1.6,0)))
	add_box(Vector3(0,.20,0),Vector3(8.7,.12,3.4),Color("202934"))
	evidence={"vertices":mesh.get_mesh_arrays()[Mesh.ARRAY_VERTEX].size(),"triangles":mesh.get_faces().size()/3,"shared_mesh_instances":3,"source_has_fract":source_code.contains("fract(uv)"),"grid_sizes":[1,4,8],"animation_uniform":0.0,"clock_adapter":"TIME replaced by film_time only","spatial_transfer":"Original flat display shader on a sphere with unchanged UV mapping"}

func _draw(time:float) -> void:
	if bodies.is_empty():return
	var p:=phase_index(time);var u:=phase_progress(time)
	for i in 3:
		bodies[i].visible=p==3 or i==1
		bodies[i].position.x=-2.7+i*2.7 if p==3 else 0.0
		bodies[i].rotation.y=.32+time*.035
		bodies[i].material_override=bare if p==0 else materials[i]
		materials[i].set_shader_parameter("film_time",time)
		materials[i].set_shader_parameter("grid_size",float([1,4,8][i]) if p==3 else (1.0 if p<2 else lerpf(1,8,u)))
		wires[i].visible=p==0
		labels[i].visible=p==3
	frame_scene(Vector3(0,1.65,0),13.0 if p==3 else 8.0,.15,.18)

func validation() -> Dictionary:
	return {"passed":evidence.source_has_fract and bodies[0].mesh==bodies[1].mesh and bodies[1].mesh==bodies[2].mesh and not materials[0].shader.code.contains("TIME"),"evidence":evidence}
