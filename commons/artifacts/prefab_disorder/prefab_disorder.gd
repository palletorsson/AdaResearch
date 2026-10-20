extends Node3D
## The same inventory at two scales: assembled objects and authored mesh parts.
signal changed
const Sample=preload("disorder_sample.gd")
const Hybrid=preload("hybrid_recipe.gd")
const Seeded=preload("seeded_grafts.gd")
const GalleryStore=preload("gallery_store.gd")
const KeptGallery=preload("kept_gallery.gd")
const GhostStudent=preload("ghost_student.gd")
const PartWitness=preload("part_witness.gd")
const BoundedButterflies=preload("bounded_butterflies.gd")
const Console=preload("res://commons/ui/control_console.gd")
const Kit=preload("res://commons/artifacts/_hangar/hangar_kit.gd")
const Rack=preload("res://commons/audio/rack_templates/RackTemplates.gd")
const SOURCES=["cardboard_box","computer_monitor","lab_stool","microscope"]
const TITLES=["CARDBOARD BOX","CRT MONITOR","LAB STOOL","MICROSCOPE"]
const SHORT_TITLES=["BOX","CRT","STOOL","SCOPE"]
const SCHEMA="prefab-disorder/2"
const SIDE=1.18
const DECK_Y=1.02
@export_range(0,1) var disorder: float=0.0
@export var experiment_seed: int=435
@export_range(0,32,1) var butterfly_count: int=0
var butterflies: Node3D
var sample=Sample.new()
var inventory: Array[Dictionary]=[]
var pieces: Array[Dictionary]=[]
var hybrids: Array[Dictionary]=[]
var recipe_version: String=Seeded.VERSION
var gallery_store=GalleryStore.new()
var gallery: Node3D
var gallery_open:=false
var gallery_selected_path: String=""
var experiment_decor: Array[Node3D]=[]
var console: Node3D
var captions: Array[Label3D]=[]
var signature: String
var slider: Node3D
var buttons: Dictionary={}
var readout: Label3D
var saved_path: String=""
var pointer_path="user://prefab-disorder-latest.json"
var note="0 original objects / 0.5 separated parts / 1 hybrids. Slide either way."
var ready_for_controls:=false
var ghost: Node3D
var witness: Node3D

func _ready() -> void:
	build_inventory()
	hybrids=Seeded.new().build(pieces,inventory,SIDE,experiment_seed)
	build_display()
	sample.seed_draws(experiment_seed,24+pieces.size()*6)
	ready_for_controls=true
	set_disorder(disorder)
	gallery=KeptGallery.new();add_child(gallery);gallery.setup(self)
	set_active(gallery,false)
	witness=PartWitness.new();add_child(witness);witness.setup(self)
	ghost=GhostStudent.new();ghost.name="GhostStudent";add_child(ghost);ghost.setup(self)
	configure_butterflies()
	call_deferred("update_visibility")

func apply_grid_config(config: Dictionary) -> void:
	if config.has("butterflies"):
		butterfly_count=clampi(int(config.butterflies),0,32)
		if is_node_ready(): configure_butterflies()

func configure_butterflies() -> void:
	if is_instance_valid(butterflies) and butterflies.count==butterfly_count: return
	if is_instance_valid(butterflies):
		remove_child(butterflies);butterflies.queue_free();butterflies=null
	if butterfly_count>0:
		butterflies=BoundedButterflies.new();butterflies.name="LocalButterflies"
		butterflies.count=butterfly_count;add_child(butterflies)
		set_active(butterflies,not gallery_open)

