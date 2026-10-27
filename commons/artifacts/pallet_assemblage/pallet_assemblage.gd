extends Node3D
## A human supplies the arrangement. Saving names the loose collection, never welds it.
## Stable part IDs and full local poses travel through terms.json, tree and live editor.
const Pickable = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const Piece = preload("res://commons/artifacts/pallet_assemblage/pallet_piece.gd")
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
const ButtonScene = preload("res://commons/interactables/cube_button.tscn")
@export var term := "pallet_hand_kit"
@export var workshop := true
@export var editor_url := "http://127.0.0.1:3003"
signal prefab_saved(id: String)
var part_defaults: Dictionary = {}
var pieces: Dictionary = {}
var definitions: Array = []
var buttons: Dictionary = {}
var events: Array = []
var placing := true
var pending_config: Dictionary = {}
var status: Label3D
var request: HTTPRequest
var pending_save: Dictionary = {}
var last_saved_id := ""
var saving := false
var study := ""
var study_runtime: Node3D
var track_height := .218
var board_count := 1
var logic_grammar := "blockers"

func apply_grid_config(config: Dictionary) -> void:
	pending_config = config.duplicate(true)
	term = str(config.get("term",term));workshop = bool(config.get("workshop",workshop))
	study = str(config.get("study",study))
	track_height = float(config.get("track_height",track_height))
	board_count = clampi(int(config.get("board_count",board_count)),1,2)
	logic_grammar = str(config.get("logic_grammar",logic_grammar))
	if is_node_ready():_apply_poses(config)

func _ready() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/modular/terms.json"))
	var record: Dictionary = doc.terms.get(term,{})
	if not record.has("handmade"):
		push_error("Unknown hand assembly term: "+term);return
	definitions = record.handmade.parts.duplicate(true)
	study = str(pending_config.get("study",record.handmade.get("study",study)))
	track_height = float(pending_config.get("track_height",record.handmade.get("track_height",track_height)))
	board_count = clampi(int(pending_config.get("board_count",record.handmade.get("board_count",board_count))),1,2)
	logic_grammar = str(pending_config.get("logic_grammar",record.handmade.get("logic_grammar",logic_grammar)))
	var kept: Array = pending_config.get("only_parts",[])
	for p in definitions:
		var id: String = p.id
		if not kept.is_empty() and not kept.has(id):continue
		var body := Pickable.instantiate() as XRToolsPickable
		body.set_script(Piece)
		body.name = id;body.mass = maxf(.08,float(p.size[0])*float(p.size[1])*float(p.size[2])*550)
		body.freeze = true;body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
		body.release_mode = XRToolsPickable.ReleaseMode.FROZEN
		body.collision_layer = 1;body.collision_mask = 1;body.continuous_cd = true
		body.physics_material_override = PhysicsMaterial.new();body.physics_material_override.friction = .7
		for child in body.get_children():
			if child is CollisionShape3D:child.free()
		var size := vec(p.size)
		var mesh := MeshInstance3D.new();mesh.name = "Timber";mesh.mesh = Timber.mesh(size);mesh.material_override = Timber.material();body.add_child(mesh)
		var collider := CollisionShape3D.new();collider.name = "SolidWood";collider.shape = BoxShape3D.new();collider.shape.size = size;body.add_child(collider)
		body.position = vec(p.position)+Vector3(0,.60 if workshop and study.is_empty() else 0,0);body.rotation_degrees = vec(p.rotation)
		body.set_meta("pallet_part_id",id);body.set_meta("pallet_source",p.source)
		add_child(body);pieces[id] = body
		body.picked_up.connect(func(_p):record_event("pick_up",id))
		body.dropped.connect(func(_p):record_event("place" if placing else "drop",id))
		part_defaults[id] = {"label":str(p.role)+" / "+id,"position":arr(body.position),"rotation":p.rotation,"bounds":[-size.x/2,-size.y/2,-size.z/2,size.x,size.y,size.z]}
	if study in ["pallet_and","pallet_or"]:
		study_runtime = load("res://commons/artifacts/pallet_assemblage/pallet_or_study.gd" if study=="pallet_or" else "res://commons/artifacts/pallet_assemblage/pallet_logic_study.gd").new();study_runtime.name = "LogicRuntime";add_child(study_runtime);study_runtime.build(self)
		if not kept.is_empty():
			for id in part_defaults.keys():
				if not kept.has(id):
					get_node(NodePath(id)).free();part_defaults.erase(id)
	elif workshop and kept.is_empty():build_controls()
	if record.handmade.has("environment"):
		_apply_poses({"parts":record.handmade.environment})
		for id in record.handmade.environment:
			if part_defaults.has(id):
				part_defaults[id].position = record.handmade.environment[id].position
				part_defaults[id].rotation = record.handmade.environment[id].rotation
		if is_instance_valid(study_runtime) and is_instance_valid(study_runtime.output):study_runtime.cone_rest = study_runtime.output.transform
	_apply_poses(pending_config)
	request = HTTPRequest.new();request.timeout = 12;add_child(request);request.request_completed.connect(_saved)
	set_meta("void_preview_kind","Real chamfered timber meshes; twenty independent pickables with stable IDs. Saved collections have no joints.")

