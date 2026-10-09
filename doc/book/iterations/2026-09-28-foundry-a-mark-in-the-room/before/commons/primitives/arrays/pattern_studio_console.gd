extends Node3D
## Body-sized front end for the existing studio model. Controls edit only this
## station; hall receivers and loom recipes have their own explicit ownership.
const Loader = preload("res://commons/patterns/pattern_loader.gd")
const BUTTON = preload("res://commons/interactables/push_button.tscn")
const GRID_METRES := 0.42
var model: Node3D
var mount: Node3D
var preview: MeshInstance3D
var material: ShaderMaterial
var labels: Dictionary = {}
var controls: Dictionary = {}
var cell_buttons: Array[Node3D] = []
var swatches: Array[MeshInstance3D] = []
var history: Array[Dictionary] = []
var package_extra: Dictionary = {}
var pattern_name := "Checkerboard"
var status := "PAINT A CELL / FOLLOW ITS COPIES"
var save_path := "user://pattern_recipes/studio.json"
var library_path := "res://commons/patterns"
var library_index := -1
var surface_controls:Node3D

func _ready() -> void:
	model = get_parent()
	model.palette.clear()
	for color in model.PERIODS[1].colors:model.palette.append(Color.html(color))
	mount = Node3D.new(); mount.name = "StudioMount"
	mount.position.y = 1.18; mount.rotation_degrees.x = -15; add_child(mount)
	model._plate_parent = mount
	box(mount, "Bezel", Vector3(0,0,-0.038), Vector3(1.36,1.23,0.065), Color("292b2c"))
	box(mount, "Face", Vector3(0,0,0), Vector3(1.32,1.19,0.026), Color("e3ddd0"))
	box(mount, "Accent", Vector3(0,0.49,0.019), Vector3(1.24,0.004,0.003), Color("c47c49"))
	box(self, "Pedestal", Vector3(0,0.13,-0.36), Vector3(0.56,1.9,0.42), Color("bdb6aa"), true)
	label("title", "PATTERN STUDIO", Vector3(0,0.555,0.022), 0.0011)
	label("source", "01  SOURCE / 2 x 2", Vector3(-0.32,0.447,0.022))
	label("result", "02  REPEATED SURFACE", Vector3(0.32,0.447,0.022))
	preview = MeshInstance3D.new(); preview.name = "TiledPreview"
	var sheet := QuadMesh.new(); sheet.size = Vector2(GRID_METRES,GRID_METRES)
	preview.mesh = sheet; preview.position = Vector3(0.32,0.20,0.023); mount.add_child(preview)
	model._build_carpet()
	material = Loader.create_material(Loader.PatternPackage.new())
	preview.material_override = material; model._carpet_mesh.material_override = material
	var rug := QuadMesh.new(); rug.size = Vector2(model.CARPET_W,model.CARPET_H); model._carpet_mesh.mesh = rug
	# Nine separated palette buttons; selected paint has a contrasting frame.
	var palette_root := Node3D.new(); palette_root.name = "Palette"; mount.add_child(palette_root)
	for i in range(9):
		var pos := Vector3(-0.524 + float(i)*0.051, -0.10, 0.025)
		var swatch := box(palette_root,"Swatch_%d"%i,pos,Vector3(0.043,0.043,0.006),Color.WHITE)
		swatches.append(swatch)
		button("paint_%d"%i,pos,func(): model._select_color(i),0.50,true)
	label("paint", "PAINT 1", Vector3(-0.32,-0.155,0.022),0.0006)
	selector("palette",Vector3(0.32,-0.10,0.025),func(d): choose("palette",d))
	selector("motif",Vector3(-0.43,-0.25,0.025),func(d): choose("motif",d))
	selector("group",Vector3(0,-0.25,0.025),func(d): choose("group",d))
	selector("size",Vector3(0.43,-0.25,0.025),func(d): choose("size",d))
	var actions := ["MIRROR","ROTATE","CLEAR","UNDO","WEB NEXT","SAVE","RESTORE"]
	for i in actions.size():
		var action: String = actions[i]
		var pos := Vector3((i-3)*0.178,-0.415,0.025)
		button(action,pos,func(): act(action))
		label(action,action,pos+Vector3(0,-0.058,0),0.00062)
	label("status",status,Vector3(0,-0.55,0.025),0.00065)
	rebuild_grid()
	refresh()
	surface_controls=load("res://commons/primitives/arrays/studio_surface_controls.gd").new()
	surface_controls.name="SurfaceControls";add_child(surface_controls)

func receiver_material(metres:Vector2) -> ShaderMaterial:
	return surface_controls.material_for_surface(metres)

