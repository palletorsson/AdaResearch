extends Node3D
## Flat XY face, physical handle. The child retains its historical Y/Z metre API;
## SliderOrigin maps those two coordinates onto the face's X/Y directions.
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")
const ValueSurface = preload("res://commons/ui/control_value_surface.gd")
const POINTER_LAYERS := (1 << 20) | (1 << 22)
signal slider_moved(value: Vector2)
var _slider: Node3D
var _handle: Node3D
var _reading: Dictionary = {}
var _title: MeshInstance3D
var _pointer: Node3D
var _start: Vector3
var _start_value: Vector2
var _display_span := 1.0

func _ready() -> void:
	set_process(false)
	_slider=get_node("SliderOrigin/InteractableSlider")
	_handle=_slider.get_node("HandleOrigin/InteractableHandle")
	for body in [get_node("Frame"),_slider.get_node("SliderBody"),_handle]:
		body.collision_layer |= POINTER_LAYERS
	var face:=StandardMaterial3D.new()
	face.albedo_color=Color(.82,.84,.77)
	face.roughness=.7
	get_node("Frame/BaseMesh").material_override=face
	_build_grid()
	_slider.slider_moved.connect(_on_moved)
	_slider.grabbed.connect(func(_node): _cancel_pointer(false))
	_title=BakedText.make_label_mesh("XY · POSITION",Color(.08,.10,.12),Vector2(.19,.024),2200,true)
	_title.position=Vector3(0,.113,.012)
	add_child(_title)
	_reading=ValueSurface.build(self,Vector2(.196,.036),Vector3(0,-.117,.012))
	_reading.viewport.size=Vector2i(440,85)
	_reading.viewport.get_child(0).size=Vector2(440,85)
	_reading.label.size=Vector2(440,85)
	_reading.label.add_theme_font_size_override("font_size",34)
	_refresh_reading()

func set_travel_limits(half_extent: Vector2) -> void:
	_slider.limit_y_min=-clampf(absf(half_extent.x),.001,.07)
	_slider.limit_y_max=-_slider.limit_y_min
	_slider.limit_z_min=-clampf(absf(half_extent.y),.001,.07)
	_slider.limit_z_max=-_slider.limit_z_min
	_slider.move_slider(_slider.slider_position)
	_refresh_reading()

func set_normalized_position(value: Vector2) -> void:
	_slider.move_slider(Vector2(lerpf(_slider.limit_y_min,_slider.limit_y_max,(clampf(value.x,-1,1)+1)*.5),lerpf(_slider.limit_z_min,_slider.limit_z_max,(clampf(value.y,-1,1)+1)*.5)))
	_refresh_reading()

func get_normalized_position() -> Vector2:
	return Vector2(remap(_slider.slider_position.x,_slider.limit_y_min,_slider.limit_y_max,-1,1),remap(_slider.slider_position.y,_slider.limit_z_min,_slider.limit_z_max,-1,1))

func set_value_mapping(title: String, span: float) -> void:
	_display_span=span
	var printed:=BakedText.make_label_mesh(title,Color(.08,.10,.12),Vector2(.19,.024),2200,true)
	_title.material_override=printed.material_override
	printed.free()
	_refresh_reading()

func _on_moved(value: Vector2) -> void:
	_refresh_reading()
	slider_moved.emit(value)

func _refresh_reading() -> void:
	if _reading.is_empty(): return
	var value:=get_normalized_position()*_display_span
	var text:="X %+.2f   Y %+.2f" % [value.x,value.y]
	if _reading.label.text!=text:
		_reading.label.text=text
		_reading.viewport.render_target_update_mode=SubViewport.UPDATE_ONCE

func pointer_event(event: XRToolsPointerEvent) -> void:
	if not event or not is_instance_valid(event.pointer) or not _slider.grabbed_handles.is_empty(): return
	match event.event_type:
		XRToolsPointerEvent.Type.PRESSED:
			if is_instance_valid(_pointer): return
			_pointer=event.pointer
			_start=to_local(event.position)
			_start_value=_slider.slider_position
			set_process(true)
		XRToolsPointerEvent.Type.MOVED:
			if event.pointer==_pointer:
				var offset:=to_local(event.position)-_start
				_slider.move_slider(_start_value+Vector2(offset.x,offset.y))
		XRToolsPointerEvent.Type.RELEASED,XRToolsPointerEvent.Type.EXITED:
			if event.pointer==_pointer: _cancel_pointer(true)

func _process(_delta:float) -> void:
	if not is_instance_valid(_pointer): _cancel_pointer(true)

func _notification(what:int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(_pointer): _cancel_pointer(true)

func _cancel_pointer(apply_release:bool) -> void:
	_pointer=null
	set_process(false)
	if apply_release and _slider.default_on_release: _slider.move_slider(_slider.default_position)

func _build_grid() -> void:
	var grid:=MeshInstance3D.new()
	grid.name="CoordinateGrid"
	var mesh:=ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in range(-2,3):
		var v:=i*.035
		mesh.surface_add_vertex(Vector3(-.07,v,.014))
		mesh.surface_add_vertex(Vector3(.07,v,.014))
		mesh.surface_add_vertex(Vector3(v,-.07,.014))
		mesh.surface_add_vertex(Vector3(v,.07,.014))
	mesh.surface_end()
	grid.mesh=mesh
	var mat:=StandardMaterial3D.new()
	mat.albedo_color=Color(.45,.51,.52)
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	grid.material_override=mat
	add_child(grid)