func build_inventory() -> void:
	var fingerprints: Array[String]=[]
	for id in SOURCES:
		var path: String="res://commons/artifacts/%s/%s.tscn" % [id,id]
		var source: Node3D=load(path).instantiate()
		add_child(source)
		var raw: Array[Dictionary]=[]
		collect(source,source,raw)
		assert(not raw.is_empty(),"Prefab must contain visible MeshInstance3D parts: "+id)
		var bounds: AABB=raw[0].home*raw[0].bounds
		for part in raw: bounds=bounds.merge(part.home*part.bounds)
		var factor: float=0.44/maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
		var offset:=Vector3(-bounds.get_center().x,-bounds.position.y,-bounds.get_center().z)*factor
		var normalise:=Transform3D(Basis.from_scale(Vector3.ONE*factor),offset)
		var item_index:=inventory.size()
		var grid:=Vector3((item_index%2-0.5)*0.94,DECK_Y,(item_index/2-0.5)*0.83-0.10)
		inventory.append({"id":id,"bounds":normalise*bounds,"grid":grid,"parts":raw.size(),"factor":factor})
		for part in raw:
			part.home=normalise*part.home
			part.item=item_index
			part.draw=24+pieces.size()*6
			part.views=[]
			pieces.append(part)
		fingerprints.append(FileAccess.get_sha256(path))
		fingerprints.append(FileAccess.get_sha256(source.get_script().resource_path))
		for part in raw: fingerprints.append(str(part.key)+str(part.home)+str(part.bounds))
		remove_child(source);source.free()
	signature="|".join(fingerprints).sha256_text()

func collect(node: Node, source: Node3D, result: Array[Dictionary]) -> void:
	if node is MeshInstance3D and node.mesh!=null and node.is_visible_in_tree():
		# Traversal indices are stable across instances; auto-generated node names are not.
		result.append({"key":str(result.size()),"label":str(node.name),"mesh":node.mesh,"material":node.material_override,
			"overlay":node.material_overlay,"home":source.global_transform.affine_inverse()*node.global_transform,"bounds":node.mesh.get_aabb()})
	for child in node.get_children(): collect(child,source,result)

func build_display() -> void:
	var palette:=Kit.finish_palette("rams")
	var housing:=Kit.finish_body("rams",palette.body,0.10)
	var dark:=Kit.rams_body(Color("263740"),0.02)
	for x in [-2.14,2.14]:
		add_child(Kit.box(Vector3(x,1.58,-0.84),Vector3(0.055,1.18,0.055),housing))
	for side in [-1,1]:
		var at:=Vector3(side*SIDE,0.93,0)
		add_child(Kit.box(at,Vector3(2.16,0.14,1.80),housing))
		add_child(Kit.box_collider(Vector3(2.16,0.14,1.80),at))
		for x in [-0.90,0.90]:
			add_child(Kit.box(at+Vector3(x,-0.42,0),Vector3(0.09,0.84,1.40),housing))
		experiment_decor.append(plate("WHOLE PREFABS" if side<0 else "PARTS BECOME HYBRIDS",Vector3(side*SIDE,1.83,-0.80),Vector2(2.08,0.16),30).get_parent())
		experiment_decor.append(plate("Scatter intact / return intact" if side<0 else "Same inventory / new relationships",Vector3(side*SIDE,1.68,-0.80),Vector2(2.08,0.13),23).get_parent())
		for i in inventory.size():
			var grid: Vector3=inventory[i].grid+Vector3(side*SIDE,0,0)
			var pad:=Kit.box(grid-Vector3(0,0.009,0),Vector3(0.57,0.012,0.57),dark)
			add_child(pad);experiment_decor.append(pad)
			var caption:=plate(TITLES[i],grid+Vector3(0,0.065,0.33),Vector2(0.85,0.12),16)
			experiment_decor.append(caption.get_parent())
			if side>0: captions.append(caption)
	for part in pieces:
		for side in [-1,1]:
			var view:=MeshInstance3D.new();view.mesh=part.mesh;view.material_override=part.material;view.material_overlay=part.overlay
			view.name="%s_%s_%d" % [SOURCES[part.item],"whole" if side<0 else "parts",part.draw]
			add_child(view);part.views.append(view)
	console=Console.new();console.auto_demo=false;console.body_height=0.64
	console.board_width=1.8;console.mounting="lectern";console.position=Vector3(0,0,1.37)
	add_child(console);console.set_title("ORIGINAL / PARTS / HYBRIDS")
	console.panel().layout_columns=5
	slider=console.add_slider("STAGE", "disorder")
	slider.slider_moved.connect(func(_v):user_disorder(slider.get_normalized_value()))
	for key in ["ORIGINAL","PARTS","HYBRIDS","SEED +1","KEEP","REPLAY","GALLERY","WATCH","FOLLOW PART"]:
		buttons[key]=console.add_button(key);buttons[key].pressed.connect(act.bind(key))
		Rack.make_button_rectangular(buttons[key])
	readout=plate("",Vector3(0,2.14,-0.78),Vector2(4.28,0.38),28)
	experiment_decor.append(readout.get_parent())

