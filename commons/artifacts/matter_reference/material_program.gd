extends "res://commons/artifacts/matter_reference/matter_reference.gd"
const Visuals = preload("res://commons/artifacts/matter_reference/source_visuals.gd")
var study := "if"
var events: Dictionary = {}
var loop_balls: Array[String] = []
var next_ball := .2
var pulled := false
var pull_requested := false
var pull_at := -1.0
func _init() -> void:graph_path = "res://commons/artifacts/matter_reference/material-programs.json";kind = "if"
func apply_grid_config(config: Dictionary) -> void:
	study = str(config.get("study",study));var c := config.duplicate(true);c.kind = study
	if study=="array":c.kind = "array"+str(clampi(int(config.get("index",0)),0,5))
	if study=="loop":c.kind = "loop"+str(clampi(int(config.get("n",3)),1,5))
	if config.has("graph_key"):c.kind = config.graph_key
	super.apply_grid_config(c)
func _ready() -> void:
	super._ready()
	for id in graph.visuals:
		if not bodies.has(id):continue
		for child in bodies[id].get_children():
			if child is MeshInstance3D:child.free()
		Visuals.append(bodies[id],graph.visuals[id]);remember(bodies[id],str(records[id].look)+" / original mesh")
	button_visibility("X",study in ["if","ifelse","array","loop"] or study.begins_with("pipeline_"));button_visibility("Y",false)
	if study=="array":set_button_label("INDEX "+str(graph.params.index))
	if study=="loop":set_button_label("LAPS "+str(graph.n))
	if study.begins_with("pipeline_"):set_button_label("PULL PINS")
	for id in bodies:
		if bodies[id] is RigidBody3D:
			var pm: PhysicsMaterial = bodies[id].physics_material_override;pm.friction = .02 if records[id].material in ["iron","cup","scale"] else 0 if records[id].material=="thing" else .5;pm.bounce = .05
	if study=="array":bodies[graph.refs.pc].physics_material_override.friction = .5
	set_meta("void_preview_kind","Original material program/cup geometry, mass, mesh recipes and support dressing. Real Jolt hinges and sphere contacts. Native per-body friction approximates source pair materials. Canonical configurations are retained; not arbitrary source factory evaluation.")
func set_button_label(text: String) -> void:
	button_text("X",text)
func update_inputs() -> void:
	super.update_inputs()
	if study=="array":set_button_label("INDEX "+str(graph.params.index))
	if study=="loop":set_button_label("LAPS "+str(graph.n))
	if study.begins_with("pipeline_"):set_button_label("PULL PINS")
func toggle_input(id: String) -> void:
	if study in ["if","ifelse"]:super.toggle_input(id);return
	if study.begins_with("pipeline_"):
		if running:pull_requested = true
		return
	if running:return
	if study=="array":pending.index = (int(graph.params.index)+1)%6
	elif study=="loop":pending.n = int(graph.n)%5+1
	rebuild_variant.call_deferred()
func rebuild_variant() -> void:
	running = false
	for child in get_children():child.free()
	bodies.clear();records.clear();homes.clear();buttons.clear();ropes.clear();chocks.clear();joints.clear();plane_joints.clear();part_defaults.clear();loop_balls.clear();events.clear()
	apply_grid_config(pending);_ready()
func build_dressing() -> void:
	var host := Node3D.new();host.name = "OriginalSupports";add_child(host);Visuals.append(host,graph.dressing);remember(host,"Original source supports, axles, posts and labels")
func contact(other: Node3D,id: String) -> void:
	if running:hit_log.append({"at":elapsed,"a":id,"b":str(other.name)})
func reset_take() -> void:
	for id in loop_balls:
		if bodies.has(id):bodies[id].queue_free();bodies.erase(id);homes.erase(id);records.erase(id)
	loop_balls.clear();events.clear();next_ball = .2;pulled = false;pull_requested = false;pull_at = -1;super.reset_take()
	for id in graph.refs.get("pins",[]):bodies[id].collision_layer = 1;bodies[id].visible = true
func mark(id: String) -> void:
	if not events.has(id):events[id] = elapsed
func tilt(id: String) -> float:return rad_to_deg(acos(clampf(bodies[id].global_basis.y.dot(global_basis.y),-1,1)))
func local_position(id: String) -> Vector3:return to_local(bodies[id].global_position)
func angle(id: String,axis := "z") -> float:return bodies[id].rotation.z if axis=="z" else bodies[id].rotation.x
func bucket_count() -> int:
	var count := 0;var a := -angle(graph.refs.beam)
	for id in loop_balls:
		var p := local_position(id);var relative := Vector2(p.x,p.y-1).rotated(a)
		if absf(relative.x-.62)<.17 and relative.y>0 and relative.y<.42 and absf(p.z+.4)<.65:count+=1;release_plane(id)
	return count
