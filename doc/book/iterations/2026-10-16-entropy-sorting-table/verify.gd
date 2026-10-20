extends SceneTree
const Model = preload("res://commons/artifacts/entropy_sorting_table/sorting_model.gd")
var checks := []
var failures := []
func _initialize() -> void: run.call_deferred()
func check(text: String, ok: bool) -> void:
	checks.append({"name":text,"passed":ok})
	if not ok: failures.append(text)
	print("[sorting] ","PASS " if ok else "FAIL ",text)
func press(table: Node3D) -> void:
	var area=table.button.get_node("InteractableAreaButton")
	area.button_pressed.emit(area); area.button_released.emit(area)
func run() -> void:
	var m=Model.new()
	for stage in 4:
		m.stage=stage
		check("alternating baseline stage "+str(stage),m.arrangements().size()==[6,4,2,1][stage])
	m.exchange(1,2)
	for stage in 4:
		m.stage=stage
		check("sorted baseline stage "+str(stage),m.arrangements().size()==[6,1,1,1][stage])
	# Independent binomial counts for every arrangement and partition.
	for order in [[0,2,1,3],[0,1,2,3],[0,1,3,2],[1,0,2,3],[1,0,3,2],[1,3,0,2]]:
		m.occupants=order
		var last:=7
		for stage in 4:
			m.stage=stage
			var ways: Array=m.arrangements()
			var expected:=1
			for box in range(stage+1):
				var n: int=Model.PARTITIONS[stage].count(box)
				var k: int=m.counts(m.colours())[box]
				var choose: Array=[[1],[1,1],[1,2,1],[1,3,3,1],[1,4,6,4,1]][n]
				expected*=choose[k]
			check("all colour patterns "+str(order)+" / "+str(stage),ways.size()==expected and ways.has(m.colours()) and ways.size()<=last)
			last=ways.size()
	var table=load("res://commons/artifacts/entropy_sorting_table/entropy_sorting_table.tscn").instantiate()
	root.add_child(table)
	table.position=Vector3(3,0,-5);table.rotation.y=PI*0.7
	check("arrival waits for button",table.delivered==0 and not table.delivering)
	var ids: Array=table.cubes.map(func(c): return c.get_instance_id())
	press(table)
	await create_timer(6.3).timeout
	check("real button delivers four then pauses",table.delivered==4 and not table.delivering)
	check("all four cubes can be picked",table.cubes.all(func(c):return c.enabled and not c.get_node("CollisionShape3D").disabled))
	check("six pictures for one box",table.picture_patterns.size()==6)
	press(table)
	check("divider preserves physical cubes and layout",table.model.stage==1 and table.model.occupants==[0,1,2,3] and table.cubes.map(func(c):return c.get_instance_id())==ids)
	check("four pictures for mixed pairs",table.picture_patterns.size()==4)
	var cube=table.cubes[1]
	cube.on_desktop_grab(null)
	press(table)
	check("no advance or misleading count while held",table.model.stage==1 and table.picture_patterns.is_empty())
	cube.global_position=table.to_global(table.slot_position(2))
	cube.on_desktop_drop(null)
	await process_frame; await physics_frame
	check("desktop swap works in rotated hall",table.model.occupants==[0,2,1,3] and table.picture_patterns.size()==1)
	check("swapped cube seats on local spot",cube.global_position.is_equal_approx(table.to_global(table.slot_position(2))))
	var before: Array=table.model.occupants.duplicate()
	cube.on_desktop_grab(null);cube.global_position+=Vector3(4,3,4);cube.on_desktop_drop(null)
	await process_frame
	check("outside release returns without losing cube",table.model.occupants==before and cube.position.is_equal_approx(table.slot_position(2)))
	# XR routes exactly the released event used by the pickup system.
	cube.picked_up.emit(cube)
	cube.global_position=table.to_global(table.slot_position(1))
	cube.dropped.emit(cube)
	await process_frame
	check("XR drop shares placement operation",table.model.occupants==[0,1,2,3] and table.picture_patterns.size()==4)
	press(table);check("third box retains two possibilities",table.model.stage==2 and table.picture_patterns.size()==2)
	press(table);check("fourth box retains one possibility",table.model.stage==3 and table.picture_patterns.size()==1)
	press(table);check("one-box return retains all four cubes",table.model.stage==0 and table.delivered==4 and table.picture_patterns.size()==6 and table.cubes.map(func(c):return c.get_instance_id())==ids)
	await create_timer(2.0).timeout
	check("sorting pause has no automatic advancement",table.model.stage==0 and not table.delivering)
	var report={"checks":checks,"failures":failures,"scope":"Model and scripted desktop/XR event checks, not a headset comfort trial"}
	var file=FileAccess.open("res://doc/book/iterations/2026-10-16-entropy-sorting-table/checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"));file.close()
	quit(0 if failures.is_empty() else 1)
