extends Node3D
## A reusable, floor-standing partition: framed reading, image, drawing and pinned notes.
const Objects=preload("res://commons/artifacts/ordinary_entropies/objects.gd")
const TextPanel=preload("res://commons/artifacts/ordinary_entropies/wall_text.gd")
const Surface=preload("writing_surface.gd")
const Note=preload("sticky_note.gd")
const Pen=preload("wall_pen.gd")
const PenBody=preload("res://commons/primitives/point/drawing_pen.gd")
const Typeface=preload("res://commons/utils/baked_text_albedo.gd")
@export_enum("gallery","workshop","night") var style: String="gallery"
@export var heading:="DIFFERENT ENTROPIES / ORDINARY OBJECTS"
@export_multiline var explanation:="The same objects can answer different questions.\nThe chair studies compare colour uncertainty with\nthe number of arrangements that fit a brief.\nFurther on: recipes, motion, heat, records and guesses.\nWhich difference does each measurement leave outside?"
@export_multiline var comparisons:="Draw a comparison. Keep a question beside it.\nLift a marker and touch the whiteboard or a sticky note.\nUse the eraser locally; lift a note and release near the wall.\nWriting and note positions return on the next visit."
@export var drawing_enabled:=true
@export var notes_enabled:=true
@export var illustration_enabled:=true
@export_file("*.png","*.jpg","*.webp") var illustration_path:="res://doc/book/iterations/2026-10-16-entropy-visible-states/aerial.png"
@export var illustration_caption:="ROOM OVERVIEW / NATIVE CAPTURE"
@export var storage_key:=""
var storage_root:="user://research_info_walls/"
var persistence_enabled:=true
var panel: Node3D
var whiteboard: Node3D
var notes: Array[XRToolsPickable]=[]
var pens: Array[XRToolsPickable]=[]
var image_view: MeshInstance3D
var image_caption: Label3D
var body_material: StandardMaterial3D
var frame_material: StandardMaterial3D
var slats: Node3D
var dirty:=false
var save_clock:=0.0
var last_save_ok:=true
var loaded_record:=false

func _ready() -> void:
	if has_meta("config_style"):style=str(get_meta("config_style"))
	if has_meta("config_storage_key"):storage_key=str(get_meta("config_storage_key"))
	if has_meta("config_illustration_path"):illustration_path=str(get_meta("config_illustration_path"))
	if has_meta("config_illustration_caption"):illustration_caption=str(get_meta("config_illustration_caption"))
	for key in ["drawing_enabled","notes_enabled","illustration_enabled"]:
		if has_meta("config_"+key):set(key,str(get_meta("config_"+key)).to_lower() in ["true","1"])
	if storage_key.is_empty():
		var ancestor: Node=get_parent()
		while ancestor!=null and not ancestor.has_meta("em_map"):ancestor=ancestor.get_parent()
		var map_name: String=str(ancestor.get_meta("em_map")) if ancestor!=null else "standalone"
		var local_at: Vector3=ancestor.to_local(global_position) if ancestor is Node3D else global_position
		storage_key="%s-%s-%d-%d-%d" % [map_name,name,roundi(local_at.x*100),roundi(local_at.y*100),roundi(local_at.z*100)]
	body_material=Objects.material(Color.WHITE);frame_material=Objects.material(Color("303d3a"))
	var body:=Objects.box(self,Vector3(0,1.175,0),Vector3(6.2,2.35,0.24),Color.WHITE,true)
	body.name="SolidPartition";body.material_override=body_material
	var base:=Objects.box(self,Vector3(0,0.045,0),Vector3(6.24,0.09,0.29),Objects.DARK,true)
	base.name="FloorPlinth"
	Objects.box(self,Vector3(0,2.34,0),Vector3(6.24,0.055,0.28),Objects.DARK)
	slats=Node3D.new();add_child(slats)
	for x in range(-14,15):Objects.box(slats,Vector3(x*0.21,1.17,0.123),Vector3(0.012,2.22,0.008),Color("74634b"))
	panel=TextPanel.new();panel.backing_enabled=false;panel.heading=heading
	panel.explanation=explanation;panel.comparisons=comparisons;panel.position=Vector3(-2,1.45,0.14);add_child(panel)
	if illustration_enabled:
		frame(Vector3(0,1.65,0.145),Vector2(1.70,0.98))
		image_view=MeshInstance3D.new();image_view.name="Illustration";add_child(image_view);image_view.position=Vector3(0,1.65,0.165)
		image_caption=ink(illustration_caption,Vector3(0,1.08,0.15),19)
		set_illustration(illustration_path,illustration_caption)
	if drawing_enabled:
		frame(Vector3(2,1.45,0.145),Vector2(1.70,1.05))
		whiteboard=Surface.new();whiteboard.name="Whiteboard";whiteboard.position=Vector3(2,1.45,0.17);add_child(whiteboard)
		whiteboard.edited.connect(mark_dirty)
		ink("DRAW / COMPARE / QUESTION",Vector3(2,2.08,0.15),23)
	if notes_enabled:
		for i in 3:
			var note:=Note.new();note.name="StickyNote%d" % i;note.wall=self;note.note_index=i
			note.tint=[Color("f3df87"),Color("edb8c9"),Color("b9d5c7")][i]
			note.pinned_at=Vector2((i-1)*0.53,0.72);note.position=Vector3(note.pinned_at.x,note.pinned_at.y,0.22+i*0.001)
			add_child(note);notes.append(note)
		ink("WRITE · LIFT · PIN",Vector3(0,0.42,0.15),20)
	if drawing_enabled or notes_enabled:build_tools()
	apply_style(style)
	if persistence_enabled:restore_record()

