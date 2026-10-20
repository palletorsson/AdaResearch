extends Node3D
## Four saved arrangements side by side, on the existing two tables.
const Kit=preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const Console=preload("res://commons/ui/control_console.gd")
const Rack=preload("res://commons/audio/rack_templates/RackTemplates.gd")
var bench: Node3D
var models: Node3D
var controls: Node3D
var buttons: Dictionary={}
var labels: Array[Label3D]=[]
var slots: Array[Dictionary]=[]
var page:=0
var page_size:=4
var status: Label3D

func setup(host: Node3D) -> void:
	bench=host
	models=Node3D.new();add_child(models)
	for i in page_size:
		var x: float=(i-1.5)*1.1
		add_child(Kit.box(Vector3(x,1.017,-0.12),Vector3(1.02,0.014,0.82),Kit.rams_body(Color("263740"),0)))
		labels.append(plate("",Vector3(x,1.10,0.39),Vector2(1.04,0.19),20))
	status=plate("",Vector3(0,1.83,-0.80),Vector2(4.28,0.22),27)
	plate("Each entry keeps all four forms / choose a number to replay",Vector3(0,1.66,-0.80),Vector2(4.28,0.13),23)
	controls=Console.new();controls.auto_demo=false;controls.body_height=0.64
	controls.board_width=1.5;controls.mounting="lectern";controls.position=Vector3(0,0,1.37)
	add_child(controls);controls.set_title("KEPT GALLERY / REPLAY AN ENTRY")
	controls.panel().layout_columns=4
	for i in page_size:
		var key: String="REPLAY "+str(i+1)
		buttons[key]=controls.add_button(key);Rack.make_button_rectangular(buttons[key])
		buttons[key].pressed.connect(replay_slot.bind(i))
	for key in ["PREVIOUS","NEXT","BACK"]:
		buttons[key]=controls.add_button(key);Rack.make_button_rectangular(buttons[key])
		buttons[key].pressed.connect(act.bind(key))

func plate(text: String, at: Vector3, size: Vector2, font_size: int) -> Label3D:
	var label: Label3D=bench.plate(text,at,size,font_size)
	var backing:=label.get_parent();bench.remove_child(backing);add_child(backing)
	return label

func refresh() -> void:
	bench.gallery_store.bind(bench.pointer_path)
	if bench.gallery_store.writable and FileAccess.file_exists(bench.gallery_store.index_path): bench.gallery_store.load_index()
	var count: int=bench.gallery_store.paths.size()
	page=clampi(page,0,maxi(0,(count-1)/page_size))
	for child in models.get_children(): models.remove_child(child);child.queue_free()
	slots.clear()
	for i in page_size:
		var index:=page*page_size+i
		if index>=count:
			labels[i].text="%d / EMPTY\nKEEP another arrangement" % (i+1)
			slots.append({"path":"","valid":false});continue
		var path: String=bench.gallery_store.paths[index]
		var record=bench.gallery_store.read_json(path)
		if not bench.valid_record(record):
			labels[i].text="%d / UNAVAILABLE\nSaved file retained" % (i+1)
			slots.append({"path":path,"valid":false});continue
		var amount: float=float(record.disorder)*(0.5 if record.schema=="prefab-disorder/1" else 1.0)
		labels[i].text="%d / SEED %s\nSTAGE %.2f" % [i+1,record.seed,amount]
		var poses: Array[Transform3D]=bench.poses_for_record(record)
		var bounds: AABB=poses[0]*bench.pieces[0].bounds
		for p in poses.size(): bounds=bounds.merge(poses[p]*bench.pieces[p].bounds)
		var factor:=minf(0.90/maxf(bounds.size.x,0.001),minf(0.65/maxf(bounds.size.z,0.001),0.53/maxf(bounds.size.y,0.001)))
		var origin:=Vector3((i-1.5)*1.1,1.03,-0.12)
		var shift:=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)*factor
		var fit:=Transform3D(Basis.from_scale(Vector3.ONE*factor),origin+shift)
		var views: Array[MeshInstance3D]=[]
		for p in poses.size():
			var part: Dictionary=bench.pieces[p]
			var view:=MeshInstance3D.new();view.mesh=part.mesh;view.material_override=part.material;view.material_overlay=part.overlay
			view.transform=fit*poses[p];models.add_child(view);views.append(view)
		# Keep the exact source poses available to verification; display fitting is separate.
		slots.append({"path":path,"valid":true,"poses":poses,"fit":fit,"views":views,"seed":record.seed,"amount":amount})
	status.text="KEPT GALLERY / %d entries / page %d of %d" % [count,page+1,maxi(1,ceili(count/float(page_size)))]
	if not bench.gallery_store.error.is_empty(): status.text=bench.gallery_store.error

func replay_slot(slot: int) -> bool:
	if slot<0 or slot>=slots.size() or not slots[slot].valid: return false
	if not bench.replay_path(slots[slot].path): return false
	bench.gallery_selected_path=slots[slot].path
	bench.show_gallery(false)
	return true

func act(key: String) -> void:
	match key:
		"PREVIOUS": page=maxi(0,page-1);refresh();bench.changed.emit()
		"NEXT": page+=1;refresh();bench.changed.emit()
		"BACK": bench.show_gallery(false)
