extends "res://commons/artifacts/matter_reference/computing_board.gd"
const StageVisuals = preload("res://commons/artifacts/matter_reference/source_visuals.gd")
var physical := false
var rule := 90
var width := 41
var rows := 30
var wrap := false
var grid: Array = []
var row := 1
var column := 0
var stitched := 0
var computed := 0
var errors := 0
var jams := 0
var one_step := false
var finished := false
var phase := "ready"
var phase_time := 0.0
var pattern := 0
var wanted := 0
var seed_mode := "single"
var seed_values: Array = []
var rule_outputs: Dictionary = {}
var rule_tag: Label3D
var ball: RigidBody3D
var fabric: MultiMeshInstance3D
var carriage: Node3D
var stage_data: Dictionary
var dx := .24
var dy := .15
var x0 := -4.8
var top_y := 1.18
func apply_grid_config(config: Dictionary) -> void:
	physical = config.get("study","")=="gravity-knitter";rule = clampi(int(config.get("rule",90)),0,255);width = clampi(int(config.get("width",21 if physical else 41)),3,61);rows = clampi(int(config.get("rows",12 if physical else 30)),1,60);wrap = bool(config.get("wrap",false));var c := config.duplicate(true);c.kind = "ruleboard";super.apply_grid_config(c)
	seed_mode = str(config.get("seed_mode","single"));seed_values = config.get("seed",[]).duplicate()
func _ready() -> void:
	stage_data = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/matter_reference/"+("gravity-knitter" if physical else "rule-knitter")+"-stage.json"))
	if physical:
		super._ready()
	else:graph = {"bodies":[{"look":"floor","position":[0,-3.75,0],"shapes":[{"size":[60,.1,30]}]}]};build_controls()
	for part in stage_data.parts:
		# Gravity's native source bodies already render these same physical boxes.
		# Match imported body poses to remove only duplicated box-only mesh groups.
		if physical and part.meshes.size()==1 and part.meshes[0].type=="BoxGeometry":
			var p: Dictionary = part.meshes[0];var duplicate := false
			for rec in graph.bodies:
				if v(rec.position).distance_to(v(p.position))<.001:duplicate = true;break
			if duplicate:continue
		var host := Node3D.new();host.name = part.id;add_child(host);StageVisuals.append(host,part);remember(host,"Original "+stage_data.source+" / "+part.id)
		if part.ref=="carriage":carriage = host
		if not physical and part.meshes.size()==5 and part.meshes[4].type=="SphereGeometry":
			var p := 0
			for j in range(3):p = p*2+int(part.meshes[j].material.color!="f2f0f7")
			rule_outputs[p] = host.get_child(4)
		for child in host.get_children():
			if child is Label3D and child.text.begins_with("Rule "):rule_tag = child
	if carriage==null:carriage = Node3D.new();carriage.name = "Carriage";add_child(carriage)
	dx = .24 if physical else minf(.3,10.6/width);dy = .15 if physical else dx*.6;x0 = 4.75 if physical else -(width-1)*dx/2;top_y = 2.62 if physical else 1.18
	var temporary := Node3D.new();var stitch: Dictionary = stage_data.stitch.duplicate(true);stitch.merge({"position":[0,0,0],"quaternion":[0,0,0,1],"scale":[1,1,1],"material":{"color":"ffffff","roughness":.75,"metallic":0,"texture":"","repeat":[1,1],"alpha":1,"double":false}},true);StageVisuals.append(temporary,{"meshes":[stitch]})
	var fabric_root := Node3D.new();fabric_root.name = "Fabric";add_child(fabric_root)
	fabric = MultiMeshInstance3D.new();fabric.name = "Stitches";fabric.multimesh = MultiMesh.new();fabric.multimesh.transform_format = MultiMesh.TRANSFORM_3D;fabric.multimesh.use_colors = true;fabric.multimesh.mesh = temporary.get_child(0).mesh;fabric.multimesh.instance_count = (rows+1)*width;fabric_root.add_child(fabric);temporary.free()
	var yarn := StandardMaterial3D.new();yarn.vertex_color_use_as_albedo = true;yarn.roughness = .75;fabric.material_override = yarn;part_defaults.Fabric = {"label":"Source knitted fabric / live output","position":[0,0,0],"rotation":[0,0,0],"bounds":[x0,-rows*dy,0,width*dx,(rows+1)*dy,.1]}
	build_rule_selector();reset_take();apply_poses(pending);set_meta("void_preview_kind","Original knitting-machine scene recipes and V-shaped stitch geometry. Rule Knitter animates a direct rule lookup, as in the source. Gravity Knitter reads actual Jolt trough arrivals; three jams pause rather than silently substituting the mathematical answer. COMPUTE is an explicit separate source finish mode. Tall original machines can span storeys.")
