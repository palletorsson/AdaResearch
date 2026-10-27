extends "res://commons/artifacts/matter_reference/material_program.gd"
## The source's threshold experiments report margins, never Boolean correctness.
var threshold := "again"
var variant := 0
var maximum := -1.0
var crossed := false
var cross_height := -1.0
var last_x := 0.0
var crossings: Array[float] = []
var samples: Array[float] = []
var grain_ids: Array[String] = []
var last_drop := -9.0
var reading: Dictionary = {}
var calm := 0.0
var over_energy := -1.0
var growth: Array[float] = []
var smooth_pipe: StaticBody3D
var auto_feed := false
var grain_requested := false
var feed_ready := false
var take_history: Array = []
var ledger_text: Label3D
var high_mark: MeshInstance3D
var high_label: Label3D
var release_height := 1.046
func apply_grid_config(config: Dictionary) -> void:
	threshold = str(config.get("threshold",threshold));variant = clampi(int(config.get("variant",0)),0,2);var c := config.duplicate(true);c.study = "almost_"+threshold;c.graph_key = c.study+"_"+str(variant);super.apply_grid_config(c)
	auto_feed = bool(config.get("auto_feed",false))
func _ready() -> void:
	super._ready();button_visibility("X",true);button_visibility("Y",true);set_button_label(setting_text())
	for id in bodies:
		if bodies[id] is RigidBody3D:
			bodies[id].physics_material_override.friction = .3 if records[id].material=="grain" else .7 if records[id].material=="block" else .5;bodies[id].physics_material_override.bounce = .05 if records[id].material in ["grain","pan"] else 0.0
	if threshold=="just":bodies[graph.refs.beam].angular_damp += -240*log(.994)
	if threshold=="almost":prepare_pipe()
	release_height = float(pending.get("release_height",graph.params.get("h",1.046)))
	if threshold=="almost" and pending.has("release_height"):place_release_height()
	build_witness();apply_poses(pending);update_witness()
	set_meta("void_preview_kind","Original threshold-study geometry, mass, supports, materials and three source parameter settings. Native Jolt observations and margins, not copied Cannon thresholds. Ball nudges, cooling noise and balance feeding remain explicit source operations. Engine-specific thresholds are intentionally reported, not forced.")

func witness_label(host: Node3D,text: String,at: Vector3,size := 21) -> Label3D:
	var label := Label3D.new();label.text = text;label.position = at;label.font_size = size;label.pixel_size = .0014;label.modulate = Color("fff3e1");label.outline_modulate = Color("211c28");label.outline_size = 4;host.add_child(label);return label

func witness_button(host: Node3D,id: String,text: String,at: Vector3,action: Callable) -> void:
	var button := ButtonScene.instantiate();button.name = id;button.label = text;button.position = at;button.cube_size = .055;button.cap_color = Color("e45391");host.add_child(button);buttons[id] = button;button.pressed.connect(action)

func build_witness() -> void:
	# The recorder is a separate editable part; it never supplies an outcome.
	var host := Node3D.new();host.name = "TakeLedger";host.position = get_node("Controls").position+Vector3(2.2,.16,0);add_child(host)
	box_mesh(host,Vector3(0,.06,0),Vector3(1.25,.72,.10),"dark")
	box_mesh(host,Vector3(0,-.48,0),Vector3(.14,.45,.14),"post")
	ledger_text = witness_label(host,"",Vector3(0,.12,.065),18)
	if threshold=="almost":
		witness_button(host,"LOWER","−1 mm",Vector3(-.3,-.25,.11),adjust_height.bind(-.001));witness_button(host,"RAISE","+1 mm",Vector3(.3,-.25,.11),adjust_height.bind(.001))
	elif threshold=="just":witness_button(host,"AUTO_FEED","AUTO OFF",Vector3(0,-.25,.11),toggle_feeding)
	finish_control_labels(host);remember(host,"Measured take history / original physics, no success gate")
	if threshold=="almost":
		var ruler := Node3D.new();ruler.name = "HeightWitness";add_child(ruler)
		box_mesh(ruler,Vector3(1.51,.75,.25),Vector3(.025,.85,.025),"dark")
		for i in range(7):box_mesh(ruler,Vector3(1.51,.4+i*.1,.25),Vector3(.10,.006,.025),"plywood")
		box_mesh(ruler,Vector3(1.51,float(graph.extra.need),.25),Vector3(.31,.012,.025),"plywood")
		box_mesh(ruler,Vector3(1.51,.4,.28),Vector3(.38,.015,.035),"red");high_mark = ruler.get_child(-1)
		high_label = witness_label(ruler,"MAX —",Vector3(1.72,.45,.30),15)
		remember(ruler,"Almost / actual maximum-height witness and lip reference")

