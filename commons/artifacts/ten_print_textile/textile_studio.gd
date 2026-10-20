extends Node3D
## The same retained draws on three fabrics, a fitted dress and the active wearer.
const PrintRecord = preload("res://commons/artifacts/ten_print_textile/print_record.gd")
const Cloth = preload("res://commons/artifacts/garment_cutting_table/cloth_record.gd")
const Suit = preload("res://commons/player/tailored_suit.gd")
const Mirror = preload("res://commons/artifacts/super_drag_mirror/super_drag_mirror.gd")
const Stage = preload("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
const Rack = preload("res://commons/audio/rack_templates/RackTemplates.gd")
const STYLES := ["aline","gown","pleated"]
const STYLE_NAMES := ["A-LINE","GOWN","PLEATED"]
@export var save_path := "user://ada_ten_print_cloth.json"
var record: Dictionary = PrintRecord.make()
var specimens: Array[MeshInstance3D] = []
var hems: Array[MeshInstance3D] = []
var buttons: Dictionary = {}
var preview: Node3D
var mirror: Node3D
var plate: Label3D
var style_index := 0
var notice := "Choose a cloth. Try it in the mirror."
var worn_wardrobe: WeakRef
var previous_outfit := ""
var previous_cloth: Dictionary = {}
var previous_style := "suit"

func _ready() -> void:
	_build()
	refresh()

func apply_grid_config(config: Dictionary) -> void:
	if config.has("seed"):
		record = PrintRecord.make(int(config.seed))
		if is_instance_valid(preview): refresh()

func _build() -> void:
	var brass := Color("baa170")
	var ink := Color("25213b")
	# Open floor: no plinth between the visitor, cloth and changing alcove.
	for x in [-4.15,-.05]:
		Stage.box(self,Vector3(x,1.35,.64),Vector3(.055,2.7,.055),brass)
	Stage.box(self,Vector3(-2.1,2.68,.64),Vector3(4.15,.06,.06),brass)
	for i in range(3):
		var x := -3.45+i*1.32
		var swatch := MeshInstance3D.new()
		swatch.name = PrintRecord.TITLES[i]+"_Cloth"
		swatch.mesh = draped_mesh()
		swatch.position = Vector3(x,1.55,.55)
		add_child(swatch); specimens.append(swatch)
		var hem := Stage.box(self,Vector3(x,.64,.51),Vector3(1.16,.018,.028),brass)
		hems.append(hem)
		Stage.box(self,Vector3(x,2.49,.58),Vector3(1.22,.025,.055),brass)
		label(PrintRecord.TITLES[i],Vector3(x,2.58,.50),.0018,23)
	controls("ONE SEED / THREE FABRICS",[
		["RIBBON","STITCH","PIXEL"],
		["SEED +","PALETTE","REPEAT"],
		["KEEP","REPLAY","RESET"]],Vector3(-2.1,1.05,-.72))
	plate = label("",Vector3(-2.1,.55,-.77),.0014,23)
	Stage.box(self,plate.position+Vector3(0,0,.018),Vector3(1.72,.22,.03),ink)
	# Keep an open aisle to the hall exit behind the studio, beside the fitting.
	for child in get_children():
		if child is Node3D: child.position.x-=.8
	# Fitting at eye/hand scale, separate from the body seen in the mirror.
	preview = Suit.new(); preview.name="DressFitting"; preview.style=STYLES[style_index]
	preview.record=record.duplicate(true); preview.position=Vector3(.85,1.54,.65)
	add_child(preview)
	var head := MeshInstance3D.new(); var sphere := SphereMesh.new()
	sphere.radius=.105;sphere.height=.25;head.mesh=sphere
	head.position=Vector3(.85,1.69,.65);head.material_override=Stage.material(Color("c6b8aa"));add_child(head)
	label("FITTING",Vector3(.85,1.95,.5),.0018,23)
	# Full-height rear and side panels make a room; the front remains a 2.3m opening.
	Stage.box(self,Vector3(3.2,1.48,1.76),Vector3(2.66,2.96,.08),Color("d5c5ca"),true)
	for x in [1.90,4.50]:
		Stage.box(self,Vector3(x,1.48,.35),Vector3(.07,2.96,2.9),Color("c2a8b6"),true)
		Stage.box(self,Vector3(x,2.99,.35),Vector3(.09,.055,2.9),brass)
	Stage.box(self,Vector3(3.2,2.99,-1.08),Vector3(2.67,.055,.07),brass)
	label("DRESSING ROOM",Vector3(3.2,2.79,-1.13),.002,28)
	mirror=Mirror.new();mirror.name="TextileMirror";mirror.show_wardrobe_controls=false
	mirror.resolution=512;mirror.position=Vector3(3.2,.0,1.62);mirror.rotation.y=PI
	add_child(mirror)
	var dressing_controls:=controls("YOUR CLOTH / YOUR DRESS",[["WEAR","SHAPE","TAKE OFF"]],Vector3(4.3,1.06,.05))
	dressing_controls.rotation.y=-PI/2
	# Controls stand at the side of the doorway, leaving a full-width entrance beside them.
	# The small plate is visual; it is not a full blocking collision box.
	label("Same draws. Other marks.\nChoose a print. Wear the pattern.",Vector3(-2.9,2.98,.5),.002,27)
	for x in [-3.0,3.2]:
		var light := OmniLight3D.new(); light.position=Vector3(x,2.55,-.3)
		light.light_color=Color("fff1df");light.light_energy=.65;light.omni_range=4;add_child(light)

func label(words: String, at: Vector3, pixel: float, font: int) -> Label3D:
	var l := Stage.label(self,words,at,PI)
	l.pixel_size=pixel;l.font_size=font;l.outline_size=2
	return l

func controls(title: String, rows: Array, at: Vector3) -> Node3D:
	var definitions: Array = []
	for row in rows:
		var entries: Array = []
		for key in row: entries.append({"type":"button","label":key})
		definitions.append(entries)
	var panel := Rack.create_panel(title,definitions)
	panel.set_meta("em_embedded_control",true)
	panel.scale=Vector3.ONE*1.4
	panel.position=at;panel.rotation.y=PI;add_child(panel)
	var index := 0
	for row in rows:
		for key in row:
			var b: Node3D=panel.find_child("Btn_"+str(index),true,false)
			b.rotation.x=PI/2
			b.pressed.connect(func():act.call_deferred(key))
			buttons[key]=b;index+=1
	Stage.box(self,at+Vector3(0,-at.y/2,.07),Vector3(.035,at.y,.035),Color("baa170"))
	return panel

static func draped_mesh() -> ArrayMesh:
	var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in range(36):
		for col in range(24):
			for offset in [Vector2(0,0),Vector2(0,1),Vector2(1,0),Vector2(1,0),Vector2(0,1),Vector2(1,1)]:
				var uv: Vector2 = (Vector2(col,row)+offset)/Vector2(24,36)
				var depth := .035*sin(uv.x*TAU*4.0)+.12*pow(uv.y,2)
				st.set_uv(uv);st.add_vertex(Vector3((uv.x-.5)*1.16,(.5-uv.y)*1.8,depth))
	st.generate_normals();return st.commit()

func act(key: String) -> void:
	if PrintRecord.TITLES.has(key):
		record.mark=PrintRecord.TITLES.find(key);notice="Selected "+key+". The same 252 draws."
	else:
		match key:
			"SEED +":
				var fresh:=PrintRecord.make(int(record.seed)+1)
				for k in ["mark","palette","repeat"]: fresh[k]=record[k]
				record=fresh;notice="New seeded draws; the design settings stay."
			"PALETTE":record.palette=(int(record.palette)+1)%3;notice="New yarn-like colours; draws unchanged."
			"REPEAT":record.repeat=int(record.repeat)%3+1;notice="Repeat count changes; draws unchanged."
			"RESET":record=PrintRecord.make();notice="Seed 41 / original studio cloth."
			"SHAPE":style_index=(style_index+1)%STYLES.size();notice="Preview: "+STYLE_NAMES[style_index]+". Press WEAR to apply."
			"KEEP":notice="Cloth kept with its draws and design." if Cloth.save_record(record,save_path) else "Could not save this cloth."
			"REPLAY":
				var kept:=Cloth.load_record(save_path)
				if PrintRecord.valid(kept):record=kept;notice="Kept cloth restored. Press WEAR to apply."
				else:notice="No kept 10 PRINT cloth yet."
			"WEAR":wear()
			"TAKE OFF":take_off()
	refresh()

func wardrobe() -> Node:
	var cam:=get_viewport().get_camera_3d()
	for w in get_tree().get_nodes_in_group("costume_wardrobes"):
		if w.has_method("wears_head") and w.wears_head(cam):return w
	return null

func wear() -> bool:
	var w:=wardrobe()
	if not w:notice="No active wearer found.";return false
	if not worn_wardrobe or worn_wardrobe.get_ref()!=w:
		previous_outfit=w.costume.outfit_id;previous_cloth=w.suit_cloth.duplicate(true)
		previous_style=w.suit_style;worn_wardrobe=weakref(w)
	var ok:bool=w.set_tailored_suit(record,true,STYLES[style_index])
	notice=STYLE_NAMES[style_index]+" worn. Step inside; look down or in the mirror." if ok else "Dress worn; wardrobe save failed."
	return ok

func take_off() -> void:
	var w:Node=worn_wardrobe.get_ref() if worn_wardrobe else null
	if not is_instance_valid(w):notice="No dress to take off here.";return
	w.suit_cloth=previous_cloth.duplicate(true);w.suit_style=previous_style
	w.choose_outfit(previous_outfit);worn_wardrobe=null;notice="Previous outfit restored."

func refresh() -> void:
	record.name="10 PRINT / "+PrintRecord.TITLES[int(record.mark)]
	for i in range(specimens.size()):
		var sample:=record.duplicate(true);sample.mark=i
		specimens[i].material_override=Cloth.material(sample)
		hems[i].material_override=Stage.material(Color("ed91be") if i==int(record.mark) else Color("baa170"))
	if preview:
		preview.set_style(STYLES[style_index]);preview.set_record(record)
	if plate:plate.text="SEED %d / %s / REPEAT %dx\n%s"%[int(record.seed),PrintRecord.TITLES[int(record.mark)],int(record.repeat),notice]

func get_state() -> Dictionary:
	return {"record":record.duplicate(true),"style":STYLES[style_index],"notice":notice}