func user_disorder(value: float) -> void:
	if ghost!=null: ghost.take_over()
	# Public pointer movement can land a few float32 bits off a landmark.
	for landmark in [0.0,0.5,1.0]:
		if absf(value-landmark)<0.00001: value=landmark;break
	note="Towards 0.5: separate. Towards 1: join. Reverse to return."
	set_disorder(value)

func set_disorder(value: float) -> void:
	if not is_finite(value): return
	disorder=clampf(value,0,1)
	if not ready_for_controls: return
	if not is_equal_approx(slider.get_normalized_value(),disorder): slider.set_normalized_value(disorder)
	var strength:=disorder*2.0 if disorder<=0.5 else (1.0-disorder)*2.0
	for i in pieces.size():
		var part: Dictionary=pieces[i]
		var item: Dictionary=inventory[part.item]
		var whole: Transform3D=sample.displaced(Transform3D.IDENTITY,item.bounds,part.item*6,strength)
		part.views[0].transform=Transform3D(Basis.IDENTITY,item.grid+Vector3(-SIDE,0,0))*whole*part.home
		part.views[1].transform=part_pose(i,disorder,sample,hybrids)
	for i in captions.size():
		var title: String=Hybrid.TITLES[i] if recipe_version==Hybrid.VERSION else "HYBRID "+["A","B","C","D"][i]
		captions[i].text=TITLES[i] if disorder<=0.5 else title+"\n"+donor_caption(i)
	readout.text="%s %.2f  |  seed %d  |  %d parts per side\nGeometric assembly; not an entropy reading.\n%s" % [stage_name(),disorder,experiment_seed,pieces.size(),note]
	changed.emit()

func part_pose(index: int, amount: float, source_sample: RefCounted, targets: Array) -> Transform3D:
	var part: Dictionary=pieces[index]
	var item: Dictionary=inventory[part.item]
	var separate: Transform3D=source_sample.displaced(part.home,part.bounds,part.draw,minf(amount*2.0,1.0))
	var pose:=Transform3D(Basis.IDENTITY,item.grid+Vector3(SIDE,0,0))*separate
	if amount>0.5:
		var target:=Hybrid.unpack(targets[index].pose)
		pose=target if amount==1.0 else pose.interpolate_with(target,(amount-0.5)*2.0)
		pose.origin.y+=maxf(0.0,DECK_Y-(pose*part.bounds).position.y)
	return pose

func poses_for_record(record: Dictionary) -> Array[Transform3D]:
	var saved_sample=Sample.new()
	for draw in record.draws: saved_sample.draws.append(int(draw))
	var amount: float=float(record.disorder)*(0.5 if record.schema=="prefab-disorder/1" else 1.0)
	var result: Array[Transform3D]=[]
	for i in pieces.size(): result.append(part_pose(i,amount,saved_sample,record.get("hybrids",[])))
	return result

func show_gallery(open: bool) -> void:
	gallery_open=open
	if open: gallery.refresh()
	update_visibility()
	changed.emit()

func update_visibility() -> void:
	for part in pieces:
		for view in part.views: view.visible=not gallery_open
	for decor in experiment_decor: decor.visible=not gallery_open
	set_active(console,not gallery_open)
	if gallery!=null: set_active(gallery,gallery_open)
	if is_instance_valid(butterflies): set_active(butterflies,not gallery_open)

func set_active(node: Node, active: bool) -> void:
	if node is Node3D: node.visible=active
	node.process_mode=Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	set_control_collisions(node,active)

