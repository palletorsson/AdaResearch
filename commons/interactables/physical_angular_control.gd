extends Node3D
const BakedText=preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface=preload("res://commons/ui/control_value_surface.gd")
const POINTER_LAYERS: int=(1<<20)|(1<<22)
@export var hinge_path:NodePath=NodePath("HingeOrigin/InteractableHinge")
@export_enum("wheel","lever") var kind: String="wheel"
@export var caption: String = ""
signal hinge_moved(angle:float)
var hinge:Node3D
var _reading:Dictionary={}
var _caption:MeshInstance3D
var _pointer:Node3D
var _previous:Vector3
var _pointer_angle:=0.0
var _mapped:=false
var _range:=Vector2.ZERO
var _unit:="°"

func _ready()->void:
	set_process(false)
	hinge=get_node(hinge_path)
	for node in find_children("*","CollisionObject3D",true,false):
		node.collision_layer|=POINTER_LAYERS
		if node is XRToolsPickable:
			node.original_collision_layer=node.collision_layer
	hinge.hinge_moved.connect(_on_moved)
	hinge.grabbed.connect(func(_node): _cancel_pointer(false))
	var material:=StandardMaterial3D.new()
	material.albedo_color=Color(.82,.84,.77)
	material.roughness=.7
	get_node("Frame/MeshInstance3D").material_override=material
	_caption=BakedText.make_label_mesh(kind.to_upper(),Color(.08,.10,.12),Vector2(.155,.024),2200,true)
	_caption.position=Vector3(0,.103,.012)
	add_child(_caption)
	if not caption.is_empty(): set_caption(caption)
	_reading=ValueSurface.build(self,Vector2(.158,.032),Vector3(0,-.093,.012))
	_reading.label.add_theme_font_size_override("font_size",40)
	_build_direction_marks()
	_on_moved(hinge.hinge_position)

func set_caption(text:String)->void:
	var printed:=BakedText.make_label_mesh(text,Color(.08,.10,.12),Vector2(.155,.024),2200,true)
	_caption.material_override=printed.material_override
	printed.free()

func set_display_range(low:float,high:float,unit:String)->void:
	_mapped=true
	_range=Vector2(low,high)
	_unit=unit
	_update_reading()

func set_readout_visible(shown:bool)->void:
	if not _reading.is_empty(): _reading.screen.visible=shown

func get_angle_degrees()->float: return hinge.hinge_position
func set_angle_degrees(angle:float)->void:
	hinge.move_hinge(deg_to_rad(angle))
	_update_reading()

func _on_moved(angle:float)->void:
	_update_reading()
	hinge_moved.emit(angle)

func _update_reading()->void:
	if _reading.is_empty(): return
	var value:float=hinge.hinge_position
	if _mapped:
		value=remap(value,hinge.hinge_limit_min,hinge.hinge_limit_max,_range.x,_range.y)
	var text:="%+.0f%s" % [value,_unit]
	if _reading.label.text!=text:
		_reading.label.text=text
		_reading.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func pointer_event(event:XRToolsPointerEvent)->void:
	if not event or not is_instance_valid(event.pointer) or not hinge.grabbed_handles.is_empty(): return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if is_instance_valid(_pointer):return
			_pointer=event.pointer
			_previous=to_local(event.position)
			_pointer_angle=hinge.hinge_position
			set_process(true)
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer!=_pointer:return
			var at:=to_local(event.position)
			if kind=="wheel":
				# Ignore the centre, where angular direction is undefined.
				if Vector2(at.x,at.y).length()>.015 and Vector2(_previous.x,_previous.y).length()>.015:
					_pointer_angle+=rad_to_deg(wrapf(atan2(at.y,at.x)-atan2(_previous.y,_previous.x),-PI,PI))
			else:
				_pointer_angle-=(at.y-_previous.y)*450.0
			set_angle_degrees(_pointer_angle)
			# Keep fractional motion between detents; only discard overshoot at stops.
			_pointer_angle=clampf(_pointer_angle,hinge.hinge_limit_min,hinge.hinge_limit_max)
			_previous=at
		XRToolsPointerEvent.Type.RELEASED,XRToolsPointerEvent.Type.EXITED:
			if event.pointer==_pointer:_cancel_pointer(true)

func _process(_delta:float)->void:
	if not is_instance_valid(_pointer):_cancel_pointer(true)
func _notification(what:int)->void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(_pointer):_cancel_pointer(true)
func _cancel_pointer(apply_release:bool)->void:
	_pointer=null
	set_process(false)
	if apply_release and hinge.default_on_release:set_angle_degrees(hinge.default_position)

func _build_direction_marks()->void:
	var ink:=StandardMaterial3D.new()
	ink.albedo_color=Color(.20,.25,.25)
	ink.roughness=.8
	if kind=="wheel":
		for i in 12:
			var angle:float=i*TAU/12
			var tick:=MeshInstance3D.new()
			tick.name="DirectionTick%d" % i
			tick.mesh=BoxMesh.new()
			tick.mesh.size=Vector3(.002,.007,.001)
			tick.position=Vector3(-sin(angle)*.073,cos(angle)*.073,.0107)
			tick.rotation.z=angle
			tick.material_override=ink
			add_child(tick)
		# A single index distinguishes the wheel's orientation from its four grips.
		var index:=MeshInstance3D.new()
		index.name="WheelIndex"
		index.mesh=BoxMesh.new()
		index.mesh.size=Vector3(.002,.005,.031)
		index.position=Vector3(.008,0,-.024)
		var paint:=StandardMaterial3D.new()
		paint.albedo_color=Color(.95,.55,.15)
		paint.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		index.material_override=paint
		hinge.add_child(index)
	else:
		# Recessed-looking travel strip and centre marker stay on the mounting plate.
		var strip:=MeshInstance3D.new()
		strip.mesh=BoxMesh.new()
		strip.mesh.size=Vector3(.012,.135,.001)
		strip.position.z=.0107
		strip.material_override=ink
		add_child(strip)
		for y in [-.06,0,.06]:
			var tick:=MeshInstance3D.new()
			tick.mesh=BoxMesh.new()
			tick.mesh.size=Vector3(.033,.002,.001)
			tick.position=Vector3(.033,y,.0107)
			tick.material_override=ink
			add_child(tick)
