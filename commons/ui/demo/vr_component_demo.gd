@tool
extends Node3D
## One active family at operating height. Physical paging replaces the tall wall.
const BakedText=preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface=preload("res://commons/ui/control_value_surface.gd")
const SLIDER_V     = preload("res://commons/interactables/slider_smooth.tscn")
const SLIDER_H     = preload("res://commons/interactables/slider_horizontal.tscn")
const SLIDER_SNAP  = preload("res://commons/interactables/slider_snap.tscn")
const SLIDER_ZERO  = preload("res://commons/interactables/slider_zero.tscn")
const SLIDER_AXIS  = preload("res://commons/interactables/slider_axis.tscn")
const SLIDER_TIME  = preload("res://commons/interactables/slider_time.tscn")
const DIAL         = preload("res://commons/interactables/dial_smooth.tscn")
const BUTTON       = preload("res://commons/interactables/push_button.tscn")
const BUTTON_2D3D  = preload("res://commons/interactables/push_button_2d3d.tscn")
const JOYSTICK     = preload("res://commons/interactables/joystick_smooth.tscn")
const JOYSTICK_SNAP = preload("res://commons/interactables/joystick_snap.tscn")
const JOYSTICK_ZERO = preload("res://commons/interactables/joystick_zero.tscn")
const LEVER        = preload("res://commons/interactables/lever_smooth.tscn")
const LEVER_SNAP   = preload("res://commons/interactables/lever_snap.tscn")
const LEVER_ZERO   = preload("res://commons/interactables/lever_zero.tscn")
const WHEEL        = preload("res://commons/interactables/wheel_smooth.tscn")
const XY_PAD       = preload("res://commons/interactables/slider_plane.tscn")

const WAVEFORM     = preload("res://commons/audio/interfaces/VRWaveformDisplay.tscn")
const SPECTRUM     = preload("res://commons/audio/interfaces/VRSpectrumDisplay.tscn")
const SIMPLE_WAVE  = preload("res://commons/audio/interfaces/VRSimpleWaveform.tscn")
const LISSAJOUS    = preload("res://commons/audio/interfaces/VRLissajousDisplay.tscn")
const MONITOR      = preload("res://commons/audio/interfaces/VRAudioMonitor.tscn")

const VR_DIAL      = preload("res://commons/audio/interfaces/VRAudioControlDial.tscn")
const VR_SLIDER    = preload("res://commons/audio/interfaces/VRAudioControlSlider.tscn")
const VR_SLIDER_V  = preload("res://commons/audio/interfaces/VRAudioControlSliderVertical.tscn")


var pages:Array=[]
var page_index:=0
var controls:Array[Node3D]=[]
var station:Node3D
var active_page:Node3D
var _heading:Dictionary={}
var _mirrors:Array=[]
var _refresh_time:=0.0
var _changing:=false

func _ready()->void:
	# The library is also an artifact. Preview cameras and lights must not take over a hall.
	if not Engine.is_editor_hint() and get_tree().current_scene!=self:
		for name in ["WorldEnvironment","DirectionalLight3D","FillLight","Camera3D"]:
			var preview:=get_node_or_null(name)
			if preview:remove_child(preview);preview.queue_free()
	var obsolete:=get_node_or_null("Backdrop")
	if obsolete:remove_child(obsolete);obsolete.queue_free()
	var container:=get_node_or_null("Components")
	if not container:container=Node3D.new();container.name="Components";add_child(container)
	container.transform=Transform3D.IDENTITY
	station=Node3D.new();station.name="Station";station.position.y=1.0;station.rotation_degrees.x=-35;container.add_child(station)
	_box(station,"Deck",Vector3(1.10,.54,.04),Vector3(0,0,-.025),Color(.12,.17,.18))
	_box(container,"Stem",Vector3(.15,.88,.16),Vector3(0,.44,-.04),Color(.12,.17,.18))
	_box(station,"UndersideMount",Vector3(.20,.15,.08),Vector3(0,-.055,-.085),Color(.12,.17,.18))
	_box(container,"Foot",Vector3(.76,.04,.48),Vector3(0,.02,0),Color(.12,.17,.18))
	_box(container,"Header",Vector3(1.10,.29,.035),Vector3(0,1.58,-.25),Color(.09,.13,.14))
	_heading=ValueSurface.build(container,Vector2(1.05,.14),Vector3(0,1.53,-.229))
	_heading.viewport.size=Vector2i(1200,160);_heading.viewport.get_child(0).size=Vector2(1200,160)
	_heading.label.size=Vector2(1200,160);_heading.label.add_theme_font_size_override("font_size",32)
	_print(container,"ADA COMPONENT LIBRARY",Vector2(1.04,.040),Vector3(0,1.69,-.229))
	_box(container,"HeaderPost",Vector3(.05,1.52,.05),Vector3(0,.76,-.27),Color(.12,.17,.18))
	_add_pager("Prev","PREVIOUS",-.18,-1)
	_add_pager("Next","NEXT",.18,1)
	pages=[
		{"title":"VERTICAL SLIDERS","items":[[SLIDER_V,"SMOOTH"],[SLIDER_AXIS,"AUTO / HAND"],[SLIDER_SNAP,"STEPPED"],[SLIDER_ZERO,"RETURN TO CENTRE"]],"gap":.24},
		{"title":"HORIZONTAL / TIME","items":[[SLIDER_H,"HORIZONTAL"],[SLIDER_TIME,"TIME"]],"gap":.38},
		{"title":"DIALS / WHEEL","items":[[DIAL,"DIAL"],[DIAL,"DIAL 2"],[WHEEL,"WHEEL"]],"gap":.28},
		{"title":"PUSH BUTTONS","items":[[BUTTON,"BUTTON"],[BUTTON_2D3D,"2D / 3D BUTTON"],[BUTTON,"BUTTON 2"]],"gap":.28},
		{"title":"JOYSTICKS","items":[[JOYSTICK,"CONTINUOUS"],[JOYSTICK_SNAP,"STEPPED"],[JOYSTICK_ZERO,"RETURNING"]],"gap":.28},
		{"title":"LEVERS","items":[[LEVER,"CONTINUOUS"],[LEVER_SNAP,"STEP 5 DEGREES"],[LEVER_ZERO,"RETURN TO ZERO"]],"gap":.24},
		{"title":"TWO AXES","items":[[XY_PAD,"XY PAD"]],"gap":.28},
		{"title":"AUDIO DIALS","items":[[VR_DIAL,"AUDIO DIAL"],[VR_DIAL,"AUDIO DIAL 2"]],"gap":.30},
		{"title":"AUDIO FADERS","items":[[VR_SLIDER,"FADER"],[VR_SLIDER_V,"VERTICAL FADER"]],"gap":.38},
		{"title":"WAVE / SPECTRUM","items":[[WAVEFORM,"WAVEFORM"],[SPECTRUM,"SPECTRUM"],[SIMPLE_WAVE,"SIMPLE WAVE"]],"gap":.34},
		{"title":"SIGNAL MONITORS","items":[[LISSAJOUS,"LISSAJOUS"],[MONITOR,"MONITOR"]],"gap":.38}
	]
	show_page(0)
	var camera:=get_node_or_null("Camera3D") as Camera3D
	if camera and not Engine.is_editor_hint():camera.position=Vector3(1.4,1.9,2.6);camera.look_at(Vector3(0,1.05,0))

