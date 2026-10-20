extends Node3D
## Two static, walkable constructions; shading never moves the collision.
@export_enum("womb", "commons") var form := "womb"
const ROOT := "res://commons/artifacts/cellular_spaces/"
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
var data: Dictionary = {}
var skin: MeshInstance3D
var wall_body: StaticBody3D
var routes: Array = []

func apply_grid_config(config: Dictionary) -> void:
	if str(config.get("form",form)) in ["womb","commons"]: form = str(config.get("form",form))

func _ready() -> void:
	data = JSON.parse_string(FileAccess.get_file_as_string(ROOT+form+"_mesh.json"))
	routes = data.routes
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for p in data.vertices: verts.append(Vector3(p[0],p[1],p[2]))
	for p in data.normals: normals.append(Vector3(p[0],p[1],p[2]))
	var indices := PackedInt32Array(data.indices)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=verts
	arrays[Mesh.ARRAY_NORMAL]=normals
	arrays[Mesh.ARRAY_INDEX]=indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	skin=MeshInstance3D.new()
	skin.name="CellularWalls"
	skin.mesh=mesh
	var mat:=ShaderMaterial.new()
	mat.shader=load(ROOT+"cellular_skin.gdshader")
	if form=="womb":
		mat.set_shader_parameter("dark_tone",Color("30341a"))
		mat.set_shader_parameter("light_tone",Color("c9c38c"))
		mat.set_shader_parameter("seam_tone",Color("fff0be"))
		mat.set_shader_parameter("frequency",0.72)
		mat.set_shader_parameter("contrast",1.0)
	else:
		mat.set_shader_parameter("dark_tone",Color("555936"))
		mat.set_shader_parameter("light_tone",Color("d5d3b2"))
		mat.set_shader_parameter("frequency",0.48)
		mat.set_shader_parameter("contrast",0.82)
	skin.material_override=mat
	add_child(skin)
	wall_body=StaticBody3D.new()
	wall_body.name="WallsSameMesh"
	wall_body.collision_layer=1
	wall_body.collision_mask=0
	add_child(wall_body)
	var collision:=CollisionShape3D.new()
	var shape:=ConcavePolygonShape3D.new()
	shape.set_faces(mesh.get_faces())
	shape.backface_collision=true
	collision.shape=shape
	wall_body.add_child(collision)
	var size: Array=data.floor_size
	var floor_mesh:=Stage.box(self,Vector3(0,-0.09,0),Vector3(float(size[0]),0.2,float(size[1])),Color("797563"),true)
	floor_mesh.name="ContinuousFloor"
	var floor_mat:=floor_mesh.material_override as StandardMaterial3D
	floor_mat.roughness=0.85
	# Three static local lights; the shaded surface stays in place in both eyes.
	for at in [Vector3(0,3.6,-4),Vector3(-2,4,0),Vector3(2,3.8,4)]:
		var light:=OmniLight3D.new()
		light.position=at
		light.light_color=Color("ffe4ad")
		light.light_energy=1.0
		light.omni_range=9
		light.shadow_enabled=false
		add_child(light)
	# A low line at the entry points into the volume without closing its throat.
	var entry:=Vector3(data.entry[0],0.018,data.entry[2])
	Stage.box(self,entry,Vector3(1.6,0.02,0.10),Color("efcb7d"))
	var sign:=Stage.label(self,"CELLULAR ENCLOSURE" if form=="womb" else "A COMMON INTERIOR",entry+Vector3(0,3.1,-0.5),PI)
	sign.font_size=27
	sign.pixel_size=0.002
	if form=="commons": _site_witnesses()

func _site_witnesses() -> void:
	# Ground dots mark the original sixteen centres even after walls are removed.
	for i in range(data.centres.size()):
		var p: Array=data.centres[i]
		var marker:=MeshInstance3D.new()
		var disc:=CylinderMesh.new()
		disc.top_radius=0.09;disc.bottom_radius=0.09;disc.height=0.015
		marker.mesh=disc
		marker.position=Vector3(p[0],0.03,p[2])
		var mat:=StandardMaterial3D.new()
		mat.albedo_color=Color("ead7a3")
		mat.emission_enabled=true;mat.emission=Color("9d8151")
		marker.material_override=mat
		add_child(marker)