func place_release_height() -> void:
	# Exact source half-pipe release equation; the physical collider is unchanged.
	release_height = snappedf(clampf(release_height,.98,1.12),.001)
	var a := -acos(clampf((1.9-release_height)/1.5,-1,1));var id: String = graph.refs.ball
	var body: Node3D = bodies[id];body.position = Vector3(1.5*sin(a),1.9-1.5*cos(a),body.position.z);homes[id] = body.transform
	PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	# The graph is cached/shared. Keep these trial-specific changes local.
	graph = graph.duplicate(true);graph.params.h = release_height;graph.extra.h = release_height

func adjust_height(amount: float) -> void:
	if running:return
	reset_take();pending.release_height = release_height+amount;release_height += amount;place_release_height();update_inputs();update_witness()

func toggle_feeding() -> void:
	auto_feed = not auto_feed;pending.auto_feed = auto_feed;grain_requested = false;update_witness()

func request_grain() -> void:
	if result>=0:return
	if not running:release_take()
	# One pending grain, not a click queue that suddenly dumps a handful.
	grain_requested = true;update_witness()

func repeat_take() -> void:
	reset_take();release_take()

func update_witness() -> void:
	button_text("Y","+1 GRAIN" if threshold=="just" else "REPEAT")
	button_text("AUTO_FEED","AUTO ON" if auto_feed else "AUTO OFF")
	if is_instance_valid(ledger_text):
		var rows: Array[String] = ["LAST TAKES"]
		for take in take_history:rows.append(str(take.setting_text)+" · "+str(take.summary))
		if take_history.is_empty():rows.append("REPEAT TO COMPARE")
		if threshold=="almost":rows.append("RELEASE %.1f cm"%(release_height*100))
		if threshold=="just":rows.append("WAIT FOR NEEDLE" if running and not feed_ready else "ONE GRAIN AT A TIME")
		ledger_text.text = "\n".join(rows)
	if is_instance_valid(high_mark):
		high_mark.position.y = maximum if maximum>=0 else float(graph.extra.bottom)
		high_label.position.y = high_mark.position.y+.05;high_label.text = "MAX %.1f cm"%(maximum*100) if maximum>=0 else "MAX —"

func reading_text() -> String:
	if reading.is_empty():return "READY"
	var ended := bool(reading.get("finished",false));var outcome := str(reading.get("outcome","waiting")).to_upper()
	match threshold:
		"almost":return "%.1f%% / %s"%[maxf(0,float(reading.get("margin",0)))*100,outcome if ended else "CLIMBING"]
		"just":return "%d / %.2f GRAINS · %.2f°"%[grain_count(),float(graph.extra.c),float(reading.get("angle",0))]
		"barely":return "PEAK %.2f° / %.2f°"%[rad_to_deg(maxf(0,maximum)),float(graph.extra.crit)]
		"still":return "%s / %.2f s"%[outcome if ended else "HESITATING",float(reading.get("margin",elapsed)) if ended and reading.get("margin")!=null else elapsed]
		"again":return "%s / %.2f s"%[outcome if ended else "WATCH THE RETURN",float(reading.margin) if ended and reading.get("outcome")=="back" and reading.get("margin")!=null else elapsed]
		"descent":return "%s / SHAKE %.2f"%[outcome if ended else "SEARCHING",float(graph.extra.T0)*maxf(0,1-elapsed/float(graph.extra.COOL))]
	return outcome

func finish_reading(finished: bool) -> void:
	running = false;result = int(finished);reading.finished = finished;reading.seconds = elapsed
	take_history.append({"setting_text":setting_text(),"summary":reading_text(),"reading":reading.duplicate(true)})
	if take_history.size()>3:take_history.pop_front()
	status.text = threshold.to_upper()+" / "+reading_text()+"\n"+("TIPPED / REPEAT TO COMPARE" if threshold=="just" and finished else "REPEAT TO COMPARE")
	update_witness()
