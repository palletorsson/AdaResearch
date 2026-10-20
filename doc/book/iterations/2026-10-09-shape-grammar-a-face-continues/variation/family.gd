extends Node3D
const Faces = preload("faces.gd")
const PointBody = preload("point_body.gd")
const RECIPES := [
	{"title":"01 CUBE","faces":[8,9],"rounds":0,"amount":.28},
	{"title":"02 INSET","faces":[8,9],"rounds":0,"amount":.28,"inset_only":true},
	{"title":"03 EXTRUDE","faces":[8,9],"rounds":1,"amount":.28},
	{"title":"04 REPEAT","faces":[8],"rounds":3,"amount":.28},
	{"title":"05 WIDER","faces":[8,9],"rounds":3,"amount":.08},
	{"title":"06 ALL","faces":[0,1,2,3,4,5,6,7,8,9,10,11],"rounds":3,"amount":.28}
]
var model = Faces.new()
var index := 0
var record: Dictionary
var body: MeshInstance3D
var wire: MeshInstance3D
var label: Label3D
var point: XRToolsPickable

func _ready() -> void:
	body=MeshInstance3D.new(); add_child(body)
	var finish:=StandardMaterial3D.new(); finish.vertex_color_use_as_albedo=true
	finish.cull_mode=BaseMaterial3D.CULL_DISABLED; finish.roughness=.56
	body.material_override=finish
	wire=MeshInstance3D.new(); body.add_child(wire)
	var ink:=StandardMaterial3D.new(); ink.albedo_color=Color("252d40")
	ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED; wire.material_override=ink
	wire.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	label=Label3D.new(); label.position=Vector3(0,1.7,2.8)
	label.font_size=32; label.pixel_size=.0015; label.outline_size=8; add_child(label)
	point=PointBody.new(); point.position=Vector3(0,1.15,2.2); add_child(point)
	point.action_pressed.connect(func(_body): advance())
	show_recipe(0)

func show_recipe(which: int) -> void:
	index=clampi(which,0,RECIPES.size()-1)
	record=model.build(RECIPES[index])
	if not record.accepted: label.text=record.error; return
	body.mesh=model.surface(record)
	var low: float=record.vertices[0].y
	for p in record.vertices: low=minf(low,p.y)
	# Keep metre scale; place the lowest point at the same height as the gallery.
	body.position.y=.56-low
	var lines:=ImmediateMesh.new(); lines.surface_begin(Mesh.PRIMITIVE_LINES)
	for face in record.faces:
		for j in 3:
			lines.surface_add_vertex(record.vertices[face[j]])
			lines.surface_add_vertex(record.vertices[face[(j+1)%3]])
	lines.surface_end(); wire.mesh=lines
	label.text="%s / %d faces / %d growing\nSpace or held trigger: next   R: first" % [RECIPES[index].title,record.faces.size(),record.tags.count("growing")]

func advance() -> void:
	show_recipe((index+1)%RECIPES.size())

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_SPACE: advance()
	elif event.keycode==KEY_R: show_recipe(0)

func _physics_process(_dt: float) -> void:
	if not point.held():
		point.global_transform=global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.15,2.2))
