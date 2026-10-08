extends Node3D
const Recipe=preload("res://commons/artifacts/fabric_shader_studio/fabric_recipe.gd")
const Agent=preload("res://commons/artifacts/drag_catwalk/runway_agent.gd")
const PUSH=preload("res://commons/interactables/push_button.tscn")
@export var save_path:String="user://ada_studio_fabric_v1.json"
var recipe:Dictionary=Recipe.initial()
var paint_index:int=1
var look:int=0
var wall:MeshInstance3D
var preview:Node3D
var mount:Node3D
var status:Label3D
var code:Label3D
var buttons:Dictionary={}
var cells:Array=[]
var history:Array=[]
var notice:String="Preview only / SAVE before WEAR"

func _ready() -> void:
	# Local display lights keep finish comparisons readable without changing the hall.
	for x in [-2.0, 2.5]:
		var light=OmniLight3D.new();light.position=Vector3(x,2.7,1.7);light.omni_range=5.0;light.light_energy=1.4;light.shadow_enabled=false;add_child(light)
	box(self,Vector3(0,1.65,-1),Vector3(8.5,3.3,0.12),Color("30343a"))
	wall=MeshInstance3D.new();wall.name="FabricWall";var mesh=QuadMesh.new();mesh.size=Vector2(3,2);mesh.subdivide_width=32;mesh.subdivide_depth=32;wall.mesh=mesh;wall.position=Vector3(-2,1.65,0);wall.extra_cull_margin=0.08;add_child(wall)
	var body=StaticBody3D.new();body.name="WallCollision";body.collision_layer=1;body.collision_mask=0;wall.add_child(body)
	var collider=CollisionShape3D.new();collider.name="CollisionShape3D";var shape=BoxShape3D.new();shape.size=Vector3(3,2,0.05);collider.shape=shape;body.add_child(collider)
	preview=Agent.new();preview.name="FabricPreview";preview.position=Vector3(2.5,0,0.2);add_child(preview)
	label(self,"WALL / ONE UV DOMAIN",Vector3(-2,2.9,0),0.0014)
	label(self,"SKIRT / ONE UV DOMAIN",Vector3(2.5,2.9,0),0.0014)
	mount=Node3D.new();mount.position=Vector3(0,1.30,2);mount.rotation_degrees.x=-12;add_child(mount)
	box(mount,Vector3.ZERO,Vector3(2.25,1.45,0.08),Color("292b30"));box(mount,Vector3(0,0,0.05),Vector3(2.20,1.40,0.025),Color("e7dfce"))
	box(self,Vector3(0,0.5,1.8),Vector3(0.60,1,0.40),Color("a5a095"),true)
	label(mount,"FROM SOURCE TO SKIRT",Vector3(0,0.62,0.08),0.001)
	for y in 4:
		for x in 4:
			var b=button("cell_%d_%d"%[x,y],Vector3(-0.91+x*0.13,0.44-y*0.13,0.09),func():paint(x,y));cells.append(b)
	for i in 4:
		var b=button("paint_%d"%i,Vector3(-0.91+i*0.13,-0.10,0.09),func():paint_index=i;refresh());b.released_color=Recipe.PALETTE[i];b.pressed_color=Recipe.PALETTE[i];b.update_colors()
	status=label(mount,"",Vector3(0.37,0.33,0.08),0.00068)
	code=label(mount,"",Vector3(0.37,0.02,0.08),0.00063)
	var ids=["UV / FABRIC","OFFSET","REPEAT","CUT OUT","FINISH","VERTICES","SAVE","LOAD","LOOK","WEAR SAVED","RUNWAY SAVED","UNDO"]
	for i in ids.size():
		var id:String=ids[i];var pos=Vector3(-0.84+(i%4)*0.56,-0.25-floori(i/4.0)*0.17,0.09)
		button(id,pos,func():act(id));label(mount,id,pos+Vector3(0,-0.055,0),0.00054)
	set_meta("em_visibility_bounds",AABB(Vector3(-4.3,0,-1.1),Vector3(8.6,3.4,4)))
	refresh()

func button(id:String,pos:Vector3,action:Callable) -> Node3D:
	var b:Node3D=PUSH.instantiate();b.name=id.replace(" ","_").replace("/","_");b.position=pos;b.scale=Vector3.ONE*0.72;mount.add_child(b);b.pressed.connect(action);buttons[id]=b;return b

func remember(entry:Dictionary) -> void:
	history.append(entry)
	if history.size()>32:history.pop_front()

func paint(x:int,y:int) -> void:
	if recipe.cells[y][x]==paint_index:return
	remember({"kind":"recipe","recipe":recipe.duplicate(true),"look":look})
	recipe.cells[y][x]=paint_index;notice="Edited preview / saved fabric unchanged";refresh()

func saved_recipe() -> Dictionary:
	if not FileAccess.file_exists(save_path):return {}
	var f=FileAccess.open(save_path,FileAccess.READ)
	if not f or f.get_length()>16384:return {}
	var data=JSON.parse_string(f.get_as_text())
	return Recipe.normalize(data) if data is Dictionary else {}

