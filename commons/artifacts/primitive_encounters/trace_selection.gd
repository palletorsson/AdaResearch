extends Node3D
## Select by archive identity + source index. Snapped duplicate positions retain identity.
const Target = preload("res://commons/artifacts/primitive_encounters/selection_target.gd")
const G = preload("res://commons/artifacts/primitive_encounters/geometry.gd")
const Text = preload("res://commons/utils/baked_text_albedo.gd")
var grid: Node3D
var trace_id := -1
var point_index := 0
var page := 0
var _newest := -1
var _elapsed := 0.0
var _signature := ""
var markers: Node3D
var targets: Node3D
var row_targets: Node3D
var selected_source := Vector3.ZERO
var selected_snapped := Vector3.ZERO
func _ready() -> void:
	grid=get_parent();grid.set_archive_auto(false)
	markers=Node3D.new();markers.name="SelectionMarkers";add_child(markers)
	targets=Node3D.new();targets.name="PointTargets";add_child(targets)
	row_targets=Node3D.new();row_targets.name="RowTargets";grid._data_panel.add_child(row_targets)
	var trace_button:Node3D=grid._page_buttons[1]
	for c in trace_button.pressed.get_connections():trace_button.pressed.disconnect(c.callable)
	trace_button.pressed.connect(next_trace)
	# Cover the old AUTO caption with an explicit trace-selector label.
	G.box(grid._data_panel,"TraceCaptionBack",Vector3(0,-.55,.009),Vector3(.17,.04,.01),Color("222a30"),false)
	var caption=Text.make_label_mesh("NEXT TRACE",Color.WHITE,Vector2(.15,.028),2200,true)
	caption.position=Vector3(0,-.55,.018);grid._data_panel.add_child(caption)
	for i in 2:
		var button=load("res://commons/interactables/push_button.tscn").instantiate()
		button.name="PreviousPoint" if i==0 else "NextPoint"
		button.position=Vector3(-.20 if i==0 else .20,-.69,.005)
		grid._data_panel.add_child(button)
		button.pressed.connect(step_point.bind(-1 if i==0 else 1))
		var label=Text.make_label_mesh("POINT −" if i==0 else "POINT +",Color.WHITE,Vector2(.17,.03),2200,true)
		label.position=button.position+Vector3(0,-.07,0);grid._data_panel.add_child(label)
	G.box(grid._data_panel,"PointStrip",Vector3(0,-.70,-.035),Vector3(.70,.22,.045),Color("222a30"),false)
	refresh()
func record() -> Dictionary:
	for item in grid._trace_data_list:
		if item.id==trace_id:return item
	return {}
func _process(delta:float) -> void:
	_elapsed+=delta
	if _elapsed<.12:return
	_elapsed=0
	if not grid._trace_data_list.is_empty() and grid._trace_data_list[-1].id!=_newest:
		_newest=grid._trace_data_list[-1].id;trace_id=_newest;point_index=0;page=0
	refresh()
func next_trace() -> void:
	var data:Array=grid._trace_data_list
	if data.is_empty():return
	var i:=0
	for j in data.size():
		if data[j].id==trace_id:i=j
	trace_id=data[(i+1)%data.size()].id;point_index=0;page=0;refresh()
func select_point(index:int) -> void:
	var data:=record()
	if data.is_empty():return
	point_index=clampi(index,0,data.raw_points.size()-1)
	page=point_index/10;refresh()
func step_point(direction:int) -> void:
	var data:=record()
	if data.is_empty():return
	select_point(posmod(point_index+direction,data.raw_points.size()))
func step_page(direction:int) -> void:
	var data:=record()
	if data.is_empty():return
	page=posmod(page+direction,maxi(1,ceili(data.raw_points.size()/10.0)));refresh()
func _clear(node:Node) -> void:
	for child in node.get_children():node.remove_child(child);child.queue_free()