static func vec(a: Array) -> Vector3:return Vector3(float(a[0]),float(a[1]),float(a[2]))
static func arr(v: Vector3) -> Array:return [v.x,v.y,v.z]
func record_event(action: String,id := "") -> void:
	var e := {"action":action,"part":id,"time_ms":Time.get_ticks_msec()}
	if pieces.has(id):e["position"] = arr(pieces[id].position);e["rotation"] = arr(pieces[id].rotation_degrees)
	events.append(e)
	if events.size()>256:events.pop_front()

func _apply_poses(config: Dictionary) -> void:
	for id in config.get("parts",{}):
		var node := get_node_or_null(NodePath(id)) as Node3D
		if node==null:continue
		var pose: Dictionary = config.parts[id]
		node.position = vec(pose.get("position",part_defaults[id].position))
		node.rotation_degrees = vec(pose.get("rotation",part_defaults[id].rotation))
		if node is RigidBody3D:PhysicsServer3D.body_set_state(node.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,node.global_transform)

func set_placing(value: bool) -> void:
	placing = value
	var materials: Array = pieces.values()
	if is_instance_valid(study_runtime):materials.append_array(study_runtime.ramp_pieces)
	for body: XRToolsPickable in materials:
		if not is_instance_valid(body):continue
		body.release_mode = XRToolsPickable.ReleaseMode.FROZEN if value else XRToolsPickable.ReleaseMode.UNFROZEN
		if not body.is_picked_up():
			body.freeze = value;body.sleeping = false
			if value:body.linear_velocity = Vector3.ZERO;body.angular_velocity = Vector3.ZERO
	record_event("place_mode" if value else "test_gravity")
	if status:status.text = "PLACE / pieces stay where released" if value else "GRAVITY / loose wood, no hidden joints"

func reset_pallet() -> void:
	if is_instance_valid(study_runtime):
		for item in study_runtime.ramp_pieces:
			if is_instance_valid(item) and item.is_picked_up():
				if status:status.text = "Release the held track board before resetting."
				return
	for body: XRToolsPickable in pieces.values():
		if body.is_picked_up():
			if status:status.text = "Release the held piece before resetting."
			return
	set_placing(true)
	pending_save = {}
	for p in definitions:
		if not pieces.has(p.id):continue
		var body: XRToolsPickable = pieces[p.id]
		body.position = vec(part_defaults[p.id].position);body.rotation_degrees = vec(part_defaults[p.id].rotation)
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	record_event("reset")
	if status:status.text = "Pallet restored / saved sculptures are kept"
	if is_instance_valid(study_runtime):study_runtime.reset_ball()