func wardrobe() -> Node:
	var cam=get_viewport().get_camera_3d()
	for w in get_tree().get_nodes_in_group("costume_wardrobes"):
		if is_instance_valid(w.costume) and w.costume.get("_head")==cam:return w
	return null

func runway() -> Node:
	var hall:Node=self
	while hall.get_parent() and not hall.has_meta("em_map"):hall=hall.get_parent()
	for n in hall.find_children("*","Node3D",true,false):
		if n.get_script() and n.get_script().resource_path=="res://commons/artifacts/drag_catwalk/drag_catwalk.gd":return n
	return null

func act(id:String) -> void:
	if id=="SAVE":
		var file=FileAccess.open(save_path,FileAccess.WRITE)
		if file:file.store_string(JSON.stringify(recipe,"  "));file.close();notice="Saved recipe / WEAR targets skirt only"
		else:notice="Save failed / preview retained"
	elif id=="WEAR SAVED":
		var saved=saved_recipe();var w=wardrobe()
		if saved.is_empty():notice="SAVE a valid fabric first"
		elif not w:notice="Player wardrobe unavailable"
		else:
			remember({"kind":"wear","wardrobe":weakref(w),"outfit":w.costume.outfit_id,"recipe":w.skirt_fabric.duplicate(true)})
			w.choose_outfit(preview.outfit.LOOKS[look]);var ok=w.set_skirt_fabric(saved)
			notice="Saved fabric worn on SKIRT" if ok else "Fabric applied / appearance save failed"
	elif id=="RUNWAY SAVED":
		var saved=saved_recipe();var stage=runway()
		if saved.is_empty():notice="SAVE a valid fabric first"
		elif not stage:notice="Runway unavailable"
		else:
			var old:Array=[]
			for agent in stage.agents:old.append({"outfit":weakref(agent.outfit),"recipe":agent.outfit.skirt_fabric.duplicate(true)});agent.outfit.apply_skirt_fabric(saved)
			remember({"kind":"runway","outfits":old});notice="Saved fabric on four performer skirts"
	elif id=="UNDO":
		if history.is_empty():notice="Nothing to undo"
		else:
			var old:Dictionary=history.pop_back()
			if old.kind=="recipe":recipe=old.recipe;look=old.look
			elif old.kind=="wear":
				var w=old.wardrobe.get_ref()
				if w:w.set_skirt_fabric(old.recipe);w.choose_outfit(old.outfit)
			elif old.kind=="runway":
				for item in old.outfits:
					var outfit=item.outfit.get_ref()
					if outfit:outfit.apply_skirt_fabric(item.recipe)
			notice="Undone / saved recipe file retained"
	else:
		var loaded:Dictionary=saved_recipe() if id=="LOAD" else {}
		if id=="LOAD" and loaded.is_empty():notice="No valid saved recipe";refresh();return
		remember({"kind":"recipe","recipe":recipe.duplicate(true),"look":look})
		match id:
			"UV / FABRIC":recipe.uv_view=not recipe.uv_view
			"OFFSET":recipe.offset=0.125 if recipe.offset==0 else 0.0
			"REPEAT":recipe.repeats=8 if recipe.repeats==4 else 4
			"CUT OUT":recipe.mask=not recipe.mask
			"FINISH":recipe.finish=1-int(recipe.finish)
			"VERTICES":recipe.displace=not recipe.displace
			"LOOK":look=(look+1)%4
			"LOAD":recipe=loaded
		notice="Preview updated / wearer unchanged"
	refresh()

func refresh() -> void:
	wall.material_override=Recipe.material(recipe)
	if preview.look_index!=look:preview.set_look(look)
	preview.outfit.apply_skirt_fabric(recipe);preview.animate(0,false)
	for i in cells.size():
		var c:Color=Recipe.PALETTE[int(recipe.cells[i/4][i%4])];cells[i].released_color=c;cells[i].pressed_color=c;cells[i].update_colors()
	status.text="%s / PAINT %d\n%d repeats per UV / %s\n%s"%[preview.outfit.TITLES[look],paint_index,recipe.repeats,"METAL" if recipe.finish==1 else "MATTE",notice]
	code.text="UV -> repeat + offset -> sample\ncut-out: %s / displacement: %s\nCollision keeps its original shape"%[recipe.mask,"4 cm local" if recipe.displace else "off"]

func label(host:Node3D,text:String,pos:Vector3,pixel:float) -> Label3D:
	var l=Label3D.new();l.text=text;l.position=pos;l.font_size=32;l.pixel_size=pixel;l.outline_size=0;l.modulate=Color("1c252c") if host==mount else Color("eee5d7");host.add_child(l);return l

func box(host:Node3D,pos:Vector3,size:Vector3,color:Color,solid:bool=false) -> void:
	var m=MeshInstance3D.new();var mesh=BoxMesh.new();mesh.size=size;m.mesh=mesh;m.position=pos
	var mat=StandardMaterial3D.new();mat.albedo_color=color;mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED;m.material_override=mat;host.add_child(m)
	if solid:
		var body=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;m.add_child(body)
		var c=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=size;c.shape=shape;body.add_child(c)