func _target(parent:Node3D,at:Vector3,size:Vector3,action:Callable) -> Node3D:
	var target:=Target.new();target.action=action;target.position=at
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=size
	collision.shape=shape;target.add_child(collision);parent.add_child(target);return target
func _dot(parent:Node3D,at:Vector3,colour:Color,radius:float) -> void:
	var mesh:=MeshInstance3D.new();var sphere:=SphereMesh.new();sphere.radius=radius;sphere.height=radius*2
	mesh.mesh=sphere;mesh.position=at;mesh.material_override=G.material(colour);parent.add_child(mesh)
func _line(a:Vector3,b:Vector3,colour:Color) -> void:
	if a.distance_to(b)<.001:return
	var mesh:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
	cylinder.top_radius=.008;cylinder.bottom_radius=.008;cylinder.height=a.distance_to(b)
	mesh.mesh=cylinder;mesh.material_override=G.material(colour);mesh.position=(a+b)/2
	mesh.quaternion=Quaternion(Vector3.UP,(b-a).normalized());markers.add_child(mesh)
func refresh() -> void:
	var data:=record()
	if data.is_empty():return
	var key:=str([trace_id,point_index,page,data.visual.global_transform])
	if key==_signature:return
	_signature=key
	_clear(markers);_clear(targets);_clear(row_targets)
	var points:Array=data.raw_points
	var frame:Dictionary=grid._display_frame(points)
	var visual:Node3D=data.visual
	if not is_instance_valid(visual):return
	var local:Vector3=(points[point_index]-frame.center)*frame.scale
	var snapped:Vector3=local.snapped(Vector3.ONE*grid.cell_spacing/maxi(1,grid.shadow_snap_subdivisions))
	selected_source=visual.to_global(local);selected_snapped=visual.to_global(snapped)
	var a:=to_local(selected_source);var b:=to_local(selected_snapped)
	_dot(markers,a,Color("f269b7"),.055);_dot(markers,b,Color("62dda8"),.040);_line(a,b,Color("e8c65c"))
	for j in [point_index-1,point_index+1]:
		if j>=0 and j<points.size():_line(a,to_local(visual.to_global((points[j]-frame.center)*frame.scale)),Color("d953a0"))
	var label:=G.label(markers,"%d"%(point_index+1),a+Vector3.UP*.11,32);label.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	grid._data_panel.heading.text="TRACE %d · POINT %d"%[trace_id+1,point_index+1]
	var text:="SOURCE (m)  →  DISPLAY (m)\n"
	text+="Pink %.2f %.2f %.2f\n"%[local.x,local.y,local.z]
	text+="Green %.2f %.2f %.2f\n"%[snapped.x,snapped.y,snapped.z]
	text+="SOURCE ROWS · page %d/%d\n"%[page+1,ceili(points.size()/10.0)]
	for i in range(page*10,mini(page*10+10,points.size())):
		var p:Vector3=points[i]
		text+="%s %4d  %.3f %.3f %.3f\n"%[">" if i==point_index else " ",i+1,p.x,p.y,p.z]
		var at:=to_local(visual.to_global((p-frame.center)*frame.scale))
		_dot(targets,at,Color("bdb2bc"),.016)
		_target(targets,at,Vector3.ONE*.12,select_point.bind(i))
	grid._data_table_label.text=text;grid._data_table_label.visible=true;grid._data_panel.visible=true
	grid._data_panel.refresh()
	var table:Label=grid._data_table_label
	var font:=table.get_theme_font("font");var pixels:=table.get_theme_font_size("font_size")
	var line_h:float=ceilf(font.get_height(pixels))+table.get_theme_constant("line_spacing")
	for i in range(page*10,mini(page*10+10,points.size())):
		var y:float=table.position.y+(4+i-page*10+.5)*line_h
		_target(row_targets,Vector3(0,grid._data_panel.size_m.y/2-y/1000,.025),Vector3(.82,line_h/1000,.018),select_point.bind(i))