func frame(p: Vector3,size: Vector2) -> void:
	var back:=Objects.box(self,p,Vector3(size.x,size.y,0.035),Objects.DARK);back.material_override=frame_material
	for x in [-1,1]:
		var edge:=Objects.box(self,p+Vector3(x*size.x/2,0,0.025),Vector3(0.035,size.y+0.04,0.055),Objects.DARK);edge.material_override=frame_material
	for y in [-1,1]:
		var edge:=Objects.box(self,p+Vector3(0,y*size.y/2,0.025),Vector3(size.x,0.035,0.055),Objects.DARK);edge.material_override=frame_material

func ink(words: String,p: Vector3,size: int) -> Label3D:
	var label:=Label3D.new();label.text=words;label.position=p;label.font=Typeface.project_font()
	label.font_size=size;label.pixel_size=0.0014;label.outline_size=0;label.modulate=Color("233538");add_child(label);return label

func set_illustration(path: String,caption: String) -> bool:
	if image_view==null:return false
	var picture:=Image.new();var ok:=not path.is_empty() and picture.load(path)==OK
	var quad:=QuadMesh.new();quad.size=Vector2(1.62,0.90)
	var material:=StandardMaterial3D.new();material.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	if ok:
		var ratio:=float(picture.get_width())/picture.get_height()
		quad.size=Vector2(minf(1.62,0.90*ratio),minf(0.90,1.62/ratio))
		material.albedo_texture=ImageTexture.create_from_image(picture)
	else:material.albedo_color=Color("ddd9cb")
	image_view.mesh=quad;image_view.material_override=material
	image_caption.text=caption if ok else "ILLUSTRATION SLOT"
	illustration_path=path;illustration_caption=caption;return ok

