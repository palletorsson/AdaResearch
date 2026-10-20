extends Node3D
signal changed
const Model=preload("structure_model.gd")
const View=preload("structure_view.gd")
const Rack=preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SCHEMA:="ada-random-structures/1"
const NAMES:={"columns":"A FIELD OF COLUMNS","spheres":"A FIELD LIFTED INTO SPACE","lattice":"CONNECTIONS BETWEEN LEVELS","tree":"ONE BRANCH BECOMES THREE"}
const COLOURS:={"columns":Color("dba567"),"spheres":Color("61b8ca"),"lattice":Color("a8c6a2"),"tree":Color("d19ba4")}
@export_enum("columns","spheres","lattice","tree") var structure_kind: String="columns"
@export var study_seed: int=435
@export_range(0.0,1.0) var variation: float=1.0
@export_range(0.0,1.0) var link_probability: float=0.4
@export_enum("Height","Radius","Height and radius") var column_target: int=2
@export var show_controls: bool=true
var model=Model.new()
var geometry: Dictionary={}
var view: Node3D
var title: Label3D
var readout: Label3D
var buttons: Dictionary={}
var captions: Dictionary={}
var last_saved_path:=""
var pointer_prefix:="user://random-structure-latest-"
var note:=""

func _ready() -> void:
	model.reseed(study_seed)
	build()
	redraw()

func build() -> void:
	box("Table",Vector3(1.54,0.08,1.66),Vector3(0,0.86,0.18),Color("273841"),true)
	box("Base",Vector3(1.23,0.025,1.23),Vector3(0,0.92,0),Color("e5dfd1"))
	for x in [-0.63,0.63]: box("Leg",Vector3(0.06,0.82,0.06),Vector3(x,0.41,0.25),Color("354951"))
	view=Node3D.new();view.name="Structure";view.set_script(View);view.position.y=0.94;add_child(view)
	title=label("Title","",Vector3(0,2.13,-0.64),25)
	box("TitleBack",Vector3(1.56,0.17,0.025),Vector3(0,2.13,-0.67),Color("182830"))
	readout=label("Readout","",Vector3(0,0.71,1.02),20)
	if not show_controls: return
	var names:=["BASELINE","RANGE +","SEED +1","TARGET","KEEP","REPLAY"]
	var actions:=[toggle_baseline,cycle_range,next_seed,cycle_target,keep,replay_saved]
	for i in names.size():
		var button=load("res://commons/interactables/push_button.tscn").instantiate()
		Rack.make_button_rectangular(button)
		button.name="Control_"+str(i)
		button.position=Vector3((i%3-1)*0.5,0.92,0.73+(i/3)*0.23)
		button.rotation.x=PI/2;button.scale=Vector3.ONE*1.4
		button.released_color=Color("426671")
		add_child(button);button.pressed.connect(actions[i]);buttons[names[i]]=button
		box("CaptionBack",Vector3(0.47,0.067,0.016),button.position+Vector3(0,0.09,0.03),Color("182830"))
		captions[names[i]]=label("Caption",names[i],button.position+Vector3(0,0.09,0.04),18)

func redraw() -> void:
	if view==null: return
	geometry=model.geometry(structure_kind,variation,column_target,link_probability)
	view.show_geometry(geometry,COLOURS[structure_kind])
	title.text=NAMES[structure_kind]
	var detail:=""
	match structure_kind:
		"columns": detail="100 cylinders | "+["height","radius","height + radius"][column_target]
		"spheres": detail="100 spheres | height | overlapping surfaces"
		"lattice": detail="196 nodes | %d pipes | links %.0f%%" % [geometry.rods.size(),link_probability*100]
		"tree": detail="40 branches | 27 tips | displacement"
	readout.text="%s\nseed %d | range %.2f\n%s" % [detail,study_seed,variation,note]
	if not captions.is_empty():
		captions["BASELINE"].text="VARY" if variation==0 else "BASELINE"
		captions["TARGET"].text="LINKS +" if structure_kind=="lattice" else ("TARGET" if structure_kind=="columns" else "RESET")
	changed.emit()

func set_variation(value: float) -> void:
	variation=clampf(value,0,1);note="Same retained draws; range changed.";redraw()
func toggle_baseline() -> void: set_variation(1.0 if variation==0.0 else 0.0)
func cycle_range() -> void: set_variation(0.0 if variation>=1.0 else variation+0.25)
func next_seed() -> void:
	study_seed=0 if study_seed==9223372036854775807 else study_seed+1
	model.reseed(study_seed);note="Seed incremented by one.";redraw()
