extends "res://commons/artifacts/matter_reference/computing_board.gd"
const Nat = preload("res://commons/artifacts/matter_reference/natural_number.gd")
const SourceVisuals = preload("res://commons/artifacts/matter_reference/source_visuals.gd")
var study := "collatz-marble-machine"
var n0 := "27"
var n := "27"
var values: Array[String] = []
var parity: Array[int] = []
var digit_rows: Array = []
var marks: Array[int] = []
var step_index := 0
var page := 0
var method := "yo"
var stopped := false
var stage: Dictionary
var marble: Node3D
var phase := "approach"
var phase_t := 0.0
var route := "even"
var exponent := 1.0/3
var panels: Array[Node3D] = []
var value_label: Label3D
var cloth: MultiMeshInstance3D
func apply_grid_config(config: Dictionary) -> void:pending = config.duplicate(true);study = str(config.get("study",study));n0 = Nat.clean(str(config.get("start","7" if study=="collatz-knitting" else "27")));n0 = "1" if n0=="0" else n0
func _ready() -> void:
	graph = {"bodies":[{"look":"floor","position":[0,-.39,0],"shapes":[{"size":[1,.1,1]}]}]}
	if study=="collatz-marble-machine":
		stage = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/matter_reference/collatz-marble-machine-stage.json"))
		for part in stage.parts:
			var host := Node3D.new();host.name = part.id;add_child(host);SourceVisuals.append(host,part);remember(host,"Original Collatz machine / "+part.id)
		marble = Node3D.new();marble.name = "Marble";add_child(marble)
		var sphere := MeshInstance3D.new();sphere.mesh = SphereMesh.new();sphere.mesh.radius = 1;sphere.mesh.height = 2;sphere.material_override = mat("marble");marble.add_child(sphere)
		var key := MeshInstance3D.new();key.mesh = CylinderMesh.new();key.mesh.top_radius = .27;key.mesh.bottom_radius = .27;key.mesh.height = .62;key.position.z = 1.05;key.rotation.x = PI/2;key.material_override = mat("stop");marble.add_child(key)
		var stripe := MeshInstance3D.new();stripe.mesh = TorusMesh.new();stripe.mesh.inner_radius = 1.003-.035;stripe.mesh.outer_radius = 1.003+.035;stripe.rotation.z = PI/2;stripe.material_override = mat("back");marble.add_child(stripe)
		remember(marble,"Source keyed marble / live arithmetic state")
		build_cloth()
	console(["START","METHOD","PAGE","CLEAR"] if study=="collatz-knitting" else ["START","RUN","STEP","FINISH","CLEAR"],command)
	value_label = Label3D.new();value_label.name = "Value";value_label.position = Vector3(0,1.8,1);value_label.font_size = 40;value_label.pixel_size = .002;add_child(value_label)
	reset_take();apply_poses(pending);set_meta("void_preview_kind","Original Collatz scene mesh recipes and sampled source paths; explicit kinematic transforms as in Three.js, not a Jolt marble simulation. Arbitrary-precision decimal integers preserve BigInt arithmetic. Knitting translates the source's written pattern, parity punch card and base-six automaton into editable display panels.")
func build_cloth() -> void:
	var holder := Node3D.new();var stitch: Dictionary = stage.stitch.duplicate(true);stitch.merge({"position":[0,0,0],"quaternion":[0,0,0,1],"scale":[1,1,1],"material":{"color":"ffffff","roughness":.75,"metallic":0,"texture":"","repeat":[1,1],"alpha":1,"double":false}},true);SourceVisuals.append(holder,{"meshes":[stitch]})
	var anchor := Node3D.new();anchor.name = "KnittedParity";add_child(anchor);cloth = MultiMeshInstance3D.new();cloth.multimesh = MultiMesh.new();cloth.multimesh.transform_format = MultiMesh.TRANSFORM_3D;cloth.multimesh.use_colors = true;cloth.multimesh.mesh = holder.get_child(0).mesh;cloth.multimesh.instance_count = 288;anchor.add_child(cloth);holder.free();var material := StandardMaterial3D.new();material.vertex_color_use_as_albedo = true;cloth.material_override = material
	part_defaults.KnittedParity = {"label":"Source Collatz parity fabric","position":[0,0,0],"rotation":[0,0,0],"bounds":[.7,-.1,-7.3,10,3,.2]}
