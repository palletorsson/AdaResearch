extends SceneTree
const P = preload("res://commons/artifacts/jacquard_weaver/weave_program.gd")
const S = preload("res://commons/artifacts/jacquard_weaver/weave_samples.gd")
const C = preload("res://commons/artifacts/jacquard_weaver/yarn_colours.gd")
const F = preload("res://commons/artifacts/jacquard_weaver/weave_fabric.gd")
const OUT := "res://doc/book/iterations/2026-10-10-six-woven-patterns/"
var checks: Array=[]
var loom: Node3D
var layers: Node3D

func _initialize() -> void:call_deferred("run")
func check(ok: bool, text: String) -> void:
	checks.append({"passed":ok,"test":text});print("PASS " if ok else "FAIL ",text)
	assert(ok,text)
func press(button: Node3D) -> void:
	button.get_node("InteractableAreaButton").emit_signal("button_pressed",button)

func run() -> void:
	create_timer(90).timeout.connect(func():quit(98))
	var studio=load("res://commons/artifacts/jacquard_weaver/jacquard_studio.tscn").instantiate()
	root.add_child(studio);await process_frame
	loom=studio.loom;layers=studio.layers;loom.set_process(false)
	check(layers.pattern_buttons.size()==6,"Six named physical sample buttons are connected in the studio")
	var masks: Dictionary={}
	for i in range(6):
		var key: String=S.KEYS[i]
		press(layers.pattern_buttons[i])
		check(loom.sample_key==key and layers.sample_name==S.TITLES[i],key+": selection labels agree")
		check(loom.program.history.size()==96 and layers.records==loom.program.history,key+": 96 committed passes shared by both views")
		check(not loom.running and loom.program.active.is_empty(),key+": complete sample stops at a cycle boundary")
		var records: Array=loom.program.snapshot()
		var surface: Array=layers.drawdown_mesh.mesh.surface_get_arrays(0)
		var colours: PackedColorArray=surface[Mesh.ARRAY_COLOR]
		var paths_ok:=true;var colours_ok:=true
		for row in range(96):
			for col in range(96):
				var r: Dictionary=records[row]
				var up: bool=int(r.bits[col%12])==1
				var warp: Vector3=layers.warp_paths[col][row]
				var weft:=F.point(records,col,row,false)
				paths_ok=paths_ok and ((warp.y>weft.y)==up) and absf(warp.y-weft.y)>F.HALF_HEIGHT*2
				var expected:=Color(str(r.warp_colors[col%r.warp_colors.size()]) if up else str(r.weft_color))
				colours_ok=colours_ok and colours[(row*96+col)*4].is_equal_approx(expected)
		check(paths_ok,key+": all 9,216 geometric crossings obey the recorded lifts")
		check(colours_ok,key+": all 9,216 drawdown cells show the upper yarn colour")
		var mesh_id: int=layers.fabric_mesh.mesh.get_instance_id()
		press(layers.layers_button)
		check(is_equal_approx(float(layers.fabric_material.get_shader_parameter("opening")),1.0) and layers.records==records and layers.fabric_mesh.mesh.get_instance_id()==mesh_id,key+": opening uses the same mesh and history")
		press(layers.flat_button)
		check(not layers.drawdown_mesh.visible and layers.records==records,key+": closing restores the cloth without changing its data")
		masks[key]=records[0].bits.duplicate()
		# Replaying from empty must reproduce the sample through animated passes.
		loom.reset_cloth()
		for row in range(16):
			assert(loom.start_pick());loom.advance_cycle(2.8)
		check(loom.program.history==records.slice(0,16),key+": sixteen animated picks reproduce the fast sample exactly")
	check(masks.stripes==masks.checks and masks.checks!=masks.tartan,"Stripes and checks share plain weave; tartan changes the crossing structure")
	check(masks.tartan==masks.houndstooth,"Tartan and houndstooth share the same 2/2 twill")
	check(masks.chevron==[1,1,0,0,1,1,0,1,1,0,0,1],"Chevron has a pointed, twelve-end reversing draft")
	check(masks.herringbone==[1,1,0,0,1,1,0,0,1,1,0,0],"Herringbone offsets the two reversing seams instead of making chevron points")
	press(layers.pattern_buttons[5])
	check(loom.warp_colors.size()==8 and loom.weft_colors.size()==8,"Houndstooth keeps its eight-thread colour period independent of twelve hooks")
	var fixture := ["####..##","#####..#","######..","####.##.","##......",".##.....","..##....","#..#...."]
	var correct:=true
	for row in range(96):
		for col in range(96):
			var colour:=C.top_colour(layers.records[row],col)
			correct=correct and colour==("282831" if fixture[row%8][col%8]=="#" else "f3e6c8")
	check(correct,"Houndstooth matches the independent 8×8 drawdown across every twelve-hook boundary")
	check(not loom.warp_buttons[8].visible and loom.warp_buttons[8].get_node("InteractableAreaButton").collision_layer==0,"Unused colour steps are hidden and cannot receive invisible hits")
	var kept: Array=loom.program.snapshot()
	loom.cards[0].on_desktop_grab(null)
	press(layers.pattern_buttons[0])
	check(loom.sample_key=="houndstooth" and loom.program.history==kept,"A held card prevents a sample replacement without losing cloth")
	loom.cards[0].position=loom.slots[0];loom.cards[0].on_desktop_drop()
	await process_frame;await process_frame
	loom.start_pick();var active: Dictionary=loom.program.active.duplicate(true)
	press(loom.weft_buttons[0]);loom.advance_cycle(2.8)
	check(loom.program.history[96]==active and loom.program.history.slice(0,96)==kept,"Manual colour edit preserves the in-flight pick and all earlier houndstooth")
	check(loom.sample_edited and "EDITED" in layers.pattern_caption.text,"Modified samples are labelled as edited")
	press(layers.pattern_buttons[0])
	check(loom.sample_key=="stripes" and loom.program.history.size()==96 and not loom.sample_edited,"A new selection replaces the sample and resets its edit state")
	var before: Array=loom.program.snapshot()
	check(not loom.select_sample("unknown") and loom.program.history==before,"An unknown preset cannot clear the cloth")
	var f:=FileAccess.open(OUT+"sample-tests.json",FileAccess.WRITE)
	var passed:=true
	for c in checks:passed=passed and c.passed
	f.store_string(JSON.stringify({"passed":passed,"checks":checks,"headset":false},"\t"));f.close();quit(0 if passed else 1)
