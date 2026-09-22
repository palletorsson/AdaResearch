extends Node3D
## Opt-in teaching layer: arrows and particles read the exact same sampler.
const PUSH = preload("res://commons/interactables/push_button.tscn")
var painter: Node3D
var arrows: MeshInstance3D
var buttons: Dictionary = {}
var status: Label3D
var age := 0.0

func _ready() -> void:
	painter = get_parent()
	painter._canvas_mesh.rotation_degrees.x = 0 # Match the actual XZ trail plane.
	painter._info_label.hide() # The lesson status occupies this title position.
	# Rest the existing controls above this lesson's tabletop, including RESET/SEED.
	painter._control_panel.position.y = -0.015
	painter._control_panel.rotation_degrees.x = -65
	painter.num_particles = 80
	painter._noise.seed = 43
	painter._update_noise()
	painter._create_particles()
	painter.field_evolving = false
	var top = MeshInstance3D.new()
	var box = BoxMesh.new(); box.size = Vector3(0.85,0.05,0.95); top.mesh = box
	top.position = Vector3(0,-0.10,0.15)
	var mat = StandardMaterial3D.new(); mat.albedo_color = Color("d9d0bc"); top.material_override = mat
	add_child(top)
	var leg = MeshInstance3D.new();var stem = BoxMesh.new();stem.size=Vector3(0.18,0.30,0.18);leg.mesh=stem;leg.position=Vector3(0,-0.275,0.12);leg.material_override=mat;add_child(leg)
	for i in 2:
		var id = ["ARROWS", "FIELD TIME"][i]
		var button = PUSH.instantiate();button.position=Vector3(-0.16+i*0.32,-0.025,0.51);button.scale=Vector3.ONE*0.35
		add_child(button);buttons[id]=button;button.pressed.connect(act.bind(id))
		var label=Label3D.new();label.text=id;label.font_size=28;label.pixel_size=0.00065;label.position=button.position+Vector3(0,0.035,0.045);label.rotation_degrees.x=-45;add_child(label)
	status=Label3D.new();status.font_size=24;status.pixel_size=0.0007;status.position=Vector3(0,0.09,-0.24);add_child(status)
	arrows=MeshInstance3D.new();arrows.name="SharedFieldArrows";var ink=StandardMaterial3D.new();ink.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;ink.albedo_color=Color("fff1a6");arrows.material_override=ink;add_child(arrows)
	arrows.hide()
	var light=OmniLight3D.new();light.position=Vector3(0,0.8,0.4);light.omni_range=3;light.light_energy=1.4;add_child(light)
	refresh()

func act(id: String) -> void:
	if id=="ARROWS":arrows.visible=not arrows.visible
	if id=="FIELD TIME":painter.field_evolving=not painter.field_evolving
	refresh()

func _process(delta: float) -> void:
	age+=delta
	if age>=0.1:age=0;refresh()

func refresh() -> void:
	status.text="FIELD %s / %d PARTICLES\nARROWS %s" % ["EVOLVING" if painter.field_evolving else "HELD",painter._particles.size(),"SHOWN" if arrows.visible else "HIDDEN"]
	if not arrows.visible:return
	var mesh=ImmediateMesh.new();mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for z in 4:
		for x in 6:
			var p=Vector2((x+0.5)/6.0-0.5,(z+0.5)/4.0-0.5)*painter.canvas_size
			var d=painter.field_direction(p);var tip=p+d*0.038
			for pair in [[p,tip],[tip,tip-d.rotated(0.55)*0.014],[tip,tip-d.rotated(-0.55)*0.014]]:
				for q in pair:mesh.surface_add_vertex(Vector3(q.x,0.007,q.y))
	mesh.surface_end();arrows.mesh=mesh