func prepare_editor_preview() -> void:
	if study!="collatz-marble-machine":return
	parity.clear()
	for i in mini(values.size()-1,288):parity.append(int(Nat.odd(values[i])))
	update_cloth();set_meta("void_preview_kind","Source Collatz stage with a completed parity-fabric preview. Native gameplay starts empty and fills it one gate reading at a time. The keyed marble uses explicit source kinematic transforms, not Jolt gravity.")
func update_cloth() -> void:
	if not is_instance_valid(cloth):return
	cloth.position = Vector3(0,2.85-floori(parity.size()/24.0)*.24,-7.1)
	for i in 288:
		var row := i/24;var col := 23-i%24 if row%2==0 else i%24;var scale := 1.0 if i<parity.size() else .00001
		cloth.multimesh.set_instance_transform(i,Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale),Vector3(.77+col*.42,row*.24,0)));cloth.multimesh.set_instance_color(i,Color("6a4fd3") if i<parity.size() and parity[i] else Color("eeeaf4"))
func command(id: String) -> void:
	match id:
		"START":n0 = ["7","27","97","6171"][(["7","27","97","6171"].find(n0)+1)%4];reset_take()
		"RUN":
			if stopped:reset_take()
			running = not running;step_once = false
		"STEP":
			if study=="collatz-knitting":page+=1;build_cards()
			else:
				if stopped:reset_take()
				step_once = true;running = true
		"FINISH":
			while step_index<values.size()-1:commit_step()
			stopped = true;running = false;build_cards()
		"PAGE":page+=1;build_cards()
		"METHOD":method = "kfbf" if method=="yo" else "yo";build_cards()
		"CLEAR":reset_take()
var step_once := false
func reset_take() -> void:
	values = Nat.trajectory(n0);n = n0;parity.clear();step_index = 0;page = 0;stopped = false;running = false;step_once = false;phase = "approach";phase_t = 0;var peak_log := 0.0
	for value in values:peak_log = maxf(peak_log,Nat.logarithm(value))
	exponent = minf(1.0/3,log(.8/.14)/log(2.0)/peak_log) if peak_log>0 else 1.0/3
	build_base_six();build_cards()
	update_cloth()
func build_base_six() -> void:
	var evens := 0;var peak_digits := 1
	for value in values:
		if not Nat.odd(value):evens+=1
		peak_digits = maxi(peak_digits,Nat.digits(value).size())
	var width := evens+peak_digits+2;var cur: Array = Nat.digits(values[0]);cur.resize(width)
	for i in width:
		if cur[i]==null:cur[i] = 0
	digit_rows = [cur];marks = [0];var mark := 0
	for i in values.size()-1:
		var odd := int(cur[mark])%2==1;var next: Array = []
		for q in width:next.append(3*(int(cur[q])&1)+(int(cur[q-1])>>1 if q>0 else 0))
		if odd:next[mark]+=1
		else:mark+=1
		digit_rows.append(next);marks.append(mark);cur = next