func set_control_collisions(node: Node, active: bool) -> void:
	if node is CollisionObject3D:
		if not active and not node.has_meta("gallery_collision_layers"):
			node.set_meta("gallery_collision_layers",[node.collision_layer,node.collision_mask])
		if node.has_meta("gallery_collision_layers"):
			var layers: Array=node.get_meta("gallery_collision_layers")
			node.collision_layer=layers[0] if active else 0;node.collision_mask=layers[1] if active else 0
	for child in node.get_children(): set_control_collisions(child,active)

func donor_caption(group: int) -> String:
	var donors: Array[String]=[]
	for item in SOURCES.size():
		if hybrids.any(func(entry):return int(entry.group)==group and int(entry.item)==item): donors.append(SHORT_TITLES[item])
	return " + ".join(donors)

func stage_name() -> String:
	if disorder==0: return "ORIGINAL OBJECTS"
	if disorder<0.5: return "SEPARATING"
	if disorder==0.5: return "SEPARATED PARTS"
	if disorder<1: return "RECOMBINING"
	return "HYBRIDS"

func act(key: String) -> void:
	if key=="WATCH":
		if ghost!=null: ghost.watch()
		return
	if ghost!=null: ghost.take_over()
	match key:
		"ZERO", "ORIGINAL": note="Original assembly and grid restored.";set_disorder(0)
		"PARTS": note="The same parts, separated. Continue to join across their former boundaries.";set_disorder(0.5)
		"HYBRIDS":
			note="Saved fixed grafts. SEED +1 explores new forms." if recipe_version==Hybrid.VERSION else "Seeded joins; SEED +1 changes which parts come together."
			set_disorder(1)
		"SEED +1":
			experiment_seed=0 if experiment_seed==9223372036854775807 else experiment_seed+1
			sample.seed_draws(experiment_seed,24+pieces.size()*6)
			hybrids=Seeded.new().build(pieces,inventory,SIDE,experiment_seed)
			recipe_version=Seeded.VERSION
			note="New part groupings, joins and turns. KEEP a form to return to it.";set_disorder(disorder)
		"KEEP": keep()
		"REPLAY": replay_saved()
		"GALLERY": show_gallery(not gallery_open)
		"FOLLOW PART": witness.enabled=not witness.enabled;witness.refresh();changed.emit()

func capture() -> Dictionary:
	return {"schema":SCHEMA,"signature":signature,"seed":str(experiment_seed),"disorder":disorder,"draws":sample.draws.duplicate(),"sources":SOURCES,"engine":Engine.get_version_info().string,"recipe":recipe_version,"hybrids":hybrids.duplicate(true)}

func valid_record(record: Variant) -> bool:
	if not record is Dictionary or record.get("schema") not in [SCHEMA,"prefab-disorder/1"] or record.get("signature")!=signature: return false
	if record.get("sources")!=SOURCES or not record.get("seed") is String or not record.seed.is_valid_int(): return false
	if str(int(record.seed))!=record.seed: return false
	var amount=record.get("disorder")
	if not (amount is float or amount is int) or not is_finite(amount) or amount<0 or amount>1: return false
	if not record.get("draws") is Array or record.draws.size()!=24+pieces.size()*6: return false
	for draw in record.draws:
		if not (draw is float or draw is int) or not is_finite(draw) or draw<0 or draw>4294967295 or draw!=int(draw): return false
	if record.schema==SCHEMA and not valid_hybrids(record): return false
	return true

func valid_hybrids(record: Dictionary) -> bool:
	if record.get("recipe") not in [Hybrid.VERSION,Seeded.VERSION] or not record.get("hybrids") is Array or record.hybrids.size()!=pieces.size(): return false
	var donors: Array[Dictionary]=[{},{},{},{}]
	for i in pieces.size():
		var entry=record.hybrids[i]
		if not entry is Dictionary or entry.get("item")!=pieces[i].item or entry.get("key")!=pieces[i].key: return false
		var group=entry.get("group")
		if not (group is int or group is float) or not is_finite(group) or group<0 or group>3 or group!=int(group): return false
		if not entry.get("pose") is Array or entry.pose.size()!=12: return false
		for value in entry.pose:
			if not (value is int or value is float) or not is_finite(value): return false
		var pose:=Hybrid.unpack(entry.pose)
		var scale_vector:=pose.basis.get_scale()
		if pose.basis.determinant()<=0: return false
		if scale_vector.x<0.05 or scale_vector.x>4 or not scale_vector.is_equal_approx(Vector3.ONE*scale_vector.x): return false
		if not pose.basis.orthonormalized().is_equal_approx(pose.basis.scaled(Vector3.ONE/scale_vector.x)): return false
		var bounds: AABB=pose*pieces[i].bounds
		var grid: Vector3=inventory[int(group)].grid+Vector3(SIDE,0,0)
		if bounds.position.y<DECK_Y-0.00001 or bounds.end.y>DECK_Y+0.56: return false
		if absf(bounds.get_center().x-grid.x)+bounds.size.x/2>0.28 or absf(bounds.get_center().z-grid.z)+bounds.size.z/2>0.28: return false
		donors[int(group)][entry.item]=true
	return donors.all(func(d):return d.size()>=3)