func snapshot(label := "") -> Dictionary:
	var parts: Array = []
	for p in definitions:
		if not pieces.has(p.id):continue
		var next: Dictionary = p.duplicate(true);var body: Node3D = pieces[p.id]
		next.position = arr(body.position);next.rotation = arr(body.rotation_degrees);parts.append(next)
	var result := {"source":"pallet_hand_kit","label":label if not label.is_empty() else ("Pallet OR " if study=="pallet_or" else "Pallet AND " if not study.is_empty() else "Pallet sculpture ")+Time.get_datetime_string_from_system().replace("T"," "),"parts":parts,"mode":"place" if placing else "gravity","events":events.duplicate(true)}
	result["map"] = str(pending_config.get("insertion_map","Primitives_Melencolia"))
	if study in ["pallet_and","pallet_or"]:
		result["study"] = study;result["environment"] = {}
		result["track_height"] = track_height
		result["board_count"] = board_count
		result["logic_grammar"] = logic_grammar
		for id in ["Board","Board2","CinderBlock1","CinderBlock2","CinderBlock3","CinderBlock4","CinderBlock5","CinderBlock6","CinderBlock7","CinderBlock8","BallAndRelease","BallAndReleaseY","LogicControls","TrueCone","BaseCrate1","BaseCrate2","BaseCrate3","BaseCrate4","BaseCrate5","BaseCrate6","BaseCrate7","BaseCrate8","Runway1","Runway2","Runway3","Runway4"]:
			var node := get_node_or_null(NodePath(id)) as Node3D
			if node:result.environment[id] = {"position":arr(node.position),"rotation":arr(node.rotation_degrees)}
	return result

func save_prefab() -> void:
	if saving:return
	if is_instance_valid(study_runtime):
		for item in study_runtime.carried_parts():
			if is_instance_valid(item) and item.is_picked_up():
				if status:status.text = "Release the ball and cone before saving."
				return
	if pieces.size()!=20:
		if status:status.text = "Save the complete twenty-piece collection at the workshop."
		return
	for body: XRToolsPickable in pieces.values():
		if body.is_picked_up():
			if status:status.text = "Release the held piece before saving."
			return
	# A failed HTTP attempt retains its exact draft and retry key. New edits are not lost.
	var fresh := snapshot()
	if pending_save.is_empty() or JSON.stringify(fresh.parts)!=JSON.stringify(pending_save.parts):
		pending_save = snapshot();pending_save["key"] = str(Time.get_unix_time_from_system())+"-"+str(randi())
	var draft_file := FileAccess.open("user://pallet-assemblage-draft.json",FileAccess.WRITE)
	if draft_file==null:
		if status:status.text = "NOT SAVED / local draft could not be written.\nThe arrangement is still here; free space and retry."
		return
	draft_file.store_string(JSON.stringify(pending_save,"  "));draft_file.flush()
	if draft_file.get_error()!=OK:
		if status:status.text = "NOT SAVED / draft write failed. Free space and retry."
		draft_file.close();return
	draft_file.close()
	var url := OS.get_environment("VOID_EDITOR_URL")
	if url.is_empty():url = editor_url
	saving = true
	var err := request.request(url.trim_suffix("/")+"/api/handmade-prefabs",["Content-Type: application/json"],HTTPClient.METHOD_POST,JSON.stringify(pending_save))
	if err!=OK:saving = false
	if status:status.text = "Saving twenty loose pieces..." if err==OK else "Save failed / draft retained. Press SAVE to retry."

func recover_draft() -> void:
	if is_instance_valid(study_runtime):
		for item in study_runtime.carried_parts():
			if is_instance_valid(item) and item.is_picked_up():
				if status:status.text = "Release the ball and cone before recovering."
				return
	for body: XRToolsPickable in pieces.values():
		if body.is_picked_up():
			if status:status.text = "Release the held piece before recovering."
			return
	if not FileAccess.file_exists("user://pallet-assemblage-draft.json"):
		if status:status.text = "No local draft yet. SAVE retains one before connecting."
		return
	var json := JSON.new()
	if json.parse(FileAccess.get_file_as_string("user://pallet-assemblage-draft.json"))!=OK:
		if status:status.text = "Local draft could not be read. Current pieces are unchanged."
		return
	var draft: Variant = json.data
	if not draft is Dictionary or draft.get("source","")!="pallet_hand_kit" or draft.get("parts",[]).size()!=20:return
	var poses := {}
	for p in draft.parts:
		if not pieces.has(p.id):return
		poses[p.id] = {"position":p.position,"rotation":p.rotation}
	if poses.size()!=20:return
	for id in draft.get("environment",{}):
		if part_defaults.has(id):
			poses[id] = draft.environment[id]
			var node := get_node_or_null(NodePath(id)) as RigidBody3D
			if node:node.freeze = true;node.linear_velocity = Vector3.ZERO;node.angular_velocity = Vector3.ZERO
	set_placing(true);_apply_poses({"parts":poses});pending_save = draft
	record_event("recover")
	if status:status.text = "Local draft recovered / SAVE retries it"

