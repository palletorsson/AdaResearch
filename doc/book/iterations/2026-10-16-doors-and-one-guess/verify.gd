extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-doors-and-one-guess/"
const Objects=preload("res://commons/artifacts/ordinary_entropies/objects.gd")
const Model=preload("res://commons/artifacts/ordinary_entropies/guess_model.gd")
const Entropy=preload("res://commons/artifacts/ordinary_entropies/model.gd")
var checks: Array=[]
var failures: Array=[]
var stage: Node3D
var camera: Camera3D

func _initialize() -> void:run.call_deferred()
func check(title: String,passed: bool) -> void:
	checks.append({"name":title,"passed":passed})
	if not passed:failures.append(title);print("FAIL ",title)
func press(button: Node3D) -> void:
	var area=button.get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
	await process_frame
	await process_frame
func snapshot(name_text: String,eye: Vector3,target: Vector3,fov: float=62) -> void:
	camera.position=eye;camera.look_at(target);camera.fov=fov
	await create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+name_text+".png")

func run() -> void:
	root.size=Vector2i(1600,1000)
	stage=Node3D.new();root.add_child(stage)
	var environment=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR;environment.environment.background_color=Color("b8c1bd")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.environment.ambient_light_color=Color.WHITE;environment.environment.ambient_light_energy=0.65;stage.add_child(environment)
	var sun=DirectionalLight3D.new();stage.add_child(sun);sun.rotation_degrees=Vector3(-55,-30,0);sun.light_energy=0.8
	Objects.box(stage,Vector3(0,-0.055,0),Vector3(40,0.1,30),Color("d4cfc2"),true)
	camera=Camera3D.new();stage.add_child(camera);camera.current=true
	var doors=load("res://commons/artifacts/ordinary_entropies/entropy_door_dynamics.tscn").instantiate()
	stage.add_child(doors)
	await process_frame
	check("door study starts still at zero",doors.step_index==0 and not doors.is_processing())
	check("shared step advances both leaves and records",doors.trace(false).size()==1 and doors.trace(true).size()==1)
	await press(doors.buttons.STEP)
	check("canonical XR/desktop button advances shared step",doors.step_index==1)
	check("halving halves initial gap",is_equal_approx(absf(doors.trace(false)[-1]-doors.trace(false,true)[-1]),1.0/1024))
	check("doubling doubles initial gap before wrapping",is_equal_approx(absf(doors.trace(true)[-1]-doors.trace(true,true)[-1]),1.0/256))
	for n in range(1,17):
		check("finite expanding words "+str(n),is_equal_approx(Entropy.word_entropy(n,true),minf(n,10)))
		check("finite contracting words "+str(n),is_equal_approx(Entropy.word_entropy(n,false),1))
	doors.advance_doors(7)
	check("eight symbols at step seven",doors.trace(true).size()==8)
	await snapshot("doors-eight-symbols",Vector3(0,2.4,11),Vector3(0,1.1,0),88)
	await snapshot("door-control",Vector3(2.25,1.35,2.3),Vector3(2.25,1.20,0.2),65)
	await snapshot("door-history",Vector3(-4.5,1.4,4.8),Vector3(-4.5,0.8,1.8),67)
	doors.advance_doors(9)
	check("dyadic offset rejoins after wrapping",is_equal_approx(doors.trace(true)[-1],doors.trace(true,true)[-1]))
	var receipt: Dictionary=doors.capture()
	await press(doors.buttons["GAP +"])
	check("changing gap resets the shared clock",doors.step_index==0 and doors.gap_index==3)
	check("door record restores exact trace",doors.restore(JSON.parse_string(JSON.stringify(receipt))) and doors.capture()==receipt)
	var broken: Dictionary=receipt.duplicate(true);broken.step=99
	check("invalid door record rejected without mutation",not doors.restore(broken) and doors.capture()==receipt)
	doors.gap_index=0;doors.advance_doors(15)
	check("identical starts remain identical under both rules",doors.trace(false)==doors.trace(false,true) and doors.trace(true)==doors.trace(true,true))
	await press(doors.buttons.STEP)
	check("last step waits rather than silently looping",doors.step_index==15)
	await press(doors.buttons.RESET)
	check("reset retains chosen gap",doors.step_index==0 and doors.gap_index==0)
	stage.remove_child(doors);doors.free()
	var study=load("res://commons/artifacts/ordinary_entropies/entropy_ball_pit.tscn").instantiate()
	stage.add_child(study);await physics_frame
	check("four tables each retain sixteen chairs",study.versions.size()==4 and study.versions.all(func(t):return t.chairs.size()==16))
	var a=study.versions[0];var b=study.versions[1];var c=study.versions[2];var d=study.versions[3]
	check("two-type baseline Hmin=H=1",a.model.readings().min==1 and a.model.readings().shannon==1)
	check("three types same Hmin, larger Shannon",b.model.readings().min==1 and b.model.readings().shannon==1.5)
	check("recording only colour erases the type distinction",b.model.readings().colour_shannon==1)
	check("three-quarter chance exact",c.model.readings().best==0.75 and absf(c.model.readings().min-0.4150374993)<1e-8)
	check("all-pink colour is certain",d.model.readings().best==1 and d.model.readings().min==0 and d.model.readings().shannon==0)
	var before=a.model.capture()
	await press(a.buttons.DRAW)
	check("a draw requires a prior guess and consumes no RNG otherwise",a.model.capture()==before)
	await press(a.buttons.BLACK);await press(a.buttons.DRAW)
	check("button path selects and reveals a chair",a.model.guess==1 and a.model.selected>=0 and a.model.draws==1 and a.markers[a.model.selected].visible)
	check("returned chair leaves category counts unchanged",a.model.counts()==[8,8,0])
	await press(b.buttons["BLACK+ARMS"]);await press(b.buttons.DRAW)
	check("third category can be guessed",b.model.guess==2 and b.model.draws==1)
	await snapshot("four-chair-tables",Vector3(0,3.5,10),Vector3(0,0.8,0),86)
	await snapshot("two-type-table",a.position+Vector3(0,1.7,3.5),a.position+Vector3(0,0.7,0),57)
	await snapshot("three-type-table",b.position+Vector3(0,1.7,3.5),b.position+Vector3(0,0.7,0),57)
	var selected_ids: Array=[]
	var replay=Model.new();check("model JSON restore accepted",replay.restore(JSON.parse_string(JSON.stringify(b.model.capture()))))
	for i in 32:
		b.model.draw();replay.draw();selected_ids.append(b.model.selected)
		check("stored RNG state preserves next ID "+str(i),b.model.selected==replay.selected)
	await press(c.buttons["CHANGE ONE"])
	check("change one preserves sixteen IDs, changes probabilities",c.model.counts()==[13,3,0] and c.model.readings().best==13.0/16)
	await press(c.buttons.RESET)
	check("reset restores population and source",c.model.counts()==[12,4,0] and c.model.draws==0)
	await press(d.buttons.PINK)
	var entropy_before: Dictionary=d.model.readings()
	var chair=d.chairs[0]
	chair.on_desktop_grab(null);chair.position=Vector3(0.7,1.1,0.6);chair.rotation.y=1.2
	await press(d.buttons.RESET)
	check("reset cannot destroy a held chair",d.chairs[0]==chair and chair.held())
	chair.on_desktop_drop(null);await process_frame;await physics_frame
	check("chair drops onto its own table with its turn retained",is_equal_approx(chair.position.y,0.75) and is_equal_approx(chair.rotation.y,1.2))
	check("rearrangement does not change the declared distribution",d.model.readings()==entropy_before)
	await press(d.buttons.DRAW)
	check("rearranged all-pink table still returns pink",d.model.categories[d.model.selected]==0)
	var saved: Dictionary=d.capture()
	await press(d.buttons.RESET)
	var restored_ok: bool=d.restore(JSON.parse_string(JSON.stringify(saved,"",true,true)))
	var restored_table: Dictionary=d.capture()
	var pose_match:=true
	for i in 16:
		for j in 4:pose_match=pose_match and absf(saved.poses[i][j]-restored_table.poses[i][j])<0.000001
	check("table JSON receipt restores positions and generator",restored_ok and pose_match and restored_table.model==saved.model)
	broken=saved.duplicate(true);broken.poses[0][0]=INF
	check("invalid position rejected before changing model",not d.restore(broken) and d.capture()==restored_table)
	await snapshot("certain-chairs-moved",d.position+Vector3(0,1.7,3.5),d.position+Vector3(0,0.7,0),57)
	var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"saved_table":saved,"draw_ids_after_restore":selected_ids,"scope":"Native model, canonical button events, desktop carry/drop and render checks. No human headset trial."}
	var file=FileAccess.open(DIR+"report.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	print("DOORS AND ONE GUESS: ",checks.size()," checks; failures=",failures.size())
	stage.queue_free();await process_frame
	quit(0 if failures.is_empty() else 1)
