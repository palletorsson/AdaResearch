extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-ordinary-entropies/"
const Model=preload("res://commons/artifacts/ordinary_entropies/model.gd")
const Objects=preload("res://commons/artifacts/ordinary_entropies/objects.gd")
const IDS=["entropy_chairs_shannon","entropy_chairs_boltzmann","entropy_chairs_description","entropy_door_dynamics","entropy_cooling_cup","entropy_frosted_chair","entropy_ball_pit"]
var checks: Array=[]
var failures: Array=[]
var camera: Camera3D
var stage: Node3D
func _initialize() -> void:run.call_deferred()
func check(name_text: String, passed: bool) -> void:
	checks.append({"name":name_text,"passed":passed})
	if not passed:failures.append(name_text);print("FAIL ",name_text)
func press(bench: Node3D,key: String) -> void:
	var area: Node=bench.buttons[key].get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
	await process_frame
	await process_frame
func poses(bench: Node3D) -> Array:
	var result: Array=[]
	for node in bench.visuals.find_children("*","MeshInstance3D",true,false):result.append(node.global_transform)
	return result
func shot(name_text: String,kind: int) -> void:
	camera.position=Vector3(-1 if kind==3 else 0,2.8,6.4 if kind!=2 else 10.2)
	camera.look_at(Vector3(-1 if kind==3 else 0,1.2,0));camera.fov=72 if kind==2 else 62
	await create_timer(0.15).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+name_text+".png")
func run() -> void:
	root.size=Vector2i(1600,1050)
	stage=Node3D.new();root.add_child(stage)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("bdc5c3")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=0.35;stage.add_child(environment)
	var sun:=DirectionalLight3D.new();stage.add_child(sun);sun.rotation_degrees=Vector3(-60,-30,0);sun.light_energy=0.7
	Objects.box(stage,Vector3(0,-0.06,0),Vector3(30,0.1,30),Color("d4cfc2"))
	camera=Camera3D.new();stage.add_child(camera);camera.current=true
	check("binary Shannon balanced 1 bit",is_equal_approx(Model.shannon([4,4]),1))
	check("certain colour has zero entropy",is_zero_approx(Model.shannon([8,0])))
	check("biased colour entropy below one",Model.shannon([7,1])<1 and Model.shannon([7,1])>0)
	var distribution: Array=[0,0,0,0,0]
	for mask in 256:
		var total:=0;var left:=0
		for bit in 8:
			if mask&(1<<bit):total+=1;left+=int(bit<4)
		if total==4:distribution[left]+=1
	check("independent enumeration yields 1 16 36 16 1",distribution==[1,16,36,16,1])
	for k in 5:check("multiplicity k="+str(k),Model.multiplicity(k)==distribution[k])
	for n in range(1,9):
		check("expanding word entropy n="+str(n),is_equal_approx(Model.word_entropy(n,true),float(n)))
		check("contracting words do not keep branching n="+str(n),is_equal_approx(Model.word_entropy(n,false),1))
	var previous:=0.0
	for t in range(0,61,5):
		var heat:=Model.thermal(t)
		check("closed thermal energy t="+str(t),absf(heat.energy-(400*353+4000*293))<0.00001)
		check("total entropy monotonic t="+str(t),heat.total>=previous-0.000001)
		previous=heat.total
	check("cup loses entropy while surroundings gain",Model.thermal(30).hot_entropy<0 and Model.thermal(30).cold_entropy>0)
	for mode in 3:check("conditional channel mode="+str(mode),is_equal_approx(Model.conditional(mode),[0.0,2.0,3.0][mode]))
	check("uniform ID min entropy 4 bits",is_equal_approx(Model.min_entropy(Model.pit_probabilities(0)),4))
	check("common colour min entropy below 0.1 bit",Model.min_entropy(Model.pit_probabilities(1))<0.1)
	check("weighted large ball min entropy 1 bit",is_equal_approx(Model.min_entropy(Model.pit_probabilities(2)),1))
	check("same seed reconstructs all chair poses",Model.chairs(435,3)==Model.chairs(435,3))
	check("new seed changes scatter",Model.chairs(435,3)!=Model.chairs(436,3))
	var saved: Array=[]
	for kind in 7:
		var bench: Node3D=load("res://commons/artifacts/ordinary_entropies/"+IDS[kind]+".tscn").instantiate()
		bench.pointer_prefix="user://ordinary-test-%d-" % Time.get_ticks_usec();stage.add_child(bench)
		for frame in 4:await process_frame
		check("kind and native controls "+str(kind),bench.kind==kind and bench.buttons.size()>=4)
		await press(bench,["7 TO 1","MIXED","SHOW RECIPE","EXPAND","+5 SECONDS","FROSTED","WEIGHT BIG"][kind])
		if kind==3:
			for step in 8:await press(bench,"STEP")
		if kind==4:
			for step in 5:await press(bench,"+5 SECONDS")
		if kind in [0,6]:await press(bench,"DRAW")
		var record: Dictionary=bench.capture();var original:=poses(bench);saved.append(record)
		var path: String=bench.keep()
		check("disk keep "+str(kind),FileAccess.file_exists(path))
		await shot(IDS[kind],kind)
		bench.setting=0;bench.steps=0;bench.seconds=0;bench.experiment_seed=436;bench.rebuild()
		await press(bench,"REPLAY")
		check("physical replay state "+str(kind),bench.capture()==record)
		check("physical replay geometry "+str(kind),poses(bench)==original)
		var wrong: Dictionary=record.duplicate();wrong.kind=(kind+1)%7
		check("wrong encounter rejected "+str(kind),not bench.restore(wrong) and bench.capture()==record)
		wrong=record.duplicate();wrong.seconds=-1
		check("invalid record rejected "+str(kind),not bench.restore(wrong) and bench.capture()==record)
		var fresh: Node3D=load("res://commons/artifacts/ordinary_entropies/"+IDS[kind]+".tscn").instantiate()
		fresh.pointer_prefix=bench.pointer_prefix;stage.add_child(fresh)
		for frame in 4:await process_frame
		check("fresh scene replay "+str(kind),fresh.replay() and fresh.capture()==record)
		fresh.visible=false;bench.visible=false
		fresh.position.x=100+kind*20;bench.position.x=110+kind*20
	# Exercise removal after deferred console construction and rendering have settled.
	for frame in 8:await process_frame
	for node in stage.get_children():
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("ordinary_entropies/encounter.gd"):node.queue_free()
	for frame in 8:await process_frame
	check("all encounter nodes release after deferred construction",stage.get_children().all(func(node):return node.get_script()==null or not str(node.get_script().resource_path).ends_with("ordinary_entropies/encounter.gd")))
	var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Native rendered controls, exact finite models, persistence and reconstruction; no human or headset acceptance."}
	var file:=FileAccess.open(DIR+"verification.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"\t"));file.close()
	file=FileAccess.open(DIR+"records.json",FileAccess.WRITE);file.store_string(JSON.stringify(saved,"\t"));file.close()
	print("ORDINARY ENTROPIES ",checks.size()," checks failures=",failures)
	for frame in 5:await process_frame
	await create_timer(0.25).timeout
	quit(0 if failures.is_empty() else 1)