func _saved(result: int,code: int,_headers: PackedStringArray,body: PackedByteArray) -> void:
	saving = false
	var response: Variant = {}
	var json := JSON.new()
	if body.size()>0 and json.parse(body.get_string_from_utf8())==OK:response = json.data
	if result!=HTTPRequest.RESULT_SUCCESS or code!=200 or not response is Dictionary or not response.has("id"):
		if status:status.text = "NOT SAVED / draft retained. Retry SAVE.\n"+(str(response.get("error","Editor connection unavailable")) if response is Dictionary else "Editor connection unavailable")
		return
	last_saved_id = response.id;pending_save = {};record_event("save",last_saved_id)
	if status:status.text = "SAVED / "+last_saved_id+"\nTree + prefab workbench + live editor"
	prefab_saved.emit(last_saved_id)

func build_controls() -> void:
	var plinth := StaticBody3D.new();plinth.name = "CubePlinths";add_child(plinth)
	for x in [-.44,.44]:
		var m := MeshInstance3D.new();var cube := BoxMesh.new();cube.size = Vector3(.30,.60,.78);m.mesh = cube;m.position = Vector3(x,.30,0)
		var concrete := StandardMaterial3D.new();concrete.albedo_color = Color("ded9cc");concrete.roughness = .92;m.material_override = concrete;plinth.add_child(m)
		var c := CollisionShape3D.new();c.shape = BoxShape3D.new();c.shape.size = cube.size;c.position = m.position;plinth.add_child(c)
	part_defaults.CubePlinths = {"position":[0,0,0],"rotation":[0,0,0],"bounds":[-.59,0,-.39,1.18,.60,.78],"label":"Two support cubes / not part of saved sculpture"}
	var host := Node3D.new();host.name = "WorkControls";host.position = Vector3(1.15,0,.0);add_child(host)
	var stand := StaticBody3D.new();stand.position = Vector3(0,.75,0);host.add_child(stand)
	var mesh := MeshInstance3D.new();var box := BoxMesh.new();box.size = Vector3(.58,1.5,.16);mesh.mesh = box
	var mat := StandardMaterial3D.new();mat.albedo_color = Color("252733");mat.metallic = .65;mat.roughness = .4;mesh.material_override = mat;stand.add_child(mesh)
	var collision := CollisionShape3D.new();collision.shape = BoxShape3D.new();collision.shape.size = box.size;stand.add_child(collision)
	for i in range(5):
		var id: String = ["PLACE","GRAVITY","SAVE","RESET","RECOVER"][i]
		var button := ButtonScene.instantiate();button.name = id;button.label = id;button.cap_color = Color("ee589c");button.position = Vector3((i%2-.5)*.29,1.32-floori(i/2.0)*.30,.10);host.add_child(button);buttons[id] = button
		button.pressed.connect(set_placing.bind(true) if i==0 else set_placing.bind(false) if i==1 else save_prefab if i==2 else reset_pallet if i==3 else recover_draft)
	status = Label3D.new();status.name = "Status";status.text = "TAKE APART / BUILD BY HAND\nRMB pick / release. X Y Z rotate; Shift reverses.\nPLACE holds. GRAVITY tests. SAVE keeps loose parts."
	status.font_size = 28;status.pixel_size = .0011;status.position = Vector3(0,1.78,.10);status.modulate = Color("fff5e7");host.add_child(status)
	part_defaults.WorkControls = {"position":arr(host.position),"rotation":[0,0,0],"bounds":[-.65,0,-.12,1.3,2,.3],"label":"Hand assembly / controls"}