func build_cards() -> void:
	for panel in panels:
		if is_instance_valid(panel):part_defaults.erase(str(panel.name));panel.free()
	panels.clear()
	if study=="collatz-marble-machine":return
	var from := (page%maxi(1,ceili(values.size()/12.0)))*12
	var text := "COLLATZ / "+n0+" / PAGE "+str(page+1)+"\nCast on "+n0+" stitches.\n"
	for i in range(maxi(1,from),mini(values.size(),from+12)):
		var previous: String = values[i-1];var rs := i%2==1;var instruction: String
		if not Nat.odd(previous):instruction = ("K2tog" if rs else "P2tog")+" to end"
		else:
			var increase: String = ("(k1, yo, k1)" if rs else "(p1, yo, p1)") if method=="yo" else ("kfbf" if rs else "pfbf")
			instruction = "["+increase+"] "+Nat.add(previous,-1)+" times, "+("M1" if rs else "M1P")+", repeat in last stitch"
		text+=str(i)+" / "+("RS" if rs else "WS")+" / "+instruction+" -> "+values[i]+"\n"
	var pattern := Node3D.new();pattern.name = "WrittenPattern";pattern.position = Vector3(-4,1.9,0);add_child(pattern);box_mesh(pattern,Vector3.ZERO,Vector3(4,3.1,.08),"back");var label := Label3D.new();label.text = text;label.position = Vector3(0,0,.06);label.font_size = 24;label.pixel_size = .0011;pattern.add_child(label);panels.append(pattern);remember(pattern,"Original written knitting instructions / paged")
	for type in ["PunchCard","BaseSix"]:
		var host := Node3D.new();host.name = type;host.position = Vector3(.5 if type=="PunchCard" else 5,1.9,0);add_child(host);box_mesh(host,Vector3.ZERO,Vector3(4.2,3.1,.08),"back")
		if type=="PunchCard":
			var width := 24;var count := mini(values.size()-1,288);var offset := (page%maxi(1,ceili((values.size()-1)/288.0)))*288
			for k in count:
				var i := offset+k
				if i>=values.size()-1:break
				var r := k/width;var c := width-1-k%width if r%2==0 else k%width;box_mesh(host,Vector3(-1.9+c*.16,1.15-r*.16,.06),Vector3(.14,.14,.04),"rocker" if Nat.odd(values[i]) else "track")
		else:
			var max_columns := mini(digit_rows[0].size(),24)
			for i in range(from,mini(digit_rows.size(),from+12)):
				for q in max_columns:
					var bit: int = digit_rows[i][q];var m := StandardMaterial3D.new();m.albedo_color = Color(["eeeaf4","6a4fd3","e45392","008a7b","a36600","436ac8"][bit]);box_mesh(host,Vector3(-1.9+q*.16,1.15-(i-from)*.2,.06),Vector3(.14,.18,.04),"track");host.get_child(-1).material_override = m
		panels.append(host);remember(host,"Original "+type+" / paged source data")
	apply_poses(pending)
func commit_step() -> void:
	if step_index>=values.size()-1:return
	parity.append(int(Nat.odd(values[step_index])));step_index+=1;n = values[step_index];update_cloth()
func path_point(name: String,t: float) -> Vector3:
	var points: Array = stage.paths[name];var f := clampf(t,0,1)*(points.size()-1);var i := mini(floori(f),points.size()-2);return v(points[i]).lerp(v(points[i+1]),f-i)
func _physics_process(dt: float) -> void:
	status.text = "COLLATZ / START "+n0+" / STEP "+str(step_index)+"\n"+(method.to_upper()+" / PAGE "+str(page+1) if study=="collatz-knitting" else "HALTED" if stopped else ("RUNNING / " if running else "PAUSED / ")+phase);value_label.text = "n = "+n
	button_text("RUN","RESTART" if stopped else "PAUSE" if running else "RUN")
	if study=="collatz-knitting":return
	var r := .14*pow(2,exponent*Nat.logarithm(n));marble.scale = Vector3.ONE*r;marble.position = path_point(phase if stage.paths.has(phase) else route,clampf(phase_t/2,0,1))+Vector3(0,.045+r,0)
	if not running or stopped:return
	phase_t+=dt
	if phase=="even" or phase=="odd":
		if phase_t>=1 and phase_t-dt<1:
			if phase=="even":n = Nat.divide(n,2).quotient
			else:n = Nat.multiply(n,3)
		if phase=="odd" and phase_t>=1.5 and phase_t-dt<1.5:n = Nat.add(n,1)
	if phase_t<2:return
	phase_t = 0
	match phase:
		"approach":phase = "drop" if n=="1" else "toRotor"
		"toRotor":marble.rotation.y = PI if Nat.odd(n) else 0;phase = "toGate"
		"toGate":route = "odd" if Nat.odd(n) else "even";phase = route
		"even","odd":commit_step();phase = "ret"
		"ret":phase = "approach"
		"drop":stopped = true;running = false
	if step_once and phase=="ret":step_once = false;running = false