func restore(record: Variant) -> bool:
	if not valid_record(record): return false
	experiment_seed=int(record.seed);sample.draws.clear()
	for draw in record.draws: sample.draws.append(int(draw))
	if record.schema==SCHEMA:
		hybrids.assign(record.hybrids.duplicate(true))
		recipe_version=record.recipe
	else:
		hybrids=Hybrid.new().build(pieces,inventory,SIDE)
		recipe_version=Hybrid.VERSION
	note="Saved offsets, hybrid targets and slider restored; no new draws." if record.schema==SCHEMA else "Earlier separation record restored in the first half of the slider."
	# Old records described only separation: old 1 becomes the new midpoint.
	set_disorder(float(record.disorder)*(0.5 if record.schema=="prefab-disorder/1" else 1.0));return true

func keep() -> String:
	# Bind before replacing the old pointer, so its previous save joins the gallery.
	gallery_store.bind(pointer_path)
	var path:="user://prefab-disorder-%d-%d.json" % [int(Time.get_unix_time_from_system()),Time.get_ticks_usec()]
	var file:=FileAccess.open(path,FileAccess.WRITE)
	if file==null: note="Save failed; current arrangement retained.";set_disorder(disorder);return ""
	file.store_string(JSON.stringify(capture(),"\t",true,true));file.flush()
	var error:=file.get_error();file.close()
	if error!=OK: note="Save incomplete; current arrangement retained.";set_disorder(disorder);return ""
	saved_path=path;gallery_selected_path=path
	var listed: bool=gallery_store.add(path)
	print("Prefab disorder record: ",ProjectSettings.globalize_path(path))
	var pointer:=FileAccess.open(pointer_path,FileAccess.WRITE)
	if pointer==null: note="Record saved; see Output for its path.";set_disorder(disorder);return path
	pointer.store_string(JSON.stringify({"path":path}));pointer.close()
	note="KEPT in gallery (%d entries). Open GALLERY to compare and replay." % gallery_store.paths.size() if listed else "Record saved; "+gallery_store.error
	if gallery!=null and listed: gallery.page=(gallery_store.paths.size()-1)/gallery.page_size
	if gallery_open: gallery.refresh()
	set_disorder(disorder);return path

func replay_saved() -> bool:
	if not gallery_selected_path.is_empty(): return replay_path(gallery_selected_path)
	if not FileAccess.file_exists(pointer_path): note="KEEP an arrangement first.";set_disorder(disorder);return false
	var pointer=JSON.parse_string(FileAccess.get_file_as_string(pointer_path))
	if not pointer is Dictionary or not pointer.get("path") is String: return false
	return replay_path(pointer.path)

func replay_path(path: String) -> bool:
	var record=GalleryStore.read_json(path)
	if not restore(record): note="Different prefab source or incompatible record; arrangement retained.";set_disorder(disorder);return false
	saved_path=path;return true

func plate(text: String, at: Vector3, size: Vector2, font_size: int) -> Label3D:
	var back:=Kit.box(at,Vector3(size.x,size.y,0.035),Kit.rams_body(Color("1a2932"),0))
	add_child(back)
	var label:=Label3D.new();label.text=text;label.font_size=font_size;label.pixel_size=0.0025
	label.outline_size=0;label.position.z=0.022;back.add_child(label)
	return label
