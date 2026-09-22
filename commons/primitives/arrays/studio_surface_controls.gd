extends Node3D
## Adapter to the hall's receiver registry. Selection does not mutate a source.
## Each receiver owns a material snapshot, including its immutable domain image.
var ui:Node3D
var study:Node3D
var panel:Node3D
var screen:Label3D
var buttons:Dictionary={}
var target_index:=0
var targets:Array[String]=["WALL","NORTH","EAST","FLAT","CURVE","ARCHITECTURE","ALL FIVE"]
var receiver_shader:Shader
var discovery_time:=0.0
var room_requested:=false
var room:Node3D

func _ready() -> void:
	ui=get_parent()
	panel=Node3D.new();panel.position=Vector3(-1.03,1.05,0.14);panel.rotation_degrees.x=-15;add_child(panel)
	ui.box(panel,"ReceiverBezel",Vector3.ZERO,Vector3(0.62,0.75,0.06),Color("292b2c"))
	ui.box(panel,"ReceiverFace",Vector3(0,0,0.035),Vector3(0.59,0.72,0.02),Color("e3ddd0"))
	ui.box(self,"ReceiverStand",Vector3(-1.03,0.35,-0.12),Vector3(0.26,0.7,0.25),Color("bdb6aa"),true)
	screen=Label3D.new();screen.position=Vector3(0,0.25,0.05);screen.font_size=32;screen.pixel_size=0.0007
	screen.outline_size=0;screen.modulate=Color("292b2c");panel.add_child(screen)
	var names:=["PREV","NEXT","APPLY LIVE","HOLD","UNDO LINK","LOOM"]
	for i in names.size():
		var id:String=names[i]
		var button:Node3D=ui.BUTTON.instantiate()
		button.position=Vector3(-0.15 if i%2==0 else 0.15,0.07-0.16*floori(i/2.0),0.06)
		panel.add_child(button);buttons[id]=button
		button.pressed.connect(func():act(id))
		var title:=Label3D.new();title.text=id;title.font_size=32;title.pixel_size=0.00062
		title.outline_size=0;title.modulate=Color("292b2c");title.position=button.position+Vector3(0,-0.06,0)
		panel.add_child(title)
	receiver_shader=Shader.new()
	# The existing sheets deliberately expose both faces. Preserve that property
	# without changing the shared shader's default culling for other artifacts.
	receiver_shader.code=ui.material.shader.code.replace("blend_mix, cull_back","blend_mix, cull_disabled")
	find_registry();refresh_screen()
	ui.tree_exiting.connect(source_exiting)
	ui.model.set_meta("em_visibility_bounds",AABB(Vector3(-1.55,-1.0,-2.1),Vector3(3.1,2.9,3.0)))

func _process(delta:float) -> void:
	if is_instance_valid(study):
		ensure_room();return
	discovery_time+=delta
	if discovery_time>=0.5:discovery_time=0;find_registry();refresh_screen()

func find_registry() -> void:
	# Only the authored simulation grid containing this studio may supply targets.
	# No search across the museum, neighbouring halls, wardrobe or other agents.
	var ancestor:Node=ui.model
	while ancestor and not ancestor.name.begins_with("SimGrid_"):ancestor=ancestor.get_parent()
	if not ancestor:return
	var found:Node=ancestor.find_child("RecipeStudy",true,false)
	if found and found.has_method("apply_source"):
		study=found
		if not study.receivers_changed.is_connected(refresh_screen):study.receivers_changed.connect(refresh_screen)

func ids() -> Array:
	match targets[target_index]:
		"ARCHITECTURE":return ["WALL","NORTH","EAST"]
		"ALL FIVE":return ["WALL","NORTH","EAST","FLAT","CURVE"]
		"ROOM":return ["ROOM WALL","ROOM FLOOR"]
	return [targets[target_index]]

func act(id:String) -> void:
	if id=="PREV" or id=="NEXT":
		target_index=posmod(target_index+(-1 if id=="PREV" else 1),targets.size());refresh_screen();return
	if not is_instance_valid(study):refresh_screen();return
	match id:
		"APPLY LIVE":study.apply_source(ids(),ui)
		"HOLD":study.hold_receivers(ids())
		"UNDO LINK":study.undo_link()
		"LOOM":study.return_to_loom(ids())
	refresh_screen()

func refresh_screen() -> void:
	if not is_instance_valid(study):screen.text="SURFACES\nNO HALL RECEIVERS";return
	var owners:Array[String]=[];var states:Array[String]=[]
	for id in ids():
		var r:Dictionary=study.receivers[id]
		var owner:="STUDIO" if r.get("source")!=null else "LOOM"
		var state:="LIVE" if r.linked else "HELD"
		if not owner in owners:owners.append(owner)
		if not state in states:states.append(state)
	screen.text=targets[target_index]+"\n"+(owners[0] if owners.size()==1 else "MIXED SOURCES")+" / "+(states[0] if states.size()==1 else "MIXED")

func material_for_surface(metres:Vector2) -> ShaderMaterial:
	var copy:ShaderMaterial=ui.material.duplicate()
	copy.shader=receiver_shader
	# Web tile_scale counts repeats across one normalized square. The adapter
	# assigns that square 1.2 m, keeping physical repeat size across all five.
	copy.set_shader_parameter("surface_metres",metres/1.2)
	return copy

func source_changed() -> void:
	if is_instance_valid(study):study.refresh_from(ui)

func source_exiting() -> void:
	if is_instance_valid(study):study.detach_source(ui)

func ensure_room() -> void:
	if not room_requested or room or not is_instance_valid(study):return
	room=load("res://commons/primitives/arrays/curved_pattern_room.gd").new()
	room.name="CurvedPatternRoom";room.position=Vector3(0,0,-1)
	room.study=study;room.source=ui
	ui.model.add_child(room)
	targets.append_array(["ROOM WALL","ROOM FLOOR","ROOM"])
	study.TARGETS.append_array(["ROOM WALL","ROOM FLOOR","ROOM"])
	target_index=targets.find("ROOM")
	ui.model.set_meta("em_visibility_bounds",AABB(Vector3(-4.3,0,-5.3),Vector3(8.6,3.5,8.6)))
	refresh_screen()
