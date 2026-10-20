extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-entropy-visible-states/"
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
	for kind in 7:
		var exhibit: Node3D=load("res://commons/artifacts/ordinary_entropies/"+IDS[kind]+".tscn").instantiate()
		stage.add_child(exhibit);await process_frame
		check("simultaneous version count "+str(kind),exhibit.versions.size()==[4,3,1,3,3,3,3][kind])
		check("no button areas "+str(kind),exhibit.find_children("*","Area3D",true,false).is_empty())
		check("one wall explanation "+str(kind),exhibit.wall_text!=null and exhibit.wall_text.get_child_count()==4)
		var contained:=true
		for label in exhibit.wall_text.get_children():
			if label is Label3D:
				var bounds: AABB=label.get_aabb()
				contained=contained and bounds.position.x+label.position.x>=-0.80 and bounds.end.x+label.position.x<=0.80 and bounds.position.y+label.position.y>=-0.49 and bounds.end.y+label.position.y<=0.49
		check("wall text contained "+str(kind),contained)
		for copy in exhibit.versions:
			check("normal scale, no console, visible version "+str(kind),copy.scale==Vector3.ONE and copy.console==null and copy.visible)
			var receipt: Dictionary=copy.capture();var before:=poses(copy)
			copy.experiment_seed=999;copy.rebuild()
			check("research reconstructs version "+str(kind),copy.restore(receipt) and poses(copy)==before)
		if kind==0:
			var counts: Array=[]
			for copy in exhibit.versions:
				var n:=0
				for chair in copy.visuals.get_children():
					if chair.has_meta("pink") and chair.get_meta("pink"):n+=1
				counts.append(n)
			check("four actual chair inventories",counts==[4,4,7,8])
		if kind==3:
			exhibit.automatic=false;exhibit.advance_doors(0)
			var initial:=absf(exhibit.versions[1].hinges[0].rotation.y-exhibit.versions[1].hinges[1].rotation.y)
			exhibit.advance_doors(8)
			var contracting: float=absf(exhibit.versions[0].hinges[0].rotation.y-exhibit.versions[0].hinges[1].rotation.y)
			var expanding: float=absf(exhibit.versions[1].hinges[0].rotation.y-exhibit.versions[1].hinges[1].rotation.y)
			check("doors reveal contraction and divergence",contracting<initial and expanding>initial)
			check("third door remains open",exhibit.versions[2].setting==2 and is_equal_approx(exhibit.versions[2].hinges[0].rotation.y,-PI/2))
		if kind==4:
			check("simultaneous cooling times",exhibit.versions[0].seconds==0 and exhibit.versions[1].seconds==15 and exhibit.versions[2].seconds==60)
		if kind==5:
			check("same identity across record channels",exhibit.versions.all(func(v):return v.selected==3))
			check("three distinct glass channels",exhibit.versions[0].setting==0 and exhibit.versions[1].setting==1 and exhibit.versions[2].setting==2)
		stage.remove_child(exhibit);exhibit.free()
	var result:={"checks":checks,"failures":failures,"passed":failures.is_empty()}
	var file:=FileAccess.open(DIR+"verification.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	print("Visible states: ",checks.size()," checks; ",failures.size()," failures")
	stage.queue_free();await process_frame;quit(0 if failures.is_empty() else 1)