func release_ball() -> void:
	if loop_balls.size()>=graph.maxBalls:return
	var rec: Dictionary = graph.templates.ball;var id := "LapBall"+str(loop_balls.size());var body := RigidBody3D.new();body.name = id;body.mass = rec.mass;body.position = v(rec.position);body.can_sleep = false;body.continuous_cd = true;body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp = -log(1.0-rec.linear_damping);body.angular_damp = -log(1.0-rec.angular_damping);body.gravity_scale = 9.82/9.8;body.collision_layer = 1;body.collision_mask = 1
	var pm := PhysicsMaterial.new();pm.friction = .02;pm.bounce = .05;body.physics_material_override = pm;add_child(body);bodies[id] = body;records[id] = rec;homes[id] = body.transform;loop_balls.append(id)
	var col := CollisionShape3D.new();col.shape = SphereShape3D.new();col.shape.radius = rec.shapes[0].radius;body.add_child(col);var mesh := MeshInstance3D.new();mesh.mesh = SphereMesh.new();mesh.mesh.radius = rec.shapes[0].radius;mesh.mesh.height = rec.shapes[0].radius*2;mesh.material_override = mat("iron");body.add_child(mesh);install_plane(id)
func pull() -> void:
	if pulled:return
	pulled = true;pull_at = elapsed
	for id in graph.refs.get("pins",[]):bodies[id].collision_layer = 0;bodies[id].visible = false
func pipeline_read() -> Dictionary:
	var cups: Array = [];var trays: Array = [];var rail := 0;var lost := 0
	for i in graph.xs.size():
		var cup := 0;var tray := 0;var cx: float = (i-(graph.xs.size()-1)*.5)
		for id in graph.refs.balls:
			var p := local_position(id)
			if absf(p.x-cx)<.41 and p.y>graph.CY-.1 and p.y<graph.CY+.25 and p.z>graph.ZH-.05 and p.z<graph.ZH+.26:cup+=1
			if absf(p.x-cx)<.45 and p.y<graph.CY-.5 and p.y>.5 and p.z>-.06 and p.z<.42:tray+=1
		cups.append(cup);trays.append(tray)
	for id in graph.refs.balls:
		var p := local_position(id)
		if graph.rail!=null:
			var cy: float = graph.rail.L0[1]+(p.x-graph.rail.L0[0])*(graph.rail.L1[1]-graph.rail.L0[1])/(graph.rail.L1[0]-graph.rail.L0[0])
			if p.x> -2.4 and p.y<cy+.2 and absf(p.z-graph.rail.TZ)<.1:rail+=1
		if p.y<.2 and not (graph.rail!=null and absf(p.z-graph.rail.TZ)<.12):lost+=1
	return {"cups":cups,"trays":trays,"rail":rail,"lost":lost}
func _physics_process(dt: float) -> void:
	if not running:return
	elapsed += dt
	if study.begins_with("pipeline_"):
		if not pulled and (pull_requested or bool(pending.get("auto_pull",false))) and elapsed>=(1.3 if study=="pipeline_chain" else .5):pull()
		status.text = study.trim_prefix("pipeline_").to_upper()+" / "+("PINS OUT" if pulled else "PULL PINS WHEN READY")+"\n"+JSON.stringify(pipeline_read())
		if pulled and elapsed>=pull_at+16:running = false;result = 1
		return
	if study in ["if","ifelse"]:
		var p := local_position(graph.refs.pc)
		if p.x>.65 and p.y>1.2 and p.y<1.95:mark("then")
		if p.x< -.65 and p.y>1.2 and p.y<1.95:mark("else")
		if tilt(graph.refs.thenThing)>30:mark("thenDone")
		if graph.refs.has("elseThing") and absf(angle(graph.refs.elseThing))>.2:mark("elseDone")
		if absf(p.x)<.34 and p.y<.4:mark("end")
	elif study=="array":
		for i in graph.refs.items.size():
			var id: String = graph.refs.items[i]
			if not id.is_empty() and local_position(id).y>records[id].rest+.35:mark("read"+str(i))
	elif study=="loop":
		if elapsed>=next_ball and not events.has("exit"):release_ball();next_ball += 2.4
		var k := bucket_count()
		if k>0:mark("lap"+str(k))
		if angle(graph.refs.beam)< -.12:mark("tipped")
		if events.has("tipped"):
			for id in loop_balls:
				var p := local_position(id);var cy := 1.8+(p.x+2.6)*(1.41-1.8)/( .38+2.6)
				if plane_joints.has(id) and p.x< -.3 and p.x> -1.3 and p.y>cy and bodies[id].linear_velocity.length()<.08:mark("exit")
	status.text = study+" / "+JSON.stringify(events)
	if elapsed>(35 if study=="loop" else 16):running = false;result = int(events.has("exit") if study=="loop" else events.has("end") if study in ["if","ifelse"] else events.has("read"+str(graph.params.index)))
