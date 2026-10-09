extends Node3D
## A current-rule specimen, distinct from the loom's historical carpet.
const WIDTH := 1.2
const HEIGHT := 1.2
var loom: Node3D
var flat: MeshInstance3D
var curved: MeshInstance3D
var buttons: Array[Node3D] = []
var readout: Label
var curved_linked := true
var save_path := "user://pattern_recipes/foundry.json"
var updates := 0

func _ready() -> void:
	loom=get_parent()
	flat=MeshInstance3D.new(); flat.name="FlatSpecimen"
	flat.mesh=bent_sheet(false)
	flat.position=Vector3(-2.3,1.4,1.2); add_child(flat)
	curved=MeshInstance3D.new(); curved.name="CurvedSpecimen"
	curved.mesh=bent_sheet(); curved.position=Vector3(-3.9,1.4,1.2); add_child(curved)
	for specimen in [flat,curved]:
		var mat:=StandardMaterial3D.new()
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.cull_mode=BaseMaterial3D.CULL_DISABLED
		mat.roughness=0.8
		specimen.material_override=mat
	box("SpecimenBench",Vector3(-3.1,0.4,1.2),Vector3(3.0,0.8,0.9))
	box("ConsoleStand",Vector3(-3.1,0.46,0.1),Vector3(1.35,0.92,0.55))
	var panel:Node3D=load("res://commons/ui/control_panel.gd").new()
	panel.title="ONE RULE / TWO SURFACES"
	panel.position=Vector3(-3.1,1.14,0.1); panel.rotation_degrees.y=180; add_child(panel)
	for title in ["MARK","SAVE","RESTORE","LINK / HOLD"]: buttons.append(panel.add_button(title))
	readout=panel.add_readout("BOTH LIVE / CURRENT RULE")
	buttons[0].pressed.connect(func(): loom.call("_toggle_peg",1,2))
	buttons[1].pressed.connect(save_recipe)
	buttons[2].pressed.connect(restore_recipe)
	buttons[3].pressed.connect(toggle_link)
	loom.recipe_changed.connect(update_specimens)
	update_specimens()
	loom.set_meta("em_visibility_bounds",AABB(Vector3(-5,0,-1),Vector3(7,2.4,7)))

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
	var n:=int(live.size)
	var img:=Image.create(n*4,n*4,false,Image.FORMAT_RGBA8)
	var group_id:int=loom.call("_group_enum_for",loom.GROUP_NAMES[int(live.group_index)])
	for y in n*4:
		for x in n*4:
			var index:int=WallpaperGroups.get_symmetric_color(x,y,n,live.card,group_id)
			var c:Array=live.palette[index]
			img.set_pixel(x,y,Color(c[0],c[1],c[2],c[3]))
	var texture:=ImageTexture.create_from_image(img)
	flat.material_override.albedo_texture=texture
	if curved_linked: curved.material_override.albedo_texture=texture
	updates+=1
	readout.text="%s / %s / CURRENT RULE" % ["BOTH LIVE" if curved_linked else "CURVE HELD",loom.group.to_upper()]

func toggle_link() -> void:
	curved_linked=not curved_linked
	update_specimens()

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
