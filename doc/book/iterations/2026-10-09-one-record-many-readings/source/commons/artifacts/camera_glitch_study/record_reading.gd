extends Node3D
## Optional receiver on the existing camera apparatus. No new camera or collision.
const Record = preload("res://commons/artifacts/camera_glitch_study/saved_record.gd")
const TITLES := ["RGB / COLOUR","BGR / EXCHANGE R AND B","UNSIGNED / HEIGHT","SIGNED / HEIGHT","7 x 8 / INVALID LAYOUT"]
const NOTES := ["Read each RGB triplet as colour. Source bytes stay.","Exchange red and blue in the receiver; keep the record.","Selected byte 0..255 becomes height 0..1.2 m at full gain.","The same byte reads -128..127; height uses value / 128.","192 saved bytes do not fit 7 x 8 x 3 = 168. No partial reading."]
var host: Node3D
var record = Record.new()
var mode := 0
var channel := 0
var gain := .8
var origin_note := ""
var visual: Node3D
var saved_texture: ImageTexture
var busy := false
var last_decode: Dictionary = {}

func _ready() -> void:
	name="RecordReading"
	visual=Node3D.new();add_child(visual)
	hide()

func enter() -> void:
	if record.bytes().is_empty():
		if host.held_texture != null:
			record.capture(host.held_texture.get_image());origin_note="CAMERA / CENTRE SAMPLES"
		else:record.fixture();origin_note="KNOWN BYTE FIXTURE"
	show();set_detents(67.5)
	for label in host.panel.find_children("*","Label3D",true,false):
		if label.text=="0 = SOURCE":label.text="0 = FLAT HEIGHT"
	refresh()

func leave() -> void:
	hide();set_detents(30.0)
	for id in host.buttons:host.buttons[id].get_node("Button/Legend").text=id
	host.buttons["READ RECORD"].set_selected(false)
	host.reference_title.text="SOURCE / THE SAME ROOM"
	for label in host.panel.find_children("*","Label3D",true,false):
		if label.text=="0 = FLAT HEIGHT":label.text="0 = SOURCE"
	host.rebuild()

func set_detents(step_degrees: float) -> void:
	var selector=host.effect_dial.get_node("DialOrigin/InteractableHinge")
	selector.hinge_steps=step_degrees

func act(id: String) -> void:
	match id:
		"PREVIOUS":mode=posmod(mode-1,5)
		"NEXT":mode=posmod(mode+1,5)
		"LIVE / HOLD":channel=(channel+1)%3
		"HOME":record.fixture();origin_note="KNOWN BYTE FIXTURE"
		"RESET":mode=0;channel=0;gain=.8
		"SNAP":
			if busy:return
			busy=true
			# A deliberate new capture is the only camera action that replaces these bytes.
			host.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
			await host.snapshot()
			if host.held_texture!=null:
				record.capture(host.held_texture.get_image());origin_note="CAMERA / CENTRE SAMPLES"
			busy=false
	refresh()

func select(index: int) -> void:
	mode=clampi(index,0,4);refresh()

func state_text() -> String:
	return "SAVED RGB8 / 8 x 8 / 192 BYTES\n%s\nSHA256 %s... / CHANNEL %s"%[origin_note,record.digest().left(12),"RGB"[channel]]

func refresh() -> void:
	for child in visual.get_children():visual.remove_child(child);child.queue_free()
	saved_texture=ImageTexture.create_from_image(record.colour_image())
	apply_reference()
	last_decode=Record.decode(record.bytes(),7 if mode==4 else 8,8,mode==3)
	if mode<=1:
		var mesh:=MeshInstance3D.new();var quad:=QuadMesh.new();quad.size=Vector2(3.2,1.8)
		mesh.mesh=quad;mesh.position=Vector3(.55,2.1,-.2)
		var mat:=StandardMaterial3D.new();mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
		mat.albedo_texture=ImageTexture.create_from_image(record.colour_image(mode==1))
		mesh.material_override=mat;visual.add_child(mesh)
	elif mode<=3:
		var heights:PackedFloat32Array=record.heights(channel,mode==3,gain)
		var source:Image=record.colour_image()
		for y in 8:
			for x in 8:
				var height:float=heights[y*8+x]
				var at:=Vector3(.55+(x-3.5)*.37,2.15+height*.5,-.2+(y-3.5)*.19)
				make_box(at,Vector3(.34,maxf(absf(height),.008),.17),source.get_pixel(x,y))
		for x in [-.98,2.08]:make_box(Vector3(x,2.15,-.2),Vector3(.008,.008,1.6),Color("efabc8"))
		for z in [-1.0,.6]:make_box(Vector3(.55,2.15,z),Vector3(3.06,.008,.008),Color("efabc8"))
		make_text("ZERO",Vector3(2.25,2.15,.65),.0010)
		var stored:int=record.bytes()[4*3+channel]
		var interpreted:int=last_decode.values[4*3+channel]
		make_text("CELL (4, 0) / %s BYTE %d\nREAD %d -> %+.3f m\nCOLOUR VALUE / NOT CAMERA DEPTH"%["RGB"[channel],stored,interpreted,heights[4]],Vector3(.55,1.12,.7),.0011)
	else:
		assert(not last_decode.valid)
		make_box(Vector3(.55,2.1,-.2),Vector3(3.2,1.8,.02),Color("24242d"))
		make_text("LAYOUT REFUSED\n192 BYTES SAVED\n7 x 8 x 3 = 168 REQUIRED\n\nTHE RECORD IS STILL HERE",Vector3(.55,2.1,-.17),.0025)
	host.status.text="RECORD / "+TITLES[mode]
	host.description.text=NOTES[mode]
	host.hide_from_source(self)
	sync_panel()

func apply_reference() -> void:
	if saved_texture==null:return
	host.reference.material_override.albedo_texture=saved_texture
	host.reference.material_override.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST
	host.reference_title.text="SAVED RECORD / SAME 192 BYTES"

func sync_panel() -> void:
	host.effect_dial.set_normalized_value(float(mode)/4)
	host.amount_dial.set_normalized_value(gain)
	host.effect_dial.get_node("Frame/Label3DValue").text=str(mode+1)+" / 5"
	host.panel.screen_title.text="RECORD  %d / 5\n%s"%[mode+1,TITLES[mode]]
	host.panel.screen_state.text="192 BYTES KEPT / CHANNEL %s\n%s..."%["RGB"[channel],record.digest().left(12)]
	for id in host.buttons:
		host.buttons[id].set_selected(id=="READ RECORD")
		host.buttons[id].get_node("Button/Legend").modulate=Color("18282c")
	for id in {"SNAP":"SAVE 8 x 8","LIVE / HOLD":"CHANNEL "+"RGB"[channel],"HOME":"FIXTURE","RESET":"RESET VIEW"}:
		host.buttons[id].get_node("Button/Legend").text={"SNAP":"SAVE 8 x 8","LIVE / HOLD":"CHANNEL "+"RGB"[channel],"HOME":"FIXTURE","RESET":"RESET VIEW"}[id]

func make_box(at:Vector3,size:Vector3,colour:Color)->void:
	var mesh:=MeshInstance3D.new();var shape:=BoxMesh.new();shape.size=size;mesh.mesh=shape;mesh.position=at
	mesh.material_override=host.material(colour);visual.add_child(mesh)
func make_text(caption:String,at:Vector3,pixel:float)->void:
	var text:=Label3D.new();text.text=caption;text.position=at;text.font_size=36;text.pixel_size=pixel;text.modulate=Color("fff0e8");visual.add_child(text)
