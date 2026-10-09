extends Node3D
## A current-rule specimen, distinct from the loom's historical carpet.
const WIDTH := 1.2
const HEIGHT := 1.2
const PIXELS_PER_METRE := 100.0
var loom: Node3D
var flat: MeshInstance3D
var curved: MeshInstance3D
var wall: MeshInstance3D
var receivers: Dictionary = {}
var target_index := 0
var TARGETS := ["CURVE", "WALL", "FLAT", "ALL FIVE", "ARCHITECTURE", "NORTH", "EAST"]
const ARCHITECTURE := ["WALL", "NORTH", "EAST"]
var link_history: Array[Dictionary] = []
var buttons: Array[Node3D] = []
var readout: Label
var curved_linked := true
var save_path := "user://pattern_recipes/foundry.json"
signal receivers_changed
var updates := 0

func _ready() -> void:
	loom=get_parent()
	flat=MeshInstance3D.new(); flat.name="FlatSpecimen"
	flat.mesh=bent_sheet(false)
	flat.position=Vector3(-2.3,1.4,1.2); add_child(flat)
	curved=MeshInstance3D.new(); curved.name="CurvedSpecimen"
	curved.mesh=bent_sheet(); curved.position=Vector3(-3.9,1.4,1.2); add_child(curved)
	# Dress the inward face of the existing x=4 grid wall. The receiver adds
	# no collision and changes no grid geometry or shared grid material.
	wall=MeshInstance3D.new(); wall.name="WallReceiver"
	wall.mesh=bent_sheet(false); wall.scale=Vector3(4.0,0.75,1.0)
	wall.position=Vector3(-3.1,0.5,-1.49); wall.rotation_degrees.y=180; add_child(wall)
	for specimen in [flat,curved,wall]:
		var mat:=StandardMaterial3D.new()
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		mat.roughness=0.8
		specimen.material_override=mat
	register_receiver("FLAT",flat,Vector2(WIDTH,HEIGHT))
	register_receiver("CURVE",curved,Vector2(WIDTH,HEIGHT))
	register_receiver("WALL",wall,Vector2(4.8,0.9))
	add_receiver_tag("FLAT",Vector3(-2.3,0.72,1.15),180)
	add_receiver_tag("CURVE",Vector3(-3.9,0.72,0.8),180)
	add_receiver_tag("WALL",Vector3(-3.1,1.1,-1.49),0)
	# Authored skins on existing inner-wall faces, with no new collision.
	add_wall_receiver("NORTH",Vector3(3.49,0.5,1.0),90,4.8)
	add_wall_receiver("EAST",Vector3(0.5,0.5,6.51),180,1.8)
	box("SpecimenBench",Vector3(-3.1,0.4,1.2),Vector3(3.0,0.8,0.9))
	box("ConsoleStand",Vector3(-3.1,0.39,0.1),Vector3(1.35,0.78,0.55))
	var panel:Node3D=load("res://commons/ui/control_panel.gd").new()
	panel.name="RecipeControls"
	panel.title="ONE RULE / FIVE SURFACES"
	# Keep all eight actions and full-size hit targets within one backed group.
	panel.layout_columns=4
	panel.label_color=Color(0.07,0.07,0.08)
	panel.title_color=Color(0.07,0.07,0.08)
	# Keep the taller board below the sample comparison rather than in its way.
	panel.position=Vector3(-3.1,1.01,0.1); panel.rotation_degrees.y=180; add_child(panel)
	for title in ["MARK","SAVE","RESTORE","LINK / HOLD","TARGET","UNDO LINK","REPEAT SIZE","OFFSET +5CM"]: buttons.append(panel.add_button(title))
	readout=panel.add_readout("LINK TARGET: CURVE / LIVE")
	buttons[0].pressed.connect(func(): loom.call("_toggle_peg",1,2))
	buttons[1].pressed.connect(save_recipe)
	buttons[2].pressed.connect(restore_recipe)
	buttons[3].pressed.connect(toggle_link)
	buttons[4].pressed.connect(cycle_target)
	buttons[5].pressed.connect(undo_link)
	buttons[6].pressed.connect(cycle_spacing)
	buttons[7].pressed.connect(cycle_offset)
	loom.recipe_changed.connect(update_specimens)
	update_specimens()
	loom.set_meta("em_visibility_bounds",AABB(Vector3(-5.7,0,-1.6),Vector3(9.3,2.4,8.3)))

func add_wall_receiver(id:String,pos:Vector3,turn:float,width:float) -> void:
	var mesh:=MeshInstance3D.new();mesh.name=id+"Receiver"
	mesh.mesh=bent_sheet(false);mesh.scale=Vector3(width/WIDTH,0.9/HEIGHT,1)
	mesh.position=pos;mesh.rotation_degrees.y=turn;add_child(mesh)
	var material:=StandardMaterial3D.new()
	material.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.cull_mode=BaseMaterial3D.CULL_DISABLED;material.roughness=0.8
	mesh.material_override=material
	register_receiver(id,mesh,Vector2(width,0.9))
	add_receiver_tag(id,pos+Vector3(0,0.6,0),turn+180)