func build_controls() -> void:console(["RULE","RUN","STEP","COMPUTE","CLEAR"],command)

func pattern_text(p: int) -> String:
	return str((p>>2)&1)+str((p>>1)&1)+str(p&1)

func build_rule_selector() -> void:
	var host := Node3D.new();host.name = "RuleSelector";host.position = get_node("Controls").position+Vector3(0,.83,0);add_child(host);box_mesh(host,Vector3(0,0,.02),Vector3(1.64,.68,.12),"dark")
	var names: Array = []
	for p in range(7,-1,-1):names.append("BIT_"+str(p))
	names.append_array(["SEED","EDGE"])
	for i in names.size():
		var key: String = names[i];var button := ButtonScene.instantiate();button.name = key;button.label = pattern_text(7-i) if i<8 else key;button.cube_size = .055;button.cap_color = Color("e45391");button.position = Vector3((i-3.5)*.19,.13,.13) if i<8 else Vector3((i-8.5)*.65,-.18,.13);host.add_child(button);buttons[key] = button;button.pressed.connect(command.bind(key));button.get_node("PushButton").selected_color = Color("9d86fe")
	finish_control_labels(host);remember(host,"Rule bits 111 to 000 / seed and boundary choices")

func sync_rule_controls() -> void:
	var bits := ""
	for p in range(7,-1,-1):
		var value: int = (rule>>p)&1;bits+=str(value)
		if buttons.has("BIT_"+str(p)):buttons["BIT_"+str(p)].get_node("PushButton").set_selected(bool(value))
		if rule_outputs.has(p):
			var output: MeshInstance3D = rule_outputs[p];var material: StandardMaterial3D = output.material_override.duplicate();material.albedo_color = Color("9d86fe" if value else "f2f0f7");output.material_override = material
	if is_instance_valid(rule_tag):rule_tag.text = "Rule "+str(rule)+" / "+bits
	button_text("RULE","RULE "+str(rule));button_text("SEED",seed_mode.to_upper());button_text("EDGE","WRAP" if wrap else "BLANK EDGE")
	if physical:
		for tray in graph.get("trays",[]):
			if not bodies.has(tray.id):continue
			var body: PhysicsBody3D = bodies[tray.id];body.rotation.x = deg_to_rad(18 if (rule>>int(tray.p))&1 else -18);PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
func command(id: String) -> void:
	match id:
		"RULE":rule = [90,30,110,184][([90,30,110,184].find(rule)+1)%4];reset_take()
		"RUN":
			if running:running = false;suspend_generated()
			else:
				if finished:reset_take()
				resume_generated();running = true
			one_step = false
		"STEP":
			if finished:reset_take()
			resume_generated();running = true;one_step = true
		"COMPUTE":finish_computed()
		"CLEAR":reset_take()
		"SEED":seed_mode = ["single","random","blank"][(["single","random","blank"].find(seed_mode)+1)%3];seed_values.clear();reset_take()
		"EDGE":wrap = not wrap;reset_take()
		_:
			if id.begins_with("BIT_"):rule = rule^(1<<int(id.trim_prefix("BIT_")));reset_take()
