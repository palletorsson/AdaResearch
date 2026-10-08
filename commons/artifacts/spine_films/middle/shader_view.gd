extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var body: MeshInstance3D
var wire_: MeshInstance3D
var normal_rod: MeshInstance3D
var view_rod: MeshInstance3D
var eye: MeshInstance3D
var text_: Label3D
var source_material: ShaderMaterial
var bare: StandardMaterial3D
var sample_at := Vector3(1.65,1.7,0)
var sample_normal := Vector3.RIGHT

func _build() -> void:
	title_text = "A SURFACE ANSWERS A VIEW"
	duration=24.0
	phases.assign(["The mesh stays", "A camera moves", "Grazing angles gain colour", "The skin returns"])
	notes.assign(["An unchanged torus beneath the oil-slick material.","White is the surface normal. Pink points toward the camera.","The source uses the angle between these directions to add a coloured rim.","This is the shader's optical approximation, not a physical thin-film simulation."])
	source_paths.assign(["res://algorithms/shaders/queer_collection_2/oil_slick_latex.gdshader","res://algorithms/shaders/book_of_shaders/shader_11_queerrubber.gd"])
	var shader: Shader = load(source_paths[0])
	var film_shader := Shader.new()
	film_shader.code = shader.code.replace("shader_type spatial;","shader_type spatial;\nuniform float film_time = 0.0;").replace("TIME","film_time")
	source_material=ShaderMaterial.new()
	source_material.shader=film_shader
	var torus := TorusMesh.new()
	torus.inner_radius=0.65
	torus.outer_radius=1.65
	torus.rings=48
	torus.ring_segments=24
	bare=Kit.material(Color("7f8d9e"))
	body=Kit.node(display,torus,Vector3(0,1.7,0),bare)
	var inspection: GDScript=load("res://commons/primitives/shared/mesh_inspection.gd")
	wire_=inspection.overlay(torus)
	body.add_child(wire_)
	normal_rod=Kit.rod(display,sample_at,sample_at+sample_normal*1.4,0.025,Kit.material(Kit.WHITE,true))
	view_rod=Kit.rod(display,sample_at,sample_at+Vector3(0,0,2),0.025,Kit.material(Kit.PINK,true))
	eye=Kit.dot(display,Vector3.ZERO,0.11,Kit.material(Kit.PINK,true))
	Kit.dot(display,sample_at,0.075,Kit.material(Kit.GOLD,true))
	text_=Kit.label(display,"",Vector3(0,3.1,0),Kit.WHITE,.005)
	evidence={"source_shader":source_paths[0],"clock_adapter":"TIME replaced with film_time only","fixed_vertices":torus.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size(),"changes_source":false}

func _draw(time: float) -> void:
	var angle := lerpf(0.10,2.5,Kit.progress(time,4.0,20.0))
	frame_from_position(Vector3(0,1.7,0),Vector3(cos(angle)*7.0,4.1,sin(angle)*7.0))
	var toward_eye := (camera.position-sample_at).normalized()
	var rim := 1.0-clampf(sample_normal.dot(toward_eye),0.0,1.0)
	Kit.set_rod(view_rod,sample_at,sample_at+toward_eye*2.0)
	eye.position=sample_at+toward_eye*2.0
	view_rod.visible=time>=4.0 and time<20.0
	normal_rod.visible=view_rod.visible
	eye.visible=view_rod.visible
	wire_.visible=time<8.0 or (time>=16.0 and time<19.0)
	body.material_override=bare if time<8.0 else source_material
	source_material.set_shader_parameter("film_time",time)
	text_.text="Same mesh\nview-dependent rim %.2f" % rim