func box(parent:Node3D,id:String,pos:Vector3,size:Vector3,color:Color,solid:bool=false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new(); mesh.name=id; mesh.position=pos
	var shape := BoxMesh.new(); shape.size=size; mesh.mesh=shape
	var mat := StandardMaterial3D.new(); mat.albedo_color=color; mat.roughness=0.75
	mesh.material_override=mat; parent.add_child(mesh)
	if solid: mesh.create_convex_collision()
	return mesh

func label(id:String,text:String,pos:Vector3,pixel:float=0.00075) -> void:
	var node := Label3D.new(); node.text=text; node.font_size=32; node.pixel_size=pixel
	node.position=pos; node.outline_size=0; node.modulate=Color("292b2c")
	mount.add_child(node); labels[id]=node

func button(id:String,pos:Vector3,callback:Callable,size:float=1.0,hidden:bool=false) -> Node3D:
	var node:Node3D=BUTTON.instantiate(); node.name=id.validate_node_name()
	node.position=pos; node.scale=Vector3.ONE*size; mount.add_child(node)
	if hidden:
		for child in node.find_children("*","MeshInstance3D",true,false): child.visible=false
	node.pressed.connect(callback); controls[id]=node
	return node

func selector(id:String,pos:Vector3,callback:Callable) -> void:
	button(id+"_prev",pos+Vector3(-0.14,0,0),func():callback.call(-1),0.75)
	button(id+"_next",pos+Vector3(0.14,0,0),func():callback.call(1),0.75)
	label(id+"_prev","<",pos+Vector3(-0.14,0,0.045),0.001)
	label(id+"_next",">",pos+Vector3(0.14,0,0.045),0.001)
	label(id,id.to_upper(),pos+Vector3(0,0.052,0),0.00065)
	label(id+"_value","",pos+Vector3(0,-0.013,0),0.00062)

func rebuild_grid() -> void:
	var old:=mount.get_node_or_null("PaintGrid")
	if old:
		mount.remove_child(old); old.queue_free()
	var grid:=Node3D.new(); grid.name="PaintGrid"; mount.add_child(grid)
	model._grid_cells.clear(); cell_buttons.clear()
	var n:int=model._current_grid_size
	var pitch:float=GRID_METRES/n
	for y in n:
		for x in n:
			# Row zero is at the top, matching the browser and domain texture.
			var pos:=Vector3(-0.32+(x+0.5)*pitch-GRID_METRES/2,0.20+GRID_METRES/2-(y+0.5)*pitch,0.025)
			var cell:=box(grid,"Cell_%d_%d"%[x,y],pos,Vector3(pitch*0.9,pitch*0.9,0.006),Color.WHITE)
			model._grid_cells.append(cell)
			var hit:Node3D=BUTTON.instantiate();hit.position=pos;hit.scale=Vector3.ONE*minf(pitch/0.085*0.9,1.8)
			grid.add_child(hit)
			for child in hit.find_children("*","MeshInstance3D",true,false):child.visible=false
			hit.pressed.connect(func():model.set_cell(x,y,model.selected_color))
			cell_buttons.append(hit)
	labels.source.text="01  SOURCE / %d x %d"%[n,n]

func export_package() -> Dictionary:
	var data:=package_extra.duplicate(true)
	data.merge({"name":pattern_name,"group":model.GROUPS[model.wallpaper_group],"domain_size":model._current_grid_size,"domain":model._grid_data.duplicate(true),"palette":model.palette.map(func(c):return "#"+c.to_html()),"zone":data.get("zone","field"),"tile_scale":data.get("tile_scale",6)},true)
	return data

func refresh() -> void:
	if not preview:return
	model._cell_materials.clear();model._refresh_grid_visuals();refresh_palette()
	var data:=export_package()
	var pkg:=Loader.PatternPackage.new()
	pkg.domain_size=model._current_grid_size;pkg.group=model._get_wallpaper_enum()
	pkg.domain_texture=Loader._build_domain_texture(model._grid_data,PackedColorArray(model.palette),pkg.domain_size)
	for key in ["tile_scale","tile_shape","grout_width","noise_distort","wear_amount","dust_amount","fade_amount","crack_density","stain_amount","chip_amount"]:
		if data.has(key):pkg.set(key,data[key])
	Loader.apply_to_material(material,pkg)
	labels.motif_value.text=pattern_name.left(20)
	labels.group_value.text=model.GROUPS[model.wallpaper_group]
	labels.size_value.text="%d x %d"%[model._current_grid_size,model._current_grid_size]
	labels.palette_value.text=model.PERIODS[model._current_period].name if model._current_period>=0 else "WEB PALETTE"
	labels.status.text=status
	if surface_controls:surface_controls.source_changed()

func refresh_palette() -> void:
	for i in swatches.size():
		var available:bool=i<model.palette.size()
		swatches[i].visible=available;controls["paint_%d"%i].visible=available
		controls["paint_%d"%i].get_node("InteractableAreaButton").collision_layer=1048576 if available else 0
		controls["paint_%d"%i].get_node("InteractableAreaButton").collision_mask=393216 if available else 0
		if available:
			swatches[i].material_override=model._get_material(i)
			swatches[i].scale=Vector3.ONE*(1.13 if i==model.selected_color else 1.0)
	labels.paint.text="PAINT %d / %s"%[model.selected_color,model.palette[model.selected_color].to_html(false).to_upper()]

func remember() -> void:
	history.append({"package":export_package(),"paint":model.selected_color,"motif":model._current_motif,"period":model._current_period})
	if history.size()>32:history.pop_front()

func choose(kind:String,direction:int) -> void:
	remember()
	match kind:
		"motif":
			var idx:int=posmod(model._current_motif+direction,model.MOTIFS.size())
			while model.palette.size()<3:model.palette.append(Color.html(model.PERIODS[1].colors[model.palette.size()]))
			pattern_name=model.MOTIFS[idx].name;model._load_motif(idx)
		"group":model.wallpaper_group=posmod(model.wallpaper_group+direction,model.GROUPS.size())
		"palette":
			while model.palette.size()<9:model.palette.append(Color.WHITE)
			model._apply_period_palette(posmod(model._current_period+direction,model.PERIODS.size()))
		"size":model._change_grid_size(model.SIZES[posmod(model._current_size_idx+direction,model.SIZES.size())])
	status="%s CHANGED / UNDO KEEPS THE PREVIOUS STATE"%kind.to_upper();refresh()

func act(action:String) -> void:
	match action:
		"UNDO":
			if history.is_empty():status="NOTHING TO UNDO"
			else:
				var prior:Dictionary=history.pop_back();import_package(prior.package,false)
				model.selected_color=prior.paint;model._current_motif=prior.motif;model._current_period=prior.period
				status="PREVIOUS SOURCE RESTORED"
		"WEB NEXT":load_next_web()
		"SAVE":save_local()
		"RESTORE":restore_local()
		_:
			remember()
			match action:
				"MIRROR":model._mirror_grid()
				"ROTATE":model._rotate_grid()
				"CLEAR":model._clear_grid()
			status=action+" / UNDO AVAILABLE"
	refresh()

func valid_package(data:Variant) -> bool:
	if not data is Dictionary:return false
	var n:Variant=data.get("domain_size")
	if not (n is int or n is float) or not n in model.SIZES:return false
	if not data.get("group") is String or not data.group.to_upper() in model.GROUPS:return false
	var colors:Variant=data.get("palette")
	if not colors is Array or colors.size()<1 or colors.size()>9:return false
	for color in colors:
		if not color is String or not Color.html_is_valid(color):return false
	var domain:Variant=data.get("domain")
	if not domain is Array or domain.size()!=n:return false
	for row in domain:
		if not row is Array or row.size()!=n:return false
		for index in row:
			if not (index is int or index is float) or not is_finite(index) or int(index)!=index or index<0 or index>=colors.size():return false
	if not data.get("name","") is String or not data.get("zone","field") is String:return false
	for key in ["tile_scale","tile_shape","grout_width","noise_distort","wear_amount","dust_amount","fade_amount","crack_density","stain_amount","chip_amount"]:
		if not data.has(key):continue
		var value:Variant=data[key]
		if not (value is int or value is float) or not is_finite(value):return false
		var maximum:=24.0 if key=="tile_scale" else (6.0 if key=="tile_shape" else 1.0)
		if value<0 or value>maximum or (key=="tile_scale" and value<1):return false
		if key=="tile_shape" and int(value)!=value:return false
	return true

func import_package(data:Variant,keep_undo:bool=true) -> bool:
	if not valid_package(data):
		status="UNSUPPORTED PACKAGE / USE 2, 4, 6 OR 8 CELLS AND UP TO 9 COLOURS"
		return false
	if keep_undo:remember()
	package_extra=data.duplicate(true);pattern_name=data.get("name","Web pattern")
	model._current_grid_size=int(data.domain_size);model._current_size_idx=model.SIZES.find(model._current_grid_size)
	model._grid_data=data.domain.duplicate(true);model.wallpaper_group=model.GROUPS.find(data.group.to_upper())
	model.palette.clear()
	for color in data.palette:model.palette.append(Color.html(color))
	model.selected_color=mini(model.selected_color,model.palette.size()-1);model._current_period=-1
	rebuild_grid();status="PACKAGE LOADED / SOURCE + SHADER FINISH";refresh();return true

func read_package(path:String) -> Variant:
	var file:=FileAccess.open(path,FileAccess.READ)
	if not file or file.get_length()>65536:return null
	return JSON.parse_string(file.get_as_text())

func load_next_web() -> void:
	var files:=DirAccess.get_files_at(library_path);files.sort()
	var candidates:Array[String]=[]
	for file in files:
		if file.ends_with(".json"):candidates.append(file)
	if candidates.is_empty():status="NO WEB PACKAGES / SAVE ONE IN THE WEB STUDIO";return
	library_index=(library_index+1)%candidates.size()
	import_package(read_package(library_path.path_join(candidates[library_index])))

func save_local() -> void:
	DirAccess.make_dir_recursive_absolute(save_path.get_base_dir())
	var file:=FileAccess.open(save_path,FileAccess.WRITE)
	if not file:status="SAVE FAILED";return
	file.store_string(JSON.stringify(export_package(),"  "));file.close();status="SAVED LOCALLY / SOURCE + SHADER FINISH"

func restore_local() -> void:
	if not FileAccess.file_exists(save_path):status="NO LOCAL SAVE YET";return
	import_package(read_package(save_path))
