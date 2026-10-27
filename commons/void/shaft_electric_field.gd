extends Node3D
## A conducting cover, not a damaging force zone. B can stand on its live sheet.
@export var field_size := Vector2(5,6)
var enabled := true
var cover: StaticBody3D
var sheet: MeshInstance3D
var collision: CollisionShape3D

func _ready() -> void:
	cover=StaticBody3D.new();cover.name="ElectricalCover";cover.collision_layer=1;cover.collision_mask=0
	add_child(cover)
	collision=CollisionShape3D.new();var shape := BoxShape3D.new()
	shape.size=Vector3(field_size.x,.1,field_size.y);collision.shape=shape;cover.add_child(collision)
	sheet=MeshInstance3D.new();sheet.name="ConductingSheet"
	var plane := QuadMesh.new();plane.size=field_size;sheet.mesh=plane;sheet.rotation.x=-PI/2
	var mat := ShaderMaterial.new();mat.shader=load("res://commons/void/shaft_electric_field.gdshader")
	sheet.material_override=mat;add_child(sheet)
	# Actual conducting strands also travel to the editor's static GLB preview.
	var strands := MultiMeshInstance3D.new();strands.name="ConductingStrands"
	strands.multimesh=MultiMesh.new();strands.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	var strand_mesh := BoxMesh.new();strand_mesh.size=Vector3.ONE
	strands.multimesh.mesh=strand_mesh;strands.multimesh.instance_count=24
	var glow := StandardMaterial3D.new();glow.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color=Color("ff82bb");glow.emission_enabled=true;glow.emission=glow.albedo_color;glow.emission_energy_multiplier=.5
	strands.material_override=glow;add_child(strands)
	for i in range(11):
		strands.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3(.009,.008,field_size.y)),Vector3(-field_size.x*.5+field_size.x*i/10.0,.008,0)))
	for i in range(13):
		strands.multimesh.set_instance_transform(11+i,Transform3D(Basis.IDENTITY.scaled(Vector3(field_size.x,.008,.009)),Vector3(0,.008,-field_size.y*.5+field_size.y*i/12.0)))
	set_enabled(enabled)

func set_enabled(value: bool) -> void:
	enabled=value
	if not is_instance_valid(cover):return
	visible=value
	cover.collision_layer=1 if value else 0
	collision.set_deferred("disabled",not value)

func prepare_editor_preview() -> void:
	set_enabled(true)
	var mat := StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color=Color(1,.25,.62,.12);mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED;sheet.material_override=mat
