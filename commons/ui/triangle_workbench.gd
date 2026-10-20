extends Node3D
## Reachable museum actions. Uses the drawing's real point/loop operations.
const Style = preload("res://commons/primitives/line/museum_line_style.gd")
var subject: Node3D
var puzzle := false
var status: Label3D
var buttons: Dictionary = {}
var tubes: MultiMeshInstance3D
var preview: MeshInstance3D
var _clock := 0.0
var _signature := 0
var _face_material := Style.face()

func _ready() -> void:
	# The source mesh already emits a front and a back triangle. Cull their
	# hidden sides so translucent coplanar faces cannot fight over depth.
	_face_material.cull_mode=BaseMaterial3D.CULL_BACK
	subject=get_parent();puzzle=subject.has_method("toggle_discovery_face")
	var board := MeshInstance3D.new();board.name="ActionBoard"
	var box:=BoxMesh.new();box.size=Vector3(1.18,0.64,0.045)
	board.mesh=box;board.material_override=Style.white()
	board.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF;add_child(board)
	status=_label("Status","",Vector3(0,0.23,0.029),0.0009)
	if puzzle:
		_button("fill","SHOW / HIDE FACE",Vector2(-0.27,-0.06),subject.toggle_discovery_face)
		_button("reset","RESET EDGES",Vector2(0.27,-0.06),subject.reset_puzzle)
	else:
		_button("place","PLACE POINT",Vector2(-0.36,0.055),subject.place_current_corner)
		_button("close","CLOSE FACE",Vector2(0,0.055),subject.close_current_face)
		_button("new","NEW FACE",Vector2(0.36,0.055),subject.begin_new_outline)
		_button("undo","UNDO POINT",Vector2(-0.405,-0.18),subject.undo_outline_step)
		_button("fill","SHOW / HIDE FILL",Vector2(-0.135,-0.18),subject.toggle_fill_visibility)
		_button("shift","SHIFT START",Vector2(0.135,-0.18),subject.shift_start)
		_button("reset","RESTORE",Vector2(0.405,-0.18),_restore)
		tubes=MultiMeshInstance3D.new();tubes.name="PinkEdges"
		tubes.multimesh=MultiMesh.new();tubes.multimesh.transform_format=MultiMesh.TRANSFORM_3D
		var tube:=CylinderMesh.new();tube.height=1;tube.top_radius=0.009;tube.bottom_radius=0.009;tube.radial_segments=16
		tubes.multimesh.mesh=tube;tubes.material_override=Style.pink()
		tubes.top_level=true;add_child(tubes);tubes.global_transform=Transform3D.IDENTITY
		preview=MeshInstance3D.new();preview.name="NextEdge";preview.mesh=tube
		preview.material_override=Style.pink();preview.top_level=true;add_child(preview)
	update_view()

func _label(id: String, words: String, at: Vector3, pixel: float) -> Label3D:
	var label:=Label3D.new();label.name=id;label.text=words
	label.font_size=24;label.pixel_size=pixel;label.modulate=Color("25282d")
	label.outline_size=0;label.position=at;add_child(label)
	return label

func _button(id: String, caption: String, at: Vector2, action: Callable) -> void:
	var button: Node3D=preload("res://commons/interactables/push_button.tscn").instantiate()
	button.name=id.capitalize()+"Button";button.position=Vector3(at.x,at.y,0.04)
	button.released_color=Style.PINK;button.selected_color=Style.PINK
	button.pressed.connect(func(): action.call();update_view())
	add_child(button);buttons[id]=button
	_label(id+"Caption",caption,Vector3(at.x,at.y-0.081,0.029),0.00068)

func _restore() -> void:
	if subject._is_grabbed or not subject._editing_points.is_empty():return
	for node in get_tree().get_nodes_in_group("triangle_live_twins"):
		if node.source==subject:node.restore_reference();return
	subject.clear_all()

func _process(delta: float) -> void:
	_clock+=delta
	if _clock<0.04:return
	_clock=0;update_view()

func update_view() -> void:
	if puzzle:
		status.text="THREE EDGES / ONE BOUNDARY\n"+("Closed. The face is another choice." if subject.is_completed else "Carry each white end to a corner. Release to snap.")
		return
	var entries:int=subject.current_path.size()
	var count:int=0
	for face in subject.completed_triangles:count+=maxi(0,face.points.size()-2)
	status.text="%d POINTS / %d %s\nHold the drawing point. Trigger: place. CLOSE FACE: join the start."%[subject.placed_points.size(),count,"FACE" if count==1 else "FACES"]
	var loops:Array=[]
	for face in subject.completed_triangles:loops.append(face.points)
	var key:=hash([subject.placed_points,loops,subject.current_path,subject.fills_visible])
	if key!=_signature:
		_signature=key
		var pairs:Dictionary={}
		for face in subject.completed_triangles:
			face.mesh.material_override=_face_material
			# The Void comparison shows the same face at both scales. Older
			# boundary-only instruments retain their original presentation.
			face.mesh.visible=subject.fills_visible and bool(subject.get_meta("config_show_local_fill",false))
			for i in range(1,face.points.size()-1):
				var tri:Array=[face.points[0],face.points[i],face.points[i+1]]
				for j in 3:_pair(pairs,tri[j],tri[(j+1)%3])
		for i in range(entries-1):_pair(pairs,subject.current_path[i],subject.current_path[i+1])
		tubes.multimesh.instance_count=pairs.size()
		var i:=0
		for pair in pairs.values():
			tubes.multimesh.set_instance_transform(i,segment(subject.placed_points[pair[0]],subject.placed_points[pair[1]]));i+=1
	subject.line_instance.visible=false;subject.active_line_instance.visible=false
	preview.visible=subject._is_grabbed and not subject.current_path.is_empty()
	if preview.visible:
		var tip:Vector3=subject.snap_position_to_grid(subject._draw_sphere.global_position)
		if subject.snap_target_index>=0:tip=subject.placed_points[subject.snap_target_index]
		preview.global_transform=segment(subject.placed_points[subject.current_path[-1]],tip)

func _pair(pairs: Dictionary, a: int, b: int) -> void:
	if a!=b:pairs[str(mini(a,b))+":"+str(maxi(a,b))]=[a,b]

static func segment(a: Vector3, b: Vector3) -> Transform3D:
	var length:=a.distance_to(b)
	if length<0.00001:return Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),a)
	return Transform3D(Basis(Quaternion(Vector3.UP,(b-a)/length))*Basis.from_scale(Vector3(1,length,1)),(a+b)*0.5)