func prepare_pipe() -> void:
	# Reconstruct the source's authored circular surface as welded triangles.
	# Jolt otherwise treats overlapping short plank ends as repeated impacts.
	# An explicitly edited plank keeps its own original box collider instead.
	if is_instance_valid(smooth_pipe):smooth_pipe.free()
	for rec in graph.bodies:
		if rec.look=="pipe":bodies[rec.id].collision_layer = 1
	for id in pending.get("parts",{}):
		if records.has(id) and records[id].look=="pipe":return
	smooth_pipe = StaticBody3D.new();smooth_pipe.name = "NativeSmoothPipe";add_child(smooth_pipe);var faces := PackedVector3Array();var count := 264
	for i in count:
		var a := deg_to_rad(-80+132.0*i/count);var b := deg_to_rad(-80+132.0*(i+1)/count)
		var p := Vector3(1.6*sin(a),1.9-1.6*cos(a),0);var q := Vector3(1.6*sin(b),1.9-1.6*cos(b),0)
		var corners := [p+Vector3(0,0,-.16),q+Vector3(0,0,-.16),q+Vector3(0,0,.16),p+Vector3(0,0,.16)]
		for k in [0,1,2,0,2,3]:faces.append(corners[k])
	var collision := CollisionShape3D.new();collision.shape = ConcavePolygonShape3D.new();collision.shape.backface_collision = true;collision.shape.set_faces(faces);smooth_pipe.add_child(collision);var pm := PhysicsMaterial.new();pm.friction = .5;pm.bounce = 0;smooth_pipe.physics_material_override = pm
	for rec in graph.bodies:
		if rec.look=="pipe":bodies[rec.id].collision_layer = 0
func toggle_input(id: String) -> void:
	if id=="Y":
		if threshold=="just":request_grain()
		else:repeat_take()
		return
	if running:return
	pending.erase("release_height");pending.variant = (variant+1)%3;rebuild_variant.call_deferred()
func reset_take() -> void:
	for id in grain_ids:
		if bodies.has(id):bodies[id].queue_free();bodies.erase(id);homes.erase(id);records.erase(id)
	grain_ids.clear();samples.clear();crossings.clear();growth.clear();reading.clear();maximum = -1;crossed = false;cross_height = -1;last_x = 0;last_drop = -9;calm = 0;over_energy = -1;grain_requested = false;feed_ready = false;super.reset_take();update_witness()
func release_take() -> void:
	if threshold=="almost":prepare_pipe()
	super.release_take()
	for rec in graph.bodies:
		if bodies.has(rec.id) and bodies[rec.id] is RigidBody3D:
			bodies[rec.id].linear_velocity = global_basis*v(rec.get("velocity",[0,0,0]));bodies[rec.id].angular_velocity = global_basis*v(rec.get("angular_velocity",[0,0,0]))
func update_inputs() -> void:
	super.update_inputs();set_button_label(setting_text())
	if not running:status.text = threshold.to_upper()+" / "+setting_text()+"\n"+("START, WAIT, ADD ONE GRAIN" if threshold=="just" else "CHANGE SETTING, THEN RELEASE")

func setting_text() -> String:
	var key: String = {"almost":"h","barely":"h","again":"k","just":"c","still":"d","descent":"T"}[threshold]
	var value := float(graph.params[key])
	match threshold:
		"almost","barely":return "h %.1f cm"%(value*100)
		"just":return "c %.2f grains"%value
		"still":return "d %+.3f mm"%(value*1000)
		"again":return "k %.1f /m"%value
	return "T %.2f"%value
func grain_count() -> int:
	var p := local_position(graph.refs.pan);var n := 0
	for id in graph.refs.get("grains",[])+grain_ids:
		var at := local_position(id)
		if absf(at.x-p.x)<.17 and absf(at.z-p.z)<.17 and at.y>p.y-.03 and at.y<p.y+.12:n+=1
	return n
func add_grain() -> void:
	var rec: Dictionary = graph.templates.grain;var id := "Grain"+str(grain_ids.size());var body := RigidBody3D.new();body.name = id;body.mass = rec.mass;body.position = local_position(graph.refs.pan)+Vector3(0,.17,.04);body.can_sleep = false;body.continuous_cd = true;body.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp_mode = RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp = -log(.99);body.angular_damp = -log(.9);body.gravity_scale = 9.82/9.8;body.collision_layer = 1;body.collision_mask = 1
	var pm := PhysicsMaterial.new();pm.friction = .3;pm.bounce = .05;body.physics_material_override = pm;add_child(body);bodies[id] = body;records[id] = rec;homes[id] = body.transform;grain_ids.append(id)
	var col := CollisionShape3D.new();col.shape = SphereShape3D.new();col.shape.radius = .028;body.add_child(col);var mesh := MeshInstance3D.new();mesh.mesh = SphereMesh.new();mesh.mesh.radius = .028;mesh.mesh.height = .056;mesh.material_override = mat("sandbag");body.add_child(mesh)