func reset_take() -> void:
	clear_generated();ball = null;grid.clear();var seed: Array = []
	for i in width:seed.append(int(seed_values[i])&1 if seed_values.size()==width else int(randf()>.5) if seed_mode=="random" else 0 if seed_mode=="blank" else int(i==floori(width*.5)))
	seed_values = seed.duplicate()
	grid.append(seed)
	for r in rows:grid.append([]);grid[-1].resize(width);grid[-1].fill(0)
	row = 1;column = 0;stitched = 0;computed = 0;errors = 0;jams = 0;finished = false;running = false;one_step = false;phase = "ready";phase_time = 0
	if is_instance_valid(fabric):update_fabric()
	sync_rule_controls()
func cell(r: int,c: int) -> int:
	if c<0 or c>=width:
		if not wrap:return 0
		c = posmod(c,width)
	return int(grid[r][c])
func current_column() -> int:return width-1-column if row%2==1 else column
func next_pattern() -> int:
	var c := current_column();return 4*cell(row-1,c-1)+2*cell(row-1,c)+cell(row-1,c+1)
func update_fabric() -> void:
	fabric.position.y = top_y-row*dy
	for r in range(rows+1):
		for c in width:
			var k := width-1-c if r%2==1 else c;var shown := finished or r==0 or r<row or r==row and k<column;var scale := dx/.42 if shown else .00001
			fabric.multimesh.set_instance_transform(r*width+c,Transform3D(Basis.IDENTITY.scaled(Vector3(scale,scale*.95,scale)),Vector3(x0+c*dx,r*dy,.05)));fabric.multimesh.set_instance_color(r*width+c,Color("6a4fd3") if int(grid[r][c]) else Color("eeeaf4"))
func finish_computed() -> void:
	running = false;clear_generated();ball = null
	while row<=rows:
		var c := current_column();grid[row][c] = (rule>>next_pattern())&1;computed+=1;column+=1
		if column>=width:column = 0;row+=1
	finished = true;update_fabric()
func start_cell() -> void:
	pattern = next_pattern();wanted = (rule>>pattern)&1;phase = "set";phase_time = 0
	if physical:
		for flap in graph.flaps:
			var bit := (pattern>>(2-int(flap.level)))&1;var p: Dictionary = flap.poses[bit];var b: PhysicsBody3D = bodies[flap.id];b.position = Vector3(p.x,p.y,0);b.rotation.z = p.angle;PhysicsServer3D.body_set_state(b.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,b.global_transform)
		for tray in graph.trays:
			var b: PhysicsBody3D = bodies[tray.id];b.rotation.x = deg_to_rad(18 if (rule>>int(tray.p))&1 else -18);PhysicsServer3D.body_set_state(b.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,b.global_transform)
func commit(bit: int) -> void:
	grid[row][current_column()] = bit
	if bit!=wanted:errors+=1
	stitched+=1;column+=1
	if column>=width:column = 0;row+=1
	if row>rows:finished = true;running = false
	phase = "ready";phase_time = 0;update_fabric()
	if one_step:running = false
func _physics_process(dt: float) -> void:
	status.text = ("GRAVITY" if physical else "RULE")+" KNITTER / "+str(rule)+" / ROW "+str(row)+"\nPHYSICAL "+str(stitched if physical else 0)+" / COMPUTED "+str(computed)+" / JAMS "+str(jams)
	button_text("RUN","RESTART" if finished else "PAUSE" if running else "RUN")
	if not running or finished:return
	phase_time += dt
	if phase=="ready":start_cell();return
	if is_instance_valid(carriage):carriage.position.x = lerpf(carriage.position.x,x0+current_column()*dx,minf(1,dt*8))
	if not physical:
		if phase_time>.35:commit(wanted)
		return
	if phase=="set" and phase_time>.35:ball = make_dynamic("marble");phase = "roll";phase_time = 0
	elif phase=="roll" and is_instance_valid(ball):
		var p := to_local(ball.global_position);var c: Dictionary = graph.constants
		if p.x>c.SENSOR_X and p.y<c.yRule:
			var bit := int(p.z>0);generated.erase(ball);ball.queue_free();ball = null;commit(bit)
		elif p.y<c.troughY0-(c.troughX1-c.troughX0)*tan(c.GAMMA)-.3 or phase_time>14:
			jams+=1;generated.erase(ball);ball.queue_free();ball = null;phase = "set";phase_time = 0
			if jams>=3:running = false
