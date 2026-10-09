extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(2.0).timeout
	for node in root.find_children("*","Node",true,false):
		if node.get_script()!=null and str(node.get_script().resource_path).ends_with("/MushroomHand.gd"):
			var hud:CanvasLayer=node.get("_hud")
			if hud!=null:hud.visible=false
	if map_id=="Change_Intro":await introduction()
	else:await flow()

func introduction() -> void:
	var rate=find_scene("/rate_comparison.gd")
	var accumulation=find_scene("/accumulation_comparison.gd")
	check("both authored workbench comparisons loaded",rate!=null and accumulation!=null)
	if rate==null or accumulation==null:return
	var bench:Node3D=rate.bench
	rate.buttons["RESET"].pressed.emit()
	var first:Dictionary=rate.sample()
	observations["first_sample"]=first
	check("wide interval falls while local derivative rises",first.rate<0 and bench._df(first.x)>0)
	await snapshot("two-readings-wide",bench.to_global(Vector3(0,1.7,2.6)),bench.to_global(Vector3(0,1.4,0)),60)
	rate.buttons["DERIVATIVE"].pressed.emit()
	rate.buttons["STEP"].pressed.emit();rate.buttons["STEP"].pressed.emit()
	var closer:Dictionary=rate.sample()
	observations["closer_sample"]=closer
	check("narrow interval reports rising at the same position",is_equal_approx(first.x,closer.x) and closer.rate>0)
	check("slope plot is revealed above the curve",bench._derivative_root.visible and bench._derivative_root.global_position.y>bench._plot_root.global_position.y)
	observations["rate_readout"]=rate.readout.text
	await snapshot("two-readings-near",bench.to_global(Vector3(0,1.7,2.6)),bench.to_global(Vector3(0,1.4,0)),60)
	await snapshot("rate-console",bench.to_global(Vector3(0,1.7,1.45)),bench.to_global(Vector3(0,0.95,0)),66)
	bench=accumulation.bench
	accumulation.buttons["RESET"].pressed.emit();accumulation.buttons["HOLD"].pressed.emit()
	var held:Dictionary=accumulation.held.duplicate(true)
	var cycles=[]
	for expected in ["RIGHT","LEFT","MID"]:
		accumulation.buttons["RULE"].pressed.emit()
		cycles.append(accumulation.RULES[accumulation.rule])
		check("RULE reaches "+expected+" without losing held image",accumulation.RULES[accumulation.rule]==expected and accumulation.held==held and accumulation.held_root.visible)
	observations["rule_cycle"]=cycles
	bench._slider.set_normalized_value(bench._n_index_to_normalized(1))
	bench._slider.slider_moved.emit(Vector3.ZERO)
	await tick()
	check("count slider gives eight live rectangles and four held",bench._n==8 and accumulation.held.n==4)
	observations["accumulation_readout"]=bench._plate_readout.text
	await snapshot("four-held-eight-live",bench.to_global(Vector3(0.65,1.7,3.2)),bench.to_global(Vector3(0.65,1.4,-0.2)),60)
	await snapshot("accumulation-console",bench.to_global(Vector3(0,1.7,1.6)),bench.to_global(Vector3(0,0.95,0)),70)
	var bridge=find_scene("/ftc_bridge.gd")
	if bridge!=null:await snapshot("change-hall",bridge.to_global(Vector3(3.6,1.7,4.5)),bridge.to_global(Vector3(0,1.2,0)),70)
	observations["headset_readability"]="OPEN: native standing views and existing readout strings only; no headset judgement."

func flow() -> void:
	var lesson=find_scene("/shared_field_lesson.gd")
	check("shared field encounter loaded in museum",lesson!=null)
	if lesson==null:return
	var painter:Node3D=lesson.painter
	check("field starts held while particles remain active",not painter.field_evolving and painter.is_processing())
	check("status label is beyond far canvas edge",lesson.status.position.z < -painter.canvas_size.y/2 and lesson.status.position.y>0)
	observations["status"]=lesson.status.text
	var first=Vector2(painter._particles[0].x,painter._particles[0].y)
	var field_time:float=painter._time
	await create_timer(0.2).timeout
	var second=Vector2(painter._particles[0].x,painter._particles[0].y)
	check("held field still produces particle movement",is_equal_approx(field_time,painter._time) and not first.is_equal_approx(second))
	lesson.buttons["ARROWS"].pressed.emit()
	check("ARROWS reveals shared field directions",lesson.arrows.visible)
	# Author placement scales the small study by 2.5; use real standing eye height.
	var eye:Vector3=painter.to_global(Vector3(0.28,0,1.15));eye.y=hall.global_position.y+1.7
	await snapshot("flow-field-held",eye,painter.to_global(Vector3(0,0,0.02)),65)
	eye=painter.to_global(Vector3(0.60,0,0.08));eye.y=hall.global_position.y+1.7
	await snapshot("flow-field-near",eye,painter.to_global(Vector3(0,0,0)),65)
	lesson.buttons["FIELD TIME"].pressed.emit()
	await create_timer(0.2).timeout
	check("FIELD TIME advances the sampled field",painter.field_evolving and painter._time>field_time)
	lesson.buttons["FIELD TIME"].pressed.emit()
	check("field can be held again with particles active",not painter.field_evolving and painter.is_processing())
	var grand=find_scene("/grand_zoetrope.gd")
	check("existing Grand Zoetrope remains in hall",grand!=null)
	if grand!=null:await snapshot("grand-zoetrope",grand.to_global(Vector3(2.8,1.7,4.0)),grand.to_global(Vector3(0,1.1,0)),62)