func register_receiver(id:String,mesh:MeshInstance3D,metres:Vector2) -> void:
	assert(not receivers.has(id))
	receivers[id]={"mesh":mesh,"metres":metres,"linked":true,"repeat_metres":loom.repeat_metres,"offset_metres":loom.offset_metres,"source":null}

func cycle_offset() -> void:
	var step:=roundi(loom.offset_metres/0.05)
	loom.set_offset_metres(float((step+1)%7)*0.05)

func cycle_spacing() -> void:
	var current:float=loom.repeat_metres
	loom.set_repeat_metres(0.3 if current<0.225 else (0.6 if current<0.45 else 0.15))

func selected_ids() -> Array:
	match TARGETS[target_index]:
		"ALL FIVE":return ["FLAT","CURVE","WALL","NORTH","EAST"]
		"ROOM":return ["ROOM WALL","ROOM FLOOR"]
		"ARCHITECTURE":return ARCHITECTURE.duplicate()
	return [TARGETS[target_index]]

func add_receiver_tag(id:String,pos:Vector3,turn:float) -> void:
	var tag:=Node3D.new();tag.name=id+"Tag";tag.position=pos;tag.rotation_degrees.y=turn;add_child(tag)
	var plate:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=Vector3(0.95,0.13,0.025);plate.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=Color("202628");plate.material_override=material;tag.add_child(plate)
	var text:=Label3D.new();text.font_size=32;text.pixel_size=0.002;text.position.z=0.02;text.outline_size=0;tag.add_child(text)
	receivers[id].tag=text

func cycle_target() -> void:
	target_index=(target_index+1)%TARGETS.size()
	refresh_readout()

func refresh_readout() -> void:
	curved_linked=receivers.CURVE.linked
	var live:=0
	var ids:=selected_ids()
	for id in ids:
		if receivers[id].linked:live+=1
	var state:="LIVE" if live==ids.size() else ("HELD" if live==0 else "MIXED")
	readout.text="%s / %s | %.0f CM | U%02.0f" % [TARGETS[target_index],state,loom.repeat_metres*100,loom.offset_metres*100]
	var studio_count:=0
	for id in ids:
		if receivers[id].get("source")!=null:studio_count+=1
	if studio_count>0:
		readout.text="%s / %s / %s" % [TARGETS[target_index],"STUDIO" if studio_count==ids.size() else "MIXED SOURCES",state]
	for id in receivers:
		var r:Dictionary=receivers[id]
		r.tag.text="%s / %s / %.0f CM / U%02.0f" % [id,"LIVE" if r.linked else "HELD",r.repeat_metres*100,r.offset_metres*100]
		if r.get("source") != null:
			r.tag.text="%s / STUDIO / %s" % [id,"LIVE" if r.linked else "HELD"]
		r.tag.modulate=Color("ffc071") if id in ids else Color("eeeeea")

	receivers_changed.emit()

func box(label:String,pos:Vector3,size:Vector3) -> void:
	var m:=MeshInstance3D.new();m.name=label
	var shape:=BoxMesh.new();shape.size=size;m.mesh=shape;m.position=pos
	var mat:=StandardMaterial3D.new();mat.albedo_color=Color("cdc5ba");m.material_override=mat
	add_child(m);m.create_convex_collision()

static func bent_sheet(bend:bool=true) -> ArrayMesh:
	var vertices:=PackedVector3Array();var normals:=PackedVector3Array();var uv:=PackedVector2Array();var indices:=PackedInt32Array()
	var radius:=WIDTH/PI
	for i in range(49):
		var u:=float(i)/48.0;var angle:float=(u-0.5)*PI
		for v in [0.0,1.0]:
			vertices.append(Vector3(sin(angle)*radius,(v-0.5)*HEIGHT,-cos(angle)*radius) if bend else Vector3((u-0.5)*WIDTH,(v-0.5)*HEIGHT,0))
			normals.append(Vector3(sin(angle),0,-cos(angle)) if bend else Vector3(0,0,-1))
			uv.append(Vector2(u,1.0-v))
	for i in range(48):
		var k:=i*2
		indices.append_array(PackedInt32Array([k,k+1,k+2,k+1,k+3,k+2]))
	var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=vertices;arrays[Mesh.ARRAY_NORMAL]=normals;arrays[Mesh.ARRAY_TEX_UV]=uv;arrays[Mesh.ARRAY_INDEX]=indices
	var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);return mesh

func update_specimens() -> void:
	var recipe:Dictionary=loom.export_recipe()
	var live:Dictionary=recipe.live
	var textures:Dictionary={}
	for receiver:Dictionary in receivers.values():
		if not receiver.linked:continue
		if receiver.get("source") != null:
			refresh_external_receiver(receiver)
			continue
		var metres:Vector2=receiver.metres
		if not textures.has(metres):textures[metres]=render_surface(live,metres,float(receiver.get("sampling",PIXELS_PER_METRE)))
		receiver.mesh.material_override.albedo_texture=textures[metres]
		receiver.repeat_metres=loom.repeat_metres
		receiver.offset_metres=loom.offset_metres
	updates+=1
	refresh_readout()