func build_tools() -> void:
	Objects.box(self,Vector3(2,0.83,0.27),Vector3(1.7,0.06,0.34),Objects.DARK,true)
	for i in 3:
		var pen:=Pen.new();pen.name=["InkMarker","RedMarker","Eraser"][i];pen.wall=self;pen.board=self
		pen.ink=[Color("242b35"),Color("b93e5c"),Color.WHITE][i];pen.eraser=i==2
		pen.freeze=true;pen.release_mode=XRToolsPickable.ReleaseMode.UNFROZEN
		pen.collision_layer=4;pen.collision_mask=1;pen.mass=0.08;pen.continuous_cd=true;pen.return_enabled=true
		pen.position=Vector3(2+(i-1)*0.47,0.91,0.32)
		if i<2:PenBody.build_body(pen,pen.ink)
		else:
			Objects.box(pen,Vector3.ZERO,Vector3(0.09,0.05,0.06),Objects.DARK)
			var collider:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(0.09,0.05,0.06);collider.shape=shape;pen.add_child(collider)
			var tip:=Marker3D.new();tip.name="WritingTip";tip.position.z=-0.035;pen.add_child(tip)
		add_child(pen);pens.append(pen)
		ink(["INK","RED","ERASE"][i],Vector3(pen.position.x,0.77,0.45),18)

func writing_surfaces() -> Array:
	var result: Array=[]
	for note in notes:result.append(note.surface)
	if whiteboard!=null:result.append(whiteboard)
	return result

func apply_grid_config(config: Dictionary) -> void:
	if config.has("style"):apply_style(str(config.style))
	if config.has("illustration_path"):set_illustration(str(config.illustration_path),str(config.get("illustration_caption",illustration_caption)))

func apply_style(value: String) -> void:
	style=value if value in ["gallery","workshop","night"] else "gallery"
	if body_material==null:return
	body_material.albedo_color={"gallery":Color("e2dfd4"),"workshop":Color("a68c67"),"night":Color("263d48")}[style]
	frame_material.albedo_color=Color("d1ad6c") if style=="night" else Color("32443e")
	slats.visible=style=="workshop"
	for label in get_children():
		if label is Label3D:label.modulate=Color("eee7d8") if style=="night" else Color("233538")

func mark_dirty() -> void:dirty=true;save_clock=0.0
func _process(delta: float) -> void:
	if not dirty:return
	save_clock+=delta
	if save_clock>=0.8:save_record()
func _exit_tree() -> void:
	if dirty:save_record()

func record_path() -> String:
	return storage_root+storage_key.validate_filename()+".json"

func save_record() -> bool:
	if not persistence_enabled:dirty=false;return true
	var record:={"schema":"research-info-wall/1","notes":[]}
	if whiteboard!=null:record["whiteboard"]=whiteboard.encode_ink()
	for note in notes:record.notes.append({"x":note.pinned_at.x,"y":note.pinned_at.y,"ink":note.surface.encode_ink()})
	DirAccess.make_dir_recursive_absolute(storage_root)
	var file:=FileAccess.open(record_path(),FileAccess.WRITE)
	if file==null:last_save_ok=false;return false
	file.store_string(JSON.stringify(record));file.flush();last_save_ok=file.get_error()==OK;file.close()
	if last_save_ok:dirty=false
	return last_save_ok

func restore_record() -> bool:
	if not FileAccess.file_exists(record_path()):return false
	var file:=FileAccess.open(record_path(),FileAccess.READ)
	if file==null:return false
	if file.get_length()>12000000:file.close();return false
	var record: Variant=JSON.parse_string(file.get_as_text());file.close()
	if not record is Dictionary or record.get("schema")!="research-info-wall/1":return false
	if whiteboard!=null and record.get("whiteboard") is String:whiteboard.restore_ink(record.whiteboard)
	var saved: Variant=record.get("notes",[])
	if saved is Array:
		for i in mini(saved.size(),notes.size()):
			var n: Variant=saved[i]
			if not n is Dictionary or not n.get("ink") is String:continue
			var x: Variant=n.get("x");var y: Variant=n.get("y")
			if not (x is float or x is int) or not (y is float or y is int) or not is_finite(x) or not is_finite(y):continue
			notes[i].pinned_at=Vector2(clampf(x,-2.9,2.9),clampf(y,0.3,2.1))
			notes[i].position=Vector3(notes[i].pinned_at.x,notes[i].pinned_at.y,0.22+i*0.001)
			notes[i].surface.restore_ink(n.ink)
	loaded_record=true;dirty=false;return true