func _physics_process(dt: float) -> void:
	if not running:return
	elapsed += dt;var finished := false;var outcome := "undecided";var margin: Variant = null;var e: Dictionary = graph.extra
	if threshold=="just":
		var a := angle(graph.refs.beam);samples.append(a)
		if samples.size()>50:samples.pop_front()
		var slow := true
		for id in graph.refs.grains+grain_ids:
			if bodies[id].linear_velocity.length()>.1:slow = false
		feed_ready = samples.size()==50 and samples.max()-samples.min()<.0009 and slow and elapsed-last_drop>.4
		reading = {"grains":grain_count(),"angle":rad_to_deg(a),"threshold":e.c,"settled":feed_ready}
		if feed_ready:
			var n := grain_count();reading = {"grains":n,"angle":rad_to_deg(a),"threshold":e.c}
			if n>0 and a>0:finished = true;outcome = "tipped";margin = n-e.c;reading.outcome = outcome;reading.margin = margin
			elif n<40 and (auto_feed or grain_requested):add_grain();grain_requested = false;feed_ready = false;last_drop = elapsed;samples.clear()
	else:
		var id: String = graph.refs.ball;var p := local_position(id);var velocity: Vector3 = global_basis.inverse()*bodies[id].linear_velocity
		match threshold:
			"almost":
				var lip_x := 1.6*sin(deg_to_rad(52))
				if p.x>0 and not crossed:maximum = maxf(maximum,p.y)
				if cross_height<0 and p.x>lip_x:cross_height = p.y+.7*velocity.length_squared()/9.82
				if p.x>.3 and velocity.x< -.02 and not events.has("over"):crossed = true
				if p.x>lip_x+.05:mark("over")
				if crossed:mark("back")
				finished = events.has("over") or events.has("back");outcome = "over" if events.has("over") else "back";margin = ((cross_height if cross_height>=0 else maximum)-e.bottom)/(e.need-e.bottom)
			"barely":
				var t := deg_to_rad(tilt(graph.refs.block));var crit: float = deg_to_rad(e.crit);var mass: float = bodies[graph.refs.block].mass;var dg := Vector2(.06,.45).length();var barrier := mass*9.82*(dg-.45)
				if t<.5:maximum = maxf(maximum,t)
				if p.x> -.26:mark("hit")
				if over_energy<0 and t>crit:over_energy = .5*mass*(4*.06*.06+4*.45*.45)/3*bodies[graph.refs.block].angular_velocity.length_squared()
				if t>crit+.08:mark("fell")
				finished = events.has("fell") or events.has("hit") and elapsed-events.hit>2.5;outcome = "fell" if events.has("fell") else "stood";margin = 1+maxf(0,over_energy)/barrier if events.has("fell") else mass*9.82*(dg*cos(crit-maximum)-.45)/barrier
			"still":
				if absf(p.x)>.1:mark("right" if p.x>0 else "left")
				if p.y<.3 and absf(p.x)>1.95:mark("landed")
				finished = events.has("landed");outcome = "right" if events.has("right") else "left" if events.has("left") else "undecided";margin = events.get("right",events.get("left",null))
			"again":
				if last_x<0 and p.x>=0:crossings.append(elapsed)
				if last_x>0 and p.x<=0:mark("back")
				for m in [.1,.2,.4,.8]:
					if growth.size()==[.1,.2,.4,.8].find(m) and absf(p.x)>m:growth.append(elapsed)
				if absf(p.x)>e.span-.15 or p.y<e.Y0-1.3:mark("away" if e.k>.02 else "drift")
				last_x = p.x;finished = events.has("away") or events.has("drift") or crossings.size()>=2;outcome = "away" if events.has("away") else "drift" if events.has("drift") else "back";margin = crossings[-1]-crossings[-2] if crossings.size()>=2 else (growth[-1]-growth[0])/(growth.size()-1) if outcome=="away" and growth.size()>=3 else null
			"descent":
				var temperature: float = e.T0*maxf(0,1-elapsed/e.COOL)
				if temperature>0:
					var dv := sqrt(2*-log(.2)*temperature*dt)*randfn(0,1);bodies[id].apply_central_impulse(global_basis*Vector3(dv*bodies[id].mass,0,0));bodies[id].apply_torque_impulse(global_basis*Vector3(0,0,-dv/.1*bodies[id].inertia.z))
				calm = calm+dt if velocity.length()<.03 else 0
				finished = (elapsed>e.COOL or e.T0==0) and calm>.8;var best: Array = e.valleys[0]
				for valley in e.valleys:
					if absf(p.x-valley[0])<absf(p.x-best[0]):best = valley
				outcome = best[1];margin = p.y-.1
		reading = {"outcome":outcome,"margin":margin,"position":arr(p),"setting":graph.params}
	status.text = threshold.to_upper()+" / "+reading_text()+"\n"+("WAIT FOR NEEDLE" if threshold=="just" and not feed_ready else "+1 GRAIN WHEN READY" if threshold=="just" else setting_text())
	update_witness()
	if finished or elapsed>40 and (threshold!="just" or auto_feed):finish_reading(finished)