func render_surface(live:Dictionary,metres:Vector2,sampling:float=PIXELS_PER_METRE) -> ImageTexture:
	var n:=int(live.size)
	# Keep the render sampling fixed while changing the source address rate.
	# A surface may end partway through a source cell; do not round its period.
	var size:=Vector2i(roundi(metres.x*sampling),roundi(metres.y*sampling))
	var img:=Image.create(size.x,size.y,false,Image.FORMAT_RGBA8)
	var group_id:int=loom.call("_group_enum_for",loom.GROUP_NAMES[int(live.group_index)])
	for y in size.y:
		for x in size.x:
			var source_x:=floori(((x+0.5)/sampling+loom.offset_metres)*n/loom.repeat_metres)
			var source_y:=floori((y+0.5)/sampling*n/loom.repeat_metres)
			var index:int=WallpaperGroups.get_symmetric_color(source_x,source_y,n,live.card,group_id)
			var c:Array=live.palette[index]
			img.set_pixel(x,y,Color(c[0],c[1],c[2],c[3]))
	return ImageTexture.create_from_image(img)

func remember_receivers(ids:Array) -> void:
	var previous:Dictionary={}
	for id in ids:
		var r:Dictionary=receivers[id]
		previous[id]={"linked":r.linked,"material":r.mesh.material_override.duplicate(),"source":r.get("source"),"repeat_metres":r.repeat_metres,"offset_metres":r.offset_metres}
	link_history.append(previous)
	if link_history.size()>16:link_history.pop_front()

func toggle_link() -> void:
	var ids:=selected_ids()
	var all_live:=true
	for id in ids:all_live=all_live and receivers[id].linked
	remember_receivers(ids)
	for id in ids:receivers[id].linked=not all_live
	update_specimens()

func undo_link() -> void:
	if link_history.is_empty():readout.text="NO LINK CHANGE TO UNDO";return
	var previous:Dictionary=link_history.pop_back()
	for id in previous:
		var r:Dictionary=receivers[id]
		r.linked=previous[id].linked;r.source=previous[id].source
		r.mesh.material_override=previous[id].material
		r.repeat_metres=previous[id].repeat_metres;r.offset_metres=previous[id].offset_metres
	# Live links catch up with their restored owner; held images remain exact.
	update_specimens()

func valid_targets(ids:Array) -> bool:
	if ids.is_empty():return false
	for id in ids:
		if not receivers.has(id):return false
	return true

func apply_source(ids:Array,source:Node) -> bool:
	if not valid_targets(ids) or not is_instance_valid(source) or not source.has_method("receiver_material"):return false
	remember_receivers(ids)
	for id in ids:
		receivers[id].source=weakref(source);receivers[id].linked=true
	update_specimens();return true

func hold_receivers(ids:Array) -> bool:
	if not valid_targets(ids):return false
	remember_receivers(ids)
	for id in ids:receivers[id].linked=false
	refresh_readout();return true

func return_to_loom(ids:Array) -> bool:
	if not valid_targets(ids):return false
	remember_receivers(ids)
	for id in ids:
		var r:Dictionary=receivers[id]
		r.source=null;r.linked=true
		var mat:=StandardMaterial3D.new()
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mat.roughness=0.8
		r.mesh.material_override=mat
	update_specimens();return true

func refresh_external_receiver(r:Dictionary) -> void:
	var owner:Node=r.source.get_ref()
	if not is_instance_valid(owner):r.linked=false;return
	r.mesh.material_override=owner.receiver_material(r.metres)
	r.repeat_metres=1.2/float(r.mesh.material_override.get_shader_parameter("tile_scale"))
	r.offset_metres=0.0

func refresh_from(source:Node) -> void:
	for r:Dictionary in receivers.values():
		if r.linked and r.get("source")!=null and r.source.get_ref()==source:refresh_external_receiver(r)
	refresh_readout()

func detach_source(source:Node) -> void:
	for r:Dictionary in receivers.values():
		if r.get("source")!=null and r.source.get_ref()==source:r.linked=false
	refresh_readout()

func save_recipe() -> void:
	if save_path.is_empty(): return
	var error:=DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	if error!=OK: readout.text="SAVE FAILED / FOLDER";return
	var file:=FileAccess.open(save_path,FileAccess.WRITE)
	if file==null:readout.text="SAVE FAILED";return
	file.store_string(JSON.stringify(loom.export_recipe(),"  ",true,true));file.flush()
	readout.text="RECIPE SAVED" if file.get_error()==OK else "SAVE FAILED / WRITE"

func restore_recipe() -> void:
	if save_path.is_empty() or not FileAccess.file_exists(save_path):readout.text="NO SAVED RECIPE";return
	var file:=FileAccess.open(save_path,FileAccess.READ)
	if file==null or file.get_length()>65536:readout.text="RECIPE NOT READABLE";return
	var recipe:Variant=JSON.parse_string(file.get_as_text())
	readout.text="RECIPE RESTORED" if loom.import_recipe(recipe) else "RECIPE REJECTED / UNCHANGED"
