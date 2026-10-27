extends "res://commons/void/lethal_pit.gd"
## Visible energized bed and feet-based lethal contact share one editable root.
var live_material: StandardMaterial3D
var time := 0.0
@export var contact_cause := "Electrocuted under the rotation cubes"
func _ready() -> void:
	width=float(get_meta("config_width",6.2));depth=float(get_meta("config_depth",14.4))
	abstract_finish=true
	super._ready()
	# Contact is the conductive sheet, not a tall volume around a safe bank.
	contact.get_child(0).shape.size=Vector3(width,.12,depth)
	contact.get_child(0).position.y=.06
	var base: MeshInstance3D=get_node("HotSurface")
	var steel:=StandardMaterial3D.new();steel.albedo_color=Color("14191e");steel.metallic=.8;steel.roughness=.3;base.material_override=steel
	var grid:=ImmediateMesh.new();live_material=StandardMaterial3D.new()
	live_material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	live_material.albedo_color=Color("49eaff");live_material.emission_enabled=true;live_material.emission=Color("49eaff");live_material.emission_energy_multiplier=1.5
	grid.surface_begin(Mesh.PRIMITIVE_LINES,live_material)
	for i in range(int(width/.25)+1):
		var x:float=-width/2+i*.25
		grid.surface_add_vertex(Vector3(x,.075,-depth/2));grid.surface_add_vertex(Vector3(x,.075,depth/2))
	for i in range(int(depth/.25)+1):
		var z:float=-depth/2+i*.25
		grid.surface_add_vertex(Vector3(-width/2,.075,z));grid.surface_add_vertex(Vector3(width/2,.075,z))
	grid.surface_end()
	var wires:=MeshInstance3D.new();wires.name="LiveConductors";wires.mesh=grid;add_child(wires)
	for z in [-depth/2,depth/2]:
		_surface("LiveEdge",Vector3(0,.08,z),Vector3(width,.04,.05),Color("ff4aa1"),1.4)
	var label:=Label3D.new();label.text="LIVE / ELECTRIC CONTACT";label.font_size=30;label.pixel_size=.0035;label.position=Vector3(-width/2-.03,.3,0);label.rotation.y=PI/2;add_child(label)
func _process(delta:float) -> void:
	time+=delta
	if live_material:live_material.emission_energy_multiplier=1.5+.25*sin(time*4.0)
func _physics_process(_delta:float) -> void:
	var health=get_tree().get_first_node_in_group("void_health")
	if health==null or health.suspended or health.get_health()<=0:return
	var game=get_tree().get_first_node_in_group("void_game")
	for body in contact.get_overlapping_bodies():
		if not body is CharacterBody3D:continue
		if game!=null and body!=game.body:continue
		if not (body.is_in_group("player") or body.is_in_group("player_body") or body.is_in_group("vr_player") or body.is_in_group("em_walker")):continue
		if game!=null:
			# XR's height-calibrating capsule can lag a scripted relocation.
			# Require the real tracked span to cross the conductive sheet.
			var feet:Vector3=to_local(body.global_position)
			var head:Vector3=to_local(game.camera.global_position)
			if minf(feet.y,head.y)>.14 or maxf(feet.y,head.y+.10)<0.0:continue
			print("ROTATION_ELECTRIC_CONTACT ",{"vr":game.vr,"feet":feet,"head":head})
		if game!=null:game.die(contact_cause)
		else:health.set_health(0.0)
		return
func prepare_editor_preview() -> void:
	set_process(false)