func _input(event:InputEvent)->void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_R:_rebuild()
func _rebuild()->void:show_page(page_index)
func _add_pager(name:String,caption:String,x:float,step:int)->void:
	var button:Node3D=BUTTON.instantiate();button.name=name
	# The button scene already orients its local press axis toward +Z.
	button.position=Vector3(x,-.195,.004);station.add_child(button)
	button.pressed.connect(func():show_page(posmod(page_index+step,pages.size())))
	_print(station,caption,Vector2(.18,.025),Vector3(x,-.251,.003))
func _has_held_control()->bool:
	if not is_instance_valid(active_page):return false
	for node in active_page.find_children("*","Node3D",true,false):
		if node is XRToolsPickable and node.is_picked_up():return true
		if is_instance_valid(node.get("_pointer")) or node.get("_pointer_dragging")==true:return true
	return false
func show_page(index:int)->bool:
	if _changing or pages.is_empty() or _has_held_control():return false
	_changing=true
	if is_instance_valid(active_page):station.remove_child(active_page);active_page.queue_free()
	controls.clear();_mirrors.clear()
	page_index=posmod(index,pages.size())
	active_page=Node3D.new();active_page.name="ActivePage";station.add_child(active_page)
	var page:Dictionary=pages[page_index]
	for i in page.items.size():
		var entry:Array=page.items[i]
		var control:Node3D=entry[0].instantiate()
		control.position=Vector3((i-(page.items.size()-1)*.5)*page.gap,.025,.004)
		active_page.add_child(control);controls.append(control)
		_print(active_page,entry[1],Vector2(minf(page.gap-.025,.29),.026),Vector3(control.position.x,.216,.003))
		if not Engine.is_editor_hint() and control.has_method("set_param_name"):control.set_param_name("")
		_flatten_labels(control)
	_heading.label.text="%02d / %02d  %s\nPages load fresh controls. R: reset page." % [page_index+1,pages.size(),page.title]
	_heading.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
	_changing=false
	return true
func _flatten_labels(control:Node3D)->void:
	# Keep legacy source nodes for scripts with typed Label3D references, but expose
	# their current words on a backed flat card. No camera-facing glyphs remain visible.
	var sources:Array[Label3D]=[]
	for label in control.find_children("*","Label3D",true,false):
		if label.visible and not label.text.strip_edges().is_empty():sources.append(label)
		label.hide()
	if sources.is_empty():return
	var card:=ValueSurface.build(active_page,Vector2(.19,.036),Vector3(control.position.x,-.126,.004))
	card.label.add_theme_font_size_override("font_size",28)
	_mirrors.append({"control":control,"sources":sources,"card":card})
	_refresh_labels()
func _process(delta:float)->void:
	_refresh_time+=delta
	if _refresh_time<.1:return
	_refresh_time=0
	_refresh_labels()
func _refresh_labels()->void:
	for entry in _mirrors:
		var texts:PackedStringArray=[]
		for source in entry.sources:
			if is_instance_valid(source):texts.append(source.text)
		var words: String=" / ".join(texts)
		if entry.card.label.text!=words:
			entry.card.label.text=words
			entry.card.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE
func _print(parent:Node3D,words:String,size:Vector2,at:Vector3)->void:
	var mesh:=BakedText.make_label_mesh(words,Color(.84,.92,.87),size,2200,true)
	mesh.position=at;parent.add_child(mesh)
func _box(parent:Node3D,label:String,size:Vector3,at:Vector3,color:Color)->void:
	var mesh:=MeshInstance3D.new();mesh.name=label;mesh.mesh=BoxMesh.new();mesh.mesh.size=size;mesh.position=at
	var mat:=StandardMaterial3D.new();mat.albedo_color=color;mat.roughness=.75;mesh.material_override=mat;parent.add_child(mesh)