func cycle_target() -> void:
	if structure_kind=="columns": column_target=(column_target+1)%3;note="Same draws; change which property varies."
	elif structure_kind=="lattice": link_probability=0.0 if link_probability>=0.999 else minf(1.0,link_probability+0.2);note="Same draws; link threshold changed."
	else: study_seed=435;model.reseed(study_seed);variation=1.0;note="Initial seed and range restored."
	redraw()
func set_kind(kind: String) -> void:
	if kind not in Model.KINDS: return
	structure_kind=kind;note="";redraw()

func capture() -> Dictionary:
	return {"schema":SCHEMA,"kind":structure_kind,"seed":str(study_seed),"variation":variation,
		"probability":link_probability,"target":column_target,"draws":model.draws.duplicate(),"engine":Engine.get_version_info().string}

func valid_record(record: Variant) -> bool:
	if not record is Dictionary or record.get("schema")!=SCHEMA or record.get("kind")!=structure_kind: return false
	if not record.get("seed") is String or not record.seed.is_valid_int() or str(int(record.seed))!=record.seed: return false
	for key in ["variation","probability"]:
		var v=record.get(key)
		if not (v is float or v is int) or not is_finite(v) or v<0 or v>1: return false
	var target=record.get("target")
	if not (target is int or target is float) or not is_finite(target) or target!=int(target) or target<0 or target>2: return false
	if not record.get("draws") is Array or record.draws.size()!=Model.DRAW_COUNT: return false
	for v in record.draws:
		if not (v is float or v is int) or not is_finite(v) or v<0 or v>4294967295 or v!=int(v): return false
	return true

func restore(record: Variant) -> bool:
	if not valid_record(record): return false
	study_seed=int(record.seed);variation=float(record.variation)
	link_probability=float(record.probability);column_target=int(record.target)
	model.set_draws(record.draws)
	note="Restored retained draws and settings.";redraw()
	return true

func keep() -> String:
	var path:="user://random-structure-%s-%d-%d.json" % [structure_kind,int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: note="Save failed; current structure retained.";redraw();return ""
	file.store_string(JSON.stringify(capture(),"\t",true,true));file.flush()
	var error:=file.get_error();file.close()
	if error!=OK: note="Save failed; current structure retained.";redraw();return ""
	last_saved_path=path
	print("Structure saved: ",ProjectSettings.globalize_path(path))
	var pointer:=FileAccess.open(pointer_prefix+structure_kind+".json",FileAccess.WRITE)
	if pointer==null: note="Saved; latest pointer unavailable. See Output.";redraw();return path
	pointer.store_string(JSON.stringify({"path":path}));pointer.close()
	note="KEPT. REPLAY reopens the saved structure.";redraw()
	return path

func replay_saved() -> bool:
	var pointer_path:=pointer_prefix+structure_kind+".json"
	if not FileAccess.file_exists(pointer_path): note="KEEP this structure first.";redraw();return false
	var pointer=JSON.parse_string(FileAccess.get_file_as_string(pointer_path))
	if not pointer is Dictionary or not pointer.get("path") is String: return false
	var file:=FileAccess.open(pointer.path,FileAccess.READ)
	if file==null or file.get_length()>1000000: return false
	var record=JSON.parse_string(file.get_as_text());file.close()
	if not restore(record): note="Incompatible record; structure retained.";redraw();return false
	last_saved_path=pointer.path
	return true

func box(id: String,size: Vector3,at: Vector3,colour: Color,solid:=false) -> void:
	var v:=MeshInstance3D.new();v.name=id;v.position=at
	var mesh:=BoxMesh.new();mesh.size=size;v.mesh=mesh
	var material:=StandardMaterial3D.new();material.albedo_color=colour;material.roughness=0.7;v.material_override=material
	add_child(v)
	if solid:
		var body:=StaticBody3D.new();body.collision_layer=1;body.collision_mask=0;v.add_child(body)
		var hit:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size;hit.shape=shape;body.add_child(hit)

func label(id: String,text: String,at: Vector3,font_size: int) -> Label3D:
	var v:=Label3D.new();v.name=id;v.text=text;v.position=at
	v.font_size=font_size;v.pixel_size=0.0022;v.outline_size=0;add_child(v)
	return v
